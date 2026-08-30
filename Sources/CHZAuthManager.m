#import "CHZAuthManager.h"
#import <UIKit/UIKit.h>
#import "CHZKeychain.h"
#import "APIClient.h"
#import "CHZSecrets.h"

@interface CHZAuthManager ()
@property (nonatomic, assign) BOOL apiConfigured;
@end

static BOOL CHZAuthMessageIndicatesExpiredKey(NSString *message) {
    if (![message isKindOfClass:[NSString class]]) return NO;
    NSString *normalized = [message lowercaseString];
    NSArray<NSString *> *markers = @[
        @"expired", @"expire", @"expiration", @"expirad",
        @"invalid key", @"key inválida", @"key invalida", @"key refused",
        @"revoked", @"revogada", @"disabled", @"desativada", @"inactive", @"inativa"
    ];
    for (NSString *marker in markers) {
        if ([normalized containsString:marker]) return YES;
    }
    return NO;
}

static BOOL CHZPayloadExplicitlyAuthorizesLogin(NSDictionary *payload) {
    if (![payload isKindOfClass:[NSDictionary class]]) return NO;

    NSArray<NSString *> *booleanKeys = @[@"success", @"ok", @"valid", @"authorized", @"active"];
    for (NSString *key in booleanKeys) {
        id value = payload[key];
        if ([value isKindOfClass:[NSNumber class]]) return [value boolValue];
    }

    id status = payload[@"status"] ?: payload[@"result"];
    if ([status isKindOfClass:[NSString class]]) {
        NSString *normalized = [status lowercaseString];
        NSArray<NSString *> *positive = @[@"success", @"successful", @"ok", @"valid", @"authorized", @"active", @"approved"];
        for (NSString *value in positive) {
            if ([normalized isEqualToString:value]) return YES;
        }
        return NO;
    }

    id code = payload[@"code"];
    if ([code isKindOfClass:[NSNumber class]]) return [code integerValue] == 200;
    if ([code isKindOfClass:[NSString class]]) return [code isEqualToString:@"200"];

    return NO;
}

static NSDate *CHZParseExpiration(NSString *value, NSTimeZone *timeZone) {
    if (![value isKindOfClass:[NSString class]] || value.length == 0) return nil;
    NSArray<NSString *> *formats = @[
        @"yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
        @"yyyy-MM-dd'T'HH:mm:ssXXXXX",
        @"yyyy-MM-dd HH:mm:ss",
        @"yyyy-MM-dd"
    ];
    for (NSString *format in formats) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = format;
        formatter.timeZone = timeZone ?: [NSTimeZone timeZoneForSecondsFromGMT:0];
        NSDate *date = [formatter dateFromString:value];
        if (date) return date;
    }
    return nil;
}

static BOOL CHZLibraryKeyMatches(NSString *inputKey) {
    const char *libraryKeyCString = apiclient_get_key();
    NSString *libraryKey = libraryKeyCString ? [NSString stringWithUTF8String:libraryKeyCString] : nil;
    return libraryKey.length > 0 && [libraryKey isEqualToString:inputKey];
}

static BOOL CHZLibraryExpirationIsValid(void) {
    const char *expirationCString = apiclient_get_expired_at();
    NSString *expirationValue = expirationCString ? [NSString stringWithUTF8String:expirationCString] : nil;
    NSDate *expirationDate = CHZParseExpiration(expirationValue, [NSTimeZone timeZoneForSecondsFromGMT:0]);
    if (!expirationDate) {
        const char *localExpirationCString = apiclient_get_expired_at_local();
        NSString *localExpirationValue = localExpirationCString ? [NSString stringWithUTF8String:localExpirationCString] : nil;
        expirationDate = CHZParseExpiration(localExpirationValue, [NSTimeZone localTimeZone]);
    }
    return expirationDate != nil && [expirationDate timeIntervalSinceNow] > 0;
}

@implementation CHZAuthManager

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
        // A biblioteca é configurada sob demanda, somente quando o usuário tenta entrar.
        _apiConfigured = NO;
    }
    return self;
}

- (void)configureAPIIfNeeded {
    if (self.apiConfigured) return;

    // Configure as opções antes do token para evitar a UI nativa da biblioteca.
    apiclient_hide_ui(true);
    apiclient_silent_mode(true);
    apiclient_strict_mode(false);
    apiclient_set_language("en");

    NSString *uid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    if (uid.length > 0) {
        apiclient_set_udid(uid.UTF8String);
        NSLog(@"[CHZLogin] UID configurado: SIM; tamanho: %lu", (unsigned long)uid.length);
    } else {
        NSLog(@"[CHZLogin] UID configurado: NAO");
    }

    const char *token = [CHZ_API_TOKEN UTF8String];
    if (token != NULL) {
        apiclient_set_token(token);
    }
    self.apiConfigured = YES;
}

