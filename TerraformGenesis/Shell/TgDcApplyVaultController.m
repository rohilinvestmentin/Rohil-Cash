//
//  TgDcApplyVaultController.m
//

#import "TgDcApplyVaultController.h"
#import "TgDockBarRelay.h"
#import "TgEnvelopeBase.h"
#import "TgOrderForgeRelay.h"
#import "TgOrderSuccessVaultController.h"
#import "TgPaneWebController.h"
#import "TgPureLinks.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"
#import "TgPolicyVault.h"
#import "TgPulseOverlay.h"
#import "TgShardFacade.h"
#import "TgStampVault.h"
#import "TgWireConduit.h"
#import "NSString+TgGlyph.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <CoreLocation/CoreLocation.h>
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <objc/runtime.h>

static CGFloat const kTgDcHorz = 16.0;
static CGFloat const kTgDcCardRadius = 16.0;
static CGFloat const kTgDcSubmitH = 56.0;
static CGFloat const kTgDcSubmitR = 28.0;
static CGFloat const kTgDcGradientDesignW = 375.0;
static CGFloat const kTgDcGradientDesignH = 496.0;
static NSString * const kTgDcCloseAsset = @"Delete0"; ///< details modal close only
static NSString * const kTgDcBackAsset = @"gst_tab";
static NSString * const kTgDcTermsOn = @"due_Terms_yes";
static NSString * const kTgDcTermsOff = @"due_Terms_no";
static NSString * const kTgDcBankAsset = @"use_bank";
static NSString * const kTgDcArrowAsset = @"use_next_loan"; ///< black arrow for Select EMIs / period
static NSString * const kTgDcTipAsset = @"details";
static NSString * const kTgDcBtnHex = @"#182040";
static NSString * const kTgDcAmountHex = @"#0A0B17";
static NSString * const kTgDcRedHex = @"#C51B12";
static NSString * const kTgDcLinkHex = @"#3D59FF";
static NSString * const kTgDcGrayHex = @"#8A8FA8";
static NSString * const kTgDcDarkHex = @"#212121";
static NSString * const kTgDcAmountBoxHex = @"#F1F1F1";
static NSString * const kTgDcTrackHex = @"#D2D2D2"; ///< slider track background
static CGFloat const kTgDcCheckSize = 20.0;
static CGFloat const kTgDcAmountBoxRadius = 12.0;
static CGFloat const kTgDcSliderH = 22.0;
static NSString * const kTgDcToastPick = @"Please choose one or more products";
static NSString * const kTgDcToastTerms = @"Please review and accept the Loan Terms";
static NSString * const kTgDcToastLocationFail = @"Unable to obtain location, please try once more";
static NSString * const kTgDcNavTitle = @"select loan amount";
static NSTimeInterval const kTgDcLocationTimeoutSec = 10.0;
static NSString * const kTgDcBackMsg =
    @"It would be a shame to leave now. Substantial loan credit is still waiting for you to withdraw - please reconsider!";
static NSString * const kTgDcTipArrival =
    @"The amount you actually receive equals the loan amount minus the service fee and GST.";
static NSString * const kTgDcTipInterest =
    @"Computed from your loan amount, loan term, and this product's interest rate.";
static NSString * const kTgDcTipFee =
    @"This fee is charged by the financial institution for delivering loan services.";
static const void *kTgDcTipKey = &kTgDcTipKey;

#pragma mark - Row state

@interface TgDcPickRow : NSObject
@property (nonatomic, strong) TgProductInfo *product;
@property (nonatomic, strong) TgProductTermData *termData;
@property (nonatomic, copy) NSArray<TgAmountDetail *> *sortedAmounts;
@property (nonatomic, assign) NSInteger amountIdx;
@property (nonatomic, assign) NSInteger termIdx;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, weak) UIView *cardVeil;
@property (nonatomic, weak) UIButton *checkLatch;
@property (nonatomic, weak) UIView *amountBox;
@property (nonatomic, weak) UILabel *amountCaption;
@property (nonatomic, weak) UISlider *amountSlider;
@property (nonatomic, weak) UILabel *minCaption;
@property (nonatomic, weak) UILabel *maxCaption;
@property (nonatomic, weak) UILabel *termTitleCaption;
@property (nonatomic, weak) UILabel *termValueCaption;
@property (nonatomic, weak) UILabel *arrivalCaption;
@end
@implementation TgDcPickRow @end

#pragma mark - Controller

@interface TgDcApplyVaultController () <CLLocationManagerDelegate, UIScrollViewDelegate>
@property (nonatomic, strong) UIView *tg_gradientVeil;
@property (nonatomic, strong) CAGradientLayer *tg_headerGradient;
@property (nonatomic, strong) MASConstraint *tg_gradientHeightConstraint;
@property (nonatomic, strong) UIScrollView *tg_scroll;
@property (nonatomic, strong) UIView *tg_body;
@property (nonatomic, strong) UIStackView *tg_cardStack;
@property (nonatomic, strong) UIView *tg_summaryCard;
@property (nonatomic, strong) UILabel *tg_totalAmountCaption;
@property (nonatomic, strong) UILabel *tg_totalFeeCaption;
@property (nonatomic, strong) UILabel *tg_totalArrivalCaption;
@property (nonatomic, strong) UILabel *tg_bankCaption;
@property (nonatomic, strong) UIButton *tg_submitLatch;
@property (nonatomic, strong) UIButton *tg_agreeLatch;
@property (nonatomic, strong) UILabel *tg_agreeCaption;
@property (nonatomic, assign) BOOL tg_agreed;
@property (nonatomic, strong) NSMutableArray<TgDcPickRow *> *tg_rows;
@property (nonatomic, strong) UIView *tg_detailVeil;
@property (nonatomic, strong) UIView *tg_detailPanel;
@property (nonatomic, strong) UIStackView *tg_detailStack;
@property (nonatomic, strong, nullable) CLLocationManager *tg_locMgr;
@property (nonatomic, strong, nullable) CLLocation *tg_location;
@property (nonatomic, copy, nullable) dispatch_block_t tg_locTimeout;
@property (nonatomic, assign) BOOL tg_submitting;
@property (nonatomic, assign) BOOL tg_apiFired;
@property (nonatomic, assign) BOOL tg_navTitleHidden;
@end

