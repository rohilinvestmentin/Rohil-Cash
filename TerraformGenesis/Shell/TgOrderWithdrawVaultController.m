//

//

#import "TgOrderWithdrawVaultController.h"
#import "TgEnvelopeBase.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"
#import "TgPulseOverlay.h"
#import "TgShardFacade.h"
#import "TgWireConduit.h"
#import "NSString+TgGlyph.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <objc/runtime.h>

static CGFloat const kTgWithdrawHorzInset = 16.0;
static CGFloat const kTgWithdrawPeachCardTopOffset = 8.0;
static CGFloat const kTgWithdrawWaveHeight = 24.0;
static CGFloat const kTgWithdrawCardRadius = 16.0;
static CGFloat const kTgWithdrawButtonHeight = 50.0;
static CGFloat const kTgWithdrawBottomBarVertPad = 8.0;
static CGFloat const kTgWithdrawBottomBarHeight = kTgWithdrawBottomBarVertPad + kTgWithdrawButtonHeight + kTgWithdrawBottomBarVertPad;
static CGFloat const kTgWithdrawScrollBodyBottomInset = 24.0;

static CGFloat const kTgWithdrawPeachFixedHeight = 200.0;
static CGFloat const kTgWithdrawProductPillHeight = 28.0;
static CGFloat const kTgWithdrawLogoCornerRadius = 4.0;
static CGFloat const kTgWithdrawStatusTopInset = 25.0;
static CGFloat const kTgWithdrawProductBottomInset = 35.0;
static CGFloat const kTgWithdrawStatusToAmountGap = 6.0;
static CGFloat const kTgWithdrawAmountStackSpacing = 6.0;
static CGFloat const kTgWithdrawMedalSize = 76.0;
static CGFloat const kTgWithdrawRowHeight = 44.0;
static CGFloat const kTgWithdrawSummaryRowHeight = 29.0;
static CGFloat const kTgWithdrawAmountArrowGap = 15.0;
static CGFloat const kTgWithdrawAmountAreaLeftInset = 16.0;

static NSString * const kTgWithdrawWaveAsset = @"use_Subtract2";
static NSString * const kTgWithdrawPeachBgAsset = @"use_bg2";
static NSString * const kTgWithdrawMedalAsset = @"use_loan_star";
static NSString * const kTgWithdrawArrowAsset = @"use_next_loan_xiao";
static NSString * const kTgWithdrawTipIconAsset = @"details";

static NSString * const kTgWithdrawPageBgHex = @"#FFFFFF";
static NSString * const kTgWithdrawSummaryBgHex = @"#FAFAFA";
static NSString * const kTgWithdrawStatusHex = @"#793200";

static NSString * const kTgWithdrawAmountHintHex = @"#9E7148";
static NSString * const kTgWithdrawAmountToneHex = @"#C51B12";
static NSString * const kTgWithdrawAmountLineHex = @"#0A0B17";
static NSString * const kTgWithdrawProductNameHex = @"#E2A369";
static NSString * const kTgWithdrawValueHex = @"#C51B12";
static NSString * const kTgWithdrawAmountHintManual = @"Please choose the loan amount yourself";
static NSString * const kTgWithdrawAmountHintSingle = @"Loan amount";
static NSString * const kTgWithdrawNoticeBgHex = @"#FFF4E8";
static NSString * const kTgWithdrawNoticeTextHex = @"#E67E22";
static NSString * const kTgWithdrawMutedHex = @"#686868";
static NSString * const kTgWithdrawDividerHex = @"#EDEDED";
static NSString * const kTgWithdrawPrimaryBtnHex = @"#182040";

static NSString * const kTgWithdrawStatusTitle = @"Pending";
static NSString * const kTgWithdrawDefaultNotice =
    @"Take action right now! Once you confirm your pending withdrawal order, we will promptly transfer the funds to your bank account.";
static NSString * const kTgWithdrawSuccessTitle = @"Success";
static NSString * const kTgWithdrawSuccessBody =
    @"Your loan has been confirmed successfully. The funds will be transferred to your bank account. Please check your bank account.";
static NSString * const kTgWithdrawSuccessBtn = @"Confirm";

static NSString * const kTgWithdrawBusyHint = @"The system is occupied. Please retry after 2 minutes.";
static NSString * const kTgWithdrawMissingIdsHint = @"Order ID or Product ID must be provided";
static NSString * const kTgWithdrawInvalidDataHint = @"Invalid data.";

static NSString * const kTgWithdrawTipAmountReceived =
    @"The amount you actually receive equals the loan amount minus the service fee and GST.";
static NSString * const kTgWithdrawTipInterest =
    @"Computed from your loan amount, loan term, and this product's interest rate.";
static NSString * const kTgWithdrawTipServiceFee =
    @"This fee is charged by the financial institution for delivering loan services.";

static const void *kTgWithdrawTipTextKey = &kTgWithdrawTipTextKey;

