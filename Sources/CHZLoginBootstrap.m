#import <UIKit/UIKit.h>
#import "CHZLoginViewController.h"
#import "CHZAuthManager.h"

static BOOL CHZLoginPresentationInProgress = NO;
static BOOL CHZLoginAlreadyPresented = NO;
static BOOL CHZLoginAuthorized = NO;
static BOOL CHZSavedKeyCheckInProgress = NO;
static BOOL CHZBootstrapWasInstalled = NO;

static UIWindow *CHZFindWindow(void) {
    UIApplication *application = [UIApplication sharedApplication];

    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in application.connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive) continue;
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;

            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow && !window.hidden && window.rootViewController) return window;
            }
            for (UIWindow *window in windowScene.windows) {
                if (!window.hidden && window.alpha > 0.0 && window.rootViewController) return window;
            }
        }
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    for (UIWindow *window in application.windows) {
        if (window.isKeyWindow && !window.hidden && window.rootViewController) return window;
    }
#pragma clang diagnostic pop

    return nil;
}

static UIViewController *CHZTopViewController(UIViewController *controller) {
    if (!controller) return nil;

    if (controller.presentedViewController && !controller.presentedViewController.isBeingDismissed) {
        return CHZTopViewController(controller.presentedViewController);
    }
    if ([controller isKindOfClass:[UINavigationController class]]) {
        return CHZTopViewController(((UINavigationController *)controller).visibleViewController);
    }
    if ([controller isKindOfClass:[UITabBarController class]]) {
        return CHZTopViewController(((UITabBarController *)controller).selectedViewController);
    }
    return controller;
}

static void CHZSchedulePresentation(void);
static void CHZPresentLoginWhenReady(void);

static BOOL CHZFirstLaunchAfterInstall(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *marker = [defaults stringForKey:@"com.room.injection.login-install-marker"];
    if (marker.length > 0) return NO;

    [defaults setObject:@"installed" forKey:@"com.room.injection.login-install-marker"];
    [defaults synchronize];
    return YES;
}

static void CHZValidateSavedKeyThenPresentIfNeeded(void) {
    if (CHZLoginAuthorized || CHZSavedKeyCheckInProgress) return;
    CHZSavedKeyCheckInProgress = YES;

    [[CHZAuthManager sharedManager]
        validateSavedKeyWithSuccess:^{
            CHZSavedKeyCheckInProgress = NO;
            CHZLoginAuthorized = YES;
        }
        failure:^(__unused NSString *message) {
            CHZSavedKeyCheckInProgress = NO;
            CHZPresentLoginWhenReady();
        }];

    // Fallback: uma falha de rede ou callback ausente nunca pode esconder
    // permanentemente a tela. O app continua bloqueado e mostra o login.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!CHZLoginAuthorized && CHZSavedKeyCheckInProgress) {
            CHZSavedKeyCheckInProgress = NO;
            CHZPresentLoginWhenReady();
        }
    });
}

static void CHZPresentLoginWhenReady(void) {
    if (CHZLoginAuthorized || CHZLoginAlreadyPresented || CHZLoginPresentationInProgress || CHZSavedKeyCheckInProgress) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (CHZLoginAuthorized || CHZLoginAlreadyPresented || CHZLoginPresentationInProgress || CHZSavedKeyCheckInProgress) return;

        UIApplication *application = [UIApplication sharedApplication];
        if (application.applicationState != UIApplicationStateActive) {
            CHZSchedulePresentation();
            return;
        }

        UIWindow *window = CHZFindWindow();
        if (!window) {
            CHZSchedulePresentation();
            return;
        }
        UIViewController *top = CHZTopViewController(window.rootViewController);
        // Não use viewIfLoaded aqui: na inicialização a view pode ainda não
        // ter sido carregada, mesmo com uma janela válida e ativa.
        if (!top) {
            CHZSchedulePresentation();
            return;
        }

        if ([top isKindOfClass:[CHZLoginViewController class]]) {
            CHZLoginAlreadyPresented = YES;
            return;
        }

        CHZLoginPresentationInProgress = YES;
        CHZLoginViewController *login = [[CHZLoginViewController alloc] init];
        login.modalPresentationStyle = UIModalPresentationFullScreen;
        [top presentViewController:login animated:NO completion:^{
            CHZLoginPresentationInProgress = NO;
            CHZLoginAlreadyPresented = YES;
        }];
    });
}

static void CHZSchedulePresentation(void) {
    if (CHZLoginAuthorized || CHZLoginAlreadyPresented || CHZSavedKeyCheckInProgress) return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CHZPresentLoginWhenReady();
    });
}

static void CHZInstallLoginBootstrap(void) {
    if (CHZBootstrapWasInstalled) return;
    CHZBootstrapWasInstalled = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserverForName:UIApplicationDidBecomeActiveNotification
                            object:nil
                             queue:[NSOperationQueue mainQueue]
                        usingBlock:^(__unused NSNotification *note) {
            // Não resetar CHZLoginAlreadyPresented ao retornar do segundo plano;
            // isso fazia a tela reaparecer a cada minimização do app.
            CHZPresentLoginWhenReady();
        }];

        [center addObserverForName:UIApplicationDidFinishLaunchingNotification
                            object:nil
                             queue:[NSOperationQueue mainQueue]
                        usingBlock:^(__unused NSNotification *note) {
            CHZPresentLoginWhenReady();
        }];

        // O Keychain pode sobreviver à exclusão da IPA. No primeiro
        // lançamento após uma instalação nova, descartar a credencial antiga
        // e exigir uma key nova.
        if (CHZFirstLaunchAfterInstall()) {
            [[CHZAuthManager sharedManager] clearSavedKey];
            CHZPresentLoginWhenReady();
        } else {
            // Nos lançamentos normais, reutilizar e validar a key salva.
            CHZValidateSavedKeyThenPresentIfNeeded();
        }
    });
}

@interface CHZLoginBootstrapMarker : NSObject
@end

@implementation CHZLoginBootstrapMarker

+ (void)load {
    CHZInstallLoginBootstrap();
}

@end

__attribute__((constructor))
static void CHZLoginBootstrapConstructor(void) {
    CHZInstallLoginBootstrap();
}
