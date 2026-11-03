//

//

#import "TgOrderSuccessVaultController.h"
#import "TgDockBarRelay.h"
#import "TgEnvelopeBase.h"
#import "TgFeedbackVaultController.h"
#import "TgOrderDetailVaultController.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"
#import "TgPulseOverlay.h"
#import "TgReviewGuideRelay.h"
#import "TgWireConduit.h"
#import "NSString+TgGlyph.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <objc/runtime.h>

static CGFloat const kTgSuccessHorzInset = 16.0;
static CGFloat const kTgSuccessCardTopInset = 8.0;
static CGFloat const kTgSuccessTitleExtraGap = 25.0;
static CGFloat const kTgSuccessWaveHeight = 24.0;
static CGFloat const kTgSuccessCardRadius = 16.0;
static CGFloat const kTgSuccessConfirmHeight = 50.0;
static CGFloat const kTgSuccessConfirmWidthRatio = 0.85;
static CGFloat const kTgSuccessPeachBgRatio = 147.0 / 315.0;
static CGFloat const kTgSuccessProductPillHeight = 28.0;
static CGFloat const kTgSuccessLogoCornerRadius = 4.0;
static CGFloat const kTgSuccessPeachTopInset = 22.0;
static CGFloat const kTgSuccessStatusToAmountGap = 14.0;
static CGFloat const kTgSuccessAmountToProductGap = 18.0;
static CGFloat const kTgSuccessProductBottomInset = 20.0;
static CGFloat const kTgSuccessMultiIntroGap = 12.0;
static CGFloat const kTgSuccessMultiBlockGap = 20.0;
static CGFloat const kTgSuccessMultiLogoSize = 20.0;

static NSString * const kTgSuccessWaveAsset = @"use_Subtract2";
static NSString * const kTgSuccessPeachBgAsset = @"use_bg";
static NSString * const kTgSuccessMedalAsset = @"use_loan_star";
static NSString * const kTgSuccessTipIconAsset = @"details";

static NSString * const kTgSuccessPageBgHex = @"#FFFFFF";
static NSString * const kTgSuccessProductNameHex = @"#E2A369";
static NSString * const kTgSuccessStatusHex = @"#793200";
static NSString * const kTgSuccessFeedbackHex = @"#2C42C4";
static NSString * const kTgSuccessDividerHex = @"#EDEDED";
static NSString * const kTgSuccessDurationValueHex = @"#C51B12";
static NSString * const kTgSuccessNoticeBgHex = @"#FFF4E8";
static NSString * const kTgSuccessNoticeTextHex = @"#E67E22";
static NSString * const kTgSuccessMutedHex = @"#686868";
static NSString * const kTgSuccessConfirmHex = @"#182040";
static NSString * const kTgSuccessBusyHint = @"The system is occupied. Please retry after 2 minutes.";
static NSString * const kTgSuccessMissingIdsHint = @"Order ID or Product ID is not available";
static NSString * const kTgSuccessStatusText = @"Under review";
static NSString * const kTgSuccessNoticeText =
    @"Your application is being reviewed. Once approved, funds will be credited to your bank account.";
/// DC multi-product intro (design); docs 19 §7.3 also allows a dedicated copy — design wins for layout match.
static NSString * const kTgSuccessMultiIntroText =
    @"Your application is being reviewed. Add your Telegram or Facebook Messenger account to speed up approval and improve your chance of better loan terms and amounts.";
static NSString * const kTgSuccessTipAmountReceived =
    @"The amount you actually receive equals the loan amount minus the service fee and GST.";
static NSString * const kTgSuccessTipInterest =
    @"Computed from your loan amount, loan term, and this product's interest rate.";
static NSString * const kTgSuccessTipServiceFee =
    @"This fee is charged by the financial institution for delivering loan services.";

static const void *kTgSuccessTipTextKey = &kTgSuccessTipTextKey;

@implementation TgOrderSuccessPair

+ (instancetype)pairWithOrderId:(NSString *)orderId productId:(NSString *)productId {
    TgOrderSuccessPair *pair = [[TgOrderSuccessPair alloc] init];
    pair.orderId = orderId ?: @"";
    pair.productId = productId ?: @"";
    return pair;
}

@end

@interface TgOrderSuccessVaultController () <UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong) UIScrollView *tg_scrollPane;
@property (nonatomic, strong) UIView *tg_scrollBody;
@property (nonatomic, strong) UILabel *tg_pageTitleCaption;
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
@property (nonatomic, strong) UILabel *tg_durationTitleCaption;
@property (nonatomic, strong) UILabel *tg_durationValueCaption;
@property (nonatomic, strong) UIView *tg_durationDivider;
@property (nonatomic, strong) UIView *tg_noticeBox;
@property (nonatomic, strong) UILabel *tg_noticeCaption;
@property (nonatomic, strong) UIStackView *tg_detailStack;
@property (nonatomic, strong) UIView *tg_confirmBackdrop;
@property (nonatomic, strong) UIButton *tg_confirmLatch;

@property (nonatomic, strong, nullable) UILabel *tg_multiIntroCaption;
@property (nonatomic, strong, nullable) UIStackView *tg_multiProductsStack;
@property (nonatomic, strong, nullable) UIView *tg_multiBottomAnchor;

