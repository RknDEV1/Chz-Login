#import "CHZAuthManager.h"
#import "CHZKeychain.h"
#import "APIClient.h"
#import "CHZSecrets.h"

@interface CHZAuthManager ()
@property (nonatomic, strong) APIClient *api;
@end

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
        _api = [APIClient sharedAPIClient];
        [_api setToken:CHZ_API_TOKEN];
        [_api setLanguage:@"en"];
        [_api hideUI:YES];
        [_api silentMode:YES];
    }
    return self;
}

- (void)validateSavedKeyWithSuccess:(CHZAuthSuccess)success failure:(CHZAuthFailure)failure {
    NSString *savedKey = [CHZKeychain loadKey:nil];
    if (savedKey.length == 0) {
        if (failure) failure(@"Nenhuma key salva.");
        return;
    }
    [self loginWithKey:savedKey success:success failure:failure];
}

- (void)loginWithKey:(NSString *)key success:(CHZAuthSuccess)success failure:(CHZAuthFailure)failure {
    NSString *trimmedKey = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedKey.length == 0) {
        if (failure) failure(@"Digite uma key válida.");
        return;
    }

    __weak typeof(self) weakSelf = self;
    [self.api onLogin:trimmedKey
        onSuccess:^(NSDictionary *data) {
            NSError *saveError = nil;
            [CHZKeychain saveKey:trimmedKey error:&saveError];
            if (success) success();
        }
        onFailure:^(NSDictionary *error) {
            [CHZKeychain deleteKey:nil];
            NSString *message = [error isKindOfClass:[NSDictionary class]] ? [error description] : @"Key recusada pela API.";
            if (failure) failure(message);
            (void)weakSelf;
        }];
}

- (void)clearSavedKey {
    [CHZKeychain deleteKey:nil];
}

@end
