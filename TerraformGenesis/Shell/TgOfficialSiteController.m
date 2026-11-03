//

//

#import "TgOfficialSiteController.h"
#import "TgPolicyVault.h"
#import "TgPulseOverlay.h"
#import "TgPayloadModels.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>

static CGFloat const kTgSiteHorzInset = 16.0;
static CGFloat const kTgSiteCardRadius = 16.0;
static NSString * const kTgSiteBodyToneHex = @"#F1F1F1";
static NSString * const kTgSiteArrowAsset = @"use_next_loan_xiao";
static NSString * const kTgSiteBusyHint = @"The system is occupied. Please retry after 2 minutes.";
static NSString * const kTgSiteNotAvailable = @"Not available";
static NSString * const kTgSiteLinkCopied = @"The link was copied to your clipboard.";
static NSString * const kTgSiteNoticeBgHex = @"#FCF4EE";
static NSString * const kTgSiteNoticeTextHex = @"#EA834C";
static NSString * const kTgSiteDescText =
@"If you face issues in the app, you can also apply and repay via the official website. We suggest saving the official website address:";

@interface TgOfficialSiteController ()

@property (nonatomic, copy, nullable) NSString *tg_prefilledWebsite;
@property (nonatomic, strong) UIView *tg_bodyVeil;
@property (nonatomic, strong) UIScrollView *tg_scrollPane;
@property (nonatomic, strong) UIStackView *tg_contentStack;
@property (nonatomic, strong) UILabel *tg_urlValueCaption;
@property (nonatomic, copy) NSString *tg_cachedWebsite;

@end

@implementation TgOfficialSiteController

- (instancetype)init {
    return [self initWithWebsiteURL:nil];
}

- (instancetype)initWithWebsiteURL:(NSString *)websiteURL {
    self = [super init];
    if (self) {
        _tg_prefilledWebsite = websiteURL.length > 0 ? [websiteURL copy] : nil;
        self.tg_backdropStyle = TgHullBackdropStyleUseBg0;
        self.tg_showsBackButton = YES;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self tg_setNavTitleMedium18:@"Official Website"];
    [self tg_buildLayout];
    if (self.tg_prefilledWebsite.length > 0) {
        self.tg_cachedWebsite = [self.tg_prefilledWebsite copy];
        [self tg_refreshURLDisplay];
    } else {
        [self tg_pullManifest];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - Layout

- (void)tg_buildLayout {
    self.tg_bodyVeil = [[UIView alloc] init];
    self.tg_bodyVeil.backgroundColor = [UIColor tg_toneFromHex:kTgSiteBodyToneHex];
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

    UIView *descCard = [self tg_buildDescCard];
    UILabel *linkTitle = [self tg_sectionTitle:@"Official Website Link"];
    UIView *linkCard = [self tg_buildCopyCard];

    [self.tg_contentStack addArrangedSubview:descCard];
    [self.tg_contentStack addArrangedSubview:linkTitle];
    [self.tg_contentStack addArrangedSubview:linkCard];
    [self.tg_contentStack setCustomSpacing:31 afterView:descCard];

    [self.tg_bodyVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset([self tg_contentTopBelowNavigation]);
    }];
    [self.tg_scrollPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_bodyVeil);
    }];
    [self.tg_contentStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_scrollPane).insets(UIEdgeInsetsMake(12, kTgSiteHorzInset, 24, kTgSiteHorzInset));
        make.width.equalTo(self.tg_scrollPane).offset(-kTgSiteHorzInset * 2);
    }];
}

- (UIView *)tg_buildDescCard {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor tg_toneFromHex:kTgSiteNoticeBgHex];
    card.layer.cornerRadius = 12;
    card.clipsToBounds = YES;

    UILabel *caption = [[UILabel alloc] init];
    caption.text = kTgSiteDescText;
    caption.font = [UIFont tg_meshGlyphWithSize:15 weight:UIFontWeightRegular];
    caption.textColor = [UIColor tg_toneFromHex:kTgSiteNoticeTextHex];
    caption.numberOfLines = 0;
    [card addSubview:caption];
    [caption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card).insets(UIEdgeInsetsMake(14, 14, 14, 14));
    }];
    return card;
}

- (UILabel *)tg_sectionTitle:(NSString *)text {
    UILabel *l = [[UILabel alloc] init];
    l.text = text;
    l.font = [UIFont tg_meshGlyphWithSize:15 weight:UIFontWeightMedium];
    l.textColor = UIColor.blackColor;
    return l;
}

- (UIView *)tg_buildCopyCard {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = UIColor.whiteColor;
    card.layer.cornerRadius = kTgSiteCardRadius;
    card.layer.shadowColor = [UIColor blackColor].CGColor;
    card.layer.shadowOpacity = 0.06;
    card.layer.shadowOffset = CGSizeMake(0, 2);
    card.layer.shadowRadius = 8;
    card.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tg_onCopyTap)];
    [card addGestureRecognizer:tap];

    UILabel *value = [[UILabel alloc] init];
    value.font = [UIFont tg_meshGlyphWithSize:15 weight:UIFontWeightRegular];
    value.textColor = UIColor.blackColor;
    value.numberOfLines = 0;
    value.text = kTgSiteNotAvailable;
    value.userInteractionEnabled = NO;
    self.tg_urlValueCaption = value;

    UIButton *copyLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    copyLatch.userInteractionEnabled = NO;

    UIColor *copyColor = [UIColor colorWithRed:220/255.0 green:38/255.0 blue:38/255.0 alpha:1];
    UIButtonConfiguration *cfg = [UIButtonConfiguration plainButtonConfiguration];
    cfg.title = @"Copy";
    cfg.image = [UIImage imageNamed:kTgSiteArrowAsset];
    cfg.imagePlacement = NSDirectionalRectEdgeTrailing;
    cfg.imagePadding = 4;
    cfg.baseForegroundColor = copyColor;
    cfg.titleTextAttributesTransformer = ^NSDictionary<NSAttributedStringKey, id> * _Nonnull(NSDictionary<NSAttributedStringKey, id> * _Nonnull incoming) {
        NSMutableDictionary *out = [incoming mutableCopy];
        out[NSFontAttributeName] = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightMedium];
        return out;
    };
    cfg.contentInsets = NSDirectionalEdgeInsetsZero;
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
        [[TgPulseOverlay shared] whisperLine:kTgSiteBusyHint];
    }];
}

- (void)tg_applyManifest:(TgSystemConfigModel *)cfg {
    self.tg_cachedWebsite = cfg.have.length > 0 ? [cfg.have copy] : @"";
    [self tg_refreshURLDisplay];
}

- (void)tg_refreshURLDisplay {
    self.tg_urlValueCaption.text = self.tg_cachedWebsite.length > 0 ? self.tg_cachedWebsite : kTgSiteNotAvailable;
}

#pragma mark - Copy

- (void)tg_onCopyTap {
    if (self.tg_cachedWebsite.length == 0) return;
    [UIPasteboard generalPasteboard].string = self.tg_cachedWebsite;
    [[TgPulseOverlay shared] whisperLine:kTgSiteLinkCopied];
}

@end