@implementation TgDcApplyVaultController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.tg_backdropStyle = TgHullBackdropStylePlain;
        self.tg_showsBackButton = YES;
        self.tg_backButtonImageName = kTgDcBackAsset;
        self.hidesBottomBarWhenPushed = YES;
        _tg_agreed = YES;
        _tg_rows = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor tg_toneFromHex:@"#F1F1F1"];
    [self tg_setNavTitleVisible:YES];
    [self tg_buildGradientBackdrop];
    [self tg_buildChrome];
    [self tg_ingestProducts];
    [self tg_rebuildCards];
    [self tg_refreshSummary];
    if (self.tg_rows.count == 0) {
        [[TgPulseOverlay shared] whisperLine:@"No available products"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    }
    __weak typeof(self) weakSelf = self;
    self.tg_backInterceptBlock = ^BOOL {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return YES;
        [self tg_handleBackIntercept];
        return NO;
    };
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    if (!self.tg_navTitleHidden) {
        [self tg_setNavTitleVisible:YES];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tg_headerGradient.frame = self.tg_gradientVeil.bounds;
    CGFloat w = CGRectGetWidth(self.view.bounds);
    if (w > 0) {
        CGFloat gradientH = w * (kTgDcGradientDesignH / kTgDcGradientDesignW);
        [self.tg_gradientHeightConstraint setOffset:gradientH];
    }
}

#pragma mark - UIScrollViewDelegate (nav title)

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    (void)scrollView;
    [self tg_setNavTitleVisible:NO];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    (void)scrollView;
    if (!decelerate) {
        [self tg_setNavTitleVisible:YES];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    (void)scrollView;
    [self tg_setNavTitleVisible:YES];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    (void)scrollView;
    [self tg_setNavTitleVisible:YES];
}

#pragma mark - Nav

- (void)tg_setNavTitleVisible:(BOOL)visible {
    self.tg_navTitleHidden = !visible;
    if (visible) {
        [self tg_setNavTitleMedium18:kTgDcNavTitle];
    } else {
        self.navigationItem.titleView = nil;
        self.navigationItem.title = nil;
    }
}

- (void)tg_handleBackIntercept {
    [self tg_confirmLeave];
}

- (void)tg_confirmLeave {
    __weak typeof(self) weakSelf = self;
    // Shard layout: secondary=left, primary=right → Confirm left, Cancel right
    [[TgShardFacade shared] showTextPanelWithContent:kTgDcBackMsg
                                        primaryTitle:@"Cancel"
                                      secondaryTitle:@"Confirm"
                                        primaryAction:nil
                                      secondaryAction:^{
        __strong typeof(weakSelf) self = weakSelf;
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

#pragma mark - Build

- (void)tg_buildGradientBackdrop {
    self.tg_gradientVeil = [[UIView alloc] init];
    self.tg_gradientVeil.userInteractionEnabled = NO;
    self.tg_gradientVeil.clipsToBounds = YES;
    [self.view insertSubview:self.tg_gradientVeil atIndex:0];

    self.tg_headerGradient = [CAGradientLayer layer];
    self.tg_headerGradient.startPoint = CGPointMake(0.51, -0.82);
    self.tg_headerGradient.endPoint = CGPointMake(0.5, 1);
    self.tg_headerGradient.colors = @[
        (__bridge id)[UIColor colorWithRed:54/255.0 green:83/255.0 blue:255/255.0 alpha:1].CGColor,
        (__bridge id)[UIColor colorWithRed:241/255.0 green:241/255.0 blue:241/255.0 alpha:1].CGColor
    ];
    self.tg_headerGradient.locations = @[@(0), @(0.9f)];
    [self.tg_gradientVeil.layer insertSublayer:self.tg_headerGradient atIndex:0];

    [self.tg_gradientVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        self.tg_gradientHeightConstraint = make.height.mas_equalTo(kTgDcGradientDesignH);
    }];
}

- (void)tg_buildChrome {
    self.tg_scroll = [[UIScrollView alloc] init];
    self.tg_scroll.delegate = self;
    self.tg_scroll.alwaysBounceVertical = YES;
    self.tg_scroll.showsVerticalScrollIndicator = NO;
    self.tg_scroll.backgroundColor = UIColor.clearColor;
    self.tg_scroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:self.tg_scroll];

    self.tg_body = [[UIView alloc] init];
    self.tg_body.backgroundColor = UIColor.clearColor;
    [self.tg_scroll addSubview:self.tg_body];

    self.tg_cardStack = [[UIStackView alloc] init];
    self.tg_cardStack.axis = UILayoutConstraintAxisVertical;
    self.tg_cardStack.spacing = 12;
    [self.tg_body addSubview:self.tg_cardStack];

    self.tg_summaryCard = [self tg_whiteCard];
    [self.tg_body addSubview:self.tg_summaryCard];
    [self tg_buildSummaryInside];

    UILabel *disclaimer = [[UILabel alloc] init];
    disclaimer.text = @"These loan details rely on the information you provided and may change with your final loan eligibility.";
    disclaimer.font = [UIFont tg_meshGlyphWithSize:12 weight:UIFontWeightRegular];
    disclaimer.textColor = [UIColor tg_toneFromHex:kTgDcAmountHex];
    disclaimer.numberOfLines = 0;
    disclaimer.textAlignment = NSTextAlignmentLeft;
    disclaimer.tag = 9901;
    [self.tg_body addSubview:disclaimer];

    self.tg_submitLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    self.tg_submitLatch.backgroundColor = [UIColor tg_toneFromHex:kTgDcBtnHex];
    self.tg_submitLatch.layer.cornerRadius = kTgDcSubmitR;
    [self.tg_submitLatch setTitle:@"Submit" forState:UIControlStateNormal];
    [self.tg_submitLatch setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.tg_submitLatch.titleLabel.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    [self.tg_submitLatch addTarget:self action:@selector(tg_onSubmit) forControlEvents:UIControlEventTouchUpInside];
    [self.tg_body addSubview:self.tg_submitLatch];

    self.tg_agreeLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_agreeLatch setImage:[UIImage imageNamed:kTgDcTermsOn] forState:UIControlStateNormal];
    [self.tg_agreeLatch addTarget:self action:@selector(tg_onAgreeToggle) forControlEvents:UIControlEventTouchUpInside];
    [self.tg_body addSubview:self.tg_agreeLatch];

    self.tg_agreeCaption = [[UILabel alloc] init];
    self.tg_agreeCaption.numberOfLines = 0;
    self.tg_agreeCaption.userInteractionEnabled = YES;
    [self tg_renderAgreeText];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tg_onTermsLink)];
    [self.tg_agreeCaption addGestureRecognizer:tap];
    [self.tg_body addSubview:self.tg_agreeCaption];

    [self.tg_scroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self.tg_body mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.width.equalTo(self.tg_scroll);
    }];
    [self.tg_cardStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_body.mas_safeAreaLayoutGuideTop).offset(12);
        make.left.equalTo(self.tg_body).offset(kTgDcHorz);
        make.right.equalTo(self.tg_body).offset(-kTgDcHorz);
    }];
    [self.tg_summaryCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_cardStack.mas_bottom).offset(12);
        make.left.right.equalTo(self.tg_cardStack);
    }];
    [disclaimer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_summaryCard.mas_bottom).offset(14);
        make.left.right.equalTo(self.tg_cardStack);
    }];
    [self.tg_submitLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(disclaimer.mas_bottom).offset(16);
        make.centerX.equalTo(self.tg_body);
        make.width.equalTo(self.tg_body).multipliedBy(0.85);
        make.height.mas_equalTo(kTgDcSubmitH);
    }];
    [self.tg_agreeLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_submitLatch.mas_bottom).offset(14);
        make.left.equalTo(self.tg_cardStack);
        make.width.height.mas_equalTo(22);
    }];
    [self.tg_agreeCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_agreeLatch);
        make.left.equalTo(self.tg_agreeLatch.mas_right).offset(8);
        make.right.equalTo(self.tg_cardStack);
        make.bottom.equalTo(self.tg_body).offset(-28);
    }];

    [self tg_buildDetailOverlay];
}

- (UIView *)tg_whiteCard {
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = UIColor.whiteColor;
    v.layer.cornerRadius = kTgDcCardRadius;
    v.clipsToBounds = YES;
    return v;
}

