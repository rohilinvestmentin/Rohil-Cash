//

//

#import "TgScoreDetailVaultController.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>

static CGFloat const kTgScoreDetailHorzInset = 16.0;

static CGFloat const kTgScoreDetailScoreSide = 230.0;
static CGFloat const kTgScoreDetailCurveHeight = 36.0;
static CGFloat const kTgScoreDetailCurveBelowScore = 20.0;
static CGFloat const kTgScoreDetailScoreTopBelowSafe = 20.0;
static NSString * const kTgScoreDetailBackAsset = @"gst_tab";
static CGFloat const kTgScoreDetailScoreContentSpacing = 15.0;
static CGFloat const kTgScoreDetailScoreTitleFontSize = 16.0;
static CGFloat const kTgScoreDetailScoreRowSpacing = 4.0;
static CGFloat const kTgScoreDetailScoreArrowPlaceholderSide = 20.0;
static CGFloat const kTgScoreDetailScoreContentHorzInset = 8.0;
static CGFloat const kTgScoreDetailNoticeBottomSpacing = 12.0;
static CGFloat const kTgScoreDetailScrollBottomInset = 24.0;
static NSString * const kTgScoreDetailBgAsset = @"bg";
static NSString * const kTgScoreDetailScoreAsset = @"use_Score";
static NSString * const kTgScoreDetailScoreArrowAsset = @"use_next_loan_bai";
static NSString * const kTgScoreDetailCurveAsset = @"use_bg_kyc";
static NSString * const kTgScoreDetailBodyHex = @"#FCF4EE";
static NSString * const kTgScoreDetailNoticeHex = @"#EA834C";
static NSString * const kTgScoreDetailNoticeText =
    @"If you have questions, please keep the proof and reach out to customer service";
static NSString * const kTgScoreDetailBodyText =
    @"Our credit scoring system carefully assesses your credit risk by reviewing your overall financial profile. It weighs factors such as payment history, credit card usage, outstanding balances, length of credit history, and how often you seek new credit, giving lenders a solid basis for decisions. Whether you apply for a loan, a credit card, or another financial product, our scoring provides dependable financial guidance.";

@interface TgScoreDetailVaultController ()

@property (nonatomic, strong) UIScrollView *tg_scrollPane;
@property (nonatomic, strong) UIView *tg_scrollBody;
@property (nonatomic, strong) UIImageView *tg_bgGlyph;
@property (nonatomic, strong) UIImageView *tg_scoreGlyph;
@property (nonatomic, strong) UIImageView *tg_curveGlyph;
@property (nonatomic, strong) UIView *tg_contentVeil;
@property (nonatomic, strong) UIView *tg_noticeBox;
@property (nonatomic, strong) UILabel *tg_noticeCaption;
@property (nonatomic, strong) UILabel *tg_bodyCaption;

@end

@implementation TgScoreDetailVaultController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.tg_backdropStyle = TgHullBackdropStylePlain;
        self.tg_showsBackButton = YES;
        self.tg_backButtonImageName = kTgScoreDetailBackAsset;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor tg_toneFromHex:kTgScoreDetailBodyHex];
    [self tg_setNavTitle:@"Credit Score" color:UIColor.whiteColor fontSize:18];
    [self tg_buildLayout];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    self.navigationController.navigationBar.tintColor = UIColor.whiteColor;
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    CGFloat safeTop = self.view.safeAreaInsets.top;
    [self.tg_scoreGlyph mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_scrollBody).offset(safeTop + kTgScoreDetailScoreTopBelowSafe);
    }];
    CGFloat bottomPad = kTgScoreDetailScrollBottomInset + self.view.safeAreaInsets.bottom;
    [self.tg_bodyCaption mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.tg_scrollBody).offset(-bottomPad);
    }];
}

#pragma mark - Layout

- (UILabel *)tg_makeCaptionWithSize:(CGFloat)size weight:(UIFontWeight)weight color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont tg_meshGlyphWithSize:size weight:weight];
    label.textColor = color;
    label.numberOfLines = 0;
    return label;
}

