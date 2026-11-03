//

//

#import "TgRepayGuideController.h"
#import "TgPolicyVault.h"
#import "TgPulseOverlay.h"
#import "TgPayloadModels.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>

static CGFloat const kTgRepayHorzInset = 16.0;
static CGFloat const kTgRepayCardRadius = 16.0;
static NSString * const kTgRepayBodyToneHex = @"#F1F1F1";
static NSString * const kTgRepayArrowAsset = @"use_next_loan_xiao";
static NSString * const kTgRepayBusyHint = @"The system is occupied. Please retry after 2 minutes.";
static NSString * const kTgRepayNotAvailable = @"Not available";
static NSString * const kTgRepayEmailCopied = @"The email address was copied to your clipboard.";
static NSString * const kTgRepayLinkCopied = @"The link was copied to your clipboard.";

@interface TgRepayGuideController ()

@property (nonatomic, strong) UIView *tg_bodyVeil;
@property (nonatomic, strong) UIScrollView *tg_scrollPane;
@property (nonatomic, strong) UIStackView *tg_contentStack;
@property (nonatomic, strong) UILabel *tg_websiteValueCaption;
@property (nonatomic, strong) UILabel *tg_emailValueCaption;
@property (nonatomic, strong) UILabel *tg_guideCaption;
@property (nonatomic, copy) NSString *tg_cachedEmail;
@property (nonatomic, copy) NSString *tg_cachedWebsite;

@end

@implementation TgRepayGuideController

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
    [self tg_setNavTitleMedium18:@"Repayment instructions"];
    [self tg_buildLayout];
    [self tg_pullManifest];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - Layout

- (void)tg_buildLayout {
    self.tg_bodyVeil = [[UIView alloc] init];
    self.tg_bodyVeil.backgroundColor = [UIColor tg_toneFromHex:kTgRepayBodyToneHex];
    [self.view insertSubview:self.tg_bodyVeil atIndex:1];

    self.tg_scrollPane = [[UIScrollView alloc] init];
    self.tg_scrollPane.showsVerticalScrollIndicator = NO;
    self.tg_scrollPane.alwaysBounceVertical = YES;
    self.tg_scrollPane.backgroundColor = UIColor.clearColor;
    [self.view addSubview:self.tg_scrollPane];

    self.tg_contentStack = [[UIStackView alloc] init];
    self.tg_contentStack.axis = UILayoutConstraintAxisVertical;
    self.tg_contentStack.spacing = 12;
    self.tg_contentStack.alignment = UIStackViewAlignmentFill;
    [self.tg_scrollPane addSubview:self.tg_contentStack];

    UIView *warning = [self tg_buildWarningBox];
    UILabel *websiteTitle = [self tg_sectionTitle:@"Official Website Link"];
    UIView *websiteCard = [self tg_buildCopyCardWithValueLabel:&_tg_websiteValueCaption
                                                       copyTag:1001];
    UILabel *emailTitle = [self tg_sectionTitle:@"Customer Service Email"];
    UIView *emailCard = [self tg_buildCopyCardWithValueLabel:&_tg_emailValueCaption
                                                     copyTag:1002];

    self.tg_guideCaption = [[UILabel alloc] init];
    self.tg_guideCaption.numberOfLines = 0;
    self.tg_guideCaption.font = [UIFont tg_meshGlyphWithSize:15 weight:UIFontWeightRegular];
    self.tg_guideCaption.textColor = UIColor.blackColor;

    [self.tg_contentStack addArrangedSubview:warning];
    [self.tg_contentStack addArrangedSubview:websiteTitle];
    [self.tg_contentStack addArrangedSubview:websiteCard];
    [self.tg_contentStack addArrangedSubview:emailTitle];
    [self.tg_contentStack addArrangedSubview:emailCard];
    [self.tg_contentStack addArrangedSubview:self.tg_guideCaption];

    [self.tg_contentStack setCustomSpacing:16 afterView:warning];
    [self.tg_contentStack setCustomSpacing:20 afterView:emailCard];

    [self.tg_bodyVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset([self tg_contentTopBelowNavigation]);
    }];
    [self.tg_scrollPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_bodyVeil);
    }];
    [self.tg_contentStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_scrollPane).insets(UIEdgeInsetsMake(12, kTgRepayHorzInset, 24, kTgRepayHorzInset));
        make.width.equalTo(self.tg_scrollPane).offset(-kTgRepayHorzInset * 2);
    }];
}

- (UILabel *)tg_sectionTitle:(NSString *)text {
    UILabel *l = [[UILabel alloc] init];
    l.text = text;
    l.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightMedium];
    l.textColor = UIColor.blackColor;
    return l;
}

- (UIView *)tg_buildWarningBox {
    UIView *box = [[UIView alloc] init];
    box.backgroundColor = [UIColor tg_toneFromHex:@"#FCF4EE"];
    box.layer.cornerRadius = 12;
    box.clipsToBounds = YES;

    UILabel *caption = [[UILabel alloc] init];
    caption.text = @"To protect your funds, please carefully review the repayment instructions before you repay.";
    caption.font = [UIFont tg_meshGlyphWithSize:13 weight:UIFontWeightRegular];
    caption.textColor = [UIColor tg_toneFromHex:@"#EA834C"];
    caption.numberOfLines = 0;
    [box addSubview:caption];
    [caption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(box).insets(UIEdgeInsetsMake(14, 14, 14, 14));
    }];
    return box;
}

