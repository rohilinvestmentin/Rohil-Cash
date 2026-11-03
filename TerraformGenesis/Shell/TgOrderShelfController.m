//

//

#import "TgOrderShelfController.h"
#import "TgOrderDetailVaultController.h"
#import "TgOrderWithdrawVaultController.h"
#import "TgOrderStatusDisplay.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"
#import "TgPulseOverlay.h"
#import "TgRejectWebController.h"
#import "TgWireConduit.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>

static CGFloat const kTgOrderShelfHorzInset = 16.0;
static CGFloat const kTgOrderShelfSectionSpacing = 12.0;
static CGFloat const kTgOrderShelfHeaderHeight = 54.0;
static CGFloat const kTgOrderShelfEmptyMinHeight = 100.0;
static CGFloat const kTgOrderShelfCardRadius = 16.0;
static CGFloat const kTgOrderShelfInnerCardRadius = 12.0;
static NSString * const kTgOrderShelfBannerAsset = @"use_order";
static CGFloat const kTgOrderShelfBannerDesignWidth = 343.0;
static CGFloat const kTgOrderShelfBannerDesignHeight = 94.0;
static CGFloat const kTgOrderShelfTitleTopExtra = 8.0;
static CGFloat const kTgOrderShelfBannerBelowTitle = 30.0;
static CGFloat const kTgOrderShelfGradientDesignWidth = 375.0;
static CGFloat const kTgOrderShelfGradientDesignHeight = 496.0;
static CGFloat const kTgOrderShelfScrollBottomInset = 24.0;
static NSString * const kTgOrderShelfArrowCollapsedAsset = @"use_next_loan_xia";
static NSString * const kTgOrderShelfArrowExpandedAsset = @"use_next_loan_shang";
static NSString * const kTgOrderShelfBusyHint = @"The system is occupied. Please retry after 2 minutes.";

#pragma mark - Item card

@interface TgOrderShelfItemView : UIView
@property (nonatomic, copy, nullable) void (^tg_onTap)(void);
- (void)tg_configureWithItem:(TgOrderItem *)item;
@end

@interface TgOrderShelfItemView ()
@property (nonatomic, strong) UILabel *tg_dateTitleCaption;
@property (nonatomic, strong) UILabel *tg_dateValueCaption;
@property (nonatomic, strong) UILabel *tg_amountCaption;
@property (nonatomic, strong) UILabel *tg_statusCaption;
@property (nonatomic, strong) UILabel *tg_productCaption;
@end

@implementation TgOrderShelfItemView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.userInteractionEnabled || self.hidden || self.alpha < 0.01) {
        return [super hitTest:point withEvent:event];
    }
    if ([self pointInside:point withEvent:event]) {
        return self;
    }
    return nil;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor tg_toneFromHex:@"#F1F1F1"];
        self.layer.cornerRadius = kTgOrderShelfInnerCardRadius;
        self.clipsToBounds = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tg_tapped)];
        [self addGestureRecognizer:tap];
        [self tg_buildUI];
    }
    return self;
}