@interface TgOrderWithdrawVaultController () <UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong) UIScrollView *tg_scrollPane;
@property (nonatomic, strong) UIView *tg_scrollBody;
@property (nonatomic, strong) UIView *tg_mainCard;
@property (nonatomic, strong) UIView *tg_peachVeil;
@property (nonatomic, strong) UIImageView *tg_peachBgGlyph;
@property (nonatomic, strong) UILabel *tg_statusCaption;
@property (nonatomic, strong) UIStackView *tg_amountAmountStack;
@property (nonatomic, strong) UIStackView *tg_amountRowStack;
@property (nonatomic, strong) UILabel *tg_amountHintCaption;
@property (nonatomic, strong) UILabel *tg_amountValueCaption;
@property (nonatomic, strong) UIImageView *tg_amountArrowGlyph;
@property (nonatomic, strong) UIView *tg_amountUnderline;
@property (nonatomic, strong) UIButton *tg_amountTapLatch;
@property (nonatomic, strong) UIView *tg_productPill;
@property (nonatomic, strong) UIImageView *tg_logoGlyph;
@property (nonatomic, strong) UILabel *tg_nameCaption;
@property (nonatomic, strong) UIImageView *tg_medalGlyph;
@property (nonatomic, strong) UIImageView *tg_waveCap;
@property (nonatomic, strong) UIView *tg_whiteVeil;
@property (nonatomic, strong) UIView *tg_summaryCard;
@property (nonatomic, strong) UILabel *tg_termTitleCaption;
@property (nonatomic, strong) UILabel *tg_termValueCaption;
@property (nonatomic, strong) UIImageView *tg_termArrowGlyph;
@property (nonatomic, strong) UIButton *tg_termTapLatch;
@property (nonatomic, strong) UIView *tg_summaryDivider;
@property (nonatomic, strong) UILabel *tg_bankTitleCaption;
@property (nonatomic, strong) UILabel *tg_bankValueCaption;
@property (nonatomic, strong) MASConstraint *tg_summaryBankRowHeightConstraint;
@property (nonatomic, strong) MASConstraint *tg_summaryDividerHeightConstraint;
@property (nonatomic, strong) MASConstraint *tg_summaryDividerTopConstraint;
@property (nonatomic, strong) MASConstraint *tg_summaryCardBottomConstraint;
@property (nonatomic, strong) MASConstraint *tg_termTitleHeightConstraint;
@property (nonatomic, strong) MASConstraint *tg_whiteVeilBottomConstraint;
@property (nonatomic, strong) MASConstraint *tg_detailStackBottomConstraint;
@property (nonatomic, strong) MASConstraint *tg_noticeTopConstraint;
@property (nonatomic, strong) MASConstraint *tg_noticeHeightConstraint;
@property (nonatomic, strong) MASConstraint *tg_scrollContentBottomConstraint;
@property (nonatomic, strong) UIStackView *tg_detailStack;
@property (nonatomic, strong) UIView *tg_noticeBox;
@property (nonatomic, strong) UILabel *tg_noticeCaption;
@property (nonatomic, strong) UIView *tg_bottomBar;
@property (nonatomic, strong) UIView *tg_bottomBackdrop;
@property (nonatomic, strong) UIButton *tg_withdrawLatch;

@property (nonatomic, strong, nullable) TgWithdrawnOrderDetailData *tg_detailData;
@property (nonatomic, copy) NSArray<TgWithdrawnAmountDetail *> *tg_sortedAmounts;
@property (nonatomic, assign) NSInteger tg_pickedAmountIdx;
@property (nonatomic, assign) NSInteger tg_pickedTermIdx;
@property (nonatomic, assign) NSInteger tg_pickedEmiIdx;
@property (nonatomic, assign) BOOL tg_hasEmiOptions;
@property (nonatomic, assign) BOOL tg_submitting;

@end

