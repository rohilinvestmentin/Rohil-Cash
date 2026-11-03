//

//

#import "TgHullController.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"

static NSString * const kTgHullBackdropImageUseBg0 = @"use_bg0";
static NSString * const kTgHullBackdropImageUseBg = @"use_bg";
static NSString * const kTgHullBackdropPlainHex = @"#F1F1F1";
static NSString * const kTgHullDefaultBackImage = @"back";

CGFloat const TgHullContentTopBelowNavigation = 30.0;

@interface TgHullController ()

@property (nonatomic, strong) UIImageView *tg_backdropImageView;

@end

@implementation TgHullController

- (instancetype)init {
    self = [super init];
    if (self) {
        _tg_backdropStyle = TgHullBackdropStyleUseBg0;
        _tg_backButtonImageName = kTgHullDefaultBackImage;
        _tg_showsBackButton = YES;
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _tg_backdropStyle = TgHullBackdropStyleUseBg0;
        _tg_backButtonImageName = kTgHullDefaultBackImage;
        _tg_showsBackButton = YES;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _tg_backdropStyle = TgHullBackdropStyleUseBg0;
        _tg_backButtonImageName = kTgHullDefaultBackImage;
        _tg_showsBackButton = YES;
    }
    return self;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = YES;

    _tg_backdropImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    _tg_backdropImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tg_backdropImageView.contentMode = UIViewContentModeScaleAspectFill;
    _tg_backdropImageView.clipsToBounds = YES;
    [self.view insertSubview:_tg_backdropImageView atIndex:0];

    [self tg_applyBackdrop];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self tg_applyTransparentNavigationBar];
    [self tg_refreshBackButtonIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.navigationController.viewControllers.count > 1) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
}

#pragma mark - Backdrop

- (void)tg_applyBackdrop {
    switch (self.tg_backdropStyle) {
        case TgHullBackdropStyleUseBg0: {
            self.view.backgroundColor = UIColor.clearColor;
            self.tg_backdropImageView.hidden = NO;
            self.tg_backdropImageView.image = [UIImage imageNamed:kTgHullBackdropImageUseBg0];
            break;
        }
        case TgHullBackdropStyleUseBg: {
            self.view.backgroundColor = UIColor.clearColor;
            self.tg_backdropImageView.hidden = NO;
            self.tg_backdropImageView.image = [UIImage imageNamed:kTgHullBackdropImageUseBg];
            break;
        }
        case TgHullBackdropStylePlain: {
            self.tg_backdropImageView.hidden = YES;
            self.tg_backdropImageView.image = nil;
            self.view.backgroundColor = [UIColor tg_toneFromHex:kTgHullBackdropPlainHex];
            break;
        }
    }
}

#pragma mark - Navigation bar

- (void)tg_applyTransparentNavigationBar {
    UINavigationBar *bar = self.navigationController.navigationBar;
    if (!bar) return;

    bar.tintColor = [UIColor tg_accentTone];

    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithTransparentBackground];
    appearance.backgroundColor = UIColor.clearColor;
    appearance.shadowColor = UIColor.clearColor;
    appearance.titleTextAttributes = @{
        NSForegroundColorAttributeName: [UIColor tg_accentTone],
        NSFontAttributeName: [UIFont tg_meshGlyphWithSize:17 weight:UIFontWeightMedium]
    };

    bar.standardAppearance = appearance;
    bar.scrollEdgeAppearance = appearance;
    bar.compactAppearance = appearance;
    bar.compactScrollEdgeAppearance = appearance;
}

- (void)tg_setNavTitle:(NSString *)title {
    [self tg_setNavTitle:title color:[UIColor tg_accentTone]];
}

- (void)tg_setNavTitleMedium18:(NSString *)title {
    [self tg_setNavTitle:title color:[UIColor tg_accentTone] fontSize:18];
}

- (void)tg_setNavTitle:(NSString *)title color:(UIColor *)color {
    [self tg_setNavTitle:title color:color fontSize:17];
}

- (void)tg_setNavTitle:(NSString *)title color:(UIColor *)color fontSize:(CGFloat)fontSize {
    if (title.length == 0) {
        self.navigationItem.titleView = nil;
        self.navigationItem.title = nil;
        return;
    }

    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.textColor = color ?: [UIColor tg_accentTone];
    label.font = [UIFont tg_meshGlyphWithSize:fontSize weight:UIFontWeightMedium];
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.lineBreakMode = NSLineBreakByWordWrapping;

    CGFloat barW = CGRectGetWidth(self.navigationController.navigationBar.bounds);
    if (barW < 1) barW = CGRectGetWidth(UIScreen.mainScreen.bounds);
    CGFloat maxW = MAX(barW - 120.0, 160.0);
    CGSize fit = [label sizeThatFits:CGSizeMake(maxW, CGFLOAT_MAX)];
    label.frame = CGRectMake(0, 0, maxW, ceil(fit.height));
    self.navigationItem.titleView = label;
}

- (void)tg_setCustomBackBarButtonItem:(UIBarButtonItem *)item {
    self.navigationItem.leftBarButtonItem = item;
}

- (void)tg_setBackButtonImageName:(NSString *)imageName {
    self.tg_backButtonImageName = imageName.length > 0 ? imageName : kTgHullDefaultBackImage;
    [self tg_refreshBackButtonIfNeeded];
}

- (void)tg_refreshBackButtonIfNeeded {
    if (!self.navigationController || !self.tg_showsBackButton) {
        if (!self.tg_showsBackButton) {
            self.navigationItem.leftBarButtonItem = nil;
            self.navigationItem.hidesBackButton = YES;
        }
        return;
    }

    BOOL isRoot = (self.navigationController.viewControllers.firstObject == self);
    if (isRoot) {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.hidesBackButton = YES;
        return;
    }

    NSString *name = self.tg_backButtonImageName.length > 0 ? self.tg_backButtonImageName : kTgHullDefaultBackImage;
    UIImage *img = [UIImage imageNamed:name];
    if (img) {
        img = [img imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:img
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(tg_onBackTapped)];
    self.navigationItem.leftBarButtonItem = item;
    self.navigationItem.hidesBackButton = NO;
}

- (CGFloat)tg_contentTopBelowNavigation {
    return TgHullContentTopBelowNavigation;
}

- (void)tg_onBackTapped {
    if (self.tg_backInterceptBlock) {
        BOOL allow = self.tg_backInterceptBlock();
        if (!allow) return;
    }
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
