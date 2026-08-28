#import "CHZAuthManager.h"
#import <UIKit/UIKit.h>
#import "CHZKeychain.h"
#import "APIClient.h"
#import "CHZSecrets.h"

@interface CHZAuthManager ()
@property (nonatomic, assign) BOOL apiConfigured;
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

    // Diagnóstico: não enviar identifierForVendor nesta build de isolamento.
    // O serviço pode exigir o UDID real obtido pelo seu próprio procedimento.
    NSLog(@"[CHZLogin] Build de isolamento: UDID não enviado à biblioteca");

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
        if (json != NULL && payload == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) failure(@"Resposta inválida da API.");
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
        [CHZKeychain deleteKey:nil];
        NSString *message = @"Key recusada pela API.";
        if (json != NULL) {
            NSData *data = [NSData dataWithBytes:json length:strlen(json)];
            id parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([parsed isKindOfClass:[NSDictionary class]]) {
                id detail = parsed[@"message"] ?: parsed[@"error"] ?: parsed[@"msg"];
                if ([detail isKindOfClass:[NSString class]] && [detail length] > 0) message = detail;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failure) failure(message);
        });
    };

    apiclient_on_login(input, onSuccess, onFailure);
}

- (void)clearSavedKey {
    [CHZKeychain deleteKey:nil];
}

@end
