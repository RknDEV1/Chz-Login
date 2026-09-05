#import "CHZLoginViewController.h"
#import "CHZAuthManager.h"
#import <UIKit/UIKit.h>

@interface CHZLoginViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *keyField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIButton *didButton;
@property (nonatomic, strong) UIImageView *logoView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) CAGradientLayer *topGradient;
@property (nonatomic, strong) CAGradientLayer *bottomGradient;
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

- (void)viewDidLoad {
    [super viewDidLoad];

    // A referência é uma composição escura; mantém o mesmo resultado no modo claro e escuro do sistema.
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.modalPresentationCapturesStatusBarAppearance = YES;
    self.view.backgroundColor = UIColor.blackColor;
    self.view.clipsToBounds = YES;
    [self buildInterface];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chz_dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];

    // Não valide nem dispense a tela automaticamente na abertura.
    // A autenticação só começa após o usuário tocar em ENTRAR;
    // isso evita que uma key antiga no Keychain feche o modal antes da interação.
    self.keyField.text = @"";
    self.statusLabel.text = @"Digite sua key para continuar.";
    self.statusLabel.textColor = self.chzMutedWhite;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutReference];
}

- (void)buildInterface {
    self.topGradient = [CAGradientLayer layer];
    self.topGradient.colors = @[
        (id)[UIColor clearColor].CGColor,
        (id)[self.chzRed colorWithAlphaComponent:0.22].CGColor,
        (id)[UIColor clearColor].CGColor
    ];
    self.topGradient.startPoint = CGPointMake(0.0, 0.5);
    self.topGradient.endPoint = CGPointMake(1.0, 0.5);
    [self.view.layer addSublayer:self.topGradient];

    self.bottomGradient = [CAGradientLayer layer];
    self.bottomGradient.colors = @[
        (id)[UIColor clearColor].CGColor,
        (id)[self.chzRed colorWithAlphaComponent:0.16].CGColor,
        (id)[UIColor clearColor].CGColor
    ];
    self.bottomGradient.startPoint = CGPointMake(0.0, 0.5);
    self.bottomGradient.endPoint = CGPointMake(1.0, 0.5);
    [self.view.layer addSublayer:self.bottomGradient];

    UIView *topGlow = [[UIView alloc] initWithFrame:CGRectZero];
    topGlow.tag = 7001;
    topGlow.backgroundColor = UIColor.clearColor;
    topGlow.layer.borderColor = [self.chzRed colorWithAlphaComponent:0.70].CGColor;
    topGlow.layer.borderWidth = 1.3;
    topGlow.layer.cornerRadius = 190.0;
    topGlow.layer.shadowColor = self.chzRed.CGColor;
    topGlow.layer.shadowOpacity = 0.55;
    topGlow.layer.shadowRadius = 18.0;
    topGlow.layer.shadowOffset = CGSizeZero;
    [self.view addSubview:topGlow];

    UIView *card = [[UIView alloc] initWithFrame:CGRectZero];
    card.tag = 7005;
    card.backgroundColor = [UIColor colorWithWhite:0.015 alpha:0.94];
    card.layer.cornerRadius = 31.0;
    card.layer.cornerCurve = kCACornerCurveContinuous;
    card.layer.borderWidth = 1.15;
    card.layer.borderColor = [self.chzRed colorWithAlphaComponent:0.88].CGColor;
    card.layer.shadowColor = self.chzRed.CGColor;
    card.layer.shadowOpacity = 0.23;
    card.layer.shadowRadius = 26.0;
    card.layer.shadowOffset = CGSizeZero;
    [self.view addSubview:card];

    UILabel *chz = [[UILabel alloc] initWithFrame:CGRectZero];
    chz.tag = 7002;
    chz.text = @"CHZ";
    chz.textColor = self.chzRed;
    chz.font = [UIFont italicSystemFontOfSize:52.0];
    chz.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:chz];

    UILabel *priv = [[UILabel alloc] initWithFrame:CGRectZero];
    priv.tag = 7003;
    priv.text = @"PRIV";
    priv.textColor = self.chzWhite;
    priv.font = [UIFont italicSystemFontOfSize:52.0];
    priv.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:priv];

    self.logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CHZPrivLogo"]];
    self.logoView.tag = 7016;
    self.logoView.contentMode = UIViewContentModeScaleAspectFit;
    self.logoView.accessibilityLabel = @"CHZ PRIV";
    self.logoView.hidden = (self.logoView.image == nil);
    [self.view addSubview:self.logoView];

    UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectZero];
    subtitle.tag = 7004;
    subtitle.text = @"Acesse sua conta";
    subtitle.textColor = self.chzMutedWhite;
    subtitle.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightMedium];
    subtitle.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:subtitle];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.tag = 7006;
    label.text = @"KEY DE ACESSO";
    label.textColor = self.chzWhite;
    label.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightBold];
    [card addSubview:label];

    self.keyField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.keyField.tag = 7007;
    self.keyField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Digite sua key" attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:0.42 alpha:1.0]}];
    self.keyField.textColor = self.chzWhite;
    self.keyField.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightMedium];
    self.keyField.backgroundColor = [UIColor colorWithWhite:0.035 alpha:0.90];
    self.keyField.layer.cornerRadius = 17.0;
    self.keyField.layer.cornerCurve = kCACornerCurveContinuous;
    self.keyField.layer.borderWidth = 1.0;
    self.keyField.layer.borderColor = [self.chzRed colorWithAlphaComponent:0.34].CGColor;
    self.keyField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.keyField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.keyField.returnKeyType = UIReturnKeyDone;
    self.keyField.keyboardAppearance = UIKeyboardAppearanceDark;
    self.keyField.delegate = self;

    UIView *left = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 58, 50)];
    UIImageView *keyIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"key"]];
    keyIcon.frame = CGRectMake(18, 13, 24, 24);
    keyIcon.tintColor = self.chzRed;
    keyIcon.contentMode = UIViewContentModeScaleAspectFit;
    [left addSubview:keyIcon];
    self.keyField.leftView = left;
    self.keyField.leftViewMode = UITextFieldViewModeAlways;
    [card addSubview:self.keyField];

    self.didButton = [self makeButton:@"OBTER DID" filled:NO action:@selector(didTapped:)];
    self.didButton.tag = 7008;
    UIImage *didIcon = [UIImage systemImageNamed:@"person.crop.rectangle"];
    if (didIcon) {
        [self.didButton setImage:[didIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        self.didButton.tintColor = [UIColor colorWithWhite:0.82 alpha:1.0];
        self.didButton.imageEdgeInsets = UIEdgeInsetsMake(0, -8, 0, 8);
    }
    [card addSubview:self.didButton];

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
    support.textColor = [UIColor colorWithWhite:0.50 alpha:1.0];
    support.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightBold];
    support.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:support];

    UIView *leftLine = [[UIView alloc] initWithFrame:CGRectZero];
    leftLine.tag = 7011;
    leftLine.backgroundColor = [UIColor colorWithWhite:0.30 alpha:0.9];
    [self.view addSubview:leftLine];

    UIView *rightLine = [[UIView alloc] initWithFrame:CGRectZero];
    rightLine.tag = 7012;
    rightLine.backgroundColor = [UIColor colorWithWhite:0.30 alpha:0.9];
    [self.view addSubview:rightLine];

    UIButton *discord = [UIButton buttonWithType:UIButtonTypeSystem];
    discord.tag = 7013;
    discord.accessibilityLabel = @"Discord";
    discord.layer.cornerRadius = 26.0;
    discord.layer.borderWidth = 1.0;
    discord.layer.borderColor = [self.chzRed colorWithAlphaComponent:0.75].CGColor;
    discord.layer.shadowColor = self.chzRed.CGColor;
    discord.layer.shadowOpacity = 0.30;
    discord.layer.shadowRadius = 13.0;
    discord.layer.shadowOffset = CGSizeZero;
    UIImage *discordImage = [UIImage imageNamed:@"discord"];
    if (discordImage) {
        [discord setImage:[discordImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    } else {
        UIImage *fallback = [UIImage systemImageNamed:@"message.fill"];
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
    button.layer.cornerRadius = 17.0;
    button.layer.cornerCurve = kCACornerCurveContinuous;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = filled ? self.chzRed.CGColor : [UIColor colorWithWhite:0.28 alpha:0.82].CGColor;
    button.backgroundColor = filled ? self.chzRed : [UIColor colorWithWhite:0.09 alpha:0.95];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:(filled ? 19.0 : 17.0) weight:UIFontWeightBold];
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    if (filled) {
        button.layer.shadowColor = self.chzRed.CGColor;
        button.layer.shadowOpacity = 0.30;
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

    CGFloat safeTop = self.view.safeAreaInsets.top;
    CGFloat safeBottom = self.view.safeAreaInsets.bottom;
    CGFloat availableHeight = MAX(1.0, H - safeTop - safeBottom);
    CGFloat scale = MIN(1.0, MAX(0.78, availableHeight / 760.0));
    BOOL compact = availableHeight < 650.0;
    BOOL tablet = MIN(W, H) >= 600.0;

    self.topGradient.frame = CGRectMake(MAX(0.0, W * 0.12), safeTop + 125.0 * scale, W * 0.76, 3.0);
    self.bottomGradient.frame = CGRectMake(MAX(0.0, W * 0.16), H - safeBottom - 250.0 * scale, W * 0.68, 3.0);

    CGFloat glowDiameter = MIN(W * 0.66, tablet ? 420.0 : 340.0);
    UIView *glow = [self.view viewWithTag:7001];
    glow.frame = CGRectMake((W - glowDiameter) / 2.0, safeTop + 22.0 * scale, glowDiameter, glowDiameter * 0.42);
    glow.layer.cornerRadius = glow.frame.size.height / 2.0;

    CGFloat logoY = safeTop + (tablet ? 54.0 : 42.0) * scale;
    CGFloat logoW = MIN(W * (tablet ? 0.70 : 0.70), tablet ? 560.0 : 350.0);
    CGFloat wordH = (tablet ? 86.0 : 58.0) * scale;
    UILabel *chz = (UILabel *)[self.view viewWithTag:7002];
    UILabel *priv = (UILabel *)[self.view viewWithTag:7003];
    CGFloat wordSize = (tablet ? 76.0 : 52.0) * scale;
    chz.font = [UIFont italicSystemFontOfSize:wordSize];
    priv.font = [UIFont italicSystemFontOfSize:wordSize];
    chz.frame = CGRectMake((W - logoW) / 2.0, logoY, logoW * 0.49, wordH);
    priv.frame = CGRectMake(CGRectGetMidX(chz.frame) - 3.0 * scale, logoY, logoW * 0.53, wordH);
    UIImageView *logoView = (UIImageView *)[self.view viewWithTag:7016];
    if (logoView.image != nil) {
        chz.hidden = YES;
        priv.hidden = YES;
        logoView.hidden = NO;
        logoView.frame = CGRectMake((W - logoW) / 2.0, logoY - 10.0 * scale, logoW, (tablet ? 116.0 : 84.0) * scale);
    } else {
        chz.hidden = NO;
        priv.hidden = NO;
        logoView.hidden = YES;
    }

    UILabel *subtitle = (UILabel *)[self.view viewWithTag:7004];
    subtitle.font = [UIFont systemFontOfSize:17.0 * scale weight:UIFontWeightMedium];
    CGFloat logoBottom = logoView.image != nil ? CGRectGetMaxY(logoView.frame) : CGRectGetMaxY(chz.frame);
    subtitle.frame = CGRectMake(20.0, logoBottom + 13.0 * scale, W - 40.0, 25.0 * scale);

    CGFloat maxCardWidth = tablet ? 726.0 : 680.0;
    CGFloat sideInset = tablet ? 42.0 : 21.0;
    CGFloat cardW = MIN(W - 2.0 * sideInset, maxCardWidth);
    CGFloat cardH = (tablet ? 560.0 : (compact ? 318.0 : 322.0)) * scale;
    CGFloat cardY = CGRectGetMaxY(subtitle.frame) + (tablet ? 64.0 : (compact ? 23.0 : 39.0)) * scale;
    UIView *card = [self.view viewWithTag:7005];
    card.frame = CGRectMake((W - cardW) / 2.0, cardY, cardW, cardH);

    CGFloat horizontalPadding = (tablet ? 48.0 : (compact ? 36.0 : 48.0)) * scale;
    CGFloat contentW = cardW - 2.0 * horizontalPadding;
    CGFloat fieldH = (tablet ? 80.0 : 54.0) * scale;
    UILabel *label = (UILabel *)[card viewWithTag:7006];
    label.font = [UIFont systemFontOfSize:15.0 * scale weight:UIFontWeightBold];
    label.frame = CGRectMake(horizontalPadding, (tablet ? 50.0 : 31.0) * scale, contentW, (tablet ? 30.0 : 24.0) * scale);

    UITextField *field = (UITextField *)[card viewWithTag:7007];
    field.frame = CGRectMake(horizontalPadding, (tablet ? 108.0 : 78.0) * scale, contentW, fieldH);
    field.layer.cornerRadius = 17.0 * scale;

    UIButton *did = (UIButton *)[card viewWithTag:7008];
    did.frame = CGRectMake(horizontalPadding, (tablet ? 220.0 : 146.0) * scale, contentW, (tablet ? 76.0 : 52.0) * scale);
    did.layer.cornerRadius = (tablet ? 22.0 : 17.0) * scale;
    did.titleLabel.font = [UIFont systemFontOfSize:(tablet ? 24.0 : 17.0) * scale weight:UIFontWeightBold];

    UIButton *login = (UIButton *)[card viewWithTag:7009];
    login.frame = CGRectMake(horizontalPadding, (tablet ? 330.0 : 213.0) * scale, contentW, (tablet ? 84.0 : 54.0) * scale);
    login.layer.cornerRadius = (tablet ? 22.0 : 17.0) * scale;
    login.titleLabel.font = [UIFont systemFontOfSize:(tablet ? 26.0 : 19.0) * scale weight:UIFontWeightBold];

    UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[card viewWithTag:7014];
    indicator.center = CGPointMake(CGRectGetMidX(login.frame), CGRectGetMidY(login.frame));

    UILabel *status = (UILabel *)[card viewWithTag:7015];
    status.frame = CGRectMake(horizontalPadding, CGRectGetMaxY(login.frame) + (tablet ? 14.0 : 8.0) * scale, contentW, (tablet ? 36.0 : 30.0) * scale);

    UILabel *support = (UILabel *)[self.view viewWithTag:7010];
    UIView *leftLine = [self.view viewWithTag:7011];
    UIView *rightLine = [self.view viewWithTag:7012];
    UIButton *discord = (UIButton *)[self.view viewWithTag:7013];
    CGFloat supportY = CGRectGetMaxY(card.frame) + (tablet ? 78.0 : (compact ? 28.0 : 48.0)) * scale;
    CGFloat lineGap = tablet ? 88.0 : 74.0;
    support.frame = CGRectMake((W - 120.0) / 2.0, supportY, 120.0, 24.0 * scale);
    leftLine.frame = CGRectMake(sideInset + 26.0, supportY + 11.0 * scale, MAX(0.0, W / 2.0 - lineGap), 1.0);
    rightLine.frame = CGRectMake(W / 2.0 + lineGap, supportY + 11.0 * scale, MAX(0.0, W / 2.0 - lineGap - sideInset - 26.0), 1.0);
    CGFloat icon = (tablet ? 76.0 : 52.0) * scale;
    discord.frame = CGRectMake((W - icon) / 2.0, supportY + 43.0 * scale, icon, icon);
    discord.layer.cornerRadius = icon / 2.0;

    CGFloat overflow = CGRectGetMaxY(discord.frame) - (H - safeBottom - 18.0);
    if (overflow > 0.0) {
        CGFloat shift = MIN(overflow, MAX(0.0, logoY - safeTop - 10.0));
        for (UIView *view in self.view.subviews) {
            if (view == card) continue;
            view.center = CGPointMake(view.center.x, view.center.y - shift);
        }
        card.center = CGPointMake(card.center.x, card.center.y - shift);
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)chz_dismissKeyboard { [self.view endEditing:YES]; }
- (BOOL)textFieldShouldReturn:(UITextField *)textField { [textField resignFirstResponder]; return YES; }

- (void)didTapped:(__unused UIButton *)sender {
    NSString *did = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    if (did.length == 0) return;
    [UIPasteboard generalPasteboard].string = did;
    UINotificationFeedbackGenerator *feedback = [[UINotificationFeedbackGenerator alloc] init];
    [feedback notificationOccurred:UINotificationFeedbackTypeSuccess];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"DID copiado" message:@"O identificador do dispositivo foi copiado para a área de transferência." preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)loginTapped:(UIButton *)sender {
    NSString *key = [self.keyField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (key.length == 0 || self.activityIndicator.isAnimating) {
        self.statusLabel.text = @"Digite sua key para continuar.";
        self.statusLabel.textColor = [self.chzRed colorWithAlphaComponent:0.95];
        return;
    }

    sender.enabled = NO;
    self.keyField.enabled = NO;
    self.didButton.enabled = NO;
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
            sender.enabled = YES;
            self.keyField.enabled = YES;
            self.didButton.enabled = YES;
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
    self.loginButton.enabled = YES;
    self.keyField.enabled = YES;
    self.didButton.enabled = YES;
    self.statusLabel.text = @"Acesso autorizado.";
    self.statusLabel.textColor = [UIColor colorWithRed:0.25 green:0.90 blue:0.55 alpha:1.0];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
