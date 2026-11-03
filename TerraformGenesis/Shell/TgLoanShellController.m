//

//

#import "TgLoanShellController.h"
#import "TgAutoOrderRelay.h"
#import "TgEnvelopeBase.h"
#import "TgDockBarRelay.h"
#import "TgKycPathRelay.h"
#import "TgOrderShelfController.h"
#import "TgOrderDetailVaultController.h"
#import "TgOrderApplyVaultController.h"
#import "TgOrderWithdrawVaultController.h"
#import "TgScoreDetailVaultController.h"
#import "TgRejectWebController.h"
#import "TgDcMatchVaultController.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"
#import "TgPolicyVault.h"
#import "TgReviewGuideRelay.h"
#import "TgPulseOverlay.h"
#import "TgShardFacade.h"
#import "TgTraceRelay.h"
#import "TgVersionPayload.h"
#import "TgWireConduit.h"
#import "NSString+TgGlyph.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <AdjustSdk/AdjustSdk.h>
#import <Masonry/Masonry.h>

static CGFloat const kTgLoanHorzInset = 16.0;
static CGFloat const kTgLoanBgDesignWidth = 375.0;
static CGFloat const kTgLoanBgDesignHeight = 496.0;
static CGFloat const kTgLoanScoreSide = 230.0;
static CGFloat const kTgLoanBannerDesignWidth = 330.0;
static CGFloat const kTgLoanBannerDesignHeight = 69.0;
static CGFloat const kTgLoanScoreTopBelowSafe = 12.0;
static CGFloat const kTgLoanScoreContentSpacing = 15.0;
static CGFloat const kTgLoanScoreTitleFontSize = 16.0;
static CGFloat const kTgLoanCardBelowScore = -8.0;
static CGFloat const kTgLoanPromptBelowCard = 16.0;
static CGFloat const kTgLoanBannerBelowPrompt = 16.0;
static CGFloat const kTgLoanMaskBelowBanner = 35.0;
static CGFloat const kTgLoanApplyHeight = 56.0;
static CGFloat const kTgLoanApplyRadius = 28.0;
static CGFloat const kTgLoanScrollBottomInset = 24.0;
static CGFloat const kTgLoanCardRadius = 16.0;
static CGFloat const kTgLoanCardInnerInset = 14.0;
static CGFloat const kTgLoanCardStarW = 110.0;
static CGFloat const kTgLoanCardStarH = 84.0;
static NSString * const kTgLoanBgAsset = @"bg";
static NSString * const kTgLoanScoreAsset = @"use_Score";
static NSString * const kTgLoanBannerAsset = @"use";
static NSString * const kTgLoanScoreArrowAsset = @"use_next_loan_bai";
static NSString * const kTgLoanCardStarAsset = @"use_loan_star";
static NSString * const kTgLoanFooterMaskAsset = @"useMaskgroup";
static NSString * const kTgLoanHardRateTag = @"0.05% / Day";
static NSString * const kTgLoanHardTermTag = @"120 Day";
static NSString * const kTgLoanBusyHint = @"The system is occupied. Please retry after 2 minutes.";

static void TgLoanWhisperBusyHintIfNeeded(void) {
    if ([[TgWireConduit shared] tg_shouldSuppressBusyToast]) return;
    [[TgPulseOverlay shared] whisperLine:kTgLoanBusyHint];
}
static NSString * const kTgLoanTermFailHint = @"Unable to load product details";
static NSString * const kTgLoanTermBlockedMessage =
    @"You already applied for this product, and that application is still being processed. "
    @"You cannot apply again right now. You may view the order details or return to pick another product.";
static NSString * const kTgLoanTermBlockedFromListOrderId = @"1";
static NSString * const kTgLoanWithdrawTitle = @"Pending";
static NSString * const kTgLoanWithdrawBody =
    @"You have a loan order pending confirmation. After entering the page to confirm, the funds will be transferred to your bank account immediately.";
static NSString * const kTgLoanWithdrawMissingIdsHint = @"Order ID or Product ID is required";

static __weak TgLoanShellController *gTgLoanShellWeak = nil;

@interface TgLoanShellController ()

@property (nonatomic, strong) UIScrollView *tg_scrollPane;
@property (nonatomic, strong) UIView *tg_scrollBody;
@property (nonatomic, strong) UIImageView *tg_bgGlyph;
@property (nonatomic, strong) MASConstraint *tg_bgHeightConstraint;
@property (nonatomic, strong) UIImageView *tg_scoreGlyph;
@property (nonatomic, strong) UILabel *tg_scoreTitleCaption;
@property (nonatomic, strong) UILabel *tg_scoreValueCaption;
@property (nonatomic, strong) UILabel *tg_scoreGradeCaption;
@property (nonatomic, strong) UIImageView *tg_scoreArrowGlyph;
@property (nonatomic, strong) UIView *tg_loanCardVeil;
@property (nonatomic, strong) UILabel *tg_loanTitleCaption;
@property (nonatomic, strong) UILabel *tg_loanAmountCaption;
@property (nonatomic, strong) UIImageView *tg_loanStarGlyph;
@property (nonatomic, strong) UILabel *tg_loanRateTagCaption;
@property (nonatomic, strong) UILabel *tg_loanTermTagCaption;
@property (nonatomic, strong) UIButton *tg_applyLatch;
@property (nonatomic, strong) UIView *tg_promptWrap;
@property (nonatomic, strong) UILabel *tg_promptCaption;
@property (nonatomic, strong) UIImageView *tg_bannerGlyph;
@property (nonatomic, strong) UIImageView *tg_footerMaskGlyph;
@property (nonatomic, strong, nullable) TgHomeData *tg_homeData;
@property (nonatomic, copy) NSArray<TgProductInfo *> *tg_productList;
@property (nonatomic, assign) NSInteger tg_cachedUserStatus;
@property (nonatomic, assign, readwrite) BOOL tg_pipelineDone;
@property (nonatomic, assign) BOOL tg_loading;
@property (nonatomic, strong, nullable) TgVersionData *tg_versionData;
@property (nonatomic, assign) BOOL tg_hasShownUpdateDialog;
@property (nonatomic, assign) BOOL tg_adidSyncStarted;

