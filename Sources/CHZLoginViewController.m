#import "CHZLoginViewController.h"
#import "CHZAuthManager.h"

@interface CHZLoginViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *keyField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIActivityIndicatorView *indicator;
@property (nonatomic, strong) CAGradientLayer *backgroundGradient;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *cardView;
@end

@implementation CHZLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.004 green:0.003 blue:0.010 alpha:1.0];
    [self buildModernInterface];

    UITapGestureRecognizer *dismissKeyboardTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chz_dismissKeyboard)];
    dismissKeyboardTap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:dismissKeyboardTap];

    [[CHZAuthManager sharedManager] validateSavedKeyWithSuccess:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishLogin];
        });
    } failure:^(__unused NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.keyField.text = @"";
            self.keyField.enabled = YES;
            self.loginButton.enabled = YES;
        });
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.backgroundGradient.frame = self.view.bounds;
}

- (void)buildModernInterface {
    self.backgroundGradient = [CAGradientLayer layer];
    self.backgroundGradient.colors = @[
        (id)[UIColor colorWithRed:0.004 green:0.002 blue:0.012 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.035 green:0.006 blue:0.085 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.006 green:0.004 blue:0.018 alpha:1.0].CGColor
    ];
    self.backgroundGradient.locations = @[@0.0, @0.48, @1.0];
    [self.view.layer insertSublayer:self.backgroundGradient atIndex:0];

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];

    UIView *content = [[UIView alloc] init];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:content];

    UILabel *brandTop = [[UILabel alloc] init];
    brandTop.translatesAutoresizingMaskIntoConstraints = NO;
    brandTop.text = @"Room";
    brandTop.textColor = [UIColor colorWithRed:0.88 green:0.82 blue:1.0 alpha:1.0];
    brandTop.font = [UIFont fontWithName:@"Copperplate-Bold" size:42.0] ?: [UIFont systemFontOfSize:42.0 weight:UIFontWeightBlack];
    brandTop.textAlignment = NSTextAlignmentCenter;
    brandTop.adjustsFontSizeToFitWidth = YES;
    brandTop.minimumScaleFactor = 0.72;
    [content addSubview:brandTop];

    UILabel *brandBottom = [[UILabel alloc] init];
    brandBottom.translatesAutoresizingMaskIntoConstraints = NO;
    brandBottom.text = @"Injection";
    brandBottom.textColor = [UIColor colorWithRed:0.68 green:0.34 blue:1.0 alpha:1.0];
    brandBottom.font = [UIFont fontWithName:@"Copperplate-Bold" size:34.0] ?: [UIFont systemFontOfSize:34.0 weight:UIFontWeightBold];
    brandBottom.textAlignment = NSTextAlignmentCenter;
    brandBottom.adjustsFontSizeToFitWidth = YES;
    brandBottom.minimumScaleFactor = 0.62;
    [content addSubview:brandBottom];

    UILabel *subtitle = [[UILabel alloc] init];
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;
    subtitle.text = @"Acesse sua conta";
    subtitle.textColor = [UIColor colorWithWhite:0.78 alpha:1.0];
    subtitle.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightMedium];
    subtitle.textAlignment = NSTextAlignmentCenter;
    [content addSubview:subtitle];

    self.cardView = [[UIView alloc] init];
    self.cardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardView.backgroundColor = [UIColor colorWithWhite:0.055 alpha:0.88];
    self.cardView.layer.cornerRadius = 24.0;
    self.cardView.layer.borderWidth = 1.0;
    self.cardView.layer.borderColor = [UIColor colorWithRed:0.58 green:0.20 blue:1.0 alpha:0.62].CGColor;
    self.cardView.layer.shadowColor = [UIColor colorWithRed:0.48 green:0.08 blue:1.0 alpha:0.70].CGColor;
    self.cardView.layer.shadowOpacity = 0.35;
    self.cardView.layer.shadowRadius = 22.0;
    self.cardView.layer.shadowOffset = CGSizeMake(0, 10);
    [content addSubview:self.cardView];

    UILabel *fieldLabel = [[UILabel alloc] init];
    fieldLabel.translatesAutoresizingMaskIntoConstraints = NO;
    fieldLabel.text = @"KEY DE ACESSO";
    fieldLabel.textColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    fieldLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
    [self.cardView addSubview:fieldLabel];

    self.keyField = [[UITextField alloc] init];
    self.keyField.translatesAutoresizingMaskIntoConstraints = NO;
    self.keyField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Digite sua key" attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.43 alpha:1.0]}];
    self.keyField.textColor = [UIColor whiteColor];
    self.keyField.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightMedium];
    self.keyField.backgroundColor = [UIColor colorWithWhite:0.02 alpha:0.75];
    self.keyField.layer.cornerRadius = 14.0;
    self.keyField.layer.borderWidth = 1.0;
    self.keyField.layer.borderColor = [UIColor colorWithWhite:0.35 alpha:0.65].CGColor;
    self.keyField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.keyField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.keyField.spellCheckingType = UITextSpellCheckingTypeNo;
    self.keyField.returnKeyType = UIReturnKeyDone;
    self.keyField.delegate = self;
    self.keyField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 1)];
    self.keyField.leftViewMode = UITextFieldViewModeAlways;
    [self.cardView addSubview:self.keyField];

    UIButton *didButton = [self buttonWithTitle:@"OBTER DID" action:@selector(didTapped:) filled:NO];
    self.loginButton = [self buttonWithTitle:@"ENTRAR" action:@selector(loginTapped:) filled:YES];
    UIButton *storeButton = [self buttonWithTitle:@"LOJA" action:@selector(storeTapped:) filled:NO];
    UIButton *supportButton = [self buttonWithTitle:@"SUPORTE" action:@selector(supportTapped:) filled:NO];
    [self.cardView addSubview:didButton];
    [self.cardView addSubview:self.loginButton];

    UIStackView *links = [[UIStackView alloc] initWithArrangedSubviews:@[storeButton, supportButton]];
    links.translatesAutoresizingMaskIntoConstraints = NO;
    links.axis = UILayoutConstraintAxisHorizontal;
    links.spacing = 12.0;
    links.distribution = UIStackViewDistributionFillEqually;
    [content addSubview:links];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

        [content.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor],
        [content.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor constant:-20.0],
        [content.leadingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.trailingAnchor],
        [content.widthAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor],

        [brandTop.topAnchor constraintEqualToAnchor:content.topAnchor constant:34.0],
        [brandTop.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:32.0],
        [brandTop.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-32.0],
        [brandTop.heightAnchor constraintEqualToConstant:56.0],

        [brandBottom.topAnchor constraintEqualToAnchor:brandTop.bottomAnchor constant:-2.0],
        [brandBottom.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:32.0],
        [brandBottom.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-32.0],
        [brandBottom.heightAnchor constraintEqualToConstant:50.0],

        [subtitle.topAnchor constraintEqualToAnchor:brandBottom.bottomAnchor constant:8.0],
        [subtitle.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:28.0],
        [subtitle.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-28.0],
        [subtitle.heightAnchor constraintEqualToConstant:26.0],

        [self.cardView.topAnchor constraintEqualToAnchor:subtitle.bottomAnchor constant:24.0],
        [self.cardView.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:24.0],
        [self.cardView.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-24.0],
        [self.cardView.heightAnchor constraintEqualToConstant:354.0],

        [fieldLabel.topAnchor constraintEqualToAnchor:self.cardView.topAnchor constant:28.0],
        [fieldLabel.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:24.0],
        [fieldLabel.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-24.0],
        [fieldLabel.heightAnchor constraintEqualToConstant:20.0],

        [self.keyField.topAnchor constraintEqualToAnchor:fieldLabel.bottomAnchor constant:10.0],
        [self.keyField.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:24.0],
        [self.keyField.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-24.0],
        [self.keyField.heightAnchor constraintEqualToConstant:56.0],

        [didButton.topAnchor constraintEqualToAnchor:self.keyField.bottomAnchor constant:18.0],
        [didButton.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:24.0],
        [didButton.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-24.0],
        [didButton.heightAnchor constraintEqualToConstant:50.0],

        [self.loginButton.topAnchor constraintEqualToAnchor:didButton.bottomAnchor constant:14.0],
        [self.loginButton.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:24.0],
        [self.loginButton.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-24.0],
        [self.loginButton.heightAnchor constraintEqualToConstant:56.0],

        [links.topAnchor constraintEqualToAnchor:self.cardView.bottomAnchor constant:18.0],
        [links.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:24.0],
        [links.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-24.0],
        [links.heightAnchor constraintEqualToConstant:52.0],
        [links.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-20.0]
    ]];
}