- (void)tg_buildUI {
    self.tg_dateTitleCaption = [[UILabel alloc] init];
    self.tg_dateTitleCaption.font = [UIFont tg_meshGlyphWithSize:12 weight:UIFontWeightRegular];
    self.tg_dateTitleCaption.textColor = [UIColor tg_toneFromHex:@"#9CA3AF"];

    self.tg_dateValueCaption = [[UILabel alloc] init];
    self.tg_dateValueCaption.font = [UIFont tg_meshGlyphWithSize:12 weight:UIFontWeightMedium];
    self.tg_dateValueCaption.textColor = [UIColor tg_toneFromHex:@"#364153"];
    self.tg_dateValueCaption.textAlignment = NSTextAlignmentRight;

    self.tg_amountCaption = [[UILabel alloc] init];
    self.tg_amountCaption.font = [UIFont tg_meshGlyphWithSize:20 weight:UIFontWeightBold];
    self.tg_amountCaption.textColor = [UIColor tg_toneFromHex:@"#364153"];
    self.tg_amountCaption.textAlignment = NSTextAlignmentCenter;

    self.tg_statusCaption = [[UILabel alloc] init];
    self.tg_statusCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightMedium];
    self.tg_statusCaption.textAlignment = NSTextAlignmentCenter;

    self.tg_productCaption = [[UILabel alloc] init];
    self.tg_productCaption.font = [UIFont tg_meshGlyphWithSize:12 weight:UIFontWeightRegular];
    self.tg_productCaption.textColor = [UIColor tg_toneFromHex:@"#9CA3AF"];
    self.tg_productCaption.textAlignment = NSTextAlignmentCenter;

    [self addSubview:self.tg_dateTitleCaption];
    [self addSubview:self.tg_dateValueCaption];
    [self addSubview:self.tg_amountCaption];
    [self addSubview:self.tg_statusCaption];
    [self addSubview:self.tg_productCaption];

    [self.tg_dateTitleCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(14);
        make.top.equalTo(self).offset(14);
    }];
    [self.tg_dateValueCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-14);
        make.centerY.equalTo(self.tg_dateTitleCaption);
        make.left.greaterThanOrEqualTo(self.tg_dateTitleCaption.mas_right).offset(8);
    }];
    [self.tg_amountCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(14);
        make.right.equalTo(self).offset(-14);
        make.top.equalTo(self.tg_dateTitleCaption.mas_bottom).offset(12);
    }];
    [self.tg_statusCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.tg_amountCaption);
        make.top.equalTo(self.tg_amountCaption.mas_bottom).offset(6);
    }];
    [self.tg_productCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.tg_amountCaption);
        make.top.equalTo(self.tg_statusCaption.mas_bottom).offset(8);
        make.bottom.equalTo(self).offset(-14);
    }];
}

- (void)tg_configureWithItem:(TgOrderItem *)item {
    self.tg_dateTitleCaption.text = [TgOrderStatusDisplay tg_dateTitleForOrderStatus:item.intellectual];
    self.tg_dateValueCaption.text = [TgOrderStatusDisplay tg_dateValueForItem:item];
    self.tg_amountCaption.text = [TgOrderStatusDisplay tg_formattedAmountFromLoanAmount:item.inch];
    self.tg_statusCaption.text = [TgOrderStatusDisplay tg_titleForOrderStatus:item.intellectual];
    self.tg_statusCaption.textColor = [TgOrderStatusDisplay tg_colorForOrderStatus:item.intellectual];
    self.tg_productCaption.text = [TgOrderStatusDisplay tg_displayOrDash:item.other];
}

- (void)tg_tapped {
    if (self.tg_onTap) self.tg_onTap();
}

@end

#pragma mark - Section

@interface TgOrderShelfSectionView : UIView
@property (nonatomic, copy) NSString *tg_title;
@property (nonatomic, copy) NSString *tg_iconName;
@property (nonatomic, assign) BOOL tg_expanded;
@property (nonatomic, copy) NSArray<TgOrderItem *> *tg_items;
@property (nonatomic, copy, nullable) void (^tg_onToggle)(void);
@property (nonatomic, copy, nullable) void (^tg_onSelectItem)(TgOrderItem *item);
- (void)tg_setExpanded:(BOOL)expanded animated:(BOOL)animated;
- (void)tg_reloadItems;
@end

@implementation TgOrderShelfSectionView {
    UIView *_tg_headerRow;
    UIImageView *_tg_iconGlyph;
    UILabel *_tg_titleCaption;
    UIImageView *_tg_arrowGlyph;
    UIView *_tg_contentVeil;
    UIStackView *_tg_itemStack;
    UILabel *_tg_emptyCaption;
    MASConstraint *_tg_contentHeightConstraint;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.userInteractionEnabled || self.hidden || self.alpha < 0.01) {
        return [super hitTest:point withEvent:event];
    }
    CGPoint headerPoint = [_tg_headerRow convertPoint:point fromView:self];
    if ([_tg_headerRow pointInside:headerPoint withEvent:event]) {
        return _tg_headerRow;
    }
    return [super hitTest:point withEvent:event];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.whiteColor;
        self.layer.cornerRadius = kTgOrderShelfCardRadius;
        self.clipsToBounds = YES;
        [self tg_buildUI];
    }
    return self;
}

