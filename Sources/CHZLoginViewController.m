#import "CHZLoginViewController.h"
#import "CHZAuthManager.h"

@interface CHZLoginViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *keyField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIButton *didButton;
@property (nonatomic, strong) UIActivityIndicatorView *indicator;
@end

@implementation CHZLoginViewController

- (UIColor *)chzRed { return [UIColor colorWithRed:1.0 green:0.035 blue:0.06 alpha:1.0]; }
- (UIColor *)chzRedSoft { return [UIColor colorWithRed:1.0 green:0.035 blue:0.06 alpha:0.72]; }
- (UIColor *)chzGlassTint { return [UIColor colorWithRed:0.08 green:0.01 blue:0.015 alpha:0.38]; }

- (UIVisualEffect *)chzGlassEffect {
    if (@available(iOS 26.0, *)) {
        UIGlassEffect *glass = [UIGlassEffect effectWithStyle:UIGlassEffectStyleRegular];
        glass.tintColor = [self chzGlassTint];
        glass.interactive = YES;
        return glass;
    }
    return [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark];
}

- (UIVisualEffectView *)chzGlassView {
    UIVisualEffectView *view = [[UIVisualEffectView alloc] initWithEffect:[self chzGlassEffect]];
    view.clipsToBounds = YES;
    view.layer.cornerCurve = kCACornerCurveContinuous;
    return view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.008 green:0.006 blue:0.009 alpha:1.0];
    [self buildInterface];

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
        });
    }];
}

- (void)buildInterface {
    // Stable layout: this screen intentionally avoids Auto Layout so it cannot
    // abort on an iOS version with stricter constraint validation.
    self.view.backgroundColor = [UIColor colorWithRed:0.008 green:0.006 blue:0.009 alpha:1.0];

    UIView *glowTop = [[UIView alloc] initWithFrame:CGRectMake(-40, -120, 320, 320)];
    glowTop.backgroundColor = [self chzRed];
    glowTop.alpha = 0.075;
    glowTop.layer.cornerRadius = 160.0;
    glowTop.layer.shadowColor = [self chzRed].CGColor;
    glowTop.layer.shadowOpacity = 0.55;
    glowTop.layer.shadowRadius = 90.0;
    glowTop.layer.shadowOffset = CGSizeZero;
    glowTop.userInteractionEnabled = NO;
    [self.view addSubview:glowTop];

    UIView *glowBottom = [[UIView alloc] initWithFrame:CGRectZero];
    glowBottom.backgroundColor = [self chzRed];
    glowBottom.alpha = 0.045;
    glowBottom.layer.cornerRadius = 140.0;
    glowBottom.layer.shadowColor = [self chzRed].CGColor;
    glowBottom.layer.shadowOpacity = 0.5;
    glowBottom.layer.shadowRadius = 90.0;
    glowBottom.layer.shadowOffset = CGSizeZero;
    glowBottom.userInteractionEnabled = NO;
    [self.view addSubview:glowBottom];

    UIVisualEffectView *card = [self chzGlassView];
    card.tag = 310501;
    card.layer.cornerRadius = 30.0;
    card.layer.borderWidth = 1.0;
    card.layer.borderColor = [self chzRedSoft].CGColor;
    card.layer.shadowColor = [self chzRed].CGColor;
    card.layer.shadowOpacity = 0.12;
    card.layer.shadowRadius = 28.0;
    card.layer.shadowOffset = CGSizeZero;
    [self.view addSubview:card];

    UILabel *chz = [[UILabel alloc] initWithFrame:CGRectZero];
    chz.text = @"CHZ";
    chz.textColor = [self chzRed];
    chz.font = [UIFont systemFontOfSize:45.0 weight:UIFontWeightBlack];
    chz.textAlignment = NSTextAlignmentRight;
    chz.layer.shadowColor = [self chzRed].CGColor;
    chz.layer.shadowOpacity = 0.28;
    chz.layer.shadowRadius = 12.0;
    chz.layer.shadowOffset = CGSizeZero;
    [self.view addSubview:chz];

    UILabel *priv = [[UILabel alloc] initWithFrame:CGRectZero];
    priv.text = @"PRIV";
    priv.textColor = UIColor.whiteColor;
    priv.font = [UIFont systemFontOfSize:45.0 weight:UIFontWeightBlack];
    priv.textAlignment = NSTextAlignmentLeft;
    priv.layer.shadowColor = UIColor.blackColor.CGColor;
    priv.layer.shadowOpacity = 0.55;
    priv.layer.shadowRadius = 8.0;
    priv.layer.shadowOffset = CGSizeMake(0, 3);
    [self.view addSubview:priv];

    UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectZero];
    subtitle.text = @"Acesse sua conta";
    subtitle.textColor = [UIColor colorWithWhite:0.80 alpha:1.0];
    subtitle.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightMedium];
    subtitle.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:subtitle];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = @"KEY DE ACESSO";
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightBold];
    [card.contentView addSubview:label];

    self.keyField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.keyField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Digite sua key" attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.52 alpha:1.0]}];
    self.keyField.textColor = UIColor.whiteColor;
    self.keyField.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightMedium];
    self.keyField.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.34];
    self.keyField.layer.cornerRadius = 19.0;
    self.keyField.layer.cornerCurve = kCACornerCurveContinuous;
    self.keyField.layer.borderWidth = 1.0;
    self.keyField.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.13].CGColor;
    self.keyField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.keyField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.keyField.returnKeyType = UIReturnKeyDone;
    self.keyField.delegate = self;
    self.keyField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 1)];
    self.keyField.leftViewMode = UITextFieldViewModeAlways;
    [card.contentView addSubview:self.keyField];

    self.didButton = [self buttonWithTitle:@"OBTER DID" action:@selector(didTapped:) filled:NO];
    self.loginButton = [self buttonWithTitle:@"ENTRAR" action:@selector(loginTapped:) filled:YES];
    [card.contentView addSubview:self.didButton];
    [card.contentView addSubview:self.loginButton];

    UIButton *discordButton = [self iconButtonWithImage:[self chzDiscordImage] action:@selector(discordTapped:) accessibilityLabel:@"Discord"];
    [self.view addSubview:discordButton];

    // Keep references using tags for layout without adding more public state.
    chz.tag = 310502;
    priv.tag = 310503;
    subtitle.tag = 310504;
    label.tag = 310505;
    discordButton.tag = 310506;
    glowBottom.tag = 310508;

    self.view.autoresizesSubviews = YES;
    [self layoutStableInterface];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutStableInterface];
}

