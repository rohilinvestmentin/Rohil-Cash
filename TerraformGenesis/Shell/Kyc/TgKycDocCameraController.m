//

//

#import "TgKycDocCameraController.h"
#import "TgKycDocCameraRelay.h"
#import "TgPulseOverlay.h"
#import "TgShardFacade.h"
#import "TgTraceRelay.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <AVFoundation/AVFoundation.h>
#import <Masonry/Masonry.h>

static NSString * const kTgDocCameraBackAsset = @"Group643";
static NSString * const kTgDocCameraCaptureAsset = @"use_an";
static NSString * const kTgDocCameraConfirmAsset = @"sue_02";
static NSString * const kTgDocCameraRetakeAsset = @"use_cp";
static NSString * const kTgDocCameraHintText =
    @"When capturing the photo, align the dotted frame with the edges of your ID.";
static NSString * const kTgDocCameraBgHex = @"#0A0B17";
static NSString * const kTgDocCameraDashHex = @"#FFFFFF";
static CGFloat const kTgDocCameraHorzInset = 15.0;
static CGFloat const kTgDocCameraPreviewCorner = 16.0;
static CGFloat const kTgDocCameraShutterSize = 70.0;
static CGFloat const kTgDocCameraSideBtnSize = 60.0;

typedef NS_ENUM(NSInteger, TgKycDocCameraPhase) {
    TgKycDocCameraPhaseLive = 0,
    TgKycDocCameraPhasePreview,
};

@interface TgKycDocCameraController ()

@property (nonatomic, assign) TgKycDocCameraPhase tg_phase;
@property (nonatomic, assign) BOOL tg_confirmLocked;
@property (nonatomic, assign) BOOL tg_captureInFlight;
@property (nonatomic, assign) BOOL tg_hasAppeared;
@property (nonatomic, assign) BOOL tg_cameraStartScheduled;
@property (nonatomic, strong) TgKycDocCameraRelay *tg_captureRelay;
@property (nonatomic, strong, nullable) UIImage *tg_capturedRawImage;

@property (nonatomic, strong) UIView *tg_headerBar;
@property (nonatomic, strong) UIView *tg_previewContainer;
@property (nonatomic, strong) UIView *tg_previewLayerHost;
@property (nonatomic, strong) UIView *tg_borderView;
@property (nonatomic, strong) CAShapeLayer *tg_dashLayer;
@property (nonatomic, strong) UIView *tg_hintContainer;
@property (nonatomic, strong) UILabel *tg_hintLabel;
@property (nonatomic, strong) UIImageView *tg_capturedPreview;
@property (nonatomic, strong) UIButton *tg_backLatch;
@property (nonatomic, strong) UIButton *tg_captureLatch;
@property (nonatomic, strong) UIButton *tg_confirmLatch;
@property (nonatomic, strong) UIButton *tg_retakeLatch;

@end

@implementation TgKycDocCameraController

+ (instancetype)controllerWithSceneToken:(NSString *)sceneToken {
    TgKycDocCameraController *vc = [[TgKycDocCameraController alloc] init];
    vc.tg_sceneToken = [sceneToken copy];
    return vc;
}

+ (void)presentFrom:(UIViewController *)host
        sceneToken:(NSString *)sceneToken
        completion:(TgKycDocCameraFinishBlock)completion {
    if (!host) return;

    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized) {
        [TgTraceRelay emitPermissionGrant:TgTraceSignalCameraGrant deny:TgTraceSignalCameraDeny granted:YES];
        [self tg_pushCameraFrom:host sceneToken:sceneToken completion:completion];
        return;
    }
    if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
        [TgTraceRelay emitPermissionGrant:TgTraceSignalCameraGrant deny:TgTraceSignalCameraDeny granted:NO];
        [self tg_showCameraSettingsDialogFrom:host];
        return;
    }

    __weak UIViewController *weakHost = host;
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [TgTraceRelay emitPermissionGrant:TgTraceSignalCameraGrant deny:TgTraceSignalCameraDeny granted:granted];
            UIViewController *strongHost = weakHost;
            if (!strongHost) return;
            if (granted) {
                [self tg_pushCameraFrom:strongHost sceneToken:sceneToken completion:completion];
            } else {
                [self tg_showCameraSettingsDialogFrom:strongHost];
            }
        });
    }];
}

+ (void)tg_pushCameraFrom:(UIViewController *)host
               sceneToken:(NSString *)sceneToken
               completion:(TgKycDocCameraFinishBlock)completion {
    TgKycDocCameraController *vc = [self controllerWithSceneToken:sceneToken];
    vc.tg_finishBlock = completion;
    vc.hidesBottomBarWhenPushed = YES;
    if (host.navigationController) {
        [host.navigationController pushViewController:vc animated:YES];
        return;
    }
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [host presentViewController:nav animated:YES completion:nil];
}

