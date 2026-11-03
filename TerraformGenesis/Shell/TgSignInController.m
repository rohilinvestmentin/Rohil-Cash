//

//

#import "TgSignInController.h"
#import "SceneDelegate.h"
#import "TgPaneWebController.h"
#import "TgPureLinks.h"
#import "TgParcelRegistry.h"
#import "TgPersonaVault.h"
#import "TgPolicyVault.h"
#import "TgPulseOverlay.h"
#import "TgSensorLattice.h"
#import "TgTraceRelay.h"
#import "TgWireConduit.h"
#import "TgPayloadModels.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import "NSString+TgGlyph.h"
#import <Masonry/Masonry.h>

static NSString * const kTgSignOtpSentHint = @"OTP has been sent";
static NSString * const kTgSignNotAvailable = @"Not available";
static NSString * const kTgSignPhoneEmpty = @"Please enter phone number";
static NSString * const kTgSignPhoneBad = @"Please enter correct phone number";
static NSString * const kTgSignOtpBad = @"Please enter correct OTP";
static NSString * const kTgSignPactBad = @"Please read and accept Privacy Policy and Service Agreement";

static NSString * const kTgSignPactIconOn = @"due_Terms_yes";
static NSString * const kTgSignPactIconOff = @"due_Terms_no";
static NSString * const kTgSignLinkHex = @"#3D59FF";
static CGFloat const kTgSignLogoTopInset = 50;
static CGFloat const kTgSignInputBelowApp = 80;
static CGFloat const kTgSignPactBelowInput = 30;
static CGFloat const kTgSignCommitBelowPact = 30;
static CGFloat const kTgSignCommitHeight = 56;
static NSInteger const kTgSignOtpMaxLen = 6;
static NSInteger const kTgSignCountdownSec = 60;

@interface TgSignPactTextPane : UITextView
@end
@implementation TgSignPactTextPane
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender { (void)action; (void)sender; return NO; }
- (UITextRange *)selectedTextRange { return nil; }
- (void)setSelectedTextRange:(UITextRange *)range { (void)range; }
- (void)layoutSubviews {
    [super layoutSubviews];
    for (UIGestureRecognizer *g in self.gestureRecognizers) {
        if ([g isKindOfClass:[UILongPressGestureRecognizer class]]) {
            g.enabled = NO;
        }
        if ([g isKindOfClass:[UITapGestureRecognizer class]]) {
            UITapGestureRecognizer *tap = (UITapGestureRecognizer *)g;
            if (tap.numberOfTapsRequired > 1) tap.enabled = NO;
        }
    }
}
@end

@interface TgSignInController () <UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, strong) UIScrollView *tg_scrollPane;
@property (nonatomic, strong) UIStackView *tg_formStack;
@property (nonatomic, strong) UIImageView *tg_brandMark;
@property (nonatomic, strong) UILabel *tg_brandCaption;
@property (nonatomic, strong) UILabel *tg_dialCaption;
@property (nonatomic, strong) UITextField *tg_dialField;
@property (nonatomic, strong) UILabel *tg_otpCaption;
@property (nonatomic, strong) UITextField *tg_otpField;
@property (nonatomic, strong) UIButton *tg_otpLatch;
@property (nonatomic, strong) UIButton *tg_pactLatch;
@property (nonatomic, strong) TgSignPactTextPane *tg_pactPane;
@property (nonatomic, strong) UIButton *tg_commitLatch;

@property (nonatomic, assign) BOOL tg_pactEngaged;
@property (nonatomic, assign) BOOL tg_otpRelayBusy;
@property (nonatomic, assign) BOOL tg_commitRelayBusy;
@property (nonatomic, assign) BOOL tg_pactNavBusy;
@property (nonatomic, assign) NSInteger tg_countdownLeft;
@property (nonatomic, strong, nullable) NSTimer *tg_countdownClock;

@end

@implementation TgSignInController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.tg_backdropStyle = TgHullBackdropStyleUseBg0;
        self.tg_showsBackButton = NO;
        _tg_pactEngaged = YES;
    }
    return self;
}

- (void)dealloc {
    [self.tg_countdownClock invalidate];
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self tg_warmManifestIfNeeded];
    [self tg_buildForm];
    [self tg_bindLatchActions];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    self.tg_pactNavBusy = NO;
}