@property (nonatomic, strong, nullable) TgOrderDetailData *tg_detailData;
@property (nonatomic, copy, nullable) NSArray<TgOrderDetailData *> *tg_multiDetailList;
@property (nonatomic, assign) BOOL tg_multiMode;

@end

@implementation TgOrderSuccessVaultController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.tg_backdropStyle = TgHullBackdropStyleUseBg0;
        self.tg_showsBackButton = YES;
        self.hidesBottomBarWhenPushed = YES;
        _tg_exitMode = TgOrderSuccessExitModeHome;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = nil;
    self.navigationItem.titleView = nil;
    self.tg_multiMode = (self.tg_orderPairs.count > 0);
    [self tg_installFeedbackNavItem];
    if (self.tg_multiMode) {
        [self tg_buildMultiLayout];
        [self tg_loadMultiOrderDetails];
    } else {
        [self tg_buildLayout];
        [self tg_loadOrderDetail];
    }
    [self tg_installBackIntercept];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - Nav

- (void)tg_installFeedbackNavItem {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    NSDictionary *attrs = @{
        NSForegroundColorAttributeName: [UIColor tg_toneFromHex:kTgSuccessFeedbackHex],
        NSFontAttributeName: [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium],
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
    };
    [btn setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Feedback" attributes:attrs]
                   forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(tg_onFeedbackTapped) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
}

- (void)tg_installBackIntercept {
    __weak typeof(self) weakSelf = self;
    self.tg_backInterceptBlock = ^BOOL {
        __strong typeof(weakSelf) self = weakSelf;
        [self tg_finishAndTryReviewGuide];
        return NO;
    };
}

#pragma mark - Shared chrome

- (void)tg_installScrollChrome {
    self.tg_scrollPane = [[UIScrollView alloc] init];
    self.tg_scrollPane.showsVerticalScrollIndicator = NO;
    self.tg_scrollPane.alwaysBounceVertical = YES;
    self.tg_scrollPane.backgroundColor = UIColor.clearColor;
    self.tg_scrollPane.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:self.tg_scrollPane];

    self.tg_scrollBody = [[UIView alloc] init];
    self.tg_scrollBody.backgroundColor = UIColor.clearColor;
    [self.tg_scrollPane addSubview:self.tg_scrollBody];

    self.tg_pageTitleCaption = [[UILabel alloc] init];
    self.tg_pageTitleCaption.text = @"Success!";
    self.tg_pageTitleCaption.font = [UIFont tg_meshGlyphWithSize:32 weight:UIFontWeightBold];
    self.tg_pageTitleCaption.textColor = UIColor.blackColor;
    self.tg_pageTitleCaption.textAlignment = NSTextAlignmentCenter;
    [self.tg_scrollBody addSubview:self.tg_pageTitleCaption];

    self.tg_confirmLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_confirmLatch setTitle:@"Confirm" forState:UIControlStateNormal];
    [self.tg_confirmLatch setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.tg_confirmLatch.titleLabel.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    self.tg_confirmLatch.backgroundColor = [UIColor tg_toneFromHex:kTgSuccessConfirmHex];
    self.tg_confirmLatch.layer.cornerRadius = kTgSuccessConfirmHeight / 2.0;
    self.tg_confirmLatch.clipsToBounds = YES;
    [self.tg_confirmLatch addTarget:self action:@selector(tg_onConfirmTapped) forControlEvents:UIControlEventTouchUpInside];

    self.tg_confirmBackdrop = [[UIView alloc] init];
    self.tg_confirmBackdrop.backgroundColor = [UIColor tg_toneFromHex:kTgSuccessPageBgHex];
    [self.view addSubview:self.tg_confirmBackdrop];
    [self.view addSubview:self.tg_confirmLatch];

    [self.tg_confirmLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(kTgSuccessConfirmWidthRatio);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-16);
        make.height.mas_equalTo(kTgSuccessConfirmHeight);
    }];
    [self.tg_scrollPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset([self tg_contentTopBelowNavigation]);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.tg_confirmLatch.mas_top).offset(-12);
    }];
    [self.tg_confirmBackdrop mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.tg_scrollPane.mas_bottom);
    }];
    [self.tg_pageTitleCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_scrollBody);
        make.left.right.equalTo(self.tg_scrollBody).inset(kTgSuccessHorzInset);
    }];
}

#pragma mark - Multi layout (DC)

