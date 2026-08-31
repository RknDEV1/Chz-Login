#import "CHZAuthManager.h"
#import <UIKit/UIKit.h>
#import "CHZKeychain.h"
#import "APIClient.h"
#import "CHZSecrets.h"

@interface CHZAuthManager ()
@property (nonatomic, assign) BOOL apiConfigured;
@property (nonatomic, assign) BOOL apiConfigurationFailed;
@property (nonatomic, strong) APIClient *apiClient;
@end

static NSString *CHZMessageFromDictionary(NSDictionary *dictionary) {
    if (![dictionary isKindOfClass:[NSDictionary class]]) return nil;

    NSArray<NSString *> *keys = @[@"message", @"error", @"msg", @"detail", @"description"];
    for (NSString *key in keys) {
        id value = dictionary[key];
        if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
            return value;
        }
    }
    return nil;
}

static BOOL CHZMessageIndicatesExpiredKey(NSString *message) {
    if (![message isKindOfClass:[NSString class]]) return NO;

    NSString *normalized = [[message lowercaseString]
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    NSArray<NSString *> *markers = @[
        @"expired", @"expiration", @"expire", @"expirad",
        @"revoked", @"revogada", @"disabled", @"desativada",
        @"inactive", @"inativa"
    ];

    for (NSString *marker in markers) {
        if ([normalized containsString:marker]) return YES;
    }
    return NO;
}

static BOOL CHZValueMeansSuccess(id value) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value boolValue];
    }

    if (![value isKindOfClass:[NSString class]]) return NO;

    NSString *normalized = [[value lowercaseString]
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    return [@[@"true", @"yes", @"ok", @"valid", @"validated", @"authorized",
              @"authorised", @"success", @"successful", @"1"] containsObject:normalized];
}

static BOOL CHZResponseHasExplicitApproval(NSDictionary *data) {
    if (![data isKindOfClass:[NSDictionary class]]) return NO;

    NSArray<NSString *> *approvalFields = @[
        @"success", @"valid", @"is_valid", @"isValid",
        @"authorized", @"authorised", @"status", @"result"
    ];

    for (NSString *field in approvalFields) {
        if (CHZValueMeansSuccess(data[field])) return YES;
    }

    NSDictionary *nestedData = [data[@"data"] isKindOfClass:[NSDictionary class]] ? data[@"data"] : nil;
    if (nestedData != nil) {
        for (NSString *field in approvalFields) {
            if (CHZValueMeansSuccess(nestedData[field])) return YES;
        }
    }

    return NO;
}

static NSDate *CHZDateFromString(NSString *value) {
    if (![value isKindOfClass:[NSString class]]) return nil;

    NSString *text = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (text.length == 0) return nil;

    NSString *normalized = [text lowercaseString];
    if ([normalized isEqualToString:@"lifetime"] ||
        [normalized isEqualToString:@"permanent"] ||
        [normalized isEqualToString:@"永久"]) {
        return [NSDate distantFuture];
    }

    NSISO8601DateFormatter *iso = [[NSISO8601DateFormatter alloc] init];
    iso.formatOptions = NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithFractionalSeconds;
    NSDate *date = [iso dateFromString:text];
    if (date != nil) return date;

    iso.formatOptions = NSISO8601DateFormatWithInternetDateTime;
    date = [iso dateFromString:text];
    if (date != nil) return date;

    NSArray<NSString *> *formats = @[
        @"yyyy-MM-dd HH:mm:ss",
        @"yyyy-MM-dd",
        @"dd/MM/yyyy HH:mm:ss",
        @"dd/MM/yyyy"
    ];

    for (NSString *format in formats) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        formatter.dateFormat = format;
        date = [formatter dateFromString:text];
        if (date != nil) return date;
    }

    return nil;
}

static BOOL CHZExpiryIsValid(APIClient *client) {
    NSString *expiry = [client getExpiredAt];
    if (![expiry isKindOfClass:[NSString class]] || expiry.length == 0) {
        expiry = [client getExpiryDate];
    }

    NSDate *expiryDate = CHZDateFromString(expiry);
    if (expiryDate == nil) return NO;
    return [expiryDate compare:[NSDate date]] == NSOrderedDescending;
}

static BOOL CHZReturnedKeyMatchesInput(APIClient *client, NSString *inputKey) {
    NSString *returnedKey = [client getKey];
    if (![returnedKey isKindOfClass:[NSString class]]) return NO;

    NSString *normalizedReturnedKey = [returnedKey
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return normalizedReturnedKey.length > 0 && [normalizedReturnedKey isEqualToString:inputKey];
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
        _apiConfigured = NO;
        _apiConfigurationFailed = NO;
    }
    return self;
}

- (BOOL)configureAPIIfNeeded:(NSString **)configurationError {
    if (self.apiConfigured) return YES;

    if (self.apiConfigurationFailed) {
        if (configurationError) *configurationError = @"Token da API não configurado neste build.";
        return NO;
    }

    self.apiClient = [APIClient sharedAPIClient];
    [self.apiClient hideUI:YES];
    [self.apiClient silentMode:YES];
    [self.apiClient strictMode:YES];
    [self.apiClient setLanguage:@"en"];

    NSString *uid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    if (uid.length > 0) {
        [self.apiClient setUDID:uid];
    }

    NSString *token = [CHZ_API_TOKEN stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (token.length == 0 || [token isEqualToString:@"COLOQUE_SEU_TOKEN_AQUI"]) {
        self.apiConfigurationFailed = YES;
        if (configurationError) *configurationError = @"Token da API não configurado neste build.";
        return NO;
    }

    [self.apiClient setToken:token];
    self.apiConfigured = YES;
    return YES;
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

    NSString *configurationError = nil;
    if (![self configureAPIIfNeeded:&configurationError]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failure) failure(configurationError ?: @"Configuração da API inválida.");
        });
        return;
    }

    void (^rejectLogin)(NSString *) = ^(NSString *message) {
        NSString *safeMessage = message.length > 0 ? message : @"A API não autorizou esta key.";
        if (CHZMessageIndicatesExpiredKey(safeMessage)) {
            [CHZKeychain deleteKey:nil];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failure) failure(safeMessage);
        });
    };

    [self.apiClient onLogin:trimmedKey
                   onSuccess:^(NSDictionary *data) {
        // Nunca liberar somente porque o callback onSuccess foi chamado.
        // Exigimos: aprovação explícita, key devolvida pelo SDK igual à digitada
        // e data de expiração futura.
        BOOL explicitlyApproved = CHZResponseHasExplicitApproval(data);
        BOOL returnedKeyMatches = CHZReturnedKeyMatchesInput(self.apiClient, trimmedKey);
        BOOL notExpired = CHZExpiryIsValid(self.apiClient);

        if (!explicitlyApproved || !returnedKeyMatches || !notExpired) {
            NSString *reason = !explicitlyApproved
                ? @"A API não confirmou explicitamente a validade da key."
                : (!returnedKeyMatches
                   ? @"A API não devolveu a mesma key autorizada."
                   : @"A key está expirada ou não possui validade verificável.");
            rejectLogin(reason);
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
    }
                   onFailure:^(NSDictionary *error) {
        rejectLogin(CHZMessageFromDictionary(error) ?: @"Key recusada pela API.");
    }];
}

- (void)clearSavedKey {
    [CHZKeychain deleteKey:nil];
}

@end