#pragma mark - UI

- (void)tg_buildForm {
    self.tg_scrollPane = [[UIScrollView alloc] init];
    self.tg_scrollPane.showsVerticalScrollIndicator = NO;
    self.tg_scrollPane.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:self.tg_scrollPane];

    UIView *centerWrap = [[UIView alloc] init];
    [self.tg_scrollPane addSubview:centerWrap];

    self.tg_formStack = [[UIStackView alloc] init];
    self.tg_formStack.axis = UILayoutConstraintAxisVertical;
    self.tg_formStack.spacing = 16;
    self.tg_formStack.alignment = UIStackViewAlignmentFill;
    [centerWrap addSubview:self.tg_formStack];

    self.tg_brandMark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
    self.tg_brandMark.contentMode = UIViewContentModeScaleAspectFit;

    self.tg_brandCaption = [[UILabel alloc] init];
    self.tg_brandCaption.text = [self tg_bundleDisplayCaption];
    self.tg_brandCaption.font = [UIFont tg_meshGlyphWithSize:18 weight:UIFontWeightMedium];
    self.tg_brandCaption.textColor = [UIColor tg_accentTone];
    self.tg_brandCaption.textAlignment = NSTextAlignmentCenter;

    UIView *brandWrap = [[UIView alloc] init];
    [brandWrap addSubview:self.tg_brandMark];
    [brandWrap addSubview:self.tg_brandCaption];
    [self.tg_brandMark mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.centerX.equalTo(brandWrap);
        make.width.height.mas_equalTo(88);
    }];
    [self.tg_brandCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_brandMark.mas_bottom).offset(12);
        make.left.right.equalTo(brandWrap);
        make.bottom.equalTo(brandWrap);
    }];

    self.tg_dialCaption = [self tg_fieldCaption:@"Mobile Number"];
    self.tg_dialField = [self tg_roundFieldWithPlaceholder:@"Please enter mobile number"];
    self.tg_dialField.keyboardType = UIKeyboardTypeNumberPad;
    self.tg_dialField.delegate = self;
    self.tg_dialField.leftView = [self tg_dialPrefixPane];
    self.tg_dialField.leftViewMode = UITextFieldViewModeAlways;

    self.tg_otpCaption = [self tg_fieldCaption:@"OTP"];
    self.tg_otpField = [self tg_roundFieldWithPlaceholder:@"Enter OTP"];
    self.tg_otpField.keyboardType = UIKeyboardTypeNumberPad;
    self.tg_otpField.delegate = self;

    self.tg_otpLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    self.tg_otpLatch.contentEdgeInsets = UIEdgeInsetsMake(0, 12, 0, 16);
    [self tg_applyOtpLatchTitle:@"Get" underlined:YES];
    self.tg_otpField.rightView = self.tg_otpLatch;
    self.tg_otpField.rightViewMode = UITextFieldViewModeAlways;

    UIView *pactRow = [self tg_buildPactRow];

    self.tg_commitLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_commitLatch setTitle:@"Sign in" forState:UIControlStateNormal];
    [self.tg_commitLatch setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.tg_commitLatch.titleLabel.font = [UIFont tg_meshGlyphWithSize:17 weight:UIFontWeightBold];
    self.tg_commitLatch.backgroundColor = [UIColor tg_accentTone];
    self.tg_commitLatch.layer.cornerRadius = kTgSignCommitHeight / 2.0;
    self.tg_commitLatch.clipsToBounds = YES;

    [self.tg_formStack addArrangedSubview:brandWrap];
    [self.tg_formStack addArrangedSubview:self.tg_dialCaption];
    [self.tg_formStack addArrangedSubview:self.tg_dialField];
    [self.tg_formStack addArrangedSubview:self.tg_otpCaption];
    [self.tg_formStack addArrangedSubview:self.tg_otpField];
    [self.tg_formStack addArrangedSubview:pactRow];
    [self.tg_formStack addArrangedSubview:self.tg_commitLatch];

    [self.tg_formStack setCustomSpacing:kTgSignInputBelowApp afterView:brandWrap];
    [self.tg_formStack setCustomSpacing:8 afterView:self.tg_dialCaption];
    [self.tg_formStack setCustomSpacing:8 afterView:self.tg_otpCaption];
    [self.tg_formStack setCustomSpacing:kTgSignPactBelowInput afterView:self.tg_otpField];
    [self.tg_formStack setCustomSpacing:kTgSignCommitBelowPact afterView:pactRow];

    [self.tg_dialField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(50);
    }];
    [self.tg_otpField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(50);
    }];
    [self.tg_commitLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(kTgSignCommitHeight);
    }];

    [self.tg_scrollPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [centerWrap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.width.equalTo(self.tg_scrollPane);
        make.height.greaterThanOrEqualTo(self.tg_scrollPane);
    }];
    [self.tg_formStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(centerWrap).offset(28);
        make.right.equalTo(centerWrap).offset(-28);
        make.top.equalTo(centerWrap.mas_safeAreaLayoutGuideTop).offset(kTgSignLogoTopInset);
        make.bottom.lessThanOrEqualTo(centerWrap.mas_safeAreaLayoutGuideBottom).offset(-24);
    }];

    [self tg_refreshPactLatchImage];
}