+ (NSString *)tg_appDisplayName {
    NSString *name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (name.length == 0) {
        name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    }
    return name.length > 0 ? name : @"App";
}

+ (void)tg_showCameraSettingsDialogFrom:(UIViewController *)host {
    (void)host;
    NSString *appName = [self tg_appDisplayName];
    TgShardPanelConfig *cfg = [[TgShardPanelConfig alloc] init];
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

- (instancetype)init {
    self = [super init];
    if (self) {
        _tg_captureRelay = [[TgKycDocCameraRelay alloc] init];
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor tg_toneFromHex:kTgDocCameraBgHex];
    [self tg_buildLayout];
    [self tg_applyPhase:TgKycDocCameraPhaseLive];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.tg_hasAppeared = YES;
    [self tg_emitOpenTrace];
    if (self.tg_phase == TgKycDocCameraPhaseLive) {
        [self tg_startLiveCamera];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.tg_hasAppeared = NO;
    self.tg_cameraStartScheduled = NO;
    [self.tg_captureRelay tg_stopRunning];
    if (self.isMovingFromParentViewController || self.isBeingDismissed) {
        [self.navigationController setNavigationBarHidden:NO animated:animated];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.tg_captureRelay tg_updatePreviewLayout];
    [self tg_layoutDashBorder];
    [self tg_layoutRotatedHint];
}

#pragma mark - Layout

- (void)tg_buildLayout {
    self.tg_headerBar = [[UIView alloc] init];
    self.tg_headerBar.backgroundColor = UIColor.clearColor;
    [self.view addSubview:self.tg_headerBar];

    self.tg_backLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_backLatch setImage:[UIImage imageNamed:kTgDocCameraBackAsset] forState:UIControlStateNormal];
    self.tg_backLatch.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.tg_backLatch addTarget:self action:@selector(tg_onBackTap) forControlEvents:UIControlEventTouchUpInside];
    [self.tg_headerBar addSubview:self.tg_backLatch];

    self.tg_previewContainer = [[UIView alloc] init];
    self.tg_previewContainer.backgroundColor = UIColor.blackColor;
    self.tg_previewContainer.layer.cornerRadius = kTgDocCameraPreviewCorner;
    self.tg_previewContainer.clipsToBounds = YES;
    [self.view addSubview:self.tg_previewContainer];

    self.tg_previewLayerHost = [[UIView alloc] init];
    self.tg_previewLayerHost.backgroundColor = UIColor.blackColor;
    [self.tg_previewContainer addSubview:self.tg_previewLayerHost];
    self.tg_captureRelay.tg_previewHost = self.tg_previewLayerHost;

    self.tg_hintContainer = [[UIView alloc] init];
    self.tg_hintContainer.backgroundColor = UIColor.clearColor;
    self.tg_hintContainer.clipsToBounds = YES;
    self.tg_hintContainer.userInteractionEnabled = NO;
    [self.tg_previewContainer addSubview:self.tg_hintContainer];

    self.tg_hintLabel = [[UILabel alloc] init];
    self.tg_hintLabel.text = kTgDocCameraHintText;
    self.tg_hintLabel.textColor = UIColor.whiteColor;
    self.tg_hintLabel.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightMedium];
    self.tg_hintLabel.numberOfLines = 1;
    self.tg_hintLabel.lineBreakMode = NSLineBreakByClipping;
    self.tg_hintLabel.adjustsFontSizeToFitWidth = YES;
    self.tg_hintLabel.minimumScaleFactor = 0.35f;
    self.tg_hintLabel.textAlignment = NSTextAlignmentCenter;
    [self.tg_hintContainer addSubview:self.tg_hintLabel];

    self.tg_capturedPreview = [[UIImageView alloc] init];
    self.tg_capturedPreview.contentMode = UIViewContentModeScaleAspectFill;
    self.tg_capturedPreview.clipsToBounds = YES;
    self.tg_capturedPreview.layer.cornerRadius = kTgDocCameraPreviewCorner;
    self.tg_capturedPreview.hidden = YES;
    [self.view addSubview:self.tg_capturedPreview];

    self.tg_borderView = [[UIView alloc] init];
    self.tg_borderView.userInteractionEnabled = NO;
    self.tg_borderView.backgroundColor = UIColor.clearColor;
    [self.view addSubview:self.tg_borderView];

    self.tg_dashLayer = [CAShapeLayer layer];
    self.tg_dashLayer.fillColor = nil;
    self.tg_dashLayer.strokeColor = [UIColor tg_toneFromHex:kTgDocCameraDashHex].CGColor;
    self.tg_dashLayer.lineWidth = 1.0;
    self.tg_dashLayer.lineDashPattern = @[@6, @4];
    [self.tg_borderView.layer addSublayer:self.tg_dashLayer];

    self.tg_captureLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_captureLatch setImage:[UIImage imageNamed:kTgDocCameraCaptureAsset] forState:UIControlStateNormal];
    self.tg_captureLatch.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.tg_captureLatch addTarget:self action:@selector(tg_onCaptureTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.tg_captureLatch];

    self.tg_confirmLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_confirmLatch setImage:[UIImage imageNamed:kTgDocCameraConfirmAsset] forState:UIControlStateNormal];
    self.tg_confirmLatch.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.tg_confirmLatch.hidden = YES;
    [self.tg_confirmLatch addTarget:self action:@selector(tg_onConfirmTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.tg_confirmLatch];

    self.tg_retakeLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_retakeLatch setImage:[UIImage imageNamed:kTgDocCameraRetakeAsset] forState:UIControlStateNormal];
    self.tg_retakeLatch.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.tg_retakeLatch.hidden = YES;
    [self.tg_retakeLatch addTarget:self action:@selector(tg_onRetakeTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.tg_retakeLatch];

    [self.tg_headerBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.equalTo(self.view);
    }];
    [self.tg_backLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_headerBar).offset(10);
        make.right.equalTo(self.tg_headerBar).offset(-10);
        make.width.height.mas_equalTo(40);
        make.bottom.equalTo(self.tg_headerBar).offset(-10);
    }];
    [self.tg_captureLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-30);
        make.width.height.mas_equalTo(kTgDocCameraShutterSize);
    }];
    [self.tg_confirmLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft).offset(50);
        make.centerY.equalTo(self.tg_captureLatch);
        make.width.height.mas_equalTo(kTgDocCameraSideBtnSize);
    }];
    [self.tg_retakeLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight).offset(-50);
        make.centerY.equalTo(self.tg_captureLatch);
        make.width.height.mas_equalTo(kTgDocCameraSideBtnSize);
    }];
    [self.tg_previewContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft).offset(kTgDocCameraHorzInset);
        make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight).offset(-kTgDocCameraHorzInset);
        make.top.equalTo(self.tg_headerBar.mas_bottom).offset(10);
        make.bottom.equalTo(self.tg_captureLatch.mas_top).offset(-20);
    }];
    [self.tg_previewLayerHost mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_previewContainer);
    }];
    [self.tg_hintContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.tg_previewContainer).offset(-16);
        make.centerY.equalTo(self.tg_previewContainer);
        make.width.mas_equalTo(24);
        make.height.mas_equalTo(200);
    }];
    [self.tg_hintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.tg_hintContainer);
        make.width.lessThanOrEqualTo(self.tg_previewContainer.mas_height).offset(-32);
    }];
    [self.tg_borderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_previewContainer);
    }];
    [self.tg_capturedPreview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_previewContainer);
    }];
}

