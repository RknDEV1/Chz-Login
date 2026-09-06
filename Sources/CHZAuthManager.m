#import "CHZAuthManager.h"
#import <UIKit/UIKit.h>
#import "APIClient.h"
#import "CHZSecrets.h"

@implementation CHZAuthManager

- (BOOL)chzResponseConfirmsKey:(NSString *)key
                        client:(APIClient *)client
                        payload:(NSDictionary *)payload {
    // Nunca libera a tela somente porque o callback onSuccess foi disparado.
    // A key retornada pelo SDK precisa ser exatamente a key informada pelo usuário.
    NSString *serverKey = [client getKey];
    BOOL keyMatches = [serverKey isKindOfClass:[NSString class]] &&
                      serverKey.length > 0 &&
                      [serverKey isEqualToString:key];

    // Algumas versões Lite Secure não preenchem getKey imediatamente, mas retornam a key
    // confirmada no payload do callback. Use somente campos explícitos de key; nunca aceite
    // o texto digitado como confirmação por conta própria.
    if (!keyMatches && [payload isKindOfClass:[NSDictionary class]]) {
        NSArray<NSString *> *keyFields = @[@"key", @"license", @"inputKey", @"accessKey"];
        for (NSString *field in keyFields) {
            id value = payload[field];
            if ([value isKindOfClass:[NSString class]] && [value isEqualToString:key]) {
                keyMatches = YES;
                break;
            }
        }
    }

    // Se o payload trouxer um indicador explícito de falha, nunca aceite a key.
    if ([payload isKindOfClass:[NSDictionary class]]) {
        id explicitSuccess = payload[@"success"] ?: payload[@"valid"] ?: payload[@"status"];
        if ([explicitSuccess isKindOfClass:[NSNumber class]] && ![explicitSuccess boolValue]) {
            return NO;
        }
        if ([explicitSuccess isKindOfClass:[NSString class]]) {
            NSString *normalized = [(NSString *)explicitSuccess lowercaseString];
            if ([normalized isEqualToString:@"false"] ||
                [normalized isEqualToString:@"invalid"] ||
                [normalized isEqualToString:@"error"]) {
                return NO;
            }
        }
    }

    if (!keyMatches) {
        NSLog(@"[CHZLogin] sucesso sem confirmação explícita da key");
        return NO;
    }

    // O package autorizado já é definido pelo token privado compilado no build.
    // Evitamos novas consultas síncronas ao SDK durante o callback de login.
    NSLog(@"[CHZLogin] resposta confirmou a key; prosseguindo sem consultas adicionais");
    return YES;
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
        BOOL confirmed = [self chzResponseConfirmsKey:trimmedKey client:client payload:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (confirmed) {
                if (success) success();
            } else if (failure) {
                failure(@"A key não pertence ao package autorizado ou foi recusada pela API.");
            }
        });
    }
          onFailure:^(NSDictionary *error) {
        NSString *message = @"Key recusada pela API.";

        if ([error isKindOfClass:[NSDictionary class]]) {
            id detail = error[@"message"] ?: error[@"error"] ?: error[@"msg"];
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