- (void)tg_buildSummaryInside {
    UILabel *totalTitle = [self tg_label:14 weight:UIFontWeightRegular color:kTgDcGrayHex text:@"Total amount"];
    self.tg_totalAmountCaption = [self tg_label:18 weight:UIFontWeightBold color:kTgDcDarkHex text:@"--"];
    self.tg_totalAmountCaption.textAlignment = NSTextAlignmentRight;
    UIView *feeBox = [[UIView alloc] init];
    feeBox.backgroundColor = [UIColor tg_toneFromHex:@"#F1F1F1"];
    feeBox.layer.cornerRadius = 10;
    UILabel *feeT = [self tg_label:13 weight:UIFontWeightRegular color:kTgDcGrayHex text:@"Total fee"];
    self.tg_totalFeeCaption = [self tg_label:14 weight:UIFontWeightBold color:kTgDcDarkHex text:@"--"];
    self.tg_totalFeeCaption.textAlignment = NSTextAlignmentRight;
    UILabel *arrT = [self tg_label:13 weight:UIFontWeightRegular color:kTgDcGrayHex text:@"Amount received"];
    self.tg_totalArrivalCaption = [self tg_label:14 weight:UIFontWeightBold color:kTgDcDarkHex text:@"--"];
    self.tg_totalArrivalCaption.textAlignment = NSTextAlignmentRight;
    UIImageView *bankIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgDcBankAsset]];
    bankIcon.contentMode = UIViewContentModeScaleAspectFit;
    self.tg_bankCaption = [self tg_label:14 weight:UIFontWeightBold color:kTgDcDarkHex text:@"-"];
    self.tg_bankCaption.textAlignment = NSTextAlignmentRight;
    self.tg_bankCaption.adjustsFontSizeToFitWidth = YES;
    self.tg_bankCaption.minimumScaleFactor = 0.7;

    [self.tg_summaryCard addSubview:totalTitle];
    [self.tg_summaryCard addSubview:self.tg_totalAmountCaption];
    [self.tg_summaryCard addSubview:feeBox];
    [feeBox addSubview:feeT];
    [feeBox addSubview:self.tg_totalFeeCaption];
    [feeBox addSubview:arrT];
    [feeBox addSubview:self.tg_totalArrivalCaption];
    [self.tg_summaryCard addSubview:bankIcon];
    [self.tg_summaryCard addSubview:self.tg_bankCaption];

    [totalTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(self.tg_summaryCard).inset(14);
    }];
    [self.tg_totalAmountCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.tg_summaryCard).inset(14);
        make.centerY.equalTo(totalTitle);
        make.left.greaterThanOrEqualTo(totalTitle.mas_right).offset(8);
    }];
    [feeBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(totalTitle.mas_bottom).offset(12);
        make.left.right.equalTo(self.tg_summaryCard).inset(14);
    }];
    [feeT mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(feeBox).inset(10);
    }];
    [self.tg_totalFeeCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(feeBox).inset(10);
        make.centerY.equalTo(feeT);
    }];
    [arrT mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(feeT);
        make.top.equalTo(feeT.mas_bottom).offset(8);
        make.bottom.equalTo(feeBox).inset(10);
    }];
    [self.tg_totalArrivalCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.tg_totalFeeCaption);
        make.centerY.equalTo(arrT);
    }];
    [bankIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_summaryCard).offset(14);
        make.top.equalTo(feeBox.mas_bottom).offset(14);
        make.width.height.mas_equalTo(22);
        make.bottom.equalTo(self.tg_summaryCard).offset(-14);
    }];
    [self.tg_bankCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(bankIcon);
        make.left.equalTo(bankIcon.mas_right).offset(8);
        make.right.equalTo(self.tg_summaryCard).offset(-14);
    }];
}

- (UILabel *)tg_label:(CGFloat)size weight:(UIFontWeight)w color:(NSString *)hex text:(NSString *)text {
    UILabel *l = [[UILabel alloc] init];
    l.font = [UIFont tg_meshGlyphWithSize:size weight:w];
    l.textColor = [UIColor tg_toneFromHex:hex];
    l.text = text;
    return l;
}

- (void)tg_renderAgreeText {
    NSDictionary *n = @{
        NSFontAttributeName: [UIFont tg_meshGlyphWithSize:12 weight:UIFontWeightRegular],
        NSForegroundColorAttributeName: [UIColor tg_toneFromHex:kTgDcGrayHex]
    };
    NSDictionary *link = @{
        NSFontAttributeName: [UIFont tg_meshGlyphWithSize:12 weight:UIFontWeightMedium],
        NSForegroundColorAttributeName: [UIColor tg_toneFromHex:kTgDcAmountHex], // black, no quotes
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
    };
    NSMutableAttributedString *a = [[NSMutableAttributedString alloc] init];
    [a appendAttributedString:[[NSAttributedString alloc] initWithString:@"I have reviewed and agreed to the " attributes:n]];
    [a appendAttributedString:[[NSAttributedString alloc] initWithString:@"Loan terms and conditions" attributes:link]];
    self.tg_agreeCaption.attributedText = a;
}

#pragma mark - Data

- (void)tg_ingestProducts {
    [self.tg_rows removeAllObjects];
    for (TgProductInfo *p in self.tg_products ?: @[]) {
        TgProductTermData *term = p.productTermV3Response;
        if (!term) continue;
        if (term.resistance.length == 0) term.resistance = p.resistance;
        if (term.other.length == 0) term.other = p.other;
        if (term.green.length == 0) term.green = p.green;

        NSArray *amounts = [self tg_sortedAmounts:term.nonsense];
        if (amounts.count == 0) continue;

        TgDcPickRow *row = [[TgDcPickRow alloc] init];
        row.product = p;
        row.termData = term;
        row.sortedAmounts = amounts;
        row.amountIdx = 0; // highest first after desc sort
        row.termIdx = (NSInteger)MAX((NSInteger)[self tg_sortedTermsForAmount:amounts.firstObject].count - 1, 0);
        row.selected = YES;
        [self.tg_rows addObject:row];
    }
}

- (NSArray<TgAmountDetail *> *)tg_sortedAmounts:(NSArray<TgAmountDetail *> *)raw {
    NSArray *list = raw ?: @[];
    return [list sortedArrayUsingComparator:^NSComparisonResult(TgAmountDetail *a, TgAmountDetail *b) {
        double av = a.inch.doubleValue;
        double bv = b.inch.doubleValue;
        if (av < bv) return NSOrderedDescending;
        if (av > bv) return NSOrderedAscending;
        return NSOrderedSame;
    }];
}

- (NSArray<TgTermDetail *> *)tg_sortedTermsForAmount:(TgAmountDetail *)amount {
    NSArray *list = amount.eighth ?: @[];
    return [list sortedArrayUsingComparator:^NSComparisonResult(TgTermDetail *a, TgTermDetail *b) {
        NSInteger av = a.ill > 0 ? a.ill : a.culture;
        NSInteger bv = b.ill > 0 ? b.ill : b.culture;
        if (av < bv) return NSOrderedAscending;
        if (av > bv) return NSOrderedDescending;
        return NSOrderedSame;
    }];
}

- (TgAmountDetail *)tg_amountForRow:(TgDcPickRow *)row {
    if (row.amountIdx < 0 || row.amountIdx >= (NSInteger)row.sortedAmounts.count) return nil;
    return row.sortedAmounts[row.amountIdx];
}

