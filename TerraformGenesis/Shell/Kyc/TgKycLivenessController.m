//

//

#import "TgKycLivenessController.h"
#import "TgKycFaceCaptureRelay.h"
#import "TgKycPathRelay.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"
#import "TgPulseOverlay.h"
#import "TgShardFacade.h"
#import "TgTraceRelay.h"
#import "TgWireConduit.h"
#import "TgPackEnvelope.h"
#import "UIImage+TgGlyph.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <AVFoundation/AVFoundation.h>
#import <Masonry/Masonry.h>

static NSString * const kTgKycIdLiveness = @"liveness";
static CGFloat const kTgLivenessHorzInset = 16.0;
static CGFloat const kTgLivenessButtonHeight = 50.0;
static CGFloat const kTgLivenessButtonWidthRatio = 0.85;
static CGFloat const kTgLivenessPreviewCorner = 20.0;
static CGFloat const kTgLivenessHintCorner = 12.0;
static NSString * const kTgLivenessHintBgHex = @"#FFF0E8";
static NSString * const kTgLivenessHintTextHex = @"#E67A2E";
static NSString * const kTgLivenessButtonHex = @"#182040";
static NSString * const kTgLivenessBusyHint = @"The system is occupied. Please retry after 2 minutes.";
static NSString * const kTgLivenessFaceAsset = @"use_face";
static NSString * const kTgLivenessRestartIconAsset = @"refresh";
static CGFloat const kTgLivenessRestartBarHeight = 56.0;

static NSString * const kTgLivenessHintEN =
    @"Keep your face inside the frame, then take a photo.";
static NSString * const kTgLivenessHintHI =
    @"\u0915\u0943\u092a\u092f\u093e \u0905\u092a\u0928\u093e \u091a\u0947\u0939\u0930\u093e \u092b\u094d\u0930\u0947\u092e \u092e\u0947\u0902 \u0930\u0916\u0947\u0902 \u0914\u0930 \u090f\u0915 \u0938\u094d\u092a\u0937\u094d\u091f \u0938\u0947\u0932\u094d\u092b\u0940 \u0932\u0947\u0902";

typedef NS_ENUM(NSInteger, TgKycLivenessPhase) {
    TgKycLivenessPhaseIntro = 0,
    TgKycLivenessPhasePreview,
    TgKycLivenessPhaseCaptured,
};

@interface TgKycLivenessController ()

@property (nonatomic, assign) TgKycLivenessPhase tg_phase;
@property (nonatomic, strong) TgKycFaceCaptureRelay *tg_captureRelay;
@property (nonatomic, strong, nullable) UIImage *tg_capturedImage;

@property (nonatomic, strong) UIView *tg_contentVeil;
@property (nonatomic, strong) UIView *tg_previewFrame;
@property (nonatomic, strong) UIImageView *tg_facePlaceholder;
@property (nonatomic, strong) UIImageView *tg_capturedPreview;
@property (nonatomic, strong) UIView *tg_hintVeil;
@property (nonatomic, strong) UILabel *tg_hintEN;
@property (nonatomic, strong) UILabel *tg_hintHI;
@property (nonatomic, strong) UIView *tg_restartOverlay;
@property (nonatomic, strong) UIButton *tg_restartLatch;
@property (nonatomic, strong) UIButton *tg_actionLatch;

@end

@implementation TgKycLivenessController

- (instancetype)init {
    self = [super init];
    if (self) {
        _tg_captureRelay = [[TgKycFaceCaptureRelay alloc] init];
        self.tg_backdropStyle = TgHullBackdropStyleUseBg0;
        self.tg_showsBackButton = YES;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self tg_setNavTitleMedium18:@"Face identification"];
    __weak typeof(self) weakSelf = self;
    self.tg_backInterceptBlock = ^BOOL {
        [weakSelf tg_showReturnConfirmDialog];
        return NO;
    };
    [self tg_buildLayout];
    [self tg_applyPhase:TgKycLivenessPhaseIntro animated:NO];
    [self tg_requestKycInit];
    if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusAuthorized) {
        [self.tg_captureRelay tg_prepareSessionWithCompletion:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [TgTraceRelay emitSignal:TgTraceSignalLivenessFace];
    if (self.tg_phase == TgKycLivenessPhasePreview) {
        [self tg_warmPreviewCamera];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.tg_captureRelay tg_stopRunning];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.tg_captureRelay tg_updatePreviewLayout];
}

#pragma mark - Layout

