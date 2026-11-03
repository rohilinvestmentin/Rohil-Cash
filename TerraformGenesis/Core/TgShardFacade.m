//
//  TgShardFacade.m
//

#import "TgShardFacade.h"
#import "TgShardOptionPicker.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImage+GIF.h>

static NSString * const kTgShardLoadingGIF = @"loading";
static CGFloat const kTgShardMaskAlpha = 0.7;
static CGFloat const kTgShardPanelWidthRatio = 0.85;
static CGFloat const kTgShardVeilCardWidthRatio = 0.72;
static CGFloat const kTgShardVeilCardCorner = 20.0;
static CGFloat const kTgShardVeilGifSize = 64.0;
static CGFloat const kTgShardButtonHeight = 50.0;
static CGFloat const kTgShardButtonCorner = 25.0;

typedef NS_ENUM(NSInteger, TgShardKind) {
    TgShardKindVeil = 0,
    TgShardKindPanel,
};

@interface TgShardRecord : NSObject
@property (nonatomic, copy) NSString *token;
@property (nonatomic, assign) TgShardKind kind;
@property (nonatomic, strong, nullable) UIWindow *hostWindow;
@property (nonatomic, strong) UIView *shellView;
@property (nonatomic, weak, nullable) UIView *parentView;
@property (nonatomic, assign) CGFloat tierRank;
@end

@implementation TgShardRecord
@end

@implementation TgShardPanelConfig
- (instancetype)init {
    self = [super init];
    if (self) {
        _tier = TgShardTierMid;
        _mount = TgShardMountWindow;
        _dismissOnPrimaryAction = YES;
        _dismissOnSecondaryAction = YES;
    }
    return self;
}
@end

@interface TgShardFacade ()
@property (nonatomic, strong) NSMutableArray<TgShardRecord *> *records;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIWindow *> *tierWindows;
@end

@implementation TgShardFacade

+ (instancetype)shared {
    static TgShardFacade *facade;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ facade = [[TgShardFacade alloc] init]; });
    return facade;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _records = [NSMutableArray array];
        _tierWindows = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Veil

- (NSString *)showVeilText:(NSString *)text {
    return [self showVeilText:text tier:TgShardTierMid];
}

- (NSString *)showVeilText:(NSString *)text tier:(TgShardTier)tier {
    return [self tg_presentVeilText:text tier:tier hostView:nil];
}

- (NSString *)showVeilText:(NSString *)text inView:(UIView *)hostView {
    return [self tg_presentVeilText:text tier:TgShardTierMid hostView:hostView];
}

- (void)dismissVeilToken:(NSString *)token {
    [self tg_dismissToken:token kind:TgShardKindVeil];
}

- (void)dismissAllVeils {
    [self tg_dismissAllKind:TgShardKindVeil];
}

#pragma mark - Panel

- (NSString *)showPanel:(TgShardPanelConfig *)config {
    if (!config) return @"";
    if (config.customBodyView) {
        config.panelStyle = TgShardPanelStyleCustomBody;
    }
    return [self tg_presentPanel:config];
}

- (NSString *)showOptionPickerWithTitle:(NSString *)title
                                options:(NSArray<NSString *> *)options
                          selectedIndex:(NSInteger)selectedIndex
                           confirmTitle:(NSString *)confirmTitle
                              onConfirm:(void (^)(NSInteger, NSString *))onConfirm {
    return [TgShardOptionPicker showWithTitle:title
                                      options:options
                                selectedIndex:selectedIndex
                                 confirmTitle:confirmTitle
                                    onConfirm:onConfirm];
}

- (NSString *)showTextPanelWithContent:(NSString *)content
                          primaryTitle:(NSString *)primaryTitle
                        secondaryTitle:(NSString *)secondaryTitle
                          primaryAction:(void (^)(void))primaryAction
                        secondaryAction:(void (^)(void))secondaryAction {
    TgShardPanelConfig *cfg = [[TgShardPanelConfig alloc] init];
    cfg.panelStyle = TgShardPanelStyleText;
    cfg.content = content;
    cfg.primaryTitle = primaryTitle;
    cfg.secondaryTitle = secondaryTitle;
    cfg.primaryAction = primaryAction;
    cfg.secondaryAction = secondaryAction;
    return [self showPanel:cfg];
}

