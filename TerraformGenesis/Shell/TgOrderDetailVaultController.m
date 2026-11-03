//

//

#import "TgOrderDetailVaultController.h"
#import "TgBankEditVaultController.h"
#import "TgEnvelopeBase.h"
#import "TgOrderForgeRelay.h"
#import "TgOrderStatusDisplay.h"
#import "TgOrderSuccessVaultController.h"
#import "TgOrderWithdrawVaultController.h"
#import "TgPaneWebController.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"
#import "TgPulseOverlay.h"
#import "TgWireConduit.h"
#import "NSString+TgGlyph.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <objc/runtime.h>

static CGFloat const kTgDetailHorzInset = 16.0;
static CGFloat const kTgDetailCardTopInset = 8.0;

static CGFloat const kTgDetailPeachCardTopOffset = 8.0;
static CGFloat const kTgDetailWaveHeight = 24.0;
static CGFloat const kTgDetailCardRadius = 16.0;
static CGFloat const kTgDetailButtonHeight = 50.0;
static CGFloat const kTgDetailButtonGap = 12.0;
static CGFloat const kTgDetailBottomBarVertPad = 8.0;
static CGFloat const kTgDetailBottomBarHeight = kTgDetailBottomBarVertPad + kTgDetailButtonHeight + kTgDetailBottomBarVertPad;
static CGFloat const kTgDetailScrollBodyBottomInset = 24.0;
static CGFloat const kTgDetailPeachBgRatio = 147.0 / 315.0;
static CGFloat const kTgDetailProductPillHeight = 28.0;
static CGFloat const kTgDetailLogoCornerRadius = 4.0;
static CGFloat const kTgDetailPeachTopInset = 22.0;
static CGFloat const kTgDetailStatusToAmountGap = 14.0;
static CGFloat const kTgDetailAmountToProductGap = 18.0;
static CGFloat const kTgDetailProductBottomInset = 20.0;
static CGFloat const kTgDetailRowHeight = 44.0;

static CGFloat const kTgDetailSummaryRowHeight = 29.0;

static NSString * const kTgDetailWaveAsset = @"use_Subtract2";
static NSString * const kTgDetailPeachBgAsset = @"use_bg";
static NSString * const kTgDetailMedalAsset = @"use_loan_star";
static NSString * const kTgDetailTipIconAsset = @"details";

static NSString * const kTgDetailPageBgHex = @"#FFFFFF";
static NSString * const kTgDetailSummaryBgHex = @"#FAFAFA";
static NSString * const kTgDetailStatusHex = @"#793200";
static NSString * const kTgDetailProductNameHex = @"#E2A369";
static NSString * const kTgDetailBankValueHex = @"#C51B12";
static NSString * const kTgDetailNoticeBgHex = @"#FFF4E8";
static NSString * const kTgDetailNoticeTextHex = @"#E67E22";
static NSString * const kTgDetailMutedHex = @"#686868";
static NSString * const kTgDetailDividerHex = @"#EDEDED";
static NSString * const kTgDetailPrimaryBtnHex = @"#182040";
static NSString * const kTgDetailSecondaryBtnHex = @"#A9B5D0";
static NSString * const kTgDetailUpiNotice =
    @"This UPI link stays valid for 15 minutes. To avoid issues, please repay using the new link from the repayment button.";

static NSString * const kTgDetailBusyHint = @"The system is occupied. Please retry after 2 minutes.";
static NSString * const kTgDetailMissingIdsHint = @"Order ID or Product ID must be provided";
static NSString * const kTgDetailMissingOrderIdHint = @"Order ID must be provided";
static NSString * const kTgDetailNoPaymentLinkHint = @"No repayment link is available";
static NSString * const kTgDetailInvalidLinkHint = @"Invalid link";

static NSString * const kTgDetailTipAmountReceived =
    @"The amount you actually receive equals the loan amount minus the service fee and GST.";
static NSString * const kTgDetailTipInterest =
    @"Computed from your loan amount, loan term, and this product's interest rate.";
static NSString * const kTgDetailTipServiceFee =
    @"This fee is charged by the financial institution for delivering loan services.";

static const void *kTgDetailTipTextKey = &kTgDetailTipTextKey;

@interface TgOrderDetailVaultController () <UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong) UIScrollView *tg_scrollPane;
@property (nonatomic, strong) UIView *tg_scrollBody;
@property (nonatomic, strong) UIView *tg_mainCard;
@property (nonatomic, strong) UIView *tg_peachVeil;
@property (nonatomic, strong) UIImageView *tg_peachBgGlyph;
@property (nonatomic, strong) UILabel *tg_statusCaption;
@property (nonatomic, strong) UILabel *tg_amountCaption;
@property (nonatomic, strong) UIView *tg_productPill;
@property (nonatomic, strong) UIImageView *tg_logoGlyph;
@property (nonatomic, strong) UILabel *tg_nameCaption;
@property (nonatomic, strong) UIImageView *tg_medalGlyph;
@property (nonatomic, strong) UIImageView *tg_waveCap;
@property (nonatomic, strong) UIView *tg_whiteVeil;
@property (nonatomic, strong) UIView *tg_summaryCard;
@property (nonatomic, strong) UILabel *tg_loanDurationTitleCaption;
@property (nonatomic, strong) UILabel *tg_loanDurationValueCaption;
@property (nonatomic, strong) UIView *tg_summaryDivider;
@property (nonatomic, strong) UILabel *tg_bankTitleCaption;
@property (nonatomic, strong) UILabel *tg_bankValueCaption;
@property (nonatomic, strong) MASConstraint *tg_summaryBankRowHeightConstraint;
@property (nonatomic, strong) MASConstraint *tg_summaryDividerHeightConstraint;
@property (nonatomic, strong) MASConstraint *tg_summaryDividerTopConstraint;
@property (nonatomic, strong) MASConstraint *tg_summaryCardBottomConstraint;
@property (nonatomic, strong) MASConstraint *tg_whiteVeilBottomConstraint;
@property (nonatomic, strong) MASConstraint *tg_detailStackBottomConstraint;
@property (nonatomic, strong) MASConstraint *tg_noticeTopConstraint;
@property (nonatomic, strong) MASConstraint *tg_noticeHeightConstraint;
@property (nonatomic, strong) UIStackView *tg_detailStack;
@property (nonatomic, strong) UIView *tg_noticeBox;
@property (nonatomic, strong) UILabel *tg_noticeCaption;
@property (nonatomic, strong) UIView *tg_bottomBar;
@property (nonatomic, strong) UIView *tg_bottomBackdrop;
@property (nonatomic, strong) MASConstraint *tg_scrollBottomConstraint;
@property (nonatomic, strong) MASConstraint *tg_scrollContentBottomConstraint;
@property (nonatomic, strong) MASConstraint *tg_bottomBarHeightConstraint;
@property (nonatomic, strong) UIButton *tg_deferLatch;
@property (nonatomic, strong) UIButton *tg_repayLatch;
@property (nonatomic, strong) UIButton *tg_singleLatch;

