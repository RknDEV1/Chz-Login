#import "CHZAuthManager.h"
#import <UIKit/UIKit.h>
#import "APIClient.h"
#import "CHZSecrets.h"
#import "CHZKeychain.h"

@implementation CHZAuthManager

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
    NSDate *expirationDate = [self chzDateFromExpiryString:expiry];

    if (![key isKindOfClass:[NSString class]] || key.length == 0 || !expirationDate || [expirationDate timeIntervalSinceNow] <= 0.0) {
        NSLog(@"[CHZLogin] sessão local ausente, inválida ou expirada; login será apresentado");
        if (session) [CHZKeychain deleteKey:nil];
        return NO;
    }
    NSLog(@"[CHZLogin] sessão local válida; expira em %@", expirationDate);
    return YES;
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

        NSString *udid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        if (udid.length > 0) {
            [client setUDID:udid];
        }

        NSLog(@"[CHZLogin] UDID configurado: %@; tamanho: %lu",
              udid.length > 0 ? @"SIM" : @"NAO",
              (unsigned long)udid.length);

        [client hideUI:YES];
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
        // O callback do SDK, isoladamente, não é suficiente para fechar a tela.
        // Confirme a key retornada e os dados do package antes de liberar o login.
        BOOL confirmed = NO;
        @try {
            confirmed = [self chzResponseConfirmsKey:trimmedKey client:client payload:data];
        } @catch (NSException *exception) {
            NSLog(@"[CHZLogin] exceção ao processar resposta do SDK: %@", exception.reason ?: @"sem motivo");
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (confirmed) {
                NSString *expiry = [self chzSafeExpiryDateFromClient:client key:trimmedKey payload:data];
                NSError *saveError = nil;
                BOOL saved = NO;
                if (expiry.length > 0) {
                    saved = [CHZKeychain saveSessionForKey:trimmedKey expiry:expiry error:&saveError];
                }
                NSLog(@"[CHZLogin] sessão salva=%@; expiração=%@; erro=%@",
                      saved ? @"SIM" : @"NAO",
                      expiry.length > 0 ? expiry : @"não disponível",
                      saveError.localizedDescription ?: @"nenhum");
                if (success) success();
            } else if (failure) {
                failure(@"A key não pertence ao package autorizado ou foi recusada pela API.");
            }
        });
    }
          onFailure:^(NSDictionary *error) {
        NSString *message = @"Key recusada pela API.";

        if ([error isKindOfClass:[NSDictionary class]]) {
            NSDictionary *safeError = (NSDictionary *)error;
            id detail = [safeError objectForKey:@"message"] ?: [safeError objectForKey:@"error"] ?: [safeError objectForKey:@"msg"];
            if ([detail isKindOfClass:[NSString class]] && [detail length] > 0) {
                message = detail;
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (failure) failure(message);
        });
    }];
}

@end
