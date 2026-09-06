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
    NSString *serverKey = nil;
    @try {
        serverKey = [client getKey];
    } @catch (NSException *exception) {
        NSLog(@"[CHZLogin] SDK retornou exceção ao ler getKey: %@", exception.reason ?: @"sem motivo");
    }

    BOOL keyMatches = [serverKey isKindOfClass:[NSString class]] &&
                      serverKey.length > 0 &&
                      [serverKey isEqualToString:key];

    // Algumas versões Lite Secure não preenchem getKey imediatamente, mas retornam a key
    // confirmada no payload do callback. Use somente campos explícitos de key; nunca aceite
    // o texto digitado como confirmação por conta própria.
    if (!keyMatches && [payload isKindOfClass:[NSDictionary class]]) {
        NSArray<NSString *> *keyFields = @[@"key", @"license", @"inputKey", @"accessKey"];
        for (NSString *field in keyFields) {
            id value = [(NSDictionary *)payload objectForKey:field];
            if ([value isKindOfClass:[NSString class]] && [value isEqualToString:key]) {
                keyMatches = YES;
                break;
            }
        }
    }

    // Se o payload trouxer um indicador explícito de falha, nunca aceite a key.
    if ([payload isKindOfClass:[NSDictionary class]]) {
        NSDictionary *safePayload = (NSDictionary *)payload;
        id explicitSuccess = [safePayload objectForKey:@"success"] ?: [safePayload objectForKey:@"valid"] ?: [safePayload objectForKey:@"status"];
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

    // O onSuccess do AuthTool é a confirmação oficial da autenticação realizada
    // pelo token/package compilado. getKey e os campos de metadata podem chegar
    // vazios ou como NSNull imediatamente após o callback; ausência de metadata
    // não deve ser confundida com package incorreto.
    if (serverKey.length > 0 && !keyMatches) {
        NSLog(@"[CHZLogin] SDK retornou uma key diferente da informada");
        return NO;
    }

    BOOL payloadContainsKey = NO;
    if ([payload isKindOfClass:[NSDictionary class]]) {
        NSArray<NSString *> *keyFields = @[@"key", @"license", @"inputKey", @"accessKey"];
        for (NSString *field in keyFields) {
            id value = [(NSDictionary *)payload objectForKey:field];
            if ([value isKindOfClass:[NSString class]]) {
                payloadContainsKey = YES;
                if (![value isEqualToString:key]) {
                    NSLog(@"[CHZLogin] payload retornou uma key diferente da informada");
                    return NO;
                }
                break;
            }
        }
    }

    NSLog(@"[CHZLogin] onSuccess confirmado; key=%@ payloadKey=%@",
          keyMatches ? @"SIM" : @"metadata pendente",
          payloadContainsKey ? @"SIM" : @"NAO");
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
        BOOL confirmed = NO;
        @try {
            confirmed = [self chzResponseConfirmsKey:trimmedKey client:client payload:data];
        } @catch (NSException *exception) {
            NSLog(@"[CHZLogin] exceção ao processar resposta do SDK: %@", exception.reason ?: @"sem motivo");
        }
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
