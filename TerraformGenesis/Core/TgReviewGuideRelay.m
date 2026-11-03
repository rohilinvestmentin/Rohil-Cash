//

//

#import "TgReviewGuideRelay.h"
#import "TgParcelRegistry.h"
#import "TgPolicyVault.h"
#import "TgPulseOverlay.h"
#import "TgShardFacade.h"
#import "TgStarGauge.h"
#import "TgPayloadModels.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>
#import <StoreKit/StoreKit.h>

static NSString * const kTgReviewWaveAsset = @"use_Subtract1";
static NSString * const kTgReviewStarHeaderHex = @"#B7BFEE";

static CGFloat const kTgReviewStarSize = 36.0;
static CGFloat const kTgReviewStarSpacing = 12.0;
static CGFloat const kTgReviewStarSectionVerticalPad = 26.0;
static CGFloat const kTgReviewWaveOverlap = 10.0;
static CGFloat const kTgReviewContentPad = 20.0;

static NSString * const kTgReviewMainMessage =
    @"If you enjoy our app, please consider leaving a five-star rating - it would mean a lot to us!";
static NSString * const kTgReviewToastNoScore =
    @"Kindly rate our app first; we will keep improving based on your feedback!";
static NSString * const kTgReviewThankMessage =
    @"Thanks! We have received your comment and look forward to staying in touch.";

static TgStarGauge *_tgActiveGauge = nil;
static TgReviewSubmitBlock _tgSubmitHandler = nil;
static TgReviewDismissBlock _tgDismissHandler = nil;

#pragma mark - Full-bleed custom body host

@interface TgReviewGuidePanelBody : UIView
@end

@implementation TgReviewGuidePanelBody

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    UIView *host = self.superview;
    UIView *card = host.superview;
    if (!host || !card) return;
    [self mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(card);
        make.bottom.equalTo(host);
    }];
}

@end

#pragma mark - Relay

@implementation TgReviewGuideRelay

+ (instancetype)shared {
    static TgReviewGuideRelay *relay = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ relay = [[TgReviewGuideRelay alloc] init]; });
    return relay;
}

+ (void)tg_storeAppUserType:(NSInteger)userType {
    if (userType <= 0) return;
    [[NSUserDefaults standardUserDefaults] setInteger:userType forKey:TgCacheAppUserType];
}

+ (NSInteger)tg_cachedAppUserType {
    NSInteger stored = [[NSUserDefaults standardUserDefaults] integerForKey:TgCacheAppUserType];
    return stored > 0 ? stored : 1;
}

#pragma mark - Public

+ (void)tg_tryShowReviewGuideOnSubmit:(TgReviewSubmitBlock)submit onDismiss:(TgReviewDismissBlock)dismiss {
    [self tg_tryShowReviewGuideForUserType:[self tg_cachedAppUserType] onSubmit:submit onDismiss:dismiss];
}

+ (void)tg_tryShowReviewGuideForUserType:(NSInteger)userType
                                onSubmit:(TgReviewSubmitBlock)submit
                               onDismiss:(TgReviewDismissBlock)dismiss {
    NSInteger category = userType > 0 ? userType : 1;

    if (![self tg_shouldShowForFeedbackGuidance:category]) {
        if (dismiss) dismiss();
        return;
    }
    if ([self tg_hasShownReviewGuideThisInstall]) {
        if (dismiss) dismiss();
        return;
    }

    [self tg_markReviewGuideShownThisInstall];
    [self tg_presentMainReviewGuidePanelOnSubmit:submit onDismiss:dismiss];
}

+ (void)tg_presentMainReviewGuidePanelOnSubmit:(TgReviewSubmitBlock)submit
                                     onDismiss:(TgReviewDismissBlock)dismiss {
    _tgSubmitHandler = [submit copy];
    _tgDismissHandler = [dismiss copy];
    _tgActiveGauge = nil;

    UIView *body = [self tg_buildMainPanelBodyWithGaugeOut:&_tgActiveGauge];
    CGFloat bodyHeight = [self tg_mainPanelBodyHeight];

    TgShardPanelConfig *cfg = [[TgShardPanelConfig alloc] init];
    cfg.panelStyle = TgShardPanelStyleCustomBody;
    cfg.customBodyView = body;
    cfg.customBodyHeight = bodyHeight;
    cfg.secondaryTitle = @"Cancel";
    cfg.primaryTitle = @"Submit";
    cfg.tier = TgShardTierHigh;
    cfg.mount = TgShardMountWindow;
    cfg.dismissOnPrimaryAction = NO;
    cfg.dismissOnSecondaryAction = YES;

    __weak typeof(self) weakSelf = self;
    cfg.secondaryAction = ^{
        [weakSelf tg_handleCancelTapped];
    };
    cfg.primaryAction = ^{
        [weakSelf tg_handleSubmitTapped];
    };

    [[TgShardFacade shared] showPanel:cfg];
}

+ (void)tg_showThankYouPanelWithConfirm:(void (^)(void))confirmAction {
    [[TgShardFacade shared] showTextPanelWithContent:kTgReviewThankMessage
                                        primaryTitle:@"Confirm"
                                      secondaryTitle:nil
                                        primaryAction:^{
        if (confirmAction) confirmAction();
    }
                                      secondaryAction:nil];
}

#pragma mark - Config / marks