@end

@implementation TgLoanShellController

+ (void)tg_requestScrollToFirstProduct {
    // Loan-supermarket home no longer lists products; keep API for callers.
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.tg_backdropStyle = TgHullBackdropStylePlain;
        self.tg_showsBackButton = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    gTgLoanShellWeak = self;
    self.view.backgroundColor = [UIColor tg_toneFromHex:@"#F1F1F1"];
    [self tg_buildLayout];
    [self tg_syncAdid];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    if (self.tg_pipelineDone) {
        [[TgPolicyVault shared] refreshManifestOnHomeEntrySuccess:nil failure:nil];
        [self tg_reloadSupHomeOnly];
    } else {
        [self tg_runFullPipeline];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat bgH = CGRectGetWidth(self.view.bounds) * (kTgLoanBgDesignHeight / kTgLoanBgDesignWidth);
    [self.tg_bgHeightConstraint setOffset:bgH];
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    CGFloat safeTop = self.view.safeAreaInsets.top;
    [self.tg_scoreGlyph mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_bgGlyph).offset(safeTop + kTgLoanScoreTopBelowSafe);
    }];
}

#pragma mark - Layout

- (UILabel *)tg_scoreLabelWithSize:(CGFloat)size weight:(UIFontWeight)weight color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont tg_meshGlyphWithSize:size weight:weight];
    label.textColor = color;
    label.textAlignment = NSTextAlignmentCenter;
    return label;
}