- (void)layoutStableInterface {
    UIView *root = self.view;
    CGFloat W = CGRectGetWidth(root.bounds);
    CGFloat H = CGRectGetHeight(root.bounds);
    if (W <= 0.0 || H <= 0.0) return;

    UIView *glowBottom = [root viewWithTag:310508];
    UILabel *chz = (UILabel *)[root viewWithTag:310502];
    UILabel *priv = (UILabel *)[root viewWithTag:310503];
    UILabel *subtitle = (UILabel *)[root viewWithTag:310504];
    UIVisualEffectView *card = (UIVisualEffectView *)[root viewWithTag:310501];
    UILabel *label = (UILabel *)[card viewWithTag:310505];
    UIButton *discordButton = (UIButton *)[root viewWithTag:310506];
    if (!card || !chz || !priv || !subtitle || !label || !discordButton) return;

    CGFloat safeTop = root.safeAreaInsets.top;
    CGFloat safeBottom = root.safeAreaInsets.bottom;
    CGFloat contentW = MIN(MAX(W - 44.0, 280.0), 390.0);
    CGFloat left = (W - contentW) * 0.5;

    // Reference layout: compact centered wordmark + focused glass form.
    CGFloat wordY = safeTop + 16.0;
    CGFloat wordH = 48.0;
    CGFloat chzW = 74.0, privW = 98.0, gap = 5.0;
    CGFloat totalW = chzW + gap + privW;
    CGFloat wordX = (W - totalW) * 0.5;
    chz.font = [UIFont systemFontOfSize:38.0 weight:UIFontWeightBlack];
    priv.font = [UIFont systemFontOfSize:38.0 weight:UIFontWeightBlack];
    chz.frame = CGRectMake(wordX, wordY, chzW, wordH);
    priv.frame = CGRectMake(wordX + chzW + gap, wordY, privW, wordH);

    CGFloat subtitleY = CGRectGetMaxY(chz.frame) - 1.0;
    subtitle.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    subtitle.frame = CGRectMake(left, subtitleY, contentW, 20.0);

    CGFloat cardH = (H < 700.0) ? 314.0 : 326.0;
    CGFloat cardY = CGRectGetMaxY(subtitle.frame) + 20.0;
    CGFloat discordSize = 50.0;
    CGFloat discordGap = 18.0;
    CGFloat bottomMargin = 10.0;

    // Compute one vertical shift from immutable base positions. This avoids
    // cumulative frame drift when UIKit calls viewDidLayoutSubviews repeatedly.
    CGFloat groupBottom = cardY + cardH + discordGap + discordSize;
    CGFloat maxBottom = H - safeBottom - bottomMargin;
    CGFloat shift = MAX(0.0, groupBottom - maxBottom);
    if (cardY - shift < safeTop + 8.0) {
        shift = MAX(0.0, cardY - (safeTop + 8.0));
    }

    card.frame = CGRectMake(left, cardY - shift, contentW, cardH);
    card.layer.cornerRadius = 26.0;

    CGFloat pad = MIN(22.0, MAX(18.0, contentW * 0.055));
    CGFloat innerW = contentW - pad * 2.0;
    CGFloat y = 20.0;
    label.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightBold];
    label.frame = CGRectMake(pad, y, innerW, 20.0);
    y += 29.0;

    self.keyField.frame = CGRectMake(pad, y, innerW, 50.0);
    self.keyField.layer.cornerRadius = 16.0;
    y += 61.0;

    self.didButton.frame = CGRectMake(pad, y, innerW, 48.0);
    self.didButton.layer.cornerRadius = 16.0;
    y += 59.0;

    self.loginButton.frame = CGRectMake(pad, y, innerW, 50.0);
    self.loginButton.layer.cornerRadius = 16.0;

    discordButton.frame = CGRectMake((W - discordSize) * 0.5,
                                     CGRectGetMaxY(card.frame) + discordGap,
                                     discordSize, discordSize);
    discordButton.layer.cornerRadius = discordSize * 0.5;

    if (glowBottom) {
        glowBottom.frame = CGRectMake(W - 260.0, H - 150.0, 300.0, 300.0);
    }
}

