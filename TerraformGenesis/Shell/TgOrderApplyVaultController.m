//

//

#import "TgOrderApplyVaultController.h"
#import "TgEnvelopeBase.h"
#import "TgDockBarRelay.h"
#import "TgOrderForgeRelay.h"
#import "TgOrderSuccessVaultController.h"
#import "TgPaneWebController.h"
#import "TgPureLinks.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"
#import "TgPolicyVault.h"
#import "TgPulseOverlay.h"
#import "TgShardFacade.h"
#import "TgTraceRelay.h"
#import "TgWireConduit.h"
#import "NSString+TgGlyph.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <objc/runtime.h>

static CGFloat const kTgApplyHorzInset = 16.0;
static CGFloat const kTgApplyBannerHeight = 42.0;
static CGFloat const kTgApplyCardRadius = 16.0;
static CGFloat const kTgApplyCardOverlap = 10.0;
static CGFloat const kTgApplyAmountBgRatio = 147.0 / 315.0;
static CGFloat const kTgApplyApplyHeight = 50.0;
static CGFloat const kTgApplyApplyWidthRatio = 0.85;
static CGFloat const kTgApplyGradientDesignW = 375.0;
static CGFloat const kTgApplyGradientDesignH = 496.0;
static CGFloat const kTgApplyBelowNavOffset = 20.0;
static CGFloat const kTgApplyBannerUpExtra = 15.0;
static CGFloat const kTgApplyAmountAreaLeftInset = 16.0;
static CGFloat const kTgApplyAmountArrowGap = 15.0;
static CGFloat const kTgApplyProductPillHeight = 32.0;
static CGFloat const kTgApplyLogoCornerRadius = 4.0;
static CGFloat const kTgApplyProductRowUpOffset = 10.0;
static NSString * const kTgApplyBackAsset = @"gst_tab";
static NSString * const kTgApplyWaveAsset = @"use_Subtract1";

static NSString * const kTgApplyBannerAsset = @"use_loan_01";
static NSString * const kTgApplyAmountBgAsset = @"use_bg_loan";
static NSString * const kTgApplyStarAsset = @"use_star_01";
static NSString * const kTgApplyArrowAsset = @"use_next_loan_xiao";
static NSString * const kTgApplyTipIconAsset = @"details";
static NSString * const kTgApplyTermsOnAsset = @"due_Terms_yes";
static NSString * const kTgApplyTermsOffAsset = @"due_Terms_no";
static NSString * const kTgApplyAmountToneHex = @"#C51B12";
static NSString * const kTgApplyValueToneHex = @"#C51B12";
static NSString * const kTgApplyProductNameHex = @"#777ACD";
static NSString * const kTgApplyLogoBgHex = @"#777ACD";
static NSString * const kTgApplyProductPillHex = @"#B7BFEE";
static NSString * const kTgApplyHintToneHex = @"#2C42C4";
static NSString * const kTgApplyAmountLineHex = @"#2F45C7";
static NSString * const kTgApplyApplyBtnHex = @"#182040";
static NSString * const kTgApplyCreditTipHex = @"#FFF4E8";
static NSString * const kTgApplyCreditTipTextHex = @"#E67E22";

static NSString * const kTgApplyCreditTipText =
    @"A strong credit score can unlock a higher loan amount. Keep your credit healthy to enjoy a larger limit.";

static NSString * const kTgApplyTipAmountReceived =
    @"The amount you actually receive equals the loan amount minus the service fee and GST.";
static NSString * const kTgApplyTipInterest =
    @"Computed from your loan amount, loan term, and this product's interest rate.";
static NSString * const kTgApplyTipServiceFee =
    @"This fee is charged by the financial institution for delivering loan services.";
static NSString * const kTgApplyBackRetainMessage =
    @"It would be a shame to leave now. Substantial loan credit is still waiting for you to withdraw - please reconsider!";

static const void *kTgApplyTipTextKey = &kTgApplyTipTextKey;

@interface TgOrderApplyVaultController () <UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong) UIScrollView *tg_scrollPane;
@property (nonatomic, strong) UIView *tg_scrollBody;
@property (nonatomic, strong) UIView *tg_gradientVeil;
@property (nonatomic, strong) CAGradientLayer *tg_headerGradient;
@property (nonatomic, strong) UIImageView *tg_bannerGlyph;
@property (nonatomic, strong) MASConstraint *tg_gradientHeightConstraint;
@property (nonatomic, strong) MASConstraint *tg_bannerTopConstraint;

@property (nonatomic, strong) UIView *tg_mainCard;
@property (nonatomic, strong) UIView *tg_amountVeil;
@property (nonatomic, strong) UIImageView *tg_amountBgGlyph;
@property (nonatomic, strong) UIImageView *tg_starGlyph;
@property (nonatomic, strong) UIView *tg_productPill;
@property (nonatomic, strong) UIImageView *tg_logoGlyph;
@property (nonatomic, strong) UILabel *tg_nameCaption;
@property (nonatomic, strong) UIStackView *tg_amountHeaderStack;
@property (nonatomic, strong) UIStackView *tg_amountRowStack;
@property (nonatomic, strong) UILabel *tg_amountHintCaption;
@property (nonatomic, strong) UILabel *tg_amountValueCaption;
@property (nonatomic, strong) UIImageView *tg_amountArrowGlyph;
@property (nonatomic, strong) UIView *tg_amountUnderline;
@property (nonatomic, strong) UIButton *tg_amountTapLatch;
@property (nonatomic, strong) UIImageView *tg_waveCap;
@property (nonatomic, strong) UIStackView *tg_detailStack;
@property (nonatomic, strong) UILabel *tg_creditTipCaption;

@property (nonatomic, strong) UIView *tg_selCard;
@property (nonatomic, strong) UILabel *tg_termTitleCaption;
@property (nonatomic, strong) UILabel *tg_termValueCaption;
@property (nonatomic, strong) UIImageView *tg_termArrowGlyph;
@property (nonatomic, strong) UIButton *tg_termTapLatch;
@property (nonatomic, strong) UIView *tg_selDivider;
@property (nonatomic, strong) UILabel *tg_bankTitleCaption;
@property (nonatomic, strong) UILabel *tg_bankValueCaption;

@property (nonatomic, strong) UIView *tg_bottomBar;
@property (nonatomic, strong) UIButton *tg_agreeLatch;
@property (nonatomic, strong) UILabel *tg_agreeCaption;
@property (nonatomic, strong) UIButton *tg_applyLatch;