@implementation TgOrderWithdrawVaultController

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
    self.tg_pickedAmountIdx = 0;
    self.tg_pickedTermIdx = 0;
    self.tg_pickedEmiIdx = 0;
    [self tg_buildLayout];
    [self tg_loadWithdrawDetail];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
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
    self.tg_peachVeil.layer.cornerRadius = kTgWithdrawCardRadius;
    self.tg_peachVeil.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    self.tg_peachVeil.clipsToBounds = YES;
    [self.tg_mainCard addSubview:self.tg_peachVeil];

    self.tg_peachBgGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgWithdrawPeachBgAsset]];
    self.tg_peachBgGlyph.contentMode = UIViewContentModeScaleAspectFill;
    [self.tg_peachVeil addSubview:self.tg_peachBgGlyph];

    self.tg_statusCaption = [[UILabel alloc] init];
    self.tg_statusCaption.text = kTgWithdrawStatusTitle;
    self.tg_statusCaption.font = [UIFont tg_meshGlyphWithSize:18 weight:UIFontWeightBold];
    self.tg_statusCaption.textColor = [UIColor tg_toneFromHex:kTgWithdrawStatusHex];
    self.tg_statusCaption.textAlignment = NSTextAlignmentLeft;

    self.tg_amountHintCaption = [[UILabel alloc] init];
    self.tg_amountHintCaption.text = kTgWithdrawAmountHintManual;
    self.tg_amountHintCaption.font = [UIFont tg_meshGlyphWithSize:13 weight:UIFontWeightRegular];
    self.tg_amountHintCaption.textColor = [UIColor tg_toneFromHex:kTgWithdrawAmountHintHex];
    self.tg_amountHintCaption.textAlignment = NSTextAlignmentLeft;
    self.tg_amountHintCaption.numberOfLines = 0;

    self.tg_amountValueCaption = [[UILabel alloc] init];
    self.tg_amountValueCaption.font = [UIFont tg_meshGlyphWithSize:32 weight:UIFontWeightBold];
    self.tg_amountValueCaption.textColor = [UIColor tg_toneFromHex:kTgWithdrawAmountToneHex];
    self.tg_amountValueCaption.textAlignment = NSTextAlignmentLeft;
    self.tg_amountValueCaption.adjustsFontSizeToFitWidth = YES;
    self.tg_amountValueCaption.minimumScaleFactor = 0.6;
    self.tg_amountValueCaption.text = @"-";

    self.tg_amountArrowGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgWithdrawArrowAsset]];
    self.tg_amountArrowGlyph.contentMode = UIViewContentModeScaleAspectFit;

    self.tg_amountRowStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.tg_amountValueCaption, self.tg_amountArrowGlyph
    ]];
    self.tg_amountRowStack.axis = UILayoutConstraintAxisHorizontal;
    self.tg_amountRowStack.alignment = UIStackViewAlignmentCenter;
    self.tg_amountRowStack.spacing = kTgWithdrawAmountArrowGap;

    self.tg_amountUnderline = [[UIView alloc] init];
    self.tg_amountUnderline.backgroundColor = [UIColor tg_toneFromHex:kTgWithdrawAmountLineHex];

    self.tg_amountAmountStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.tg_amountHintCaption,
        self.tg_amountRowStack,
        self.tg_amountUnderline
    ]];
    self.tg_amountAmountStack.axis = UILayoutConstraintAxisVertical;
    self.tg_amountAmountStack.alignment = UIStackViewAlignmentLeading;
    self.tg_amountAmountStack.spacing = kTgWithdrawAmountStackSpacing;

    [self.tg_peachVeil addSubview:self.tg_statusCaption];
    [self.tg_peachVeil addSubview:self.tg_amountAmountStack];

    self.tg_amountTapLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_amountTapLatch addTarget:self action:@selector(tg_onAmountRowTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.tg_peachVeil addSubview:self.tg_amountTapLatch];

    self.tg_productPill = [[UIView alloc] init];
    [self.tg_peachVeil addSubview:self.tg_productPill];

    self.tg_logoGlyph = [[UIImageView alloc] init];
    self.tg_logoGlyph.contentMode = UIViewContentModeScaleAspectFit;
    self.tg_logoGlyph.layer.cornerRadius = kTgWithdrawLogoCornerRadius;
    self.tg_logoGlyph.clipsToBounds = YES;
    [self.tg_productPill addSubview:self.tg_logoGlyph];

    self.tg_nameCaption = [[UILabel alloc] init];
    self.tg_nameCaption.font = [UIFont tg_meshGlyphWithSize:13 weight:UIFontWeightBold];
    self.tg_nameCaption.textColor = [UIColor tg_toneFromHex:kTgWithdrawProductNameHex];
    [self.tg_productPill addSubview:self.tg_nameCaption];

    self.tg_medalGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgWithdrawMedalAsset]];
    self.tg_medalGlyph.contentMode = UIViewContentModeScaleAspectFit;
    [self.tg_peachVeil addSubview:self.tg_medalGlyph];

    self.tg_whiteVeil = [[UIView alloc] init];
    self.tg_whiteVeil.backgroundColor = [UIColor tg_toneFromHex:kTgWithdrawPageBgHex];
    [self.tg_scrollBody addSubview:self.tg_whiteVeil];

    self.tg_waveCap = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgWithdrawWaveAsset]];
    self.tg_waveCap.contentMode = UIViewContentModeScaleToFill;
    [self.tg_scrollBody addSubview:self.tg_waveCap];

    self.tg_summaryCard = [[UIView alloc] init];
    self.tg_summaryCard.backgroundColor = [UIColor tg_toneFromHex:kTgWithdrawSummaryBgHex];
    self.tg_summaryCard.layer.cornerRadius = kTgWithdrawCardRadius;
    self.tg_summaryCard.clipsToBounds = YES;

    self.tg_termTitleCaption = [[UILabel alloc] init];
    self.tg_termTitleCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    self.tg_termTitleCaption.textColor = [UIColor tg_toneFromHex:kTgWithdrawMutedHex];

    self.tg_termValueCaption = [[UILabel alloc] init];
    self.tg_termValueCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightBold];
    self.tg_termValueCaption.textColor = [UIColor tg_toneFromHex:kTgWithdrawValueHex];
    self.tg_termValueCaption.textAlignment = NSTextAlignmentRight;

    self.tg_termArrowGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgWithdrawArrowAsset]];
    self.tg_termArrowGlyph.contentMode = UIViewContentModeScaleAspectFit;
    self.tg_termArrowGlyph.hidden = YES;

    self.tg_termTapLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    self.tg_termTapLatch.hidden = YES;
    [self.tg_termTapLatch addTarget:self action:@selector(tg_onTermRowTapped) forControlEvents:UIControlEventTouchUpInside];

    self.tg_summaryDivider = [[UIView alloc] init];
    self.tg_summaryDivider.backgroundColor = [UIColor tg_toneFromHex:kTgWithdrawDividerHex];

    self.tg_bankTitleCaption = [[UILabel alloc] init];
    self.tg_bankTitleCaption.text = @"Bank account number";
    self.tg_bankTitleCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    self.tg_bankTitleCaption.textColor = [UIColor tg_toneFromHex:kTgWithdrawMutedHex];

    self.tg_bankValueCaption = [[UILabel alloc] init];
    self.tg_bankValueCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightBold];
    self.tg_bankValueCaption.textColor = [UIColor tg_toneFromHex:kTgWithdrawValueHex];
    self.tg_bankValueCaption.textAlignment = NSTextAlignmentRight;
    self.tg_bankValueCaption.text = @"-";

    [self.tg_summaryCard addSubview:self.tg_termTitleCaption];
    [self.tg_summaryCard addSubview:self.tg_termValueCaption];
    [self.tg_summaryCard addSubview:self.tg_termArrowGlyph];
    [self.tg_summaryCard addSubview:self.tg_termTapLatch];
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
    self.tg_noticeBox.backgroundColor = [UIColor tg_toneFromHex:kTgWithdrawNoticeBgHex];
    self.tg_noticeBox.layer.cornerRadius = 8;
    self.tg_noticeBox.clipsToBounds = YES;
    [self.tg_whiteVeil addSubview:self.tg_noticeBox];

    self.tg_noticeCaption = [[UILabel alloc] init];
    self.tg_noticeCaption.font = [UIFont tg_meshGlyphWithSize:13 weight:UIFontWeightRegular];
    self.tg_noticeCaption.textColor = [UIColor tg_toneFromHex:kTgWithdrawNoticeTextHex];
    self.tg_noticeCaption.numberOfLines = 0;
    self.tg_noticeCaption.text = kTgWithdrawDefaultNotice;
    [self.tg_noticeBox addSubview:self.tg_noticeCaption];

    self.tg_withdrawLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_withdrawLatch setTitle:@"Get loan" forState:UIControlStateNormal];
    [self.tg_withdrawLatch setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.tg_withdrawLatch.titleLabel.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    self.tg_withdrawLatch.backgroundColor = [UIColor tg_toneFromHex:kTgWithdrawPrimaryBtnHex];
    self.tg_withdrawLatch.layer.cornerRadius = kTgWithdrawButtonHeight / 2.0;
    self.tg_withdrawLatch.clipsToBounds = YES;
    [self.tg_withdrawLatch addTarget:self action:@selector(tg_onWithdrawTapped) forControlEvents:UIControlEventTouchUpInside];

    self.tg_bottomBar = [[UIView alloc] init];
    self.tg_bottomBar.backgroundColor = UIColor.clearColor;
    [self.tg_bottomBar addSubview:self.tg_withdrawLatch];

    self.tg_bottomBackdrop = [[UIView alloc] init];
    self.tg_bottomBackdrop.backgroundColor = [UIColor tg_toneFromHex:kTgWithdrawPageBgHex];
    [self.view addSubview:self.tg_bottomBackdrop];
    [self.view addSubview:self.tg_bottomBar];
    [self.view bringSubviewToFront:self.tg_bottomBackdrop];
    [self.view bringSubviewToFront:self.tg_bottomBar];

    [self.tg_bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        make.height.mas_equalTo(kTgWithdrawBottomBarHeight);
    }];
    [self.tg_withdrawLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_bottomBar).offset(kTgWithdrawHorzInset);
        make.right.equalTo(self.tg_bottomBar).offset(-kTgWithdrawHorzInset);
        make.top.equalTo(self.tg_bottomBar).offset(kTgWithdrawBottomBarVertPad);
        make.height.mas_equalTo(kTgWithdrawButtonHeight);
    }];
    [self.tg_scrollPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset([self tg_contentTopBelowNavigation]);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.tg_bottomBar.mas_top);
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
        make.top.equalTo(self.tg_scrollBody).offset(kTgWithdrawPeachCardTopOffset);
        make.left.right.equalTo(self.tg_scrollBody).inset(kTgWithdrawHorzInset);
        make.bottom.equalTo(self.tg_peachVeil);
    }];
    [self.tg_peachVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.tg_mainCard);
        make.height.mas_equalTo(kTgWithdrawPeachFixedHeight);
    }];
    [self.tg_peachBgGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_peachVeil);
    }];
    [self.tg_statusCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_peachVeil).offset(kTgWithdrawStatusTopInset);
        make.left.equalTo(self.tg_peachVeil).offset(kTgWithdrawAmountAreaLeftInset);
        make.right.lessThanOrEqualTo(self.tg_medalGlyph.mas_left).offset(-8);
    }];
    [self.tg_amountAmountStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_statusCaption.mas_bottom).offset(kTgWithdrawStatusToAmountGap);
        make.left.equalTo(self.tg_peachVeil).offset(kTgWithdrawAmountAreaLeftInset);
        make.right.lessThanOrEqualTo(self.tg_medalGlyph.mas_left).offset(-8);
    }];
    [self.tg_amountArrowGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(16);
    }];
    [self.tg_amountUnderline mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(1);
        make.width.equalTo(self.tg_amountRowStack);
    }];
    [self.tg_amountTapLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.tg_amountAmountStack);
        make.top.equalTo(self.tg_amountHintCaption);
        make.bottom.equalTo(self.tg_amountUnderline);
    }];
    [self.tg_productPill mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_peachVeil).offset(kTgWithdrawAmountAreaLeftInset);
        make.height.mas_equalTo(kTgWithdrawProductPillHeight);
        make.bottom.equalTo(self.tg_peachVeil).offset(-kTgWithdrawProductBottomInset);
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
        make.centerY.equalTo(self.tg_peachVeil);
        make.width.height.mas_equalTo(kTgWithdrawMedalSize);
    }];
    [self.tg_waveCap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.tg_peachVeil.mas_bottom);
        make.height.mas_equalTo(kTgWithdrawWaveHeight);
    }];
    [self.tg_whiteVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.tg_waveCap.mas_bottom);
        self.tg_whiteVeilBottomConstraint = make.bottom.equalTo(self.tg_noticeBox.mas_bottom).offset(16);
    }];
    [self.tg_summaryCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_waveCap.mas_bottom).offset(16);
        make.left.right.equalTo(self.tg_scrollBody).inset(kTgWithdrawHorzInset);
        self.tg_summaryCardBottomConstraint = make.bottom.equalTo(self.tg_termTitleCaption.mas_bottom).offset(12);
    }];
    [self.tg_termTitleCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_summaryCard).offset(16);
        make.top.equalTo(self.tg_summaryCard).offset(12);
        self.tg_termTitleHeightConstraint = make.height.mas_equalTo(kTgWithdrawSummaryRowHeight);
    }];
    [self.tg_termArrowGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.tg_termTitleCaption);
        make.right.equalTo(self.tg_summaryCard).offset(-16);
        make.width.height.mas_equalTo(16);
    }];
    [self.tg_termValueCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.tg_termTitleCaption);
        make.right.equalTo(self.tg_termArrowGlyph.mas_left).offset(-4);
        make.left.greaterThanOrEqualTo(self.tg_termTitleCaption.mas_right).offset(8);
    }];
    [self.tg_termTapLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.tg_summaryCard);
        make.top.bottom.equalTo(self.tg_termTitleCaption);
    }];
    [self.tg_summaryDivider mas_makeConstraints:^(MASConstraintMaker *make) {
        self.tg_summaryDividerTopConstraint = make.top.equalTo(self.tg_termTitleCaption.mas_bottom).offset(12);
        make.left.right.equalTo(self.tg_summaryCard).inset(16);
        self.tg_summaryDividerHeightConstraint = make.height.mas_equalTo(1);
    }];
    [self.tg_bankTitleCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_summaryDivider.mas_bottom).offset(12);
        make.left.equalTo(self.tg_summaryCard).offset(16);
        self.tg_summaryBankRowHeightConstraint = make.height.mas_equalTo(kTgWithdrawSummaryRowHeight);
    }];
    [self.tg_bankValueCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.tg_bankTitleCaption);
        make.right.equalTo(self.tg_summaryCard).offset(-16);
        make.left.greaterThanOrEqualTo(self.tg_bankTitleCaption.mas_right).offset(8);
    }];
    [self.tg_detailStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_summaryCard.mas_bottom).offset(8);
        make.left.right.equalTo(self.tg_scrollBody).inset(kTgWithdrawHorzInset);
    }];
    [self.tg_noticeBox mas_makeConstraints:^(MASConstraintMaker *make) {
        self.tg_noticeTopConstraint = make.top.equalTo(self.tg_detailStack.mas_bottom).offset(12);
        make.left.right.equalTo(self.tg_scrollBody).inset(kTgWithdrawHorzInset);
        self.tg_noticeHeightConstraint = make.height.mas_equalTo(0).priority(MASLayoutPriorityDefaultLow);
        self.tg_scrollContentBottomConstraint =
            make.bottom.equalTo(self.tg_scrollBody).offset(-kTgWithdrawScrollBodyBottomInset);
    }];
    [self.tg_noticeCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_noticeBox).insets(UIEdgeInsetsMake(10, 12, 10, 12));
    }];

    [self.tg_scrollBody bringSubviewToFront:self.tg_waveCap];
}