@property (nonatomic, strong, nullable) TgOrderDetailData *tg_detailData;
@property (nonatomic, assign) BOOL tg_actionInFlight;

@end

@implementation TgOrderDetailVaultController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.tg_backdropStyle = TgHullBackdropStyleUseBg0;
        self.tg_showsBackButton = YES;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self tg_setNavTitleMedium18:@"Loan details"];
    [self tg_buildLayout];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self tg_loadOrderDetail];
}

#pragma mark - Layout

- (void)tg_buildLayout {
    self.tg_scrollPane = [[UIScrollView alloc] init];
    self.tg_scrollPane.showsVerticalScrollIndicator = NO;
    self.tg_scrollPane.alwaysBounceVertical = YES;
    self.tg_scrollPane.backgroundColor = UIColor.clearColor;
    self.tg_scrollPane.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:self.tg_scrollPane];

    self.tg_scrollBody = [[UIView alloc] init];
    [self.tg_scrollPane addSubview:self.tg_scrollBody];

    self.tg_mainCard = [[UIView alloc] init];
    self.tg_mainCard.clipsToBounds = NO;
    [self.tg_scrollBody addSubview:self.tg_mainCard];

    self.tg_peachVeil = [[UIView alloc] init];
    self.tg_peachVeil.layer.cornerRadius = kTgDetailCardRadius;
    self.tg_peachVeil.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    self.tg_peachVeil.clipsToBounds = YES;
    [self.tg_mainCard addSubview:self.tg_peachVeil];

    self.tg_peachBgGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgDetailPeachBgAsset]];
    self.tg_peachBgGlyph.contentMode = UIViewContentModeScaleAspectFill;
    [self.tg_peachVeil addSubview:self.tg_peachBgGlyph];

    self.tg_statusCaption = [[UILabel alloc] init];
    self.tg_statusCaption.font = [UIFont tg_meshGlyphWithSize:18 weight:UIFontWeightBold];
    self.tg_statusCaption.textColor = [UIColor tg_toneFromHex:kTgDetailStatusHex];
    [self.tg_peachVeil addSubview:self.tg_statusCaption];

    self.tg_amountCaption = [[UILabel alloc] init];
    self.tg_amountCaption.font = [UIFont tg_meshGlyphWithSize:28 weight:UIFontWeightBold];
    self.tg_amountCaption.textColor = UIColor.blackColor;
    self.tg_amountCaption.text = @"-";
    [self.tg_peachVeil addSubview:self.tg_amountCaption];

    self.tg_productPill = [[UIView alloc] init];
    [self.tg_peachVeil addSubview:self.tg_productPill];

    self.tg_logoGlyph = [[UIImageView alloc] init];
    self.tg_logoGlyph.contentMode = UIViewContentModeScaleAspectFit;
    self.tg_logoGlyph.layer.cornerRadius = kTgDetailLogoCornerRadius;
    self.tg_logoGlyph.clipsToBounds = YES;
    [self.tg_productPill addSubview:self.tg_logoGlyph];

    self.tg_nameCaption = [[UILabel alloc] init];
    self.tg_nameCaption.font = [UIFont tg_meshGlyphWithSize:13 weight:UIFontWeightMedium];
    self.tg_nameCaption.textColor = [UIColor tg_toneFromHex:kTgDetailProductNameHex];
    [self.tg_productPill addSubview:self.tg_nameCaption];

    self.tg_medalGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgDetailMedalAsset]];
    self.tg_medalGlyph.contentMode = UIViewContentModeScaleAspectFit;
    [self.tg_peachVeil addSubview:self.tg_medalGlyph];

    self.tg_whiteVeil = [[UIView alloc] init];
    self.tg_whiteVeil.backgroundColor = [UIColor tg_toneFromHex:kTgDetailPageBgHex];
    [self.tg_scrollBody addSubview:self.tg_whiteVeil];

    self.tg_waveCap = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgDetailWaveAsset]];
    self.tg_waveCap.contentMode = UIViewContentModeScaleToFill;
    [self.tg_scrollBody addSubview:self.tg_waveCap];

    self.tg_summaryCard = [[UIView alloc] init];
    self.tg_summaryCard.backgroundColor = [UIColor tg_toneFromHex:kTgDetailSummaryBgHex];

    self.tg_loanDurationTitleCaption = [[UILabel alloc] init];
    self.tg_loanDurationTitleCaption.text = @"Loan duration";
    self.tg_loanDurationTitleCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    self.tg_loanDurationTitleCaption.textColor = [UIColor tg_toneFromHex:kTgDetailMutedHex];

    self.tg_loanDurationValueCaption = [[UILabel alloc] init];
    self.tg_loanDurationValueCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightBold];
    self.tg_loanDurationValueCaption.textColor = [UIColor tg_toneFromHex:kTgDetailBankValueHex];
    self.tg_loanDurationValueCaption.textAlignment = NSTextAlignmentRight;
    self.tg_loanDurationValueCaption.text = @"-";

    self.tg_summaryDivider = [[UIView alloc] init];
    self.tg_summaryDivider.backgroundColor = [UIColor tg_toneFromHex:kTgDetailDividerHex];

    self.tg_bankTitleCaption = [[UILabel alloc] init];
    self.tg_bankTitleCaption.text = @"Bank account number";
    self.tg_bankTitleCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    self.tg_bankTitleCaption.textColor = [UIColor tg_toneFromHex:kTgDetailMutedHex];

    self.tg_bankValueCaption = [[UILabel alloc] init];
    self.tg_bankValueCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightBold];
    self.tg_bankValueCaption.textColor = [UIColor tg_toneFromHex:kTgDetailBankValueHex];
    self.tg_bankValueCaption.textAlignment = NSTextAlignmentRight;
    self.tg_bankValueCaption.text = @"-";

    [self.tg_summaryCard addSubview:self.tg_loanDurationTitleCaption];
    [self.tg_summaryCard addSubview:self.tg_loanDurationValueCaption];
    [self.tg_summaryCard addSubview:self.tg_summaryDivider];
    [self.tg_summaryCard addSubview:self.tg_bankTitleCaption];
    [self.tg_summaryCard addSubview:self.tg_bankValueCaption];
    [self.tg_whiteVeil addSubview:self.tg_summaryCard];

    self.tg_detailStack = [[UIStackView alloc] init];
    self.tg_detailStack.axis = UILayoutConstraintAxisVertical;
    self.tg_detailStack.spacing = 0;
    [self.tg_detailStack setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                         forAxis:UILayoutConstraintAxisVertical];
    [self.tg_whiteVeil addSubview:self.tg_detailStack];

    self.tg_noticeBox = [[UIView alloc] init];
    self.tg_noticeBox.backgroundColor = [UIColor tg_toneFromHex:kTgDetailNoticeBgHex];
    self.tg_noticeBox.layer.cornerRadius = 8;
    self.tg_noticeBox.clipsToBounds = YES;
    [self.tg_whiteVeil addSubview:self.tg_noticeBox];

    self.tg_noticeCaption = [[UILabel alloc] init];
    self.tg_noticeCaption.font = [UIFont tg_meshGlyphWithSize:13 weight:UIFontWeightRegular];
    self.tg_noticeCaption.textColor = [UIColor tg_toneFromHex:kTgDetailNoticeTextHex];
    self.tg_noticeCaption.numberOfLines = 0;
    [self.tg_noticeBox addSubview:self.tg_noticeCaption];

    self.tg_deferLatch = [self tg_makeSecondaryButton:@"Defer"];
    self.tg_repayLatch = [self tg_makePrimaryButton:@"Repay"];
    self.tg_singleLatch = [self tg_makePrimaryButton:@"Confirm"];

    self.tg_bottomBar = [[UIView alloc] init];
    self.tg_bottomBar.backgroundColor = UIColor.clearColor;
    [self.tg_bottomBar addSubview:self.tg_deferLatch];
    [self.tg_bottomBar addSubview:self.tg_repayLatch];
    [self.tg_bottomBar addSubview:self.tg_singleLatch];

    self.tg_bottomBackdrop = [[UIView alloc] init];
    self.tg_bottomBackdrop.backgroundColor = [UIColor tg_toneFromHex:kTgDetailPageBgHex];
    [self.view addSubview:self.tg_bottomBackdrop];
    [self.view addSubview:self.tg_bottomBar];
    [self.view bringSubviewToFront:self.tg_bottomBackdrop];
    [self.view bringSubviewToFront:self.tg_bottomBar];

    [self tg_hideAllBottomButtons];

    [self.tg_deferLatch addTarget:self action:@selector(tg_onDeferTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.tg_repayLatch addTarget:self action:@selector(tg_onRepayTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.tg_singleLatch addTarget:self action:@selector(tg_onSinglePrimaryTapped) forControlEvents:UIControlEventTouchUpInside];

    [self.tg_bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        self.tg_bottomBarHeightConstraint = make.height.mas_equalTo(0);
    }];
    [self.tg_deferLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_bottomBar).offset(kTgDetailHorzInset);
        make.top.equalTo(self.tg_bottomBar).offset(kTgDetailBottomBarVertPad);
        make.bottom.equalTo(self.tg_bottomBar).offset(-kTgDetailBottomBarVertPad);
    }];
    [self.tg_repayLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.tg_bottomBar).offset(-kTgDetailHorzInset);
        make.left.equalTo(self.tg_deferLatch.mas_right).offset(kTgDetailButtonGap);
        make.top.bottom.equalTo(self.tg_deferLatch);
        make.width.equalTo(self.tg_deferLatch);
    }];
    [self.tg_singleLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_bottomBar).offset(kTgDetailHorzInset);
        make.right.equalTo(self.tg_bottomBar).offset(-kTgDetailHorzInset);
        make.top.bottom.equalTo(self.tg_deferLatch);
    }];
    [self.tg_scrollPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset([self tg_contentTopBelowNavigation]);
        make.left.right.equalTo(self.view);
        self.tg_scrollBottomConstraint = make.bottom.equalTo(self.tg_bottomBar.mas_top);
    }];
    [self.tg_bottomBackdrop mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.tg_scrollPane.mas_bottom);
    }];
    [self.tg_scrollBody mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.tg_scrollPane);
        make.width.equalTo(self.tg_scrollPane);
    }];
    [self.tg_mainCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_scrollBody).offset(kTgDetailPeachCardTopOffset);
        make.left.right.equalTo(self.tg_scrollBody).inset(kTgDetailHorzInset);
        make.bottom.equalTo(self.tg_peachVeil);
    }];
    [self.tg_peachVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.tg_mainCard);
        make.height.equalTo(self.tg_peachVeil.mas_width).multipliedBy(kTgDetailPeachBgRatio);
    }];
    [self.tg_peachBgGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_peachVeil);
    }];
    [self.tg_statusCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_peachVeil).offset(kTgDetailPeachTopInset);
        make.left.equalTo(self.tg_peachVeil).offset(16);
        make.right.lessThanOrEqualTo(self.tg_medalGlyph.mas_left).offset(-8);
    }];
    [self.tg_amountCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_statusCaption.mas_bottom).offset(kTgDetailStatusToAmountGap);
        make.left.equalTo(self.tg_statusCaption);
        make.right.lessThanOrEqualTo(self.tg_medalGlyph.mas_left).offset(-8);
    }];
    [self.tg_productPill mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_amountCaption.mas_bottom).offset(kTgDetailAmountToProductGap);
        make.left.equalTo(self.tg_statusCaption);
        make.height.mas_equalTo(kTgDetailProductPillHeight);
        make.bottom.lessThanOrEqualTo(self.tg_peachVeil).offset(-kTgDetailProductBottomInset);
    }];
    [self.tg_logoGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.centerY.equalTo(self.tg_productPill);
        make.width.height.mas_equalTo(20);
    }];
    [self.tg_nameCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_logoGlyph.mas_right).offset(8);
        make.centerY.right.equalTo(self.tg_productPill);
    }];
    [self.tg_medalGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.tg_peachVeil).offset(-8);
        make.centerY.equalTo(self.tg_peachVeil).offset(4);
        make.width.height.mas_equalTo(88);
    }];
    [self.tg_waveCap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.tg_peachVeil.mas_bottom);
        make.height.mas_equalTo(kTgDetailWaveHeight);
    }];
    [self.tg_whiteVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.tg_waveCap.mas_bottom);
        self.tg_whiteVeilBottomConstraint = make.bottom.equalTo(self.tg_noticeBox.mas_bottom).offset(16);
    }];
    [self.tg_summaryCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_waveCap.mas_bottom).offset(16);
        make.left.right.equalTo(self.tg_scrollBody).inset(kTgDetailHorzInset);
        self.tg_summaryCardBottomConstraint = make.bottom.equalTo(self.tg_loanDurationTitleCaption.mas_bottom).offset(12);
    }];
    [self.tg_loanDurationTitleCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_summaryCard).offset(12);
        make.left.equalTo(self.tg_summaryCard).offset(16);
        make.height.mas_equalTo(kTgDetailSummaryRowHeight);
    }];
    [self.tg_loanDurationValueCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.tg_loanDurationTitleCaption);
        make.right.equalTo(self.tg_summaryCard).offset(-16);
        make.left.greaterThanOrEqualTo(self.tg_loanDurationTitleCaption.mas_right).offset(8);
    }];
    [self.tg_summaryDivider mas_makeConstraints:^(MASConstraintMaker *make) {
        self.tg_summaryDividerTopConstraint = make.top.equalTo(self.tg_loanDurationTitleCaption.mas_bottom).offset(12);
        make.left.right.equalTo(self.tg_summaryCard).inset(16);
        self.tg_summaryDividerHeightConstraint = make.height.mas_equalTo(1);
    }];
    [self.tg_bankTitleCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_summaryDivider.mas_bottom).offset(12);
        make.left.equalTo(self.tg_summaryCard).offset(16);
        self.tg_summaryBankRowHeightConstraint = make.height.mas_equalTo(kTgDetailSummaryRowHeight);
    }];
    [self.tg_bankValueCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.tg_bankTitleCaption);
        make.right.equalTo(self.tg_summaryCard).offset(-16);
        make.left.greaterThanOrEqualTo(self.tg_bankTitleCaption.mas_right).offset(8);
    }];
    [self.tg_detailStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_summaryCard.mas_bottom).offset(8);
        make.left.right.equalTo(self.tg_scrollBody).inset(kTgDetailHorzInset);
    }];
    [self.tg_noticeBox mas_makeConstraints:^(MASConstraintMaker *make) {
        self.tg_noticeTopConstraint = make.top.equalTo(self.tg_detailStack.mas_bottom).offset(12);
        make.left.right.equalTo(self.tg_scrollBody).inset(kTgDetailHorzInset);
        self.tg_noticeHeightConstraint = make.height.mas_equalTo(0).priority(MASLayoutPriorityDefaultLow);
        self.tg_scrollContentBottomConstraint =
            make.bottom.equalTo(self.tg_scrollBody).offset(-kTgDetailScrollBodyBottomInset);
    }];
    [self.tg_noticeCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_noticeBox).insets(UIEdgeInsetsMake(10, 12, 10, 12));
    }];

    [self.tg_scrollBody bringSubviewToFront:self.tg_waveCap];
}

