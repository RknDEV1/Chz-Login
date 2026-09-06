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
    if (![serverKey isKindOfClass:[NSString class]] ||
        serverKey.length == 0 ||
        ![serverKey isEqualToString:key]) {
        return NO;
    }

    // O SDK deve conseguir obter os dados da key dentro do package configurado.
    id packageData = [client getPackageDataWithKey:key];
    if (packageData == nil || packageData == (id)[NSNull null]) {
        return NO;
    }
    if ([packageData isKindOfClass:[NSDictionary class]] && [(NSDictionary *)packageData count] == 0) {
        return NO;
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

    NSLog(@"[CHZLogin] resposta confirmou a key e o package");
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