- (UILabel *)tg_tagChipWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = [NSString stringWithFormat:@"  %@  ", text ?: @""];
    label.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightMedium];
    label.textColor = UIColor.blackColor;
    label.backgroundColor = [UIColor tg_toneFromHex:@"#F1F1F1"];
    label.textAlignment = NSTextAlignmentCenter;
    label.layer.cornerRadius = 12.0;
    label.clipsToBounds = YES;
    return label;
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

    self.tg_bgGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgLoanBgAsset]];
    self.tg_bgGlyph.contentMode = UIViewContentModeScaleAspectFill;
    self.tg_bgGlyph.clipsToBounds = YES;
    [self.tg_scrollBody addSubview:self.tg_bgGlyph];

    self.tg_scoreGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgLoanScoreAsset]];
    self.tg_scoreGlyph.contentMode = UIViewContentModeScaleAspectFit;
    self.tg_scoreGlyph.userInteractionEnabled = YES;
    UITapGestureRecognizer *scoreTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tg_onScoreTapped)];
    [self.tg_scoreGlyph addGestureRecognizer:scoreTap];
    [self.tg_scrollBody addSubview:self.tg_scoreGlyph];

    self.tg_scoreTitleCaption = [self tg_scoreLabelWithSize:kTgLoanScoreTitleFontSize weight:UIFontWeightBold color:UIColor.whiteColor];
    self.tg_scoreTitleCaption.text = @"Credit Score";

    self.tg_scoreValueCaption = [self tg_scoreLabelWithSize:34 weight:UIFontWeightBold color:UIColor.whiteColor];
    self.tg_scoreValueCaption.text = @"816 /";

    self.tg_scoreGradeCaption = [self tg_scoreLabelWithSize:16 weight:UIFontWeightMedium color:[UIColor tg_toneFromHex:@"#F7FF00"]];
    self.tg_scoreGradeCaption.text = @"Excellent";

    UIImage *arrowImg = [UIImage imageNamed:@"use_next_loan0"] ?: [UIImage imageNamed:kTgLoanScoreArrowAsset];
    self.tg_scoreArrowGlyph = [[UIImageView alloc] initWithImage:arrowImg];
    self.tg_scoreArrowGlyph.contentMode = UIViewContentModeScaleAspectFit;

    UIStackView *scoreRow = [[UIStackView alloc] initWithArrangedSubviews:@[self.tg_scoreValueCaption, self.tg_scoreGradeCaption]];
    scoreRow.axis = UILayoutConstraintAxisHorizontal;
    scoreRow.alignment = UIStackViewAlignmentLastBaseline;
    scoreRow.spacing = 4;
    scoreRow.userInteractionEnabled = NO;

    UIStackView *scoreContent = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.tg_scoreTitleCaption, scoreRow, self.tg_scoreArrowGlyph
    ]];
    scoreContent.axis = UILayoutConstraintAxisVertical;
    scoreContent.alignment = UIStackViewAlignmentCenter;
    scoreContent.spacing = kTgLoanScoreContentSpacing;
    scoreContent.userInteractionEnabled = NO;

    [self.tg_scoreGlyph addSubview:scoreContent];
    [self.tg_scoreArrowGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(20);
    }];
    [scoreContent mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.tg_scoreGlyph);
        make.left.greaterThanOrEqualTo(self.tg_scoreGlyph).offset(8);
        make.right.lessThanOrEqualTo(self.tg_scoreGlyph).offset(-8);
    }];

    // Single loan card (no top wave)
    self.tg_loanCardVeil = [[UIView alloc] init];
    self.tg_loanCardVeil.backgroundColor = UIColor.whiteColor;
    self.tg_loanCardVeil.layer.cornerRadius = kTgLoanCardRadius;
    self.tg_loanCardVeil.clipsToBounds = YES;
    UITapGestureRecognizer *cardTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tg_onApplyTapped)];
    [self.tg_loanCardVeil addGestureRecognizer:cardTap];
    [self.tg_scrollBody addSubview:self.tg_loanCardVeil];

    self.tg_loanTitleCaption = [[UILabel alloc] init];
    self.tg_loanTitleCaption.text = @"Maximum Loan Amount";
    self.tg_loanTitleCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    self.tg_loanTitleCaption.textColor = [UIColor tg_toneFromHex:@"#212121"];
    [self.tg_loanCardVeil addSubview:self.tg_loanTitleCaption];

    self.tg_loanAmountCaption = [[UILabel alloc] init];
    self.tg_loanAmountCaption.text = @"--";
    self.tg_loanAmountCaption.font = [UIFont tg_meshGlyphWithSize:32 weight:UIFontWeightBold];
    self.tg_loanAmountCaption.textColor = [UIColor tg_toneFromHex:@"#C51B12"];
    self.tg_loanAmountCaption.adjustsFontSizeToFitWidth = YES;
    self.tg_loanAmountCaption.minimumScaleFactor = 0.5;
    [self.tg_loanCardVeil addSubview:self.tg_loanAmountCaption];

    self.tg_loanStarGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgLoanCardStarAsset]];
    self.tg_loanStarGlyph.contentMode = UIViewContentModeScaleAspectFit;
    self.tg_loanStarGlyph.userInteractionEnabled = NO;
    [self.tg_loanCardVeil addSubview:self.tg_loanStarGlyph];

    self.tg_loanRateTagCaption = [self tg_tagChipWithText:kTgLoanHardRateTag];
    self.tg_loanTermTagCaption = [self tg_tagChipWithText:kTgLoanHardTermTag];
    [self.tg_loanCardVeil addSubview:self.tg_loanRateTagCaption];
    [self.tg_loanCardVeil addSubview:self.tg_loanTermTagCaption];

    self.tg_applyLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    self.tg_applyLatch.backgroundColor = [UIColor tg_toneFromHex:@"#182040"];
    self.tg_applyLatch.layer.cornerRadius = kTgLoanApplyRadius;
    self.tg_applyLatch.clipsToBounds = YES;
    [self.tg_applyLatch setTitle:@"Apply now" forState:UIControlStateNormal];
    [self.tg_applyLatch setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.tg_applyLatch.titleLabel.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    [self.tg_applyLatch addTarget:self action:@selector(tg_onApplyTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.tg_loanCardVeil addSubview:self.tg_applyLatch];

    // Prompt below card
    self.tg_promptWrap = [[UIView alloc] init];
    self.tg_promptWrap.hidden = YES;
    UITapGestureRecognizer *promptTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tg_onPromptTapped)];
    [self.tg_promptWrap addGestureRecognizer:promptTap];
    [self.tg_scrollBody addSubview:self.tg_promptWrap];

    self.tg_promptCaption = [[UILabel alloc] init];
    self.tg_promptCaption.textColor = [UIColor tg_toneFromHex:@"#182040"];
    self.tg_promptCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    self.tg_promptCaption.textAlignment = NSTextAlignmentLeft;
    self.tg_promptCaption.numberOfLines = 0;
    [self.tg_promptWrap addSubview:self.tg_promptCaption];

    // Process banner
    self.tg_bannerGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgLoanBannerAsset]];
    self.tg_bannerGlyph.contentMode = UIViewContentModeScaleAspectFit;
    self.tg_bannerGlyph.clipsToBounds = NO;
    [self.tg_scrollBody addSubview:self.tg_bannerGlyph];

    // useMaskgroup follows banner in scroll content (not fixed)
    self.tg_footerMaskGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgLoanFooterMaskAsset]];
    self.tg_footerMaskGlyph.contentMode = UIViewContentModeScaleAspectFit;
    self.tg_footerMaskGlyph.clipsToBounds = NO;
    self.tg_footerMaskGlyph.userInteractionEnabled = NO;
    [self.tg_scrollBody addSubview:self.tg_footerMaskGlyph];

    [self.tg_scrollPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self.tg_scrollBody mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.width.equalTo(self.tg_scrollPane);
    }];
    [self.tg_bgGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.tg_scrollBody);
        self.tg_bgHeightConstraint = make.height.mas_equalTo(kTgLoanBgDesignHeight);
    }];
    [self.tg_scoreGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.tg_bgGlyph);
        make.top.equalTo(self.tg_bgGlyph).offset(kTgLoanScoreTopBelowSafe);
        make.width.height.mas_equalTo(kTgLoanScoreSide);
    }];

    [self.tg_loanCardVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_scrollBody).offset(kTgLoanHorzInset);
        make.right.equalTo(self.tg_scrollBody).offset(-kTgLoanHorzInset);
        make.top.equalTo(self.tg_scoreGlyph.mas_bottom).offset(kTgLoanCardBelowScore);
    }];

    [self.tg_loanTitleCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_loanCardVeil).offset(kTgLoanCardInnerInset);
        make.right.lessThanOrEqualTo(self.tg_loanCardVeil).offset(-kTgLoanCardInnerInset);
        make.top.equalTo(self.tg_loanCardVeil).offset(kTgLoanCardInnerInset);
    }];
    [self.tg_loanStarGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.tg_loanCardVeil).offset(-kTgLoanCardInnerInset);
        make.top.equalTo(self.tg_loanTitleCaption.mas_bottom).offset(-4);
        make.width.mas_equalTo(kTgLoanCardStarW);
        make.height.mas_equalTo(kTgLoanCardStarH);
    }];
    [self.tg_loanAmountCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_loanTitleCaption);
        make.right.equalTo(self.tg_loanStarGlyph.mas_left).offset(-4);
        make.centerY.equalTo(self.tg_loanStarGlyph);
    }];
    [self.tg_loanRateTagCaption setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.tg_loanTermTagCaption setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.tg_loanRateTagCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_loanTitleCaption);
        make.top.equalTo(self.tg_loanStarGlyph.mas_bottom).offset(4);
        make.height.mas_equalTo(28);
        make.width.greaterThanOrEqualTo(@98);
    }];
    [self.tg_loanTermTagCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_loanRateTagCaption.mas_right).offset(10);
        make.centerY.equalTo(self.tg_loanRateTagCaption);
        make.height.equalTo(self.tg_loanRateTagCaption);
        make.width.greaterThanOrEqualTo(@72);
    }];
    [self.tg_applyLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.tg_loanCardVeil);
        make.width.equalTo(self.tg_loanCardVeil).multipliedBy(0.85);
        make.top.equalTo(self.tg_loanRateTagCaption.mas_bottom).offset(18);
        make.height.mas_equalTo(kTgLoanApplyHeight);
        make.bottom.equalTo(self.tg_loanCardVeil).offset(-kTgLoanCardInnerInset);
    }];

    [self.tg_promptWrap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_scrollBody).offset(kTgLoanHorzInset);
        make.right.equalTo(self.tg_scrollBody).offset(-kTgLoanHorzInset);
        make.top.equalTo(self.tg_loanCardVeil.mas_bottom).offset(kTgLoanPromptBelowCard);
    }];
    [self.tg_promptCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_promptWrap);
    }];
    [self.tg_bannerGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_scrollBody).offset(kTgLoanHorzInset);
        make.right.equalTo(self.tg_scrollBody).offset(-kTgLoanHorzInset);
        make.top.equalTo(self.tg_promptWrap.mas_bottom).offset(kTgLoanBannerBelowPrompt);
        make.height.equalTo(self.tg_bannerGlyph.mas_width).multipliedBy(kTgLoanBannerDesignHeight / kTgLoanBannerDesignWidth);
    }];

    UIImage *footerImg = [UIImage imageNamed:kTgLoanFooterMaskAsset];
    CGFloat footerRatio = (footerImg.size.width > 0) ? (footerImg.size.height / footerImg.size.width) : 0.15;
    [self.tg_footerMaskGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_scrollBody).offset(kTgLoanHorzInset);
        make.right.equalTo(self.tg_scrollBody).offset(-kTgLoanHorzInset);
        make.top.equalTo(self.tg_bannerGlyph.mas_bottom).offset(kTgLoanMaskBelowBanner);
        make.height.equalTo(self.tg_footerMaskGlyph.mas_width).multipliedBy(footerRatio);
        make.bottom.equalTo(self.tg_scrollBody).offset(-kTgLoanScrollBottomInset);
    }];
}

