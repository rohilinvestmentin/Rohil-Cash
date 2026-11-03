//

//

#import "TgMeVaultController.h"
#import "TgRepayGuideController.h"
#import "TgOfficialSiteController.h"
#import "TgAboutVaultController.h"
#import "TgFeedbackVaultController.h"
#import "TgBankVaultController.h"
#import "TgEmiCalcVaultController.h"
#import "TgPaneWebController.h"
#import "TgPureLinks.h"
#import "TgPolicyVault.h"
#import "TgPersonaVault.h"
#import "TgShardFacade.h"
#import "SceneDelegate.h"
#import "TgTraceRelay.h"
#import "TgParcelRegistry.h"
#import "TgPulseOverlay.h"
#import "TgWireConduit.h"
#import "TgPayloadModels.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import "NSString+TgGlyph.h"
#import <Masonry/Masonry.h>

static CGFloat const kTgMeHorzInset = 16.0;
static CGFloat const kTgMeNameTopExtra = 30.0;
static CGFloat const kTgMeCardRadius = 12.0;
static CGFloat const kTgMeActionCardHeight = 72.0;
static CGFloat const kTgMeMenuRowHeight = 52.0;
static NSString * const kTgMeArrowAsset = @"use_next_loan_hong";
static NSString * const kTgMeChevronAsset = @"use_me_01";
static NSString * const kTgMeNotAvailable = @"Not available";
static NSString * const kTgMeBusyHint = @"The system is occupied. Please retry after 2 minutes.";
static NSString * const kTgMeSignOutTitle = @"Sign out";
static NSString * const kTgMeSignOutMessage = @"Do you confirm that you want to sign out?";

@interface TgMeVaultController ()

@property (nonatomic, strong) UIScrollView *tg_scrollPane;
@property (nonatomic, strong) UIView *tg_scrollBody;
@property (nonatomic, strong) UIView *tg_gradientVeil;
@property (nonatomic, strong) CAGradientLayer *tg_headerGradient;
@property (nonatomic, strong) UILabel *tg_nameCaption;
@property (nonatomic, strong) UILabel *tg_phoneCaption;
@property (nonatomic, strong) UIView *tg_emiWrap;
@property (nonatomic, strong) UIView *tg_menuShell;
@property (nonatomic, strong) UIStackView *tg_menuStack;
@property (nonatomic, strong) MASConstraint *tg_gradientHeightConstraint;
@property (nonatomic, assign) BOOL tg_webNavBusy;

@end