- (NSString *)showCustomBodyPanel:(UIView *)bodyView
                            title:(NSString *)title
                    primaryTitle:(NSString *)primaryTitle
                  secondaryTitle:(NSString *)secondaryTitle
                    primaryAction:(void (^)(void))primaryAction
                  secondaryAction:(void (^)(void))secondaryAction {
    TgShardPanelConfig *cfg = [[TgShardPanelConfig alloc] init];
    cfg.panelStyle = TgShardPanelStyleCustomBody;
    cfg.customBodyView = bodyView;
    cfg.title = title;
    cfg.primaryTitle = primaryTitle;
    cfg.secondaryTitle = secondaryTitle;
    cfg.primaryAction = primaryAction;
    cfg.secondaryAction = secondaryAction;
    return [self showPanel:cfg];
}

- (void)dismissPanelToken:(NSString *)token {
    [self tg_dismissToken:token kind:TgShardKindPanel];
}

- (void)dismissTopPanel {
    TgShardRecord *top = [self tg_topRecordOfKind:TgShardKindPanel];
    if (top) [self tg_removeRecord:top animated:YES];
}

- (void)dismissAllPanels {
    [self tg_dismissAllKind:TgShardKindPanel];
}

#pragma mark - Present veil

- (NSString *)tg_presentVeilText:(NSString *)text tier:(TgShardTier)tier hostView:(UIView *)hostView {
    NSString *token = [[NSUUID UUID] UUIDString];
    [self onMain:^{
        NSString *captionRaw = text.length > 0 ? text : @"";
        NSString *caption = [captionRaw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        UIView *container = nil;
        UIWindow *window = nil;
        if (hostView) {
            container = hostView;
        } else {
            window = [self obtainTierWindow:tier];
            container = window.rootViewController.view;
        }

        UIView *shell = [[UIView alloc] initWithFrame:container.bounds];
        shell.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        shell.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:kTgShardMaskAlpha];
        shell.alpha = 0;
        shell.userInteractionEnabled = YES;

        UIView *card = [[UIView alloc] init];
        card.backgroundColor = UIColor.whiteColor;
        card.layer.cornerRadius = kTgShardVeilCardCorner;
        card.clipsToBounds = YES;
        [shell addSubview:card];

        UIImageView *gifView = [[UIImageView alloc] init];
        gifView.contentMode = UIViewContentModeScaleAspectFit;
        [self tg_applyLoadingGIFToImageView:gifView];
        [card addSubview:gifView];

        UILabel *label = nil;
        if (caption.length > 0) {
            label = [[UILabel alloc] init];
            label.text = caption;
            label.textColor = UIColor.blackColor;
            label.font = [UIFont tg_meshGlyphWithSize:15 weight:UIFontWeightMedium];
            label.textAlignment = NSTextAlignmentCenter;
            label.numberOfLines = 0;
            [card addSubview:label];
        }

        CGFloat cardW = MAX(floor(container.bounds.size.width * kTgShardVeilCardWidthRatio), 240.0);
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(shell);
            make.width.mas_equalTo(cardW);
        }];
        [gifView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(card).offset(28);
            make.centerX.equalTo(card);
            make.width.height.mas_equalTo(kTgShardVeilGifSize);
            if (!label) make.bottom.equalTo(card).offset(-28);
        }];
        if (label) {
            [label mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(gifView.mas_bottom).offset(16);
                make.left.equalTo(card).offset(20);
                make.right.equalTo(card).offset(-20);
                make.bottom.equalTo(card).offset(-24);
            }];
        }

        [container addSubview:shell];
        [UIView animateWithDuration:0.2 animations:^{ shell.alpha = 1; }];

        TgShardRecord *rec = [[TgShardRecord alloc] init];
        rec.token = token;
        rec.kind = TgShardKindVeil;
        rec.shellView = shell;
        rec.hostWindow = window;
        rec.parentView = hostView;
        rec.tierRank = [self tierRank:tier];
        [self.records addObject:rec];
    }];
    return token;
}

#pragma mark - Present panel

