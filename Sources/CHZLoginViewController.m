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
    UILabel *discordCaption = [[UILabel alloc] initWithFrame:CGRectZero];
    discordCaption.text = @"Discord";
    discordCaption.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    discordCaption.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold];
    discordCaption.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:discordButton];
    [self.view addSubview:discordCaption];

    // Keep references using tags for layout without adding more public state.
    chz.tag = 310502;
    priv.tag = 310503;
    subtitle.tag = 310504;
    label.tag = 310505;
    discordButton.tag = 310506;
    discordCaption.tag = 310507;
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
    if (W <= 0 || H <= 0) return;

    UIView *glowBottom = [root viewWithTag:310508];
    glowBottom.frame = CGRectMake(W - 260.0, H - 80.0, 280.0, 280.0);

    UILabel *chz = (UILabel *)[root viewWithTag:310502];
    UILabel *priv = (UILabel *)[root viewWithTag:310503];
    UILabel *subtitle = (UILabel *)[root viewWithTag:310504];
    UILabel *label = (UILabel *)[[root viewWithTag:310501] viewWithTag:310505];
    UIButton *discordButton = (UIButton *)[root viewWithTag:310506];
    UILabel *discordCaption = (UILabel *)[root viewWithTag:310507];
    UIVisualEffectView *card = (UIVisualEffectView *)[root viewWithTag:310501];

    CGFloat safeTop = root.safeAreaInsets.top;
    CGFloat safeBottom = root.safeAreaInsets.bottom;
    CGFloat contentW = MIN(W - 40.0, 430.0);
    CGFloat left = (W - contentW) * 0.5;

    CGFloat wordY = safeTop + 4.0;
    CGFloat wordH = 58.0;
    CGFloat chzW = 88.0;
    CGFloat privW = 112.0;
    CGFloat gap = 7.0;
    CGFloat totalW = chzW + gap + privW;
    CGFloat wordX = (W - totalW) * 0.5;
    chz.frame = CGRectMake(wordX, wordY, chzW, wordH);
    priv.frame = CGRectMake(wordX + chzW + gap, wordY, privW, wordH);

    CGFloat subtitleY = CGRectGetMaxY(chz.frame) - 1.0;
    subtitle.frame = CGRectMake(left, subtitleY, contentW, 24.0);

    CGFloat cardY = CGRectGetMaxY(subtitle.frame) + 22.0;
    CGFloat cardH = 394.0;
    if (H < 700.0) cardH = 374.0;
    card.frame = CGRectMake(left, cardY, contentW, cardH);

    CGFloat pad = 24.0;
    CGFloat innerW = contentW - pad * 2.0;
    CGFloat y = 24.0;
    label.frame = CGRectMake(pad, y, innerW, 22.0);
    y += 32.0;
    self.keyField.frame = CGRectMake(pad, y, innerW, 56.0);
    y += 70.0;
    self.didButton.frame = CGRectMake(pad, y, innerW, 54.0);
    y += 68.0;
    self.loginButton.frame = CGRectMake(pad, y, innerW, 54.0);

    CGFloat discordY = CGRectGetMaxY(card.frame) + 14.0;
    discordButton.frame = CGRectMake((W - 58.0) * 0.5, discordY, 58.0, 58.0);
    discordCaption.frame = CGRectMake((W - 100.0) * 0.5, discordY + 62.0, 100.0, 18.0);

    // Keep the bottom controls inside the visible safe area on compact devices.
    CGFloat maxBottom = H - safeBottom - 4.0;
    if (CGRectGetMaxY(discordCaption.frame) > maxBottom) {
        CGFloat shift = CGRectGetMaxY(discordCaption.frame) - maxBottom;
        card.frame = CGRectOffset(card.frame, 0, -shift);
        label.frame = CGRectOffset(label.frame, 0, -shift);
        self.keyField.frame = CGRectOffset(self.keyField.frame, 0, -shift);
        self.didButton.frame = CGRectOffset(self.didButton.frame, 0, -shift);
        self.loginButton.frame = CGRectOffset(self.loginButton.frame, 0, -shift);
        discordButton.frame = CGRectOffset(discordButton.frame, 0, -shift);
        discordCaption.frame = CGRectOffset(discordCaption.frame, 0, -shift);
    }
}