#pragma mark - Helpers

- (NSString *)tg_trimmed:(NSString *)text {
    return [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
}

- (NSString *)tg_displayOrDash:(NSString *)text {
    NSString *trim = [self tg_trimmed:text];
    return trim.length > 0 ? trim : @"-";
}

- (NSInteger)tg_integerFromString:(NSString *)raw {
    NSString *trim = [self tg_trimmed:raw];
    if (trim.length == 0) return 0;
    return (NSInteger)trim.longLongValue;
}

- (NSInteger)tg_emiCountFromTerm:(TgWithdrawnTermDetail *)term {
    return [self tg_integerFromString:term.EMIs];
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
    return [NSString stringWithFormat:@"₹%@", [NSString tg_weaveIndianDigits:digits]];
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

- (BOOL)tg_shouldShowInterest:(NSString *)raw {
    NSString *trim = [self tg_trimmed:raw];
    if (trim.length == 0) return NO;
    return [trim doubleValue] != 0.0;
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

- (NSString *)tg_appDisplayName {
    NSString *name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    name = [self tg_trimmed:name];
    if (name.length > 0) return name;
    name = [self tg_trimmed:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]];
    return name.length > 0 ? name : @"App";
}

- (NSString *)tg_resolvedOrderId {
    NSString *fromApi = [self tg_trimmed:self.tg_detailData.interpret];
    if (fromApi.length > 0) return fromApi;
    return [self tg_trimmed:self.tg_orderId];
}

#pragma mark - Sort / Access

- (NSArray<TgWithdrawnAmountDetail *> *)tg_sortAmountList:(NSArray<TgWithdrawnAmountDetail *> *)list {
    return [list sortedArrayUsingComparator:^NSComparisonResult(TgWithdrawnAmountDetail *a, TgWithdrawnAmountDetail *b) {
        NSInteger av = [self tg_integerFromString:a.inch];
        NSInteger bv = [self tg_integerFromString:b.inch];
        if (av == bv) return NSOrderedSame;
        return av > bv ? NSOrderedAscending : NSOrderedDescending;
    }];
}

- (NSArray<TgWithdrawnTermDetail *> *)tg_sortTermList:(NSArray<TgWithdrawnTermDetail *> *)list {
    return [list sortedArrayUsingComparator:^NSComparisonResult(TgWithdrawnTermDetail *a, TgWithdrawnTermDetail *b) {
        NSInteger av = a.ill > 0 ? a.ill : a.culture;
        NSInteger bv = b.ill > 0 ? b.ill : b.culture;
        if (av == bv) return NSOrderedSame;
        return av < bv ? NSOrderedAscending : NSOrderedDescending;
    }];
}

- (TgWithdrawnAmountDetail *)tg_activeAmount {
    if (self.tg_pickedAmountIdx < 0 || self.tg_pickedAmountIdx >= (NSInteger)self.tg_sortedAmounts.count) {
        return nil;
    }
    return self.tg_sortedAmounts[self.tg_pickedAmountIdx];
}

- (NSArray<TgWithdrawnTermDetail *> *)tg_sortedTermsForActiveAmount {
    TgWithdrawnAmountDetail *amount = [self tg_activeAmount];
    if (!amount.eighth.count) return @[];
    return [self tg_sortTermList:amount.eighth];
}

- (TgWithdrawnTermDetail *)tg_activeTerm {
    NSArray<TgWithdrawnTermDetail *> *terms = [self tg_sortedTermsForActiveAmount];
    if (terms.count == 0) return nil;
    if (self.tg_hasEmiOptions) {
        if (self.tg_pickedEmiIdx < 0 || self.tg_pickedEmiIdx >= (NSInteger)terms.count) {
            return terms.firstObject;
        }
        return terms[self.tg_pickedEmiIdx];
    }
    if (self.tg_pickedTermIdx < 0 || self.tg_pickedTermIdx >= (NSInteger)terms.count) {
        return terms.firstObject;
    }
    return terms[self.tg_pickedTermIdx];
}

- (void)tg_detectEmiAvailability {
    self.tg_hasEmiOptions = NO;
    TgWithdrawnAmountDetail *amount = [self tg_activeAmount];
    for (TgWithdrawnTermDetail *t in amount.eighth) {
        if ([self tg_emiCountFromTerm:t] > 0) {
            self.tg_hasEmiOptions = YES;
            break;
        }
    }
}

- (BOOL)tg_hasValidSelection {
    return [self tg_activeAmount] != nil && [self tg_activeTerm] != nil;
}

- (BOOL)tg_isAmountRowSelectable {
    if (self.tg_sortedAmounts.count > 1) return YES;
    return [self tg_sortedTermsForActiveAmount].count > 1;
}

#pragma mark - Network

- (void)tg_loadWithdrawDetail {
    NSString *orderId = [self tg_trimmed:self.tg_orderId];
    NSString *productId = [self tg_trimmed:self.tg_productId];
    if (orderId.length == 0 && productId.length == 0) {
        [[TgPulseOverlay shared] whisperLine:kTgWithdrawMissingIdsHint duration:2.0];
        return;
    }

    NSString *signOrderId = orderId.length > 0 ? orderId : @"1";
    NSMutableDictionary *nonSign = [NSMutableDictionary dictionaryWithObject:@"DC" forKey:@"appType"];
    if (productId.length > 0) {
        nonSign[@"productId"] = productId;
    }

    [[TgPulseOverlay shared] veilSpin];
    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneWithdrawnDetail
                             signData:@{ @"orderId": signOrderId }
                           nonSignData:nonSign
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        __strong typeof(weakSelf) self = weakSelf;
        [[TgPulseOverlay shared] veilDismiss];
        if (!self) return;
        if (envelope.cheer == 200 && envelope.trick) {
            TgWithdrawnOrderDetailData *data = [TgWithdrawnOrderDetailData yy_modelWithJSON:envelope.trick];
            [self tg_applyDetailData:data];
            return;
        }
        NSString *msg = [self tg_trimmed:envelope.power];
        [[TgPulseOverlay shared] whisperLine:msg.length > 0 ? msg : kTgWithdrawBusyHint duration:2.0];
    } failure:^{
        [[TgPulseOverlay shared] veilDismiss];
        [[TgPulseOverlay shared] whisperLine:kTgWithdrawBusyHint duration:2.0];
    }];
}