- (NSString *)tg_presentPanel:(TgShardPanelConfig *)config {
    NSString *token = [[NSUUID UUID] UUIDString];
    [self onMain:^{
        UIView *container = nil;
        UIWindow *window = nil;
        if (config.mount == TgShardMountView && config.hostView) {
            container = config.hostView;
        } else {
            window = [self obtainTierWindow:config.tier];
            container = window.rootViewController.view;
        }

        CGFloat panelW = CGRectGetWidth(container.bounds) * kTgShardPanelWidthRatio;

        UIView *shell = [[UIView alloc] initWithFrame:container.bounds];
        shell.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        shell.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:kTgShardMaskAlpha];
        shell.alpha = 0;
        shell.userInteractionEnabled = YES;

        UIView *card = [[UIView alloc] init];
        card.backgroundColor = [UIColor tg_toneFromHex:@"#FAFAFA"];
        card.layer.cornerRadius = 12;
        card.clipsToBounds = YES;
        [shell addSubview:card];

        UIView *buttonRow = [[UIView alloc] init];
        [card addSubview:buttonRow];

        TgShardRecord *rec = [[TgShardRecord alloc] init];
        rec.token = token;
        rec.kind = TgShardKindPanel;
        rec.shellView = shell;
        rec.hostWindow = window;
        rec.parentView = (config.mount == TgShardMountView ? container : nil);
        rec.tierRank = [self tierRank:config.tier];
        [self.records addObject:rec];

        [self tg_installButtons:buttonRow config:config record:rec];

        UIView *bodyAnchor = nil;
        if (config.panelStyle == TgShardPanelStyleCustomBody && config.customBodyView) {
            bodyAnchor = [self tg_installCustomBody:config card:card];
        } else {
            bodyAnchor = [self tg_installTextBody:config card:card];
        }

        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(shell);
            make.width.mas_equalTo(panelW);
        }];
        [buttonRow mas_makeConstraints:^(MASConstraintMaker *make) {
            if (bodyAnchor) {
                make.top.equalTo(bodyAnchor.mas_bottom).offset(24);
            } else {
                make.top.equalTo(card).offset(24);
            }
            make.left.equalTo(card).offset(20);
            make.right.equalTo(card).offset(-20);
            make.bottom.equalTo(card).offset(-24);
            make.height.mas_equalTo(config.primaryTitle.length > 0 ? kTgShardButtonHeight : 0);
        }];

        [container addSubview:shell];
        [UIView animateWithDuration:0.25 animations:^{ shell.alpha = 1; }];
    }];
    return token;
}

