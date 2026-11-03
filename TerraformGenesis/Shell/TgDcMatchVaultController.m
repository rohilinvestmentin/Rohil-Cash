//
//  TgDcMatchVaultController.m
//

#import "TgDcMatchVaultController.h"
#import "TgDockBarRelay.h"
#import "TgEnvelopeBase.h"
#import "TgDcApplyVaultController.h"
#import "TgOrderShelfController.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"
#import "TgPolicyVault.h"
#import "TgRejectWebController.h"
#import "TgWireConduit.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImage+GIF.h>

static NSString * const kTgDcMatchNavTitle = @"Accurate Recommendation";
static NSString * const kTgDcMatchLoadingTitle = @"Matching in progress";
static NSString * const kTgDcMatchLoadingBody =
    @"We are checking your profile to suggest better-fitting products. Priority matching is underway - about 10 seconds...";
static NSString * const kTgDcMatchIneligibleBody =
    @"You do not meet this product's requirements at the moment. When a better-fitting loan product is available, we will notify you in the app. Please stay tuned.";
static NSString * const kTgDcMatchOtherFallbackBody =
    @"You currently have an outstanding loan. After you repay, products with higher limits will become available.";
static NSString * const kTgDcMatchViewNowTitle = @"View Now >>";
static NSString * const kTgDcMatchLoadingGIF = @"loading";
static NSTimeInterval const kTgDcMatchTimeoutSeconds = 10.0;
static CGFloat const kTgDcMatchHorzInset = 16.0;
static CGFloat const kTgDcMatchPanelCorner = 20.0;
static CGFloat const kTgDcMatchGifSide = 72.0;
static CGFloat const kTgDcMatchButtonHeight = 56.0;
static CGFloat const kTgDcMatchButtonRadius = 28.0;
static CGFloat const kTgDcMatchButtonBottom = 40.0;

typedef NS_ENUM(NSInteger, TgDcMatchPhase) {
    TgDcMatchPhaseMatching = 0,
    TgDcMatchPhaseIneligible,
    TgDcMatchPhaseOtherError,
};

@interface TgDcMatchVaultController ()

@property (nonatomic, strong) UILabel *tg_resultCaption;
@property (nonatomic, strong) UIButton *tg_viewNowLatch;
@property (nonatomic, strong) UIView *tg_matchVeil;
@property (nonatomic, strong) UIView *tg_matchPanel;
@property (nonatomic, strong) UIImageView *tg_matchGifGlyph;
@property (nonatomic, strong) UILabel *tg_matchTitleCaption;
@property (nonatomic, strong) UILabel *tg_matchBodyCaption;
@property (nonatomic, assign) TgDcMatchPhase tg_phase;
@property (nonatomic, assign) BOOL tg_requesting;
@property (nonatomic, assign) BOOL tg_finished;
@property (nonatomic, strong, nullable) dispatch_block_t tg_timeoutBlock;

@end

@implementation TgDcMatchVaultController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.tg_backdropStyle = TgHullBackdropStyleUseBg0;
        self.tg_showsBackButton = YES;
        self.hidesBottomBarWhenPushed = YES;
        _tg_phase = TgDcMatchPhaseMatching;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self tg_setNavTitleMedium18:kTgDcMatchNavTitle];
    [self tg_buildLayout];
    [self tg_applyPhase:TgDcMatchPhaseMatching];
    [self tg_startRecommend];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    BOOL hideNav = (self.tg_phase == TgDcMatchPhaseMatching);
    [self.navigationController setNavigationBarHidden:hideNav animated:animated];
}

- (void)dealloc {
    [self tg_cancelTimeout];
}

#pragma mark - Layout