- (TgTermDetail *)tg_termForRow:(TgDcPickRow *)row {
    TgAmountDetail *amt = [self tg_amountForRow:row];
    NSArray *terms = [self tg_sortedTermsForAmount:amt];
    if (row.termIdx < 0 || row.termIdx >= (NSInteger)terms.count) return terms.lastObject;
    return terms[row.termIdx];
}

#pragma mark - Cards

- (void)tg_rebuildCards {
    for (UIView *v in self.tg_cardStack.arrangedSubviews) {
        [self.tg_cardStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    NSInteger idx = 0;
    for (TgDcPickRow *row in self.tg_rows) {
        UIView *card = [self tg_makeCardForRow:row index:idx];
        [self.tg_cardStack addArrangedSubview:card];
        idx++;
    }
}

- (UIView *)tg_makeCardForRow:(TgDcPickRow *)row index:(NSInteger)index {
    UIView *card = [self tg_whiteCard];
    row.cardVeil = card;

    UIView *pill = [[UIView alloc] init];
    pill.backgroundColor = [UIColor tg_toneFromHex:@"#F1F1F1"];
    pill.layer.cornerRadius = 14;
    UIImageView *logo = [[UIImageView alloc] init];
    logo.contentMode = UIViewContentModeScaleAspectFit;
    logo.clipsToBounds = YES;
    logo.layer.cornerRadius = 4;
    logo.backgroundColor = [UIColor tg_toneFromHex:@"#D0D0D0"];
    NSString *logoURL = [row.termData.green ?: row.product.green stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (logoURL.length > 0) {
        [logo sd_setImageWithURL:[NSURL URLWithString:logoURL]];
    }
    UILabel *name = [self tg_label:13 weight:UIFontWeightMedium color:kTgDcGrayHex text:(row.termData.other.length ? row.termData.other : (row.product.other ?: @"-"))];
    UIButton *check = [UIButton buttonWithType:UIButtonTypeCustom];
    check.tag = index;
    [check addTarget:self action:@selector(tg_onCheck:) forControlEvents:UIControlEventTouchUpInside];
    row.checkLatch = check;
    [self tg_syncCheck:row];

    BOOL multiAmount = (row.sortedAmounts.count > 1);

    UIView *amountBox = [[UIView alloc] init];
    amountBox.backgroundColor = [UIColor tg_toneFromHex:kTgDcAmountBoxHex];
    amountBox.layer.cornerRadius = kTgDcAmountBoxRadius;
    amountBox.clipsToBounds = YES;
    row.amountBox = amountBox;

    UILabel *amount = [self tg_label:28 weight:UIFontWeightBold color:kTgDcAmountHex text:@"--"];
    amount.textAlignment = NSTextAlignmentCenter;
    row.amountCaption = amount;

    UISlider *slider = [[UISlider alloc] init];
    slider.minimumTrackTintColor = [UIColor tg_toneFromHex:kTgDcBtnHex]; // #182040 filled
    slider.maximumTrackTintColor = [UIColor tg_toneFromHex:kTgDcTrackHex]; // #D2D2D2 track
    // Progress-bar look: hide thumb (design has no circular handle).
    UIImage *clearThumb = [self tg_clearThumbImage];
    [slider setThumbImage:clearThumb forState:UIControlStateNormal];
    [slider setThumbImage:clearThumb forState:UIControlStateHighlighted];
    // Thicker track (~22pt visual) via stretchable track images
    [slider setMinimumTrackImage:[self tg_sliderTrackImage:[UIColor tg_toneFromHex:kTgDcBtnHex]] forState:UIControlStateNormal];
    [slider setMaximumTrackImage:[self tg_sliderTrackImage:[UIColor tg_toneFromHex:kTgDcTrackHex]] forState:UIControlStateNormal];
    slider.tag = index;
    slider.minimumValue = 0;
    slider.maximumValue = MAX((float)row.sortedAmounts.count - 1, 0);
    // Design: left=min, right=max. sortedAmounts is desc → invert index for slider.
    slider.value = (float)MAX((NSInteger)row.sortedAmounts.count - 1 - row.amountIdx, 0);
    [slider addTarget:self action:@selector(tg_onSlider:) forControlEvents:UIControlEventValueChanged];
    [slider addTarget:self action:@selector(tg_onSliderEnd:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    row.amountSlider = slider;
    slider.hidden = !multiAmount;

    UILabel *minL = [self tg_label:15 weight:UIFontWeightMedium color:kTgDcGrayHex text:@""];
    UILabel *maxL = [self tg_label:15 weight:UIFontWeightMedium color:kTgDcGrayHex text:@""];
    maxL.textAlignment = NSTextAlignmentRight;
    row.minCaption = minL;
    row.maxCaption = maxL;
    minL.hidden = !multiAmount;
    maxL.hidden = !multiAmount;

    UILabel *termTitle = [self tg_label:14 weight:UIFontWeightRegular color:kTgDcGrayHex text:@"Loan tenure"];
    UILabel *termValue = [self tg_label:14 weight:UIFontWeightBold color:kTgDcRedHex text:@"-"];
    termValue.textAlignment = NSTextAlignmentRight;
    UIImageView *termArrow = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:kTgDcArrowAsset] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    termArrow.contentMode = UIViewContentModeScaleAspectFit;
    UIButton *termTap = [UIButton buttonWithType:UIButtonTypeCustom];
    termTap.tag = index;
    [termTap addTarget:self action:@selector(tg_onTermTap:) forControlEvents:UIControlEventTouchUpInside];
    row.termTitleCaption = termTitle;
    row.termValueCaption = termValue;

    UILabel *arrTitle = [self tg_label:14 weight:UIFontWeightRegular color:kTgDcGrayHex text:@"Amount received"];
    UILabel *arrValue = [self tg_label:14 weight:UIFontWeightBold color:kTgDcDarkHex text:@"-"];
    arrValue.textAlignment = NSTextAlignmentRight;
    row.arrivalCaption = arrValue;

    UIButton *details = [UIButton buttonWithType:UIButtonTypeSystem];
    [details setTitle:@"Loan details >>>" forState:UIControlStateNormal];
    [details setTitleColor:[UIColor tg_toneFromHex:kTgDcLinkHex] forState:UIControlStateNormal];
    details.titleLabel.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightMedium];
    details.tag = index;
    [details addTarget:self action:@selector(tg_onDetails:) forControlEvents:UIControlEventTouchUpInside];

    [card addSubview:pill];
    [pill addSubview:logo];
    [pill addSubview:name];
    [card addSubview:check];
    [card addSubview:amountBox];
    [amountBox addSubview:amount];
    [amountBox addSubview:slider];
    [amountBox addSubview:minL];
    [amountBox addSubview:maxL];
    [card addSubview:termTitle];
    [card addSubview:termValue];
    [card addSubview:termArrow];
    [card addSubview:termTap];
    [card addSubview:arrTitle];
    [card addSubview:arrValue];
    [card addSubview:details];

    [pill mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(card).inset(14);
        make.height.mas_equalTo(28);
        make.right.lessThanOrEqualTo(check.mas_left).offset(-8);
    }];
    [logo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(pill).offset(6);
        make.centerY.equalTo(pill);
        make.width.height.mas_equalTo(18);
    }];
    [name mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(logo.mas_right).offset(6);
        make.right.equalTo(pill).offset(-10);
        make.centerY.equalTo(pill);
    }];
    [check mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(card).offset(-14);
        make.centerY.equalTo(pill);
        make.width.height.mas_equalTo(kTgDcCheckSize);
    }];
    [amountBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(pill.mas_bottom).offset(12);
        make.left.right.equalTo(card).inset(14);
    }];
    [amount mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(amountBox).offset(14);
        make.left.right.equalTo(amountBox).inset(12);
        if (!multiAmount) {
            make.bottom.equalTo(amountBox).offset(-14);
        }
    }];
    [slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(amount.mas_bottom).offset(multiAmount ? 12 : 0);
        make.left.right.equalTo(amountBox).inset(12);
        make.height.mas_equalTo(multiAmount ? kTgDcSliderH : 0);
    }];
    [minL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(slider.mas_bottom).offset(multiAmount ? 6 : 0);
        make.left.equalTo(slider);
        if (multiAmount) {
            make.bottom.equalTo(amountBox).offset(-12);
        }
    }];
    [maxL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(minL);
        make.right.equalTo(slider);
    }];
    [termTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(amountBox.mas_bottom).offset(14);
        make.left.equalTo(card).offset(14);
    }];
    [termArrow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(card).offset(-14);
        make.centerY.equalTo(termTitle);
        make.width.height.mas_equalTo(14);
    }];
    [termValue mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(termTitle);
        make.right.equalTo(termArrow.mas_left).offset(-4);
        make.left.greaterThanOrEqualTo(termTitle.mas_right).offset(8);
    }];
    [termTap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(termTitle);
        make.right.equalTo(termArrow);
        make.top.bottom.equalTo(termTitle).inset(-6);
    }];
    [arrTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(termTitle.mas_bottom).offset(12);
        make.left.equalTo(termTitle);
    }];
    [arrValue mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(arrTitle);
        make.right.equalTo(card).offset(-14);
        make.left.greaterThanOrEqualTo(arrTitle.mas_right).offset(8);
    }];
    [details mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(arrTitle.mas_bottom).offset(12);
        make.centerX.equalTo(card);
        make.bottom.equalTo(card).offset(-14);
    }];

    [self tg_refreshRowUI:row];
    return card;
}