- (UIButton *)tg_makePrimaryButton:(NSString *)title {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    btn.backgroundColor = [UIColor tg_toneFromHex:kTgDetailPrimaryBtnHex];
    btn.layer.cornerRadius = kTgDetailButtonHeight / 2.0;
    btn.clipsToBounds = YES;
    return btn;
}

- (UIButton *)tg_makeSecondaryButton:(NSString *)title {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    btn.backgroundColor = [UIColor tg_toneFromHex:kTgDetailSecondaryBtnHex];
    btn.layer.cornerRadius = kTgDetailButtonHeight / 2.0;
    btn.clipsToBounds = YES;
    return btn;
}

#pragma mark - Data

- (NSString *)tg_trimmed:(NSString *)text {
    return [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
}

- (NSString *)tg_displayOrDash:(NSString *)text {
    NSString *trim = [self tg_trimmed:text];
    return trim.length > 0 ? trim : @"-";
}

- (NSString *)tg_digitsFromAmount:(NSString *)raw {
    NSString *trim = [self tg_trimmed:raw];
    if (trim.length == 0) return @"";
    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return [[trim componentsSeparatedByCharactersInSet:nonDigits] componentsJoinedByString:@""];
}

- (NSString *)tg_formatLoanAmountText:(NSString *)raw {
    NSString *digits = [self tg_digitsFromAmount:raw];
    if (digits.length == 0) return @"-";
    return [NSString stringWithFormat:@"₹ %@", [NSString tg_weaveIndianDigits:digits]];
}

- (NSString *)tg_formatPlainAmountText:(NSString *)raw {
    NSString *trim = [self tg_trimmed:raw];
    if (trim.length == 0) return @"-";
    NSString *digits = [self tg_digitsFromAmount:trim];
    if (digits.length > 0) {
        return [NSString tg_weaveIndianDigits:digits];
    }
    return trim;
}

- (BOOL)tg_shouldShowCurrencyValue:(NSString *)raw {
    NSString *trim = [self tg_trimmed:raw];
    if (trim.length == 0) return NO;
    double val = [trim doubleValue];
    return val != 0.0;
}

- (BOOL)tg_shouldHideRepaymentRelatedForStatus:(NSInteger)status {
    switch (status) {
        case 10:
        case 30:
        case 31:
        case 36:
        case 50:
        case 99:
            return YES;
        default:
            return NO;
    }
}

- (BOOL)tg_isPayoutPaymentDateStatus:(NSInteger)status {
    return status == 60 || status == 61 || status == 70;
}

- (NSString *)tg_formatDaysFromDetail:(TgOrderDetail *)detail {
    if (!detail) return @"-";
    NSInteger days = detail.ill > 0 ? detail.ill : detail.culture;
    if (days <= 0) return @"-";
    return [NSString stringWithFormat:@"%ld Days", (long)days];
}

- (NSString *)tg_formatDisplayDate:(NSString *)raw {
    NSString *trim = [self tg_trimmed:raw];
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

- (NSString *)tg_formatBankAccountDisplay:(NSString *)accountNo {
    NSString *digits = [self tg_digitsFromAmount:accountNo];
    if (digits.length == 0) {
        return [self tg_displayOrDash:accountNo];
    }
    NSMutableArray<NSString *> *chunks = [NSMutableArray array];
    NSUInteger i = 0;
    while (i < digits.length) {
        NSUInteger len = MIN(4, digits.length - i);
        [chunks addObject:[digits substringWithRange:NSMakeRange(i, len)]];
        i += len;
    }
    return [chunks componentsJoinedByString:@" "];
}

- (NSString *)tg_statusTipForOrderStatus:(NSInteger)status {
    switch (status) {
        case 10:
            return @"Please submit complete information so we can process your application more quickly.";
        case 30:
            return @"Your application is being reviewed; the credit evaluation result will determine your loan amount";
        case 31:
            return @"Your loan application could not be approved.";
        case 32:
            return @"You have a loan order pending confirmation. After entering the page to confirm, the funds will be transferred to your bank account immediately.";
        case 36:
            return @"Your bank card cannot receive the loan. Please update it promptly so disbursement can proceed on time.";
        case 50:
            return @"Your loan application is approved. Funds will be disbursed to your account shortly - please watch for the credit.";
        case 60:
            return @"Please repay before the due date. On-time repayments can greatly improve your future loan eligibility.";
        case 61:
            return @"You are overdue. Please repay as soon as you can, or your credit may be affected.";
        case 70:
            return @"This order was settled successfully. You may now apply for a new loan at a higher amount.";
        case 99:
            return @"The order was canceled. If you need to reapply or have questions, please contact us.";
        default:
            return @"";
    }
}

- (NSString *)tg_appDisplayName {
    NSString *name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    name = [self tg_trimmed:name];
    if (name.length > 0) return name;
    name = [self tg_trimmed:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]];
    return name.length > 0 ? name : @"App";
}

- (void)tg_loadOrderDetail {
    NSString *orderId = [self tg_trimmed:self.tg_orderId];
    NSString *productId = [self tg_trimmed:self.tg_productId];
    if (orderId.length == 0) {
        [[TgPulseOverlay shared] whisperLine:kTgDetailMissingIdsHint duration:2.0];
        return;
    }

    NSMutableDictionary *nonSign = [NSMutableDictionary dictionaryWithObject:@"DC" forKey:@"appType"];
    if (productId.length > 0) {
        nonSign[@"productId"] = productId;
    }

    [[TgPulseOverlay shared] veilSpin];
    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneOrderDetail
                             signData:@{ @"orderId": orderId }
                           nonSignData:nonSign
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        __strong typeof(weakSelf) self = weakSelf;
        [[TgPulseOverlay shared] veilDismiss];
        if (envelope.cheer == 200 && envelope.trick) {
            self.tg_detailData = [TgOrderDetailData yy_modelWithJSON:envelope.trick];
            NSString *apiOrderId = [self tg_trimmed:self.tg_detailData.hillside.interpret];
            if (apiOrderId.length > 0) {
                self.tg_orderId = apiOrderId;
            }
            [self tg_refreshUI];
            return;
        }
        NSString *msg = [self tg_trimmed:envelope.power];
        [[TgPulseOverlay shared] whisperLine:msg.length > 0 ? msg : kTgDetailBusyHint duration:2.0];
    } failure:^{
        [[TgPulseOverlay shared] veilDismiss];
        [[TgPulseOverlay shared] whisperLine:kTgDetailBusyHint duration:2.0];
    }];
}