+ (BOOL)tg_shouldShowForFeedbackGuidance:(NSInteger)userType {
    TgSystemConfigModel *cfg = [[TgPolicyVault shared] currentManifest];
    NSString *raw = [cfg.vanish stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    NSInteger guidance = raw.length > 0 ? raw.integerValue : 1;
    if (guidance == 0) return NO;
    if (guidance == 2 && userType != 2) return NO;
    return YES;
}

+ (BOOL)tg_hasShownReviewGuideThisInstall {
    return [[NSUserDefaults standardUserDefaults] boolForKey:TgMarkReviewGuideDisplayed];
}

+ (void)tg_markReviewGuideShownThisInstall {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:TgMarkReviewGuideDisplayed];
}

#pragma mark - Actions

+ (void)tg_handleSubmitTapped {
    NSInteger score = _tgActiveGauge.tg_currentScore;
    if (score <= 0) {
        [[TgPulseOverlay shared] whisperLine:kTgReviewToastNoScore duration:2.0];
        return;
    }

    [[TgShardFacade shared] dismissTopPanel];
    _tgActiveGauge = nil;

    TgReviewSubmitBlock submit = _tgSubmitHandler;
    _tgSubmitHandler = nil;
    _tgDismissHandler = nil;

    if (score >= 4) {
        [self tg_requestAppStoreReview];
        if (submit) submit(score);
        return;
    }

    [self tg_showThankYouPanelWithConfirm:^{
        if (submit) submit(score);
    }];
}

+ (void)tg_handleCancelTapped {
    TgReviewDismissBlock dismiss = _tgDismissHandler;
    _tgSubmitHandler = nil;
    _tgDismissHandler = nil;
    _tgActiveGauge = nil;
    if (dismiss) dismiss();
}

+ (void)tg_requestAppStoreReview {
    UIWindowScene *scene = nil;
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if (s.activationState != UISceneActivationStateForegroundActive) continue;
        if ([s isKindOfClass:[UIWindowScene class]]) {
            scene = (UIWindowScene *)s;
            break;
        }
    }
    if (scene) {
        [SKStoreReviewController requestReviewInScene:scene];
    }
}

#pragma mark - Main panel UI

+ (UIView *)tg_buildMainPanelBodyWithGaugeOut:(TgStarGauge * __strong *)gaugeOut {
    TgReviewGuidePanelBody *root = [[TgReviewGuidePanelBody alloc] init];
    root.backgroundColor = UIColor.whiteColor;
    root.clipsToBounds = YES;

    UIView *starVeil = [[UIView alloc] init];
    starVeil.backgroundColor = [UIColor tg_toneFromHex:kTgReviewStarHeaderHex];
    starVeil.clipsToBounds = YES;
    [root addSubview:starVeil];

    TgStarGauge *gauge = [[TgStarGauge alloc] init];
    gauge.tg_starSize = kTgReviewStarSize;
    gauge.tg_starSpacing = kTgReviewStarSpacing;
    [starVeil addSubview:gauge];
    if (gaugeOut) *gaugeOut = gauge;

    UIImageView *waveCap = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgReviewWaveAsset]];
    waveCap.contentMode = UIViewContentModeScaleToFill;
    [root addSubview:waveCap];

    UIView *contentVeil = [[UIView alloc] init];
    contentVeil.backgroundColor = UIColor.whiteColor;
    [root addSubview:contentVeil];

    UILabel *messageLab = [[UILabel alloc] init];
    messageLab.text = kTgReviewMainMessage;
    messageLab.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightRegular];
    messageLab.textColor = UIColor.blackColor;
    messageLab.numberOfLines = 0;
    messageLab.textAlignment = NSTextAlignmentCenter;
    [contentVeil addSubview:messageLab];

    UIImage *waveImg = [UIImage imageNamed:kTgReviewWaveAsset];
    CGFloat waveRatio = (waveImg.size.width > 0) ? (waveImg.size.height / waveImg.size.width) : 0.18;
    CGFloat starSectionH = kTgReviewStarSize + kTgReviewStarSectionVerticalPad * 2.0;

    [starVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(root);
        make.height.mas_equalTo(starSectionH);
    }];
    [gauge mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(starVeil);
    }];
    [waveCap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(root);
        make.top.equalTo(starVeil.mas_bottom).offset(-kTgReviewWaveOverlap);
        make.height.equalTo(waveCap.mas_width).multipliedBy(waveRatio);
    }];
    [contentVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(root);
        make.top.equalTo(waveCap.mas_bottom);
    }];
    [messageLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(contentVeil).offset(kTgReviewContentPad);
        make.left.equalTo(contentVeil).offset(kTgReviewContentPad);
        make.right.equalTo(contentVeil).offset(-kTgReviewContentPad);
        make.bottom.equalTo(contentVeil).offset(-kTgReviewContentPad);
    }];

    return root;
}

+ (CGFloat)tg_mainPanelBodyHeight {
    UIImage *waveImg = [UIImage imageNamed:kTgReviewWaveAsset];
    CGFloat waveRatio = (waveImg.size.width > 0) ? (waveImg.size.height / waveImg.size.width) : 0.18;
    CGFloat panelW = CGRectGetWidth(UIScreen.mainScreen.bounds) * 0.85;
    CGFloat starSectionH = kTgReviewStarSize + kTgReviewStarSectionVerticalPad * 2.0;
    CGFloat waveH = panelW * waveRatio - kTgReviewWaveOverlap;
    CGFloat textH = [kTgReviewMainMessage boundingRectWithSize:CGSizeMake(panelW - kTgReviewContentPad * 2.0 - 40.0, CGFLOAT_MAX)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:@{NSFontAttributeName: [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightRegular]}
                                                       context:nil].size.height;
    return starSectionH + waveH + textH + kTgReviewContentPad * 2.0 + 8.0;
}

@end