@property (nonatomic, strong, nullable) TgProductTermData *tg_termData;
@property (nonatomic, copy) NSArray<TgAmountDetail *> *tg_sortedAmounts;
@property (nonatomic, assign) NSInteger tg_pickedAmountIdx;
@property (nonatomic, assign) NSInteger tg_pickedTermIdx;
@property (nonatomic, assign) NSInteger tg_pickedEmiIdx;
@property (nonatomic, assign) BOOL tg_hasEmiOptions;
@property (nonatomic, assign) BOOL tg_isAgreed;
@property (nonatomic, assign) BOOL tg_loading;

@end

@implementation TgOrderApplyVaultController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.tg_backdropStyle = TgHullBackdropStylePlain;
        self.tg_showsBackButton = YES;
        self.tg_backButtonImageName = kTgApplyBackAsset;
        self.hidesBottomBarWhenPushed = YES;
        _tg_isAgreed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor tg_toneFromHex:@"#F1F1F1"];
    [self tg_setNavTitle:@"Loan details" color:UIColor.whiteColor fontSize:18];
    [self tg_installBackIntercept];
    [self tg_buildLayout];
    if (self.tg_preloadedTermJSON.count > 0) {
        [self tg_resolveTermPayload:self.tg_preloadedTermJSON];
    } else {
        [self tg_fetchTerm];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    self.navigationController.navigationBar.tintColor = UIColor.whiteColor;
    [self tg_updateBannerTopInset];
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    [self tg_updateBannerTopInset];
}

- (CGFloat)tg_bannerTopOffsetFromNavigation {
    CGFloat navBottom = self.view.safeAreaInsets.top;
    if (self.navigationController && !self.navigationController.navigationBarHidden) {
        CGFloat navH = CGRectGetHeight(self.navigationController.navigationBar.frame);
        if (navH <= 0) {
            navH = 44.0;
        }
        navBottom += navH;
    }
    return navBottom + kTgApplyBelowNavOffset - kTgApplyBannerUpExtra;
}