- (void)tg_refreshUI {
    TgOrderDetailData *data = self.tg_detailData;
    TgOrderDetail *detail = data.hillside;
    TgOrderProduct *product = data.invent;
    TgOrderBankCard *bank = data.living;
    if (!detail) return;

    NSInteger status = detail.intellectual;

    self.tg_statusCaption.text = [TgOrderStatusDisplay tg_titleForOrderStatus:status];

    self.tg_amountCaption.text = [self tg_formatLoanAmountText:detail.inch];

    NSString *productName = [self tg_trimmed:product.other];
    self.tg_nameCaption.text = productName.length > 0 ? productName : [self tg_appDisplayName];

    NSString *logoURL = [self tg_trimmed:product.green];
    if (logoURL.length > 0) {
        [self.tg_logoGlyph sd_setImageWithURL:[NSURL URLWithString:logoURL] placeholderImage:nil];
    } else {
        self.tg_logoGlyph.image = nil;
    }

    self.tg_loanDurationValueCaption.text = [self tg_formatDaysFromDetail:detail];

    NSString *accountNo = [self tg_trimmed:bank.measure];
    BOOL showBank = accountNo.length > 0;
    self.tg_summaryDivider.hidden = !showBank;
    self.tg_bankTitleCaption.hidden = !showBank;
    self.tg_bankValueCaption.hidden = !showBank;
    if (showBank) {
        self.tg_bankValueCaption.text = [self tg_formatBankAccountDisplay:accountNo];
        [self.tg_summaryDividerTopConstraint setOffset:12];
        [self.tg_summaryDividerHeightConstraint setOffset:1];
        [self.tg_summaryBankRowHeightConstraint setOffset:kTgDetailSummaryRowHeight];
    } else {
        [self.tg_summaryDividerTopConstraint setOffset:0];
        [self.tg_summaryDividerHeightConstraint setOffset:0];
        [self.tg_summaryBankRowHeightConstraint setOffset:0];
    }

    [self.tg_summaryCardBottomConstraint uninstall];
    [self.tg_summaryCard mas_updateConstraints:^(MASConstraintMaker *make) {
        if (showBank) {
            self.tg_summaryCardBottomConstraint = make.bottom.equalTo(self.tg_bankTitleCaption.mas_bottom).offset(12);
        } else {
            self.tg_summaryCardBottomConstraint = make.bottom.equalTo(self.tg_loanDurationTitleCaption.mas_bottom).offset(12);
        }
    }];

    [self tg_rebuildDetailRowsWithDetail:detail];
    [self tg_refreshNoticeWithDetail:detail];
    [self tg_refreshBottomButtonsWithDetail:detail];
    [self tg_updateScrollContentLayout];
}