- (void)tg_buildMultiLayout {
    [self tg_installScrollChrome];

    self.tg_multiIntroCaption = [[UILabel alloc] init];
    self.tg_multiIntroCaption.text = kTgSuccessMultiIntroText;
    self.tg_multiIntroCaption.font = [UIFont tg_meshGlyphWithSize:12 weight:UIFontWeightRegular];
    self.tg_multiIntroCaption.textColor = UIColor.blackColor;
    self.tg_multiIntroCaption.textAlignment = NSTextAlignmentLeft;
    self.tg_multiIntroCaption.numberOfLines = 0;
    [self.tg_scrollBody addSubview:self.tg_multiIntroCaption];

    self.tg_multiProductsStack = [[UIStackView alloc] init];
    self.tg_multiProductsStack.axis = UILayoutConstraintAxisVertical;
    self.tg_multiProductsStack.spacing = kTgSuccessMultiBlockGap;
    self.tg_multiProductsStack.alignment = UIStackViewAlignmentFill;
    [self.tg_scrollBody addSubview:self.tg_multiProductsStack];

    self.tg_multiBottomAnchor = [[UIView alloc] init];
    self.tg_multiBottomAnchor.backgroundColor = UIColor.clearColor;
    [self.tg_scrollBody addSubview:self.tg_multiBottomAnchor];

    [self.tg_multiIntroCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_pageTitleCaption.mas_bottom).offset(kTgSuccessMultiIntroGap);
        make.left.right.equalTo(self.tg_scrollBody).inset(kTgSuccessHorzInset);
    }];
    [self.tg_multiProductsStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_multiIntroCaption.mas_bottom).offset(20);
        make.left.right.equalTo(self.tg_scrollBody).inset(kTgSuccessHorzInset);
    }];
    [self.tg_multiBottomAnchor mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_multiProductsStack.mas_bottom);
        make.left.right.equalTo(self.tg_scrollBody);
        make.height.mas_equalTo(1);
    }];
    [self.tg_scrollBody mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.tg_scrollPane);
        make.width.equalTo(self.tg_scrollPane);
        make.bottom.equalTo(self.tg_multiBottomAnchor.mas_bottom).offset(24);
    }];
}

- (void)tg_loadMultiOrderDetails {
    NSArray<TgOrderSuccessPair *> *pairs = self.tg_orderPairs ?: @[];
    if (pairs.count == 0) {
        [[TgPulseOverlay shared] whisperLine:kTgSuccessMissingIdsHint duration:2.0];
        return;
    }

    [[TgPulseOverlay shared] veilSpin];
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:pairs.count];
    for (NSUInteger i = 0; i < pairs.count; i++) {
        [results addObject:[NSNull null]];
    }
    dispatch_group_t group = dispatch_group_create();
    __block NSInteger successCount = 0;
    __weak typeof(self) weakSelf = self;

    for (NSUInteger i = 0; i < pairs.count; i++) {
        TgOrderSuccessPair *pair = pairs[i];
        NSString *orderId = [self tg_trimmed:pair.orderId];
        NSString *productId = [self tg_trimmed:pair.productId];
        if (orderId.length == 0 || productId.length == 0) continue;

        NSUInteger idx = i;
        dispatch_group_enter(group);
        [[TgWireConduit shared] relayPOST:TgLaneOrderDetail
                                 signData:@{ @"orderId": orderId }
                               nonSignData:@{ @"productId": productId, @"appType": @"DC" }
                          envelopeSuccess:^(TgEnvelopeBase *envelope) {
            __strong typeof(weakSelf) self = weakSelf;
            if (self && envelope.cheer == 200 && envelope.trick) {
                TgOrderDetailData *data = [TgOrderDetailData yy_modelWithJSON:envelope.trick];
                if (data) {
                    @synchronized (results) {
                        results[idx] = data;
                        successCount += 1;
                    }
                }
            }
            dispatch_group_leave(group);
        } failure:^{
            dispatch_group_leave(group);
        }];
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self tg_finishMultiLoadWithResults:[results copy] successCount:successCount];
    });
}

- (void)tg_finishMultiLoadWithResults:(NSArray *)results successCount:(NSInteger)successCount {
    [[TgPulseOverlay shared] veilDismiss];
    if (successCount <= 0) {
        [[TgPulseOverlay shared] whisperLine:kTgSuccessBusyHint duration:2.0];
        return;
    }
    NSMutableArray<TgOrderDetailData *> *list = [NSMutableArray array];
    for (id item in results) {
        if ([item isKindOfClass:[TgOrderDetailData class]]) {
            [list addObject:item];
        }
    }
    self.tg_multiDetailList = list;
    [self tg_refreshMultiUI];
}