- (void)tg_buildLayout {
    self.tg_resultCaption = [[UILabel alloc] init];
    self.tg_resultCaption.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightRegular];
    self.tg_resultCaption.textColor = [UIColor tg_toneFromHex:@"#212121"];
    self.tg_resultCaption.textAlignment = NSTextAlignmentCenter;
    self.tg_resultCaption.numberOfLines = 0;
    self.tg_resultCaption.hidden = YES;
    [self.view addSubview:self.tg_resultCaption];

    self.tg_viewNowLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    self.tg_viewNowLatch.backgroundColor = [UIColor tg_toneFromHex:@"#182040"];
    self.tg_viewNowLatch.layer.cornerRadius = kTgDcMatchButtonRadius;
    self.tg_viewNowLatch.clipsToBounds = YES;
    [self.tg_viewNowLatch setTitle:kTgDcMatchViewNowTitle forState:UIControlStateNormal];
    [self.tg_viewNowLatch setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.tg_viewNowLatch.titleLabel.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    [self.tg_viewNowLatch addTarget:self action:@selector(tg_onViewNowTapped) forControlEvents:UIControlEventTouchUpInside];
    self.tg_viewNowLatch.hidden = YES;
    [self.view addSubview:self.tg_viewNowLatch];

    [self.tg_resultCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(kTgDcMatchHorzInset + 8);
        make.right.equalTo(self.view).offset(-(kTgDcMatchHorzInset + 8));
        make.centerY.equalTo(self.view).offset(-40);
    }];
    [self.tg_viewNowLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(0.85);
        make.height.mas_equalTo(kTgDcMatchButtonHeight);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-kTgDcMatchButtonBottom);
    }];

    self.tg_matchVeil = [[UIView alloc] init];
    self.tg_matchVeil.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.45];
    self.tg_matchVeil.hidden = YES;
    [self.view addSubview:self.tg_matchVeil];
    [self.tg_matchVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    self.tg_matchPanel = [[UIView alloc] init];
    self.tg_matchPanel.backgroundColor = UIColor.whiteColor;
    self.tg_matchPanel.layer.cornerRadius = kTgDcMatchPanelCorner;
    self.tg_matchPanel.clipsToBounds = YES;
    [self.tg_matchVeil addSubview:self.tg_matchPanel];

    self.tg_matchGifGlyph = [[UIImageView alloc] init];
    self.tg_matchGifGlyph.contentMode = UIViewContentModeScaleAspectFit;
    [self.tg_matchPanel addSubview:self.tg_matchGifGlyph];
    [self tg_applyLoadingGIF];

    self.tg_matchTitleCaption = [[UILabel alloc] init];
    self.tg_matchTitleCaption.text = kTgDcMatchLoadingTitle;
    self.tg_matchTitleCaption.font = [UIFont tg_meshGlyphWithSize:18 weight:UIFontWeightBold];
    self.tg_matchTitleCaption.textColor = [UIColor tg_toneFromHex:@"#182040"];
    self.tg_matchTitleCaption.textAlignment = NSTextAlignmentCenter;
    self.tg_matchTitleCaption.numberOfLines = 0;
    [self.tg_matchPanel addSubview:self.tg_matchTitleCaption];

    self.tg_matchBodyCaption = [[UILabel alloc] init];
    self.tg_matchBodyCaption.text = kTgDcMatchLoadingBody;
    self.tg_matchBodyCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    self.tg_matchBodyCaption.textColor = [UIColor tg_toneFromHex:@"#212121"];
    self.tg_matchBodyCaption.textAlignment = NSTextAlignmentCenter;
    self.tg_matchBodyCaption.numberOfLines = 0;
    [self.tg_matchPanel addSubview:self.tg_matchBodyCaption];

    [self.tg_matchPanel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.tg_matchVeil);
        make.left.equalTo(self.tg_matchVeil).offset(36);
        make.right.equalTo(self.tg_matchVeil).offset(-36);
    }];
    [self.tg_matchGifGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_matchPanel).offset(28);
        make.centerX.equalTo(self.tg_matchPanel);
        make.width.height.mas_equalTo(kTgDcMatchGifSide);
    }];
    [self.tg_matchTitleCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_matchGifGlyph.mas_bottom).offset(18);
        make.left.equalTo(self.tg_matchPanel).offset(20);
        make.right.equalTo(self.tg_matchPanel).offset(-20);
    }];
    [self.tg_matchBodyCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_matchTitleCaption.mas_bottom).offset(12);
        make.left.equalTo(self.tg_matchPanel).offset(20);
        make.right.equalTo(self.tg_matchPanel).offset(-20);
        make.bottom.equalTo(self.tg_matchPanel).offset(-28);
    }];

    __weak typeof(self) weakSelf = self;
    self.tg_backInterceptBlock = ^BOOL {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return YES;
        // Matching: block back. Other phases: allow.
        return self.tg_phase != TgDcMatchPhaseMatching;
    };
}