- (void)tg_updateBannerTopInset {
    if (!self.tg_bannerTopConstraint) return;
    [self.tg_bannerTopConstraint setOffset:[self tg_bannerTopOffsetFromNavigation]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tg_headerGradient.frame = self.tg_gradientVeil.bounds;
    CGFloat gradientH = CGRectGetWidth(self.view.bounds) * (kTgApplyGradientDesignH / kTgApplyGradientDesignW);
    [self.tg_gradientHeightConstraint setOffset:gradientH];
    [self tg_updateBannerTopInset];
}

#pragma mark - Layout

- (void)tg_applyHeaderGradient {
    self.tg_headerGradient = [CAGradientLayer layer];
    self.tg_headerGradient.startPoint = CGPointMake(0.73, 0.23);
    self.tg_headerGradient.endPoint = CGPointMake(0.73, 0.78);
    self.tg_headerGradient.colors = @[
        (__bridge id)[UIColor colorWithRed:54/255.0 green:83/255.0 blue:255/255.0 alpha:1].CGColor,
        (__bridge id)[UIColor colorWithRed:241/255.0 green:241/255.0 blue:241/255.0 alpha:1].CGColor
    ];
    self.tg_headerGradient.locations = @[@0, @0.9f];
    [self.tg_gradientVeil.layer insertSublayer:self.tg_headerGradient atIndex:0];
}

- (void)tg_buildLayout {
    self.tg_scrollPane = [[UIScrollView alloc] init];
    self.tg_scrollPane.showsVerticalScrollIndicator = NO;
    self.tg_scrollPane.alwaysBounceVertical = YES;
    self.tg_scrollPane.backgroundColor = UIColor.clearColor;
    self.tg_scrollPane.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:self.tg_scrollPane];

    self.tg_scrollBody = [[UIView alloc] init];
    [self.tg_scrollPane addSubview:self.tg_scrollBody];

    self.tg_gradientVeil = [[UIView alloc] init];
    self.tg_gradientVeil.clipsToBounds = YES;
    [self tg_applyHeaderGradient];
    [self.tg_scrollBody addSubview:self.tg_gradientVeil];

    self.tg_bannerGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgApplyBannerAsset]];
    self.tg_bannerGlyph.contentMode = UIViewContentModeScaleAspectFill;
    self.tg_bannerGlyph.clipsToBounds = YES;
    self.tg_bannerGlyph.layer.cornerRadius = 12;
    [self.tg_gradientVeil addSubview:self.tg_bannerGlyph];

    self.tg_mainCard = [[UIView alloc] init];
    self.tg_mainCard.backgroundColor = UIColor.whiteColor;
    self.tg_mainCard.layer.cornerRadius = kTgApplyCardRadius;
    self.tg_mainCard.clipsToBounds = YES;
    [self.tg_scrollBody addSubview:self.tg_mainCard];

    self.tg_amountVeil = [[UIView alloc] init];
    self.tg_amountVeil.clipsToBounds = YES;
    [self.tg_mainCard addSubview:self.tg_amountVeil];

    self.tg_amountBgGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgApplyAmountBgAsset]];
    self.tg_amountBgGlyph.contentMode = UIViewContentModeScaleAspectFill;
    [self.tg_amountVeil addSubview:self.tg_amountBgGlyph];

    self.tg_starGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgApplyStarAsset]];
    self.tg_starGlyph.contentMode = UIViewContentModeScaleAspectFit;
    [self.tg_amountVeil addSubview:self.tg_starGlyph];

    self.tg_productPill = [[UIView alloc] init];
    self.tg_productPill.backgroundColor = [UIColor tg_toneFromHex:kTgApplyProductPillHex];
    self.tg_productPill.layer.cornerRadius = kTgApplyProductPillHeight / 2.0;
    self.tg_productPill.clipsToBounds = YES;
    [self.tg_amountVeil addSubview:self.tg_productPill];

    self.tg_logoGlyph = [[UIImageView alloc] init];
    self.tg_logoGlyph.contentMode = UIViewContentModeScaleAspectFit;
    self.tg_logoGlyph.layer.cornerRadius = kTgApplyLogoCornerRadius;
    self.tg_logoGlyph.clipsToBounds = YES;
    self.tg_logoGlyph.backgroundColor = [UIColor tg_toneFromHex:kTgApplyLogoBgHex];
    [self.tg_productPill addSubview:self.tg_logoGlyph];

    self.tg_nameCaption = [[UILabel alloc] init];
    self.tg_nameCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightBold];
    self.tg_nameCaption.textColor = [UIColor tg_toneFromHex:kTgApplyProductNameHex];
    [self.tg_productPill addSubview:self.tg_nameCaption];

    self.tg_amountHintCaption = [[UILabel alloc] init];
    self.tg_amountHintCaption.font = [UIFont tg_meshGlyphWithSize:13 weight:UIFontWeightRegular];
    self.tg_amountHintCaption.textColor = [UIColor tg_toneFromHex:kTgApplyHintToneHex];
    self.tg_amountHintCaption.textAlignment = NSTextAlignmentLeft;
    self.tg_amountHintCaption.numberOfLines = 0;

    self.tg_amountValueCaption = [[UILabel alloc] init];
    self.tg_amountValueCaption.font = [UIFont tg_meshGlyphWithSize:32 weight:UIFontWeightBold];
    self.tg_amountValueCaption.textColor = [UIColor tg_toneFromHex:kTgApplyAmountToneHex];
    self.tg_amountValueCaption.textAlignment = NSTextAlignmentLeft;
    self.tg_amountValueCaption.adjustsFontSizeToFitWidth = YES;
    self.tg_amountValueCaption.minimumScaleFactor = 0.6;

    self.tg_amountArrowGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgApplyArrowAsset]];
    self.tg_amountArrowGlyph.contentMode = UIViewContentModeScaleAspectFit;

    self.tg_amountRowStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.tg_amountValueCaption, self.tg_amountArrowGlyph]];
    self.tg_amountRowStack.axis = UILayoutConstraintAxisHorizontal;
    self.tg_amountRowStack.alignment = UIStackViewAlignmentCenter;
    self.tg_amountRowStack.spacing = kTgApplyAmountArrowGap;

    self.tg_amountUnderline = [[UIView alloc] init];
    self.tg_amountUnderline.backgroundColor = [UIColor tg_toneFromHex:kTgApplyAmountLineHex];

    self.tg_amountHeaderStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.tg_productPill,
        self.tg_amountHintCaption,
        self.tg_amountRowStack,
        self.tg_amountUnderline
    ]];
    self.tg_amountHeaderStack.axis = UILayoutConstraintAxisVertical;
    self.tg_amountHeaderStack.alignment = UIStackViewAlignmentLeading;
    self.tg_amountHeaderStack.spacing = 8;
    [self.tg_amountVeil addSubview:self.tg_amountHeaderStack];

    self.tg_amountTapLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_amountTapLatch addTarget:self action:@selector(tg_onAmountRowTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.tg_amountVeil addSubview:self.tg_amountTapLatch];

    self.tg_waveCap = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgApplyWaveAsset]];
    self.tg_waveCap.contentMode = UIViewContentModeScaleToFill;
    [self.tg_mainCard addSubview:self.tg_waveCap];

    self.tg_detailStack = [[UIStackView alloc] init];
    self.tg_detailStack.axis = UILayoutConstraintAxisVertical;
    self.tg_detailStack.spacing = 0;
    self.tg_detailStack.alignment = UIStackViewAlignmentFill;
    [self.tg_mainCard addSubview:self.tg_detailStack];

    UIView *tipBox = [[UIView alloc] init];
    tipBox.backgroundColor = [UIColor tg_toneFromHex:kTgApplyCreditTipHex];
    tipBox.layer.cornerRadius = 8;
    tipBox.clipsToBounds = YES;
    [self.tg_mainCard addSubview:tipBox];

    self.tg_creditTipCaption = [[UILabel alloc] init];
    self.tg_creditTipCaption.text = kTgApplyCreditTipText;
    self.tg_creditTipCaption.font = [UIFont tg_meshGlyphWithSize:12 weight:UIFontWeightRegular];
    self.tg_creditTipCaption.textColor = [UIColor tg_toneFromHex:kTgApplyCreditTipTextHex];
    self.tg_creditTipCaption.numberOfLines = 0;
    [tipBox addSubview:self.tg_creditTipCaption];

    self.tg_selCard = [[UIView alloc] init];
    self.tg_selCard.backgroundColor = UIColor.whiteColor;
    self.tg_selCard.layer.cornerRadius = kTgApplyCardRadius;
    self.tg_selCard.clipsToBounds = YES;
    [self.tg_scrollBody addSubview:self.tg_selCard];

    self.tg_termTitleCaption = [[UILabel alloc] init];
    self.tg_termTitleCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    self.tg_termTitleCaption.textColor = [UIColor tg_toneFromHex:@"#686868"];
    [self.tg_selCard addSubview:self.tg_termTitleCaption];

    self.tg_termValueCaption = [[UILabel alloc] init];
    self.tg_termValueCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightBold];
    self.tg_termValueCaption.textColor = [UIColor tg_toneFromHex:kTgApplyValueToneHex];
    self.tg_termValueCaption.textAlignment = NSTextAlignmentRight;
    [self.tg_selCard addSubview:self.tg_termValueCaption];

    self.tg_termArrowGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgApplyArrowAsset]];
    self.tg_termArrowGlyph.contentMode = UIViewContentModeScaleAspectFit;
    [self.tg_selCard addSubview:self.tg_termArrowGlyph];

    self.tg_termTapLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_termTapLatch addTarget:self action:@selector(tg_onTermRowTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.tg_selCard addSubview:self.tg_termTapLatch];

    self.tg_selDivider = [[UIView alloc] init];
    self.tg_selDivider.backgroundColor = [UIColor tg_toneFromHex:@"#E5E7EB"];
    [self.tg_selCard addSubview:self.tg_selDivider];

    self.tg_bankTitleCaption = [[UILabel alloc] init];
    self.tg_bankTitleCaption.text = @"Bank account number";
    self.tg_bankTitleCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    self.tg_bankTitleCaption.textColor = [UIColor tg_toneFromHex:@"#686868"];
    [self.tg_selCard addSubview:self.tg_bankTitleCaption];

    self.tg_bankValueCaption = [[UILabel alloc] init];
    self.tg_bankValueCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightBold];
    self.tg_bankValueCaption.textColor = [UIColor tg_toneFromHex:kTgApplyValueToneHex];
    self.tg_bankValueCaption.textAlignment = NSTextAlignmentRight;
    self.tg_bankValueCaption.adjustsFontSizeToFitWidth = YES;
    self.tg_bankValueCaption.minimumScaleFactor = 0.75;
    [self.tg_selCard addSubview:self.tg_bankValueCaption];

    self.tg_bottomBar = [[UIView alloc] init];
    self.tg_bottomBar.backgroundColor = UIColor.clearColor;
    [self.view addSubview:self.tg_bottomBar];

    self.tg_agreeLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_agreeLatch setImage:[UIImage imageNamed:kTgApplyTermsOnAsset] forState:UIControlStateNormal];
    [self.tg_agreeLatch addTarget:self action:@selector(tg_onAgreeToggled) forControlEvents:UIControlEventTouchUpInside];
    [self.tg_bottomBar addSubview:self.tg_agreeLatch];

    self.tg_agreeCaption = [[UILabel alloc] init];
    self.tg_agreeCaption.userInteractionEnabled = YES;
    self.tg_agreeCaption.numberOfLines = 2;
    [self tg_renderAgreementText];
    UITapGestureRecognizer *termsTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tg_onTermsLinkTapped)];
    [self.tg_agreeCaption addGestureRecognizer:termsTap];
    [self.tg_bottomBar addSubview:self.tg_agreeCaption];

    self.tg_applyLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_applyLatch setTitle:@"Apply" forState:UIControlStateNormal];
    [self.tg_applyLatch setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.tg_applyLatch.titleLabel.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    self.tg_applyLatch.backgroundColor = [UIColor tg_toneFromHex:kTgApplyApplyBtnHex];
    self.tg_applyLatch.layer.cornerRadius = kTgApplyApplyHeight / 2.0;
    self.tg_applyLatch.clipsToBounds = YES;
    [self.tg_applyLatch addTarget:self action:@selector(tg_onApplyTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.tg_bottomBar addSubview:self.tg_applyLatch];

    [self.tg_scrollPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(self.view);
        make.bottom.equalTo(self.tg_bottomBar.mas_top);
    }];

    [self.tg_scrollBody mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_scrollPane);
        make.width.equalTo(self.tg_scrollPane);
    }];

    [self.tg_gradientVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.tg_scrollBody);
        self.tg_gradientHeightConstraint = make.height.mas_equalTo(200);
    }];

    [self.tg_bannerGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.tg_gradientVeil).inset(kTgApplyHorzInset);
        self.tg_bannerTopConstraint = make.top.equalTo(self.tg_gradientVeil).offset(kTgApplyBelowNavOffset);
        make.height.mas_equalTo(kTgApplyBannerHeight);
    }];

    [self.tg_mainCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.tg_scrollBody).inset(kTgApplyHorzInset);
        make.top.equalTo(self.tg_bannerGlyph.mas_bottom).offset(12);
    }];

    UIImage *waveImg = [UIImage imageNamed:kTgApplyWaveAsset];
    CGFloat waveRatio = (waveImg.size.width > 0) ? (waveImg.size.height / waveImg.size.width) : 0.18;

    [self.tg_amountVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.tg_mainCard);
        make.height.equalTo(self.tg_amountVeil.mas_width).multipliedBy(kTgApplyAmountBgRatio);
    }];

    [self.tg_amountBgGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_amountVeil);
    }];

    [self.tg_starGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.tg_amountVeil).offset(-8);
        make.top.equalTo(self.tg_amountVeil).offset(8);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(76);
    }];

    [self.tg_amountHeaderStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.tg_amountVeil).offset(-kTgApplyProductRowUpOffset);
        make.left.equalTo(self.tg_amountVeil).offset(kTgApplyAmountAreaLeftInset);
        make.right.lessThanOrEqualTo(self.tg_starGlyph.mas_left).offset(-8);
    }];

    [self.tg_productPill mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(kTgApplyProductPillHeight);
    }];

    [self.tg_logoGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_productPill).offset(6);
        make.centerY.equalTo(self.tg_productPill);
        make.width.height.mas_equalTo(20);
    }];

    [self.tg_nameCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_logoGlyph.mas_right).offset(6);
        make.centerY.equalTo(self.tg_productPill);
        make.right.equalTo(self.tg_productPill).offset(-10);
    }];

    [self.tg_amountArrowGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(16);
    }];

    [self.tg_amountUnderline mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(1);
        make.width.equalTo(self.tg_amountRowStack);
    }];

    [self.tg_amountTapLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.tg_amountVeil);
        make.top.equalTo(self.tg_amountHintCaption.mas_top);
    }];

    [self.tg_waveCap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.tg_mainCard);
        make.top.equalTo(self.tg_amountVeil.mas_bottom).offset(-kTgApplyCardOverlap);
        make.height.equalTo(self.tg_waveCap.mas_width).multipliedBy(waveRatio);
    }];

    [self.tg_detailStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_waveCap.mas_bottom);
        make.left.right.equalTo(self.tg_mainCard).inset(16);
    }];

    UIView *creditTipBox = self.tg_creditTipCaption.superview;
    [creditTipBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_detailStack.mas_bottom).offset(12);
        make.left.right.equalTo(self.tg_mainCard).inset(16);
        make.bottom.equalTo(self.tg_mainCard).offset(-14);
    }];
    [self.tg_creditTipCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(creditTipBox).insets(UIEdgeInsetsMake(10, 12, 10, 12));
    }];

    [self.tg_selCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_mainCard.mas_bottom).offset(12);
        make.left.right.equalTo(self.tg_scrollBody).inset(kTgApplyHorzInset);
        make.bottom.equalTo(self.tg_scrollBody).offset(-24);
    }];

    [self.tg_termTitleCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_selCard).offset(16);
        make.top.equalTo(self.tg_selCard).offset(14);
        make.width.lessThanOrEqualTo(self.tg_selCard).multipliedBy(0.5);
    }];

    [self.tg_termArrowGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.tg_selCard).offset(-16);
        make.centerY.equalTo(self.tg_termTitleCaption);
        make.width.height.mas_equalTo(16);
    }];

    [self.tg_termValueCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.tg_termTitleCaption);
        make.right.equalTo(self.tg_termArrowGlyph.mas_left).offset(-6);
        make.left.greaterThanOrEqualTo(self.tg_termTitleCaption.mas_right).offset(8);
    }];

    [self.tg_termTapLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(self.tg_selCard);
        make.bottom.equalTo(self.tg_selDivider.mas_top);
    }];

    [self.tg_selDivider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.tg_selCard).inset(16);
        make.top.equalTo(self.tg_termTitleCaption.mas_bottom).offset(14);
        make.height.mas_equalTo(0.5);
    }];

    [self.tg_bankTitleCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_selCard).offset(16);
        make.top.equalTo(self.tg_selDivider.mas_bottom).offset(14);
        make.bottom.equalTo(self.tg_selCard).offset(-14);
        make.width.lessThanOrEqualTo(self.tg_selCard).multipliedBy(0.45);
    }];

    [self.tg_bankValueCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.tg_bankTitleCaption);
        make.right.equalTo(self.tg_selCard).offset(-16);
        make.left.greaterThanOrEqualTo(self.tg_bankTitleCaption.mas_right).offset(8);
    }];

    CGFloat applyW = UIScreen.mainScreen.bounds.size.width * kTgApplyApplyWidthRatio;
    [self.tg_bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
    }];

    [self.tg_agreeLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_bottomBar).offset(20);
        make.top.equalTo(self.tg_bottomBar).offset(4);
        make.width.height.mas_equalTo(24);
    }];

    [self.tg_agreeCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_agreeLatch.mas_right).offset(8);
        make.right.equalTo(self.tg_bottomBar).offset(-20);
        make.centerY.equalTo(self.tg_agreeLatch);
    }];

    [self.tg_applyLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_agreeLatch.mas_bottom).offset(12);
        make.centerX.equalTo(self.tg_bottomBar);
        make.width.mas_equalTo(applyW);
        make.height.mas_equalTo(kTgApplyApplyHeight);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-12);
    }];
}