- (void)tg_updateWhiteVeilBottomAnchor {
    BOOL showNotice = !self.tg_noticeBox.hidden;

    if (showNotice) {
        [self.tg_noticeTopConstraint setOffset:12];
        [self.tg_noticeHeightConstraint uninstall];
        self.tg_noticeHeightConstraint = nil;
    } else {
        [self.tg_noticeTopConstraint setOffset:0];
        [self.tg_noticeHeightConstraint uninstall];
        [self.tg_noticeBox mas_updateConstraints:^(MASConstraintMaker *make) {
            self.tg_noticeHeightConstraint = make.height.mas_equalTo(0);
        }];
    }

    [self.tg_detailStackBottomConstraint uninstall];
    [self.tg_detailStack mas_updateConstraints:^(MASConstraintMaker *make) {
        if (!showNotice) {
            self.tg_detailStackBottomConstraint = make.bottom.equalTo(self.tg_whiteVeil).offset(-16);
        }
    }];

    [self.tg_whiteVeilBottomConstraint uninstall];
    [self.tg_whiteVeil mas_updateConstraints:^(MASConstraintMaker *make) {
        if (showNotice) {
            self.tg_whiteVeilBottomConstraint = make.bottom.equalTo(self.tg_noticeBox.mas_bottom).offset(16);
        } else {
            self.tg_whiteVeilBottomConstraint = make.bottom.equalTo(self.tg_detailStack.mas_bottom).offset(16);
        }
    }];
}

