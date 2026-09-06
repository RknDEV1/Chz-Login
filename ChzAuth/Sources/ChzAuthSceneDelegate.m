#import <UIKit/UIKit.h>
#import "CHZLoginViewController.h"

@interface ChzAuthRootViewController : UIViewController
@property (nonatomic, assign) BOOL loginWasPresented;
@end

@implementation ChzAuthRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.loginWasPresented || self.presentedViewController != nil) return;

    self.loginWasPresented = YES;
    CHZLoginViewController *login = [CHZLoginViewController new];
    login.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:login animated:NO completion:nil];
}

@end

@interface ChzAuthSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation ChzAuthSceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) return;

    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.rootViewController = [ChzAuthRootViewController new];
    [self.window makeKeyAndVisible];
}

@end