- (void)tg_buildLayout {
    self.tg_contentVeil = [[UIView alloc] init];
    self.tg_contentVeil.backgroundColor = UIColor.clearColor;
    [self.view insertSubview:self.tg_contentVeil atIndex:1];

    self.tg_previewFrame = [[UIView alloc] init];
    self.tg_previewFrame.backgroundColor = UIColor.blackColor;
    self.tg_previewFrame.layer.cornerRadius = kTgLivenessPreviewCorner;
    self.tg_previewFrame.clipsToBounds = YES;
    [self.tg_contentVeil addSubview:self.tg_previewFrame];

    self.tg_facePlaceholder = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgLivenessFaceAsset]];
    self.tg_facePlaceholder.contentMode = UIViewContentModeScaleAspectFit;
    [self.tg_previewFrame addSubview:self.tg_facePlaceholder];

    self.tg_capturedPreview = [[UIImageView alloc] init];
    self.tg_capturedPreview.contentMode = UIViewContentModeScaleAspectFill;
    self.tg_capturedPreview.clipsToBounds = YES;
    self.tg_capturedPreview.hidden = YES;
    [self.tg_previewFrame addSubview:self.tg_capturedPreview];

    self.tg_captureRelay.tg_previewHost = self.tg_previewFrame;

    self.tg_hintVeil = [[UIView alloc] init];
    self.tg_hintVeil.backgroundColor = [UIColor tg_toneFromHex:kTgLivenessHintBgHex];
    self.tg_hintVeil.layer.cornerRadius = kTgLivenessHintCorner;
    self.tg_hintVeil.clipsToBounds = YES;
    [self.tg_contentVeil addSubview:self.tg_hintVeil];

    UIColor *hintColor = [UIColor tg_toneFromHex:kTgLivenessHintTextHex];
    self.tg_hintEN = [[UILabel alloc] init];
    self.tg_hintEN.text = kTgLivenessHintEN;
    self.tg_hintEN.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    self.tg_hintEN.textColor = hintColor;
    self.tg_hintEN.numberOfLines = 0;
    self.tg_hintEN.textAlignment = NSTextAlignmentLeft;
    [self.tg_hintVeil addSubview:self.tg_hintEN];

    self.tg_hintHI = [[UILabel alloc] init];
    self.tg_hintHI.text = kTgLivenessHintHI;
    self.tg_hintHI.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    self.tg_hintHI.textColor = hintColor;
    self.tg_hintHI.numberOfLines = 0;
    self.tg_hintHI.textAlignment = NSTextAlignmentLeft;
    [self.tg_hintVeil addSubview:self.tg_hintHI];

    self.tg_restartOverlay = [[UIView alloc] init];
    self.tg_restartOverlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
    self.tg_restartOverlay.hidden = YES;
    [self.tg_previewFrame addSubview:self.tg_restartOverlay];

    self.tg_restartLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    UIButtonConfiguration *restartCfg = [UIButtonConfiguration plainButtonConfiguration];
    restartCfg.title = @"Restart";
    restartCfg.baseForegroundColor = UIColor.whiteColor;
    restartCfg.titleTextAttributesTransformer = ^NSDictionary<NSAttributedStringKey, id> *(NSDictionary<NSAttributedStringKey, id> *attrs) {
        NSMutableDictionary *m = [attrs mutableCopy];
        m[NSFontAttributeName] = [UIFont tg_meshGlyphWithSize:15 weight:UIFontWeightMedium];
        return m;
    };
    UIImage *restartIcon = [UIImage imageNamed:kTgLivenessRestartIconAsset];
    if (restartIcon) {
        restartCfg.image = [restartIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        restartCfg.imagePadding = 6;
        restartCfg.imagePlacement = NSDirectionalRectEdgeLeading;
    }
    self.tg_restartLatch.configuration = restartCfg;
    [self.tg_restartLatch addTarget:self action:@selector(tg_onRestartTap) forControlEvents:UIControlEventTouchUpInside];
    [self.tg_restartOverlay addSubview:self.tg_restartLatch];

    self.tg_actionLatch = [self tg_makePrimaryButton];
    [self.tg_actionLatch addTarget:self action:@selector(tg_onActionTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.tg_actionLatch];

    [self.tg_contentVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset([self tg_contentTopBelowNavigation]);
        make.bottom.equalTo(self.tg_actionLatch.mas_top).offset(-16);
    }];
    [self.tg_previewFrame mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_contentVeil).offset(24);
        make.left.equalTo(self.tg_contentVeil).offset(kTgLivenessHorzInset);
        make.right.equalTo(self.tg_contentVeil).offset(-kTgLivenessHorzInset);
        make.height.equalTo(self.tg_previewFrame.mas_width).multipliedBy(1.15);
    }];
    [self.tg_facePlaceholder mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_previewFrame).insets(UIEdgeInsetsMake(12, 12, 12, 12));
    }];
    [self.tg_capturedPreview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_previewFrame);
    }];
    [self.tg_restartOverlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.tg_previewFrame);
        make.height.mas_equalTo(kTgLivenessRestartBarHeight);
    }];
    [self.tg_restartLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.tg_restartOverlay);
    }];
    [self.tg_hintVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_previewFrame.mas_bottom).offset(20);
        make.left.right.equalTo(self.tg_previewFrame);
    }];
    [self.tg_hintEN mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.tg_hintVeil).insets(UIEdgeInsetsMake(14, 14, 0, 14));
    }];
    [self.tg_hintHI mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_hintEN.mas_bottom).offset(8);
        make.left.right.bottom.equalTo(self.tg_hintVeil).insets(UIEdgeInsetsMake(0, 14, 14, 14));
    }];
    [self.tg_actionLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(kTgLivenessButtonWidthRatio);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-16);
        make.height.mas_equalTo(kTgLivenessButtonHeight);
    }];
}