#pragma mark - Network

- (void)tg_fetchTerm {
    NSString *productId = [self.tg_productId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (productId.length == 0) {
        [[TgPulseOverlay shared] whisperLine:@"Product ID is not set"];
        return;
    }
    if (self.tg_loading) return;
    self.tg_loading = YES;
    [[TgPulseOverlay shared] veilSpin];

    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneProductTerm
                             signData:@{@"productId": productId}
                           nonSignData:@{}
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.tg_loading = NO;
        [[TgPulseOverlay shared] veilDismiss];
        if (envelope.cheer == 200 && envelope.trick) {
            [self tg_resolveTermPayload:envelope.trick];
        } else {
            NSString *msg = [envelope.power stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
            [[TgPulseOverlay shared] whisperLine:msg.length > 0 ? msg : @"Unable to load loan details"];
        }
    } failure:^{
        __strong typeof(weakSelf) self = weakSelf;
        self.tg_loading = NO;
        [[TgPulseOverlay shared] veilDismiss];
        [[TgPulseOverlay shared] whisperLine:@"The system is occupied. Please retry after 2 minutes."];
    }];
}

- (void)tg_resolveTermPayload:(id)rawData {
    TgProductTermData *data = [TgProductTermData yy_modelWithJSON:rawData];
    if (!data || data.nonsense.count == 0) {
        [[TgPulseOverlay shared] whisperLine:@"No loan options are available"];
        return;
    }
    self.tg_termData = data;
    self.tg_sortedAmounts = [self tg_sortAmountList:data.nonsense];
    self.tg_pickedAmountIdx = 0;
    self.tg_pickedTermIdx = 0;
    self.tg_pickedEmiIdx = 0;
    [self tg_detectEmiAvailability];
    [self tg_refreshEntireDisplay];
}