- (UILabel *)tg_fieldCaption:(NSString *)text {
    UILabel *l = [[UILabel alloc] init];
    l.text = text;
    l.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightMedium];
    l.textColor = [UIColor colorWithWhite:0.22 alpha:1];
    return l;
}

- (UITextField *)tg_roundFieldWithPlaceholder:(NSString *)placeholder {
    UITextField *f = [[UITextField alloc] init];
    f.backgroundColor = UIColor.whiteColor;
    f.layer.cornerRadius = 12;
    f.clipsToBounds = YES;
    f.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightRegular];
    f.textColor = [UIColor colorWithWhite:0.15 alpha:1];
    UIColor *phColor = [UIColor colorWithWhite:0.65 alpha:1];
    f.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder ?: @""
                                                             attributes:@{ NSForegroundColorAttributeName: phColor }];
    f.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14, 1)];
    f.leftViewMode = UITextFieldViewModeAlways;
    return f;
}

- (UIView *)tg_dialPrefixPane {
    UILabel *code = [[UILabel alloc] initWithFrame:CGRectMake(14, 0, 44, 50)];
    code.text = @"+91";
    code.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    code.textColor = [UIColor tg_toneFromHex:kTgSignLinkHex];
    UIView *wrap = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 58, 50)];
    [wrap addSubview:code];
    return wrap;
}

- (UIColor *)tg_signLinkTone {
    return [UIColor tg_toneFromHex:kTgSignLinkHex];
}

- (UIView *)tg_buildPactRow {
    self.tg_pactLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    self.tg_pactLatch.adjustsImageWhenHighlighted = NO;
    self.tg_pactLatch.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.tg_pactLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(22);
    }];

    self.tg_pactPane = [[TgSignPactTextPane alloc] init];
    self.tg_pactPane.editable = NO;
    self.tg_pactPane.scrollEnabled = NO;
    self.tg_pactPane.backgroundColor = UIColor.clearColor;
    self.tg_pactPane.textContainerInset = UIEdgeInsetsZero;
    self.tg_pactPane.textContainer.lineFragmentPadding = 0;
    self.tg_pactPane.delegate = self;
    UIColor *pactBodyTone = [UIColor tg_toneFromHex:@"#686868"];
    UIColor *pactLinkTone = UIColor.blackColor;
    self.tg_pactPane.linkTextAttributes = @{
        NSForegroundColorAttributeName: pactLinkTone,
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
    };

    NSString *full = @"Please read and accept privacy policy and service agreement.";
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:full];
    UIFont *font = [UIFont tg_meshGlyphWithSize:13 weight:UIFontWeightRegular];
    [attr addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, full.length)];
    [attr addAttribute:NSForegroundColorAttributeName value:pactBodyTone range:NSMakeRange(0, full.length)];

    NSRange rPrivacy = [full rangeOfString:@"privacy policy"];
    NSRange rService = [full rangeOfString:@"service agreement"];
    [attr addAttribute:NSLinkAttributeName value:[NSURL URLWithString:@"tg://privacy"] range:rPrivacy];
    [attr addAttribute:NSLinkAttributeName value:[NSURL URLWithString:@"tg://service"] range:rService];
    [attr addAttribute:NSForegroundColorAttributeName value:pactLinkTone range:rPrivacy];
    [attr addAttribute:NSForegroundColorAttributeName value:pactLinkTone range:rService];
    [attr addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:rPrivacy];
    [attr addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:rService];
    self.tg_pactPane.attributedText = attr;

    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[self.tg_pactLatch, self.tg_pactPane]];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.spacing = 8;
    row.alignment = UIStackViewAlignmentTop;
    return row;
}