- (void)tg_applyDetailData:(TgWithdrawnOrderDetailData *)data {
    if (!data) {
        [[TgPulseOverlay shared] whisperLine:kTgWithdrawInvalidDataHint duration:2.0];
        return;
    }
    self.tg_detailData = data;

    NSString *apiOrderId = [self tg_trimmed:data.interpret];
    if (apiOrderId.length > 0) {
        self.tg_orderId = apiOrderId;
    }

    NSMutableArray<TgWithdrawnAmountDetail *> *filtered = [NSMutableArray array];
    for (TgWithdrawnAmountDetail *item in data.nonsense) {
        if (item.eighth.count > 0) {
            [filtered addObject:item];
        }
    }
    if (filtered.count == 0) {
        self.tg_sortedAmounts = @[];
        self.tg_withdrawLatch.enabled = NO;
        [[TgPulseOverlay shared] whisperLine:kTgWithdrawInvalidDataHint duration:2.0];
        [self tg_refreshEntireDisplay];
        return;
    }

    self.tg_sortedAmounts = [self tg_sortAmountList:filtered];
    self.tg_pickedAmountIdx = 0;
    self.tg_pickedTermIdx = 0;
    self.tg_pickedEmiIdx = 0;
    [self tg_detectEmiAvailability];
    self.tg_withdrawLatch.enabled = YES;
    [self tg_refreshEntireDisplay];
}