- (UIButton *)buttonWithTitle:(NSString *)title action:(SEL)action filled:(BOOL)filled {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithWhite:0.55 alpha:1.0] forState:UIControlStateDisabled];
    button.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
    button.layer.cornerRadius = 14.0;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = [UIColor colorWithRed:0.68 green:0.32 blue:1.0 alpha:0.92].CGColor;
    button.backgroundColor = filled ? [UIColor colorWithRed:0.38 green:0.08 blue:0.78 alpha:1.0] : [UIColor colorWithWhite:0.04 alpha:0.82];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)chz_dismissKeyboard {
    [self.view endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)loginTapped:(UIButton *)sender {
    [self chz_dismissKeyboard];
    NSString *key = [self.keyField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (key.length == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Key obrigatória" message:@"Digite sua key de acesso para continuar." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    sender.enabled = NO;
    [[CHZAuthManager sharedManager] loginWithKey:key success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            sender.enabled = YES;
            [self finishLogin];
        });
    } failure:^(NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            sender.enabled = YES;
            NSString *safeMessage = ([message isKindOfClass:[NSString class]] && message.length > 0) ? message : @"Não foi possível validar a key. Verifique a conexão e tente novamente.";
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Login não autorizado" message:safeMessage preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        });
    }];
}

- (void)didTapped:(__unused UIButton *)sender {
    NSURL *url = [NSURL URLWithString:@"https://discord.gg/room222"];
    if (url) [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void)storeTapped:(__unused UIButton *)sender { [self openStoreLink]; }
- (void)supportTapped:(__unused UIButton *)sender { [self openStoreLink]; }

- (void)openStoreLink {
    NSURL *url = [NSURL URLWithString:@"https://discord.gg/dukkKRvz"];
    if (url) [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void)finishLogin {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