- (NSString *)tg_bundleDisplayCaption {
    NSString *name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (name.length == 0) {
        name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    }
    return name.length > 0 ? name : @"App";
}

- (void)tg_bindLatchActions {
    [self.tg_otpLatch addTarget:self action:@selector(tg_onOtpLatchTap) forControlEvents:UIControlEventTouchUpInside];
    [self.tg_commitLatch addTarget:self action:@selector(tg_onCommitLatchTap) forControlEvents:UIControlEventTouchUpInside];
    [self.tg_pactLatch addTarget:self action:@selector(tg_onPactLatchTap) forControlEvents:UIControlEventTouchUpInside];
}

- (void)tg_refreshPactLatchImage {
    NSString *icon = self.tg_pactEngaged ? kTgSignPactIconOn : kTgSignPactIconOff;
    [self.tg_pactLatch setImage:[UIImage imageNamed:icon] forState:UIControlStateNormal];
}

#pragma mark - Config

- (void)tg_warmManifestIfNeeded {
    [[TgPolicyVault shared] ensureManifestCachedSuccess:nil failure:nil];
}

#pragma mark - Actions

- (void)tg_onPactLatchTap {
    self.tg_pactEngaged = !self.tg_pactEngaged;
    [self tg_refreshPactLatchImage];
}

- (void)tg_onOtpLatchTap {
    if (self.tg_otpRelayBusy || self.tg_countdownLeft > 0) return;

    NSString *mobile = [self tg_resolveWireMobileShowingToast:YES];
    if (!mobile) return;

    [TgTraceRelay emitSignal:TgTraceSignalSmsTap];
    self.tg_otpRelayBusy = YES;
    self.tg_otpLatch.enabled = NO;
    [[TgPulseOverlay shared] veilSpin];

    NSDictionary *sign = @{
        @"mobile": mobile,
        @"verifyType": @1
    };
    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneSmsVerify
                             signData:sign
                           nonSignData:nil
                              success:^(id _Nullable data) {
        (void)data;
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.tg_otpRelayBusy = NO;
        [[TgPulseOverlay shared] veilDismiss];
        [[TgPulseOverlay shared] whisperLine:kTgSignOtpSentHint];
        [self tg_beginCountdown];
    } failure:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.tg_otpRelayBusy = NO;
        [[TgPulseOverlay shared] veilDismiss];
        if (self.tg_countdownLeft <= 0 && !self.tg_countdownClock) {
            self.tg_otpLatch.enabled = YES;
        }
    }];
}

- (void)tg_onCommitLatchTap {
    if (self.tg_commitRelayBusy) return;

    NSString *mobile = [self tg_resolveWireMobileShowingToast:YES];
    if (!mobile) return;

    NSString *otp = [NSString tg_digitsOnlyFromMixed:(self.tg_otpField.text ?: @"")];
    if (otp.length != kTgSignOtpMaxLen) {
        [[TgPulseOverlay shared] whisperLine:kTgSignOtpBad];
        return;
    }
    if (!self.tg_pactEngaged) {
        [[TgPulseOverlay shared] whisperLine:kTgSignPactBad];
        return;
    }

    [TgTraceRelay emitSignal:TgTraceSignalLoginTap];
    self.tg_commitRelayBusy = YES;
    self.tg_commitLatch.enabled = NO;
    [[TgPulseOverlay shared] veilSpin];

    NSDictionary *sign = @{
        @"mobile": mobile,
        @"verifyCode": otp,
        @"longitude": @"-360",
        @"latitude": @"-360",
        @"imei": @"null",
        @"serialNo": [TgPersonaVault shared].holderSerial ?: @""
    };
    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneAuthRegister
                             signData:sign
                           nonSignData:nil
                              success:^(id _Nullable data) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.tg_commitRelayBusy = NO;
        self.tg_commitLatch.enabled = YES;
        [[TgPulseOverlay shared] veilDismiss];
        [self tg_handleAuthPayload:data];
    } failure:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.tg_commitRelayBusy = NO;
        self.tg_commitLatch.enabled = YES;
        [[TgPulseOverlay shared] veilDismiss];
    }];
}