- (void)tg_applyLoadingGIF {
    NSString *path = [[NSBundle mainBundle] pathForResource:kTgDcMatchLoadingGIF ofType:@"gif"];
    if (path.length == 0) return;
    NSData *data = [NSData dataWithContentsOfFile:path];
    UIImage *gif = [UIImage sd_imageWithGIFData:data];
    if (gif.images.count > 0) {
        self.tg_matchGifGlyph.image = gif.images.firstObject;
        self.tg_matchGifGlyph.animationImages = gif.images;
        self.tg_matchGifGlyph.animationDuration = gif.duration > 0 ? gif.duration : 1.0;
        self.tg_matchGifGlyph.animationRepeatCount = 0;
        [self.tg_matchGifGlyph startAnimating];
        return;
    }
    if (gif) {
        self.tg_matchGifGlyph.image = gif;
    }
}

#pragma mark - Phase

- (void)tg_applyPhase:(TgDcMatchPhase)phase {
    self.tg_phase = phase;
    BOOL matching = (phase == TgDcMatchPhaseMatching);
    self.tg_matchVeil.hidden = !matching;
    self.tg_showsBackButton = !matching;
    self.navigationController.interactivePopGestureRecognizer.enabled = !matching;
    [self.navigationController setNavigationBarHidden:matching animated:YES];
    [self tg_syncBackBarForPhase];

    if (matching) {
        self.tg_resultCaption.hidden = YES;
        self.tg_viewNowLatch.hidden = YES;
        if (!self.tg_matchGifGlyph.isAnimating) {
            [self.tg_matchGifGlyph startAnimating];
        }
        return;
    }

    [self.tg_matchGifGlyph stopAnimating];
    self.tg_resultCaption.hidden = NO;
    if (phase == TgDcMatchPhaseIneligible) {
        self.tg_resultCaption.text = kTgDcMatchIneligibleBody;
        self.tg_viewNowLatch.hidden = YES;
    } else {
        NSString *copy = [self.tg_promptCopy stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
        self.tg_resultCaption.text = copy.length > 0 ? copy : kTgDcMatchOtherFallbackBody;
        self.tg_viewNowLatch.hidden = (self.tg_userStatus != 80);
    }
}

- (void)tg_syncBackBarForPhase {
    if (self.tg_phase == TgDcMatchPhaseMatching) {
        self.navigationItem.hidesBackButton = YES;
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIView alloc] init]];
        return;
    }
    self.tg_showsBackButton = YES;
    [self tg_setBackButtonImageName:self.tg_backButtonImageName];
}

#pragma mark - Network

- (void)tg_startRecommend {
    if (self.tg_requesting || self.tg_finished) return;
    self.tg_requesting = YES;
    [self tg_applyPhase:TgDcMatchPhaseMatching];

    __weak typeof(self) weakSelf = self;
    dispatch_block_t timeout = dispatch_block_create(0, ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.tg_finished) return;
        [self tg_finishIneligible];
    });
    self.tg_timeoutBlock = timeout;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kTgDcMatchTimeoutSeconds * NSEC_PER_SEC)),
                   dispatch_get_main_queue(),
                   timeout);

    [[TgWireConduit shared] relayPOST:TgLaneDcRecommend
                             signData:@{}
                           nonSignData:@{}
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.tg_finished) return;
        [self tg_handleEnvelope:envelope];
    } failure:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.tg_finished) return;
        [self tg_finishOtherError];
    }];
}

- (void)tg_cancelTimeout {
    if (self.tg_timeoutBlock) {
        dispatch_block_cancel(self.tg_timeoutBlock);
        self.tg_timeoutBlock = nil;
    }
}

- (void)tg_handleEnvelope:(TgEnvelopeBase *)envelope {
    NSString *code = [NSString stringWithFormat:@"%ld", (long)envelope.cheer];
    if ([code isEqualToString:TgFaultRejectNoProduct]) {
        // 4102007 → rejectH5 if configured, else no-product page (docs 50 §3.4.2)
        [self tg_finishNoProductOrReject];
        return;
    }
    if (envelope.cheer != 200) {
        [self tg_finishOtherError];
        return;
    }

    TgProductListData *listData = [TgProductListData yy_modelWithJSON:envelope.trick];
    NSArray<TgProductInfo *> *products = listData.portrait ?: @[];
    if (products.count == 0) {
        // Also accept direct array / nested portrait on trick dict
        if ([envelope.trick isKindOfClass:[NSDictionary class]]) {
            id raw = [(NSDictionary *)envelope.trick objectForKey:@"productInfoList"];
            if ([raw isKindOfClass:[NSArray class]] && [(NSArray *)raw count] > 0) {
                products = [NSArray yy_modelArrayWithClass:[TgProductInfo class] json:raw] ?: @[];
            }
        }
    }
    if (products.count == 0) {
        // Success empty list: same branch as 4102007
        [self tg_finishNoProductOrReject];
        return;
    }
    [self tg_finishWithProducts:products];
}