#pragma mark - Sort / Access

- (NSArray<TgAmountDetail *> *)tg_sortAmountList:(NSArray<TgAmountDetail *> *)list {
    return [list sortedArrayUsingComparator:^NSComparisonResult(TgAmountDetail *a, TgAmountDetail *b) {
        NSInteger av = [self tg_integerFromString:a.inch];
        NSInteger bv = [self tg_integerFromString:b.inch];
        if (av == bv) return NSOrderedSame;
        return av > bv ? NSOrderedAscending : NSOrderedDescending;
    }];
}

- (NSArray<TgTermDetail *> *)tg_sortTermList:(NSArray<TgTermDetail *> *)list {
    return [list sortedArrayUsingComparator:^NSComparisonResult(TgTermDetail *a, TgTermDetail *b) {
        NSInteger av = a.ill > 0 ? a.ill : a.culture;
        NSInteger bv = b.ill > 0 ? b.ill : b.culture;
        if (av == bv) return NSOrderedSame;
        return av < bv ? NSOrderedAscending : NSOrderedDescending;
    }];
}

- (NSInteger)tg_integerFromString:(NSString *)raw {
    NSString *trim = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (trim.length == 0) return 0;
    return (NSInteger)trim.longLongValue;
}

- (TgAmountDetail *)tg_activeAmount {
    if (self.tg_pickedAmountIdx < 0 || self.tg_pickedAmountIdx >= (NSInteger)self.tg_sortedAmounts.count) return nil;
    return self.tg_sortedAmounts[self.tg_pickedAmountIdx];
}

- (NSArray<TgTermDetail *> *)tg_sortedTermsForActiveAmount {
    TgAmountDetail *amount = [self tg_activeAmount];
    if (!amount.eighth.count) return @[];
    return [self tg_sortTermList:amount.eighth];
}

- (TgTermDetail *)tg_activeTerm {
    NSArray<TgTermDetail *> *terms = [self tg_sortedTermsForActiveAmount];
    if (terms.count == 0) return nil;
    if (self.tg_hasEmiOptions) {
        if (self.tg_pickedEmiIdx < 0 || self.tg_pickedEmiIdx >= (NSInteger)terms.count) return terms.firstObject;
        return terms[self.tg_pickedEmiIdx];
    }
    if (self.tg_pickedTermIdx < 0 || self.tg_pickedTermIdx >= (NSInteger)terms.count) return terms.firstObject;
    return terms[self.tg_pickedTermIdx];
}

- (void)tg_detectEmiAvailability {
    self.tg_hasEmiOptions = NO;
    TgAmountDetail *amount = [self tg_activeAmount];
    for (TgTermDetail *t in amount.eighth) {
        if (t.EMIs > 0) {
            self.tg_hasEmiOptions = YES;
            break;
        }
    }
}

#pragma mark - Refresh UI

- (void)tg_refreshEntireDisplay {
    [self tg_refreshProductHeader];
    [self tg_refreshAmountSection];
    [self tg_refreshDetailRows];
    [self tg_refreshTermRow];
    [self tg_refreshBankRow];
}