- (UIView *)tg_installTextBody:(TgShardPanelConfig *)config card:(UIView *)card {
    UIStackView *textStack = [[UIStackView alloc] init];
    textStack.axis = UILayoutConstraintAxisVertical;
    textStack.spacing = 12;
    textStack.alignment = UIStackViewAlignmentFill;
    [card addSubview:textStack];

    NSString *title = [config.title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (title.length > 0) {
        [textStack addArrangedSubview:[self tg_titleLabel:title]];
    }
    NSString *content = [config.content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (content.length > 0) {
        [textStack addArrangedSubview:[self tg_contentLabel:content]];
    }
    NSString *detail = [config.detailText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (detail.length > 0) {
        [textStack addArrangedSubview:[self tg_detailLabel:detail]];
    }

    [textStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(24);
        make.left.equalTo(card).offset(20);
        make.right.equalTo(card).offset(-20);
    }];
    return textStack.arrangedSubviews.count > 0 ? textStack : nil;
}

- (UIView *)tg_installCustomBody:(TgShardPanelConfig *)config card:(UIView *)card {
    UIView *topAnchor = nil;

    NSString *title = [config.title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (title.length > 0) {
        UILabel *titleLab = [self tg_titleLabel:title];
        [card addSubview:titleLab];
        [titleLab mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(card).offset(24);
            make.left.equalTo(card).offset(20);
            make.right.equalTo(card).offset(-20);
        }];
        topAnchor = titleLab;
    }

    UIView *bodyHost = [[UIView alloc] init];
    bodyHost.backgroundColor = UIColor.clearColor;
    [card addSubview:bodyHost];

    UIView *body = config.customBodyView;
    [body removeFromSuperview];
    [bodyHost addSubview:body];

    [body mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(bodyHost);
    }];

    [bodyHost mas_makeConstraints:^(MASConstraintMaker *make) {
        if (topAnchor) {
            make.top.equalTo(topAnchor.mas_bottom).offset(16);
        } else {
            make.top.equalTo(card).offset(24);
        }
        make.left.equalTo(card).offset(20);
        make.right.equalTo(card).offset(-20);
        if (config.customBodyHeight > 0) {
            make.height.mas_equalTo(config.customBodyHeight);
        }
    }];

    return bodyHost;
}

- (void)tg_installButtons:(UIView *)buttonRow config:(TgShardPanelConfig *)config record:(TgShardRecord *)rec {
    BOOL dual = config.secondaryTitle.length > 0 && config.primaryTitle.length > 0;
    __weak typeof(self) weakSelf = self;
    if (config.primaryTitle.length == 0) return;

    UIButton *primaryBtn = [self tg_primaryButton:config.primaryTitle];
    [buttonRow addSubview:primaryBtn];
    [primaryBtn addAction:[UIAction actionWithHandler:^(__kindof UIAction *a) {
        (void)a;
        if (config.primaryAction) config.primaryAction();
        if (config.dismissOnPrimaryAction) {
            [weakSelf tg_removeRecord:rec animated:YES];
        }
    }] forControlEvents:UIControlEventTouchUpInside];

    if (dual) {
        UIButton *secondaryBtn = [self tg_secondaryButton:config.secondaryTitle];
        [buttonRow addSubview:secondaryBtn];
        [secondaryBtn addAction:[UIAction actionWithHandler:^(__kindof UIAction *a) {
            (void)a;
            if (config.secondaryAction) config.secondaryAction();
            if (config.dismissOnSecondaryAction) {
                [weakSelf tg_removeRecord:rec animated:YES];
            }
        }] forControlEvents:UIControlEventTouchUpInside];
        CGFloat gap = 12;
        [secondaryBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.bottom.equalTo(buttonRow);
            make.right.equalTo(buttonRow.mas_centerX).offset(-gap / 2);
        }];
        [primaryBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.top.bottom.equalTo(buttonRow);
            make.left.equalTo(buttonRow.mas_centerX).offset(gap / 2);
        }];
    } else {
        [primaryBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.top.bottom.equalTo(buttonRow);
            make.width.equalTo(buttonRow).multipliedBy(0.8);
        }];
    }
}

#pragma mark - UI helpers

- (UILabel *)tg_titleLabel:(NSString *)text {
    UILabel *lab = [[UILabel alloc] init];
    lab.text = text;
    lab.textColor = UIColor.blackColor;
    lab.font = [UIFont tg_meshGlyphWithSize:20 weight:UIFontWeightBold];
    lab.numberOfLines = 0;
    lab.textAlignment = NSTextAlignmentCenter;
    return lab;
}

- (UILabel *)tg_contentLabel:(NSString *)text {
    UILabel *lab = [[UILabel alloc] init];
    lab.text = text;
    lab.textColor = UIColor.blackColor;
    lab.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightRegular];
    lab.numberOfLines = 0;
    lab.textAlignment = NSTextAlignmentCenter;
    return lab;
}

- (UILabel *)tg_detailLabel:(NSString *)text {
    UILabel *lab = [[UILabel alloc] init];
    lab.text = text;
    lab.textColor = [UIColor tg_toneFromHex:@"#686868"];
    lab.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightRegular];
    lab.numberOfLines = 0;
    lab.textAlignment = NSTextAlignmentCenter;
    return lab;
}

- (UIButton *)tg_primaryButton:(NSString *)title {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    btn.backgroundColor = [UIColor tg_toneFromHex:@"#182040"];
    btn.layer.cornerRadius = kTgShardButtonCorner;
    btn.clipsToBounds = YES;
    return btn;
}

- (UIButton *)tg_secondaryButton:(NSString *)title {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    btn.backgroundColor = [UIColor tg_toneFromHex:@"#A9B5D0"];
    btn.layer.cornerRadius = kTgShardButtonCorner;
    btn.clipsToBounds = YES;
    return btn;
}

- (void)tg_applyLoadingGIFToImageView:(UIImageView *)imageView {
    NSString *path = [[NSBundle mainBundle] pathForResource:kTgShardLoadingGIF ofType:@"gif"];
    if (path.length > 0) {
        NSData *data = [NSData dataWithContentsOfFile:path];
        UIImage *gif = [UIImage sd_imageWithGIFData:data];
        if (gif.images.count > 0) {
            imageView.image = gif.images.firstObject;
            imageView.animationImages = gif.images;
            imageView.animationDuration = gif.duration > 0 ? gif.duration : 1.0;
            imageView.animationRepeatCount = 0;
            [imageView startAnimating];
            return;
        }
        if (gif) {
            imageView.image = gif;
            return;
        }
    }
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    spinner.color = UIColor.blackColor;
    [spinner startAnimating];
    UIImageView *holder = imageView;
    [holder addSubview:spinner];
    [spinner mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(holder);
    }];
}