#pragma mark - Prompt

+ (BOOL)tg_shouldAppendPromptChevronForStatus:(NSInteger)userStatus {
    switch (userStatus) {
        case 10:
        case 30:
        case 32:
        case 41:
        case 80:
        case 81:
            return YES;
        case 51:
            // QA: 51 prompt jump only when rejectH5 is configured.
            return [TgRejectWebController tg_cachedRejectH5URLString].length > 0;
        default:
            return NO;
    }
}

- (nullable NSString *)tg_displayPromptTextFromCopy:(nullable NSString *)copy userStatus:(NSInteger)userStatus {
    NSString *trimmed = [copy stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (trimmed.length == 0) return nil;
    if ([[self class] tg_shouldAppendPromptChevronForStatus:userStatus]) {
        if (![trimmed containsString:@">>>"]) {
            return [trimmed stringByAppendingString:@" >>>"];
        }
    }
    return trimmed;
}

- (void)tg_refreshPromptUI {
    NSInteger status = self.tg_homeData.telescope;
    NSString *text = [self tg_displayPromptTextFromCopy:self.tg_homeData.fold
                                             userStatus:status];
    BOOL show = text.length > 0;
    BOOL clickable = show && [[self class] tg_shouldAppendPromptChevronForStatus:status];
    self.tg_promptWrap.hidden = !show;
    self.tg_promptWrap.userInteractionEnabled = clickable;
    self.tg_promptCaption.text = text;

    CGFloat promptGap = show ? kTgLoanPromptBelowCard : 8.0;
    [self.tg_promptWrap mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_scrollBody).offset(kTgLoanHorzInset);
        make.right.equalTo(self.tg_scrollBody).offset(-kTgLoanHorzInset);
        make.top.equalTo(self.tg_loanCardVeil.mas_bottom).offset(promptGap);
        if (!show) {
            make.height.mas_equalTo(0);
        }
    }];
}

- (void)tg_refreshUnverifiedUI {
    [self tg_refreshPromptUI];
    [self tg_refreshLoanCardAmount];
    [self tg_refreshApplyButtonTitle];
}

- (void)tg_refreshCompletedUI {
    [self tg_refreshPromptUI];
    [self tg_refreshLoanCardAmount];
    [self tg_refreshApplyButtonTitle];
}

- (NSString *)tg_formatLoanAmountDisplay:(nullable NSString *)raw {
    NSString *trim = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (trim.length == 0) return @"--";
    NSString *digits = [NSString tg_digitsOnlyFromMixed:trim];
    if (digits.length == 0) return @"--";
    return [NSString stringWithFormat:@"₹ %@", [NSString tg_weaveIndianDigits:digits]];
}

