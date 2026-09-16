#import "CHZAuthManager.h"
#import <UIKit/UIKit.h>
#import "APIClient.h"
#import "CHZSecrets.h"
#import "CHZKeychain.h"

@implementation CHZAuthManager

- (NSString *)chzCurrentDeviceID {
    NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    return [deviceID isKindOfClass:[NSString class]] ? deviceID : @"";
}

- (NSString *)chzNormalizedDeviceID:(NSString *)value {
    if (![value isKindOfClass:[NSString class]]) return @"";
    NSString *trimmed = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [[trimmed stringByReplacingOccurrencesOfString:@"-" withString:@""] lowercaseString];
}

- (NSString *)chzDeviceIDFromObject:(id)object {
    if (![object isKindOfClass:[NSDictionary class]]) return nil;
    NSDictionary *dictionary = (NSDictionary *)object;
    NSArray<NSString *> *keys = @[@"udid", @"deviceID", @"deviceId", @"device_id", @"hwid", @"identifierForVendor"];
    for (NSString *key in keys) {
        id value = [dictionary objectForKey:key];
        if ([value isKindOfClass:[NSString class]] && [value length] > 0) return value;
    }
    NSArray<NSString *> *nestedKeys = @[@"data", @"result", @"device", @"package"];
    for (NSString *key in nestedKeys) {
        NSString *nested = [self chzDeviceIDFromObject:[dictionary objectForKey:key]];
        if (nested.length > 0) return nested;
    }
    return nil;
}

- (NSString *)chzMessageFromError:(NSDictionary *)error fallback:(NSString *)fallback {
    if ([error isKindOfClass:[NSDictionary class]]) {
        id detail = [error objectForKey:@"message"] ?: [error objectForKey:@"error"] ?: [error objectForKey:@"msg"];
        if ([detail isKindOfClass:[NSString class]] && [detail length] > 0) return detail;
    }
    return fallback;
}