- (UIView *)tg_buildCopyCardWithValueLabel:(UILabel * __strong *)valueLabel copyTag:(NSInteger)tag {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = UIColor.whiteColor;
    card.layer.cornerRadius = kTgRepayCardRadius;
    card.layer.shadowColor = [UIColor blackColor].CGColor;
    card.layer.shadowOpacity = 0.06;
    card.layer.shadowOffset = CGSizeMake(0, 2);
    card.layer.shadowRadius = 8;
    card.tag = tag;
    card.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tg_onCopyCardTap:)];
    [card addGestureRecognizer:tap];

    UILabel *value = [[UILabel alloc] init];
    value.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    value.textColor = UIColor.blackColor;
    value.numberOfLines = 0;
    value.text = kTgRepayNotAvailable;
    value.userInteractionEnabled = NO;
    if (valueLabel) *valueLabel = value;

    UIButton *copyLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    copyLatch.userInteractionEnabled = NO;

    UIColor *copyColor = [UIColor colorWithRed:220/255.0 green:38/255.0 blue:38/255.0 alpha:1];
    UIImage *arrow = [UIImage imageNamed:kTgRepayArrowAsset];
    UIButtonConfiguration *cfg = [UIButtonConfiguration plainButtonConfiguration];
    cfg.title = @"Copy";
    cfg.image = arrow;
    cfg.imagePlacement = NSDirectionalRectEdgeTrailing;
    cfg.imagePadding = 4;
    cfg.baseForegroundColor = copyColor;
    cfg.titleTextAttributesTransformer = ^NSDictionary<NSAttributedStringKey, id> * _Nonnull(NSDictionary<NSAttributedStringKey, id> * _Nonnull incoming) {
        NSMutableDictionary *out = [incoming mutableCopy];
        out[NSFontAttributeName] = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightMedium];
        return out;
    };
    cfg.contentInsets = NSDirectionalEdgeInsetsMake(0, 0, 0, 0);
    copyLatch.configuration = cfg;

    [card addSubview:value];
    [card addSubview:copyLatch];

    [value mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(card).offset(16);
        make.top.equalTo(card).offset(14);
        make.right.equalTo(copyLatch.mas_left).offset(-8);
        make.bottom.equalTo(card).offset(-14);
    }];
    [copyLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(card).offset(-12);
        make.top.equalTo(card).offset(12);
        make.width.mas_greaterThanOrEqualTo(72);
        make.height.mas_equalTo(28);
    }];
    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_greaterThanOrEqualTo(56);
    }];
    return card;
}

#pragma mark - Data

- (void)tg_pullManifest {
    TgSystemConfigModel *cached = [[TgPolicyVault shared] currentManifest];
    if (cached) {
        [self tg_applyManifest:cached];
        return;
    }
    [[TgPulseOverlay shared] veilSpin:@"Loading..."];
    [[TgPolicyVault shared] pullManifestSuccess:^(TgSystemConfigModel *cfg) {
        [[TgPulseOverlay shared] veilDismiss];
        [self tg_applyManifest:cfg];
    } failure:^{
        [[TgPulseOverlay shared] veilDismiss];
        [[TgPulseOverlay shared] whisperLine:kTgRepayBusyHint];
    }];
}

- (void)tg_applyManifest:(TgSystemConfigModel *)cfg {
    self.tg_cachedEmail = cfg.conjunction.length > 0 ? [cfg.conjunction copy] : @"";
    self.tg_cachedWebsite = cfg.have.length > 0 ? [cfg.have copy] : @"";

    self.tg_emailValueCaption.text = self.tg_cachedEmail.length > 0 ? self.tg_cachedEmail : kTgRepayNotAvailable;
    self.tg_websiteValueCaption.text = self.tg_cachedWebsite.length > 0 ? self.tg_cachedWebsite : kTgRepayNotAvailable;

    NSString *template =
    @"When repaying, please first obtain the repayment link from the app. If the app is unavailable, you may also log in to our official website to repay: [Official Website Link]. Note that using a link different from the one shown in the app or on the official website will be treated as a failed repayment.\n\n"
    @"If anyone asks you to split the total repayment into multiple payments, or sends a repayment link that does not match the app or official website, please contact customer service. After we verify the case, we will waive the service fee for you.\n\n"
    @"If you notice anything suspicious while repaying, please email customer service first. We will help you resolve the issue promptly.";

    NSString *url = self.tg_cachedWebsite.length > 0 ? self.tg_cachedWebsite : @"[Official Website Link]";
    self.tg_guideCaption.text = [template stringByReplacingOccurrencesOfString:@"[Official Website Link]" withString:url];
}

#pragma mark - Copy

- (void)tg_onCopyCardTap:(UITapGestureRecognizer *)gesture {
    UIView *card = gesture.view;
    if (card.tag == 1001) {
        if (self.tg_cachedWebsite.length == 0) return;
        [UIPasteboard generalPasteboard].string = self.tg_cachedWebsite;
        [[TgPulseOverlay shared] whisperLine:kTgRepayLinkCopied];
        return;
    }
    if (card.tag == 1002) {
        if (self.tg_cachedEmail.length == 0) return;
        [UIPasteboard generalPasteboard].string = self.tg_cachedEmail;
        [[TgPulseOverlay shared] whisperLine:kTgRepayEmailCopied];
    }
}

@end