- (void)tg_refreshMultiUI {
    for (UIView *v in self.tg_multiProductsStack.arrangedSubviews) {
        [self.tg_multiProductsStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }

    NSArray<TgOrderDetailData *> *list = self.tg_multiDetailList ?: @[];
    for (NSUInteger i = 0; i < list.count; i++) {
        UIView *block = [self tg_makeMultiProductBlock:list[i] showDivider:(i < list.count - 1)];
        [self.tg_multiProductsStack addArrangedSubview:block];
    }

    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    [self tg_applyScrollContentSize];
}

- (UIView *)tg_makeMultiProductBlock:(TgOrderDetailData *)data showDivider:(BOOL)showDivider {
    TgOrderDetail *detail = data.hillside;
    TgOrderProduct *product = data.invent;

    UIView *block = [[UIView alloc] init];
    block.backgroundColor = UIColor.clearColor;

    UIView *peach = [[UIView alloc] init];
    peach.backgroundColor = UIColor.clearColor;
    peach.layer.cornerRadius = kTgSuccessCardRadius;
    peach.clipsToBounds = YES;
    [block addSubview:peach];

    UIImageView *peachBg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgSuccessPeachBgAsset]];
    peachBg.contentMode = UIViewContentModeScaleAspectFill;
    [peach addSubview:peachBg];

    UIView *productPill = [[UIView alloc] init];
    [peach addSubview:productPill];

    UIImageView *logo = [[UIImageView alloc] init];
    logo.contentMode = UIViewContentModeScaleAspectFit;
    logo.layer.cornerRadius = kTgSuccessLogoCornerRadius;
    logo.clipsToBounds = YES;
    [productPill addSubview:logo];

    UILabel *nameLab = [[UILabel alloc] init];
    nameLab.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightBold];
    nameLab.textColor = [UIColor tg_toneFromHex:kTgSuccessProductNameHex];
    NSString *productName = [self tg_trimmed:product.other];
    if (productName.length == 0) {
        productName = [self tg_trimmed:product.resistance];
    }
    nameLab.text = productName.length > 0 ? productName : [self tg_appDisplayName];
    [productPill addSubview:nameLab];

    NSString *logoURL = [self tg_trimmed:product.green];
    if (logoURL.length > 0) {
        [logo sd_setImageWithURL:[NSURL URLWithString:logoURL] placeholderImage:nil];
    }

    UILabel *amountLab = [[UILabel alloc] init];
    amountLab.font = [UIFont tg_meshGlyphWithSize:28 weight:UIFontWeightBold];
    amountLab.textColor = UIColor.blackColor;
    amountLab.text = [self tg_formatLoanAmountText:detail.inch];
    [peach addSubview:amountLab];

    UILabel *statusLab = [[UILabel alloc] init];
    statusLab.text = kTgSuccessStatusText;
    statusLab.font = [UIFont tg_meshGlyphWithSize:18 weight:UIFontWeightHeavy];
    statusLab.textColor = [UIColor tg_toneFromHex:kTgSuccessStatusHex];
    [peach addSubview:statusLab];

    UIImageView *medal = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgSuccessMedalAsset]];
    medal.contentMode = UIViewContentModeScaleAspectFit;
    [peach addSubview:medal];

    UIStackView *detailStack = [[UIStackView alloc] init];
    detailStack.axis = UILayoutConstraintAxisVertical;
    detailStack.spacing = 0;
    detailStack.alignment = UIStackViewAlignmentFill;
    [block addSubview:detailStack];

    // Loan duration (red value) + divider — design
    UIView *durationRow = [self tg_makeDetailRowWithTitle:@"Loan duration"
                                                    value:[self tg_formatDaysFromDetail:detail]
                                                  tipText:nil
                                               valueColor:[UIColor tg_toneFromHex:kTgSuccessDurationValueHex]];
    [detailStack addArrangedSubview:durationRow];

    UIView *durationDivider = [[UIView alloc] init];
    durationDivider.backgroundColor = [UIColor tg_toneFromHex:kTgSuccessDividerHex];
    [detailStack addArrangedSubview:durationDivider];
    [durationDivider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(1);
    }];

    NSArray<UIView *> *rows = [self tg_detailRowsForDetail:detail includeDuration:NO];
    for (UIView *row in rows) {
        [detailStack addArrangedSubview:row];
    }

    UIView *divider = nil;
    if (showDivider) {
        divider = [[UIView alloc] init];
        divider.backgroundColor = [UIColor tg_toneFromHex:kTgSuccessDividerHex];
        [block addSubview:divider];
    }

    [peach mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(block);
        make.height.equalTo(peach.mas_width).multipliedBy(kTgSuccessPeachBgRatio);
    }];
    [peachBg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(peach);
    }];
    [productPill mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(peach).offset(kTgSuccessPeachTopInset);
        make.left.equalTo(peach).offset(16);
        make.height.mas_equalTo(kTgSuccessProductPillHeight);
        make.right.lessThanOrEqualTo(medal.mas_left).offset(-8);
    }];
    [logo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.centerY.equalTo(productPill);
        make.width.height.mas_equalTo(kTgSuccessMultiLogoSize);
    }];
    [nameLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(logo.mas_right).offset(8);
        make.centerY.equalTo(productPill);
        make.right.lessThanOrEqualTo(productPill);
    }];
    [amountLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(productPill.mas_bottom).offset(kTgSuccessStatusToAmountGap);
        make.left.equalTo(productPill);
        make.right.lessThanOrEqualTo(medal.mas_left).offset(-8);
    }];
    [statusLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(amountLab.mas_bottom).offset(25);
        make.left.equalTo(productPill);
        make.right.lessThanOrEqualTo(medal.mas_left).offset(-8);
        make.bottom.lessThanOrEqualTo(peach).offset(-kTgSuccessProductBottomInset);
    }];
    [medal mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(peach).offset(-8);
        make.centerY.equalTo(peach).offset(4);
        make.width.height.mas_equalTo(88);
    }];
    [detailStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(peach.mas_bottom).offset(8);
        make.left.right.equalTo(block);
        if (!divider) make.bottom.equalTo(block);
    }];
    if (divider) {
        [divider mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(detailStack.mas_bottom).offset(16);
            make.left.right.equalTo(block);
            make.height.mas_equalTo(1);
            make.bottom.equalTo(block);
        }];
    }

    return block;
}

#pragma mark - Single layout (ordinary)