#pragma mark - Auth / device

- (void)tg_handleAuthPayload:(id)data {
    TgLoginData *login = [TgLoginData yy_modelWithJSON:data];
    if (!login.face.length || !login.rank.length) {
        [[TgPulseOverlay shared] whisperLine:kTgSignOtpBad];
        return;
    }
    NSString *mobile = [self tg_resolveWireMobileShowingToast:NO] ?: @"";
    [[TgPersonaVault shared] imprintUserId:login.face token:login.rank mobile:mobile];
    [self tg_uploadDeviceOnce];
    [self tg_enterMainShell];
}

- (void)tg_uploadDeviceOnce {
    NSDictionary *payload = [TgSensorLattice harvestPayload];
    [[TgWireConduit shared] relayPOST:TgLaneRegisterDevice
                             signData:nil
                           nonSignData:payload
                              success:^(id _Nullable d) { (void)d; }
                              failure:^{}];
}

- (void)tg_enterMainShell {
    UIWindowScene *scene = self.view.window.windowScene;
    if (!scene) {
        for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
            if (s.activationState == UISceneActivationStateForegroundActive && [s isKindOfClass:[UIWindowScene class]]) {
                scene = (UIWindowScene *)s;
                break;
            }
        }
    }
    id delegate = scene.delegate;
    if ([delegate respondsToSelector:@selector(tg_switchToMainAnimated:)]) {
        [(SceneDelegate *)delegate tg_switchToMainAnimated:YES];
    }
}

#pragma mark - Validation

- (nullable NSString *)tg_resolveWireMobileShowingToast:(BOOL)toast {
    NSString *local = self.tg_dialField.text ?: @"";
    NSString *digits = [NSString tg_digitsOnlyFromMixed:local];
    if (digits.length == 0) {
        if (toast) [[TgPulseOverlay shared] whisperLine:kTgSignPhoneEmpty];
        return nil;
    }
    NSString *wire = [NSString tg_wireReadyMobileFromLocalDigits:local];
    if (!wire) {
        if (toast) [[TgPulseOverlay shared] whisperLine:kTgSignPhoneBad];
        return nil;
    }
    return wire;
}

#pragma mark - Countdown

- (void)tg_beginCountdown {
    [self.tg_countdownClock invalidate];
    self.tg_countdownLeft = kTgSignCountdownSec;
    self.tg_otpLatch.enabled = NO;
    [self tg_applyOtpLatchTitle:[NSString stringWithFormat:@"%lds", (long)self.tg_countdownLeft] underlined:NO];
    self.tg_countdownClock = [NSTimer timerWithTimeInterval:1
                                                     target:self
                                                   selector:@selector(tg_tickCountdown)
                                                   userInfo:nil
                                                    repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.tg_countdownClock forMode:NSRunLoopCommonModes];
}

- (void)tg_tickCountdown {
    self.tg_countdownLeft -= 1;
    if (self.tg_countdownLeft > 0) {
        [self tg_applyOtpLatchTitle:[NSString stringWithFormat:@"%lds", (long)self.tg_countdownLeft] underlined:NO];
        return;
    }
    [self.tg_countdownClock invalidate];
    self.tg_countdownClock = nil;
    [self tg_applyOtpLatchTitle:@"Reacquire" underlined:YES];
    self.tg_otpLatch.enabled = !self.tg_otpRelayBusy;
}