- (UIImage *)tg_clearThumbImage {
    CGSize size = CGSizeMake(1, 1);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (UIImage *)tg_sliderTrackImage:(UIColor *)color {
    CGFloat h = kTgDcSliderH;
    CGSize size = CGSizeMake(h + 2.0, h);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height)
                                                    cornerRadius:h / 2.0];
    [color setFill];
    [path fill];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [img resizableImageWithCapInsets:UIEdgeInsetsMake(0, h / 2.0, 0, h / 2.0)
                               resizingMode:UIImageResizingModeStretch];
}

- (void)tg_syncCheck:(TgDcPickRow *)row {
    UIImage *on = [UIImage imageNamed:kTgDcTermsOn];
    UIImage *off = [UIImage imageNamed:kTgDcTermsOff];
    [row.checkLatch setImage:row.selected ? on : off forState:UIControlStateNormal];
}

- (NSString *)tg_rupee:(NSString *)raw {
    NSString *d = [NSString tg_digitsOnlyFromMixed:raw ?: @""];
    if (d.length == 0) return @"--";
    return [NSString stringWithFormat:@"₹%@", [NSString tg_weaveIndianDigits:d]];
}

- (NSString *)tg_plainAmount:(NSString *)raw {
    NSString *d = [NSString tg_digitsOnlyFromMixed:raw ?: @""];
    if (d.length == 0) return @"-";
    return [NSString tg_weaveIndianDigits:d];
}

- (void)tg_refreshRowUI:(TgDcPickRow *)row {
    TgAmountDetail *amt = [self tg_amountForRow:row];
    TgTermDetail *term = [self tg_termForRow:row];
    row.amountCaption.text = [self tg_rupee:amt.inch];
    if (row.sortedAmounts.count > 1) {
        TgAmountDetail *low = row.sortedAmounts.lastObject;
        TgAmountDetail *high = row.sortedAmounts.firstObject;
        row.minCaption.text = [self tg_rupee:low.inch];
        row.maxCaption.text = [self tg_rupee:high.inch];
        // Slider left=min (high index), right=max (index 0)
        float sliderVal = (float)MAX((NSInteger)row.sortedAmounts.count - 1 - row.amountIdx, 0);
        if (fabsf(row.amountSlider.value - sliderVal) > 0.01) {
            row.amountSlider.value = sliderVal;
        }
    }
    BOOL emi = (term.EMIs > 0);
    if (emi) {
        row.termTitleCaption.text = @"Select EMIs";
        row.termValueCaption.text = term.EMIs == 1 ? @"1 EMI" : [NSString stringWithFormat:@"%ld EMIs", (long)term.EMIs];
    } else {
        NSInteger show = term.ill > 0 ? term.ill : term.culture;
        row.termTitleCaption.text = @"Choose your loan tenure";
        row.termValueCaption.text = show > 0 ? [NSString stringWithFormat:@"%ld Days", (long)show] : @"-";
    }
    row.arrivalCaption.text = [self tg_plainAmount:term.minority];
    [self tg_syncCheck:row];
}

