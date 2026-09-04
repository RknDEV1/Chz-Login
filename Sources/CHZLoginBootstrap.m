#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>

#import "CHZLoginViewController.h"

static void CHZShowLogin(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[CHZ TEST] iniciou apresentação");

        UIWindow *window = nil;

        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if (![scene isKindOfClass:[UIWindowScene class]]) {
                    continue;
                }

                UIWindowScene *windowScene = (UIWindowScene *)scene;

                for (UIWindow *candidate in windowScene.windows) {
                    if (candidate.isKeyWindow &&
                        !candidate.hidden &&
                        candidate.alpha > 0.0) {
                        window = candidate;
                        break;
                    }
                }

                if (window) {
                    break;
                }
            }
        }

        if (!window) {
            NSLog(@"[CHZ TEST] nenhuma window encontrada");
            return;
        }

        NSLog(@"[CHZ TEST] window encontrada: %@", window);

        UIViewController *root = window.rootViewController;

        if (!root) {
            NSLog(@"[CHZ TEST] rootViewController inexistente");
            return;
        }

        UIViewController *top = root;

        while (top.presentedViewController) {
            top = top.presentedViewController;
        }

        NSLog(@"[CHZ TEST] apresentando sobre: %@", top);

        CHZLoginViewController *login =
            [[CHZLoginViewController alloc] init];

        login.modalPresentationStyle = UIModalPresentationFullScreen;

        [top presentViewController:login
                           animated:NO
                         completion:^{
            NSLog(@"[CHZ TEST] LOGIN APRESENTADO");
        }];
    });
}

__attribute__((constructor))
static void CHZLoginBootstrapConstructor(void) {
    NSLog(@"[CHZ TEST] DYLIB CARREGOU");

    dispatch_async(dispatch_get_main_queue(), ^{
        CHZShowLogin();
    });
}