- (void)tg_layoutDashBorder {
    CGRect bounds = self.tg_borderView.bounds;
    if (bounds.size.width < 2 || bounds.size.height < 2) return;
    self.tg_dashLayer.frame = bounds;
    CGFloat inset = self.tg_dashLayer.lineWidth / 2.0;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(bounds, inset, inset)
                                                    cornerRadius:kTgDocCameraPreviewCorner];
    self.tg_dashLayer.path = path.CGPath;
}

- (void)tg_layoutRotatedHint {
    self.tg_hintLabel.transform = CGAffineTransformIdentity;
    [self.tg_hintLabel layoutIfNeeded];
    CGSize textSize = self.tg_hintLabel.bounds.size;
    if (textSize.width < 2 || textSize.height < 2) return;
    self.tg_hintLabel.transform = CGAffineTransformMakeRotation((CGFloat)M_PI_2);
    [self.tg_hintContainer mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(textSize.height);
        make.height.mas_equalTo(textSize.width);
    }];
}

#pragma mark - Phase

- (void)tg_applyPhase:(TgKycDocCameraPhase)phase {
    self.tg_phase = phase;
    BOOL live = (phase == TgKycDocCameraPhaseLive);
    self.tg_previewContainer.hidden = !live;
    self.tg_borderView.hidden = !live;
    self.tg_hintContainer.hidden = !live;
    self.tg_capturedPreview.hidden = live;
    self.tg_captureLatch.hidden = !live;
    self.tg_confirmLatch.hidden = live;
    self.tg_retakeLatch.hidden = live;
    [self.tg_captureRelay tg_setPreviewHidden:!live];
    if (live) {
        self.tg_capturedRawImage = nil;
        self.tg_capturedPreview.image = nil;
        if (self.tg_hasAppeared) {
            [self tg_startLiveCamera];
        }
    } else {
        self.tg_cameraStartScheduled = NO;
        self.tg_capturedPreview.image = self.tg_capturedRawImage;
        [self.tg_captureRelay tg_stopRunning];
    }
}