#pragma mark - Refresh UI

- (void)tg_refreshEntireDisplay {
    [self tg_refreshProductHeader];
    [self tg_refreshAmountSection];
    [self tg_refreshBankRow];
    [self tg_refreshTermRow];
    [self tg_rebuildDetailRows];
    [self tg_refreshNotice];
    [self tg_updateScrollContentLayout];
}

- (void)tg_refreshProductHeader {
    TgWithdrawnOrderDetailData *data = self.tg_detailData;
    NSString *productName = [self tg_trimmed:data.other];
    self.tg_nameCaption.text = productName.length > 0 ? productName : [self tg_appDisplayName];

    NSString *logoURL = [self tg_trimmed:data.green];
    if (logoURL.length > 0) {
        [self.tg_logoGlyph sd_setImageWithURL:[NSURL URLWithString:logoURL] placeholderImage:nil];
    } else {
        [self.tg_logoGlyph sd_cancelCurrentImageLoad];
        self.tg_logoGlyph.image = nil;
    }
}

- (void)tg_refreshAmountSection {
    TgWithdrawnAmountDetail *amount = [self tg_activeAmount];
    NSString *digits = [self tg_digitsFromAmount:amount.inch];
    self.tg_amountValueCaption.text = digits.length > 0
        ? [NSString stringWithFormat:@"₹%@", [NSString tg_weaveIndianDigits:digits]]
        : @"-";

    BOOL hasAmount = amount != nil;
    BOOL multiAmount = self.tg_sortedAmounts.count > 1;
    BOOL selectable = [self tg_isAmountRowSelectable];
    self.tg_amountHintCaption.text = multiAmount ? kTgWithdrawAmountHintManual : kTgWithdrawAmountHintSingle;
    self.tg_amountHintCaption.hidden = !hasAmount;
    self.tg_amountArrowGlyph.hidden = !selectable;
    self.tg_amountUnderline.hidden = !hasAmount;
    self.tg_amountTapLatch.hidden = !selectable;
    self.tg_amountTapLatch.userInteractionEnabled = selectable;
}