- (UIButton *)tg_makePrimaryButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    btn.backgroundColor = [UIColor tg_toneFromHex:kTgLivenessButtonHex];
    btn.layer.cornerRadius = kTgLivenessButtonHeight / 2.0;
    btn.clipsToBounds = YES;
    return btn;
}

#pragma mark - Phase

- (void)tg_applyPhase:(TgKycLivenessPhase)phase animated:(BOOL)animated {
    self.tg_phase = phase;
    switch (phase) {
        case TgKycLivenessPhaseIntro:
            self.tg_previewFrame.backgroundColor = UIColor.clearColor;
            self.tg_facePlaceholder.hidden = NO;
            self.tg_capturedPreview.hidden = YES;
            [self.tg_captureRelay tg_setPreviewHidden:YES];
            [self.tg_captureRelay tg_stopRunning];
            [self.tg_actionLatch setTitle:@"Start" forState:UIControlStateNormal];
            self.tg_actionLatch.hidden = NO;
            self.tg_restartOverlay.hidden = YES;
            [self tg_setCaptureActionEnabled:YES];
            break;
        case TgKycLivenessPhasePreview:
            self.tg_previewFrame.backgroundColor = UIColor.blackColor;
            self.tg_facePlaceholder.hidden = YES;
            self.tg_capturedPreview.hidden = YES;
            [self.tg_captureRelay tg_setPreviewHidden:NO];
            [self.tg_actionLatch setTitle:@"Take a photo" forState:UIControlStateNormal];
            self.tg_actionLatch.hidden = NO;
            self.tg_restartOverlay.hidden = YES;
            [self tg_warmPreviewCamera];
            break;
        case TgKycLivenessPhaseCaptured:
            self.tg_previewFrame.backgroundColor = UIColor.blackColor;
            self.tg_facePlaceholder.hidden = YES;
            self.tg_capturedPreview.hidden = NO;
            self.tg_capturedPreview.image = self.tg_capturedImage;
            [self.tg_captureRelay tg_setPreviewHidden:YES];
            [self.tg_captureRelay tg_stopRunning];
            [self.tg_actionLatch setTitle:@"Continue" forState:UIControlStateNormal];
            self.tg_actionLatch.hidden = NO;
            self.tg_restartOverlay.hidden = NO;
            [self tg_setCaptureActionEnabled:YES];
            [self.tg_previewFrame bringSubviewToFront:self.tg_restartOverlay];
            break;
    }
    (void)animated;
}

#pragma mark - Init API

- (void)tg_requestKycInit {
    [[TgWireConduit shared] relayPOST:TgLaneKycInit
                             signData:@{ @"kycId": kTgKycIdLiveness }
                           nonSignData:@{}
                              success:nil
                              failure:nil];
}

#pragma mark - Actions

- (void)tg_onActionTap {
    if (self.tg_phase == TgKycLivenessPhaseIntro) {
        [self tg_beginCameraFlow];
        return;
    }
    if (self.tg_phase == TgKycLivenessPhasePreview) {
        [self tg_takePhoto];
        return;
    }
    if (self.tg_phase == TgKycLivenessPhaseCaptured) {
        [self tg_submitLiveness];
    }
}

- (void)tg_onRestartTap {
    self.tg_capturedImage = nil;
    [self tg_applyPhase:TgKycLivenessPhasePreview animated:YES];
}