- (void)tg_refreshSummary {
    double totalAmt = 0;
    double totalArr = 0;
    NSString *bank = @"-";
    for (TgDcPickRow *row in self.tg_rows) {
        if (!row.selected) continue;
        TgAmountDetail *amt = [self tg_amountForRow:row];
        TgTermDetail *term = [self tg_termForRow:row];
        totalAmt += amt.inch.doubleValue;
        totalArr += term.minority.doubleValue;
        if ([bank isEqualToString:@"-"]) {
            TgCardInfo *card = row.termData.superior.firstObject;
            NSString *acct = [card.measure stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
            if (acct.length > 0) bank = acct;
        }
    }
    double fee = MAX(totalAmt - totalArr, 0);
    self.tg_totalAmountCaption.text = [self tg_rupee:[NSString stringWithFormat:@"%.0f", totalAmt]];
    self.tg_totalFeeCaption.text = [self tg_rupee:[NSString stringWithFormat:@"%.0f", fee]];
    self.tg_totalArrivalCaption.text = [self tg_rupee:[NSString stringWithFormat:@"%.0f", totalArr]];
    self.tg_bankCaption.text = bank;
}

#pragma mark - Interactions

- (void)tg_onCheck:(UIButton *)sender {
    if (sender.tag < 0 || sender.tag >= (NSInteger)self.tg_rows.count) return;
    TgDcPickRow *row = self.tg_rows[sender.tag];
    if (row.selected) {
        NSInteger selectedCount = 0;
        for (TgDcPickRow *r in self.tg_rows) if (r.selected) selectedCount++;
        if (selectedCount <= 1) {
            [[TgPulseOverlay shared] whisperLine:kTgDcToastPick];
            return;
        }
        row.selected = NO;
    } else {
        row.selected = YES;
    }
    [self tg_syncCheck:row];
    [self tg_refreshSummary];
}

- (void)tg_onSlider:(UISlider *)slider {
    if (slider.tag < 0 || slider.tag >= (NSInteger)self.tg_rows.count) return;
    TgDcPickRow *row = self.tg_rows[slider.tag];
    NSInteger maxIdx = (NSInteger)row.sortedAmounts.count - 1;
    NSInteger sliderIdx = (NSInteger)llroundf(slider.value);
    sliderIdx = MAX(0, MIN(sliderIdx, maxIdx));
    // Slider left=min → amountIdx = last; right=max → amountIdx = 0
    row.amountIdx = maxIdx - sliderIdx;
    NSArray *terms = [self tg_sortedTermsForAmount:[self tg_amountForRow:row]];
    row.termIdx = (NSInteger)MAX((NSInteger)terms.count - 1, 0);
    [self tg_refreshRowUI:row];
    [self tg_refreshSummary];
}

- (void)tg_onSliderEnd:(UISlider *)slider {
    if (slider.tag < 0 || slider.tag >= (NSInteger)self.tg_rows.count) return;
    TgDcPickRow *row = self.tg_rows[slider.tag];
    NSInteger maxIdx = (NSInteger)row.sortedAmounts.count - 1;
    slider.value = (float)MAX(maxIdx - row.amountIdx, 0);
}

- (void)tg_onTermTap:(UIButton *)sender {
    if (sender.tag < 0 || sender.tag >= (NSInteger)self.tg_rows.count) return;
    TgDcPickRow *row = self.tg_rows[sender.tag];
    NSArray<TgTermDetail *> *terms = [self tg_sortedTermsForAmount:[self tg_amountForRow:row]];
    if (terms.count <= 1) return;
    NSMutableArray *options = [NSMutableArray array];
    BOOL emi = (terms.firstObject.EMIs > 0);
    for (TgTermDetail *t in terms) {
        if (emi) {
            [options addObject:t.EMIs == 1 ? @"1 EMI" : [NSString stringWithFormat:@"%ld EMIs", (long)t.EMIs]];
        } else {
            NSInteger show = t.ill > 0 ? t.ill : t.culture;
            [options addObject:[NSString stringWithFormat:@"%ld Days", (long)show]];
        }
    }
    __weak typeof(self) weakSelf = self;
    [[TgShardFacade shared] showOptionPickerWithTitle:emi ? @"Select EMIs" : @"Select loan period"
                                              options:options
                                        selectedIndex:row.termIdx
                                         confirmTitle:@"Confirm"
                                            onConfirm:^(NSInteger index, NSString *value) {
        (void)value;
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        row.termIdx = index;
        [self tg_refreshRowUI:row];
        [self tg_refreshSummary];
    }];
}

- (void)tg_onAgreeToggle {
    self.tg_agreed = !self.tg_agreed;
    [self.tg_agreeLatch setImage:[UIImage imageNamed:self.tg_agreed ? kTgDcTermsOn : kTgDcTermsOff] forState:UIControlStateNormal];
}

- (void)tg_onTermsLink {
    NSString *href = [TgPureLinks loanTerms];
    NSURL *url = [TgPaneWebController tg_normalizedURLFromString:href];
    if (href.length == 0 || !url) {
        [[TgPulseOverlay shared] whisperLine:@"The agreement link is not available"];
        return;
    }
    TgPaneWebController *pane = [[TgPaneWebController alloc] initWithPageURL:url navTitle:@"Loan Terms"];
    pane.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:pane animated:YES];
}

#pragma mark - Loan details modal

- (void)tg_buildDetailOverlay {
    self.tg_detailVeil = [[UIView alloc] init];
    self.tg_detailVeil.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.45];
    self.tg_detailVeil.hidden = YES;
    [self.view addSubview:self.tg_detailVeil];
    [self.tg_detailVeil mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(self.view); }];

    self.tg_detailPanel = [self tg_whiteCard];
    [self.tg_detailVeil addSubview:self.tg_detailPanel];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeCustom];
    [close setImage:[[UIImage imageNamed:kTgDcCloseAsset] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [close addTarget:self action:@selector(tg_hideDetails) forControlEvents:UIControlEventTouchUpInside];
    [self.tg_detailPanel addSubview:close];

    self.tg_detailStack = [[UIStackView alloc] init];
    self.tg_detailStack.axis = UILayoutConstraintAxisVertical;
    self.tg_detailStack.spacing = 12;
    [self.tg_detailPanel addSubview:self.tg_detailStack];

    [self.tg_detailPanel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.tg_detailVeil);
        make.left.equalTo(self.tg_detailVeil).offset(28);
        make.right.equalTo(self.tg_detailVeil).offset(-28);
    }];
    [close mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.right.equalTo(self.tg_detailPanel).inset(10);
        make.width.height.mas_equalTo(28);
    }];
    [self.tg_detailStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_detailPanel).offset(40);
        make.left.right.equalTo(self.tg_detailPanel).inset(18);
        make.bottom.equalTo(self.tg_detailPanel).offset(-20);
    }];
}

- (void)tg_onDetails:(UIButton *)sender {
    if (sender.tag < 0 || sender.tag >= (NSInteger)self.tg_rows.count) return;
    TgDcPickRow *row = self.tg_rows[sender.tag];
    TgTermDetail *term = [self tg_termForRow:row];
    for (UIView *v in self.tg_detailStack.arrangedSubviews) {
        [self.tg_detailStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    NSInteger show = term.ill > 0 ? term.ill : term.culture;
    [self tg_addDetailRow:@"Loan tenure" value:show > 0 ? [NSString stringWithFormat:@"%ld Days", (long)show] : @"-" tip:nil];
    [self tg_addDetailRow:@"Amount received" value:[self tg_plainAmount:term.minority] tip:kTgDcTipArrival];
    [self tg_addDetailRow:@"Interest" value:[self tg_plainAmount:term.typist] tip:kTgDcTipInterest];
    [self tg_addDetailRow:@"Service fee" value:[self tg_plainAmount:term.pit] tip:kTgDcTipFee];
    [self tg_addDetailRow:@"GST" value:[self tg_plainAmount:term.feather] tip:nil];
    [self tg_addDetailRow:@"Date of application" value:[self tg_formatDate:term.postage] tip:nil];
    [self tg_addDetailRow:@"Due date" value:[self tg_formatDate:term.unity] tip:nil];
    if (term.EMIs > 0) {
        [self tg_addDetailRow:@"1st EMI Date" value:[self tg_formatDate:term.EMIRepayDate] tip:nil];
        if (term.upright.length > 0) {
            [self tg_addDetailRow:@"EMI Amount" value:[self tg_rupee:term.upright] tip:nil];
        }
        [self tg_addDetailRow:@"EMIs" value:[NSString stringWithFormat:@"%ld", (long)term.EMIs] tip:nil];
    }
    self.tg_detailVeil.hidden = NO;
}

- (void)tg_hideDetails {
    self.tg_detailVeil.hidden = YES;
}

- (void)tg_addDetailRow:(NSString *)title value:(NSString *)value tip:(NSString *)tip {
    UIView *row = [[UIView alloc] init];
    UILabel *t = [self tg_label:14 weight:UIFontWeightRegular color:kTgDcGrayHex text:title];
    UILabel *v = [self tg_label:14 weight:UIFontWeightBold color:kTgDcDarkHex text:value ?: @"-"];
    v.textAlignment = NSTextAlignmentRight;
    [row addSubview:t];
    [row addSubview:v];
    [t mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(row);
    }];
    if (tip.length > 0) {
        UIButton *info = [UIButton buttonWithType:UIButtonTypeCustom];
        [info setImage:[UIImage imageNamed:kTgDcTipAsset] forState:UIControlStateNormal];
        objc_setAssociatedObject(info, kTgDcTipKey, tip, OBJC_ASSOCIATION_COPY_NONATOMIC);
        [info addTarget:self action:@selector(tg_onTip:) forControlEvents:UIControlEventTouchUpInside];
        [row addSubview:info];
        [info mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(t.mas_right).offset(4);
            make.centerY.equalTo(t);
            make.width.height.mas_equalTo(16);
        }];
        [v mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.centerY.equalTo(row);
            make.left.greaterThanOrEqualTo(info.mas_right).offset(8);
        }];
    } else {
        [v mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.centerY.equalTo(row);
            make.left.greaterThanOrEqualTo(t.mas_right).offset(8);
        }];
    }
    [row mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_greaterThanOrEqualTo(22);
    }];
    [self.tg_detailStack addArrangedSubview:row];
}

