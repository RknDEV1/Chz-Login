#import <UIKit/UIKit.h>
#import "CHZLoginViewController.h"

static BOOL CHZLoginIsVisibleOrPresented = NO;
static BOOL CHZBootstrapInstalled = NO;

static UIWindow *CHZFindActiveWindow(void) {
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive) continue;
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;

            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow && window.rootViewController) return window;
            }
            for (UIWindow *window in windowScene.windows) {
                if (!window.hidden && window.alpha > 0.0 && window.rootViewController) return window;
            }
        }
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if (window.isKeyWindow && window.rootViewController) return window;
    }
#pragma clang diagnostic pop

    return nil;
}

static UIViewController *CHZVisibleController(UIViewController *controller) {
    if (!controller) return nil;
    if (controller.presentedViewController && !controller.presentedViewController.isBeingDismissed) {
        return CHZVisibleController(controller.presentedViewController);
    }
    if ([controller isKindOfClass:[UINavigationController class]]) {
        return CHZVisibleController(((UINavigationController *)controller).visibleViewController);
    }
    if ([controller isKindOfClass:[UITabBarController class]]) {
        return CHZVisibleController(((UITabBarController *)controller).selectedViewController);
    }
    return controller;
}

static void CHZTryPresentLogin(void);

static void CHZScheduleRetry(void) {
    if (CHZLoginIsVisibleOrPresented) return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CHZTryPresentLogin();
    });
}

static void CHZTryPresentLogin(void) {
    if (CHZLoginIsVisibleOrPresented) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (CHZLoginIsVisibleOrPresented) return;
        if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
            CHZScheduleRetry();
            return;
        }

        UIWindow *window = CHZFindActiveWindow();
        UIViewController *root = window.rootViewController;
        UIViewController *visible = CHZVisibleController(root);
        if (!window || !root || !visible) {
            CHZScheduleRetry();
            return;
        }

        if ([visible isKindOfClass:[CHZLoginViewController class]]) {
            CHZLoginIsVisibleOrPresented = YES;
            return;
        }

        CHZLoginViewController *login = [[CHZLoginViewController alloc] init];
        login.modalPresentationStyle = UIModalPresentationFullScreen;
        CHZLoginIsVisibleOrPresented = YES;
        [visible presentViewController:login animated:NO completion:nil];
    });
}

static void CHZInstallBootstrap(void) {
    if (CHZBootstrapInstalled) return;
    CHZBootstrapInstalled = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserverForName:UIApplicationDidBecomeActiveNotification
                            object:nil
                             queue:[NSOperationQueue mainQueue]
                        usingBlock:^(__unused NSNotification *notification) {
            CHZLoginIsVisibleOrPresented = NO;
            CHZTryPresentLogin();
        }];

        [center addObserverForName:UIApplicationWillEnterForegroundNotification
                            object:nil
                             queue:[NSOperationQueue mainQueue]
                        usingBlock:^(__unused NSNotification *notification) {
            CHZLoginIsVisibleOrPresented = NO;
            CHZTryPresentLogin();
        }];

        CHZTryPresentLogin();
    });
}

@interface CHZLoginBootstrapMarker : NSObject
@end

@implementation CHZLoginBootstrapMarker

+ (void)load {
    CHZInstallBootstrap();
}

@end

__attribute__((constructor))
static void CHZLoginBootstrapConstructor(void) {
    CHZInstallBootstrap();
}