- (void)tg_submitLiveness {
    if (!self.tg_capturedImage) return;
    TgPackEnvelope *pack = [self.tg_capturedImage tg_foldPayloadMinKB:200 maxKB:800];
    NSString *base64 = pack.base64Payload;
    if (base64.length == 0) {
        [[TgPulseOverlay shared] whisperLine:kTgLivenessBusyHint];
        return;
    }
    [[TgPulseOverlay shared] veilSpin:nil];
    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneKycLiveness
                             signData:@{ @"liveness": base64 }
                           nonSignData:@{}
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        [[TgPulseOverlay shared] veilDismiss];
        if (!envelope.isSuccess) {
            if (envelope.power.length > 0) {
                [[TgPulseOverlay shared] whisperLine:envelope.power];
            }
            return;
        }
        [TgKycPathRelay continueAfterCommitFromNav:weakSelf.navigationController];
    } failure:^{
        [[TgPulseOverlay shared] veilDismiss];
        [[TgPulseOverlay shared] whisperLine:kTgLivenessBusyHint];
    }];
}

- (void)tg_beginCameraFlow {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized) {
        [TgTraceRelay emitPermissionGrant:TgTraceSignalCameraGrant deny:TgTraceSignalCameraDeny granted:YES];
        [self tg_applyPhase:TgKycLivenessPhasePreview animated:YES];
        return;
    }
    if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
        [TgTraceRelay emitPermissionGrant:TgTraceSignalCameraGrant deny:TgTraceSignalCameraDeny granted:NO];
        [self tg_showCameraSettingsDialog];
        return;
    }
    __weak typeof(self) weakSelf = self;
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [TgTraceRelay emitPermissionGrant:TgTraceSignalCameraGrant deny:TgTraceSignalCameraDeny granted:granted];
            if (granted) {
                [weakSelf tg_applyPhase:TgKycLivenessPhasePreview animated:YES];
            } else {
                [weakSelf tg_showCameraSettingsDialog];
            }
        });
    }];
}

- (void)tg_setCaptureActionEnabled:(BOOL)enabled {
    self.tg_actionLatch.enabled = enabled;
    self.tg_actionLatch.alpha = enabled ? 1.0 : 0.45;
}

- (void)tg_warmPreviewCamera {
    [self tg_setCaptureActionEnabled:NO];
    __weak typeof(self) weakSelf = self;
    [self.tg_captureRelay tg_startRunningWithCompletion:^(BOOL success) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.tg_phase != TgKycLivenessPhasePreview) return;
        [self tg_setCaptureActionEnabled:success];
        if (!success) {
            [[TgPulseOverlay shared] whisperLine:kTgLivenessBusyHint];
        }
    }];
}

- (void)tg_takePhoto {
    if (!self.tg_actionLatch.enabled) return;
    [self tg_setCaptureActionEnabled:NO];
    __weak typeof(self) weakSelf = self;
    [self.tg_captureRelay tg_capturePhoto:^(UIImage *image) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (!image) {
            [[TgPulseOverlay shared] whisperLine:kTgLivenessBusyHint];
            if (self.tg_phase == TgKycLivenessPhasePreview) {
                [self tg_setCaptureActionEnabled:YES];
            }
            return;
        }
        self.tg_capturedImage = image;
        [self tg_applyPhase:TgKycLivenessPhaseCaptured animated:YES];
    }];
}

#pragma mark - Dialogs

- (NSString *)tg_appDisplayName {
    NSString *name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (name.length == 0) {
        name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    }
    return name.length > 0 ? name : @"App";
}

- (void)tg_showCameraSettingsDialog {
    NSString *appName = [self tg_appDisplayName];
    TgShardPanelConfig *cfg = [[TgShardPanelConfig alloc] init];
    cfg.title = nil;
    cfg.content = [NSString stringWithFormat:
                     @"Please enable camera access for %@ in Settings so you can take photos", appName];
    cfg.secondaryTitle = @"Cancel";
    cfg.primaryTitle = @"Confirm";
    cfg.secondaryAction = ^{
        [[TgShardFacade shared] dismissTopPanel];
    };
    cfg.primaryAction = ^{
        [[TgShardFacade shared] dismissTopPanel];
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if (url) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }
    };
    [[TgShardFacade shared] showPanel:cfg];
}

- (void)tg_showReturnConfirmDialog {
    TgShardPanelConfig *cfg = [[TgShardPanelConfig alloc] init];
    cfg.title = @"Confirm to return?";
    cfg.content = @"Do you want to pause authentication and go back";
    cfg.secondaryTitle = @"Cancel";
    cfg.primaryTitle = @"Confirm";
    cfg.secondaryAction = ^{
        [[TgShardFacade shared] dismissTopPanel];
    };
    __weak typeof(self) weakSelf = self;
    cfg.primaryAction = ^{
        [[TgShardFacade shared] dismissTopPanel];
        [weakSelf.navigationController popViewControllerAnimated:YES];
    };
    [[TgShardFacade shared] showPanel:cfg];
}

@end