- (void)validateSavedKeyWithSuccess:(CHZAuthSuccess)success failure:(CHZAuthFailure)failure {
    NSError *loadError = nil;
    NSString *savedKey = [CHZKeychain loadKey:&loadError];
    if (savedKey.length == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failure) failure(loadError.localizedDescription ?: @"Nenhuma key salva.");
        });
        return;
    }
    [self loginWithKey:savedKey success:success failure:failure];
}

- (void)loginWithKey:(NSString *)key success:(CHZAuthSuccess)success failure:(CHZAuthFailure)failure {
    NSString *trimmedKey = [key isKindOfClass:[NSString class]]
        ? [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
        : @"";

    if (trimmedKey.length == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failure) failure(@"Digite uma key válida.");
        });
        return;
    }

    [self configureAPIIfNeeded];

    const char *input = [trimmedKey UTF8String];
    if (input == NULL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failure) failure(@"A key possui um formato inválido.");
        });
        return;
    }

    apiclient_dict_callback onSuccess = ^(const char *json) {
        NSDictionary *payload = nil;
        if (json != NULL) {
            NSData *data = [NSData dataWithBytes:json length:strlen(json)];
            id parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([parsed isKindOfClass:[NSDictionary class]]) payload = parsed;
        }
        BOOL explicitPayloadSuccess = CHZPayloadExplicitlyAuthorizesLogin(payload);
        BOOL libraryKeyMatches = CHZLibraryKeyMatches(trimmedKey);
        BOOL expirationIsValid = CHZLibraryExpirationIsValid();
        if (!explicitPayloadSuccess || !libraryKeyMatches || !expirationIsValid) {
            NSString *diagnostic = [NSString stringWithFormat:@"Validação recusada — API: %@; key confirmada: %@; expiração válida: %@.",
                                     explicitPayloadSuccess ? @"sim" : @"não",
                                     libraryKeyMatches ? @"sim" : @"não",
                                     expirationIsValid ? @"sim" : @"não"];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) failure(diagnostic);
            });
            return;
        }
        NSError *saveError = nil;
        BOOL saved = [CHZKeychain saveKey:trimmedKey error:&saveError];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!saved) {
                if (failure) failure(saveError.localizedDescription ?: @"Não foi possível salvar a key.");
            } else if (success) {
                success();
            }
        });
    };

    apiclient_dict_callback onFailure = ^(const char *json) {
        NSLog(@"[CHZLogin] API login failure JSON: %s", json ?: "<null>");
        // Falhas de rede ou respostas temporárias mantêm a key salva.
        // A key só é removida quando a resposta identifica expiração,
        // revogação, desativação ou invalidez explícita.
        NSString *message = @"Key recusada pela API.";
        if (json != NULL) {
            NSData *data = [NSData dataWithBytes:json length:strlen(json)];
            id parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([parsed isKindOfClass:[NSDictionary class]]) {
                id detail = parsed[@"message"] ?: parsed[@"error"] ?: parsed[@"msg"];
                if ([detail isKindOfClass:[NSString class]] && [detail length] > 0) message = detail;
            }
        }
        NSString *rawResponse = json ? [NSString stringWithUTF8String:json] : nil;
        BOOL shouldClearKey = CHZAuthMessageIndicatesExpiredKey(message)
            || CHZAuthMessageIndicatesExpiredKey(rawResponse);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (shouldClearKey) {
                [CHZKeychain deleteKey:nil];
            }
            if (failure) failure(message);
        });
    };

    // A biblioteca pode executar os callbacks de forma assíncrona.
    // Mantemos cópias em heap para evitar uso de blocos temporários já liberados.
    apiclient_dict_callback safeSuccess = [onSuccess copy];
    apiclient_dict_callback safeFailure = [onFailure copy];
    // A documentação indica que check device deve ocorrer antes do login.
    // Tanto sucesso quanto falha do check seguem para login: um dispositivo
    // ausente deve ser ativado pela key, enquanto um existente é revalidado.
    apiclient_dict_callback checkDone = ^(const char *json) {
        (void)json;
        apiclient_on_login(input, safeSuccess, safeFailure);
    };
    apiclient_dict_callback safeCheckDone = [checkDone copy];
    apiclient_on_check_device(safeCheckDone, safeCheckDone);
}

- (void)clearSavedKey {
    [CHZKeychain deleteKey:nil];
}

@end