- (void)tg_buildLayout {
    [self tg_installScrollChrome];

    self.tg_mainCard = [[UIView alloc] init];
    self.tg_mainCard.backgroundColor = UIColor.clearColor;
    self.tg_mainCard.clipsToBounds = NO;
    [self.tg_scrollBody addSubview:self.tg_mainCard];

    self.tg_peachVeil = [[UIView alloc] init];
    self.tg_peachVeil.backgroundColor = UIColor.clearColor;
    self.tg_peachVeil.layer.cornerRadius = kTgSuccessCardRadius;
    self.tg_peachVeil.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    self.tg_peachVeil.clipsToBounds = YES;
    [self.tg_mainCard addSubview:self.tg_peachVeil];

    self.tg_peachBgGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgSuccessPeachBgAsset]];
    self.tg_peachBgGlyph.contentMode = UIViewContentModeScaleAspectFill;
    [self.tg_peachVeil addSubview:self.tg_peachBgGlyph];

    self.tg_statusCaption = [[UILabel alloc] init];
    self.tg_statusCaption.text = kTgSuccessStatusText;
    self.tg_statusCaption.font = [UIFont tg_meshGlyphWithSize:18 weight:UIFontWeightBold];
    self.tg_statusCaption.textColor = [UIColor tg_toneFromHex:kTgSuccessStatusHex];
    [self.tg_peachVeil addSubview:self.tg_statusCaption];

    self.tg_amountCaption = [[UILabel alloc] init];
    self.tg_amountCaption.font = [UIFont tg_meshGlyphWithSize:28 weight:UIFontWeightBold];
    self.tg_amountCaption.textColor = UIColor.blackColor;
    self.tg_amountCaption.text = @"-";
    [self.tg_peachVeil addSubview:self.tg_amountCaption];

    self.tg_productPill = [[UIView alloc] init];
    self.tg_productPill.backgroundColor = UIColor.clearColor;
    [self.tg_peachVeil addSubview:self.tg_productPill];

    self.tg_logoGlyph = [[UIImageView alloc] init];
    self.tg_logoGlyph.contentMode = UIViewContentModeScaleAspectFit;
    self.tg_logoGlyph.layer.cornerRadius = kTgSuccessLogoCornerRadius;
    self.tg_logoGlyph.clipsToBounds = YES;
    self.tg_logoGlyph.backgroundColor = UIColor.clearColor;
    [self.tg_productPill addSubview:self.tg_logoGlyph];

    self.tg_nameCaption = [[UILabel alloc] init];
    self.tg_nameCaption.font = [UIFont tg_meshGlyphWithSize:13 weight:UIFontWeightMedium];
    self.tg_nameCaption.textColor = [UIColor tg_toneFromHex:kTgSuccessProductNameHex];
    [self.tg_productPill addSubview:self.tg_nameCaption];

    self.tg_medalGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgSuccessMedalAsset]];
    self.tg_medalGlyph.contentMode = UIViewContentModeScaleAspectFit;
    [self.tg_peachVeil addSubview:self.tg_medalGlyph];

    self.tg_whiteVeil = [[UIView alloc] init];
    self.tg_whiteVeil.backgroundColor = [UIColor tg_toneFromHex:kTgSuccessPageBgHex];
    [self.tg_scrollBody addSubview:self.tg_whiteVeil];

    self.tg_waveCap = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgSuccessWaveAsset]];
    self.tg_waveCap.contentMode = UIViewContentModeScaleToFill;
    self.tg_waveCap.clipsToBounds = NO;
    [self.tg_scrollBody addSubview:self.tg_waveCap];

    self.tg_durationTitleCaption = [[UILabel alloc] init];
    self.tg_durationTitleCaption.text = @"Loan duration";
    self.tg_durationTitleCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    self.tg_durationTitleCaption.textColor = [UIColor tg_toneFromHex:kTgSuccessMutedHex];

    self.tg_durationValueCaption = [[UILabel alloc] init];
    self.tg_durationValueCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightBold];
    self.tg_durationValueCaption.textColor = [UIColor tg_toneFromHex:kTgSuccessDurationValueHex];
    self.tg_durationValueCaption.textAlignment = NSTextAlignmentRight;
    self.tg_durationValueCaption.text = @"-";

    [self.tg_whiteVeil addSubview:self.tg_durationTitleCaption];
    [self.tg_whiteVeil addSubview:self.tg_durationValueCaption];

    self.tg_durationDivider = [[UIView alloc] init];
    self.tg_durationDivider.backgroundColor = [UIColor tg_toneFromHex:kTgSuccessDividerHex];
    [self.tg_whiteVeil addSubview:self.tg_durationDivider];

    self.tg_noticeBox = [[UIView alloc] init];
    self.tg_noticeBox.backgroundColor = [UIColor tg_toneFromHex:kTgSuccessNoticeBgHex];
    self.tg_noticeBox.layer.cornerRadius = 8;
    self.tg_noticeBox.clipsToBounds = YES;
    [self.tg_whiteVeil addSubview:self.tg_noticeBox];

    self.tg_noticeCaption = [[UILabel alloc] init];
    self.tg_noticeCaption.text = kTgSuccessNoticeText;
    self.tg_noticeCaption.font = [UIFont tg_meshGlyphWithSize:13 weight:UIFontWeightRegular];
    self.tg_noticeCaption.textColor = [UIColor tg_toneFromHex:kTgSuccessNoticeTextHex];
    self.tg_noticeCaption.numberOfLines = 0;
    [self.tg_noticeBox addSubview:self.tg_noticeCaption];

    self.tg_detailStack = [[UIStackView alloc] init];
    self.tg_detailStack.axis = UILayoutConstraintAxisVertical;
    self.tg_detailStack.spacing = 0;
    self.tg_detailStack.alignment = UIStackViewAlignmentFill;
    [self.tg_whiteVeil addSubview:self.tg_detailStack];

    [self.tg_scrollBody mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.tg_scrollPane);
        make.width.equalTo(self.tg_scrollPane);
        make.bottom.equalTo(self.tg_whiteVeil.mas_bottom).offset(24);
    }];
    [self.tg_mainCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_pageTitleCaption.mas_bottom).offset(kTgSuccessCardTopInset + kTgSuccessTitleExtraGap);
        make.left.right.equalTo(self.tg_scrollBody).inset(kTgSuccessHorzInset);
        make.bottom.equalTo(self.tg_peachVeil.mas_bottom);
    }];
    [self.tg_peachVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.tg_mainCard);
        make.height.equalTo(self.tg_peachVeil.mas_width).multipliedBy(kTgSuccessPeachBgRatio);
    }];
    [self.tg_peachBgGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_peachVeil);
    }];
    [self.tg_statusCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_peachVeil).offset(kTgSuccessPeachTopInset);
        make.left.equalTo(self.tg_peachVeil).offset(16);
        make.right.lessThanOrEqualTo(self.tg_medalGlyph.mas_left).offset(-8);
    }];
    [self.tg_amountCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_statusCaption.mas_bottom).offset(kTgSuccessStatusToAmountGap);
        make.left.equalTo(self.tg_statusCaption);
        make.right.lessThanOrEqualTo(self.tg_medalGlyph.mas_left).offset(-8);
    }];
    [self.tg_productPill mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_amountCaption.mas_bottom).offset(kTgSuccessAmountToProductGap);
        make.left.equalTo(self.tg_statusCaption);
        make.height.mas_equalTo(kTgSuccessProductPillHeight);
        make.bottom.lessThanOrEqualTo(self.tg_peachVeil).offset(-kTgSuccessProductBottomInset);
    }];
    [self.tg_logoGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.centerY.equalTo(self.tg_productPill);
        make.width.height.mas_equalTo(20);
    }];
    [self.tg_nameCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_logoGlyph.mas_right).offset(8);
        make.centerY.equalTo(self.tg_productPill);
        make.right.lessThanOrEqualTo(self.tg_productPill);
    }];
    [self.tg_medalGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.tg_peachVeil).offset(-8);
        make.centerY.equalTo(self.tg_peachVeil).offset(4);
        make.width.height.mas_equalTo(88);
    }];
    [self.tg_waveCap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.tg_scrollBody);
        make.bottom.equalTo(self.tg_peachVeil.mas_bottom);
        make.height.mas_equalTo(kTgSuccessWaveHeight);
    }];
    [self.tg_whiteVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.tg_scrollBody);
        make.top.equalTo(self.tg_waveCap.mas_bottom);
        make.bottom.equalTo(self.tg_noticeBox.mas_bottom).offset(16);
    }];
    [self.tg_durationTitleCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_whiteVeil).offset(16);
        make.left.equalTo(self.tg_whiteVeil).offset(16);
    }];
    [self.tg_durationValueCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.tg_durationTitleCaption);
        make.right.equalTo(self.tg_whiteVeil).offset(-16);
        make.left.greaterThanOrEqualTo(self.tg_durationTitleCaption.mas_right).offset(8);
    }];
    [self.tg_durationDivider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_durationTitleCaption.mas_bottom).offset(12);
        make.left.right.equalTo(self.tg_whiteVeil).inset(16);
        make.height.mas_equalTo(1);
    }];
    [self.tg_detailStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_durationDivider.mas_bottom).offset(8);
        make.left.right.equalTo(self.tg_whiteVeil).inset(16);
    }];
    [self.tg_detailStack setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                         forAxis:UILayoutConstraintAxisVertical];
    [self.tg_noticeBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_detailStack.mas_bottom).offset(12);
        make.left.right.equalTo(self.tg_whiteVeil).inset(16);
    }];
    [self.tg_noticeCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_noticeBox).insets(UIEdgeInsetsMake(10, 12, 10, 12));
    }];

    [self.tg_scrollBody bringSubviewToFront:self.tg_waveCap];
}