- (void)tg_refreshLoanCardAmount {
    // DC upgrade: prefer home maxApplyAmount, else product list highAmount (bold).
    NSString *amountRaw = [self.tg_homeData.maxApplyAmount stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (amountRaw.length == 0) {
        TgProductInfo *first = self.tg_productList.firstObject;
        if (first.bold.length > 0) {
            amountRaw = first.bold;
        }
    }
    self.tg_loanAmountCaption.text = [self tg_formatLoanAmountDisplay:amountRaw];
}

- (void)tg_refreshApplyButtonTitle {
    NSInteger status = self.tg_homeData.telescope;
    NSString *title = @"Apply now";
    switch (status) {
        case 81: title = @"Pay Overdue"; break;
        case 41: title = @"Change Bank Account"; break;
        case 32: title = @"Get loan"; break;
        case 30: title = @"Submit Application"; break;
        default: title = @"APPLY"; break;
    }
    if (status == 10 || status == 0) {
        title = @"Apply now";
    }
    [self.tg_applyLatch setTitle:title forState:UIControlStateNormal];
}

#pragma mark - Data

- (void)tg_applyHomeData:(TgHomeData *)home {
    self.tg_homeData = home;
    if (!home) {
        self.tg_promptWrap.hidden = YES;
        self.tg_cachedUserStatus = 0;
        [self tg_refreshLoanCardAmount];
        [self tg_refreshApplyButtonTitle];
        return;
    }
    self.tg_cachedUserStatus = home.telescope;
    if (home.elsewhere > 0) {
        [TgReviewGuideRelay tg_storeAppUserType:home.elsewhere];
    }
    if (home.telescope == 10) {
        [self tg_refreshUnverifiedUI];
        return;
    }
    [self tg_refreshCompletedUI];
}

- (void)tg_runFullPipeline {
    if (self.tg_loading) return;
    if ([[TgWireConduit shared] tg_isForceUpdateBlocking]) return;
    self.tg_loading = YES;
    [[TgPulseOverlay shared] veilSpin];

    __block TgHomeData *homeResult = nil;
    __block BOOL anyFailed = NO;
    __weak typeof(self) weakSelf = self;

    dispatch_group_t phase1 = dispatch_group_create();

    dispatch_group_enter(phase1);
    [[TgWireConduit shared] relayPOST:TgLaneUserSupHome
                             signData:@{}
                           nonSignData:@{@"dcUpFlag": @"1"}
                              success:^(id _Nullable data) {
        homeResult = [TgHomeData yy_modelWithJSON:data];
        dispatch_group_leave(phase1);
    } failure:^{
        anyFailed = YES;
        dispatch_group_leave(phase1);
    }];

    dispatch_group_enter(phase1);
    [[TgWireConduit shared] relayPOST:TgLaneVersionProbe
                             signData:@{}
                           nonSignData:@{}
                              success:^(id _Nullable data) {
        __strong typeof(weakSelf) self = weakSelf;
        if (self) {
            self.tg_versionData = [TgVersionData yy_modelWithJSON:data];
        }
        dispatch_group_leave(phase1);
    } failure:^{
        anyFailed = YES;
        dispatch_group_leave(phase1);
    }];

    dispatch_group_notify(phase1, dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;

        if ([[TgWireConduit shared] tg_isForceUpdateBlocking]) {
            self.tg_loading = NO;
            [[TgPulseOverlay shared] veilDismiss];
            return;
        }

        [[TgPolicyVault shared] pullManifestSuccess:^(TgSystemConfigModel *cfg) {
            (void)cfg;
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            if ([[TgWireConduit shared] tg_isForceUpdateBlocking]) {
                self.tg_loading = NO;
                [[TgPulseOverlay shared] veilDismiss];
                return;
            }
            // Always pull product/list for single-card amount (no list UI).
            [self tg_runPhase3WithHome:homeResult phase12Failed:anyFailed];
        } failure:^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            if ([[TgWireConduit shared] tg_isForceUpdateBlocking]) {
                self.tg_loading = NO;
                [[TgPulseOverlay shared] veilDismiss];
                return;
            }
            [self tg_runPhase3WithHome:homeResult phase12Failed:YES];
        }];
    });
}

- (void)tg_runPhase3WithHome:(TgHomeData *)home phase12Failed:(BOOL)phase12Failed {
    if ([[TgWireConduit shared] tg_isForceUpdateBlocking]) {
        self.tg_loading = NO;
        [[TgPulseOverlay shared] veilDismiss];
        return;
    }
    __block NSArray<TgProductInfo *> *products = @[];
    __block BOOL phase3Failed = NO;

    dispatch_group_t group = dispatch_group_create();

    dispatch_group_enter(group);
    [[TgWireConduit shared] relayPOST:TgLaneProductList
                             signData:@{}
                           nonSignData:@{}
                              success:^(id _Nullable data) {
        TgProductListData *listData = [TgProductListData yy_modelWithJSON:data];
        if (listData.portrait.count > 0) {
            products = listData.portrait;
        }
        dispatch_group_leave(group);
    } failure:^{
        phase3Failed = YES;
        dispatch_group_leave(group);
    }];

    dispatch_group_enter(group);
    [[TgWireConduit shared] relayPOST:TgLaneProductState
                             signData:@{}
                           nonSignData:@{}
                              success:^(id _Nullable data) {
        (void)data;
        dispatch_group_leave(group);
    } failure:^{
        phase3Failed = YES;
        dispatch_group_leave(group);
    }];

    __weak typeof(self) weakSelf = self;
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if ([[TgWireConduit shared] tg_isForceUpdateBlocking]) {
            self.tg_loading = NO;
            [[TgPulseOverlay shared] veilDismiss];
            return;
        }
        [self tg_finishPipelineWithHome:home products:products failed:(phase12Failed || phase3Failed)];
    });
}

- (void)tg_fetchProductList {
    if (self.tg_loading) return;
    self.tg_loading = YES;
    [[TgPulseOverlay shared] veilSpin];

    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneProductList
                             signData:@{}
                           nonSignData:@{}
                              success:^(id _Nullable data) {
        __strong typeof(weakSelf) self = weakSelf;
        TgProductListData *listData = [TgProductListData yy_modelWithJSON:data];
        self.tg_productList = listData.portrait ?: @[];
        self.tg_loading = NO;
        [[TgPulseOverlay shared] veilDismiss];
        [self tg_refreshLoanCardAmount];
    } failure:^{
        __strong typeof(weakSelf) self = weakSelf;
        self.tg_loading = NO;
        [[TgPulseOverlay shared] veilDismiss];
        TgLoanWhisperBusyHintIfNeeded();
    }];
}