- (UIButton *)buttonWithTitle:(NSString *)title action:(SEL)action filled:(BOOL)filled {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
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
    [button setImage:image forState:UIControlStateNormal];
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
        NSString *b64 =
@"iVBORw0KGgoAAAANSUhEUgAAAMAAAADACAYAAABS3GwHAAA3JElEQVR42u29eZxdVZUv/l1773POHapuDUkqIwlTCAlhnhGp"
@"QItoo4x9IQhPhGAc2vd86kd/6s9+lWr7Y9OvX+vPboc2JiC+RCH1RBl8jWhLCsEBAZGhmAxjgMyp6U7n7L3X749zT9WtDCRF"
@"Vd17q3LW51NAUbdu7bvPd631XWuvvRYhlreVjg4WGzdCYBnQvQoGRLyP16iXt+Rn+ox5AjTfsF1AhHkAzwHTDIZtBdAE5jSB"
@"EiB2maGISAAAM1siaDD5DC6CKEeMfoB2QWAbg9+SLF63zK9BiFddSm0+Yha2dnaS3mvBzNS+ChIAlgG2s5Ns/BT3LxRvwV4I"
@"omwWYtsSUPc+AJZd0duqVOpoQWapNeZ4gI9losPBPAtAs1QJCFLhO4EBtmC2YDYV3zMA3utREBFAAgQCkQSRGPoeACxrGF0E"
@"gF4AWwl4GaDnSOBpy/R02qReXLuWdu255vYOVm094K4uWGBvBY4V4JDHPFP7so2yrW0Zd3WRqfzR1R8rHC6ZT2fCOWB7OoDF"
@"QritUjkgAqwFrNWwNgBbHVlzHn7rcI8pQjGIDrSY8j+5/OoR70VEgoSCEA6EUBAi/A2jA1jr7wLwHAN/FBAPC0uPrluTfHmE"
@"AmdZbtu2kbo3LtunN4sV4BCz9ABQCfrrr+dmP1k8E9ZeCOZ2Jl7qOA2JEOwW1pRgbcBgmMhwh8AEHRjc46exzGAiMHhIQSRJ"
@"h6T0IIQAMxAEg0UiehqgbmbxKy+Z+P1t36TeSmUIP/+h6xkOOQXo6GDR0wOqBH32k4OzpBbvEeAPMnCeVIlZQghYY2BMEcwm"
@"5C+hFRfVA/roFQOAjdZKJKWUCQgpYa2F0cWtBNFtwfd4Kvmr275DWyqVYckS8KEWMxwiChBa+0pLl13JTZL8iwTMVWC+QDqp"
@"FgAwughjfEuAZUBU17JPkKcofxYpXSFVAgCgg1wvkfxPgtgwWMzff9dtLb3726tYASY1t4fs7h4OZq/9eO4sy/I6sL1MOcm5"
@"IRjyYNamHLmKMBqdkvvBINgwtlBSOalIGd4kiJ8xsO7Hq1O/Gwqe21l1b8SUjhWm5IPek+ZccuP2xgan4UoAKwCcq5wEdFCE"
@"tX5Eg8TktfJjpEsAhHBluCclAPwQM25J6sT/ueUWGpjq9IimFvA7RE/PqiHgX3tTbh6kvJHZ3qCc5OGWLXQwGAWwcspa+nfi"
@"GQADglROAwkSCILiqyT4VtK8dv2a9OZhRVjFnZ2dNlaAOuP47e0bZXf3+RoArl5ZOEoSPgXm65WbbNFBCdYWTfhxScaIf9u9"
@"NABDiIRUjgcdFHcDuC3QpW93rW3+S6QIUyVGmOwKQO3tDwwBP3vT7iMcmfwMwDcoJ9EQ+Hmw1ZpBgihMecZy0ATJEtiSUMpx"
@"U9BBcRCgWwNT+EbXmpaXwxjhAdXdfb7B3qd6sQJMtIRWKKQ62Rv6Zziu81kGf9JxkpnAz4Gt0SDIQ4/bT4AqMAwJqRw3jSAo"
@"9hPwncAPvt51a2b7ns8iVoAqZHayV0F0dZE59dRHnYWnHvdxQfRF5XhzYuBXTxF0UHoTbP7peTz73cdWnxZksyy7NsBOtozR"
@"pAJJ2eVqALjmpsGLSMqvKSdxig6KMMbXFAO/OhEzw0jpqnI27XE25ss/XtPwiz2fUawA45jdAVahs5Ns9mM75jqc/pqQ6sMA"
@"QQeDJuT4MfCrrQYEGOWkFcCwRv8woNyXu743/Y2ODhYAMBnSpnUPmkp+ec3Kwg1C0D9K5c0sFfstwCAScXBbU0WwFiB4iYzQ"
@"QXGbteZLt3+/4ZbJEhvUsQJER/Jksit3zXco+U2lEpdpXYAxgSYq1xzHUi8eQUvpKOUkEfiFuzSK/61rdetr9Z4yrUvrGbpQ"
@"4q4uMtd8NL/codQflUpc5pf6jDEBx+CvQ0tKpIwJ2C/2GcdJXupQ8tHlNw1cE3oA4ogWxR7gQIFuB6vuTtIfWPlGKkMt35Aq"
@"udLoAqzxDUjEh1iTwh1YI6QrpUrC6MLq7bkXPvvLdSflomcbK8ABwL98xa4TSCVvc53ESaVSv2FmQSTiIHdyxQZMRNbzMlIH"
@"pSeMzl9/+9rWJ+tNCerELTF1dLDo7iR99cqBD0mVelhK96RisU8DJGPwT0ZKJAggWSz2aZLqJKlSD191U++13Z2kQzrEFCtA"
@"Bd/v7CS7fGXuH12nYb1l06CDQUMkYq4/+RVB6SBnLJsGz2tat/yjAzeH6dH6iAtqqoVRmiyb3dqgWhp/6HrJy0vFmPJMaUqU"
@"yEi/VPip3j3w4a6umYO1TpXWDGQRF7z6IzsPk17qp8pJnFoq9unY6k95RdBeoknpoPhYkN91Rdf/nvtaLeMCqiX4l6/YdYJ0"
@"UncL4S3w/Rj8h5ISuG6TMrb0mi71XbLh1pl/rpUSUK3Af9WN285znMzPIGSLDnKG4hTnoaYERjlpCWt2B0H+sg23tD5YCyWg"
@"WoB/+Yqd75NO+k4GklYX4/z+IasF1giVkAQUTFC84va1zfdVWwmo2uC/akXfB5Xj/QRsHWN8G9fyHPKewErpCpAIAj//N123"
@"tN5dTSWg6oJ/1wcdJ32ntVpaG3AM/lgiJRDCISGUCYLiFRvWNt1TLSWgaoE/u2Ln+xw3fTcbo2Lwx7I/JSApdeDnLulaO60q"
@"dGhCFaC9nVV3N+nsDbvOdb3U/cw2YYwfgz+Wt6NDRCSKxWL/RT/5QdtvIgxN1N+cMCBmsyy7u0lnP7LreMdN3sPMyRj8sbyt"
@"NSYhjPGZmZOe13h39iO7ju/uJh31MJ00CtDRwaKri8zlN+2Y53jJn5OQzdaUTAz+WA5GCawpGRKy2fGSP7/8ph3zurrITFTZ"
@"xPi/KYdFTtdd91Y6IZJ3S+kdZoJ8nOqMZRRaIKQJ8kZK77CESN593XVvpSuxVccKEE4n6ewkq5MN6x03dbLv9+sY/LG8EyXw"
@"/X7tuKmTdbJhfWcn2XDyzfgqwbgqQHsHZHjQ1Xuzl2i4tFTsD+LyhljGQIdUqdgfeImGS5ev6L25u5N0ewfG1ZiOmzZF7TCy"
@"N+28JuG1/ijwBzSAGPyxjIdox21UxdKuD3Wtmfbj8Wy9Mi4eoKODRXf3+frKm3Ye56jUGh3kLbONaU8s4xRWWqmDvHVUas21"
@"H+tf0t19vh6voHgcPEB51NA8uGow94h0Ekt1kDNxE9pYxlkNjHLS0gTFp3VD+gxshj8e3SbGrEXtHZBdXWTEQN+/uon00sAf"
@"1DH4Y5mAiEAG/qB2E+mlYqDvX7u6yIxHPDAmDxDd5rl6RW/WTTRtiHl/LNWKB/xi31V3rG3uGuuNsnfsATo6WHRtgF1+Y26O"
@"UO6/G120zBwfdMUywfEAC6OLVij335ffmJvTtQF2LPHAO/7FjRs3ChAxZPA9RyVbrSlxNPk8llgmjAgRCWtK7KhkK2TwPRDx"
@"xo0bq6sAYZ3P+Tq7Ytf1rtf0Ab8UH3bFUk0tENIv9WvXa/rAVTf1fbi7+/x3XC806hggcjfPbx6cQVI+Q0Qt1vhAbP1jqS4X"
@"skK6YLa72djjFs1r2A6MviP1qEHb0wPq7CTLsP/iuMlp1pQ4Bn8sNeBCIRVyU9MY9l86O8n29IzeoI/qF6KIe/lNuy9QTsN/"
@"al0Ipy3GEkvtxCiVlNYUL/jR6sYHRpsVGoXlZlqyBLxy5aMOIL5Z/n/x9sdSay4EALCWv7ly5aPOkiXg0RTMHbQCZDdAdHaS"
@"7bdHr3QTmUP6tJcIEHU0WluIQ3kwFEkd5IybaDy+3x69srOTbHbDweP64LaNmbAKlN3c1yyFek4IOc2aADhERo8SAVGjRsuA"
@"NoAOGEoRlCrPXK9ZLAiUSsNrESJ8qFz+GR8KTpphhXRg2ew0Rh/bNe8bvVi1ig9mYN9BATh7FQQ6yUrgC14iPcMa305l8BMB"
@"UoRgYgaKJUb/YPgVBEBjmrBkkcL0aYQgqJ31ZQYcBzhxqcKM6eEiBnOMvgFGPs/QuvxZ5BT3EgRhjW89Lz2DgC+gs9Nmrzo4"
@"fB5wSzo6WHR2gq+9KT/XCH6OQElmTVNpO6n8aQiAsYDvM/wgVIJMI2H2LIEjF0gcdbjEgsME2qYLNGUITz6j0fE/80glCbbK"
@"4+CkBPr6GVdc7OKGDyVQKDJ27mK89obBS69YbHrF4PU3LHb1WgQBoCTguqGXwJT0DsxEigHkhcXi9WtSb3R0hBnLt/utA9bt"
@"hKklspr7vui5mbRf7NeYAiOKCECUvNU6pBHWAuk04agjJI5dKHHcIoUjDxeYMW1vY2ItcMJxCqccrfDYcxrpDMGa6ilsEADT"
@"WgiXX+yBGUgmCPPmEObNETjn9PB1A4OMV1+3ePYFjZ7nDV5+zWB3H4MZ8FyC64b7YKeEMhCx1cZNZBpKhf4vAvSpnp4Dl0jQ"
@"wVj/7MrCYYr4WTASk936Rxw5MECxyAADLS0Ci46WOPl4iaXHKsybs2/Ac6Q4FAJGCKDnzwZf+fsckm3VU4DI+i+/3MO1f+PB"
@"2NBbRVadEcYsez6lXbsZz71o8KenNJ5+TmPLNgtjhpUh+pyT3gsQipppcdfq5OsH8gLqYKy/sL2fcxJNqclq/aMg1jKQLzCM"
@"BlqaCaee4ODMUxWOX6LQ2kx7Ab6SHu3Zz4IofM2SEyVOWqzw+MsaDRkC21BLKDIvPJwsZt7H9xgJVKr43X29Bzj0WK3NhPe/"
@"xw0VkUautTJGqFSI1hbCOWconHOGQqEYKsMjj2s88ZTGW1stGKEnUaqs8Dz5nnTZC6S4OPBZgP77gbwA7d/6d4jOzlWcvT43"
@"U3r8AkE0MGtMJusfAd8PwkDW8wiLjpY49wyF005WmN4qRoDF8r4t5/7E2lAxnnhUo+OreSRmEgKfYQzAdhi0QoTvKyQNBdeC"
@"Ru6+tcNfxoZ0bK/3EIDrEAZzjMsvdnHTdYmhNRxs0ByBuvJ38gXGkz0GD/0+wJ+f0ejtY7guIeFNRq/ATKTA4AFTyi3quq1t"
@"a0fHKurs7LSj8gAbsUoApJXbv9JxGxsnm/UXAiiWwoB25gyB957voP0cBwuPHD66sGWLHFlOSaP/G8zAiaconHCswuZBi1nz"
@"BZozAi3NhJYmQiYj0JgGUilCwiN4LqAUDWVmImAaE1p2P2AUS4xCIczo9A8wevstdvcydvcxensZiYTFReeH1n80Z/mVHqJS"
@"GVJJwlmnKpx1qsK2HRa/fUTjwd8FeOlVM/TzSo81CbyAdhOZTMB2JUB/vxEsgX0rwH62L+rtg5RODDwvlDvH6slT80MEFIqM"
@"I+ZLvKfdwbvOdNDUSCMePI1zJJPPMUAh0CdSgiD8bJlGGkebubdnMAZ4/EmNX2708cTTZiidOimUgNkK5ZHV/puqmFu0bt2s"
@"fBkZe61+n4AOr5oRm3TuSjfRONfqop0s4BcidOk3XJPA/+pM46/f46KpMUxTWp64U9xUmobAH9KYEETGjqQ3Ebfe15flPanQ"
@"yPeI8v7jCf4hqlhx7mFtCPbTT1b48mdS+OqXUkilCNpMEgJMJKwuWjfRONckUlcCxPu7PrlPUHcDNnyQ+hPWGp4stF+KkDac"
@"c7qDS97ngigEUJSxmcixe3taUSlCEA1x/oqvoXOHPb4EjXzdnu9BNHzCO6Fxkxjm/sYAi46WuPEaD8U8Y9I0tySCtYYt8ycq"
@"MX1ABchmWaKT7PKVvadJ6Z2p/TxPhpofIiDQQHMTYcW1iSFASlkdq0VVSg5TFdMQoqyAxgDvPtvBeSc5GOhnyElRAUZS+3mW"
@"yjtz+cre09BJdl+XZvZSgG1LynGBpRuVSlCYi5g81Oe6bALTWmnI6scyPnvLDNzwEQ/NLiEwNZ6ve/B+2SonQbDyhhHY3n8Q"
@"zAQQX3Lj9sakcP8ipddmbYnrnfkJAeTzjBOOU1j1hVQM/gmQKN16//8N8G+3FtA0g2B03SsAC+GRsf7WgiktvPuWGQMRxvfp"
@"AcqBAqWEd5HrNbZZU5oUYY+1gOMQbrjGO4TLgifeyFgLXPg+BycerZAbnAzxAJG1JeO6DTNTwrsIAO0ZDI/4CG095RiL+EMA"
@"HVQ5ac0DXxkGvhdf6OLw+XJUB0OxvANICeAj13uQJQJPCmNDDFAZ0+AyxvdFgULXkL2hf4ZQ9BdBMsMc1DX9IQoPj5qbCF//"
@"ahrpchoy9gITT4W+9+0i7v2Nj6bWeqdCzEQOWdb9VuPorlsz2ytpkNiT/pC07/Xchgxb30wG7l8oMq661ENDmoYOuGKZWKPD"
@"DFy13MO0hAjvQ9T5itn6xnUbMyTte/ekQWJP+kNEl4X1U4LrHfz5AmPxQonzz3XCOp6Y+lRHASzQMo1w+Qdc5Hcz6n8ChGAA"
@"LIS8dE8aRJX059prd2R0Um2S0pturV/X9lQIIJdj/I/Pp3DKCSrm/lUlFeG//SLjc5/NYUuJ4Tr1XCbBLIRL1vrbZT44ev36"
@"6f0R5gUAZLOhJ9DpxFmO2zDdmJKte/DnGSefoELwx9a/Jl7ASxKuvNxDqZdR330BiYwpWeWkZ+h04qxKzAtg+ICAWF8khASB"
@"6vvwqwz47KXe0PexVNkIlQvj3n2+g4XzJAr54Rt2dakCICuEBGDfW4l5AQDdnTBlJrTMGgNQ/Vv/0050sOQYGVv/WtohCygH"
@"uPwyF0FfnZ8LEJE1BmT5/ErMi7DXJ3F25a75IHGcMUUAddzmnEPrc/nFbmz968QLnH2eg4WHSRRy9ewFWBhTBIiOy67cNR8g"
@"7uhgITaWvYC06gzHTXvMpm7Tn0IAuQLjpKUKi4+RcclDHYi1gFLABz7gwq9rL0DEbIzjNnjSqjMAYCMgxLLhj3IuhfW2dW9T"
@"P3iROyIbEUvtJLok8652B4fPlCgW6jh9wuCQ3dtzAWAZANFZrpNmiDOstQDV57mGKN/yOvZoiROXqtj615kXcD3gwgsdlHbX"
@"cUaIQNZaAPJ0AOgErEAn2euv390M8GJrSkOBcf05MEAHwEUXuEMdHmKpH2oKAMve42BGo0Dg160XENaUwLBLrr9+dzM6yQoA"
@"8BUdo1Sy2dr6rP0hAko+MHe2wNmnqSGPEEv9PB9rgUwz4ZyzVXg6LOtzpdYGrFSy2Vd0zJC1Z0FLpXIAhqlXC1MsMd59toNE"
@"gmBsXPNTr/Kei1wkmeq3lQrDSOWABS0dVgDQ8fUMKGOAhjRh2bucIYsTS/0ZKWbg8KMEliySKPTVbywQ5nro+Aq+z4tt2NGM"
@"6nFjC0XG8Ysl5swSIzqhxVJ/wTAALLvAgRmsU0NFoPI6jwUA0d7BikCHW6vBXJ8ZIGuB884JrX8c/NZ/MHzaWQptzQJ+sf6U"
@"gBlkrQYBR7R3sBJtW3bOBGOWtQGozjxA1AV5ZpvAKSfEwe9kCYYbGgmnnKxQrMMiOSKQtQHAmDX79XybkOzMA1GGbf31/RQU"
@"Br+nHK+GevDH/H9yyDnnKcigHg8ridhqgCgDpQ8TDDFfqgQx11/7Ey671Sj1GcvkoUFLjleY0ybg12F9EDNbqRLEEPMF2C4Q"
@"pEBUXyUQRIDvA7NnCiw+JvSj8TTiSRIMm/Bk+MSTFEr99VcfRAQWpAC2CwSYD6tLS0JAyWecsETB88r0p3aBU9iv04Qp2Xrr"
@"nV936ys/qNPPUhC6fmu2iGmeItDseqx/47IXOPXE2tGfKK33ds10rd2713811xeNetrX+qL2kNW2wNFaFh0n0dYq0JtnqGR9"
@"9RgMMc9zFANtYAvm+rkGE7U7mdZSQX+o+uCKgDM4wNj8usXOHRZaAw0NhNlzBebMFSMayVYLaHu2Mt+9i7H5dYPe3eH8r6Ym"
@"wpx5AjPaxFAXh2ruYZQNSqUIi46VePDRAE6a6kYBmEFgCwbaFIDWeot/qUx/TjxOorGhuu1OuKKF+qYXDX5+t48n/2Swe6eF"
@"9suBuQSSKcKCBQLL/srBX73fheNURwkq9+JPj2ncd2+A53o0BnrDsago9/FvaCAcvVDiwvc7OKfdqZmSnniywsaHgro7YCpj"
@"vlWBKMNs6uoMIGprvnSxGnpw1ehIHIHLWmD9D0q4+04fpQIjkSR4jeWRQU4IMmuAF7YYPLPa4P5fBvj4JxM4ZvHEdqZjG9Kd"
@"wUHG979dRPevA6B8OT3ZQoCLcOZPuVP2E5s0HvtfGqf9KsAn/jaBGbNE1ZQg+huLl0o0eATjA5Coixt8RCBmAxBlBJjTXGdR"
@"irWA5xGWLKoe/Rlq9eEDN/99Abf/7xIcBWRmEFQbwC2ATQPWAawC4AHJVkLTAsIrfQZf+Yc8/vB7PdRDc0KUUwA7dzC+8vk8"
@"/vMXAdIpQnoGQc4AbBNgU8ProySQmkHIzCc8tknji/8jj5c3mQlb3/7igNlzBebMrr90KIcBUloQKBHeiamPCCA6/W2bRjhs"
@"brhj1di4yPr/278U8HB3gNZWAqcB0wSwU7Zctvzv8pc1gPHD6TCUAv75uwU889z4gywKZgt5xtdW5fHyXwxaWgm2EbAZgNU+"
@"1mcBqwEThGXKuwOLr/5/BWzbbocK1ybckJnQExx9jESQ4zo6xScCLAiUECB268kDEIWD4g6fL+G51Ul/RrTg53f5+PX9Ifh1"
@"CkBjBaDeJuVnTDiJHRL41+8XMDDII4LP8VAAIYAffL+E53sMMk0E3QAgVQH6txGtgVSCsLPX4lu3FIdmHlcjkwcAxy6RgI+6"
@"amDAzACxK5ih6mllEQdfeJQcQU0m0vILEWZSNqwvoaGBYDwAaexnqM7+lSjpAW+8ZfGTe/1xU4BIOZ/rMbj/P3w0NRF0EkBi"
@"dOszBsg0EB7/s0b3b4PwVp2d+GcJAEculEi6BBOgjhqJMpihBNXZ8Dsudxk46nBRFf4fgeD+/+tj5w6GkwS4YXTgGrK05XsL"
@"v/6Nj929PK5U4+47fVgNUKLC8o9STDm2uucXflUG3g3FAXMEprUSdJ1dmCei+rtWrm1oqebNqU4ALGVIEX73kEbCI9gUxnQr"
@"Wilgdy/jkceDUMHGoACRd9qx3eLJJzSSaYJJju39Eh7wyusGL2wyQ952IhWAOSyLmDNPIMhz3ZWziHoqgosuvs+YLtDSNPG9"
@"/qOHv/k1gzc3W7gpgN13Zl33BO2TPSYKEca8vmefMejvZagUwjTsGJSKECYZnurRVaGY0WdYcISEKdZXK3VmtoIIul6WRQRo"
@"w5gzS0y4dap8+K++YlEsMCiJMffEYAYcRXhjix23nPvLm2x4iuqNnUNHFbavvm6r4mEjmX+4CDvO1o+5BRG0AJNfLzUQEegP"
@"myOqYp0i2bkjLCGgMVrXIbdaPqzKF3hMnyN6LDt32LAN4Xisj8O5w719PLTWasQBc+YJuIpgdX0EwmETOPIFg4uh2at9LjS6"
@"7zt3tqiqdSoWOHwoavweejTlfTykVCxPahZjVwAu8yBtuEpAC/89o02gIU0wpXoIhJkBAQYXBYhy9eIBmAHXJbTNqG6k5JTL"
@"G8bLMjGH5wJqnMo3lArHOYzH+ohCLVCKhhWiCgqQaSI0t4QKUDcegCgnwNxPJME1rokmhBYzlQRaW6rrAVpaxbj+LWuBdIqQ"
@"TI4tkI98ckvr+F4HNRZoaiwrQBU4eZQYmDaNoEtccw/ADCaSAHO/ALCrLo4CyrShsVEg00AYcwplFNbpsAUCjjM+zZyIgEAz"
@"Zs8U41YSMf9weeAT6VEYGmsxVGZSlRPh8h5MbxOwQZ2EwCHmdwkCtoFEza9EhhWgjOYMhS6fJ95TRgqw4AiBtjZCMA5tPKJA"
@"/rhjx36SXVlRmU6Wx5GOQxZIyeH1VcMYR1swbTqBdeWc9pphjUECBGwTAL1ZL5XQ1oYzf6uVAaJyWXMiQTjlNIXiwNjvr0Yl"
@"B2ecosacZYkOkuYdJnDMIjnm9UX3rOfOFli8UFYlC1QprdPEcNFezQkHAaA3BRNvrguXVFaApkx1grMRfxjA+z/oIqVoTJmb"
@"aGr92Wc4aJsuxoW3R/Th4ktdmDHO4ZLlLnsXLnPhumGP1WpmgppaCLI8YK8ebC4TbxYg8arlOugKF21ShlBNDYh4+rwFAn/9"
@"fhf9OxjKeYfcPwjXf9Wl7rjdYhMyXN8Z5yiccYpC/26GVO/sc+YLjCMXSFx0gVOTFpONGYKUBK5xC2ZmkGUNkHhVEOxrRhe5"
@"5kVxZcA3VikA3hdvX36di6VHS/T3MZQa3e8TAfk846P/JYG26WJcr3FG7/OxTyYwPSVQLI7uhpwQITUjInzyxgQSXnWvmUZ/"
@"Jp0ux3emth6AiITRRSbY14QpBpvB3E9CoZaHYVEXiHSKarAh4ZeXIHzh8yksmC3R28+Q8sBWUpYtdF8/44ZrE2g/xxn3a4dR"
@"LDBjpsCXPp9E0gknZSr59iCm8v1g3w/vWHzm4wkcu1BWf6h4eY2JZHjmUlsPwExCAcz90Op1seSIaVtB2CKEU/OzAEFAMkHV"
@"dgAjQDZtOuGrf5fCmaco9PUzij4PAUmK8pccbgfePxAqymc+nsQVF7sTBq6Iqi1cJPEPX0njyAUSu/sYQRD+bF/rMwbo62M0"
@"ZQh/97kU3nWmU33wV4jrERwnpEA17PHEQjgAYctbh6W2qc5O0ld/tO8VIdSimqZCy3dePa+m6bGwrUiG8JXPpvDr3wT4+S99"
@"vPK6ge+PfA0R0JwhnHOGi7/5oIs5VbhwHinBgsMEbv67NO6538evun28tTVs10IV3lQKYFqrwPsucHDFBzw0Zaim4AdC6+84"
@"AAc1fcYshIIGXu7uJF1muvSsELgIjJqFwmGVIsF1ahyLV9zkuuDdDs4/18HzfzF48SWD7TvLfYHShPlzBY49RmF6a7jeanZb"
@"YA6BdMXFLi6+0MFzLxhsesViV68dUuDDD5NYfIwciqlqDf6ILkoFcC3LIRhc3ofngHL5F4GfqodrwYIwquBzotN2EWiOXShx"
@"7MJ9R51RqrOa4AonnITpRM8lnLhU4cSlqJv17S8IFqKcBarxkIfwkJWfGlYAy08bHQAEWWvg1dMdtcqub8wYwTGiwLlW641a"
@"IkYdI+ptffvSACHK66lt31JpdACy/PSQAriaXyhSoVdKp2aTIvdq30f1pwj1KBHQJ4vUdqnMQjikdaE3ofkFABDoYHHbbS29"
@"AD0rpAfU0Z2dWKae8F7/UVWxQnogUM9tt7X0ooOF6ChfAiTYR4QQUdvc2gSfFZ4A8SywKYd6yzXuEM1gIQSI8AgAdABCbBx2"
@"9A+FzYJq56WYx+8WVSz1Z/WtYRhTw/sABGJmMONhANgIQCwrUx4j9COBnysRSVmrE2G2YYuSWKamGIOq9CPan3klkjLwB0tG"
@"6EcAYBlgRWcnWYCpa3Xra2D7jJQJILy/X3UKZJnhBzH3maqiddj2pjYKQDbENp7uWt36GsDU2UlWAEB7R5j+JEEPiNAB1ASF"
@"1gLFUgyUqSp+iREEYXOsqgOMmYWUYMLGSswLAGjrCddjIe631oDBNUn8MQOFqJVIlRXPmvqdZTURn9fU4POWimUPUIPTJgYL"
@"aw0Ae38l5gUAdHWFcYDKFX8f+IM7pPREtbeHygqQyzOqpQGVo4aEHC6L5imYCOZyO/fo80qJce1gfTD7nM+HxXvVL7xnltIT"
@"OshtVzn9+0rMl5dCnM2yXL9+ej8J+YBUCQZTdfMxZV44MMhVU72Ii/6f20u46yc+BsojPaMT1snuFYamR0blEDK0/A8/GGDN"
@"d4soFrmqSjAwUM4CVVsBmEyIabFx/frp/dksy+hm8lDlzbYl4em6teYuArKApTH3CRydjwIQXtkLA2JMWF1G9MC3brFY890i"
@"HvmdBgG49y4f57xLof0CB0culEOu2pZ78JOo/1PXobIIjJxuuWO7xcMPamz8zwCvbDLQAfDkEwYf/3QCixfLCb0gYw2gnDIF"
@"0mUKVFXDYgkAscDPAFAZ6xihAN2dMACYjbi/5A/2C+FmmKtXFmE5LOx6qiesupwxbfhO7XivILoOuHM7Y/OrFoKAxDTCoMf4"
@"6f0+7vtFgGOPkXjXux2ceobCtBm0l1WN1lUPCsE23L+o9idaU7HAeOrPBg89GOCJRzV272QkEoRkA6EAxk5jsfktiyWL5YTh"
@"0ZTB7/uh51FOuclXFU0CCVf6/kC/1fglAC5jvZJ4hJLNsuzqInP1R/vudN3MZYE/YDBuDQMPjpKUSoxMRmDFVR7OPXfiphtG"
@"Fs8Y4D/u83HPAz7e2mKRShOUBPK9DD0AtDYQFi9WOP1MheNPkpgxU+yTZlQqw0QqRWXx276K3XI5xvM9Bo/+QeOJxzXe3GwB"
@"C6QawyF6OcNonE54z/kuLv9rF02NE3M9snJP/vK8wXf/rYhNLxikUwTbijF3uR6FaMdtlL7f/7M7vt90RYTxvTxAJQ0iph8B"
@"fHmoq1RFXQ1blOTyjH/+dgF/elzj+g8nkGmmcfcGEfeVEvjAxS6WLXNw/wMB7n/Ax5tbLLwUoaEVKJWA3z0V4OE/BGhKE448"
@"QmLpCRJLjldYcKRAQwPtdT93RIUmRq8YleUgUZFnRL/23AOtgTc3Wzz3rMFTT2i88KzBti0WxoSjXBtbCYEABi2jaRrhg+e4"
@"uPhCF7PbxIQYl8ggSBl6pp/cUcKGH/kIfEa6oTx/QVWTAjEBXMb0SPqzlwcoA54vuXF7Y1J6L0rhzrS2VPXqUKLwgQ/0MeY0"
@"CVz/oQTOfrcacqnjPTK1EgS5PKP7twF+1R3gpVdDQ5FMEaQAdAkoDTB0DnAJaG0WmL9A4KiFEkceLTF3vsD0GcMtESeCTuze"
@"xXjrTYtXXjLY9KLBy5sstr5lkc+FsZOXJDgpAC5QsAxNwOxZAued7eDC85yhvqsTQS8r93HTiwa3fK+EJ/+k0ZAmiARgG8J1"
@"Va/cklkIj4z1txZMaeHdt8wYiDC+HwUA2jtYdXeSXn5T33fcROYTfrFfg6gm11SkBEo+EAwyzjvNwXX/xUPbrImzXFEPywhs"
@"jz+p8cBDAZ59waBQ4DBVKoYbaukC4OcYpgAICyQ9QnMTYfoMgbZZhLaZAtPbBJpbCJkmQipNSCQAxw1pFonh9K8x4Wxfv8TI"
@"5xmDA4y+XsbOHYzt2yy2bbHYvpWxa6fF4MDwXWDHIzhJQHrhcA+WAIuQdx8xX6L9bAdnnaqQTtOEAb9y70ol4M47SvjZT3z4"
@"xdDqmwTCmWtU5eCXWbuJjPKLg9+5fU3j30bYrnzJXsCODggg+Batix+v5XRXYwBHAW4rYeMTAZ7sMbjyEhd//UEXUmFoguR4"
@"rDACRfQwpQROP1nh9JMV/vlbBTz8xwBpRUO5dABQKcBpCKsH2QA2AHYWGVtf1njyOYRtAMuKqmTYEsRxws7M0cX1KONlDaB1"
@"CGwdAEHAQ4dVRIBQgHIJygUSrYRUBPYy4E0ZXESA9oFpLYRVn0+NuNQz3hdkuFzdGZ2h/PH3Gut+UMJLLxo0pAmpZoJJV1j9"
@"qqeUSeigyBDm1hHY3j8FKksHC3SSvXpF7+8cr+FMHeRsbc7vRnqDwAD53Yxj50tcc7WHU85QE+rOI1f+/34hD9lQtmIHOMsY"
@"WkfkaMsHa2xChWBT/r5ypm/l75ZvTZEAUPYSEBGTDV/HNDJ1vOdjFSI8T/nbFUm8d5kzxMknAvgA8NorFrevK+G3vwkgBYZn"
@"mSVrYPWHV2mUkxZBafAPd6xtPjvC9J6v2ie1aQdEN2AF0XeFkGdVtYvS23gDCaBpBmHTToOv/nMeZ53kIJt1ceQxckIUQQjg"
@"jvUllHKMhgSF2WR++7MM5n28pAxiuCEexAGOQ0Y0gua3++H+Aeq5hDvvLeHdZykkE+OT6Rlh8SWwayfjrp+UcP9/BMgPMhoa"
@"CJwATDTLzKJ29zqYIYQkQfTdSkwfnAco25jrrtuS0on080K5c2zY2L0uLgcKEa58sJ+RMIT2sxxceoWLufMrArwxUKMovnj0"
@"EY1/+Eo+zF40VzV1Ny4es6+f8aErPVxzhTemmGlPiz/Qz7jvXh//cW+A7VttGOQmAZtEOMcMtd0nZrZSeWS1/6Yq5hatWzcr"
@"X4b7Pm3Tvnw5t3dArls3O0eE1Up5hDq6KhkVrzVkCKIZuO93Pr7wxRxWf6uIN16zI8sZ7OgfNhAe3Ky7pRR2MUhMLvBHHrMh"
@"TbjnvjCtK8ToR7buWUbR38e48w4fn/tUDj9cW0KuP0ytogWhgfAwbnMMxsT8AauUR0xYvW7d7FxY+bnvpuz7tQnLsMoCTNov"
@"rPb9XD8JJeutMiYs7gMy0wimEbj3QR9f+EIO3/56eOhSGfQdbF1PZCnvvrOETS8aJNMApzApRQogV2DcdkfpoK1yZDSirI4Q"
@"wPZtFj/+YQmf+1QOt64uondnCHzZCpjmMtfnejEQzCSU9P1cv/ULqwGmEMv7VZb9y9DJ8E293/QSTf+tlinRg3rgKrxxlN/N"
@"SFjCyccrvPd9Dk4+XY3IhlRmffYF/s2vW3z+v+ZCn5cB8A4nx9eLEvQPMr7wX5M4921aI0b7Uvmzv7xg8Kv7Avz2oQC7dzCS"
@"SYKbBmwCoVcUdbgvQ6nPgW/evibz3/c8+T2oIDiSJUvAAJMVhX8JgvxNJFSCWXO9loSZcnvAzPSw9/0fng3wyJ8CHHWYRPsy"
@"B2ef52B6RV2PLXcpFhUD6JiB73+7iEKekW4un1xO4vJoy0DCI9z6oxKOX6yQqSh9iGqIopQsAORzjEcf0XjgVwGe+bNBscBI"
@"pghNMwg2ARivAvh1ty/MJJQIgnzeCPV1gCnE8NvSpbeXIS+wou9bXjLzt/XuBUbwu3LQVhxk+P1Aa4pw8kkK57Y7OP4kBS8x"
@"/NogCHP09/zUx+pvFdHURDBNYeZmsneokDJs4rvsXQ4++4kktB7ZgY8ZeOE5g4cfDPDI7zTe2hwWCCYbysFt+ZANVOfGoGz9"
@"S4X+b9+xtulTB7L+B/QAlV5AUf7mwM9fT0Kl6tkL7BUjAPDShGQmvG75wB8DdD8cYG6bwCmnKpxxjoNjFku4LvDySxbrbi2h"
@"IU3DGY0pcDkmGtu08eEAJy1VuODd4YCMV14yePQRjT/+XuOlv1j4BYaXJDS0EuCFwDdyjxRsHaOfhBKBnx9UpG4+GOt/UB6g"
@"0gssX9F7s5dq+n9KhcnjBUZ8WBquRffzQKmP4VhgTpvEyadKPPOUwcsvGSQz5bTnFBKisHAunSacf5aDnkc0XtpkUcgxXDc0"
@"EiIBWLc8kV5MBtCPtP5eMqMKhf6bN6xp+tLBWP+DVgAwE1aBspv7mqVUzwmS06wJAIKYtIAQw+3G/Rzg9zM8IjgC4ObJl/Y8"
@"WCWwNiz4cwYBTxBkqgx6hfCkkSfh52ZYIR1YNjuFTC9a2Ia+zlVg0IHnUYqD3DnO9oC61jbvgtWdykm8g6xyne2ZDYNmtoCb"
@"BjJzCc5MgFunJvgjri8obJ+enEXAdMA07sHvJ+XntqychIDVnT/6Lu3uOQ50MOA/eA8Qbh91dIDeeusx2W+PeUw5yeO1zpta"
@"1wjFcqgLG6VSUgeFpzLihVNnzz7VdHaCD3Ya8SgoDHFPD2j16tMCIejTo9afWGKZGGIXAlnQp1evPi3o6QGNZhT3qDh8VxeZ"
@"bJblj1Y3PhD4+fWu1yjBNu7mGUuteKxxvUYZ+IPrf7S68YGDDXzfIQUKpaMjbJr1/ObBGSTFM0SixRof9VIoF8uhAn62Qrpg"
@"trvZ2OMWzWvYDgCdnaNr6zlq0HZ2ku3pAd2+tnGrsfqzYUAczxSIpfqRr3ISwlj92dvXNm7t6QGNFvzvSAEiKtTe/oDasKbp"
@"h36p717Xy6iYCsVSXeqTUX6p794Na5p+2N7+gBot9RmTAgDAsmXLLJgJxvlYoAu7hPSImWNPEMsEMx+2QnoU6PwuGOdjYKZl"
@"y5a9Y9yNKY0zXCfUm3UTTRsCf0Cjin2EYjkkRTtuo/KLfVfdsba5650EvuPiAYaoUAerO9Y2d/mlvjVeolEx23jERSwTFfdq"
@"L9Go/FLfmjvWNne1d7AaC/jH7AHKy6JsFgLz4KrB3CPSSSzVQS4+IItlvOFvlJOWJig+rRvSZ2Az/LDDM43p7Ho8GorwkiXg"
@"rm9QQQt7tbVBnkgRs41HvcQyXpafiRRZG+S1sFd3fYMKYaUnjRlj43aU297+gOruPl9f9dHe5Z7b9OM4HohlvHl/qdB3zYZb"
@"mm+PsDYebzxuh1fd3efr9g5WG77ffHup2PdPYTzAQfzsYhmb9efASzSqUrHvnzbc0nx7ewePG/jH1QNE8UB7B2R3J+nlH+37"
@"metlLi0V+zSRiD1BLO8w6G1Sfqn/rtu/33RZ2NoQZjyozwQpAABm6lgF2rRpS9KkMr9RTvLkoNRvQCIOimMZBY6scbyM1EHh"
@"TzLf/+6jjppVONga/5pQoGGVChe4bt3sXNEWLjG69Lp0UnHRXCyjAr90UtLo0utFW7hk3brZuUpsjStcJ+ozRAcU2Y/sOt7x"
@"kg8CaDamZIlEXDQXy9vRHhsOaURvUCqc1/WD1qfGethVEwUAgPZ2Vt3dpLM37DrX9VL3M9uEMT7HShDL/sHvEpEo+qX8e7tu"
@"bX0owtBE/c0JBWJ3N+n2DlZdt7Y+FOji5RBCC+EQs41rhmLZC/xCOAQhtB/krui6tfWhMONDE1pZMOGWuLszVIINa5p/of38"
@"lUIoEytBLPsCvxDKaD9/Zdfaaffta5jFpKNAI+hQ+QNdtaLvg8rxfgK2jjF+HBPE4LdSugIkgsDP/03XLa13Vwv8VVWASiXI"
@"rtj5PtdJ38lA0upinCI9ZNFvjVAJSUDBD4pXdK1tvq+a4K8KBdoXHepaO+0+rfMXEWO3dNKS4xTpoWj5jXTSkhi7tc5fVAvw"
@"V10BKpXgjjWtvzE6vwzWvOp6TTIuoz6kwK9dt0mCzauB33f+HWtaf1ML8FedAu2LDl39kZ2HSS/5U+UkT43LJg4N8HuJJqWD"
@"4mOmlL/8jh9Me71W4K+pAgAVh2XZrQ2qpfGHrpe8vFTsN8wsiETcdGhqAZ+JyHqJjPRLhZ/q3QMf7uqaOTiRh1x1rwBA2GYl"
@"us2/fGXuHx0n9UUd5MGs40s1Uwf+hkhJ5aQQBPmbb1+d/tKez/6QVYDyBlFHR9jW4uqVAx+S5HxPSKch8AdiSjQFKI/jNio2"
@"wWBgih/fsKZ5fQj88bnQMkUUYGRcsHzFrhNIJW9zncRJpVJMiSY15fEy0g+KT7AuXH/72tYna8n39yV1dQgVZYhuX9v65ADv"
@"elcQFFY7bkZK6VJcTTqZ0G+NlC45bkYGQWH1jtzz59Yj+OvOA+wrLrjmowPLSTjfVMpr80t9hkGCiGJvUJdWn5nA1vWapNal"
@"bWyDT//4+4231wvfnzQKEMUF2SxEVxeZ7Mpd8x1KflOpxGVaF2BMoGkSTqiZ4uDXUjpKqSS0Lv4s4MKnu1a3vhZmecbeveEQ"
@"VIBQKtNk16wcvEEI9Y9SeTNLxX4LMOJaoppzfQsQvERG6KC4jRlf/PHq5K17Prt6lUlBJTo6OgSwCp2dZLMf3jHXSaS/JqT6"
@"MEDQwWBMi2pGd2CUk1YAwxr9w4ByX+763vQ3og7i9Uh5JqUCRFLZDuPalYPvZVJfU453qg6KMMbXRJCTYXrl5Ic+jJSuUk4C"
@"Oig+zsZ8+cdrGn6x5zOaDEKTcP8pe1UYG7S3s5q9KP8JQfKLyvHmBH4ObI1GrAgTsvFgGBJSOW4aOii9aZlvfhHP/Ptjq08L"
@"slmWXRtgJ+LebqwAB4gNsjf0z3Bc+VmQ+IRSiaZYESYO+EFQ6CfQdwI/+HrXrZntk4XrTzkFiNbf3v6AjFxu9qbdRzjS+wyA"
@"G5STbAj8PNhqHcYIiIPl0cHeEtiSUMpxU9BBcRCgWwNT+EbXmpaXK+iOwSSeqTlFrONwyhQArl5ZOEoSPgXm65WbbNG6BGuK"
@"Jvy4cX3RAfbSAAwhElI5HrRf2A2i2wzjW3esTm4atvj1m9o8BBUglI6ODtHTs4oiRbj2ph3zrEzdSIwblJM83LKFDgYZDANA"
@"Is4cDcW1AAwIUjkNJEggCPKvCpK3wJhb1q9Jb46Av2TJKu7s7Jwy97mnJAA6Olj09GBIES65cXtjg9NwJWBXAOLccvYC1voR"
@"bxWHXqzAjPJsNyFcGe5JCQA/BGDtYJD4yd230MAw8MGTIa0ZK8AeGaP2ZZCVrTWu/XjuLMt0HRiXKSc5FwCGy68BMMSU9QzM"
@"DApBH5Unh5+/8IYg8TOQWLf+393fRy9vb2fVvRFmsmV2YgXYb4wwzFuzK7lJUuEiwbgK4Aukk2oBAKOLMMa3BFgGBBFo8noH"
@"ZmZw9FmkdIVUCQCACfK7QfRrC7mhUMzff9dtLb3726upLIccB96THgFA9pODs5Rx/gqsLwFwnlSJWUIIWGNgTBHMxoDBIFB9"
@"06UyrSmvlUhKKRMQUsJaC6OLWwh40ILu8VTyV7d9h7YM7cEUpjmxAryNVwDCWWfR/73++t3NfjJxJtheCMvtTLzUcRoSRIC1"
@"FtaUYG0QBdIAgZhB1fUUZctOYPBQClKSdEhKD0IIMANBMFgkoqcB6mbmX3nJ9O9v+yb1VoI+/PyHhrWPFeBtY4WNsq1tGe95"
@"oHP1xwqHK9BpFvZdYHs6gxdL4bZK5SJUCsBaDWsDsNVgZks0nBdnDvc4VJDyfx3YiofHT+GrR7wXEQkSCkI4EEJBiPA3jA5g"
@"rb8LwHMg8QgxfutQ8o+3fY9eqXz3bJbltm0bqXvjsinN7WMFGKNn2LYEtK/LG9kVva1KpY5m6y8lEksBPpZhjwBjFoBmqRIQ"
@"5UptBgNswWzBbCq+Z+x9dkRh7E0CBAKRBJEY+h4ALGsYXQSAXhBtIeZXAHpOSPmUsfYZY1Ivdq2lXXuuub2DVVsP+FC29LEC"
@"jCFm2LgRAsuA7lX7zoh0dLDq2ZKfKRnzBGi+BebD6sMgaA6YZzDQSqAMs20gUALELjMUEYkyobFE0GDyGVwkEoNgHmDQLhLY"
@"xuC3wOJ1Yn4NQrzqEjYfMSu1tXNft6uYqX0VJDYCy5bBHmqcfrTy/wOCN4l8LMiv7QAAAABJRU5ErkJggg==";
        NSData *data = [[NSData alloc] initWithBase64EncodedString:b64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
        image = [UIImage imageWithData:data scale:3.0];
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