- (void)tg_applyScrollContentSize {
    if (!self.tg_scrollPane || !self.tg_noticeBox) {
        return;
    }
    [self.tg_scrollBody layoutIfNeeded];
    CGRect noticeInScroll = [self.tg_noticeBox convertRect:self.tg_noticeBox.bounds
                                                    toView:self.tg_scrollPane];
    CGFloat contentH = ceil(CGRectGetMaxY(noticeInScroll) + kTgDetailScrollBodyBottomInset);
    if (contentH < 1) {
        return;
    }
    CGFloat contentW = CGRectGetWidth(self.tg_scrollPane.bounds);
    if (contentW < 1) {
        contentW = CGRectGetWidth(self.view.bounds);
    }
    CGSize size = CGSizeMake(contentW, contentH);
    if (fabs(self.tg_scrollPane.contentSize.height - size.height) > 1.0
        || fabs(self.tg_scrollPane.contentSize.width - size.width) > 1.0) {
        self.tg_scrollPane.contentSize = size;
    }
}

- (void)tg_updateScrollContentLayout {
    [self tg_updateWhiteVeilBottomAnchor];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    [self tg_applyScrollContentSize];
}

- (void)tg_rebuildDetailRowsWithDetail:(TgOrderDetail *)detail {
    for (UIView *v in self.tg_detailStack.arrangedSubviews) {
        [self.tg_detailStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }

    NSInteger status = detail.intellectual;
    BOOL hideRepayment = [self tg_shouldHideRepaymentRelatedForStatus:status];

    [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"Amount received"
                                                                      value:[self tg_formatPlainAmountText:detail.husband]
                                                                  tipText:kTgDetailTipAmountReceived]];
    [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"Interest"
                                                                      value:[self tg_formatPlainAmountText:detail.typist]
                                                                  tipText:kTgDetailTipInterest]];
    [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"Service fee"
                                                                      value:[self tg_formatPlainAmountText:detail.pit]
                                                                  tipText:kTgDetailTipServiceFee]];
    [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"GST"
                                                                      value:[self tg_formatPlainAmountText:detail.feather]
                                                                  tipText:nil]];

    if ([self tg_isPayoutPaymentDateStatus:status]) {
        [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"Payment date"
                                                                          value:[self tg_formatDisplayDate:detail.resident]
                                                                      tipText:nil]];
    } else {
        [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"Date of application"
                                                                          value:[self tg_formatDisplayDate:detail.tailor]
                                                                      tipText:nil]];
    }

    [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"Due date"
                                                                      value:[self tg_formatDisplayDate:detail.fierce]
                                                                  tipText:nil]];

    if (!hideRepayment && status == 61 && [self tg_shouldShowCurrencyValue:detail.means]) {
        [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"Late charge"
                                                                          value:[self tg_formatPlainAmountText:detail.means]
                                                                      tipText:nil]];
    }

    if (!hideRepayment && [self tg_shouldShowCurrencyValue:detail.nationality]) {
        [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"Total repayment"
                                                                          value:[self tg_formatPlainAmountText:detail.nationality]
                                                                      tipText:nil]];
    }

    if (!hideRepayment && [self tg_shouldShowCurrencyValue:detail.pale]) {
        [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"Amount of deduction"
                                                                          value:[self tg_formatPlainAmountText:detail.pale]
                                                                      tipText:nil]];
    }

    if (!hideRepayment && [self tg_shouldShowCurrencyValue:detail.wire]) {
        [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"Amount repaid"
                                                                          value:[self tg_formatPlainAmountText:detail.wire]
                                                                      tipText:nil]];
    }

    BOOL hasDeductionOrRepaid = [self tg_shouldShowCurrencyValue:detail.pale]
        || [self tg_shouldShowCurrencyValue:detail.wire];
    if (!hideRepayment && status != 70 && hasDeductionOrRepaid
        && [self tg_shouldShowCurrencyValue:detail.shouldRepaymentAmount]) {
        [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"Amount due"
                                                                          value:[self tg_formatPlainAmountText:detail.shouldRepaymentAmount]
                                                                      tipText:nil]];
    }

    if (!hideRepayment && status == 70 && [self tg_trimmed:detail.unity].length > 0) {
        [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"Repayment date"
                                                                          value:[self tg_formatDisplayDate:detail.unity]
                                                                      tipText:nil]];
    }

    if (detail.EMIs > 0) {
        if ([self tg_trimmed:detail.EMIRepayDate].length > 0) {
            [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"1st EMI Date"
                                                                              value:[self tg_formatDisplayDate:detail.EMIRepayDate]
                                                                          tipText:nil]];
        }
        if ([self tg_trimmed:detail.upright].length > 0) {
            NSString *emiAmt = [self tg_formatPlainAmountText:detail.upright];
            if (emiAmt.length > 0 && ![emiAmt isEqualToString:@"-"]) {
                emiAmt = [NSString stringWithFormat:@"₹ %@", emiAmt];
            }
            [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"EMI Amount"
                                                                              value:emiAmt
                                                                          tipText:nil]];
        }
        [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"EMIs"
                                                                          value:[NSString stringWithFormat:@"%ld EMIS", (long)detail.EMIs]
                                                                      tipText:nil]];
    }
}

- (void)tg_refreshNoticeWithDetail:(TgOrderDetail *)detail {
    NSString *primary = [self tg_statusTipForOrderStatus:detail.intellectual];
    if (primary.length == 0) {
        self.tg_noticeBox.hidden = YES;
        self.tg_noticeCaption.text = @"";
    } else {
        self.tg_noticeBox.hidden = NO;
        if (detail.intellectual == 60 || detail.intellectual == 61) {
            self.tg_noticeCaption.text = [NSString stringWithFormat:@"%@\n\n%@", primary, kTgDetailUpiNotice];
        } else {
            self.tg_noticeCaption.text = primary;
        }
    }
}