- (void)tg_finishPipelineWithHome:(TgHomeData *)home
                         products:(NSArray<TgProductInfo *> *)products
                           failed:(BOOL)failed {
    self.tg_loading = NO;
    self.tg_pipelineDone = YES;
    self.tg_productList = products ?: @[];
    if (failed) {
        TgLoanWhisperBusyHintIfNeeded();
    }
    [self tg_applyHomeData:home];
    // Optional update: show first; auto-order resumes after user closes the dialog.
    BOOL deferAutoOrderForUpdate = [self tg_shouldShowOptionalUpdateDialog];
    if (deferAutoOrderForUpdate) {
        [self tg_showOptionalUpdateDialogIfNeeded];
    }
    BOOL holdVeilForAutoOrder = !failed && !deferAutoOrderForUpdate && home.telescope > 10;
    if (!holdVeilForAutoOrder) {
        [[TgPulseOverlay shared] veilDismiss];
    }
    [self tg_handleCompletedHomeBusinessDeferAutoOrder:deferAutoOrderForUpdate];
}

- (void)tg_refreshAfterAuthComplete {
    if (self.tg_loading) return;
    self.tg_pipelineDone = NO;
    [self tg_runFullPipeline];
}

- (void)tg_reloadSupHomeOnly {
    if (self.tg_loading) return;
    if ([[TgWireConduit shared] tg_isForceUpdateBlocking]) return;
    self.tg_loading = YES;
    [[TgPulseOverlay shared] veilSpin];

    __weak typeof(self) weakSelf = self;
    __block TgHomeData *parsedHome = nil;
    __block NSArray<TgProductInfo *> *products = nil;
    __block BOOL homeFailed = NO;
    __block BOOL productFailed = NO;

    dispatch_group_t group = dispatch_group_create();

    dispatch_group_enter(group);
    [[TgWireConduit shared] relayPOST:TgLaneUserSupHome
                             signData:@{}
                           nonSignData:@{@"dcUpFlag": @"1"}
                              success:^(id _Nullable data) {
        parsedHome = [TgHomeData yy_modelWithJSON:data];
        dispatch_group_leave(group);
    } failure:^{
        homeFailed = YES;
        dispatch_group_leave(group);
    }];

    dispatch_group_enter(group);
    [[TgWireConduit shared] relayPOST:TgLaneProductList
                             signData:@{}
                           nonSignData:@{}
                              success:^(id _Nullable data) {
        TgProductListData *listData = [TgProductListData yy_modelWithJSON:data];
        products = listData.portrait ?: @[];
        dispatch_group_leave(group);
    } failure:^{
        productFailed = YES;
        dispatch_group_leave(group);
    }];

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;

        self.tg_loading = NO;

        // Always apply a successful product list, even if home request failed.
        if (!productFailed && products) {
            self.tg_productList = products;
            [self tg_refreshLoanCardAmount];
        }

        if (homeFailed) {
            [[TgPulseOverlay shared] veilDismiss];
            TgLoanWhisperBusyHintIfNeeded();
            return;
        }

        NSInteger prevStatus = self.tg_cachedUserStatus;
        if (prevStatus == 10 && parsedHome.telescope > 10) {
            self.tg_pipelineDone = NO;
            [self tg_runFullPipeline];
            return;
        }

        if (productFailed) {
            TgLoanWhisperBusyHintIfNeeded();
        }

        [self tg_applyHomeData:parsedHome];
        // Hold soft-reload veil through auto-order check when status may trigger it.
        BOOL holdVeilForAutoOrder = parsedHome.telescope > 10;
        if (!holdVeilForAutoOrder) {
            [[TgPulseOverlay shared] veilDismiss];
        }
        [self tg_handleCompletedHomeBusiness];
    });
}

#pragma mark - ADID (§4.3)

