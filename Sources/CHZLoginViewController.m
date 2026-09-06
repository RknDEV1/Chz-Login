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

- (UIImage *)chzImageNamed:(NSString *)name {
    UIImage *image = [UIImage imageNamed:name];
    if (image != nil) return image;

    // O ESign pode renomear o bundle para CHZLoginResources 2.bundle.
    // Procura todos os bundles CHZ e prefere a logo horizontal da referência.
    NSArray<NSString *> *bundlePaths = [[NSBundle mainBundle] pathsForResourcesOfType:@"bundle" inDirectory:nil];
    UIImage *bestImage = nil;
    CGFloat bestScore = -1.0;
    for (NSString *path in bundlePaths) {
        NSString *filename = [[path lastPathComponent] stringByDeletingPathExtension];
        if (![filename hasPrefix:@"CHZLoginResources"]) continue;
        NSBundle *bundle = [NSBundle bundleWithPath:path];
        UIImage *candidate = [UIImage imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
        if (candidate == nil) continue;
        CGFloat aspect = candidate.size.height > 0.0 ? candidate.size.width / candidate.size.height : 0.0;
        CGFloat score = (aspect > 1.15 ? 1000.0 : 0.0) + aspect;
        if (score > bestScore) {
            bestScore = score;
            bestImage = candidate;
        }
    }
    return bestImage;
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
    self.statusLabel.text = @"";
    self.statusLabel.hidden = YES;
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
    card.backgroundColor = [UIColor colorWithWhite:0.02 alpha:0.52];
    card.layer.cornerRadius = 31.0;
    card.layer.cornerCurve = kCACornerCurveContinuous;
    card.layer.borderWidth = 1.0;
    card.layer.borderColor = [UIColor colorWithWhite:0.95 alpha:0.22].CGColor;
    card.layer.shadowColor = self.chzRed.CGColor;
    card.layer.shadowOpacity = 0.16;
    card.layer.shadowRadius = 28.0;
    card.layer.shadowOffset = CGSizeZero;
    [self.view addSubview:card];

    UIBlurEffect *glassEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterialDark];
    UIVisualEffectView *glass = [[UIVisualEffectView alloc] initWithEffect:glassEffect];
    glass.tag = 7020;
    glass.userInteractionEnabled = NO;
    glass.layer.cornerRadius = 31.0;
    glass.layer.cornerCurve = kCACornerCurveContinuous;
    glass.clipsToBounds = YES;
    glass.alpha = 0.82;
    [card addSubview:glass];

    UILabel *chz = [[UILabel alloc] initWithFrame:CGRectZero];
    chz.tag = 7002;
    chz.text = @"CHZ";
    chz.textColor = self.chzRed;
    chz.font = [UIFont fontWithName:@"HelveticaNeue-BoldItalic" size:52.0] ?: [UIFont italicSystemFontOfSize:52.0];
    chz.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:chz];

    UILabel *priv = [[UILabel alloc] initWithFrame:CGRectZero];
    priv.tag = 7003;
    priv.text = @"PRIV";
    priv.textColor = self.chzWhite;
    priv.font = [UIFont fontWithName:@"HelveticaNeue-BoldItalic" size:52.0] ?: [UIFont italicSystemFontOfSize:52.0];
    priv.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:priv];

    // Usa a logo brush/grafite transparente enviada pelo usuário como referência final.
    self.logoView = [[UIImageView alloc] initWithImage:[self chzImageNamed:@"CHZPrivLogoFinal"]];
    self.logoView.tag = 7016;
    self.logoView.contentMode = UIViewContentModeScaleAspectFit;
    self.logoView.hidden = (self.logoView.image == nil);
    self.logoView.accessibilityLabel = @"CHZ PRIV";
    [self.view addSubview:self.logoView];

    UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectZero];
    subtitle.tag = 7004;
    subtitle.text = @"Acesse sua conta";
    subtitle.textColor = self.chzMutedWhite;
    subtitle.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightMedium];
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
    self.keyField.font = [UIFont systemFontOfSize:20.0 weight:UIFontWeightMedium];
    self.keyField.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.38];
    self.keyField.layer.cornerRadius = 17.0;
    self.keyField.layer.cornerCurve = kCACornerCurveContinuous;
    self.keyField.layer.borderWidth = 1.0;
    self.keyField.layer.borderColor = [UIColor colorWithWhite:0.95 alpha:0.24].CGColor;
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

    self.didButton = [self makeButton:@"OBTER UDID" filled:NO action:@selector(didTapped:)];
    self.didButton.tag = 7008;
    UIImage *didIcon = [UIImage systemImageNamed:@"doc.on.clipboard"];
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
    self.statusLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 2;
    self.statusLabel.accessibilityIdentifier = @"chz.login.status";
    [card addSubview:self.statusLabel];

    UILabel *support = [[UILabel alloc] initWithFrame:CGRectZero];
    support.tag = 7010;
    support.text = @"SUPORTE";
    support.textColor = [UIColor colorWithWhite:0.50 alpha:1.0];
    support.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
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
    discord.layer.borderWidth = 0.0;
    discord.layer.borderColor = UIColor.clearColor.CGColor;
    discord.backgroundColor = UIColor.clearColor;
    discord.layer.shadowColor = UIColor.blackColor.CGColor;
    discord.layer.shadowOpacity = 0.16;
    discord.layer.shadowRadius = 10.0;
    discord.layer.shadowOffset = CGSizeZero;
    UIImage *discordImage = [self chzImageNamed:@"discord"];
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
    button.layer.borderColor = filled ? [UIColor colorWithWhite:1.0 alpha:0.28].CGColor : [UIColor colorWithWhite:0.92 alpha:0.22].CGColor;
    button.backgroundColor = filled ? [self.chzRed colorWithAlphaComponent:0.88] : [UIColor colorWithWhite:0.16 alpha:0.45];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:(filled ? 21.0 : 19.0) weight:UIFontWeightBold];
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

    CGFloat safeTop = self.view.safeAreaInsets.top;
    CGFloat safeBottom = self.view.safeAreaInsets.bottom;
    CGFloat availableHeight = MAX(1.0, H - safeTop - safeBottom);
    CGFloat scale = MIN(1.0, MAX(0.78, availableHeight / 760.0));
    BOOL compact = availableHeight < 650.0;
    BOOL tablet = MIN(W, H) >= 600.0;

    self.topGradient.frame = CGRectMake(MAX(0.0, W * 0.20), safeTop + 122.0 * scale, W * 0.60, 2.0);
    self.bottomGradient.frame = CGRectMake(MAX(0.0, W * 0.16), H - safeBottom - 250.0 * scale, W * 0.68, 3.0);

    CGFloat glowDiameter = MIN(W * 0.54, tablet ? 360.0 : 285.0);
    UIView *glow = [self.view viewWithTag:7001];
    glow.frame = CGRectMake((W - glowDiameter) / 2.0, safeTop + 22.0 * scale, glowDiameter, glowDiameter * 0.28);
    glow.layer.cornerRadius = glow.frame.size.height / 2.0;
    glow.layer.borderWidth = 0.0;
    glow.layer.shadowOpacity = 0.0;

    CGFloat logoY = safeTop + (tablet ? 72.0 : 86.0) * scale;
    CGFloat logoW = MIN(W * (tablet ? 0.70 : 0.70), tablet ? 560.0 : 350.0);
    CGFloat wordH = (tablet ? 86.0 : 58.0) * scale;
    UILabel *chz = (UILabel *)[self.view viewWithTag:7002];
    UILabel *priv = (UILabel *)[self.view viewWithTag:7003];
    CGFloat wordSize = (tablet ? 76.0 : 52.0) * scale;
    chz.font = [UIFont fontWithName:@"HelveticaNeue-BoldItalic" size:wordSize] ?: [UIFont italicSystemFontOfSize:wordSize];
    priv.font = [UIFont fontWithName:@"HelveticaNeue-BoldItalic" size:wordSize] ?: [UIFont italicSystemFontOfSize:wordSize];
    CGFloat wordX = (W - logoW) / 2.0;
    chz.frame = CGRectMake(wordX, logoY, logoW * 0.43, wordH);
    priv.frame = CGRectMake(wordX + logoW * 0.39, logoY, logoW * 0.61, wordH);
    UIImageView *logoView = (UIImageView *)[self.view viewWithTag:7016];
    // A logo enviada é o wordmark final; os labels ficam como fallback somente se o asset não carregar.
    if (logoView.image != nil) {
        chz.hidden = YES;
        priv.hidden = YES;
        logoView.hidden = NO;
        CGFloat logoH = logoW * (857.0 / 1181.0);
        logoView.frame = CGRectMake((W - logoW) / 2.0, logoY, logoW, logoH);
    } else {
        chz.hidden = NO;
        priv.hidden = NO;
        logoView.hidden = YES;
        logoView.frame = CGRectZero;
    }

    UILabel *subtitle = (UILabel *)[self.view viewWithTag:7004];
    subtitle.font = [UIFont systemFontOfSize:18.0 * scale weight:UIFontWeightMedium];
    CGFloat logoBottom = logoView.image != nil ? CGRectGetMaxY(logoView.frame) : CGRectGetMaxY(chz.frame);
    subtitle.frame = CGRectMake(20.0, logoBottom + 13.0 * scale, W - 40.0, 25.0 * scale);

    CGFloat maxCardWidth = tablet ? 726.0 : 680.0;
    CGFloat sideInset = tablet ? 42.0 : 34.0;
    CGFloat cardW = MIN(W - 2.0 * sideInset, maxCardWidth);
    CGFloat cardY = CGRectGetMaxY(subtitle.frame) + (tablet ? 64.0 : (compact ? 28.0 : 48.0)) * scale;
    CGFloat horizontalPadding = (tablet ? 48.0 : (compact ? 30.0 : 38.0)) * scale;
    CGFloat contentW = cardW - 2.0 * horizontalPadding;
    CGFloat cardTop = (tablet ? 50.0 : 31.0) * scale;
    CGFloat labelH = (tablet ? 30.0 : 24.0) * scale;
    CGFloat gapAfterLabel = (tablet ? 28.0 : 22.0) * scale;
    CGFloat fieldH = (tablet ? 80.0 : 56.0) * scale;
    CGFloat controlGap = (tablet ? 24.0 : 16.0) * scale;
    CGFloat didH = (tablet ? 76.0 : 56.0) * scale;
    CGFloat loginH = (tablet ? 84.0 : 58.0) * scale;
    CGFloat cardH = cardTop + labelH + gapAfterLabel + fieldH + controlGap + didH + controlGap + loginH + (tablet ? 42.0 : 32.0) * scale;
    if (compact && !tablet) cardH = MIN(cardH, 326.0 * scale);
    UIView *card = [self.view viewWithTag:7005];
    card.frame = CGRectMake((W - cardW) / 2.0, cardY, cardW, cardH);
    UIVisualEffectView *glass = (UIVisualEffectView *)[card viewWithTag:7020];
    glass.frame = card.bounds;
    glass.layer.cornerRadius = card.layer.cornerRadius;

    UILabel *label = (UILabel *)[card viewWithTag:7006];
    label.font = [UIFont systemFontOfSize:17.0 * scale weight:UIFontWeightBold];
    label.frame = CGRectMake(horizontalPadding, cardTop, contentW, labelH);

    UITextField *field = (UITextField *)[card viewWithTag:7007];
    CGFloat fieldY = CGRectGetMaxY(label.frame) + gapAfterLabel;
    field.frame = CGRectMake(horizontalPadding, fieldY, contentW, fieldH);
    field.layer.cornerRadius = 18.0 * scale;

    UIButton *did = (UIButton *)[card viewWithTag:7008];
    CGFloat didY = CGRectGetMaxY(field.frame) + controlGap;
    did.frame = CGRectMake(horizontalPadding + 2.0 * scale, didY, contentW - 4.0 * scale, didH);
    did.layer.cornerRadius = (tablet ? 22.0 : 18.0) * scale;
    did.titleLabel.font = [UIFont systemFontOfSize:(tablet ? 24.0 : 19.0) * scale weight:UIFontWeightBold];

    UIButton *login = (UIButton *)[card viewWithTag:7009];
    CGFloat loginY = CGRectGetMaxY(did.frame) + controlGap;
    login.frame = CGRectMake(horizontalPadding + 2.0 * scale, loginY, contentW - 4.0 * scale, loginH);
    login.layer.cornerRadius = (tablet ? 22.0 : 18.0) * scale;
    login.titleLabel.font = [UIFont systemFontOfSize:(tablet ? 26.0 : 21.0) * scale weight:UIFontWeightBold];

    UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[card viewWithTag:7014];
    indicator.center = CGPointMake(CGRectGetMidX(login.frame), CGRectGetMidY(login.frame));

    UILabel *status = (UILabel *)[card viewWithTag:7015];
    status.frame = CGRectMake(horizontalPadding, CGRectGetMaxY(login.frame) + (tablet ? 12.0 : 8.0) * scale, contentW, (tablet ? 34.0 : 28.0) * scale);

    UILabel *support = (UILabel *)[self.view viewWithTag:7010];
    UIView *leftLine = [self.view viewWithTag:7011];
    UIView *rightLine = [self.view viewWithTag:7012];
    UIButton *discord = (UIButton *)[self.view viewWithTag:7013];
    CGFloat supportY = CGRectGetMaxY(card.frame) + (tablet ? 78.0 : (compact ? 30.0 : 42.0)) * scale;
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
    NSURL *url = [NSURL URLWithString:@"https://udid.baontq.xyz/udid.php?id=23741&openurl=(null)"];
    if (!url) return;
    UIApplication *application = UIApplication.sharedApplication;
    if ([application canOpenURL:url]) {
        [application openURL:url options:@{} completionHandler:nil];
    }
}

- (void)loginTapped:(UIButton *)sender {
    NSString *key = [self.keyField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (key.length == 0 || self.activityIndicator.isAnimating) {
        self.statusLabel.hidden = NO;
        self.statusLabel.text = @"Digite sua key para continuar.";
        self.statusLabel.textColor = [self.chzRed colorWithAlphaComponent:0.95];
        return;
    }

    sender.enabled = NO;
    self.keyField.enabled = NO;
    self.didButton.enabled = NO;
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
