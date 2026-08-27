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
        @try {
            _api = [APIClient sharedAPIClient];
            [_api setToken:CHZ_API_TOKEN];
            [_api setLanguage:@"en"];
            [_api hideUI:YES];
            [_api silentMode:YES];
        } @catch (NSException *exception) {
            _api = nil;
        }
    }
    return self;
}

- (void)validateSavedKeyWithSuccess:(CHZAuthSuccess)success failure:(CHZAuthFailure)failure {
    NSError *loadError = nil;
    NSString *savedKey = [CHZKeychain loadKey:&loadError];
    if (savedKey.length == 0) {
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(loadError.localizedDescription ?: @"Nenhuma key salva.");
            });
        }
        return;
    }
    [self loginWithKey:savedKey success:success failure:failure];
}

- (void)loginWithKey:(NSString *)key success:(CHZAuthSuccess)success failure:(CHZAuthFailure)failure {
    NSString *trimmedKey = [key isKindOfClass:[NSString class]]
        ? [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
        : @"";

    if (trimmedKey.length == 0) {
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(@"Digite uma key válida.");
            });
        }
        return;
    }

    APIClient *api = self.api;
    if (!api) {
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(@"O serviço de autenticação não foi inicializado.");
            });
        }
        return;
    }

    @try {
        [api onLogin:trimmedKey
          onSuccess:^(NSDictionary *data) {
              if (![data isKindOfClass:[NSDictionary class]]) {
                  if (failure) {
                      dispatch_async(dispatch_get_main_queue(), ^{
                          failure(@"Resposta inválida da API.");
                      });
                  }
                  return;
              }

              NSError *saveError = nil;
              BOOL saved = [CHZKeychain saveKey:trimmedKey error:&saveError];
              dispatch_async(dispatch_get_main_queue(), ^{
                  if (!saved) {
                      if (failure) {
                          failure(saveError.localizedDescription ?: @"Não foi possível salvar a key.");
                      }
                  } else if (success) {
                      success();
                  }
              });
          }
          onFailure:^(NSDictionary *error) {
              [CHZKeychain deleteKey:nil];
              NSString *message = @"Key recusada pela API.";
              if ([error isKindOfClass:[NSDictionary class]]) {
                  id detail = error[@"message"] ?: error[@"error"] ?: error[@"msg"];
                  if ([detail isKindOfClass:[NSString class]] && [detail length] > 0) {
                      message = detail;
                  }
              }
              if (failure) {
                  dispatch_async(dispatch_get_main_queue(), ^{
                      failure(message);
                  });
              }
          }];
    } @catch (NSException *exception) {
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(@"Não foi possível concluir a autenticação.");
            });
        }
    }
}

- (void)clearSavedKey {
    [CHZKeychain deleteKey:nil];
}

@end

