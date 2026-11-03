//
//  TgEmiResultVaultController.m
//

#import "TgEmiResultVaultController.h"
#import "TgEmiPayload.h"
#import "TgDockBarRelay.h"
#import "TgKycPathRelay.h"
#import "TgLoanShellController.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"
#import "TgPulseOverlay.h"
#import "TgWireConduit.h"
#import "NSString+TgGlyph.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>

static CGFloat const kTgEmiResultHorzInset = 16.0;
static CGFloat const kTgEmiResultCardTopInset = 16.0;
static CGFloat const kTgEmiResultCardOverlap = 10.0;
static CGFloat const kTgEmiResultDetailRowHeight = 54.0;
static CGFloat const kTgEmiResultApplyHeight = 50.0;
static CGFloat const kTgEmiResultApplyWidthRatio = 0.85;
static CGFloat const kTgEmiResultTotalPayValueSize = 24.0;
static CGFloat const kTgEmiResultSubValueSize = 20.0;
static CGFloat const kTgEmiResultSubBlockBottomInset = 37.0;
static NSString * const kTgEmiResultBodyHex = @"#F1F1F1";
static NSString * const kTgEmiResultMutedHex = @"#686868";
static NSString * const kTgEmiResultCardCapAsset = @"use_Subtract1";

@interface TgEmiResultVaultController ()

@property (nonatomic, strong) UIView *tg_bodyVeil;
@property (nonatomic, strong) UIScrollView *tg_scrollPane;
@property (nonatomic, strong) UIView *tg_cardSection;
@property (nonatomic, strong) UIImageView *tg_cardTopBg;
@property (nonatomic, strong) UIImageView *tg_cardCap;
@property (nonatomic, strong) UIView *tg_detailBox;
@property (nonatomic, strong) UILabel *tg_totalPayTitle;
@property (nonatomic, strong) UILabel *tg_totalPayValue;
@property (nonatomic, strong) UILabel *tg_monthlyTitle;
@property (nonatomic, strong) UILabel *tg_monthlyValue;
@property (nonatomic, strong) UILabel *tg_interestTitle;
@property (nonatomic, strong) UILabel *tg_interestValue;
@property (nonatomic, strong) UIStackView *tg_detailStack;
@property (nonatomic, strong) UIButton *tg_applyLatch;
@property (nonatomic, assign) NSInteger tg_userStatus;
@property (nonatomic, assign) BOOL tg_userInfoLoaded;

@end

@implementation TgEmiResultVaultController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.tg_backdropStyle = TgHullBackdropStyleUseBg0;
        self.tg_showsBackButton = YES;
        self.hidesBottomBarWhenPushed = YES;
        _tg_userStatus = -1;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self tg_setNavTitleMedium18:@"EMI"];
    [self tg_buildLayout];
    [self tg_refreshSummary];
    [self tg_loadUserInfo];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - Layout

- (UILabel *)tg_mutedCaptionWithSize:(CGFloat)size {
    UILabel *l = [[UILabel alloc] init];
    l.font = [UIFont tg_meshGlyphWithSize:size weight:UIFontWeightRegular];
    l.textColor = [UIColor tg_toneFromHex:kTgEmiResultMutedHex];
    return l;
}

- (UILabel *)tg_boldValueLabelWithSize:(CGFloat)size {
    UILabel *l = [[UILabel alloc] init];
    l.font = [UIFont tg_meshGlyphWithSize:size weight:UIFontWeightBold];
    l.textColor = UIColor.blackColor;
    return l;
}