#pragma mark - Records / windows

- (void)tg_dismissToken:(NSString *)token kind:(TgShardKind)kind {
    if (token.length == 0) return;
    [self onMain:^{
        TgShardRecord *target = nil;
        for (TgShardRecord *rec in self.records) {
            if (rec.kind == kind && [rec.token isEqualToString:token]) {
                target = rec;
                break;
            }
        }
        if (target) [self tg_removeRecord:target animated:YES];
    }];
}

- (void)tg_dismissAllKind:(TgShardKind)kind {
    [self onMain:^{
        NSArray *copy = [self.records copy];
        for (TgShardRecord *rec in copy) {
            if (rec.kind == kind) [self tg_removeRecord:rec animated:YES];
        }
    }];
}

- (nullable TgShardRecord *)tg_topRecordOfKind:(TgShardKind)kind {
    TgShardRecord *top = nil;
    for (TgShardRecord *rec in self.records) {
        if (rec.kind != kind) continue;
        if (!top || rec.tierRank >= top.tierRank) top = rec;
    }
    return top;
}

- (void)tg_removeRecord:(TgShardRecord *)rec animated:(BOOL)animated {
    if (!rec) return;
    void (^finish)(void) = ^{
        [rec.shellView removeFromSuperview];
        if (rec.hostWindow) {
            rec.hostWindow.hidden = YES;
            rec.hostWindow.rootViewController = nil;
        }
        [self.records removeObject:rec];
        [self tg_scheduleRetireIdleTierWindows];
    };
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            rec.shellView.alpha = 0;
        } completion:^(BOOL done) {
            finish();
        }];
    } else {
        finish();
    }
}

- (UIWindow *)obtainTierWindow:(TgShardTier)tier {
    NSNumber *key = @(tier);
    UIWindow *existing = self.tierWindows[key];
    if (existing && existing.windowScene) {
        existing.hidden = NO;
        return existing;
    }
    UIWindowScene *scene = [self activeScene];
    if (!scene) return nil;

    UIWindow *window = [[UIWindow alloc] initWithWindowScene:scene];
    window.frame = UIScreen.mainScreen.bounds;
    window.windowLevel = UIWindowLevelAlert + [self tierRank:tier];
    window.backgroundColor = UIColor.clearColor;

    UIViewController *root = [[UIViewController alloc] init];
    root.view.backgroundColor = UIColor.clearColor;
    window.rootViewController = root;
    window.hidden = NO;

    self.tierWindows[key] = window;
    return window;
}

- (void)tg_scheduleRetireIdleTierWindows {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self tg_retireIdleTierWindows];
    });
}

- (void)tg_retireIdleTierWindows {
    NSMutableArray *idleKeys = [NSMutableArray array];
    for (NSNumber *key in self.tierWindows) {
        UIWindow *window = self.tierWindows[key];
        if (!window) continue;
        BOOL busy = NO;
        for (TgShardRecord *rec in self.records) {
            if (rec.hostWindow == window) {
                busy = YES;
                break;
            }
        }
        if (!busy) {
            window.hidden = YES;
            window.rootViewController = nil;
            [idleKeys addObject:key];
        }
    }
    [self.tierWindows removeObjectsForKeys:idleKeys];
}

- (CGFloat)tierRank:(TgShardTier)tier {
    switch (tier) {
        case TgShardTierFloor: return 100;
        case TgShardTierLow: return 200;
        case TgShardTierMid: return 300;
        case TgShardTierHigh: return 400;
    }
    return 300;
}

- (UIWindowScene *)activeScene {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
            return (UIWindowScene *)scene;
        }
    }
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) return (UIWindowScene *)scene;
    }
    return nil;
}

- (void)onMain:(dispatch_block_t)block {
    if ([NSThread isMainThread]) block();
    else dispatch_async(dispatch_get_main_queue(), block);
}

@end