@implementation TgMeVaultController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tg_backdropStyle = TgHullBackdropStylePlain;
    self.tg_showsBackButton = NO;
    self.view.backgroundColor = [UIColor tg_toneFromHex:@"#F1F1F1"];

    [self tg_buildLayout];
    [self tg_refreshPersonaLabels:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self tg_pullPersonaSnapshot];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tg_headerGradient.frame = self.tg_gradientVeil.bounds;
    CGFloat gradientH = CGRectGetWidth(self.view.bounds) * (496.0 / 375.0);
    [self.tg_gradientHeightConstraint setOffset:gradientH];
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    CGFloat safeTop = self.view.safeAreaInsets.top;
    [self.tg_emiWrap mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_gradientVeil).offset(safeTop + 4);
    }];
    [self.tg_nameCaption mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_gradientVeil).offset(safeTop + 8 + kTgMeNameTopExtra);
    }];
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
    self.tg_scrollPane.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:self.tg_scrollPane];

    self.tg_scrollBody = [[UIView alloc] init];
    [self.tg_scrollPane addSubview:self.tg_scrollBody];

    self.tg_gradientVeil = [[UIView alloc] init];
    self.tg_gradientVeil.clipsToBounds = YES;
    [self tg_applyHeaderGradient];
    [self.tg_scrollBody addSubview:self.tg_gradientVeil];

    self.tg_nameCaption = [self tg_whiteCaptionLabelWithSize:20 weight:UIFontWeightBold];
    self.tg_phoneCaption = [self tg_whiteCaptionLabelWithSize:15 weight:UIFontWeightRegular];
    [self.tg_gradientVeil addSubview:self.tg_nameCaption];
    [self.tg_gradientVeil addSubview:self.tg_phoneCaption];

    self.tg_emiWrap = [self tg_buildEmiWrap];
    [self.tg_gradientVeil addSubview:self.tg_emiWrap];

    UIView *bankCard = [self tg_buildActionCard:@"Bank Account" iconName:@"use_bank"];
    bankCard.userInteractionEnabled = YES;
    [bankCard addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tg_openBankAccount)]];
    UIView *feedbackCard = [self tg_buildActionCard:@"Feedback" iconName:@"use_feedback"];
    feedbackCard.userInteractionEnabled = YES;
    [feedbackCard addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tg_openFeedback)]];

    UIStackView *actionColumn = [[UIStackView alloc] initWithArrangedSubviews:@[bankCard, feedbackCard]];
    actionColumn.axis = UILayoutConstraintAxisVertical;
    actionColumn.spacing = 12;
    actionColumn.distribution = UIStackViewDistributionFill;
    [self.tg_scrollBody addSubview:actionColumn];

    UIImageView *banner = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"use_bg_me"]];
    banner.contentMode = UIViewContentModeScaleAspectFill;
    banner.clipsToBounds = YES;
    banner.layer.cornerRadius = kTgMeCardRadius;
    [self.tg_scrollBody addSubview:banner];

    self.tg_menuShell = [[UIView alloc] init];
    self.tg_menuShell.backgroundColor = UIColor.whiteColor;
    self.tg_menuShell.layer.cornerRadius = kTgMeCardRadius;
    self.tg_menuShell.clipsToBounds = YES;
    [self.tg_scrollBody addSubview:self.tg_menuShell];

    NSArray<NSString *> *menuTitles = @[
        @"Official Website",
        @"Contact us",
        @"About",
        @"Terms of the loan",
        @"Privacy Policy",
        @"Repayment Instructions",
        kTgMeSignOutTitle
    ];
    self.tg_menuStack = [[UIStackView alloc] init];
    self.tg_menuStack.axis = UILayoutConstraintAxisVertical;
    self.tg_menuStack.spacing = 0;
    [self.tg_menuShell addSubview:self.tg_menuStack];

    [menuTitles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger idx, BOOL *stop) {
        (void)stop;
        SEL tapAction = NULL;
        if ([title isEqualToString:@"Repayment Instructions"]) {
            tapAction = @selector(tg_openRepayGuide);
        } else if ([title isEqualToString:@"Official Website"]) {
            tapAction = @selector(tg_openOfficialSite);
        } else if ([title isEqualToString:@"Contact us"]) {
            tapAction = @selector(tg_openContactUs);
        } else if ([title isEqualToString:@"Terms of the loan"]) {
            tapAction = @selector(tg_openTermsOfLoan);
        } else if ([title isEqualToString:@"Privacy Policy"]) {
            tapAction = @selector(tg_openPrivacyPolicy);
        } else if ([title isEqualToString:@"About"]) {
            tapAction = @selector(tg_openAbout);
        } else if ([title isEqualToString:kTgMeSignOutTitle]) {
            tapAction = @selector(tg_openSignOut);
        }
        [self.tg_menuStack addArrangedSubview:[self tg_buildMenuRow:title tapAction:tapAction]];
        if (idx < menuTitles.count - 1) {
            [self.tg_menuStack addArrangedSubview:[self tg_buildMenuDivider]];
        }
    }];

    [self.tg_scrollPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self.tg_scrollBody mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.width.equalTo(self.tg_scrollPane);
    }];
    [self.tg_gradientVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.tg_scrollBody);
        self.tg_gradientHeightConstraint = make.height.mas_equalTo(496);
    }];
    [self.tg_emiWrap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_gradientVeil).offset(52);
        make.right.equalTo(self.tg_gradientVeil).offset(-kTgMeHorzInset);
        make.height.mas_equalTo(30);
    }];
    [self.tg_nameCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_gradientVeil).offset(kTgMeHorzInset);
        make.right.lessThanOrEqualTo(self.tg_gradientVeil).offset(-kTgMeHorzInset);
        make.top.equalTo(self.tg_gradientVeil).offset(52 + kTgMeNameTopExtra);
    }];
    [self.tg_phoneCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_nameCaption);
        make.top.equalTo(self.tg_nameCaption.mas_bottom).offset(6);
    }];
    [actionColumn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_phoneCaption.mas_bottom).offset(20);
        make.left.equalTo(self.tg_scrollBody).offset(kTgMeHorzInset);
        make.right.equalTo(self.tg_scrollBody).offset(-kTgMeHorzInset);
    }];
    [[actionColumn arrangedSubviews] enumerateObjectsUsingBlock:^(__kindof UIView *card, NSUInteger idx, BOOL *stop) {
        (void)idx; (void)stop;
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(kTgMeActionCardHeight);
        }];
    }];
    [banner mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(actionColumn.mas_bottom).offset(12);
        make.left.right.equalTo(actionColumn);
        make.height.mas_equalTo(72);
    }];
    [self.tg_menuShell mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(banner.mas_bottom).offset(12);
        make.left.equalTo(self.tg_scrollBody).offset(kTgMeHorzInset);
        make.right.equalTo(self.tg_scrollBody).offset(-kTgMeHorzInset);
        make.bottom.equalTo(self.tg_scrollBody).offset(-24);
    }];
    [self.tg_menuStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_menuShell).insets(UIEdgeInsetsMake(4, 0, 8, 0));
    }];
}