- (void)tg_syncAdid {
    if (self.tg_adidSyncStarted) return;
    self.tg_adidSyncStarted = YES;
    [Adjust adidWithCompletionHandler:^(NSString *_Nullable adid) {
        NSString *trimmed = [adid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
        if (trimmed.length == 0) return;
        NSDictionary *nonSign = @{@"adid": trimmed};
        [[TgWireConduit shared] relayPOST:TgLaneUserInfo
                                 signData:@{}
                               nonSignData:nonSign
                                  success:nil
                                  failure:nil];
    }];
}

#pragma mark - Home business (§5.3–5.5)

- (void)tg_handleCompletedHomeBusiness {
    [self tg_handleCompletedHomeBusinessDeferAutoOrder:NO];
}

- (void)tg_handleCompletedHomeBusinessDeferAutoOrder:(BOOL)deferAutoOrder {
    if (!self.tg_homeData || self.tg_homeData.telescope <= 10) {
        [[TgPulseOverlay shared] veilDismiss];
        return;
    }
    if (!deferAutoOrder) {
        [self tg_tryAutoOrderAfterHomePipeline];
    } else {
        [[TgPulseOverlay shared] veilDismiss];
    }
    [self tg_showPendingWithdrawDialogIfNeeded];
}

- (void)tg_tryAutoOrderAfterHomePipeline {
    // Block taps while evaluating / starting auto-order (docs 40 Loading).
    [[TgPulseOverlay shared] veilSpin];
    if (![TgAutoOrderRelay tg_shouldAutoOrderWithHomeData:self.tg_homeData]) {
        [[TgPulseOverlay shared] veilDismiss];
        return;
    }
    // DC upgrade auto-order uses dcRecommend (docs 50 §3.6); product/list not required.
    BOOL started = [[TgAutoOrderRelay shared] tg_checkAndExecuteWithHomeData:self.tg_homeData
                                                                  productList:self.tg_productList
                                                                       hostVC:self
                                                                userInitiated:NO];
    if (!started) {
        [[TgPulseOverlay shared] veilDismiss];
    }
}

- (BOOL)tg_attemptAutoOrderIfNeeded {
    [[TgPulseOverlay shared] veilSpin];
    BOOL started = [[TgAutoOrderRelay shared] tg_checkAndExecuteWithHomeData:self.tg_homeData
                                                                productList:self.tg_productList
                                                                     hostVC:self
                                                              userInitiated:YES];
    if (!started) {
        [[TgPulseOverlay shared] veilDismiss];
    }
    return started;
}

- (NSString *)tg_trimmedStringFromDynamicId:(id)value {
    if (!value || value == [NSNull null]) return @"";
    if ([value isKindOfClass:[NSString class]]) {
        return [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [[(NSNumber *)value stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    }
    return [[NSString stringWithFormat:@"%@", value] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
}

- (void)tg_showPendingWithdrawDialogIfNeeded {
    if (self.tg_homeData.telescope != 32) return;

    __weak typeof(self) weakSelf = self;
    TgShardPanelConfig *cfg = [[TgShardPanelConfig alloc] init];
    cfg.title = kTgLoanWithdrawTitle;
    cfg.content = kTgLoanWithdrawBody;
    cfg.secondaryTitle = @"Cancel";
    cfg.primaryTitle = @"Get loan";
    cfg.tier = TgShardTierMid;
    cfg.mount = TgShardMountWindow;
    cfg.secondaryAction = ^{
        [[TgShardFacade shared] dismissTopPanel];
    };
    cfg.primaryAction = ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [[TgShardFacade shared] dismissTopPanel];
        [self tg_confirmPendingWithdraw];
    };
    [[TgShardFacade shared] showPanel:cfg];
}

- (void)tg_confirmPendingWithdraw {
    NSString *orderId = [self tg_trimmedStringFromDynamicId:self.tg_homeData.withdrawalOrderId];
    NSString *productId = [self.tg_homeData.orderStatusCount.resistance stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (orderId.length == 0 && productId.length == 0) {
        [[TgPulseOverlay shared] whisperLine:kTgLoanWithdrawMissingIdsHint];
        return;
    }
    if (!self.navigationController) return;
    TgOrderWithdrawVaultController *withdraw = [[TgOrderWithdrawVaultController alloc] init];
    withdraw.tg_orderId = orderId.length > 0 ? orderId : nil;
    withdraw.tg_productId = productId.length > 0 ? productId : nil;
    withdraw.hidesBottomBarWhenPushed = YES;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController pushViewController:withdraw animated:YES];
}

- (NSString *)tg_currentAppVersion {
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    version = [version stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    return version.length > 0 ? version : @"1.0.0";
}

- (BOOL)tg_shouldShowOptionalUpdateDialog {
    if (self.tg_hasShownUpdateDialog) return NO;
    TgVersionData *vd = self.tg_versionData;
    if (!vd) return NO;
    if (![vd.updateType isEqualToString:@"1"]) return NO;
    NSString *latest = [vd.noticeable stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (latest.length == 0) return NO;
    NSString *current = [self tg_currentAppVersion];
    return [current compare:latest options:NSNumericSearch] == NSOrderedAscending;
}

- (void)tg_showOptionalUpdateDialogIfNeeded {
    if (![self tg_shouldShowOptionalUpdateDialog]) return;
    self.tg_hasShownUpdateDialog = YES;

    TgVersionData *vd = self.tg_versionData;
    NSString *ver = [vd.noticeable stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    NSString *urlStr = vd.contrast;

    __weak typeof(self) weakSelf = self;
    void (^resumeAutoOrderAfterClose)(void) = ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self tg_tryAutoOrderAfterHomePipeline];
    };

    TgShardPanelConfig *cfg = [[TgShardPanelConfig alloc] init];
    cfg.panelStyle = TgShardPanelStyleText;
    cfg.title = @"Upgrade";
    cfg.content = @"New version found";
    cfg.detailText = ver.length > 0 ? [NSString stringWithFormat:@"V%@", ver] : nil;
    cfg.secondaryTitle = @"Cancel";
    cfg.primaryTitle = @"Upgrade";
    cfg.tier = TgShardTierHigh;
    cfg.mount = TgShardMountWindow;
    cfg.dismissOnPrimaryAction = NO;
    cfg.dismissOnSecondaryAction = YES;
    cfg.secondaryAction = ^{
        resumeAutoOrderAfterClose();
    };
    cfg.primaryAction = ^{
        NSURL *url = urlStr.length > 0 ? [NSURL URLWithString:urlStr] : nil;
        if (url && [UIApplication.sharedApplication canOpenURL:url]) {
            [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
        } else {
            [[TgPulseOverlay shared] whisperLine:@"The download link is not available." duration:2.0];
        }
    };
    [[TgShardFacade shared] showPanel:cfg];
}

#pragma mark - Product term (§5.6)

- (void)tg_onProductCardTapped:(TgProductInfo *)product {
    if ([self tg_attemptAutoOrderIfNeeded]) return;

    NSString *productId = [product.resistance stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
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
        [self tg_handleProductTermEnvelope:envelope productId:productId];
    } failure:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.tg_loading = NO;
        [[TgPulseOverlay shared] veilDismiss];
        TgLoanWhisperBusyHintIfNeeded();
    }];
}

- (void)tg_handleProductTermEnvelope:(TgEnvelopeBase *)envelope productId:(NSString *)productId {
    NSString *code = [NSString stringWithFormat:@"%ld", (long)envelope.cheer];
    if ([code isEqualToString:TgFaultHasOrder]) {
        [self tg_showProductTermBlockedPanelOpensWithdraw:NO productId:productId];
        return;
    }
    if ([code isEqualToString:TgFaultHasWithdrawOrder]) {
        [self tg_showProductTermBlockedPanelOpensWithdraw:YES productId:productId];
        return;
    }
    if ([code isEqualToString:TgFaultRejectQuota]) {
        NSString *msg = [envelope.power stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
        if (msg.length == 0) {
            msg = kTgLoanTermFailHint;
        }
        [TgRejectWebController tg_tryPushFromNav:self.navigationController unavailableToast:msg];
        return;
    }
    if (envelope.cheer == 200 && envelope.trick) {
        [self tg_navigateToProductApplicationWithProductId:productId preloadedTerm:envelope.trick];
        return;
    }
    NSString *msg = [envelope.power stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (msg.length == 0) {
        msg = kTgLoanTermFailHint;
    }
    [[TgPulseOverlay shared] whisperLine:msg];
}

- (void)tg_showProductTermBlockedPanelOpensWithdraw:(BOOL)opensWithdraw productId:(NSString *)productId {
    __weak typeof(self) weakSelf = self;
    [[TgShardFacade shared] showTextPanelWithContent:kTgLoanTermBlockedMessage
                                        primaryTitle:@"Know More"
                                      secondaryTitle:@"Back"
                                        primaryAction:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !self.navigationController) return;
        if (opensWithdraw) {
            [self tg_pushWithdrawDetailForProductId:productId];
        } else {
            [self tg_pushOrderDetailForProductId:productId];
        }
    }
                                      secondaryAction:nil];
}

- (void)tg_pushOrderDetailForProductId:(NSString *)productId {
    TgOrderDetailVaultController *detail = [[TgOrderDetailVaultController alloc] init];
    detail.tg_orderId = kTgLoanTermBlockedFromListOrderId;
    detail.tg_productId = productId;
    detail.hidesBottomBarWhenPushed = YES;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController pushViewController:detail animated:YES];
}

- (void)tg_pushWithdrawDetailForProductId:(NSString *)productId {
    TgOrderWithdrawVaultController *withdraw = [[TgOrderWithdrawVaultController alloc] init];
    withdraw.tg_orderId = kTgLoanTermBlockedFromListOrderId;
    withdraw.tg_productId = productId;
    withdraw.hidesBottomBarWhenPushed = YES;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController pushViewController:withdraw animated:YES];
}

- (void)tg_navigateToProductApplicationWithProductId:(NSString *)productId preloadedTerm:(id _Nullable)termData {
    NSString *trimmed = [productId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (trimmed.length == 0 || !self.navigationController) return;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    TgOrderApplyVaultController *apply = [[TgOrderApplyVaultController alloc] init];
    apply.tg_productId = trimmed;
    if ([termData isKindOfClass:[NSDictionary class]]) {
        apply.tg_preloadedTermJSON = termData;
    } else if (termData) {
        apply.tg_preloadedTermJSON = [termData yy_modelToJSONObject];
    }
    apply.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:apply animated:YES];
}

- (void)tg_navigateToProductApplicationWithProductId:(NSString *)productId {
    [self tg_navigateToProductApplicationWithProductId:productId preloadedTerm:nil];
}

#pragma mark - Actions

- (void)tg_onScoreTapped {
    if (!self.navigationController) return;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    TgScoreDetailVaultController *detail = [[TgScoreDetailVaultController alloc] init];
    [self.navigationController pushViewController:detail animated:YES];
}

- (void)tg_onApplyTapped {
    [self tg_routeHomePrimaryActionForUserStatus:self.tg_homeData.telescope];
}

- (void)tg_onPromptTapped {
    if (!self.tg_homeData) return;
    [TgTraceRelay emitSignal:TgTraceSignalHomeApplyTap];
    NSInteger status = self.tg_homeData.telescope;
    // Prompt hot area: only statuses with chevron are clickable (51 needs rejectH5).
    if (![[self class] tg_shouldAppendPromptChevronForStatus:status]) {
        return;
    }
    // userStatus 51: prompt → rejectH5 (docs 18/49); empty link already gated by chevron check.
    if (status == 51) {
        [TgRejectWebController tg_tryPushFromNav:self.navigationController unavailableToast:nil];
        return;
    }
    [self tg_routeHomePrimaryActionForUserStatus:status];
}

/// Loan-supermarket home primary CTA (§50 §2.2).
- (void)tg_routeHomePrimaryActionForUserStatus:(NSInteger)userStatus {
    if (!self.navigationController) return;

    if (userStatus == 10 || userStatus == 0) {
        [TgTraceRelay emitSignal:TgTraceSignalStartTap];
        [TgKycPathRelay startAuthFromNav:self.navigationController];
        return;
    }
    if (userStatus == 81) {
        [self tg_openOrderListWithFocusApiOrderStatus:20];
        return;
    }
    if (userStatus == 41 || userStatus == 30 || userStatus == 32) {
        [self tg_openOrderListWithFocusApiOrderStatus:10];
        return;
    }

    if ([self tg_attemptAutoOrderIfNeeded]) return;
    // 20 / 80 / 51 / 100 / others → precise recommend (51 Apply does not open rejectH5 directly).
    [self tg_pushDcMatchRecommend];
}

- (void)tg_pushDcMatchRecommend {
    if (!self.navigationController) return;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    TgDcMatchVaultController *vc = [[TgDcMatchVaultController alloc] init];
    vc.tg_promptCopy = self.tg_homeData.fold;
    vc.tg_userStatus = self.tg_homeData.telescope;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)tg_openOrderListWithFocusApiOrderStatus:(NSInteger)apiOrderStatus {
    UITabBarController *dock = self.tabBarController;
    if (dock) {
        [TgDockBarRelay primeRootAtIndex:TgDockTabIndexOrder dock:dock];
        dock.selectedIndex = TgDockTabIndexOrder;
        UINavigationController *orderNav = (UINavigationController *)dock.viewControllers[TgDockTabIndexOrder];
        if ([orderNav isKindOfClass:[UINavigationController class]]) {
            [orderNav popToRootViewControllerAnimated:NO];
        }
        [TgOrderShelfController tg_requestFocusSectionWithApiOrderStatus:apiOrderStatus];
        return;
    }

    if (!self.navigationController) return;
    [TgOrderShelfController tg_requestFocusSectionWithApiOrderStatus:apiOrderStatus];
    TgOrderShelfController *orderVC = [[TgOrderShelfController alloc] init];
    orderVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:orderVC animated:YES];
}

@end