- (void)tg_refreshProductHeader {
    TgProductTermData *data = self.tg_termData;
    NSString *name = [data.other stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    self.tg_nameCaption.text = name.length > 0 ? name : @"-";
    NSString *logo = [data.green stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (logo.length > 0) {
        [self.tg_logoGlyph sd_setImageWithURL:[NSURL URLWithString:logo] placeholderImage:nil];
    } else {
        [self.tg_logoGlyph sd_cancelCurrentImageLoad];
        self.tg_logoGlyph.image = nil;
    }
}

- (void)tg_refreshAmountSection {
    TgAmountDetail *amount = [self tg_activeAmount];
    NSString *digits = [amount.inch stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    self.tg_amountValueCaption.text = [NSString stringWithFormat:@"₹%@", [NSString tg_weaveIndianDigits:digits.length > 0 ? digits : @"0"]];

    BOOL multiAmount = self.tg_sortedAmounts.count > 1;
    self.tg_amountHintCaption.text = multiAmount ? @"Please choose the loan amount yourself" : @"Loan amount";
    self.tg_amountHintCaption.textColor = [UIColor tg_toneFromHex:kTgApplyHintToneHex];
    self.tg_amountArrowGlyph.hidden = !multiAmount;
    self.tg_amountTapLatch.hidden = !multiAmount;
    self.tg_amountTapLatch.userInteractionEnabled = multiAmount;
}

- (void)tg_refreshDetailRows {
    for (UIView *v in self.tg_detailStack.arrangedSubviews) {
        [self.tg_detailStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }

    TgTermDetail *term = [self tg_activeTerm];
    if (!term) return;

    [self tg_addDetailRowTitle:@"Amount received" value:[self tg_plainNumber:term.minority] showTip:YES tip:kTgApplyTipAmountReceived];
    [self tg_addDetailRowTitle:@"Interest" value:[self tg_plainNumber:term.typist] showTip:YES tip:kTgApplyTipInterest];
    [self tg_addDetailRowTitle:@"Service fee" value:[self tg_plainNumber:term.pit] showTip:YES tip:kTgApplyTipServiceFee];
    [self tg_addDetailRowTitle:@"GST" value:[self tg_plainNumber:term.feather] showTip:NO tip:nil];
    [self tg_addDetailRowTitle:@"Date of application" value:[self tg_formatDate:term.postage] showTip:NO tip:nil];
    [self tg_addDetailRowTitle:@"Due date" value:[self tg_formatDate:term.unity] showTip:NO tip:nil];

    if (self.tg_hasEmiOptions && term.EMIs > 0) {
        if (term.EMIRepayDate.length > 0) {
            [self tg_addDetailRowTitle:@"1st EMI Date" value:[self tg_formatDate:term.EMIRepayDate] showTip:NO tip:nil];
        }
        if (term.upright.length > 0) {
            [self tg_addDetailRowTitle:@"EMI Amount" value:[self tg_plainNumber:term.upright] showTip:NO tip:nil];
        }
    }
}

- (void)tg_addDetailRowTitle:(NSString *)title
                       value:(NSString *)value
                     showTip:(BOOL)showTip
                         tip:(NSString *)tip {
    UIView *row = [[UIView alloc] init];
    [row mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(36);
    }];

    UILabel *titleLab = [[UILabel alloc] init];
    titleLab.text = title;
    titleLab.font = [UIFont tg_meshGlyphWithSize:13 weight:UIFontWeightRegular];
    titleLab.textColor = [UIColor tg_toneFromHex:@"#686868"];
    [row addSubview:titleLab];

    UIView *titleAnchor = titleLab;
    if (showTip && tip.length > 0) {
        UIButton *tipBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [tipBtn setImage:[UIImage imageNamed:kTgApplyTipIconAsset] forState:UIControlStateNormal];
        objc_setAssociatedObject(tipBtn, kTgApplyTipTextKey, tip, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [tipBtn addTarget:self action:@selector(tg_onTipTapped:) forControlEvents:UIControlEventTouchUpInside];
        [row addSubview:tipBtn];
        [tipBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(row);
            make.left.equalTo(titleLab.mas_right).offset(4);
            make.width.height.mas_equalTo(16);
        }];
        titleAnchor = tipBtn;
    }

    UILabel *valueLab = [[UILabel alloc] init];
    valueLab.text = value;
    valueLab.font = [UIFont tg_meshGlyphWithSize:13 weight:UIFontWeightBold];
    valueLab.textColor = [UIColor tg_toneFromHex:kTgApplyValueToneHex];
    valueLab.textAlignment = NSTextAlignmentRight;
    [row addSubview:valueLab];

    [titleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(row);
        make.left.equalTo(row);
    }];
    [valueLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(row);
        make.right.equalTo(row);
        make.left.greaterThanOrEqualTo(titleAnchor.mas_right).offset(8);
    }];

    [self.tg_detailStack addArrangedSubview:row];
}

- (void)tg_refreshTermRow {
    NSArray<TgTermDetail *> *terms = [self tg_sortedTermsForActiveAmount];
    TgTermDetail *term = [self tg_activeTerm];
    BOOL multiTerm = terms.count > 1;
    BOOL showTermRow = terms.count > 0;

    self.tg_termTitleCaption.hidden = !showTermRow;
    self.tg_termValueCaption.hidden = !showTermRow;
    self.tg_termArrowGlyph.hidden = YES;
    self.tg_termTapLatch.hidden = YES;
    self.tg_termTapLatch.userInteractionEnabled = NO;
    self.tg_selDivider.hidden = !showTermRow;

    if (!showTermRow) {
        [self.tg_termTitleCaption mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(0);
        }];
        return;
    }

    [self.tg_termTitleCaption mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_selCard).offset(16);
        make.top.equalTo(self.tg_selCard).offset(14);
    }];

    if (self.tg_hasEmiOptions) {
        self.tg_termTitleCaption.text = @"Select EMIs";
        self.tg_termValueCaption.text = [self tg_formatEmiLabel:term.EMIs];
        BOOL multiEmi = terms.count > 1;
        self.tg_termArrowGlyph.hidden = !multiEmi;
        self.tg_termTapLatch.hidden = !multiEmi;
        self.tg_termTapLatch.userInteractionEnabled = multiEmi;
    } else if (multiTerm) {
        self.tg_termTitleCaption.text = @"Choose your loan tenure";
        self.tg_termValueCaption.text = [self tg_formatDaysFromTerm:term];
        self.tg_termArrowGlyph.hidden = NO;
        self.tg_termTapLatch.hidden = NO;
        self.tg_termTapLatch.userInteractionEnabled = YES;
    } else {
        self.tg_termTitleCaption.text = @"Loan duration";
        self.tg_termValueCaption.text = [self tg_formatDaysFromTerm:term];
        self.tg_termArrowGlyph.hidden = YES;
        self.tg_termTapLatch.hidden = YES;
        self.tg_termTapLatch.userInteractionEnabled = NO;
    }
}