#pragma mark - Components

- (UILabel *)tg_whiteCaptionLabelWithSize:(CGFloat)size weight:(UIFontWeight)weight {
    UILabel *l = [[UILabel alloc] init];
    l.font = [UIFont tg_meshGlyphWithSize:size weight:weight];
    l.textColor = UIColor.whiteColor;
    return l;
}

- (UIView *)tg_buildEmiWrap {
    UIView *wrap = [[UIView alloc] init];
    wrap.backgroundColor = UIColor.clearColor;
    wrap.userInteractionEnabled = YES;
    UITapGestureRecognizer *emiTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tg_openEmiCalculator)];
    [wrap addGestureRecognizer:emiTap];

    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"use_emi"]];
    icon.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *caption = [[UILabel alloc] init];
    caption.text = @"EMI >>";
    caption.font = [UIFont tg_meshGlyphWithSize:15 weight:UIFontWeightMedium];
    caption.textColor = UIColor.whiteColor;
    caption.numberOfLines = 1;
    [caption setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [caption setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    [wrap addSubview:icon];
    [wrap addSubview:caption];
    [icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.centerY.equalTo(wrap);
        make.width.height.mas_equalTo(30);
    }];
    [caption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(icon.mas_right).offset(4);
        make.right.centerY.equalTo(wrap);
    }];
    return wrap;
}