- (void)tg_buildUI {
    _tg_headerRow = [[UIView alloc] init];
    _tg_headerRow.backgroundColor = UIColor.whiteColor;
    UITapGestureRecognizer *headerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tg_headerTapped)];
    [_tg_headerRow addGestureRecognizer:headerTap];

    _tg_iconGlyph = [[UIImageView alloc] init];
    _tg_iconGlyph.contentMode = UIViewContentModeScaleAspectFit;

    _tg_titleCaption = [[UILabel alloc] init];
    _tg_titleCaption.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    _tg_titleCaption.textColor = [UIColor tg_toneFromHex:@"#364153"];

    _tg_arrowGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgOrderShelfArrowCollapsedAsset]];
    _tg_arrowGlyph.contentMode = UIViewContentModeScaleAspectFit;
    _tg_arrowGlyph.userInteractionEnabled = NO;

    _tg_contentVeil = [[UIView alloc] init];
    _tg_contentVeil.clipsToBounds = YES;

    _tg_itemStack = [[UIStackView alloc] init];
    _tg_itemStack.axis = UILayoutConstraintAxisVertical;
    _tg_itemStack.spacing = 10;

    _tg_emptyCaption = [[UILabel alloc] init];
    _tg_emptyCaption.text = @"No order";
    _tg_emptyCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    _tg_emptyCaption.textColor = [UIColor tg_toneFromHex:@"#9CA3AF"];
    _tg_emptyCaption.textAlignment = NSTextAlignmentCenter;
    _tg_emptyCaption.hidden = YES;

    [_tg_headerRow addSubview:_tg_iconGlyph];
    [_tg_headerRow addSubview:_tg_titleCaption];
    [_tg_headerRow addSubview:_tg_arrowGlyph];
    [_tg_contentVeil addSubview:_tg_itemStack];
    [_tg_contentVeil addSubview:_tg_emptyCaption];
    [self addSubview:_tg_headerRow];
    [self addSubview:_tg_contentVeil];

    [_tg_headerRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(self);
        make.height.mas_equalTo(kTgOrderShelfHeaderHeight);
    }];
    [_tg_iconGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_tg_headerRow).offset(14);
        make.centerY.equalTo(_tg_headerRow);
        make.width.height.mas_equalTo(28);
    }];
    [_tg_titleCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_tg_iconGlyph.mas_right).offset(10);
        make.centerY.equalTo(_tg_headerRow);
        make.right.lessThanOrEqualTo(_tg_arrowGlyph.mas_left).offset(-8);
    }];
    [_tg_arrowGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_tg_headerRow).offset(-14);
        make.centerY.equalTo(_tg_headerRow);
        make.width.height.mas_equalTo(16);
    }];
    [_tg_contentVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.top.equalTo(_tg_headerRow.mas_bottom);
        self->_tg_contentHeightConstraint = make.height.mas_equalTo(0);
    }];
    [_tg_itemStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_tg_contentVeil).insets(UIEdgeInsetsMake(0, 14, 14, 14));
    }];
    [_tg_emptyCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(_tg_contentVeil);
        make.left.greaterThanOrEqualTo(_tg_contentVeil).offset(14);
        make.right.lessThanOrEqualTo(_tg_contentVeil).offset(-14);
    }];
}

- (void)tg_headerTapped {
    if (self.tg_onToggle) self.tg_onToggle();
}