#pragma mark - Data helpers

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
    NSArray *parts = [trim componentsSeparatedByCharactersInSet:nonDigits];
    NSString *digits = [parts componentsJoinedByString:@""];
    return digits;
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

- (NSString *)tg_formatDaysFromDetail:(TgOrderDetail *)detail {
    if (!detail) return @"-";
    NSInteger days = detail.ill > 0 ? detail.ill : detail.culture;
    if (days <= 0) return @"-";
    return [NSString stringWithFormat:@"%ld Days", (long)days];
}

- (NSString *)tg_formatEmiLabel:(NSInteger)emiCount {
    if (emiCount <= 0) return @"-";
    if (emiCount == 1) return @"1 EMI";
    return [NSString stringWithFormat:@"%ld EMIs", (long)emiCount];
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

- (NSString *)tg_appDisplayName {
    NSString *name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    name = [self tg_trimmed:name];
    if (name.length > 0) return name;
    name = [self tg_trimmed:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]];
    return name.length > 0 ? name : @"App";
}

#pragma mark - Single data

- (void)tg_loadOrderDetail {
    NSString *orderId = [self tg_trimmed:self.tg_orderId];
    NSString *productId = [self tg_trimmed:self.tg_productId];
    if (orderId.length == 0 || productId.length == 0) {
        [[TgPulseOverlay shared] whisperLine:kTgSuccessMissingIdsHint duration:2.0];
        return;
    }

    [[TgPulseOverlay shared] veilSpin];
    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneOrderDetail
                             signData:@{ @"orderId": orderId }
                           nonSignData:@{ @"productId": productId, @"appType": @"DC" }
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        __strong typeof(weakSelf) self = weakSelf;
        [[TgPulseOverlay shared] veilDismiss];
        if (envelope.cheer == 200 && envelope.trick) {
            self.tg_detailData = [TgOrderDetailData yy_modelWithJSON:envelope.trick];
            [self tg_refreshUI];
            return;
        }
        NSString *msg = [self tg_trimmed:envelope.power];
        [[TgPulseOverlay shared] whisperLine:msg.length > 0 ? msg : kTgSuccessBusyHint duration:2.0];
    } failure:^{
        __strong typeof(weakSelf) self = weakSelf;
        (void)self;
        [[TgPulseOverlay shared] veilDismiss];
        [[TgPulseOverlay shared] whisperLine:kTgSuccessBusyHint duration:2.0];
    }];
}