/// Timeout only → no-product page (never reject H5).
- (void)tg_finishIneligible {
    if (self.tg_finished) return;
    self.tg_finished = YES;
    self.tg_requesting = NO;
    [self tg_cancelTimeout];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self tg_applyPhase:TgDcMatchPhaseIneligible];
}

/// 4102007 / empty productInfoList: rejectH5 non-empty → replace match page; else no-product.
- (void)tg_finishNoProductOrReject {
    if (self.tg_finished) return;
    self.tg_finished = YES;
    self.tg_requesting = NO;
    [self tg_cancelTimeout];
    [self.tg_matchGifGlyph stopAnimating];

    __weak typeof(self) weakSelf = self;
    void (^applyBranch)(void) = ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if ([TgRejectWebController tg_tryReplaceTopFromNav:self.navigationController]) {
            return;
        }
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        [self tg_applyPhase:TgDcMatchPhaseIneligible];
    };

    // Cached rejectH5: use immediately. Empty/missing: force pull once (cache may be stale).
    if ([TgRejectWebController tg_cachedRejectH5URLString].length > 0) {
        applyBranch();
        return;
    }
    [[TgPolicyVault shared] pullManifestSuccess:^(TgSystemConfigModel *cfg) {
        (void)cfg;
        applyBranch();
    } failure:^{
        applyBranch();
    }];
}

- (void)tg_finishOtherError {
    if (self.tg_finished) return;
    self.tg_finished = YES;
    self.tg_requesting = NO;
    [self tg_cancelTimeout];
    [self tg_applyPhase:TgDcMatchPhaseOtherError];
}

- (void)tg_finishWithProducts:(NSArray<TgProductInfo *> *)products {
    if (self.tg_finished) return;
    self.tg_finished = YES;
    self.tg_requesting = NO;
    [self tg_cancelTimeout];
    [self.tg_matchGifGlyph stopAnimating];
    self.tg_matchVeil.hidden = YES;

    if (products.count == 0 || !self.navigationController) {
        [self tg_finishIneligible];
        return;
    }

    NSMutableArray *stack = [self.navigationController.viewControllers mutableCopy];
    if (stack.count > 0) {
        [stack removeLastObject];
    }
    TgDcApplyVaultController *apply = [[TgDcApplyVaultController alloc] init];
    apply.tg_products = products;
    apply.hidesBottomBarWhenPushed = YES;
    [stack addObject:apply];
    [self.navigationController setViewControllers:stack animated:YES];
}

#pragma mark - Actions

- (void)tg_onViewNowTapped {
    UITabBarController *dock = self.tabBarController;
    if (dock) {
        [TgDockBarRelay primeRootAtIndex:TgDockTabIndexOrder dock:dock];
        dock.selectedIndex = TgDockTabIndexOrder;
        UINavigationController *orderNav = (UINavigationController *)dock.viewControllers[TgDockTabIndexOrder];
        if ([orderNav isKindOfClass:[UINavigationController class]]) {
            [orderNav popToRootViewControllerAnimated:NO];
        }
        [TgOrderShelfController tg_requestFocusSectionWithApiOrderStatus:20];
        [self.navigationController popToRootViewControllerAnimated:NO];
        return;
    }
    if (!self.navigationController) return;
    [TgOrderShelfController tg_requestFocusSectionWithApiOrderStatus:20];
    TgOrderShelfController *orderVC = [[TgOrderShelfController alloc] init];
    orderVC.hidesBottomBarWhenPushed = YES;
    NSMutableArray *stack = [self.navigationController.viewControllers mutableCopy];
    if (stack.count > 0) [stack removeLastObject];
    [stack addObject:orderVC];
    [self.navigationController setViewControllers:stack animated:YES];
}

@end