- (void)tg_onTip:(UIButton *)sender {
    NSString *tip = objc_getAssociatedObject(sender, kTgDcTipKey);
    if (tip.length == 0) return;
    [[TgPulseOverlay shared] whisperLine:tip duration:3.0];
}

- (NSString *)tg_formatDate:(NSString *)raw {
    NSString *s = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (s.length == 0) return @"-";
    static NSDateFormatter *inF;
    static NSDateFormatter *outF;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        inF = [[NSDateFormatter alloc] init];
        inF.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        inF.dateFormat = @"yyyy-MM-dd";
        outF = [[NSDateFormatter alloc] init];
        outF.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        outF.dateFormat = @"MMM dd,yyyy";
    });
    NSDate *d = [inF dateFromString:s];
    if (!d) return s;
    return [outF stringFromDate:d] ?: s;
}

#pragma mark - Submit

- (NSArray<TgDcPickRow *> *)tg_selectedRows {
    NSMutableArray *arr = [NSMutableArray array];
    for (TgDcPickRow *r in self.tg_rows) if (r.selected) [arr addObject:r];
    return arr;
}

- (void)tg_onSubmit {
    if (self.tg_submitting) return;
    NSArray *selected = [self tg_selectedRows];
    if (selected.count == 0) {
        [[TgPulseOverlay shared] whisperLine:kTgDcToastPick];
        return;
    }
    if (!self.tg_agreed) {
        [[TgPulseOverlay shared] whisperLine:kTgDcToastTerms];
        return;
    }
    [self tg_beginLocationThenSubmit];
}

- (BOOL)tg_isStrictGrab {
    return [[TgPolicyVault shared] currentManifest].preceding == 1;
}

- (void)tg_abortLocationFlowWithToast:(BOOL)toast {
    [self tg_cancelLocationTimeout];
    [self.tg_locMgr stopUpdatingLocation];
    self.tg_submitting = NO;
    self.tg_apiFired = NO;
    self.tg_location = nil;
    [[TgPulseOverlay shared] veilDismiss];
    if (toast) {
        [[TgPulseOverlay shared] whisperLine:kTgDcToastLocationFail duration:2.0];
    }
}

- (void)tg_cancelLocationTimeout {
    if (self.tg_locTimeout) {
        dispatch_block_cancel(self.tg_locTimeout);
        self.tg_locTimeout = nil;
    }
}

- (NSString *)tg_appDisplayName {
    NSString *name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (name.length > 0) return name;
    name = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]
            stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    return name.length > 0 ? name : @"App";
}

- (void)tg_showLocationSecondaryThenAbort {
    [[TgPulseOverlay shared] veilDismiss];
    [self tg_cancelLocationTimeout];
    [self.tg_locMgr stopUpdatingLocation];
    self.tg_submitting = NO;
    self.tg_apiFired = NO;

    NSString *body = [NSString stringWithFormat:
                      @"Please enable location access for %@ in Settings so you can finish the loan application.",
                      [self tg_appDisplayName]];
    TgShardPanelConfig *cfg = [[TgShardPanelConfig alloc] init];
    cfg.content = body;
    cfg.secondaryTitle = @"Cancel";
    cfg.primaryTitle = @"Confirm";
    cfg.tier = TgShardTierMid;
    cfg.dismissOnPrimaryAction = YES;
    cfg.dismissOnSecondaryAction = YES;
    cfg.primaryAction = ^{
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if (url) {
            [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
        }
    };
    [[TgShardFacade shared] showPanel:cfg];
}

- (void)tg_beginLocationThenSubmit {
    self.tg_submitting = YES;
    self.tg_apiFired = NO;
    self.tg_location = nil;
    [[TgPulseOverlay shared] veilSpin];
    self.tg_locMgr = [[CLLocationManager alloc] init];
    self.tg_locMgr.delegate = self;
    self.tg_locMgr.desiredAccuracy = kCLLocationAccuracyHundredMeters;

    if (![CLLocationManager locationServicesEnabled]) {
        if ([self tg_isStrictGrab]) {
            [self tg_abortLocationFlowWithToast:YES];
        } else {
            [self tg_performSubmit];
        }
        return;
    }

    CLAuthorizationStatus st = [CLLocationManager authorizationStatus];
    if (st == kCLAuthorizationStatusNotDetermined) {
        [self.tg_locMgr requestWhenInUseAuthorization];
        return;
    }
    if (st == kCLAuthorizationStatusAuthorizedWhenInUse || st == kCLAuthorizationStatusAuthorizedAlways) {
        [self tg_startLocationFetchWithTimeout];
        return;
    }
    // denied / restricted
    if ([self tg_isStrictGrab]) {
        [self tg_showLocationSecondaryThenAbort];
    } else {
        [self tg_performSubmit];
    }
}

/// Same pattern as PandoraGateway SilkLeaf: startUpdatingLocation + cancelable timeout.
- (void)tg_startLocationFetchWithTimeout {
    [self tg_cancelLocationTimeout];
    [self.tg_locMgr stopUpdatingLocation];
    [self.tg_locMgr startUpdatingLocation];

    __weak typeof(self) weakSelf = self;
    dispatch_block_t work = dispatch_block_create(0, ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !self.tg_submitting || self.tg_apiFired) return;
        self.tg_locTimeout = nil;
        [self.tg_locMgr stopUpdatingLocation];
        if (self.tg_location) {
            [self tg_performSubmit];
            return;
        }
        // Strong grab: must have real coords — never submit -360 (docs 37 / Pandora silkStrongGrab).
        if ([self tg_isStrictGrab]) {
            [self tg_abortLocationFlowWithToast:YES];
        } else {
            [self tg_performSubmit];
        }
    });
    self.tg_locTimeout = work;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kTgDcLocationTimeoutSec * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), work);
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
    (void)manager;
    if (!self.tg_submitting || self.tg_apiFired) return;
    CLAuthorizationStatus st = [CLLocationManager authorizationStatus];
    if (st == kCLAuthorizationStatusNotDetermined) return;
    if (st == kCLAuthorizationStatusAuthorizedWhenInUse || st == kCLAuthorizationStatusAuthorizedAlways) {
        [self tg_startLocationFetchWithTimeout];
        return;
    }
    // First system deny: end round only — secondary shows on next Apply tap when already Denied (docs 31.8.1).
    if ([self tg_isStrictGrab]) {
        [self tg_abortLocationFlowWithToast:NO];
    } else {
        [self tg_performSubmit];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    (void)manager;
    if (!self.tg_submitting || self.tg_apiFired) return;
    CLLocation *loc = locations.lastObject;
    if (!loc) return;
    self.tg_location = loc;
    [self tg_cancelLocationTimeout];
    [manager stopUpdatingLocation];
    [self tg_performSubmit];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    (void)manager;
    if (!self.tg_submitting || self.tg_apiFired) return;
    // Pandora: ignore transient unknown; keep waiting until timeout.
    if (error.code == kCLErrorLocationUnknown) return;
    [self tg_cancelLocationTimeout];
    [self.tg_locMgr stopUpdatingLocation];
    if ([self tg_isStrictGrab]) {
        [self tg_abortLocationFlowWithToast:YES];
    } else {
        [self tg_performSubmit];
    }
}