- (void)tg_refreshUI {
    TgOrderDetailData *data = self.tg_detailData;
    TgOrderDetail *detail = data.hillside;
    TgOrderProduct *product = data.invent;

    self.tg_amountCaption.text = [self tg_formatLoanAmountText:detail.inch];
    self.tg_durationValueCaption.text = [self tg_formatDaysFromDetail:detail];

    NSString *productName = [self tg_trimmed:product.other];
    self.tg_nameCaption.text = productName.length > 0 ? productName : [self tg_appDisplayName];

    NSString *logoURL = [self tg_trimmed:product.green];
    if (logoURL.length > 0) {
        [self.tg_logoGlyph sd_setImageWithURL:[NSURL URLWithString:logoURL]
                             placeholderImage:nil];
    } else {
        self.tg_logoGlyph.image = nil;
    }

    for (UIView *v in self.tg_detailStack.arrangedSubviews) {
        [self.tg_detailStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }

    NSArray<UIView *> *rows = [self tg_detailRowsForDetail:detail includeDuration:NO];
    for (UIView *row in rows) {
        [self.tg_detailStack addArrangedSubview:row];
    }

    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    [self tg_applyScrollContentSize];
}

- (NSArray<UIView *> *)tg_detailRowsForDetail:(TgOrderDetail *)detail includeDuration:(BOOL)includeDuration {
    NSMutableArray<UIView *> *rows = [NSMutableArray array];
    if (includeDuration) {
        [rows addObject:[self tg_makeDetailRowWithTitle:@"Loan duration"
                                                  value:[self tg_formatDaysFromDetail:detail]
                                                tipText:nil
                                             valueColor:[UIColor tg_toneFromHex:kTgSuccessDurationValueHex]]];
    }

    NSString *payout = [self tg_trimmed:detail.resident];
    NSString *dateTitle = payout.length > 0 ? @"Payment date" : @"Date of application";
    NSString *dateValue = payout.length > 0 ? payout : [self tg_displayOrDash:detail.tailor];

    [rows addObject:[self tg_makeDetailRowWithTitle:@"Amount received"
                                              value:[self tg_formatPlainAmountText:detail.husband]
                                            tipText:kTgSuccessTipAmountReceived
                                         valueColor:nil]];
    [rows addObject:[self tg_makeDetailRowWithTitle:@"Interest"
                                              value:[self tg_formatPlainAmountText:detail.typist]
                                            tipText:kTgSuccessTipInterest
                                         valueColor:nil]];
    [rows addObject:[self tg_makeDetailRowWithTitle:@"Service fee"
                                              value:[self tg_formatPlainAmountText:detail.pit]
                                            tipText:kTgSuccessTipServiceFee
                                         valueColor:nil]];
    [rows addObject:[self tg_makeDetailRowWithTitle:@"GST"
                                              value:[self tg_formatPlainAmountText:detail.feather]
                                            tipText:nil
                                         valueColor:nil]];
    [rows addObject:[self tg_makeDetailRowWithTitle:dateTitle
                                              value:dateValue
                                            tipText:nil
                                         valueColor:nil]];
    [rows addObject:[self tg_makeDetailRowWithTitle:@"Due date"
                                              value:[self tg_displayOrDash:detail.fierce]
                                            tipText:nil
                                         valueColor:nil]];

    if (detail.EMIs > 0) {
        if ([self tg_trimmed:detail.EMIRepayDate].length > 0) {
            [rows addObject:[self tg_makeDetailRowWithTitle:@"1st EMI Date"
                                                      value:[self tg_formatDisplayDate:detail.EMIRepayDate]
                                                    tipText:nil
                                                 valueColor:nil]];
        }
        if ([self tg_trimmed:detail.upright].length > 0) {
            [rows addObject:[self tg_makeDetailRowWithTitle:@"EMI Amount"
                                                      value:[self tg_formatPlainAmountText:detail.upright]
                                                    tipText:nil
                                                 valueColor:nil]];
        }
        [rows addObject:[self tg_makeDetailRowWithTitle:@"EMIs"
                                                  value:[self tg_formatEmiLabel:detail.EMIs]
                                                tipText:nil
                                             valueColor:nil]];
    }
    return rows;
}

- (void)tg_applyScrollContentSize {
    if (!self.tg_scrollPane || !self.tg_scrollBody) return;
    UIView *anchor = self.tg_multiMode ? self.tg_multiBottomAnchor : self.tg_whiteVeil;
    if (!anchor) return;
    [self.tg_scrollBody layoutIfNeeded];
    CGRect frameInScroll = [anchor convertRect:anchor.bounds toView:self.tg_scrollPane];
    CGFloat contentH = ceil(CGRectGetMaxY(frameInScroll) + 24.0);
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

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self tg_applyScrollContentSize];
}