- (void)tg_refreshBottomButtonsWithDetail:(TgOrderDetail *)detail {
    [self tg_hideAllBottomButtons];
    if (!detail) return;

    NSInteger status = detail.intellectual;
    NSString *ifExt = [self tg_trimmed:detail.exclude];
    if (ifExt.length == 0) ifExt = @"2";

    switch (status) {
        case 10:
            [self tg_showSingleButtonWithTitle:@"Continue submitting"];
            break;
        case 32:
            [self tg_showSingleButtonWithTitle:@"Get loan"];
            break;
        case 36:
            [self tg_showSingleButtonWithTitle:@"Change Bank Account"];
            break;
        case 60:
            if ([ifExt isEqualToString:@"1"]) {
                [self tg_showDualButtons];
            } else {
                [self tg_showSingleButtonWithTitle:@"Repay"];
            }
            break;
        case 61:
            [self tg_showSingleButtonWithTitle:@"Repay"];
            break;
        default:
            break;
    }
}

- (void)tg_hideAllBottomButtons {
    self.tg_deferLatch.hidden = YES;
    self.tg_repayLatch.hidden = YES;
    self.tg_singleLatch.hidden = YES;
    self.tg_deferLatch.userInteractionEnabled = NO;
    self.tg_repayLatch.userInteractionEnabled = NO;
    self.tg_singleLatch.userInteractionEnabled = NO;
    self.tg_bottomBackdrop.hidden = YES;
    [self.tg_bottomBarHeightConstraint setOffset:0];
}

- (void)tg_showBottomBarWithDualButtons:(BOOL)dual title:(nullable NSString *)singleTitle {
    self.tg_bottomBar.hidden = NO;
    self.tg_bottomBackdrop.hidden = NO;
    [self.tg_bottomBarHeightConstraint setOffset:kTgDetailBottomBarHeight];
    self.tg_deferLatch.hidden = !dual;
    self.tg_repayLatch.hidden = !dual;
    self.tg_singleLatch.hidden = dual;
    self.tg_deferLatch.userInteractionEnabled = dual;
    self.tg_repayLatch.userInteractionEnabled = dual;
    self.tg_singleLatch.userInteractionEnabled = !dual;
    if (!dual && singleTitle.length > 0) {
        [self.tg_singleLatch setTitle:singleTitle forState:UIControlStateNormal];
    }
    [self tg_updateScrollContentLayout];
}

- (void)tg_showDualButtons {
    [self tg_showBottomBarWithDualButtons:YES title:nil];
}

- (void)tg_showSingleButtonWithTitle:(NSString *)title {
    [self tg_showBottomBarWithDualButtons:NO title:title];
}

#pragma mark - Bottom actions (§5.6)

- (NSString *)tg_resolvedOrderId {
    NSString *fromDetail = [self tg_trimmed:self.tg_detailData.hillside.interpret];
    if (fromDetail.length > 0) return fromDetail;
    NSString *fromPage = [self tg_trimmed:self.tg_orderId];
    if (fromPage.length > 0 && ![fromPage isEqualToString:@"1"]) return fromPage;
    return @"";
}

- (NSString *)tg_resolvedProductId {
    NSString *fromProduct = [self tg_trimmed:self.tg_detailData.invent.resistance];
    if (fromProduct.length > 0) return fromProduct;
    return [self tg_trimmed:self.tg_productId];
}

- (BOOL)tg_isValidRepayURLString:(NSString *)urlString {
    NSString *trim = [self tg_trimmed:urlString];
    if (trim.length == 0) return NO;
    NSString *lower = trim.lowercaseString;
    return [lower hasPrefix:@"http://"] || [lower hasPrefix:@"https://"];
}

- (void)tg_onDeferTapped {
    [self tg_requestRepayLinkExtension:YES navTitle:@"Deferment"];
}

- (void)tg_onRepayTapped {
    [self tg_requestRepayLinkExtension:NO navTitle:@"Repayment"];
}

- (void)tg_onSinglePrimaryTapped {
    TgOrderDetail *detail = self.tg_detailData.hillside;
    if (!detail) return;

    switch (detail.intellectual) {
        case 10:
            [self tg_handleContinueSubmitting];
            break;
        case 32:
            [self tg_handleGetLoan];
            break;
        case 36:
            [self tg_handleChangeBankAccount];
            break;
        case 60:
        case 61:
            [self tg_requestRepayLinkExtension:NO navTitle:@"Repayment"];
            break;
        default:
            break;
    }
}

- (void)tg_requestRepayLinkExtension:(BOOL)isExtension navTitle:(NSString *)navTitle {
    if (self.tg_actionInFlight || [TgOrderForgeRelay tg_isRunning]) return;

    NSString *orderId = [self tg_resolvedOrderId];
    if (orderId.length == 0) {
        [[TgPulseOverlay shared] whisperLine:kTgDetailMissingOrderIdHint duration:2.0];
        return;
    }

    self.tg_actionInFlight = YES;
    self.tg_deferLatch.userInteractionEnabled = NO;
    self.tg_repayLatch.userInteractionEnabled = NO;
    self.tg_singleLatch.userInteractionEnabled = NO;
    [[TgPulseOverlay shared] veilSpin];

    NSString *lane = isExtension ? TgLaneRepayExtension : TgLaneRepayConnect;
    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:lane
                             signData:@{ @"orderId": orderId }
                           nonSignData:@{ @"periodNoList": @[ @"1" ] }
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        __strong typeof(weakSelf) self = weakSelf;
        [[TgPulseOverlay shared] veilDismiss];
        self.tg_actionInFlight = NO;
        if (!self) return;
        [self tg_refreshBottomButtonsWithDetail:self.tg_detailData.hillside];
        if (envelope.cheer == 200 && envelope.trick) {
            TgRepayConnectData *data = [TgRepayConnectData yy_modelWithJSON:envelope.trick];
            NSString *connect = [self tg_trimmed:data.lest];
            if (![self tg_isValidRepayURLString:connect]) {
                [[TgPulseOverlay shared] whisperLine:connect.length > 0 ? kTgDetailInvalidLinkHint : kTgDetailNoPaymentLinkHint
                                             duration:2.0];
                return;
            }
            [self tg_openRepayWebWithURLString:connect navTitle:navTitle];
            return;
        }
        NSString *msg = [self tg_trimmed:envelope.power];
        [[TgPulseOverlay shared] whisperLine:msg.length > 0 ? msg : kTgDetailBusyHint duration:2.0];
    } failure:^{
        __strong typeof(weakSelf) self = weakSelf;
        [[TgPulseOverlay shared] veilDismiss];
        if (!self) return;
        self.tg_actionInFlight = NO;
        [self tg_refreshBottomButtonsWithDetail:self.tg_detailData.hillside];
        [[TgPulseOverlay shared] whisperLine:kTgDetailBusyHint duration:2.0];
    }];
}