- (void)tg_performSubmit {
    if (!self.tg_submitting || self.tg_apiFired) return;

    // Hard gate: strict must have coordinates before any submit.
    if ([self tg_isStrictGrab] && !self.tg_location) {
        [self tg_abortLocationFlowWithToast:YES];
        return;
    }

    self.tg_apiFired = YES;
    [self tg_cancelLocationTimeout];
    [self.tg_locMgr stopUpdatingLocation];
    NSArray<TgDcPickRow *> *selected = [self tg_selectedRows];
    if (selected.count == 0) {
        self.tg_submitting = NO;
        self.tg_apiFired = NO;
        [[TgPulseOverlay shared] veilDismiss];
        return;
    }

    NSMutableArray *ids = [NSMutableArray array];
    NSMutableArray *amts = [NSMutableArray array];
    NSMutableArray *terms = [NSMutableArray array];
    NSString *bindId = nil;
    for (TgDcPickRow *row in selected) {
        TgAmountDetail *amt = [self tg_amountForRow:row];
        TgTermDetail *term = [self tg_termForRow:row];
        NSString *pid = row.termData.resistance.length ? row.termData.resistance : row.product.resistance;
        [ids addObject:pid ?: @""];
        [amts addObject:amt.inch ?: @"0"];
        NSInteger loanTerm = term.culture > 0 ? term.culture : term.ill;
        [terms addObject:[NSString stringWithFormat:@"%ld", (long)loanTerm]];
        if (!bindId) {
            TgCardInfo *card = row.termData.superior.firstObject;
            NSString *b = [card.comparison stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
            if (b.length > 0) bindId = b;
        }
    }

    NSString *lon = @"-360";
    NSString *lat = @"-360";
    if (self.tg_location) {
        lon = [NSString stringWithFormat:@"%.6f", self.tg_location.coordinate.longitude];
        lat = [NSString stringWithFormat:@"%.6f", self.tg_location.coordinate.latitude];
    }

    // Docs: plaintext business field names for userSubmitDcUpgrade
    NSDictionary *sign = @{
        @"productIds": [ids componentsJoinedByString:@","],
        @"loanAmounts": [amts componentsJoinedByString:@","],
        @"loanTerms": [terms componentsJoinedByString:@","],
        @"longitude": lon,
        @"latitude": lat,
        @"imei": @"null",
        @"serialNo": [TgStampVault serialStamp] ?: @""
    };
    NSMutableDictionary *nonSign = [NSMutableDictionary dictionary];
    if (bindId.length > 0) nonSign[@"bankCardBindId"] = bindId;
    NSArray *productIdsCopy = [ids copy];
    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneOrderSubmitDcUpgrade
                             signData:sign
                           nonSignData:nonSign
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (envelope.cheer != 200) {
            self.tg_submitting = NO;
            self.tg_apiFired = NO;
            [[TgPulseOverlay shared] veilDismiss];
            NSString *msg = [envelope.power stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
            [[TgPulseOverlay shared] whisperLine:msg.length ? msg : @"The system is occupied. Please retry after 2 minutes."];
            return;
        }
        TgDcUpgradeSubmitData *data = [TgDcUpgradeSubmitData yy_modelWithJSON:envelope.trick];
        NSArray<TgDcUpgradeOrderItem *> *list = data.list ?: @[];
        if (list.count == 0 && [envelope.trick isKindOfClass:[NSDictionary class]]) {
            id raw = [(NSDictionary *)envelope.trick objectForKey:@"list"];
            if ([raw isKindOfClass:[NSArray class]]) {
                list = [NSArray yy_modelArrayWithClass:[TgDcUpgradeOrderItem class] json:raw] ?: @[];
            }
        }
        // Pair list[] with productIds by same index (docs 50 §4.4 / 19 §7.1)
        NSMutableArray<TgOrderSuccessPair *> *pairs = [NSMutableArray array];
        NSUInteger pairCount = MIN(list.count, productIdsCopy.count);
        for (NSUInteger i = 0; i < pairCount; i++) {
            TgDcUpgradeOrderItem *item = list[i];
            NSString *oid = [item.interpret stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
            NSString *pid = [productIdsCopy[i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
            if (oid.length == 0 || pid.length == 0) continue;
            [pairs addObject:[TgOrderSuccessPair pairWithOrderId:oid productId:pid]];
        }
        if (pairs.count == 0) {
            self.tg_submitting = NO;
            self.tg_apiFired = NO;
            [[TgPulseOverlay shared] veilDismiss];
            [[TgPulseOverlay shared] whisperLine:@"The system is occupied. Please retry after 2 minutes."];
            return;
        }

        NSString *firstOrderId = pairs.firstObject.orderId;
        NSArray<TgOrderSuccessPair *> *pairsCopy = [pairs copy];
        [TgOrderForgeRelay tg_resumeDataCaptureForOrderId:firstOrderId
                                                   hostVC:self
                                                   origin:TgOrderForgeOriginApplyPage
                                   allowSecondaryPrompt:YES
                                                  success:^(NSString *orderId) {
            __strong typeof(weakSelf) self = weakSelf;
            self.tg_submitting = NO;
            TgOrderSuccessVaultController *ok = [[TgOrderSuccessVaultController alloc] init];
            ok.tg_orderPairs = pairsCopy;
            ok.tg_orderId = orderId.length ? orderId : firstOrderId;
            ok.tg_productId = pairsCopy.firstObject.productId;
            ok.tg_exitMode = TgOrderSuccessExitModeHome;
            ok.hidesBottomBarWhenPushed = YES;
            NSMutableArray *stack = [self.navigationController.viewControllers mutableCopy];
            if (stack.count) [stack removeLastObject];
            [stack addObject:ok];
            [self.navigationController setViewControllers:stack animated:YES];
        } failure:^(NSString *message) {
            __strong typeof(weakSelf) self = weakSelf;
            self.tg_submitting = NO;
            self.tg_apiFired = NO;
            NSString *msg = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
            if (msg.length > 0) {
                [[TgPulseOverlay shared] whisperLine:msg];
            }
        } cancelled:^{
            __strong typeof(weakSelf) self = weakSelf;
            self.tg_submitting = NO;
            self.tg_apiFired = NO;
        }];
    } failure:^{
        __strong typeof(weakSelf) self = weakSelf;
        self.tg_submitting = NO;
        self.tg_apiFired = NO;
        [[TgPulseOverlay shared] veilDismiss];
        [[TgPulseOverlay shared] whisperLine:@"The system is occupied. Please retry after 2 minutes."];
    }];
}

@end
