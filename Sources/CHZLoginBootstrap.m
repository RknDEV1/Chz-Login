// ... código atual do CHZLoginBootstrap.m ...

__attribute__((constructor))
static void CHZTestConstructor(void) {
    NSLog(@"[CHZ TEST] DYLIB CARREGOU");

    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[CHZ TEST] MAIN QUEUE OK");

        UIWindow *window = nil;

        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if (![scene isKindOfClass:[UIWindowScene class]]) continue;

                UIWindowScene *ws = (UIWindowScene *)scene;

                for (UIWindow *w in ws.windows) {
                    if (w.isKeyWindow) {
                        window = w;
                        break;
                    }
                }

                if (window) break;
            }
        }

        NSLog(@"[CHZ TEST] WINDOW = %@", window);

        if (!window.rootViewController) {
            NSLog(@"[CHZ TEST] ROOT VC NAO ENCONTRADO");
            return;
        }

        NSLog(@"[CHZ TEST] ROOT VC = %@", window.rootViewController);
    });
}