- (UIView *)tg_makeDetailRowWithTitle:(NSString *)title value:(NSString *)value {
    UIView *row = [[UIView alloc] init];
    row.backgroundColor = [UIColor tg_toneFromHex:kTgEmiResultBodyHex];
    row.layer.cornerRadius = kTgEmiResultDetailRowHeight / 2.0;
    row.clipsToBounds = YES;

    UILabel *left = [[UILabel alloc] init];
    left.text = title;
    left.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    left.textColor = [UIColor tg_toneFromHex:kTgEmiResultMutedHex];

    UILabel *right = [[UILabel alloc] init];
    right.text = value;
    right.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightMedium];
    right.textColor = UIColor.blackColor;
    right.textAlignment = NSTextAlignmentRight;

    [row addSubview:left];
    [row addSubview:right];
    [left mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(row).offset(16);
        make.centerY.equalTo(row);
        make.right.lessThanOrEqualTo(right.mas_left).offset(-8);
    }];
    [right mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(row).offset(-16);
        make.centerY.equalTo(row);
    }];
    [row mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(kTgEmiResultDetailRowHeight);
    }];
    return row;
}

- (void)tg_buildLayout {
    self.tg_bodyVeil = [[UIView alloc] init];
    self.tg_bodyVeil.backgroundColor = [UIColor tg_toneFromHex:kTgEmiResultBodyHex];
    [self.view insertSubview:self.tg_bodyVeil atIndex:1];

    self.tg_applyLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_applyLatch setTitle:@"Apply now" forState:UIControlStateNormal];
    [self.tg_applyLatch setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.tg_applyLatch.titleLabel.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    self.tg_applyLatch.backgroundColor = [UIColor tg_toneFromHex:@"#182040"];
    self.tg_applyLatch.layer.cornerRadius = kTgEmiResultApplyHeight / 2.0;
    self.tg_applyLatch.clipsToBounds = YES;
    self.tg_applyLatch.hidden = YES;
    [self.tg_applyLatch addTarget:self action:@selector(tg_onApplyTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.tg_applyLatch];

    self.tg_scrollPane = [[UIScrollView alloc] init];
    self.tg_scrollPane.showsVerticalScrollIndicator = NO;
    self.tg_scrollPane.alwaysBounceVertical = YES;
    [self.view addSubview:self.tg_scrollPane];

    self.tg_cardSection = [[UIView alloc] init];
    self.tg_cardSection.backgroundColor = UIColor.clearColor;
    [self.tg_scrollPane addSubview:self.tg_cardSection];

    self.tg_cardTopBg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"use_bg_bank"]];
    self.tg_cardTopBg.contentMode = UIViewContentModeScaleToFill;
    self.tg_cardTopBg.clipsToBounds = YES;
    [self.tg_cardSection addSubview:self.tg_cardTopBg];

    self.tg_totalPayTitle = [self tg_mutedCaptionWithSize:13];
    self.tg_totalPayTitle.text = @"Total payment";
    self.tg_totalPayValue = [self tg_boldValueLabelWithSize:kTgEmiResultTotalPayValueSize];
    self.tg_monthlyTitle = [self tg_mutedCaptionWithSize:12];
    self.tg_monthlyTitle.text = @"Monthly EMI";
    self.tg_monthlyValue = [self tg_boldValueLabelWithSize:kTgEmiResultSubValueSize];
    self.tg_interestTitle = [self tg_mutedCaptionWithSize:12];
    self.tg_interestTitle.text = @"Total Interest";
    self.tg_interestValue = [self tg_boldValueLabelWithSize:kTgEmiResultSubValueSize];
    self.tg_interestValue.lineBreakMode = NSLineBreakByClipping;
    [self.tg_interestValue setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                           forAxis:UILayoutConstraintAxisHorizontal];

    [self.tg_cardTopBg addSubview:self.tg_totalPayTitle];
    [self.tg_cardTopBg addSubview:self.tg_totalPayValue];
    [self.tg_cardTopBg addSubview:self.tg_monthlyTitle];
    [self.tg_cardTopBg addSubview:self.tg_monthlyValue];
    [self.tg_cardTopBg addSubview:self.tg_interestTitle];
    [self.tg_cardTopBg addSubview:self.tg_interestValue];

    UIImageView *star = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"use_loan_star"]];
    star.contentMode = UIViewContentModeScaleAspectFit;
    [self.tg_cardTopBg addSubview:star];

    self.tg_cardCap = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgEmiResultCardCapAsset]];
    self.tg_cardCap.contentMode = UIViewContentModeScaleToFill;
    [self.tg_cardSection addSubview:self.tg_cardCap];

    self.tg_detailBox = [[UIView alloc] init];
    self.tg_detailBox.backgroundColor = UIColor.whiteColor;
    self.tg_detailBox.layer.cornerRadius = 16;
    self.tg_detailBox.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    self.tg_detailBox.clipsToBounds = YES;
    [self.tg_cardSection addSubview:self.tg_detailBox];

    self.tg_detailStack = [[UIStackView alloc] init];
    self.tg_detailStack.axis = UILayoutConstraintAxisVertical;
    self.tg_detailStack.spacing = 10;
    [self.tg_detailBox addSubview:self.tg_detailStack];

    UIImage *topImg = [UIImage imageNamed:@"use_bg_bank"];
    UIImage *capImg = [UIImage imageNamed:kTgEmiResultCardCapAsset];
    CGFloat topRatio = (topImg.size.width > 0) ? (topImg.size.height / topImg.size.width) : 0.55;
    CGFloat capRatio = (capImg.size.width > 0) ? (capImg.size.height / capImg.size.width) : 0.18;

    [self.tg_bodyVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset([self tg_contentTopBelowNavigation]);
        make.bottom.equalTo(self.tg_applyLatch.mas_top).offset(-12);
    }];
    [self.tg_applyLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(kTgEmiResultApplyWidthRatio);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-16);
        make.height.mas_equalTo(kTgEmiResultApplyHeight);
    }];
    [self.tg_scrollPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_bodyVeil);
    }];
    [self.tg_cardSection mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_scrollPane).offset(kTgEmiResultCardTopInset);
        make.left.equalTo(self.tg_scrollPane).offset(kTgEmiResultHorzInset);
        make.width.equalTo(self.tg_scrollPane).offset(-kTgEmiResultHorzInset * 2);
        make.bottom.equalTo(self.tg_scrollPane).offset(-24);
    }];
    [self.tg_cardTopBg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.tg_cardSection);
        make.height.equalTo(self.tg_cardTopBg.mas_width).multipliedBy(topRatio);
    }];
    [self.tg_cardCap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.tg_cardSection);
        make.top.equalTo(self.tg_cardTopBg.mas_bottom).offset(-kTgEmiResultCardOverlap);
        make.height.equalTo(self.tg_cardCap.mas_width).multipliedBy(capRatio);
    }];
    [self.tg_detailBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.tg_cardSection);
        make.top.equalTo(self.tg_cardCap.mas_bottom);
        make.bottom.equalTo(self.tg_cardSection);
    }];
    [self.tg_detailStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_detailBox).insets(UIEdgeInsetsMake(16, 12, 16, 12));
    }];

    [self.tg_totalPayValue mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_cardTopBg).offset(18);
        make.left.equalTo(self.tg_cardTopBg).offset(20);
        make.right.lessThanOrEqualTo(star.mas_left).offset(-8);
    }];
    [self.tg_totalPayTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_totalPayValue.mas_bottom).offset(4);
        make.left.equalTo(self.tg_totalPayValue);
        make.right.lessThanOrEqualTo(star.mas_left).offset(-8);
    }];
    [self.tg_monthlyTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_totalPayValue);
        make.right.equalTo(self.tg_cardTopBg.mas_centerX).offset(-6);
        make.bottom.equalTo(self.tg_cardTopBg).offset(-kTgEmiResultSubBlockBottomInset);
    }];
    [self.tg_monthlyValue mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.tg_monthlyTitle);
        make.bottom.equalTo(self.tg_monthlyTitle.mas_top).offset(-2);
    }];
    [self.tg_interestTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_cardTopBg.mas_centerX).offset(6);
        make.right.equalTo(star.mas_left).offset(-8);
        make.bottom.equalTo(self.tg_monthlyTitle);
    }];
    [self.tg_interestValue mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_interestTitle);
        make.right.equalTo(self.tg_interestTitle);
        make.bottom.equalTo(self.tg_interestTitle.mas_top).offset(-2);
    }];
    [star mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.tg_cardTopBg).offset(-12);
        make.centerY.equalTo(self.tg_cardTopBg).offset(4);
        make.width.height.mas_equalTo(64);
    }];
    [star setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
}

