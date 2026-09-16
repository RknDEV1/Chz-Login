#import "CHZLoginViewController.h"
#import "CHZAuthManager.h"
#import <UIKit/UIKit.h>

@interface CHZLoginViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *keyField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIImageView *lockView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) CAGradientLayer *topGradient;
@property (nonatomic, strong) CAGradientLayer *bottomGradient;
@property (nonatomic, assign) BOOL loginFinishing;
@end

@implementation CHZLoginViewController

- (UIColor *)chzRed {
    return [UIColor colorWithRed:1.0 green:0.015 blue:0.075 alpha:1.0];
}

- (UIColor *)chzWhite {
    return [UIColor colorWithWhite:0.96 alpha:1.0];
}

- (UIColor *)chzMutedWhite {
    return [UIColor colorWithWhite:0.70 alpha:1.0];
}

- (UIImage *)chzImageNamed:(NSString *)name {
    NSBundle *frameworkBundle = [NSBundle bundleForClass:[self class]];
    NSString *resourcePath = [frameworkBundle pathForResource:@"CHZLoginResources" ofType:@"bundle"];
    NSBundle *resourceBundle = resourcePath ? [NSBundle bundleWithPath:resourcePath] : nil;
    UIImage *image = resourceBundle ? [UIImage imageNamed:name inBundle:resourceBundle compatibleWithTraitCollection:nil] : nil;
    if (image != nil) return image;
    image = [UIImage imageNamed:name inBundle:frameworkBundle compatibleWithTraitCollection:nil];
    if (image != nil) return image;
    return [UIImage imageNamed:name];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // A referência é uma composição escura; mantém o mesmo resultado no modo claro e escuro do sistema.
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.modalPresentationCapturesStatusBarAppearance = YES;
    self.view.backgroundColor = [UIColor colorWithRed:0.018 green:0.004 blue:0.008 alpha:1.0];
    self.view.clipsToBounds = YES;
    [self buildInterface];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chz_dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];

    // Não valide nem dispense a tela automaticamente na abertura.
    // A autenticação só começa após o usuário tocar em ENTRAR;
    // isso evita que uma key antiga no Keychain feche o modal antes da interação.
    self.keyField.text = @"";
    self.statusLabel.text = @"";
    self.statusLabel.hidden = YES;
    self.statusLabel.textColor = self.chzMutedWhite;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutReference];
}