- (void)tg_setExpanded:(BOOL)expanded animated:(BOOL)animated {
    self.tg_expanded = expanded;
    void (^apply)(void) = ^{
        NSString *arrowName = expanded ? kTgOrderShelfArrowExpandedAsset : kTgOrderShelfArrowCollapsedAsset;
        self->_tg_arrowGlyph.image = [UIImage imageNamed:arrowName];
        self->_tg_arrowGlyph.transform = CGAffineTransformIdentity;
        [self tg_reloadItems];
    };
    if (animated) {
        [UIView animateWithDuration:0.25 animations:apply];
    } else {
        apply();
    }
}

- (void)tg_reloadItems {
    for (UIView *v in _tg_itemStack.arrangedSubviews) {
        [_tg_itemStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }

    if (!self.tg_expanded) {
        [_tg_contentHeightConstraint setOffset:0];
        _tg_contentVeil.hidden = YES;
        return;
    }

    _tg_contentVeil.hidden = NO;
    if (self.tg_items.count == 0) {
        _tg_emptyCaption.hidden = NO;
        _tg_itemStack.hidden = YES;
        [_tg_contentHeightConstraint setOffset:kTgOrderShelfEmptyMinHeight];
        return;
    }

    _tg_emptyCaption.hidden = YES;
    _tg_itemStack.hidden = NO;
    __weak typeof(self) weakSelf = self;
    for (TgOrderItem *item in self.tg_items) {
        TgOrderShelfItemView *card = [[TgOrderShelfItemView alloc] init];
        [card tg_configureWithItem:item];
        card.tg_onTap = ^{
            if (weakSelf.tg_onSelectItem) weakSelf.tg_onSelectItem(item);
        };
        [_tg_itemStack addArrangedSubview:card];
    }
    CGFloat stackW = CGRectGetWidth(_tg_contentVeil.bounds);
    if (stackW < 1.0) {
        stackW = CGRectGetWidth(UIScreen.mainScreen.bounds) - kTgOrderShelfHorzInset * 2.0 - 28.0;
    }
    CGFloat stackH = 0;
    NSArray<UIView *> *cards = _tg_itemStack.arrangedSubviews;
    for (NSUInteger i = 0; i < cards.count; i++) {
        CGSize fit = [cards[i] systemLayoutSizeFittingSize:CGSizeMake(stackW, UILayoutFittingCompressedSize.height)
                             withHorizontalFittingPriority:UILayoutPriorityRequired
                                   verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
        stackH += fit.height;
        if (i > 0) {
            stackH += _tg_itemStack.spacing;
        }
    }
    [_tg_contentHeightConstraint setOffset:stackH + 14.0];
}

- (void)setTg_title:(NSString *)tg_title {
    _tg_title = [tg_title copy];
    _tg_titleCaption.text = tg_title;
}

- (void)setTg_iconName:(NSString *)tg_iconName {
    _tg_iconName = [tg_iconName copy];
    _tg_iconGlyph.image = [UIImage imageNamed:tg_iconName];
}

- (void)setTg_items:(NSArray<TgOrderItem *> *)tg_items {
    _tg_items = [tg_items copy];
    [self tg_reloadItems];
}

@end

#pragma mark - Controller

typedef struct {
    __unsafe_unretained NSString *title;
    __unsafe_unretained NSString *iconName;
    NSInteger apiOrderStatus;
} TgOrderShelfSectionSpec;

static const TgOrderShelfSectionSpec kTgOrderShelfSpecs[] = {
    { @"Repayment Due", @"use_03", 20 },
    { @"Submit Application", @"use_01", 10 },
    { @"Processing", @"use_02", 30 },
    { @"Completed", @"use_04", 40 },
};

static const NSUInteger kTgOrderShelfSectionCount = 4;

static NSInteger gTgOrderShelfPendingFocusApiStatus = 0;
static __weak TgOrderShelfController *gTgOrderShelfWeak = nil;

@interface TgOrderShelfController ()

@property (nonatomic, strong) UIScrollView *tg_scrollPane;
@property (nonatomic, strong) UIView *tg_scrollBody;
@property (nonatomic, strong) UIView *tg_gradientVeil;
@property (nonatomic, strong) CAGradientLayer *tg_headerGradient;
@property (nonatomic, strong) UILabel *tg_titleCaption;
@property (nonatomic, strong) UIStackView *tg_contentStack;
@property (nonatomic, strong) UIImageView *tg_bannerGlyph;
@property (nonatomic, strong) MASConstraint *tg_gradientHeightConstraint;
@property (nonatomic, strong) MASConstraint *tg_contentBottomConstraint;
@property (nonatomic, strong) NSMutableArray<TgOrderShelfSectionView *> *tg_sectionViews;
@property (nonatomic, strong) NSMutableArray<NSMutableArray<TgOrderItem *> *> *tg_sectionItems;
@property (nonatomic, assign) BOOL tg_loading;

@end

@implementation TgOrderShelfController

+ (void)tg_requestFocusSectionWithApiOrderStatus:(NSInteger)apiOrderStatus {
    gTgOrderShelfPendingFocusApiStatus = apiOrderStatus;
    [gTgOrderShelfWeak tg_performPendingFocusIfNeeded];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _tg_sectionViews = [NSMutableArray array];
        _tg_sectionItems = [NSMutableArray array];
        for (NSUInteger i = 0; i < kTgOrderShelfSectionCount; i++) {
            [_tg_sectionItems addObject:[NSMutableArray array]];
        }
        self.tg_backdropStyle = TgHullBackdropStylePlain;
        self.tg_showsBackButton = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    gTgOrderShelfWeak = self;
    self.view.backgroundColor = [UIColor tg_toneFromHex:@"#F1F1F1"];
    [self tg_buildLayout];
    [self tg_buildSections];
    [self tg_performPendingFocusIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self tg_loadAllSections];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self tg_performPendingFocusIfNeeded];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tg_headerGradient.frame = self.tg_gradientVeil.bounds;
    CGFloat gradientH = CGRectGetWidth(self.view.bounds) * (kTgOrderShelfGradientDesignHeight / kTgOrderShelfGradientDesignWidth);
    [self.tg_gradientHeightConstraint setOffset:gradientH];
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    CGFloat safeTop = self.view.safeAreaInsets.top;
    [self.tg_titleCaption mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_gradientVeil).offset(safeTop + kTgOrderShelfTitleTopExtra);
    }];
    CGFloat bottomPad = kTgOrderShelfScrollBottomInset + self.view.safeAreaInsets.bottom;
    [self.tg_contentBottomConstraint setOffset:-bottomPad];
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

    self.tg_titleCaption = [[UILabel alloc] init];
    self.tg_titleCaption.text = @"Order history";
    self.tg_titleCaption.textColor = UIColor.whiteColor;
    self.tg_titleCaption.textAlignment = NSTextAlignmentCenter;
    self.tg_titleCaption.font = [UIFont tg_meshGlyphWithSize:18 weight:UIFontWeightMedium];
    [self.tg_gradientVeil addSubview:self.tg_titleCaption];

    self.tg_bannerGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgOrderShelfBannerAsset]];
    self.tg_bannerGlyph.contentMode = UIViewContentModeScaleAspectFill;
    self.tg_bannerGlyph.clipsToBounds = YES;
    self.tg_bannerGlyph.layer.cornerRadius = 12;
    [self.tg_gradientVeil addSubview:self.tg_bannerGlyph];

    self.tg_contentStack = [[UIStackView alloc] init];
    self.tg_contentStack.axis = UILayoutConstraintAxisVertical;
    self.tg_contentStack.spacing = kTgOrderShelfSectionSpacing;
    self.tg_contentStack.alignment = UIStackViewAlignmentFill;
    [self.tg_scrollBody addSubview:self.tg_contentStack];

    [self.tg_scrollPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self.tg_scrollBody mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.width.equalTo(self.tg_scrollPane);
    }];
    [self.tg_gradientVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.tg_scrollBody);
        self.tg_gradientHeightConstraint = make.height.mas_equalTo(kTgOrderShelfGradientDesignHeight);
    }];
    [self.tg_titleCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.tg_gradientVeil);
        make.left.greaterThanOrEqualTo(self.tg_gradientVeil).offset(kTgOrderShelfHorzInset);
        make.right.lessThanOrEqualTo(self.tg_gradientVeil).offset(-kTgOrderShelfHorzInset);
        make.top.equalTo(self.tg_gradientVeil).offset(kTgOrderShelfTitleTopExtra);
    }];
    [self.tg_bannerGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_gradientVeil).offset(kTgOrderShelfHorzInset);
        make.right.equalTo(self.tg_gradientVeil).offset(-kTgOrderShelfHorzInset);
        make.top.equalTo(self.tg_titleCaption.mas_bottom).offset(kTgOrderShelfBannerBelowTitle);
        make.height.equalTo(self.tg_bannerGlyph.mas_width).multipliedBy(kTgOrderShelfBannerDesignHeight / kTgOrderShelfBannerDesignWidth);
    }];
    [self.tg_contentStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_bannerGlyph.mas_bottom).offset(12);
        make.left.equalTo(self.tg_scrollBody).offset(kTgOrderShelfHorzInset);
        make.right.equalTo(self.tg_scrollBody).offset(-kTgOrderShelfHorzInset);
        self.tg_contentBottomConstraint = make.bottom.equalTo(self.tg_scrollBody).offset(-kTgOrderShelfScrollBottomInset);
    }];
}

