//

//

#import "TgAboutVaultController.h"
#import "SceneDelegate.h"
#import "TgParcelRegistry.h"
#import "TgPersonaVault.h"
#import "TgPulseOverlay.h"
#import "TgShardFacade.h"
#import "TgWireConduit.h"
#import "TgEnvelopeBase.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>

static CGFloat const kTgAboutHorzInset = 16.0;
static CGFloat const kTgAboutDescHorzInset = 24.0;
static CGFloat const kTgAboutDeleteHeight = 50.0;
static CGFloat const kTgAboutDeleteWidthRatio = 0.8;
static NSString * const kTgAboutBodyToneHex = @"#F1F1F1";
static NSString * const kTgAboutDeleteHex = @"#182040";

static NSString * const kTgAboutDeleteConfirmMessage =
@"When your loan order is under review and loan processing, you cannot cancel your account.\n\n"
@"When your loan order has not been settled, you cannot cancel your account.\n\n"
@"After confirming the cancellation, the account will not be restored. Please operate with caution.";

@interface TgAboutVaultController ()

@property (nonatomic, strong) UIView *tg_bodyVeil;
@property (nonatomic, strong) UIScrollView *tg_scrollPane;
@property (nonatomic, strong) UIStackView *tg_contentStack;
@property (nonatomic, strong) UIButton *tg_deleteLatch;
@property (nonatomic, assign) BOOL tg_deleteBusy;

@end

@implementation TgAboutVaultController

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
    [self tg_setNavTitleMedium18:@"About"];
    [self tg_buildLayout];
    [self tg_fillAppInfo];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - Layout

- (void)tg_buildLayout {
    self.tg_bodyVeil = [[UIView alloc] init];
    self.tg_bodyVeil.backgroundColor = [UIColor tg_toneFromHex:kTgAboutBodyToneHex];
    [self.view insertSubview:self.tg_bodyVeil atIndex:1];

    self.tg_deleteLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_deleteLatch setTitle:@"Delete account" forState:UIControlStateNormal];
    [self.tg_deleteLatch setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.tg_deleteLatch.titleLabel.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    self.tg_deleteLatch.backgroundColor = [UIColor tg_toneFromHex:kTgAboutDeleteHex];
    self.tg_deleteLatch.layer.cornerRadius = kTgAboutDeleteHeight / 2.0;
    self.tg_deleteLatch.clipsToBounds = YES;
    [self.tg_deleteLatch addTarget:self action:@selector(tg_onDeleteTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.tg_deleteLatch];

    self.tg_scrollPane = [[UIScrollView alloc] init];
    self.tg_scrollPane.showsVerticalScrollIndicator = NO;
    self.tg_scrollPane.alwaysBounceVertical = YES;
    self.tg_scrollPane.backgroundColor = UIColor.clearColor;
    [self.view addSubview:self.tg_scrollPane];

    self.tg_contentStack = [[UIStackView alloc] init];
    self.tg_contentStack.axis = UILayoutConstraintAxisVertical;
    self.tg_contentStack.spacing = 16;
    self.tg_contentStack.alignment = UIStackViewAlignmentFill;
    [self.tg_scrollPane addSubview:self.tg_contentStack];

    [self.tg_contentStack addArrangedSubview:[self tg_buildBrandCard]];
    [self.tg_contentStack addArrangedSubview:[self tg_buildDescCard]];

    [self.tg_bodyVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset([self tg_contentTopBelowNavigation]);
    }];
    [self.tg_deleteLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(kTgAboutDeleteWidthRatio);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-24);
        make.height.mas_equalTo(kTgAboutDeleteHeight);
    }];
    [self.tg_scrollPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.tg_bodyVeil);
        make.bottom.equalTo(self.tg_deleteLatch.mas_top).offset(-16);
    }];
    [self.tg_contentStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_scrollPane).insets(UIEdgeInsetsMake(12, kTgAboutHorzInset, 20, kTgAboutHorzInset));
        make.width.equalTo(self.tg_scrollPane).offset(-kTgAboutHorzInset * 2);
    }];
}

- (UIView *)tg_buildBrandCard {
    UIView *card = [self tg_plainSection];
    UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
    logo.contentMode = UIViewContentModeScaleAspectFit;
    logo.layer.cornerRadius = 12;
    logo.clipsToBounds = YES;

    UILabel *name = [[UILabel alloc] init];
    name.tag = 2001;
    name.font = [UIFont tg_meshGlyphWithSize:18 weight:UIFontWeightBold];
    name.textColor = UIColor.blackColor;
    name.textAlignment = NSTextAlignmentCenter;

    UILabel *version = [[UILabel alloc] init];
    version.tag = 2002;
    version.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    version.textColor = [UIColor tg_toneFromHex:@"#6B7280"];
    version.textAlignment = NSTextAlignmentCenter;

    [card addSubview:logo];
    [card addSubview:name];
    [card addSubview:version];

    [logo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(24);
        make.centerX.equalTo(card);
        make.width.height.mas_equalTo(64);
    }];
    [name mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(logo.mas_bottom).offset(16);
        make.centerX.equalTo(card);
        make.left.equalTo(card).offset(kTgAboutDescHorzInset);
        make.right.equalTo(card).offset(-kTgAboutDescHorzInset);
    }];
    [version mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(name.mas_bottom).offset(8);
        make.left.right.equalTo(name);
        make.bottom.equalTo(card).offset(-24);
    }];
    return card;
}

