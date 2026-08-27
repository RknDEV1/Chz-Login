#import "CHZLoginViewController.h"
#import "CHZAuthManager.h"

@interface CHZLoginViewController ()
@property (nonatomic, strong) UITextField *keyField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIActivityIndicatorView *indicator;
@end

@implementation CHZLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.015 green:0.015 blue:0.02 alpha:1.0];
    [self buildInterface];
    [[CHZAuthManager sharedManager] validateSavedKeyWithSuccess:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishLogin];
        });
    } failure:^(__unused NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.keyField.text = @"";
        });
    }];
}

- (void)buildInterface {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentFill;
    stack.spacing = 18.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stack];

    UILabel *logoTitle = [[UILabel alloc] init];
    logoTitle.text = @"CHZ PRIV";
    logoTitle.textColor = [UIColor whiteColor];
    logoTitle.font = [UIFont boldSystemFontOfSize:36.0];
    logoTitle.textAlignment = NSTextAlignmentCenter;

    UILabel *subtitle = [[UILabel alloc] init];
    subtitle.text = @"Acesse sua conta";
    subtitle.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
    subtitle.font = [UIFont systemFontOfSize:17.0];
    subtitle.textAlignment = NSTextAlignmentCenter;

    UILabel *label = [[UILabel alloc] init];
    label.text = @"KEY DE ACESSO";
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:15.0];

    self.keyField = [[UITextField alloc] init];
    self.keyField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Digite sua key" attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.45 alpha:1.0]}];
    self.keyField.textColor = [UIColor whiteColor];
    self.keyField.backgroundColor = [UIColor colorWithWhite:0.08 alpha:1.0];
    self.keyField.layer.cornerRadius = 12.0;
    self.keyField.layer.borderWidth = 1.0;
    self.keyField.layer.borderColor = [UIColor colorWithRed:0.9 green:0.05 blue:0.08 alpha:0.75].CGColor;
    self.keyField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.keyField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.keyField.returnKeyType = UIReturnKeyDone;
    self.keyField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14, 1)];
    self.keyField.leftViewMode = UITextFieldViewModeAlways;
    [self.keyField.heightAnchor constraintEqualToConstant:54.0].active = YES;

    self.loginButton = [self buttonWithTitle:@"ENTRAR" action:@selector(loginTapped:) filled:YES];
    UIButton *storeButton = [self buttonWithTitle:@"LOJA" action:@selector(storeTapped:) filled:NO];
    UIButton *supportButton = [self buttonWithTitle:@"SUPORTE" action:@selector(supportTapped:) filled:NO];

    UIStackView *links = [[UIStackView alloc] initWithArrangedSubviews:@[storeButton, supportButton]];
    links.axis = UILayoutConstraintAxisHorizontal;
    links.spacing = 12.0;
    links.distribution = UIStackViewDistributionFillEqually;

    [stack addArrangedSubview:logoTitle];
    [stack addArrangedSubview:subtitle];
    [stack addArrangedSubview:[[UIView alloc] init]];
    [stack addArrangedSubview:label];
    [stack addArrangedSubview:self.keyField];
    [stack addArrangedSubview:self.loginButton];
    [stack addArrangedSubview:links];

    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:28.0],
        [stack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-28.0],
        [stack.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
}

- (UIButton *)buttonWithTitle:(NSString *)title action:(SEL)action filled:(BOOL)filled {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    button.layer.cornerRadius = 12.0;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = [UIColor colorWithRed:0.9 green:0.05 blue:0.08 alpha:1.0].CGColor;
    button.backgroundColor = filled ? [UIColor colorWithRed:0.95 green:0.03 blue:0.05 alpha:1.0] : [UIColor colorWithWhite:0.06 alpha:1.0];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button.heightAnchor constraintEqualToConstant:52.0].active = YES;
    return button;
}

- (void)loginTapped:(UIButton *)sender {
    sender.enabled = NO;
    [[CHZAuthManager sharedManager] loginWithKey:self.keyField.text success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            sender.enabled = YES;
            [self finishLogin];
        });
    } failure:^(NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            sender.enabled = YES;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Login não autorizado" message:message preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        });
    }];
}

- (void)storeTapped:(__unused UIButton *)sender { [self openStoreLink]; }
- (void)supportTapped:(__unused UIButton *)sender { [self openStoreLink]; }

- (void)openStoreLink {
    NSURL *url = [NSURL URLWithString:@"https://discord.gg/dukkKRvz"];
    if (url) [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void)finishLogin {
    // Substituir por uma chamada ao controlador/menu original da aplicação.
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