- (UIView *)tg_buildActionCard:(NSString *)title iconName:(NSString *)iconName {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = UIColor.whiteColor;
    card.layer.cornerRadius = kTgMeCardRadius;
    card.layer.shadowColor = [UIColor blackColor].CGColor;
    card.layer.shadowOpacity = 0.06;
    card.layer.shadowOffset = CGSizeMake(0, 2);
    card.layer.shadowRadius = 8;

    UIView *iconWrap = [[UIView alloc] init];
    iconWrap.backgroundColor = [UIColor tg_toneFromHex:@"#EEF2FF"];
    iconWrap.layer.cornerRadius = 22;
    iconWrap.clipsToBounds = YES;

    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:iconName]];
    icon.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *caption = [[UILabel alloc] init];
    caption.text = title;
    caption.font = [UIFont tg_meshGlyphWithSize:15 weight:UIFontWeightMedium];
    caption.textColor = UIColor.blackColor;

    UIImageView *arrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgMeArrowAsset]];
    arrow.contentMode = UIViewContentModeScaleAspectFit;

    [iconWrap addSubview:icon];
    [card addSubview:iconWrap];
    [card addSubview:caption];
    [card addSubview:arrow];

    [iconWrap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(card).offset(12);
        make.centerY.equalTo(card);
        make.width.height.mas_equalTo(44);
    }];
    [icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(iconWrap);
        make.width.height.mas_equalTo(28);
    }];
    [caption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(iconWrap.mas_right).offset(10);
        make.centerY.equalTo(card);
        make.right.lessThanOrEqualTo(arrow.mas_left).offset(-8);
    }];
    [arrow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(card).offset(-12);
        make.centerY.equalTo(card);
        make.width.mas_equalTo(28);
        make.height.mas_equalTo(20);
    }];
    return card;
}

- (UIView *)tg_buildMenuRow:(NSString *)title tapAction:(SEL)tapAction {
    UIView *row = [[UIView alloc] init];
    row.userInteractionEnabled = (tapAction != NULL);
    if (tapAction) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:tapAction];
        [row addGestureRecognizer:tap];
    }

    UILabel *caption = [[UILabel alloc] init];
    caption.text = title;
    caption.font = [UIFont tg_meshGlyphWithSize:15 weight:UIFontWeightMedium];
    if ([title isEqualToString:kTgMeSignOutTitle]) {
        caption.textColor = [UIColor tg_toneFromHex:@"#C51B12"];
    } else {
        caption.textColor = UIColor.blackColor;
    }

    UIImageView *chevron = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgMeChevronAsset]];
    chevron.contentMode = UIViewContentModeScaleAspectFit;

    [row addSubview:caption];
    [row addSubview:chevron];
    [caption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(row).offset(kTgMeHorzInset);
        make.centerY.equalTo(row);
        make.right.lessThanOrEqualTo(chevron.mas_left).offset(-8);
    }];
    [chevron mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(row).offset(-kTgMeHorzInset);
        make.centerY.equalTo(row);
        make.width.height.mas_equalTo(16);
    }];
    [row mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(kTgMeMenuRowHeight);
    }];
    return row;
}

- (UIView *)tg_buildMenuDivider {
    UIView *wrap = [[UIView alloc] init];
    UIView *line = [[UIView alloc] init];
    line.backgroundColor = [UIColor tg_toneFromHex:@"#EEEEEE"];
    [wrap addSubview:line];
    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(wrap).offset(kTgMeHorzInset);
        make.right.equalTo(wrap);
        make.top.bottom.equalTo(wrap);
        make.height.mas_equalTo(1.0 / UIScreen.mainScreen.scale);
    }];
    return wrap;
}

#pragma mark - Navigation

- (void)tg_openRepayGuide {
    TgRepayGuideController *guide = [[TgRepayGuideController alloc] init];
    guide.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:guide animated:YES];
}

- (void)tg_openEmiCalculator {
    TgEmiCalcVaultController *emi = [[TgEmiCalcVaultController alloc] init];
    emi.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:emi animated:YES];
}

- (void)tg_openBankAccount {
    TgBankVaultController *bank = [[TgBankVaultController alloc] init];
    bank.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:bank animated:YES];
}

- (void)tg_openFeedback {
    TgFeedbackVaultController *feedback = [[TgFeedbackVaultController alloc] init];
    feedback.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:feedback animated:YES];
}

- (void)tg_openAbout {
    TgAboutVaultController *about = [[TgAboutVaultController alloc] init];
    about.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:about animated:YES];
}

