//
//  TgEmiCalcVaultController.m
//

#import "TgEmiCalcVaultController.h"
#import "TgEmiResultVaultController.h"
#import "TgEmiInputRow.h"
#import "TgEmiPayload.h"
#import "TgKycFormCell.h"
#import "TgPulseOverlay.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>

static CGFloat const kTgEmiCalcHorzInset = 16.0;
static CGFloat const kTgEmiCalcContentTopInset = 31.0;
static CGFloat const kTgEmiCalcSubmitHeight = 50.0;
static CGFloat const kTgEmiCalcSubmitWidthRatio = 0.85;
static NSString * const kTgEmiCalcBodyHex = @"#F1F1F1";

static NSInteger const kTgEmiAmountMin = 1;
static NSInteger const kTgEmiAmountMax = 10000000;
static NSInteger const kTgEmiDurationMin = 1;
static NSInteger const kTgEmiDurationMax = 25;
static NSInteger const kTgEmiRateMin = 1;
static NSInteger const kTgEmiRateMax = 22;

@interface TgEmiCalcVaultController ()

@property (nonatomic, strong) UIView *tg_bodyVeil;
@property (nonatomic, strong) UIScrollView *tg_scrollPane;
@property (nonatomic, strong) UIStackView *tg_formStack;
@property (nonatomic, strong) TgEmiInputRow *tg_amountRow;
@property (nonatomic, strong) TgEmiInputRow *tg_rateRow;
@property (nonatomic, strong) TgEmiInputRow *tg_durationRow;
@property (nonatomic, strong) UIButton *tg_submitLatch;

@end

@implementation TgEmiCalcVaultController

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
    [self tg_setNavTitleMedium18:@"EMI"];
    [self tg_buildLayout];
    [self tg_applyDefaults];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - Layout

- (void)tg_buildLayout {
    self.tg_bodyVeil = [[UIView alloc] init];
    self.tg_bodyVeil.backgroundColor = [UIColor tg_toneFromHex:kTgEmiCalcBodyHex];
    [self.view insertSubview:self.tg_bodyVeil atIndex:1];

    self.tg_submitLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_submitLatch setTitle:@"Submit" forState:UIControlStateNormal];
    [self.tg_submitLatch setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.tg_submitLatch.titleLabel.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    self.tg_submitLatch.backgroundColor = [UIColor tg_toneFromHex:@"#182040"];
    self.tg_submitLatch.layer.cornerRadius = kTgEmiCalcSubmitHeight / 2.0;
    self.tg_submitLatch.clipsToBounds = YES;
    [self.tg_submitLatch addTarget:self action:@selector(tg_onSubmitTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.tg_submitLatch];

    self.tg_scrollPane = [[UIScrollView alloc] init];
    self.tg_scrollPane.showsVerticalScrollIndicator = NO;
    self.tg_scrollPane.alwaysBounceVertical = YES;
    self.tg_scrollPane.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:self.tg_scrollPane];

    self.tg_formStack = [[UIStackView alloc] init];
    self.tg_formStack.axis = UILayoutConstraintAxisVertical;
    self.tg_formStack.spacing = TgKycFormCellStackSpacing;
    self.tg_formStack.alignment = UIStackViewAlignmentFill;
    [self.tg_scrollPane addSubview:self.tg_formStack];

    self.tg_amountRow = [[TgEmiInputRow alloc] init];
    [self.tg_amountRow tg_configureWithTitle:@"Loan amount"
                                 placeholder:@"Please enter"
                                        hint:@"1~1,00,00,000"
                                      format:TgEmiInputRowFormatIndianAmount
                                    maxValue:kTgEmiAmountMax];

    self.tg_rateRow = [[TgEmiInputRow alloc] init];
    [self.tg_rateRow tg_configureWithTitle:@"Interest rate"
                               placeholder:@"Please enter"
                                      hint:@"1~22"
                                    format:TgEmiInputRowFormatPlainDigits
                                  maxValue:kTgEmiRateMax];

    self.tg_durationRow = [[TgEmiInputRow alloc] init];
    [self.tg_durationRow tg_configureWithTitle:@"Duration"
                                   placeholder:@"Please enter"
                                          hint:@"1~25"
                                        format:TgEmiInputRowFormatPlainDigits
                                      maxValue:kTgEmiDurationMax];

    [self.tg_formStack addArrangedSubview:self.tg_amountRow];
    [self.tg_formStack addArrangedSubview:self.tg_rateRow];
    [self.tg_formStack addArrangedSubview:self.tg_durationRow];

    [self.tg_bodyVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset([self tg_contentTopBelowNavigation]);
        make.bottom.equalTo(self.tg_submitLatch.mas_top).offset(-12);
    }];
    [self.tg_submitLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(kTgEmiCalcSubmitWidthRatio);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-16);
        make.height.mas_equalTo(kTgEmiCalcSubmitHeight);
    }];
    [self.tg_scrollPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_bodyVeil);
    }];
    [self.tg_formStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_scrollPane).insets(UIEdgeInsetsMake(kTgEmiCalcContentTopInset, kTgEmiCalcHorzInset, 24, kTgEmiCalcHorzInset));
        make.width.equalTo(self.tg_scrollPane).offset(-kTgEmiCalcHorzInset * 2);
    }];
}

- (void)tg_applyDefaults {
    [self.tg_amountRow tg_setRawDigitsText:@"50000"];
    [self.tg_rateRow tg_setRawDigitsText:@"3"];
    [self.tg_durationRow tg_setRawDigitsText:@"5"];
}

#pragma mark - Submit

- (NSInteger)tg_parseIntFromRow:(TgEmiInputRow *)row {
    NSString *raw = [row tg_rawDigitsText];
    return raw.length > 0 ? raw.integerValue : 0;
}

- (void)tg_onSubmitTap {
    NSInteger amount = [self tg_parseIntFromRow:self.tg_amountRow];
    NSInteger rate = [self tg_parseIntFromRow:self.tg_rateRow];
    NSInteger duration = [self tg_parseIntFromRow:self.tg_durationRow];

    if (amount < kTgEmiAmountMin || amount > kTgEmiAmountMax) {
        [[TgPulseOverlay shared] whisperLine:@"Loan amount should fall between 1 and 1,00,00,000"];
        return;
    }
    if (duration < kTgEmiDurationMin || duration > kTgEmiDurationMax) {
        [[TgPulseOverlay shared] whisperLine:@"Duration should fall between 1 and 25 years"];
        return;
    }
    if (rate < kTgEmiRateMin || rate > kTgEmiRateMax) {
        [[TgPulseOverlay shared] whisperLine:@"Interest rate should fall between 1% and 22%"];
        return;
    }

    TgEmiInputBundle *input = [[TgEmiInputBundle alloc] init];
    input.amount = amount;
    input.durationYears = duration;
    input.interestRatePercent = rate;
    TgEmiResultBundle *result = [TgEmiResultBundle bundleComputedFromInput:input];

    TgEmiResultVaultController *resultVC = [[TgEmiResultVaultController alloc] init];
    resultVC.tg_inputBundle = input;
    resultVC.tg_resultBundle = result;
    resultVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:resultVC animated:YES];
}

@end