#pragma mark - Display

- (NSString *)tg_rupeeFromAmount:(double)value {
    long long rounded = (long long)llround(value);
    NSString *digits = [NSString stringWithFormat:@"%lld", (long long)rounded];
    return [NSString stringWithFormat:@"₹%@", [NSString tg_weaveIndianDigits:digits]];
}

- (NSString *)tg_indianAmountText:(NSInteger)amount {
    return [NSString tg_weaveIndianDigits:[NSString stringWithFormat:@"%ld", (long)amount]];
}

- (void)tg_refreshSummary {
    TgEmiInputBundle *input = self.tg_inputBundle;
    TgEmiResultBundle *result = self.tg_resultBundle;
    if (!input || !result) return;

    self.tg_totalPayValue.text = [self tg_rupeeFromAmount:result.totalPayment];
    self.tg_monthlyValue.text = [self tg_rupeeFromAmount:result.monthlyEmi];
    self.tg_interestValue.text = [self tg_rupeeFromAmount:result.totalInterest];

    for (UIView *v in self.tg_detailStack.arrangedSubviews) {
        [self.tg_detailStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"Loan amount"
                                                                     value:[self tg_rupeeFromAmount:input.amount]]];
    [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"Interest rate"
                                                                     value:[NSString stringWithFormat:@"%ld%%", (long)input.interestRatePercent]]];
    [self.tg_detailStack addArrangedSubview:[self tg_makeDetailRowWithTitle:@"Duration"
                                                                     value:[NSString stringWithFormat:@"%ld Year", (long)input.durationYears]]];
}