- (void)tg_refreshBankRow {
    TgCardInfo *card = self.tg_termData.superior.firstObject;
    NSString *acct = [card.measure stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    self.tg_bankValueCaption.text = acct.length > 0 ? acct : @"-";
}

#pragma mark - Format

- (NSString *)tg_plainNumber:(NSString *)raw {
    NSString *trim = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (trim.length == 0) return @"-";
    return [NSString tg_weaveIndianDigits:trim];
}

- (NSString *)tg_formatDate:(NSString *)raw {
    NSString *trim = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (trim.length == 0) return @"-";
    NSDateFormatter *inFmt = [[NSDateFormatter alloc] init];
    inFmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    inFmt.dateFormat = @"yyyy-MM-dd";
    NSDate *date = [inFmt dateFromString:trim];
    if (!date) return trim;
    NSDateFormatter *outFmt = [[NSDateFormatter alloc] init];
    outFmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    outFmt.dateFormat = @"MMM dd, yyyy";
    return [outFmt stringFromDate:date] ?: trim;
}

- (NSString *)tg_formatDaysFromTerm:(TgTermDetail *)term {
    if (!term) return @"-";
    NSInteger days = term.ill > 0 ? term.ill : term.culture;
    if (days <= 0) return @"-";
    return [NSString stringWithFormat:@"%ld Days", (long)days];
}

- (NSString *)tg_formatEmiLabel:(NSInteger)emiCount {
    if (emiCount <= 0) return @"-";
    if (emiCount == 1) return @"1 EMI";
    return [NSString stringWithFormat:@"%ld EMIs", (long)emiCount];
}

#pragma mark - Agreement

- (void)tg_renderAgreementText {
    NSDictionary *normal = @{
        NSFontAttributeName: [UIFont tg_meshGlyphWithSize:12 weight:UIFontWeightRegular],
        NSForegroundColorAttributeName: [UIColor tg_toneFromHex:@"#686868"]
    };
    NSDictionary *link = @{
        NSFontAttributeName: [UIFont tg_meshGlyphWithSize:12 weight:UIFontWeightMedium],
        NSForegroundColorAttributeName: [UIColor tg_toneFromHex:kTgApplyValueToneHex],
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
    };
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] init];
    [attr appendAttributedString:[[NSAttributedString alloc] initWithString:@"I have reviewed and agreed to the " attributes:normal]];
    [attr appendAttributedString:[[NSAttributedString alloc] initWithString:@"Loan terms and conditions" attributes:link]];
    self.tg_agreeCaption.attributedText = attr;
}

- (void)tg_onAgreeToggled {
    self.tg_isAgreed = !self.tg_isAgreed;
    NSString *icon = self.tg_isAgreed ? kTgApplyTermsOnAsset : kTgApplyTermsOffAsset;
    [self.tg_agreeLatch setImage:[UIImage imageNamed:icon] forState:UIControlStateNormal];
}

- (void)tg_onTermsLinkTapped {
    NSString *href = [TgPureLinks loanTerms];
    NSURL *url = [TgPaneWebController tg_normalizedURLFromString:href];
    if (href.length == 0 || !url) {
        [[TgPulseOverlay shared] whisperLine:@"The agreement link is not available"];
        return;
    }
    [TgTraceRelay emitSignal:TgTraceSignalTermsOpen];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    TgPaneWebController *pane = [[TgPaneWebController alloc] initWithPageURL:url navTitle:@"Loan Terms"];
    pane.tg_showsBackButton = YES;
    pane.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:pane animated:YES];
}

#pragma mark - Selection