- (void)tg_refreshTermRow {
    NSArray<TgWithdrawnTermDetail *> *terms = [self tg_sortedTermsForActiveAmount];
    TgWithdrawnTermDetail *term = [self tg_activeTerm];
    BOOL showTermRow = terms.count > 0;

    self.tg_termTitleCaption.hidden = !showTermRow;
    self.tg_termValueCaption.hidden = !showTermRow;
    self.tg_termArrowGlyph.hidden = YES;
    self.tg_termTapLatch.hidden = YES;
    self.tg_termTapLatch.userInteractionEnabled = NO;
    self.tg_summaryDivider.hidden = !showTermRow;

    if (!showTermRow) {
        [self.tg_termTitleHeightConstraint setOffset:0];
        [self.tg_summaryDividerTopConstraint setOffset:0];
        [self.tg_summaryDividerHeightConstraint setOffset:0];
        [self tg_updateSummaryCardBottomWithBankVisible:[self tg_trimmed:self.tg_bankValueCaption.text].length > 0
                                          showTermRow:NO];
        return;
    }

    [self.tg_termTitleHeightConstraint setOffset:kTgWithdrawSummaryRowHeight];
    [self.tg_summaryDividerTopConstraint setOffset:12];
    [self.tg_summaryDividerHeightConstraint setOffset:1];

    if (self.tg_hasEmiOptions) {
        self.tg_termTitleCaption.text = @"Select EMIs";
        self.tg_termValueCaption.text = [self tg_formatEmiLabel:[self tg_emiCountFromTerm:term]];
        BOOL multiEmi = terms.count > 1;
        self.tg_termArrowGlyph.hidden = !multiEmi;
        self.tg_termTapLatch.hidden = !multiEmi;
        self.tg_termTapLatch.userInteractionEnabled = multiEmi;
    } else if (terms.count > 1) {
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

    [self tg_updateSummaryCardBottomWithBankVisible:YES showTermRow:YES];
}

- (void)tg_updateSummaryCardBottomWithBankVisible:(BOOL)showBank showTermRow:(BOOL)showTermRow {
    TgWithdrawnBankCard *card = self.tg_detailData.superior.firstObject;
    NSString *accountNo = [self tg_trimmed:card.measure];
    BOOL hasBank = showBank && accountNo.length > 0;
    self.tg_summaryDivider.hidden = !showTermRow || !hasBank;
    self.tg_bankTitleCaption.hidden = !hasBank;
    self.tg_bankValueCaption.hidden = !hasBank;

    if (!hasBank) {
        [self.tg_summaryDividerTopConstraint setOffset:showTermRow ? 12 : 0];
        [self.tg_summaryDividerHeightConstraint setOffset:showTermRow ? 1 : 0];
        [self.tg_summaryBankRowHeightConstraint setOffset:0];
    } else {
        [self.tg_summaryDividerTopConstraint setOffset:12];
        [self.tg_summaryDividerHeightConstraint setOffset:1];
        [self.tg_summaryBankRowHeightConstraint setOffset:kTgWithdrawSummaryRowHeight];
    }

    [self.tg_summaryCardBottomConstraint uninstall];
    [self.tg_summaryCard mas_updateConstraints:^(MASConstraintMaker *make) {
        if (hasBank) {
            self.tg_summaryCardBottomConstraint = make.bottom.equalTo(self.tg_bankTitleCaption.mas_bottom).offset(12);
        } else if (showTermRow) {
            self.tg_summaryCardBottomConstraint = make.bottom.equalTo(self.tg_termTitleCaption.mas_bottom).offset(12);
        } else {
            self.tg_summaryCardBottomConstraint = make.bottom.equalTo(self.tg_summaryCard.mas_top);
        }
    }];
}

- (void)tg_refreshBankRow {
    TgWithdrawnBankCard *card = self.tg_detailData.superior.firstObject;
    NSString *accountNo = [self tg_trimmed:card.measure];
    if (accountNo.length > 0) {
        self.tg_bankValueCaption.text = [self tg_formatBankAccountDisplay:accountNo];
    } else {
        self.tg_bankValueCaption.text = @"-";
    }
}

- (void)tg_refreshNotice {
    NSString *msg = [self tg_trimmed:self.tg_detailData.message];
    self.tg_noticeCaption.text = msg.length > 0 ? msg : kTgWithdrawDefaultNotice;
    self.tg_noticeBox.hidden = NO;
}

- (NSString *)tg_formatDaysFromTerm:(TgWithdrawnTermDetail *)term {
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

- (void)tg_rebuildDetailRows {
    for (UIView *v in self.tg_detailStack.arrangedSubviews) {
        [self.tg_detailStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }

    TgWithdrawnTermDetail *term = [self tg_activeTerm];
    if (!term) return;

    [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"Amount received"
                                                                     value:[self tg_formatPlainAmountText:term.minority]
                                                                 tipText:kTgWithdrawTipAmountReceived]];
    [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"Service fee"
                                                                     value:[self tg_formatPlainAmountText:term.pit]
                                                                 tipText:kTgWithdrawTipServiceFee]];
    if ([self tg_shouldShowInterest:term.typist]) {
        [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"Interest"
                                                                         value:[self tg_formatPlainAmountText:term.typist]
                                                                     tipText:kTgWithdrawTipInterest]];
    }
    [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"GST"
                                                                     value:[self tg_formatPlainAmountText:term.feather]
                                                                 tipText:nil]];
    [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"Date of application"
                                                                     value:[self tg_formatDisplayDate:term.postage]
                                                                 tipText:nil]];
    [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"Due date"
                                                                     value:[self tg_formatDisplayDate:term.unity]
                                                                 tipText:nil]];

    BOOL emiMode = [self tg_trimmed:term.EMIs].length > 0 && [self tg_trimmed:term.upright].length > 0;
    if (emiMode) {
        if ([self tg_trimmed:term.EMIRepayDate].length > 0) {
            [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"1st EMI Date"
                                                                             value:[self tg_formatDisplayDate:term.EMIRepayDate]
                                                                         tipText:nil]];
        }
        NSString *emiAmt = [self tg_formatPlainAmountText:term.upright];
        if (![emiAmt isEqualToString:@"-"]) {
            emiAmt = [NSString stringWithFormat:@"₹ %@", emiAmt];
        }
        [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"EMI Amount"
                                                                         value:emiAmt
                                                                     tipText:nil]];
    }
}

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
    titleLab.textColor = [UIColor tg_toneFromHex:kTgWithdrawMutedHex];
    [leftStack addArrangedSubview:titleLab];

    if (tipText.length > 0) {
        UIButton *tipBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [tipBtn setImage:[UIImage imageNamed:kTgWithdrawTipIconAsset] forState:UIControlStateNormal];
        tipBtn.adjustsImageWhenHighlighted = NO;
        [tipBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(16);
        }];
        objc_setAssociatedObject(tipBtn, kTgWithdrawTipTextKey, tipText, OBJC_ASSOCIATION_COPY_NONATOMIC);
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
        make.height.mas_greaterThanOrEqualTo(kTgWithdrawRowHeight);
    }];
    return row;
}

#pragma mark - Scroll