- (void)tg_openRepayWebWithURLString:(NSString *)urlString navTitle:(NSString *)navTitle {
    NSURL *url = [TgPaneWebController tg_normalizedURLFromString:urlString];
    if (!url || ![self tg_isValidRepayURLString:url.absoluteString]) {
        [[TgPulseOverlay shared] whisperLine:kTgDetailInvalidLinkHint duration:2.0];
        return;
    }
    TgPaneWebController *pane = [[TgPaneWebController alloc] initWithPageURL:url navTitle:navTitle];
    pane.tg_showsBackButton = YES;
    pane.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:pane animated:YES];
}

- (void)tg_handleContinueSubmitting {
    if (self.tg_actionInFlight || [TgOrderForgeRelay tg_isRunning]) return;

    NSString *orderId = [self tg_resolvedOrderId];
    if (orderId.length == 0) {
        [[TgPulseOverlay shared] whisperLine:kTgDetailMissingOrderIdHint duration:2.0];
        return;
    }

    self.tg_actionInFlight = YES;
    self.tg_singleLatch.userInteractionEnabled = NO;

    __weak typeof(self) weakSelf = self;
    [TgOrderForgeRelay tg_resumeDataCaptureForOrderId:orderId
                                                hostVC:self
                                                origin:TgOrderForgeOriginOrderDetail
                                  allowSecondaryPrompt:YES
                                               success:^(NSString *resolvedOrderId) {
        __strong typeof(weakSelf) self = weakSelf;
        self.tg_actionInFlight = NO;
        if (!self) return;
        [self tg_refreshBottomButtonsWithDetail:self.tg_detailData.hillside];

        NSString *oid = [self tg_trimmed:resolvedOrderId];
        if (oid.length == 0) oid = orderId;

        TgOrderSuccessVaultController *successVC = [[TgOrderSuccessVaultController alloc] init];
        successVC.tg_orderId = oid;
        successVC.tg_productId = [self tg_resolvedProductId];
        successVC.tg_exitMode = TgOrderSuccessExitModeOrderDetail;
        successVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:successVC animated:YES];
    } failure:^(NSString *message) {
        __strong typeof(weakSelf) self = weakSelf;
        self.tg_actionInFlight = NO;
        if (!self) return;
        [self tg_refreshBottomButtonsWithDetail:self.tg_detailData.hillside];
        NSString *msg = [self tg_trimmed:message];
        if (msg.length > 0) {
            [[TgPulseOverlay shared] whisperLine:msg duration:2.0];
        }
    } cancelled:^{
        __strong typeof(weakSelf) self = weakSelf;
        self.tg_actionInFlight = NO;
        if (!self) return;
        [self tg_refreshBottomButtonsWithDetail:self.tg_detailData.hillside];
    }];
}

- (void)tg_handleGetLoan {
    NSString *orderId = [self tg_resolvedOrderId];
    NSString *productId = [self tg_resolvedProductId];
    if (orderId.length == 0 && productId.length == 0) {
        [[TgPulseOverlay shared] whisperLine:kTgDetailMissingIdsHint duration:2.0];
        return;
    }
    TgOrderWithdrawVaultController *withdraw = [[TgOrderWithdrawVaultController alloc] init];
    withdraw.tg_orderId = orderId.length > 0 ? orderId : nil;
    withdraw.tg_productId = productId.length > 0 ? productId : nil;
    withdraw.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:withdraw animated:YES];
}

- (void)tg_handleChangeBankAccount {
    TgBankEditVaultController *edit = [[TgBankEditVaultController alloc] init];
    edit.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:edit animated:YES];
}

#pragma mark - Detail rows

- (UIView *)tg_makeDetailRowWithTitle:(NSString *)title
                                value:(NSString *)value
                            tipText:(nullable NSString *)tipText {
    UIView *row = [[UIView alloc] init];

    UIStackView *leftStack = [[UIStackView alloc] init];
    leftStack.axis = UILayoutConstraintAxisHorizontal;
    leftStack.alignment = UIStackViewAlignmentCenter;
    leftStack.spacing = 4;

    UILabel *titleLab = [[UILabel alloc] init];
    titleLab.text = title;
    titleLab.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    titleLab.textColor = [UIColor tg_toneFromHex:kTgDetailMutedHex];
    [leftStack addArrangedSubview:titleLab];

    if (tipText.length > 0) {
        UIButton *tipBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [tipBtn setImage:[UIImage imageNamed:kTgDetailTipIconAsset] forState:UIControlStateNormal];
        tipBtn.adjustsImageWhenHighlighted = NO;
        [tipBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(16);
        }];
        objc_setAssociatedObject(tipBtn, kTgDetailTipTextKey, tipText, OBJC_ASSOCIATION_COPY_NONATOMIC);
        [tipBtn addTarget:self action:@selector(tg_onTipTapped:) forControlEvents:UIControlEventTouchUpInside];
        [leftStack addArrangedSubview:tipBtn];
    }

    UILabel *valueLab = [[UILabel alloc] init];
    valueLab.text = value.length > 0 ? value : @"-";
    valueLab.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightBold];
    valueLab.textColor = UIColor.blackColor;
    valueLab.textAlignment = NSTextAlignmentRight;
    valueLab.numberOfLines = 2;

    [row addSubview:leftStack];
    [row addSubview:valueLab];
    [leftStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.centerY.equalTo(row);
        make.right.lessThanOrEqualTo(valueLab.mas_left).offset(-8);
    }];
    [valueLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.centerY.equalTo(row);
        make.width.lessThanOrEqualTo(row).multipliedBy(0.55);
    }];
    [row mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_greaterThanOrEqualTo(kTgDetailRowHeight);
    }];
    return row;
}

#pragma mark - Tip popover

- (void)tg_onTipTapped:(UIButton *)sender {
    NSString *tip = objc_getAssociatedObject(sender, kTgDetailTipTextKey);
    if (tip.length == 0) return;

    UIFont *tipFont = [UIFont tg_meshGlyphWithSize:11 weight:UIFontWeightRegular];
    CGFloat maxW = CGRectGetWidth(self.view.bounds) * 0.72;
    CGFloat horzPad = 14;
    CGFloat vertPad = 16;
    CGRect textRect = [tip boundingRectWithSize:CGSizeMake(maxW - horzPad * 2, CGFLOAT_MAX)
                                        options:NSStringDrawingUsesLineFragmentOrigin
                                     attributes:@{NSFontAttributeName: tipFont}
                                        context:nil];
    CGFloat popH = ceil(CGRectGetHeight(textRect)) + vertPad * 2;

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
