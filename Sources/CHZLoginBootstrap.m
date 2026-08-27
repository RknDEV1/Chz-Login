#import <UIKit/UIKit.h>
#import "CHZLoginViewController.h"

static BOOL CHZLoginWasPresented = NO;

static UIWindow *CHZActiveWindow(void) {
    if (@available(iOS 13.0, *)) {
        NSSet<UIScene *> *scenes = [UIApplication sharedApplication].connectedScenes;
        for (UIScene *scene in scenes) {
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

static UIViewController *CHZTopController(UIViewController *controller) {
    if (controller.presentedViewController && !controller.presentedViewController.isBeingDismissed) {
        return CHZTopController(controller.presentedViewController);
    }
    if ([controller isKindOfClass:[UINavigationController class]]) {
        return CHZTopController(((UINavigationController *)controller).visibleViewController);
    }
    if ([controller isKindOfClass:[UITabBarController class]]) {
        return CHZTopController(((UITabBarController *)controller).selectedViewController);
    }
    return controller;
}

static void CHZPresentLoginIfPossible(void);

static void CHZRetryPresentation(void) {
    if (CHZLoginWasPresented) return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CHZPresentLoginIfPossible();
    });
}

static void CHZPresentLoginIfPossible(void) {
    if (CHZLoginWasPresented) return;

    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    if (state != UIApplicationStateActive) {
        CHZRetryPresentation();
        return;
    }

    UIWindow *window = CHZActiveWindow();
    UIViewController *root = window.rootViewController;
    if (!window || !root) {
        CHZRetryPresentation();
        return;
    }

    UIViewController *top = CHZTopController(root);
    if ([top isKindOfClass:[CHZLoginViewController class]]) {
        CHZLoginWasPresented = YES;
        return;
    }

    CHZLoginWasPresented = YES;
    CHZLoginViewController *login = [[CHZLoginViewController alloc] init];
    login.modalPresentationStyle = UIModalPresentationFullScreen;
    [top presentViewController:login animated:NO completion:nil];
}

__attribute__((constructor))
static void CHZLoginBootstrap(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(__unused NSNotification *notification) {
            CHZPresentLoginIfPossible();
        }];
        CHZPresentLoginIfPossible();
    });
}