#pragma mark - Camera

- (void)tg_startLiveCamera {
    if (self.tg_phase != TgKycDocCameraPhaseLive) return;
    if (self.tg_cameraStartScheduled) return;
    self.tg_cameraStartScheduled = YES;
    __weak typeof(self) weakSelf = self;
    [self.tg_captureRelay tg_prepareSessionWithCompletion:^(BOOL success) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.tg_cameraStartScheduled = NO;
        if (self.tg_phase != TgKycDocCameraPhaseLive || !self.tg_hasAppeared) return;
        if (!success) return;
        [self.tg_captureRelay tg_startRunning];
        [self.tg_captureRelay tg_updatePreviewLayout];
    }];
}

#pragma mark - Trace

- (BOOL)tg_isPanScene {
    return [[self.tg_sceneToken lowercaseString] isEqualToString:@"pan"];
}

- (BOOL)tg_isBackScene {
    return [[self.tg_sceneToken lowercaseString] isEqualToString:@"back"];
}

#pragma mark - Actions

- (void)tg_emitOpenTrace {
    if ([self tg_isPanScene]) {
        [TgTraceRelay emitSignal:TgTraceSignalPanCameraOpen];
        return;
    }
    [TgTraceRelay emitSignal:[self tg_isBackScene] ? TgTraceSignalIdBackCameraOpen : TgTraceSignalIdFrontCameraOpen];
}

- (void)tg_onBackTap {
    if ([self tg_isPanScene]) {
        [TgTraceRelay emitSignal:TgTraceSignalPanCameraBack];
        [self tg_closeWithImage:nil];
        return;
    }
    [TgTraceRelay emitSignal:[self tg_isBackScene] ? TgTraceSignalIdBackBack : TgTraceSignalIdFrontBack];
    [self tg_closeWithImage:nil];
}

- (void)tg_onCaptureTap {
    if (self.tg_phase != TgKycDocCameraPhaseLive || self.tg_captureInFlight) return;
    self.tg_captureInFlight = YES;

    if ([self tg_isPanScene]) {
        [TgTraceRelay emitSignal:TgTraceSignalPanCapture];
    } else {
        [TgTraceRelay emitSignal:[self tg_isBackScene] ? TgTraceSignalIdBackCapture : TgTraceSignalIdFrontCapture];
    }
    __weak typeof(self) weakSelf = self;
    [self.tg_captureRelay tg_capturePhoto:^(UIImage *image) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (!image) {
            self.tg_captureInFlight = NO;
            [[TgPulseOverlay shared] whisperLine:@"The system is occupied. Please retry after 2 minutes."];
            return;
        }
        self.tg_capturedRawImage = image;
        self.tg_confirmLocked = NO;
        [self tg_applyPhase:TgKycDocCameraPhasePreview];
    }];
}

- (void)tg_onRetakeTap {
    if ([self tg_isPanScene]) {
        [TgTraceRelay emitSignal:TgTraceSignalPanRetake];
    }
    self.tg_capturedRawImage = nil;
    self.tg_confirmLocked = NO;
    self.tg_captureInFlight = NO;
    [self tg_applyPhase:TgKycDocCameraPhaseLive];
}

- (void)tg_onConfirmTap {
    if (self.tg_confirmLocked || !self.tg_capturedRawImage) return;
    self.tg_confirmLocked = YES;
    if ([self tg_isPanScene]) {
        [TgTraceRelay emitSignal:TgTraceSignalPanConfirm];
    } else {
        [TgTraceRelay emitSignal:[self tg_isBackScene] ? TgTraceSignalIdBackConfirm : TgTraceSignalIdFrontConfirm];
    }
    UIImage *output = [self.tg_captureRelay tg_rotateCounterClockwise90:self.tg_capturedRawImage];
    [self tg_closeWithImage:output ?: self.tg_capturedRawImage];
}

- (void)tg_closeWithImage:(UIImage *)image {
    [self.tg_captureRelay tg_stopRunning];
    if (self.navigationController && self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController popViewControllerAnimated:YES];
    } else if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    if (image && self.tg_finishBlock) {
        self.tg_finishBlock(image);
    }
}

@end