- (UIButton *)buttonWithTitle:(NSString *)title action:(SEL)action filled:(BOOL)filled {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightBold];
    button.layer.cornerRadius = 19.0;
    button.layer.cornerCurve = kCACornerCurveContinuous;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = filled ? [self chzRed].CGColor : [UIColor colorWithWhite:1.0 alpha:0.16].CGColor;
    button.backgroundColor = filled ? [self chzRed] : [UIColor colorWithWhite:1.0 alpha:0.055];
    button.layer.shadowColor = filled ? [self chzRed].CGColor : UIColor.clearColor.CGColor;
    button.layer.shadowOpacity = filled ? 0.22 : 0.0;
    button.layer.shadowRadius = 14.0;
    button.layer.shadowOffset = CGSizeZero;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIButton *)iconButtonWithImage:(UIImage *)image action:(SEL)action accessibilityLabel:(NSString *)label {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    if (image != nil) {
        [button setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    }
    button.tintColor = UIColor.clearColor;
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    button.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.055];
    button.layer.cornerRadius = 22.0;
    button.layer.cornerCurve = kCACornerCurveContinuous;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = [self chzRedSoft].CGColor;
    button.layer.shadowColor = [self chzRed].CGColor;
    button.layer.shadowOpacity = 0.10;
    button.layer.shadowRadius = 18.0;
    button.layer.shadowOffset = CGSizeZero;
    button.accessibilityLabel = label;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIImage *)chzDiscordImage {
    static UIImage *image = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *b64 = @"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";
        NSData *data = [[NSData alloc] initWithBase64EncodedString:b64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
        UIImage *decoded = data.length ? [UIImage imageWithData:data scale:3.0] : nil;
        image = [decoded imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    });
    return image;
}

- (void)chz_dismissKeyboard { [self.view endEditing:YES]; }

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

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
    sender.enabled = NO;
    [[CHZAuthManager sharedManager] loginWithKey:self.keyField.text success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            sender.enabled = YES;
            [self finishLogin];
        });
    } failure:^(NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            sender.enabled = YES;
            NSString *safeMessage = ([message isKindOfClass:[NSString class]] && message.length > 0) ? message : @"Falha de validação — build CHZ-2026-08-27. Verifique a conexão e tente novamente.";
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Login não autorizado" message:safeMessage preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        });
    }];
}

- (void)discordTapped:(__unused UIButton *)sender {
    NSURL *url = [NSURL URLWithString:@"https://discord.gg/BZ53Fsgr"];
    if (url) [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void)finishLogin { [self dismissViewControllerAnimated:YES completion:nil]; }

@end