- (UIView *)tg_buildDescCard {
    UIView *card = [self tg_plainSection];
    UILabel *caption = [[UILabel alloc] init];
    caption.tag = 2003;
    caption.font = [UIFont tg_meshGlyphWithSize:15 weight:UIFontWeightRegular];
    caption.textColor = [UIColor tg_toneFromHex:@"#364153"];
    caption.numberOfLines = 0;
    caption.textAlignment = NSTextAlignmentCenter;
    caption.lineBreakMode = NSLineBreakByWordWrapping;
    [card addSubview:caption];
    [caption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(card);
        make.centerX.equalTo(card);
        make.left.equalTo(card).offset(kTgAboutDescHorzInset);
        make.right.equalTo(card).offset(-kTgAboutDescHorzInset);
    }];
    return card;
}

- (UIView *)tg_plainSection {
    UIView *wrap = [[UIView alloc] init];
    wrap.backgroundColor = UIColor.clearColor;
    return wrap;
}

- (void)tg_fillAppInfo {
    NSDictionary *info = NSBundle.mainBundle.infoDictionary;
    NSString *name = info[@"CFBundleDisplayName"] ?: info[@"CFBundleName"] ?: @"App";
    NSString *version = info[@"CFBundleShortVersionString"] ?: @"1.0.0";

    UILabel *nameLabel = [self.view viewWithTag:2001];
    UILabel *versionLabel = [self.view viewWithTag:2002];
    UILabel *descLabel = [self.view viewWithTag:2003];
    descLabel.textAlignment = NSTextAlignmentLeft;
    nameLabel.text = name;
    versionLabel.text = [NSString stringWithFormat:@"V %@", version];
    descLabel.text = @"Flexible loan solutions, simple applications, and convenient access - all designed around you.";
}

#pragma mark - Delete account

- (void)tg_onDeleteTap {
    if (self.tg_deleteBusy) return;

    __weak typeof(self) weakSelf = self;
    TgShardPanelConfig *cfg = [[TgShardPanelConfig alloc] init];
    cfg.title = @"Delete account";
    cfg.content = kTgAboutDeleteConfirmMessage;
    cfg.secondaryTitle = @"Cancel";
    cfg.primaryTitle = @"Confirm";
    cfg.secondaryAction = ^{
        [[TgShardFacade shared] dismissTopPanel];
    };
    cfg.primaryAction = ^{
        __strong typeof(weakSelf) self = weakSelf;
        [[TgShardFacade shared] dismissTopPanel];
        [self tg_performDeleteAccount];
    };
    [[TgShardFacade shared] showPanel:cfg];
}

- (void)tg_performDeleteAccount {
    if (self.tg_deleteBusy) return;
    self.tg_deleteBusy = YES;
    self.tg_deleteLatch.enabled = NO;

    [[TgPulseOverlay shared] veilSpin:@"Loading..."];
    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneAuthClose
                             signData:@{}
                           nonSignData:@{}
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        __strong typeof(weakSelf) self = weakSelf;
        [[TgPulseOverlay shared] veilDismiss];
        self.tg_deleteBusy = NO;
        self.tg_deleteLatch.enabled = YES;
        BOOL ok = (envelope.cheer == 200);
        [self tg_showDeleteResultSuccess:ok];
    } failure:^{
        __strong typeof(weakSelf) self = weakSelf;
        [[TgPulseOverlay shared] veilDismiss];
        self.tg_deleteBusy = NO;
        self.tg_deleteLatch.enabled = YES;
        [self tg_showDeleteResultSuccess:NO];
    }];
}

- (void)tg_showDeleteResultSuccess:(BOOL)success {
    __weak typeof(self) weakSelf = self;
    TgShardPanelConfig *cfg = [[TgShardPanelConfig alloc] init];
    if (success) {
        cfg.title = @"Success";
        cfg.content = @"Account cancelled successfully.";
    } else {
        cfg.title = @"Failed";
        cfg.content = @"Account cancellation failed, please check your order.";
    }
    cfg.primaryTitle = @"Confirm";
    cfg.primaryAction = ^{
        __strong typeof(weakSelf) self = weakSelf;
        [[TgShardFacade shared] dismissTopPanel];
        if (success) {
            [[TgPersonaVault shared] wipe];
            [self tg_switchToSignIn];
        }
    };
    [[TgShardFacade shared] showPanel:cfg];
}

- (void)tg_switchToSignIn {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState != UISceneActivationStateForegroundActive) continue;
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        id delegate = ((UIWindowScene *)scene).delegate;
        if ([delegate respondsToSelector:@selector(tg_switchToSignInAnimated:)]) {
            [(SceneDelegate *)delegate tg_switchToSignInAnimated:YES];
            return;
        }
    }
}

@end
