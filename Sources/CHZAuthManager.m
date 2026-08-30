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

    void (^acceptLogin)(void) = ^{
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

    void (^rejectLogin)(NSDictionary *) = ^(NSDictionary *error) {
        NSString *message = CHZMessageFromDictionary(error) ?: @"Key recusada pela API.";
        if (CHZMessageIndicatesExpiredKey(message)) {
            [CHZKeychain deleteKey:nil];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failure) failure(message);
        });
    };

    // A API Lite Secure separa explicitamente sucesso e falha. O callback
    // success só libera o acesso; nenhum JSON genérico é interpretado como aprovação.
    [self.apiClient onLogin:trimmedKey
                   onSuccess:^(__unused NSDictionary *data) {
        acceptLogin();
    }
                   onFailure:^(NSDictionary *error) {
        rejectLogin(error);
    }];
}

- (void)clearSavedKey {
    [CHZKeychain deleteKey:nil];
}

@end