- (void)tg_updateWhiteVeilBottomAnchor {
    BOOL showNotice = !self.tg_noticeBox.hidden;

    if (showNotice) {
        [self.tg_noticeTopConstraint setOffset:12];
        [self.tg_noticeHeightConstraint uninstall];
        self.tg_noticeHeightConstraint = nil;
    } else {
        [self.tg_noticeTopConstraint setOffset:0];
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
    if (!self.tg_scrollPane || !self.tg_noticeBox) return;
    [self.tg_scrollBody layoutIfNeeded];
    CGRect noticeInScroll = [self.tg_noticeBox convertRect:self.tg_noticeBox.bounds toView:self.tg_scrollPane];
    CGFloat contentH = ceil(CGRectGetMaxY(noticeInScroll) + kTgWithdrawScrollBodyBottomInset);
    if (contentH < 1) return;
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

#pragma mark - Selection

- (void)tg_onAmountRowTapped {
    if (self.tg_sortedAmounts.count > 1) {
        [self tg_presentAmountPicker];
        return;
    }
    if ([self tg_sortedTermsForActiveAmount].count > 1) {
        [self tg_onTermRowTapped];
    }
}

- (void)tg_presentAmountPicker {
    NSMutableArray<NSString *> *options = [NSMutableArray array];
    for (TgWithdrawnAmountDetail *a in self.tg_sortedAmounts) {
        [options addObject:[self tg_formatLoanAmountText:a.inch]];
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
    NSArray<TgWithdrawnTermDetail *> *terms = [self tg_sortedTermsForActiveAmount];
    if (terms.count <= 1) return;

    if (self.tg_hasEmiOptions) {
        NSMutableArray<NSString *> *options = [NSMutableArray array];
        NSMutableArray<NSNumber *> *termIndices = [NSMutableArray array];
        NSInteger selectedPickerIdx = 0;
        for (NSInteger i = 0; i < (NSInteger)terms.count; i++) {
            TgWithdrawnTermDetail *t = terms[i];
            if ([self tg_emiCountFromTerm:t] > 0) {
                if (i == self.tg_pickedEmiIdx) {
                    selectedPickerIdx = (NSInteger)options.count;
                }
                [options addObject:[self tg_formatEmiLabel:[self tg_emiCountFromTerm:t]]];
                [termIndices addObject:@(i)];
            }
        }
        if (options.count <= 1) return;
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
            [self tg_refreshEntireDisplay];
        }];
        return;
    }

    NSMutableArray<NSString *> *options = [NSMutableArray array];
    for (TgWithdrawnTermDetail *t in terms) {
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
        [self tg_refreshEntireDisplay];
    }];
}

#pragma mark - Withdraw submit

- (NSString *)tg_loanTermStringForTerm:(TgWithdrawnTermDetail *)term {
    if (!term) return @"";
    if (term.culture > 0) {
        return [NSString stringWithFormat:@"%ld", (long)term.culture];
    }
    if (term.ill > 0) {
        return [NSString stringWithFormat:@"%ld", (long)term.ill];
    }
    return @"";
}

- (void)tg_onWithdrawTapped {
    if (self.tg_submitting) return;
    if (![self tg_hasValidSelection]) {
        [[TgPulseOverlay shared] whisperLine:kTgWithdrawInvalidDataHint duration:2.0];
        return;
    }

    NSString *orderId = [self tg_resolvedOrderId];
    if (orderId.length == 0) {
        [[TgPulseOverlay shared] whisperLine:kTgWithdrawMissingIdsHint duration:2.0];
        return;
    }

    TgWithdrawnAmountDetail *amount = [self tg_activeAmount];
    TgWithdrawnTermDetail *term = [self tg_activeTerm];
    NSString *loanAmount = [self tg_trimmed:amount.inch];
    NSString *loanTerm = [self tg_loanTermStringForTerm:term];
    if (loanAmount.length == 0 || loanTerm.length == 0) {
        [[TgPulseOverlay shared] whisperLine:kTgWithdrawInvalidDataHint duration:2.0];
        return;
    }

    self.tg_submitting = YES;
    self.tg_withdrawLatch.enabled = NO;
    [[TgPulseOverlay shared] veilSpin];

    NSDictionary *nonSign = @{
        @"loanAmount": loanAmount,
        @"loanTerm": loanTerm
    };

    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneApplyWithdrawal
                             signData:@{ @"orderId": orderId }
                           nonSignData:nonSign
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        __strong typeof(weakSelf) self = weakSelf;
        [[TgPulseOverlay shared] veilDismiss];
        if (!self) return;
        self.tg_submitting = NO;
        self.tg_withdrawLatch.enabled = YES;
        if (envelope.cheer == 200) {
            [self tg_showWithdrawSuccessPanel];
            return;
        }
        NSString *msg = [self tg_trimmed:envelope.power];
        [[TgPulseOverlay shared] whisperLine:msg.length > 0 ? msg : kTgWithdrawBusyHint duration:2.0];
    } failure:^{
        __strong typeof(weakSelf) self = weakSelf;
        [[TgPulseOverlay shared] veilDismiss];
        if (!self) return;
        self.tg_submitting = NO;
        self.tg_withdrawLatch.enabled = YES;
        [[TgPulseOverlay shared] whisperLine:kTgWithdrawBusyHint duration:2.0];
    }];
}

- (void)tg_showWithdrawSuccessPanel {
    TgShardPanelConfig *cfg = [[TgShardPanelConfig alloc] init];
    cfg.panelStyle = TgShardPanelStyleText;
    cfg.title = kTgWithdrawSuccessTitle;
    cfg.content = kTgWithdrawSuccessBody;
    cfg.primaryTitle = kTgWithdrawSuccessBtn;
    cfg.dismissOnPrimaryAction = YES;
    cfg.tier = TgShardTierHigh;
    __weak typeof(self) weakSelf = self;
    cfg.primaryAction = ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        UINavigationController *nav = self.navigationController;
        if (nav.viewControllers.count > 1) {
            [nav popViewControllerAnimated:YES];
        } else {
            [nav dismissViewControllerAnimated:YES completion:nil];
        }
    };
    [[TgShardFacade shared] showPanel:cfg];
}

#pragma mark - Tip popover

- (void)tg_onTipTapped:(UIButton *)sender {
    NSString *tip = objc_getAssociatedObject(sender, kTgWithdrawTipTextKey);
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