- (void)tg_onAmountRowTapped {
    if (self.tg_sortedAmounts.count <= 1) return;
    NSMutableArray<NSString *> *options = [NSMutableArray array];
    for (TgAmountDetail *a in self.tg_sortedAmounts) {
        NSString *digits = [a.inch stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"0";
        [options addObject:[NSString stringWithFormat:@"₹%@", [NSString tg_weaveIndianDigits:digits]]];
    }
    __weak typeof(self) weakSelf = self;
    [[TgShardFacade shared] showOptionPickerWithTitle:@"Select loan amount"
                                              options:options
                                        selectedIndex:self.tg_pickedAmountIdx
                                         confirmTitle:@"Confirm"
                                            onConfirm:^(NSInteger index, NSString *value) {
        (void)value;
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.tg_pickedAmountIdx = index;
        self.tg_pickedTermIdx = 0;
        self.tg_pickedEmiIdx = 0;
        [self tg_detectEmiAvailability];
        [self tg_refreshEntireDisplay];
    }];
}

- (void)tg_onTermRowTapped {
    NSArray<TgTermDetail *> *terms = [self tg_sortedTermsForActiveAmount];
    if (terms.count <= 1) return;

    NSMutableArray<NSString *> *options = [NSMutableArray array];
    if (self.tg_hasEmiOptions) {
        NSMutableArray<NSNumber *> *termIndices = [NSMutableArray array];
        NSInteger selectedPickerIdx = 0;
        for (NSInteger i = 0; i < (NSInteger)terms.count; i++) {
            TgTermDetail *t = terms[i];
            if (t.EMIs > 0) {
                if (i == self.tg_pickedEmiIdx) {
                    selectedPickerIdx = (NSInteger)options.count;
                }
                [options addObject:[self tg_formatEmiLabel:t.EMIs]];
                [termIndices addObject:@(i)];
            }
        }
        __weak typeof(self) weakSelf = self;
        [[TgShardFacade shared] showOptionPickerWithTitle:@"Select EMIs"
                                                  options:options
                                            selectedIndex:selectedPickerIdx
                                             confirmTitle:@"Confirm"
                                                onConfirm:^(NSInteger index, NSString *value) {
            (void)value;
            __strong typeof(weakSelf) self = weakSelf;
            if (!self || index < 0 || index >= (NSInteger)termIndices.count) return;
            self.tg_pickedEmiIdx = termIndices[index].integerValue;
            [self tg_refreshDetailRows];
            [self tg_refreshTermRow];
        }];
        return;
    }

    for (TgTermDetail *t in terms) {
        [options addObject:[self tg_formatDaysFromTerm:t]];
    }
    __weak typeof(self) weakSelf = self;
    [[TgShardFacade shared] showOptionPickerWithTitle:@"Choose your loan tenure"
                                              options:options
                                        selectedIndex:self.tg_pickedTermIdx
                                         confirmTitle:@"Confirm"
                                            onConfirm:^(NSInteger index, NSString *value) {
        (void)value;
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.tg_pickedTermIdx = index;
        [self tg_refreshDetailRows];
        [self tg_refreshTermRow];
    }];
}

#pragma mark - Apply / submit (38)

- (void)tg_returnToLoanHomeAfterOrderInterrupt {
    UITabBarController *dock = self.tabBarController;
    UINavigationController *nav = self.navigationController;
    if (dock) {
        dock.selectedIndex = TgDockTabIndexLoan;
        UINavigationController *loanNav = (UINavigationController *)dock.viewControllers[TgDockTabIndexLoan];
        if ([loanNav isKindOfClass:[UINavigationController class]]) {
            [loanNav popToRootViewControllerAnimated:NO];
        }
    }
    [nav popToRootViewControllerAnimated:YES];
}

- (void)tg_onApplyTapped {
    if (self.tg_loading || [TgOrderForgeRelay tg_isRunning]) return;
    [TgTraceRelay emitSignal:TgTraceSignalOrderApplyTap];
    if (!self.tg_isAgreed) {
        [[TgPulseOverlay shared] whisperLine:@"Please review and agree to the loan terms and conditions" duration:2.0];
        return;
    }

    TgAmountDetail *amount = [self tg_activeAmount];
    TgTermDetail *term = [self tg_activeTerm];
    if (!amount || !term) {
        [[TgPulseOverlay shared] whisperLine:@"No loan options are available" duration:2.0];
        return;
    }

    NSString *productId = [self.tg_productId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    NSString *loanAmount = [amount.inch stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    NSInteger showTermVal = term.ill > 0 ? term.ill : term.culture;
    if (productId.length == 0 || loanAmount.length == 0 || showTermVal <= 0) {
        [[TgPulseOverlay shared] whisperLine:@"Invalid loan data" duration:2.0];
        return;
    }

    TgOrderForgeParams *params = [[TgOrderForgeParams alloc] init];
    params.productId = productId;
    params.loanAmount = loanAmount;
    params.showTerm = [NSString stringWithFormat:@"%ld", (long)showTermVal];

    __weak typeof(self) weakSelf = self;
    void (^launch)(void) = ^{
        [TgOrderForgeRelay tg_launchFullOrderWithParams:params
                                                 hostVC:weakSelf
                                                 origin:TgOrderForgeOriginApplyPage
                                   allowSecondaryPrompt:YES
                                                success:^(NSString *orderId) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            TgOrderSuccessVaultController *successVC = [[TgOrderSuccessVaultController alloc] init];
            successVC.tg_orderId = orderId;
            successVC.tg_productId = productId;
            successVC.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:successVC animated:YES];
        } failure:^(NSString *message) {
            (void)message;
        } cancelled:^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            [self tg_returnToLoanHomeAfterOrderInterrupt];
        }];
    };

    if ([[TgPolicyVault shared] currentManifest]) {
        launch();
        return;
    }
    [[TgPulseOverlay shared] veilSpin];
    [[TgPolicyVault shared] pullManifestSuccess:^(TgSystemConfigModel *cfg) {
        (void)cfg;
        [[TgPulseOverlay shared] veilDismiss];
        launch();
    } failure:^{
        [[TgPulseOverlay shared] veilDismiss];
        launch();
    }];
}

#pragma mark - Back intercept (§5.4.4)

- (void)tg_installBackIntercept {
    __weak typeof(self) weakSelf = self;
    self.tg_backInterceptBlock = ^BOOL {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return YES;
        [self tg_handleBackIntercept];
        return NO;
    };
}

- (void)tg_handleBackIntercept {
    [self tg_showBackRetainDialog];
}

- (void)tg_showBackRetainDialog {
    __weak typeof(self) weakSelf = self;
    [[TgShardFacade shared] showTextPanelWithContent:kTgApplyBackRetainMessage
                                        primaryTitle:@"Confirm"
                                      secondaryTitle:@"Cancel"
                                        primaryAction:^{
        __strong typeof(weakSelf) self = weakSelf;
        [[TgShardFacade shared] dismissTopPanel];
        if (self.navigationController) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
                                      secondaryAction:^{
        [[TgShardFacade shared] dismissTopPanel];
    }];
}

#pragma mark - Tip popover

- (void)tg_onTipTapped:(UIButton *)sender {
    NSString *tip = objc_getAssociatedObject(sender, kTgApplyTipTextKey);
    if (tip.length == 0) return;

    UIFont *tipFont = [UIFont tg_meshGlyphWithSize:11 weight:UIFontWeightRegular];
    CGFloat maxW = CGRectGetWidth(self.view.bounds) * 0.72;
    CGFloat horzPad = 14;
    CGFloat vertPad = 16;
    CGRect textRect = [tip boundingRectWithSize:CGSizeMake(maxW - horzPad * 2, CGFLOAT_MAX)
                                        options:NSStringDrawingUsesLineFragmentOrigin
                                     attributes:@{NSFontAttributeName: tipFont}
                                        context:nil];
    CGFloat textH = ceil(CGRectGetHeight(textRect));
    CGFloat popH = textH + vertPad * 2;

    UIViewController *tipVC = [[UIViewController alloc] init];
    UIColor *bg = [[UIColor tg_toneFromHex:@"#242424"] colorWithAlphaComponent:0.69];
    tipVC.view.backgroundColor = bg;
    tipVC.preferredContentSize = CGSizeMake(maxW, popH);
    tipVC.modalPresentationStyle = UIModalPresentationPopover;

    UILabel *lab = [[UILabel alloc] init];
    lab.text = tip;
    lab.font = tipFont;
    lab.textColor = UIColor.whiteColor;
    lab.numberOfLines = 0;
    lab.textAlignment = NSTextAlignmentLeft;
    [tipVC.view addSubview:lab];
    [lab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(tipVC.view);
        make.left.equalTo(tipVC.view).offset(horzPad);
        make.right.equalTo(tipVC.view).offset(-horzPad);
    }];

    UIPopoverPresentationController *pop = tipVC.popoverPresentationController;
    pop.sourceView = sender;
    pop.sourceRect = sender.bounds;
    pop.permittedArrowDirections = UIPopoverArrowDirectionUp;
    pop.backgroundColor = bg;
    pop.delegate = self;
    [self presentViewController:tipVC animated:YES completion:nil];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    (void)controller;
    return UIModalPresentationNone;
}

@end
