#import "CHZLoginViewController.h"
#import "CHZAuthManager.h"
#import <UIKit/UIKit.h>

@interface CHZLoginViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *keyField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIButton *didButton;
@end

@implementation CHZLoginViewController

- (UIColor *)chzRed { return [UIColor colorWithRed:1.0 green:0.02 blue:0.06 alpha:1.0]; }
- (UIColor *)chzWhite { return [UIColor colorWithWhite:0.96 alpha:1.0]; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.view.clipsToBounds = YES;
    [self buildInterface];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chz_dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];

    [[CHZAuthManager sharedManager] validateSavedKeyWithSuccess:^{
        dispatch_async(dispatch_get_main_queue(), ^{ [self finishLogin]; });
    } failure:^(__unused NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{ self.keyField.text = @""; });
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutReference];
}

- (void)buildInterface {
    // Frame-based layout only. No NSLayoutConstraint is used on this screen.
    UIView *topGlow = [[UIView alloc] initWithFrame:CGRectZero];
    topGlow.tag = 7001;
    topGlow.backgroundColor = [self chzRed];
    topGlow.alpha = 0.035;
    topGlow.layer.cornerRadius = 170.0;
    topGlow.layer.shadowColor = [self chzRed].CGColor;
    topGlow.layer.shadowOpacity = 0.75;
    topGlow.layer.shadowRadius = 90.0;
    topGlow.layer.shadowOffset = CGSizeZero;
    [self.view addSubview:topGlow];

    // Wordmark built from native text so there is no fragile image decoding at launch.
    UILabel *chz = [[UILabel alloc] initWithFrame:CGRectZero];
    chz.tag = 7002;
    chz.text = @"CHZ";
    chz.textColor = [self chzRed];
    chz.font = [UIFont italicSystemFontOfSize:48.0 weight:UIFontWeightBlack];
    chz.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:chz];

    UILabel *priv = [[UILabel alloc] initWithFrame:CGRectZero];
    priv.tag = 7003;
    priv.text = @"PRIV";
    priv.textColor = [self chzWhite];
    priv.font = [UIFont italicSystemFontOfSize:48.0 weight:UIFontWeightBlack];
    priv.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:priv];

    UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectZero];
    subtitle.tag = 7004;
    subtitle.text = @"Acesse sua conta";
    subtitle.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    subtitle.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightMedium];
    subtitle.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:subtitle];

    UIView *card = [[UIView alloc] initWithFrame:CGRectZero];
    card.tag = 7005;
    card.backgroundColor = [UIColor colorWithWhite:0.035 alpha:0.92];
    card.layer.cornerRadius = 30.0;
    card.layer.cornerCurve = kCACornerCurveContinuous;
    card.layer.borderWidth = 1.0;
    card.layer.borderColor = [self.chzRed colorWithAlphaComponent:0.82].CGColor;
    card.layer.shadowColor = [self chzRed].CGColor;
    card.layer.shadowOpacity = 0.16;
    card.layer.shadowRadius = 25.0;
    card.layer.shadowOffset = CGSizeZero;
    [self.view addSubview:card];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.tag = 7006;
    label.text = @"KEY DE ACESSO";
    label.textColor = [self chzWhite];
    label.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightBold];
    [card addSubview:label];

    self.keyField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.keyField.tag = 7007;
    self.keyField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Digite sua key" attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:0.42 alpha:1.0]}];
    self.keyField.textColor = [self chzWhite];
    self.keyField.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightMedium];
    self.keyField.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.42];
    self.keyField.layer.cornerRadius = 17.0;
    self.keyField.layer.cornerCurve = kCACornerCurveContinuous;
    self.keyField.layer.borderWidth = 1.0;
    self.keyField.layer.borderColor = [UIColor colorWithRed:1.0 green:0.10 blue:0.14 alpha:0.38].CGColor;
    self.keyField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.keyField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.keyField.returnKeyType = UIReturnKeyDone;
    self.keyField.delegate = self;
    UIView *left = [[UIView alloc] initWithFrame:CGRectMake(0,0,54,50)];
    UIImageView *keyIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"key"]];
    keyIcon.frame = CGRectMake(17,13,24,24);
    keyIcon.tintColor = [self chzRed];
    keyIcon.contentMode = UIViewContentModeScaleAspectFit;
    [left addSubview:keyIcon];
    self.keyField.leftView = left;
    self.keyField.leftViewMode = UITextFieldViewModeAlways;
    [card addSubview:self.keyField];

    self.didButton = [self makeButton:@"OBTER DID" filled:NO action:@selector(didTapped:)];
    self.didButton.tag = 7008;
    [card addSubview:self.didButton];

    self.loginButton = [self makeButton:@"ENTRAR" filled:YES action:@selector(loginTapped:)];
    self.loginButton.tag = 7009;
    [card addSubview:self.loginButton];

    UILabel *support = [[UILabel alloc] initWithFrame:CGRectZero];
    support.tag = 7010;
    support.text = @"SUPORTE";
    support.textColor = [UIColor colorWithWhite:0.54 alpha:1.0];
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
    discord.frame = CGRectZero;
    discord.layer.cornerRadius = 25.0;
    discord.layer.borderWidth = 1.0;
    discord.layer.borderColor = [self chzRed].CGColor;
    discord.layer.shadowColor = [self chzRed].CGColor;
    discord.layer.shadowOpacity = 0.28;
    discord.layer.shadowRadius = 12.0;
    discord.layer.shadowOffset = CGSizeZero;
    UIImage *discordImage = [UIImage imageNamed:@"discord"];
    if (discordImage) [discord setImage:[discordImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    else [discord setImage:[UIImage systemImageNamed:@"message.fill"] forState:UIControlStateNormal];
    discord.imageView.contentMode = UIViewContentModeScaleAspectFit;
    discord.tintColor = UIColor.whiteColor;
    [discord addTarget:self action:@selector(discordTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:discord];
}

- (UIButton *)makeButton:(NSString *)title filled:(BOOL)filled action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectZero;
    button.layer.cornerRadius = 17.0;
    button.layer.cornerCurve = kCACornerCurveContinuous;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = filled ? [self chzRed].CGColor : [UIColor colorWithWhite:0.30 alpha:0.75].CGColor;
    button.backgroundColor = filled ? [self chzRed] : [UIColor colorWithWhite:0.09 alpha:0.95];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:(filled ? 19.0 : 17.0) weight:UIFontWeightBold];
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    if (filled) {
        button.layer.shadowColor = [self chzRed].CGColor;
        button.layer.shadowOpacity = 0.24;
        button.layer.shadowRadius = 12.0;
        button.layer.shadowOffset = CGSizeZero;
    }
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)layoutReference {
    CGFloat W = CGRectGetWidth(self.view.bounds);
    CGFloat H = CGRectGetHeight(self.view.bounds);
    if (W <= 0 || H <= 0) return;
    CGFloat top = self.view.safeAreaInsets.top;
    CGFloat bottom = self.view.safeAreaInsets.bottom;
    BOOL compact = H < 700.0;

    UIView *glow = [self.view viewWithTag:7001];
    glow.frame = CGRectMake((W-340)/2.0, top-105, 340, 340);

    CGFloat logoY = top + (compact ? 25 : 50);
    CGFloat logoW = MIN(W * 0.58, 285.0);
    CGFloat wordH = 58.0;
    CGFloat gap = 0.0;
    UILabel *chz = (UILabel *)[self.view viewWithTag:7002];
    UILabel *priv = (UILabel *)[self.view viewWithTag:7003];
    chz.frame = CGRectMake((W-logoW)/2.0, logoY, logoW*0.49, wordH);
    priv.frame = CGRectMake(CGRectGetMidX(chz.frame)-3, logoY, logoW*0.53, wordH);

    UILabel *subtitle = (UILabel *)[self.view viewWithTag:7004];
    subtitle.frame = CGRectMake(20, CGRectGetMaxY(chz.frame)+13, W-40, 24);

    CGFloat cardW = MIN(W-44, 726.0);
    if (W <= 430) cardW = W-42;
    CGFloat cardH = compact ? 285 : 305;
    CGFloat cardY = CGRectGetMaxY(subtitle.frame) + (compact ? 22 : 38);
    if (cardY + cardH > H - 155) cardY = MAX(top+150, H - 155 - cardH);
    UIView *card = [self.view viewWithTag:7005];
    card.frame = CGRectMake((W-cardW)/2.0, cardY, cardW, cardH);

    UILabel *label = (UILabel *)[card viewWithTag:7006];
    label.frame = CGRectMake(48, 31, cardW-96, 24);

    UITextField *field = (UITextField *)[card viewWithTag:7007];
    field.frame = CGRectMake(48, 78, cardW-96, 54);

    UIButton *did = (UIButton *)[card viewWithTag:7008];
    did.frame = CGRectMake(48, 146, cardW-96, 52);

    UIButton *login = (UIButton *)[card viewWithTag:7009];
    login.frame = CGRectMake(48, 213, cardW-96, 54);
    if (compact) {
        label.frame = CGRectMake(36, 24, cardW-72, 22);
        field.frame = CGRectMake(36, 64, cardW-72, 50);
        did.frame = CGRectMake(36, 125, cardW-72, 48);
        login.frame = CGRectMake(36, 184, cardW-72, 52);
    }

    UILabel *support = (UILabel *)[self.view viewWithTag:7010];
    UIView *leftLine = [self.view viewWithTag:7011];
    UIView *rightLine = [self.view viewWithTag:7012];
    UIButton *discord = (UIButton *)[self.view viewWithTag:7013];
    CGFloat supportY = CGRectGetMaxY(card.frame) + (compact ? 45 : 62);
    support.frame = CGRectMake((W-110)/2.0, supportY, 110, 24);
    leftLine.frame = CGRectMake(48, supportY+11, MAX(0, W/2.0-74), 1);
    rightLine.frame = CGRectMake(W/2.0+74, supportY+11, MAX(0, W/2.0-122), 1);
    CGFloat icon = 50.0;
    discord.frame = CGRectMake((W-icon)/2.0, supportY+42, icon, icon);
    discord.imageEdgeInsets = UIEdgeInsetsMake(11,11,11,11);
    (void)bottom;
    (void)gap;
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
    sender.enabled = NO;
    [[CHZAuthManager sharedManager] loginWithKey:self.keyField.text success:^{
        dispatch_async(dispatch_get_main_queue(), ^{ sender.enabled = YES; [self finishLogin]; });
    } failure:^(NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            sender.enabled = YES;
            NSString *safe = ([message isKindOfClass:[NSString class]] && message.length) ? message : @"Falha de validação. Verifique a conexão e tente novamente.";
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Login não autorizado" message:safe preferredStyle:UIAlertControllerStyleAlert];
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