- (void)tg_buildScoreBubbleContent {

    UILabel *title = [self tg_makeCaptionWithSize:kTgScoreDetailScoreTitleFontSize weight:UIFontWeightBold color:UIColor.whiteColor];
    title.text = @"Credit Score";
    title.textAlignment = NSTextAlignmentCenter;

    UILabel *value = [self tg_makeCaptionWithSize:34 weight:UIFontWeightBold color:UIColor.whiteColor];
    value.text = @"816 /";
    value.textAlignment = NSTextAlignmentCenter;

    UILabel *grade = [self tg_makeCaptionWithSize:16 weight:UIFontWeightMedium color:[UIColor tg_toneFromHex:@"#F7FF00"]];
    grade.text = @"Excellent";
    grade.textAlignment = NSTextAlignmentCenter;

    UIStackView *scoreRow = [[UIStackView alloc] initWithArrangedSubviews:@[value, grade]];
    scoreRow.axis = UILayoutConstraintAxisHorizontal;
    scoreRow.alignment = UIStackViewAlignmentLastBaseline;
    scoreRow.spacing = kTgScoreDetailScoreRowSpacing;
    scoreRow.userInteractionEnabled = NO;

    UIImage *arrowImg = [UIImage imageNamed:@"use_next_loan0"] ?: [UIImage imageNamed:kTgScoreDetailScoreArrowAsset];
    UIImageView *arrowPlaceholder = [[UIImageView alloc] initWithImage:arrowImg];
    arrowPlaceholder.alpha = 0;
    arrowPlaceholder.contentMode = UIViewContentModeScaleAspectFit;
    arrowPlaceholder.userInteractionEnabled = NO;
    [arrowPlaceholder mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(kTgScoreDetailScoreArrowPlaceholderSide);
    }];

    UIStackView *scoreContent = [[UIStackView alloc] initWithArrangedSubviews:@[title, scoreRow, arrowPlaceholder]];
    scoreContent.axis = UILayoutConstraintAxisVertical;
    scoreContent.alignment = UIStackViewAlignmentCenter;
    scoreContent.spacing = kTgScoreDetailScoreContentSpacing;
    scoreContent.userInteractionEnabled = NO;

    [self.tg_scoreGlyph addSubview:scoreContent];
    [scoreContent mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.tg_scoreGlyph);
        make.left.greaterThanOrEqualTo(self.tg_scoreGlyph).offset(kTgScoreDetailScoreContentHorzInset);
        make.right.lessThanOrEqualTo(self.tg_scoreGlyph).offset(-kTgScoreDetailScoreContentHorzInset);
    }];
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

    self.tg_bgGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgScoreDetailBgAsset]];
    self.tg_bgGlyph.contentMode = UIViewContentModeScaleAspectFill;
    self.tg_bgGlyph.clipsToBounds = YES;
    [self.tg_scrollBody addSubview:self.tg_bgGlyph];

    self.tg_scoreGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgScoreDetailScoreAsset]];
    self.tg_scoreGlyph.contentMode = UIViewContentModeScaleAspectFit;
    self.tg_scoreGlyph.userInteractionEnabled = NO;
    [self.tg_scrollBody addSubview:self.tg_scoreGlyph];
    [self tg_buildScoreBubbleContent];

    self.tg_curveGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgScoreDetailCurveAsset]];
    self.tg_curveGlyph.contentMode = UIViewContentModeScaleToFill;
    self.tg_curveGlyph.clipsToBounds = YES;
    [self.tg_scrollBody addSubview:self.tg_curveGlyph];

    self.tg_contentVeil = [[UIView alloc] init];
    self.tg_contentVeil.backgroundColor = [UIColor tg_toneFromHex:kTgScoreDetailBodyHex];
    [self.tg_scrollBody addSubview:self.tg_contentVeil];

    self.tg_noticeBox = [[UIView alloc] init];
    self.tg_noticeBox.backgroundColor = [UIColor colorWithRed:234/255.0 green:131/255.0 blue:76/255.0 alpha:0.12];
    self.tg_noticeBox.layer.cornerRadius = 12;
    self.tg_noticeBox.clipsToBounds = YES;
    [self.tg_contentVeil addSubview:self.tg_noticeBox];

    self.tg_noticeCaption = [self tg_makeCaptionWithSize:12 weight:UIFontWeightRegular color:[UIColor tg_toneFromHex:kTgScoreDetailNoticeHex]];
    self.tg_noticeCaption.text = kTgScoreDetailNoticeText;
    self.tg_noticeCaption.textAlignment = NSTextAlignmentLeft;
    [self.tg_noticeBox addSubview:self.tg_noticeCaption];

    self.tg_bodyCaption = [self tg_makeCaptionWithSize:15 weight:UIFontWeightRegular color:[UIColor tg_toneFromHex:@"#364153"]];
    self.tg_bodyCaption.text = kTgScoreDetailBodyText;
    self.tg_bodyCaption.textAlignment = NSTextAlignmentLeft;
    [self.tg_contentVeil addSubview:self.tg_bodyCaption];

    [self.tg_scrollPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self.tg_scrollBody mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.width.equalTo(self.tg_scrollPane);
    }];
    [self.tg_scoreGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.tg_scrollBody);
        make.top.equalTo(self.tg_scrollBody).offset(kTgScoreDetailScoreTopBelowSafe);
        make.width.height.mas_equalTo(kTgScoreDetailScoreSide);
    }];
    [self.tg_curveGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_scoreGlyph.mas_bottom).offset(kTgScoreDetailCurveBelowScore);
        make.left.right.equalTo(self.tg_scrollBody);
        make.height.mas_equalTo(kTgScoreDetailCurveHeight);
    }];
    [self.tg_bgGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.tg_scrollBody);
        make.bottom.equalTo(self.tg_curveGlyph.mas_bottom);
    }];
    [self.tg_contentVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_curveGlyph.mas_bottom);
        make.left.right.equalTo(self.tg_scrollBody);
        make.bottom.equalTo(self.tg_bodyCaption);
    }];
    [self.tg_noticeBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_contentVeil);
        make.left.equalTo(self.tg_contentVeil).offset(kTgScoreDetailHorzInset);
        make.right.equalTo(self.tg_contentVeil).offset(-kTgScoreDetailHorzInset);
    }];
    [self.tg_noticeCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_noticeBox).insets(UIEdgeInsetsMake(14, 14, 14, 14));
    }];
    [self.tg_bodyCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_noticeBox.mas_bottom).offset(kTgScoreDetailNoticeBottomSpacing);
        make.left.right.equalTo(self.tg_noticeCaption);
        make.bottom.equalTo(self.tg_scrollBody).offset(-kTgScoreDetailScrollBottomInset);
    }];
}

@end