- (void)tg_openSignOut {
    __weak typeof(self) weakSelf = self;
    TgShardPanelConfig *cfg = [[TgShardPanelConfig alloc] init];
    cfg.title = kTgMeSignOutTitle;
    cfg.content = kTgMeSignOutMessage;
    cfg.secondaryTitle = @"Cancel";
    cfg.primaryTitle = @"Confirm";
    cfg.secondaryAction = ^{
        [[TgShardFacade shared] dismissTopPanel];
    };
    cfg.primaryAction = ^{
        __strong typeof(weakSelf) self = weakSelf;
        [[TgShardFacade shared] dismissTopPanel];
        [self tg_performSignOut];
    };
    [[TgShardFacade shared] showPanel:cfg];
}

- (void)tg_performSignOut {
    [[TgPersonaVault shared] wipe];
    [self tg_switchToSignIn];
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

- (void)tg_openOfficialSite {
    TgSystemConfigModel *cfg = [[TgPolicyVault shared] currentManifest];
    NSString *url = cfg.have;
    TgOfficialSiteController *site = [[TgOfficialSiteController alloc] initWithWebsiteURL:url];
    site.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:site animated:YES];
}

- (void)tg_openContactUs {
    [self tg_openWebPaneWithTitle:@"Contact us"
                             href:[TgPureLinks contactUs]
                      traceSignal:-1];
}

- (void)tg_openTermsOfLoan {
    [self tg_openWebPaneWithTitle:@"Terms of the Loan"
                             href:[TgPureLinks loanTerms]
                      traceSignal:TgTraceSignalTermsOpen];
}

- (void)tg_openPrivacyPolicy {
    [self tg_openWebPaneWithTitle:@"Privacy policy"
                             href:[TgPureLinks privacyPolicy]
                      traceSignal:TgTraceSignalPrivacyOpen];
}

- (void)tg_openWebPaneWithTitle:(NSString *)title
                           href:(NSString *)href
                    traceSignal:(NSInteger)traceSignal {
    if (self.tg_webNavBusy) return;
    self.tg_webNavBusy = YES;
    if (traceSignal >= 0) {
        [TgTraceRelay emitSignal:(TgTraceSignal)traceSignal];
    }

    NSURL *url = [TgPaneWebController tg_normalizedURLFromString:href];
    if (href.length == 0 || !url) {
        self.tg_webNavBusy = NO;
        [[TgPulseOverlay shared] whisperLine:kTgMeNotAvailable];
        return;
    }
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    TgPaneWebController *pane = [[TgPaneWebController alloc] initWithPageURL:url navTitle:title];
    pane.tg_showsBackButton = YES;
    pane.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:pane animated:YES];
    self.tg_webNavBusy = NO;
}

#pragma mark - Data

- (void)tg_pullPersonaSnapshot {
    [[TgPulseOverlay shared] veilSpin];
    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneUserInfo
                             signData:@{}
                           nonSignData:@{}
                              success:^(id _Nullable data) {
        __strong typeof(weakSelf) self = weakSelf;
        [[TgPulseOverlay shared] veilDismiss];
        TgUserInfoData *info = [TgUserInfoData yy_modelWithJSON:data];
        [self tg_refreshPersonaLabels:info];
    } failure:^{
        [[TgPulseOverlay shared] veilDismiss];
    }];
}

- (void)tg_refreshPersonaLabels:(nullable TgUserInfoData *)info {
    NSString *name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (name.length == 0) {
        name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    }
    if (name.length == 0) name = @"App";
    if (info.matter.length > 0) name = info.matter;

    NSString *phone = @"+91";
    if (info.receiver.length > 0) {
        NSString *digits = [NSString tg_digitsOnlyFromMixed:info.receiver];
        phone = [NSString stringWithFormat:@"+91 %@", digits.length > 0 ? digits : info.receiver];
    }

    self.tg_nameCaption.text = name;
    self.tg_phoneCaption.text = phone;
}

@end