- (void)tg_refreshApplyVisibility {
    BOOL show = (self.tg_userStatus == 10 || self.tg_userStatus == 20);
    self.tg_applyLatch.hidden = !show;
    [self.tg_applyLatch mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(show ? kTgEmiResultApplyHeight : 0);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(show ? -16 : 0);
    }];
}

#pragma mark - User Info

- (void)tg_loadUserInfo {
    [[TgPulseOverlay shared] veilSpin];
    [[TgWireConduit shared] relayPOST:TgLaneUserInfo
                             signData:@{}
                           nonSignData:@{}
                              success:^(id _Nullable data) {
        [[TgPulseOverlay shared] veilDismiss];
        TgUserInfoData *user = [TgUserInfoData yy_modelWithJSON:data];
        self.tg_userStatus = user.telescope;
        self.tg_userInfoLoaded = YES;
        [self tg_refreshApplyVisibility];
    } failure:^{
        [[TgPulseOverlay shared] veilDismiss];
        self.tg_userStatus = -1;
        self.tg_userInfoLoaded = YES;
        [self tg_refreshApplyVisibility];
    }];
}

#pragma mark - Actions

- (void)tg_onApplyTap {
    if (self.tg_userStatus == 10) {
        [TgKycPathRelay startAuthFromNav:self.navigationController];
        return;
    }
    if (self.tg_userStatus == 20) {
        [self tg_navigateToLoanHomeAndScrollFirstProduct];
    }
}

- (void)tg_navigateToLoanHomeAndScrollFirstProduct {
    UITabBarController *dock = self.tabBarController;
    if (!dock) {
        return;
    }

    [TgLoanShellController tg_requestScrollToFirstProduct];

    dock.selectedIndex = TgDockTabIndexLoan;
    UINavigationController *loanNav = (UINavigationController *)dock.viewControllers[TgDockTabIndexLoan];
    if ([loanNav isKindOfClass:[UINavigationController class]]) {
        [loanNav popToRootViewControllerAnimated:NO];
    }
    [self.navigationController popToRootViewControllerAnimated:YES];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [TgLoanShellController tg_requestScrollToFirstProduct];
    });
}

@end