- (void)tg_buildSections {
    [self.tg_sectionViews removeAllObjects];
    for (NSUInteger i = 0; i < kTgOrderShelfSectionCount; i++) {
        const TgOrderShelfSectionSpec spec = kTgOrderShelfSpecs[i];
        TgOrderShelfSectionView *section = [[TgOrderShelfSectionView alloc] init];
        section.tg_title = spec.title;
        section.tg_iconName = spec.iconName;
        section.tg_expanded = NO;
        section.tg_items = @[];

        __weak typeof(self) weakSelf = self;
        NSUInteger idx = i;
        section.tg_onToggle = ^{
            [weakSelf tg_toggleSectionAtIndex:idx];
        };
        section.tg_onSelectItem = ^(TgOrderItem *item) {
            [weakSelf tg_openDetailForItem:item];
        };

        [self.tg_contentStack addArrangedSubview:section];
        [self.tg_sectionViews addObject:section];
    }
}

#pragma mark - Data

- (void)tg_loadAllSections {
    if (self.tg_loading) return;
    self.tg_loading = YES;
    [[TgPulseOverlay shared] veilSpin];

    dispatch_group_t group = dispatch_group_create();
    __block BOOL anyFailure = NO;

    for (NSUInteger i = 0; i < kTgOrderShelfSectionCount; i++) {
        const TgOrderShelfSectionSpec spec = kTgOrderShelfSpecs[i];
        NSMutableArray<TgOrderItem *> *bucket = self.tg_sectionItems[i];
        [bucket removeAllObjects];

        dispatch_group_enter(group);
        NSDictionary *nonSign = @{ @"orderStatus": @(spec.apiOrderStatus) };
        [[TgWireConduit shared] relayPOST:TgLaneOrderList
                                 signData:@{}
                               nonSignData:nonSign
                                  success:^(id _Nullable data) {
            TgOrderListData *listData = [TgOrderListData yy_modelWithJSON:data];
            if (listData.vital.count > 0) {
                [bucket addObjectsFromArray:listData.vital];
            }
            dispatch_group_leave(group);
        } failure:^{
            anyFailure = YES;
            dispatch_group_leave(group);
        }];
    }

    __weak typeof(self) weakSelf = self;
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        self.tg_loading = NO;
        [[TgPulseOverlay shared] veilDismiss];
        if (anyFailure) {
            [[TgPulseOverlay shared] whisperLine:kTgOrderShelfBusyHint];
        }
        [self tg_refreshAllSections];
    });
}

