#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>

#import "CHZLoginViewController.h"

static BOOL CHZLoginWasPresented = NO;
static NSUInteger CHZPresentationAttempts = 0;
static const NSUInteger CHZMaximumPresentationAttempts = 120;

static UIWindow *CHZActiveWindow(void) {
    UIApplication *application = UIApplication.sharedApplication;
    UIWindow *fallbackWindow = nil;

    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in application.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;

            UIWindowScene *windowScene = (UIWindowScene *)scene;
            if (windowScene.activationState == UISceneActivationStateUnattached ||
                windowScene.activationState == UISceneActivationStateBackground) {
                continue;
            }

            for (UIWindow *candidate in windowScene.windows) {
                if (!candidate.hidden && candidate.alpha > 0.0 && candidate.windowLevel == UIWindowLevelNormal) {
                    if (candidate.isKeyWindow) return candidate;
                    if (!fallbackWindow) fallbackWindow = candidate;
                }
            }
        }
    }

    if (!fallbackWindow) {
        for (UIWindow *candidate in application.windows) {
            if (!candidate.hidden && candidate.alpha > 0.0 && candidate.windowLevel == UIWindowLevelNormal) {
                if (candidate.isKeyWindow) return candidate;
                if (!fallbackWindow) fallbackWindow = candidate;
            }
        }
    }

    return fallbackWindow;
}

static UIViewController *CHZTopViewController(UIViewController *root) {
    UIViewController *top = root;

    while (top.presentedViewController && !top.presentedViewController.isBeingDismissed) {
        top = top.presentedViewController;
    }

    if ([top isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigation = (UINavigationController *)top;
        if (navigation.visibleViewController) return CHZTopViewController(navigation.visibleViewController);
    }

    if ([top isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabs = (UITabBarController *)top;
        if (tabs.selectedViewController) return CHZTopViewController(tabs.selectedViewController);
    }

    return top;
}

static void CHZTryPresentLogin(void);

static void CHZScheduleAnotherPresentationAttempt(void) {
    if (CHZLoginWasPresented || CHZPresentationAttempts >= CHZMaximumPresentationAttempts) return;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CHZTryPresentLogin();
    });
}

static void CHZTryPresentLogin(void) {
    if (CHZLoginWasPresented) return;
    CHZPresentationAttempts += 1;

    UIWindow *window = CHZActiveWindow();
    UIViewController *root = window.rootViewController;
    if (!window || !root || !root.viewIfLoaded.window) {
        CHZScheduleAnotherPresentationAttempt();
        return;
    }

    UIViewController *top = CHZTopViewController(root);
    if (!top || top.isBeingDismissed || top.isBeingPresented) {
        CHZScheduleAnotherPresentationAttempt();
        return;
    }

    if ([top isKindOfClass:[CHZLoginViewController class]] ||
        [top.presentedViewController isKindOfClass:[CHZLoginViewController class]]) {
        CHZLoginWasPresented = YES;
        return;
    }

    CHZLoginViewController *login = [[CHZLoginViewController alloc] init];
    login.modalPresentationStyle = UIModalPresentationFullScreen;
    CHZLoginWasPresented = YES;

    [top presentViewController:login animated:NO completion:^{
        NSLog(@"[CHZLogin] tela de login apresentada na inicialização");
    }];
}

static void CHZStartLoginPresentation(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] addObserverForName:UISceneDidActivateNotification
                                                            object:nil
                                                             queue:[NSOperationQueue mainQueue]
                                                        usingBlock:^(__unused NSNotification *notification) {
            CHZTryPresentLogin();
        }];

        CHZTryPresentLogin();
    });
}

__attribute__((constructor))
static void CHZLoginBootstrapConstructor(void) {
    NSLog(@"[CHZLogin] bootstrap carregado; aguardando a janela do app");
    CHZStartLoginPresentation();
}