#pragma mark - Detail rows

- (UIView *)tg_makeDetailRowWithTitle:(NSString *)title
                                value:(NSString *)value
                              tipText:(nullable NSString *)tipText {
    return [self tg_makeDetailRowWithTitle:title value:value tipText:tipText valueColor:nil];
}

- (UIView *)tg_makeDetailRowWithTitle:(NSString *)title
                                value:(NSString *)value
                              tipText:(nullable NSString *)tipText
                           valueColor:(nullable UIColor *)valueColor {
    UIView *row = [[UIView alloc] init];

    UIStackView *leftStack = [[UIStackView alloc] init];
    leftStack.axis = UILayoutConstraintAxisHorizontal;
    leftStack.alignment = UIStackViewAlignmentCenter;
    leftStack.spacing = 4;

    UILabel *titleLab = [[UILabel alloc] init];
    titleLab.text = title;
    titleLab.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    titleLab.textColor = [UIColor tg_toneFromHex:kTgSuccessMutedHex];
    [leftStack addArrangedSubview:titleLab];

    if (tipText.length > 0) {
        UIButton *tipBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *tipImg = [UIImage imageNamed:kTgSuccessTipIconAsset];
        [tipBtn setImage:tipImg forState:UIControlStateNormal];
        tipBtn.adjustsImageWhenHighlighted = NO;
        [tipBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(16);
        }];
        objc_setAssociatedObject(tipBtn, kTgSuccessTipTextKey, tipText, OBJC_ASSOCIATION_COPY_NONATOMIC);
        [tipBtn addTarget:self action:@selector(tg_onTipTapped:) forControlEvents:UIControlEventTouchUpInside];
        [leftStack addArrangedSubview:tipBtn];
    }

    UILabel *valueLab = [[UILabel alloc] init];
    valueLab.text = value.length > 0 ? value : @"-";
    valueLab.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightBold];
    valueLab.textColor = valueColor ?: UIColor.blackColor;
    valueLab.textAlignment = NSTextAlignmentRight;

    [row addSubview:leftStack];
    [row addSubview:valueLab];
    [leftStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.centerY.equalTo(row);
        make.right.lessThanOrEqualTo(valueLab.mas_left).offset(-8);
    }];
    [valueLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.centerY.equalTo(row);
    }];
    [row mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(44);
    }];
    return row;
}

#pragma mark - Tip popover

- (void)tg_onTipTapped:(UIButton *)sender {
    NSString *tip = objc_getAssociatedObject(sender, kTgSuccessTipTextKey);
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

#pragma mark - Exit + review

- (void)tg_onConfirmTapped {
    [self tg_finishAndTryReviewGuide];
}

- (void)tg_onFeedbackTapped {
    [self tg_navigateToFeedbackReplacingSelf];
    [self tg_tryReviewGuideAfterDelay];
}

- (void)tg_finishAndTryReviewGuide {
    [self tg_performExitNavigation];
    [self tg_tryReviewGuideAfterDelay];
}

- (void)tg_performExitNavigation {
    if (self.tg_exitMode == TgOrderSuccessExitModeOrderDetail) {
        for (UIViewController *vc in self.navigationController.viewControllers) {
            if ([vc isKindOfClass:[TgOrderDetailVaultController class]]) {
                [self.navigationController popToViewController:vc animated:YES];
                return;
            }
        }
    }
    [self tg_popToLoanHome];
}

- (void)tg_popToLoanHome {
    UITabBarController *dock = self.tabBarController;
    if (dock) {
        dock.selectedIndex = TgDockTabIndexLoan;
        UINavigationController *loanNav = (UINavigationController *)dock.viewControllers[TgDockTabIndexLoan];
        if ([loanNav isKindOfClass:[UINavigationController class]]) {
            [loanNav popToRootViewControllerAnimated:NO];
        }
    }
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)tg_navigateToFeedbackReplacingSelf {
    NSMutableArray<UIViewController *> *stack = [self.navigationController.viewControllers mutableCopy];
    [stack removeObject:self];
    TgFeedbackVaultController *feedback = [[TgFeedbackVaultController alloc] initWithPopToRootOnBack:YES];
    feedback.hidesBottomBarWhenPushed = YES;
    [stack addObject:feedback];
    [self.navigationController setViewControllers:stack animated:YES];
}

- (void)tg_tryReviewGuideAfterDelay {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [TgReviewGuideRelay tg_tryShowReviewGuideOnSubmit:nil onDismiss:nil];
    });
}

@end
