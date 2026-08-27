#import <UIKit/UIKit.h>
#import "CHZLoginViewController.h"

static BOOL CHZLoginPresentationInProgress = NO;
static BOOL CHZLoginAlreadyPresented = NO;
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

static void CHZPresentLoginWhenReady(void) {
    if (CHZLoginAlreadyPresented || CHZLoginPresentationInProgress) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (CHZLoginAlreadyPresented || CHZLoginPresentationInProgress) return;

        UIApplication *application = [UIApplication sharedApplication];
        if (application.applicationState != UIApplicationStateActive) {
            CHZSchedulePresentation();
            return;
        }

        UIWindow *window = CHZFindWindow();
        UIViewController *top = CHZTopViewController(window.rootViewController);
        if (!window || !top || !top.viewIfLoaded.window) {
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
    if (CHZLoginAlreadyPresented) return;
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
            CHZLoginAlreadyPresented = NO;
            CHZPresentLoginWhenReady();
        }];

        [center addObserverForName:UIApplicationDidFinishLaunchingNotification
                            object:nil
                             queue:[NSOperationQueue mainQueue]
                        usingBlock:^(__unused NSNotification *note) {
            CHZPresentLoginWhenReady();
        }];

        CHZPresentLoginWhenReady();
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