- (BOOL)chzDeviceResponseIsValid:(NSDictionary *)payload currentDeviceID:(NSString *)currentDeviceID {
    if (![payload isKindOfClass:[NSDictionary class]] || currentDeviceID.length == 0) return NO;

    NSString *serverDeviceID = [self chzDeviceIDFromObject:payload];
    if (serverDeviceID.length > 0) {
        return [[self chzNormalizedDeviceID:serverDeviceID] isEqualToString:[self chzNormalizedDeviceID:currentDeviceID]];
    }

    id explicitStatus = [payload objectForKey:@"success"] ?: [payload objectForKey:@"valid"] ?: [payload objectForKey:@"authorized"] ?: [payload objectForKey:@"status"];
    if ([explicitStatus isKindOfClass:[NSNumber class]]) {
        return [explicitStatus boolValue];
    }
    if ([explicitStatus isKindOfClass:[NSString class]]) {
        NSString *normalized = [[(NSString *)explicitStatus stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
        return [@[@"true", @"valid", @"success", @"ok", @"authorized", @"active"] containsObject:normalized];
    }

    // Sem contrato reconhecível, não há prova de vínculo no servidor: falhar fechado.
    return NO;
}

- (BOOL)chzResponseConfirmsKey:(NSString *)key
                        client:(APIClient *)client
                        payload:(NSDictionary *)payload {
    // O bloco onSuccess só é executado pelo SDK depois que o servidor aceitou
    // a key usando o token/package configurado no APIClient. Não usamos getKey
    // para revalidar aqui, porque algumas versões do Lite Secure retornam esse
    // metadata atrasado ou pertencente à sessão anterior.
    if (![payload isKindOfClass:[NSDictionary class]]) {
        NSLog(@"[CHZLogin] onSuccess confirmado sem payload; usando confirmação do SDK");
        return YES;
    }

    NSDictionary *safePayload = (NSDictionary *)payload;
    id explicitSuccess = [safePayload objectForKey:@"success"] ?: [safePayload objectForKey:@"valid"] ?: [safePayload objectForKey:@"status"];
    if ([explicitSuccess isKindOfClass:[NSNumber class]] && ![explicitSuccess boolValue]) {
        return NO;
    }
    if ([explicitSuccess isKindOfClass:[NSString class]]) {
        NSString *normalized = [(NSString *)explicitSuccess lowercaseString];
        if ([normalized isEqualToString:@"false"] ||
            [normalized isEqualToString:@"invalid"] ||
            [normalized isEqualToString:@"error"] ||
            [normalized isEqualToString:@"blocked"] ||
            [normalized isEqualToString:@"deleted"]) {
            return NO;
        }
    }

    NSLog(@"[CHZLogin] onSuccess confirmado pelo AuthTool; metadata de key será ignorado");
    return YES;
}

- (NSString *)chzExpiryStringFromObject:(id)object {
    if ([object isKindOfClass:[NSString class]]) return object;
    if ([object isKindOfClass:[NSNumber class]]) return [(NSNumber *)object stringValue];
    if ([object isKindOfClass:[NSDate class]]) {
        NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
        formatter.formatOptions = NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithFractionalSeconds;
        return [formatter stringFromDate:(NSDate *)object];
    }
    return nil;
}

- (NSString *)chzSafeExpiryDateFromClient:(APIClient *)client key:(NSString *)key payload:(NSDictionary *)payload {
    NSString *expiry = nil;
    @try {
        id rawExpiry = [client getExpiryDate];
        expiry = [self chzExpiryStringFromObject:rawExpiry];
        if (expiry.length == 0) {
            id rawExpiredAt = [client getExpiredAt];
            expiry = [self chzExpiryStringFromObject:rawExpiredAt];
        }
    } @catch (NSException *exception) {
        NSLog(@"[CHZLogin] não foi possível ler a expiração: %@", exception.reason ?: @"sem motivo");
    }

    NSArray<NSString *> *fields = @[@"expiry", @"expiresAt", @"expiredAt", @"expiration", @"expiryDate"];
    if (![expiry isKindOfClass:[NSString class]] || expiry.length == 0) {
        for (NSString *field in fields) {
            id value = [payload isKindOfClass:[NSDictionary class]] ? [(NSDictionary *)payload objectForKey:field] : nil;
            expiry = [self chzExpiryStringFromObject:value];
            if (expiry.length > 0) break;
        }
    }

    // Algumas versões do SDK só expõem a expiração no objeto de dados do pacote.
    // A leitura é protegida e o retorno é tratado como dado não confiável.
    if (![expiry isKindOfClass:[NSString class]] || expiry.length == 0) {
        @try {
            id packageData = [client getPackageDataWithKey:key];
            if ([packageData isKindOfClass:[NSDictionary class]]) {
                for (NSString *field in fields) {
                    id value = [(NSDictionary *)packageData objectForKey:field];
                    if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
                        expiry = value;
                        break;
                    }
                    if ([value isKindOfClass:[NSNumber class]]) {
                        expiry = [(NSNumber *)value stringValue];
                        break;
                    }
                }
            }
        } @catch (NSException *exception) {
            NSLog(@"[CHZLogin] não foi possível ler os dados do pacote: %@", exception.reason ?: @"sem motivo");
        }
    }

    return [expiry isKindOfClass:[NSString class]] ? expiry : nil;
}

- (NSDate *)chzDateFromExpiryString:(NSString *)value {
    if (![value isKindOfClass:[NSString class]] || value.length == 0) return nil;

    NSISO8601DateFormatter *iso = [[NSISO8601DateFormatter alloc] init];
    iso.formatOptions = NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithFractionalSeconds;
    NSDate *date = [iso dateFromString:value];
    if (!date) {
        iso.formatOptions = NSISO8601DateFormatWithInternetDateTime;
        date = [iso dateFromString:value];
    }
    if (!date) {
        NSNumberFormatter *number = [[NSNumberFormatter alloc] init];
        NSNumber *timestamp = [number numberFromString:value];
        if (timestamp != nil) date = [NSDate dateWithTimeIntervalSince1970:timestamp.doubleValue];
    }
    if (!date) {
        NSArray<NSString *> *formats = @[
            @"yyyy-MM-dd HH:mm:ss Z",
            @"yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
            @"yyyy-MM-dd'T'HH:mm:ssXXXXX",
            @"yyyy-MM-dd"
        ];
        for (NSString *format in formats) {
            NSDateFormatter *fallback = [[NSDateFormatter alloc] init];
            fallback.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
            fallback.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            fallback.dateFormat = format;
            date = [fallback dateFromString:value];
            if (date) break;
        }
    }
    return date;
}

- (BOOL)hasValidSavedSession {
    NSDictionary *session = [CHZKeychain loadSession:nil];
    NSString *key = [session objectForKey:@"key"];
    NSString *expiry = [session objectForKey:@"expiry"];
    NSString *savedDeviceID = [session objectForKey:@"deviceID"];
    NSString *currentDeviceID = [self chzCurrentDeviceID];
    NSDate *expirationDate = [self chzDateFromExpiryString:expiry];
    BOOL sameDevice = [self chzNormalizedDeviceID:savedDeviceID].length > 0 &&
        [[self chzNormalizedDeviceID:savedDeviceID] isEqualToString:[self chzNormalizedDeviceID:currentDeviceID]];

    if (![key isKindOfClass:[NSString class]] || key.length == 0 || !expirationDate || [expirationDate timeIntervalSinceNow] <= 0.0 || !sameDevice) {
        NSLog(@"[CHZLogin] sessão local ausente, inválida ou expirada; login será apresentado");
        if (session) [CHZKeychain deleteKey:nil];
        return NO;
    }
    NSLog(@"[CHZLogin] sessão local válida neste dispositivo; expira em %@", expirationDate);
    return YES;
}

- (void)validateSavedSessionWithSuccess:(CHZAuthSuccess)success failure:(CHZAuthFailure)failure {
    NSDictionary *session = [CHZKeychain loadSession:nil];
    NSString *key = [session objectForKey:@"key"];
    if (![self hasValidSavedSession] || ![key isKindOfClass:[NSString class]] || key.length == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failure) failure(@"Sessão ausente, expirada ou vinculada a outro dispositivo.");
        });
        return;
    }
    [self loginWithKey:key success:success failure:failure];
}