- (void)tg_applyOtpLatchTitle:(NSString *)title underlined:(BOOL)underlined {
    NSMutableDictionary *attrs = [@{
        NSFontAttributeName: [UIFont tg_meshGlyphWithSize:15 weight:UIFontWeightBold],
        NSForegroundColorAttributeName: [self tg_signLinkTone]
    } mutableCopy];
    if (underlined) {
        attrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
    }
    NSAttributedString *attr = [[NSAttributedString alloc] initWithString:title attributes:attrs];

    NSMutableDictionary *disabledAttrs = [attrs mutableCopy];
    disabledAttrs[NSForegroundColorAttributeName] = [[self tg_signLinkTone] colorWithAlphaComponent:0.45];
    NSAttributedString *disabledAttr = [[NSAttributedString alloc] initWithString:title attributes:disabledAttrs];

    [self.tg_otpLatch setAttributedTitle:attr forState:UIControlStateNormal];
    [self.tg_otpLatch setAttributedTitle:disabledAttr forState:UIControlStateDisabled];
    [self.tg_otpLatch setTitle:nil forState:UIControlStateNormal];
    [self.tg_otpLatch setTitle:nil forState:UIControlStateDisabled];
    [self tg_relayoutOtpLatch];
}

- (void)tg_relayoutOtpLatch {
    UIButton *latch = self.tg_otpLatch;
    latch.titleLabel.lineBreakMode = NSLineBreakByClipping;

    CGFloat fieldH = 50;
    CGSize fit = [latch sizeThatFits:CGSizeMake(CGFLOAT_MAX, fieldH)];
    latch.frame = CGRectMake(0, 0, ceil(fit.width), fieldH);

    self.tg_otpField.rightView = latch;
    [self.tg_otpField setNeedsLayout];
    [self.tg_otpField layoutIfNeeded];
}

#pragma mark - Agreement Web

- (void)tg_openPactPanePrivacy {
    [self tg_openPactPaneWithTitle:@"Privacy policy"
                              href:[TgPureLinks privacyPolicy]
                            signal:TgTraceSignalPrivacyOpen];
}

- (void)tg_openPactPaneService {
    [self tg_openPactPaneWithTitle:@"Service agreement"
                              href:[TgPureLinks serviceAgreement]
                            signal:TgTraceSignalTermsOpen];
}

- (void)tg_openPactPaneWithTitle:(NSString *)title
                            href:(NSString *)href
                          signal:(TgTraceSignal)signal {
    if (self.tg_pactNavBusy) return;
    self.tg_pactNavBusy = YES;
    [TgTraceRelay emitSignal:signal];

    NSURL *url = [TgPaneWebController tg_normalizedURLFromString:href];
    if (href.length == 0 || !url) {
        self.tg_pactNavBusy = NO;
        [[TgPulseOverlay shared] whisperLine:kTgSignNotAvailable];
        return;
    }
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    TgPaneWebController *pane = [[TgPaneWebController alloc] initWithPageURL:url navTitle:title];
    pane.tg_showsBackButton = YES;
    pane.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:pane animated:YES];
    self.tg_pactNavBusy = NO;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *filtered = [NSString tg_digitsOnlyFromMixed:string];
    NSString *current = textField.text ?: @"";
    NSString *merged = [current stringByReplacingCharactersInRange:range withString:filtered];
    NSString *digits = [NSString tg_digitsOnlyFromMixed:merged];

    if (textField == self.tg_dialField) {
        NSInteger cap = 11;
        if (digits.length > 0) {
            unichar lead = [digits characterAtIndex:0];
            cap = (lead == '0') ? 11 : 10;
        }
        if (digits.length > cap) {
            digits = [digits substringToIndex:cap];
        }
        textField.text = digits;
        return NO;
    }

    if (textField == self.tg_otpField) {
        if (digits.length > kTgSignOtpMaxLen) {
            digits = [digits substringToIndex:kTgSignOtpMaxLen];
        }
        textField.text = digits;
        return NO;
    }
    return YES;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChangeSelection:(UITextView *)textView {
    if (textView.selectedTextRange) {
        textView.selectedTextRange = nil;
    }
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    (void)textView; (void)characterRange; (void)interaction;
    NSString *host = URL.host ?: @"";
    if ([host isEqualToString:@"privacy"]) {
        [self tg_openPactPanePrivacy];
    } else if ([host isEqualToString:@"service"]) {
        [self tg_openPactPaneService];
    }
    return NO;
}

@end