- (void)buildInterface {
    CAGradientLayer *background = [CAGradientLayer layer];
    background.colors = @[
        (id)[UIColor colorWithRed:0.015 green:0.003 blue:0.006 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.15 green:0.005 blue:0.014 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.025 green:0.002 blue:0.006 alpha:1.0].CGColor
    ];
    background.locations = @[@0.0, @0.52, @1.0];
    background.startPoint = CGPointMake(0.0, 0.0);
    background.endPoint = CGPointMake(1.0, 1.0);
    background.name = @"RKNLoginBackground";
    [self.view.layer addSublayer:background];

    UIView *card = [[UIView alloc] initWithFrame:CGRectZero];
    card.tag = 7005;
    card.backgroundColor = [UIColor colorWithRed:0.035 green:0.008 blue:0.012 alpha:0.96];
    card.layer.cornerRadius = 22.0;
    card.layer.cornerCurve = kCACornerCurveContinuous;
    card.layer.borderWidth = 1.0;
    card.layer.borderColor = [self.chzRed colorWithAlphaComponent:0.34].CGColor;
    card.layer.shadowColor = UIColor.blackColor.CGColor;
    card.layer.shadowOpacity = 0.38;
    card.layer.shadowRadius = 22.0;
    card.layer.shadowOffset = CGSizeMake(0.0, 10.0);
    [self.view addSubview:card];

    self.lockView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"lock.fill"]];
    self.lockView.tag = 7016;
    self.lockView.tintColor = self.chzRed;
    self.lockView.contentMode = UIViewContentModeScaleAspectFit;
    self.lockView.accessibilityLabel = @"Cadeado";
    [self.view addSubview:self.lockView];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectZero];
    title.tag = 7017;
    title.text = @"ACESSO";
    title.textAlignment = NSTextAlignmentCenter;
    title.textColor = self.chzWhite;
    title.font = [UIFont systemFontOfSize:28.0 weight:UIFontWeightBold];
    [self.view addSubview:title];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.tag = 7006;
    label.text = @"KEY DE ACESSO";
    label.textColor = self.chzWhite;
    label.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
    [card addSubview:label];

    self.keyField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.keyField.tag = 7007;
    self.keyField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Digite sua key" attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:0.42 alpha:1.0]}];
    self.keyField.textColor = self.chzWhite;
    self.keyField.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightMedium];
    self.keyField.backgroundColor = [UIColor colorWithRed:0.10 green:0.018 blue:0.025 alpha:0.84];
    self.keyField.layer.cornerRadius = 13.0;
    self.keyField.layer.cornerCurve = kCACornerCurveContinuous;
    self.keyField.layer.borderWidth = 1.0;
    self.keyField.layer.borderColor = [self.chzRed colorWithAlphaComponent:0.30].CGColor;
    self.keyField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.keyField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.keyField.returnKeyType = UIReturnKeyDone;
    self.keyField.keyboardAppearance = UIKeyboardAppearanceDark;
    self.keyField.delegate = self;
    UIView *left = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
    UIImageView *keyIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"key.fill"]];
    keyIcon.frame = CGRectMake(15, 13, 20, 20);
    keyIcon.tintColor = self.chzRed;
    keyIcon.contentMode = UIViewContentModeScaleAspectFit;
    [left addSubview:keyIcon];
    self.keyField.leftView = left;
    self.keyField.leftViewMode = UITextFieldViewModeAlways;
    [card addSubview:self.keyField];

    self.loginButton = [self makeButton:@"ENTRAR" filled:YES action:@selector(loginTapped:)];
    self.loginButton.tag = 7009;
    [card addSubview:self.loginButton];

    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.activityIndicator.tag = 7014;
    self.activityIndicator.hidesWhenStopped = YES;
    self.activityIndicator.color = UIColor.whiteColor;
    [card addSubview:self.activityIndicator];

    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.statusLabel.tag = 7015;
    self.statusLabel.textColor = self.chzMutedWhite;
    self.statusLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 2;
    self.statusLabel.accessibilityIdentifier = @"chz.login.status";
    [card addSubview:self.statusLabel];

    UILabel *support = [[UILabel alloc] initWithFrame:CGRectZero];
    support.tag = 7010;
    support.text = @"SUPORTE";
    support.textColor = [UIColor colorWithWhite:0.58 alpha:1.0];
    support.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
    support.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:support];

    UIView *leftLine = [[UIView alloc] initWithFrame:CGRectZero];
    leftLine.tag = 7011;
    leftLine.backgroundColor = [self.chzRed colorWithAlphaComponent:0.28];
    [self.view addSubview:leftLine];

    UIView *rightLine = [[UIView alloc] initWithFrame:CGRectZero];
    rightLine.tag = 7012;
    rightLine.backgroundColor = [self.chzRed colorWithAlphaComponent:0.28];
    [self.view addSubview:rightLine];

    UIButton *discord = [UIButton buttonWithType:UIButtonTypeSystem];
    discord.tag = 7013;
    discord.accessibilityLabel = @"Suporte";
    discord.layer.cornerRadius = 22.0;
    discord.layer.borderWidth = 1.0;
    discord.layer.borderColor = [self.chzRed colorWithAlphaComponent:0.42].CGColor;
    discord.backgroundColor = [UIColor colorWithRed:0.10 green:0.018 blue:0.025 alpha:0.90];
    UIImage *discordImage = [self chzImageNamed:@"discord"];
    if (discordImage) {
        [discord setImage:[discordImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    } else {
        UIImage *fallback = [UIImage systemImageNamed:@"questionmark.circle.fill"];
        [discord setImage:[fallback imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        discord.tintColor = self.chzWhite;
    }
    discord.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [discord addTarget:self action:@selector(discordTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:discord];
}

- (UIButton *)makeButton:(NSString *)title filled:(BOOL)filled action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectZero;
    button.layer.cornerRadius = 14.0;
    button.layer.cornerCurve = kCACornerCurveContinuous;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = filled ? [UIColor colorWithWhite:1.0 alpha:0.28].CGColor : [UIColor colorWithWhite:0.92 alpha:0.22].CGColor;
    button.backgroundColor = filled ? [self.chzRed colorWithAlphaComponent:0.94] : [UIColor colorWithWhite:0.14 alpha:0.76];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:(filled ? 18.0 : 16.0) weight:UIFontWeightBold];
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    button.clipsToBounds = YES;
    if (filled) {
        button.layer.shadowColor = self.chzRed.CGColor;
        button.layer.shadowOpacity = 0.24;
        button.layer.shadowRadius = 13.0;
        button.layer.shadowOffset = CGSizeZero;
    }
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)layoutReference {
    CGFloat W = CGRectGetWidth(self.view.bounds);
    CGFloat H = CGRectGetHeight(self.view.bounds);
    if (W <= 0.0 || H <= 0.0) return;

    for (CALayer *layer in self.view.layer.sublayers) {
        if ([layer.name isEqualToString:@"RKNLoginBackground"]) {
            layer.frame = self.view.bounds;
        }
    }
    CGFloat safeTop = self.view.safeAreaInsets.top;
    CGFloat safeBottom = self.view.safeAreaInsets.bottom;
    CGFloat availableHeight = MAX(1.0, H - safeTop - safeBottom);
    CGFloat scale = MIN(1.0, MAX(0.82, availableHeight / 760.0));
    BOOL tablet = MIN(W, H) >= 600.0;
    CGFloat sideInset = tablet ? 44.0 : 24.0;
    CGFloat cardW = MIN(W - 2.0 * sideInset, tablet ? 520.0 : 360.0);
    CGFloat contentW = cardW - 48.0 * scale;
    CGFloat lockSize = (tablet ? 66.0 : 54.0) * scale;
    CGFloat titleY = safeTop + (tablet ? 58.0 : 74.0) * scale;
    UIImageView *lock = (UIImageView *)[self.view viewWithTag:7016];
    lock.frame = CGRectMake((W - lockSize) / 2.0, titleY, lockSize, lockSize);

    UILabel *title = (UILabel *)[self.view viewWithTag:7017];
    title.frame = CGRectMake(20.0, CGRectGetMaxY(lock.frame) + 10.0 * scale, W - 40.0, 38.0 * scale);
    title.font = [UIFont systemFontOfSize:(tablet ? 32.0 : 28.0) * scale weight:UIFontWeightBold];

    CGFloat cardY = CGRectGetMaxY(title.frame) + (tablet ? 28.0 : 24.0) * scale;
    CGFloat cardH = (tablet ? 292.0 : 250.0) * scale;
    UIView *card = [self.view viewWithTag:7005];
    card.frame = CGRectMake((W - cardW) / 2.0, cardY, cardW, cardH);

    CGFloat padding = 24.0 * scale;
    CGFloat labelH = 22.0 * scale;
    CGFloat fieldH = (tablet ? 64.0 : 52.0) * scale;
    CGFloat buttonH = (tablet ? 64.0 : 52.0) * scale;
    CGFloat gap = 15.0 * scale;
    CGFloat contentHeight = labelH + 8.0 * scale + fieldH + gap + buttonH;
    CGFloat contentTop = MAX(22.0 * scale, (cardH - contentHeight - 22.0 * scale) / 2.0);

    UILabel *label = (UILabel *)[card viewWithTag:7006];
    label.frame = CGRectMake(padding, contentTop, contentW, labelH);

    UITextField *field = (UITextField *)[card viewWithTag:7007];
    CGFloat fieldY = CGRectGetMaxY(label.frame) + 8.0 * scale;
    field.frame = CGRectMake(padding, fieldY, contentW, fieldH);
    field.layer.cornerRadius = 13.0 * scale;

    UIButton *login = (UIButton *)[card viewWithTag:7009];
    CGFloat loginY = CGRectGetMaxY(field.frame) + gap;
    login.frame = CGRectMake(padding, loginY, contentW, buttonH);
    login.layer.cornerRadius = 14.0 * scale;
    login.titleLabel.font = [UIFont systemFontOfSize:(tablet ? 21.0 : 18.0) * scale weight:UIFontWeightBold];

    UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[card viewWithTag:7014];
    indicator.center = CGPointMake(CGRectGetMidX(login.frame), CGRectGetMidY(login.frame));

    UILabel *status = (UILabel *)[card viewWithTag:7015];
    status.frame = CGRectMake(padding, CGRectGetMaxY(login.frame) + 7.0 * scale, contentW, 30.0 * scale);

    UILabel *support = (UILabel *)[self.view viewWithTag:7010];
    UIView *leftLine = [self.view viewWithTag:7011];
    UIView *rightLine = [self.view viewWithTag:7012];
    UIButton *discord = (UIButton *)[self.view viewWithTag:7013];
    CGFloat supportY = CGRectGetMaxY(card.frame) + (tablet ? 42.0 : 28.0) * scale;
    CGFloat lineGap = tablet ? 82.0 : 68.0;
    support.frame = CGRectMake((W - 100.0) / 2.0, supportY, 100.0, 22.0 * scale);
    leftLine.frame = CGRectMake(sideInset + 8.0, supportY + 10.0 * scale, MAX(0.0, W / 2.0 - lineGap), 1.0);
    rightLine.frame = CGRectMake(W / 2.0 + lineGap, supportY + 10.0 * scale, MAX(0.0, W / 2.0 - lineGap - sideInset - 8.0), 1.0);
    CGFloat icon = (tablet ? 64.0 : 46.0) * scale;
    discord.frame = CGRectMake((W - icon) / 2.0, supportY + 32.0 * scale, icon, icon);
    discord.layer.cornerRadius = icon / 2.0;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)chz_dismissKeyboard { [self.view endEditing:YES]; }
- (BOOL)textFieldShouldReturn:(UITextField *)textField { [textField resignFirstResponder]; return YES; }

- (void)loginTapped:(UIButton *)sender {
    NSString *key = [self.keyField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (key.length == 0 || self.activityIndicator.isAnimating) {
        self.statusLabel.hidden = NO;
        self.statusLabel.text = @"Digite sua key para continuar.";
        self.statusLabel.textColor = [self.chzRed colorWithAlphaComponent:0.95];
        return;
    }

    self.loginFinishing = NO;
    sender.enabled = NO;
    self.keyField.enabled = NO;
    self.statusLabel.hidden = NO;
    self.statusLabel.text = @"Validando sua key…";
    self.statusLabel.textColor = self.chzMutedWhite;
    [self.activityIndicator startAnimating];

    [[CHZAuthManager sharedManager] loginWithKey:key success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            [self finishLogin];
        });
    } failure:^(NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            self.loginFinishing = NO;
            sender.enabled = YES;
            self.keyField.enabled = YES;
            NSString *safe = ([message isKindOfClass:[NSString class]] && message.length) ? message : @"Não foi possível validar a key. Verifique a conexão e tente novamente.";
            self.statusLabel.text = safe;
            self.statusLabel.textColor = [self.chzRed colorWithAlphaComponent:0.95];
            [self.keyField becomeFirstResponder];
        });
    }];
}

- (void)discordTapped:(__unused UIButton *)sender {
    NSURL *url = [NSURL URLWithString:@"https://discord.gg/BZ53Fsgr"];
    if (url) [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void)finishLogin {
    if (self.loginFinishing) {
        return;
    }

    self.loginFinishing = YES;
    self.loginButton.enabled = NO;
    self.keyField.enabled = NO;
    self.statusLabel.text = @"Acesso autorizado.";
    self.statusLabel.textColor = [UIColor colorWithRed:0.25 green:0.90 blue:0.55 alpha:1.0];

    // O app hospedeiro usa esta notificação para atualizar a sessão em memória.
    // O post ocorre antes da dispensa para evitar corrida entre UIKit e SwiftUI.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CHZLoginDidAuthenticateNotification" object:nil];

    // A transição ocorre na main thread e somente uma vez. Não dependemos de
    // presentingViewController, pois fullScreenCover pode usar um host intermediário.
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isBeingDismissed && self.presentedViewController == nil) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    });
}

@end