- (void)tg_refreshAllSections {
    for (NSUInteger i = 0; i < self.tg_sectionViews.count; i++) {
        TgOrderShelfSectionView *section = self.tg_sectionViews[i];
        section.tg_items = [self.tg_sectionItems[i] copy];
        [section tg_setExpanded:section.tg_expanded animated:NO];
    }
    [self tg_performPendingFocusIfNeeded];
}

- (NSUInteger)tg_sectionIndexForApiOrderStatus:(NSInteger)apiOrderStatus {
    for (NSUInteger i = 0; i < kTgOrderShelfSectionCount; i++) {
        if (kTgOrderShelfSpecs[i].apiOrderStatus == apiOrderStatus) {
            return i;
        }
    }
    return NSNotFound;
}

- (void)tg_performPendingFocusIfNeeded {
    NSInteger apiOrderStatus = gTgOrderShelfPendingFocusApiStatus;
    if (apiOrderStatus <= 0) return;
    if (self.tg_sectionViews.count == 0) return;
    if (self.tg_loading) return;

    NSUInteger targetIdx = [self tg_sectionIndexForApiOrderStatus:apiOrderStatus];
    if (targetIdx == NSNotFound) {
        gTgOrderShelfPendingFocusApiStatus = 0;
        return;
    }
    gTgOrderShelfPendingFocusApiStatus = 0;

    for (NSUInteger i = 0; i < self.tg_sectionViews.count; i++) {
        TgOrderShelfSectionView *section = self.tg_sectionViews[i];
        BOOL shouldExpand = (i == targetIdx);
        if (section.tg_expanded != shouldExpand) {
            [section tg_setExpanded:shouldExpand animated:YES];
        }
    }

    [self.tg_scrollBody setNeedsLayout];
    [self.tg_scrollBody layoutIfNeeded];

    if (targetIdx < self.tg_sectionViews.count) {
        TgOrderShelfSectionView *target = self.tg_sectionViews[targetIdx];
        CGRect frame = [target convertRect:target.bounds toView:self.tg_scrollPane];
        CGFloat offsetY = CGRectGetMinY(frame);
        CGFloat maxOffset = MAX(0.0, self.tg_scrollPane.contentSize.height - CGRectGetHeight(self.tg_scrollPane.bounds));
        offsetY = MIN(MAX(0.0, offsetY - 8.0), maxOffset);
        [self.tg_scrollPane setContentOffset:CGPointMake(0, offsetY) animated:YES];
    }
}