- (void)clearSavedSession {
    [CHZKeychain deleteKey:nil];
}

+ (instancetype)sharedManager {
    static CHZAuthManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        APIClient *client = [APIClient sharedAPIClient];

        if (CHZ_API_TOKEN.length > 0) {
            [client setToken:CHZ_API_TOKEN];
        }

        [client setLanguage:@"en"];

        NSString *udid = [self chzCurrentDeviceID];
        if (udid.length > 0) {
            [client setUDID:udid];
        }

        NSLog(@"[CHZLogin] UDID configurado: %@; tamanho: %lu",
              udid.length > 0 ? @"SIM" : @"NAO",
              (unsigned long)udid.length);

        [client hideUI:YES];
        [client strictMode:YES];
        [client silentMode:YES];
    }
    return self;
}

- (void)loginWithKey:(NSString *)key
             success:(CHZAuthSuccess)success
             failure:(CHZAuthFailure)failure {
    NSString *trimmedKey = [key isKindOfClass:[NSString class]]
        ? [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
        : @"";

    if (trimmedKey.length == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failure) failure(@"Digite uma key válida.");
        });
        return;
    }

    APIClient *client = [APIClient sharedAPIClient];

    [client onLogin:trimmedKey
          onSuccess:^(NSDictionary *data) {
        BOOL keyConfirmed = NO;
        @try {
            keyConfirmed = [self chzResponseConfirmsKey:trimmedKey client:client payload:data];
        } @catch (NSException *exception) {
            NSLog(@"[CHZLogin] exceção ao processar resposta do SDK: %@", exception.reason ?: @"sem motivo");
        }
        if (!keyConfirmed) {
            [CHZKeychain deleteKey:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) failure(@"A key não pertence ao package autorizado ou foi recusada pela API.");
            });
            return;
        }

        NSString *currentDeviceID = [self chzCurrentDeviceID];
        if (currentDeviceID.length == 0) {
            [CHZKeychain deleteKey:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) failure(@"Não foi possível identificar este dispositivo.");
            });
            return;
        }

        [client setUDID:currentDeviceID];
        [client onCheckDevice:^(NSDictionary *deviceData) {
            BOOL deviceConfirmed = NO;
            @try {
                deviceConfirmed = [self chzDeviceResponseIsValid:deviceData currentDeviceID:currentDeviceID];
            } @catch (NSException *exception) {
                NSLog(@"[CHZLogin] exceção na confirmação do dispositivo: %@", exception.reason ?: @"sem motivo");
            }
            if (!deviceConfirmed) {
                [CHZKeychain deleteKey:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failure) failure(@"Esta key está vinculada a outro dispositivo ou o vínculo não pôde ser confirmado.");
                });
                return;
            }

            NSString *expiry = [self chzSafeExpiryDateFromClient:client key:trimmedKey payload:data];
            NSError *saveError = nil;
            BOOL saved = NO;
            if (expiry.length > 0) {
                saved = [CHZKeychain saveSessionForKey:trimmedKey
                                                expiry:expiry
                                              deviceID:currentDeviceID
                                                 error:&saveError];
            }
            NSLog(@"[CHZLogin] dispositivo confirmado; sessão salva=%@; expiração=%@; erro=%@",
                  saved ? @"SIM" : @"NAO",
                  expiry.length > 0 ? expiry : @"não disponível",
                  saveError.localizedDescription ?: @"nenhum");
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CHZLoginDidAuthenticateNotification" object:nil];
                if (success) success();
            });
        } onFailure:^(NSDictionary *deviceError) {
            [CHZKeychain deleteKey:nil];
            NSString *message = [self chzMessageFromError:deviceError fallback:@"Esta key não está autorizada para este dispositivo."];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) failure(message);
            });
        }];
    }
          onFailure:^(NSDictionary *error) {
        [CHZKeychain deleteKey:nil];
        NSString *message = [self chzMessageFromError:error fallback:@"Key recusada pela API."];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failure) failure(message);
        });
    }];
}

@end