- (void)tg_toggleSectionAtIndex:(NSUInteger)index {
    if (index >= self.tg_sectionViews.count) return;
    TgOrderShelfSectionView *section = self.tg_sectionViews[index];
    [section tg_setExpanded:!section.tg_expanded animated:YES];
    [self.tg_scrollBody setNeedsLayout];
    [self.tg_scrollBody layoutIfNeeded];
}

#pragma mark - Navigation

- (void)tg_openDetailForItem:(TgOrderItem *)item {
    if (item.intellectual == 31) {
        if ([TgRejectWebController tg_tryPushFromNav:self.navigationController unavailableToast:nil]) {
            return;
        }
    }

    NSString *orderId = [item.interpret stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    NSString *productId = [item.resistance stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (orderId.length == 0 && productId.length == 0) {
        [[TgPulseOverlay shared] whisperLine:@"Order ID or Product ID must be provided"];
        return;
    }

    UIViewController *vc = nil;
    if (item.intellectual == 32) {
        TgOrderWithdrawVaultController *withdraw = [[TgOrderWithdrawVaultController alloc] init];
        withdraw.tg_orderId = orderId.length > 0 ? orderId : nil;
        withdraw.tg_productId = productId.length > 0 ? productId : nil;
        vc = withdraw;
    } else {
        TgOrderDetailVaultController *detail = [[TgOrderDetailVaultController alloc] init];
        detail.tg_orderId = orderId.length > 0 ? orderId : nil;
        detail.tg_productId = productId.length > 0 ? productId : nil;
        vc = detail;
    }
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
