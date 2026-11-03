//
//  TgDockBarRelay.m
//

#import "TgDockBarRelay.h"
#import "TgLoanShellController.h"
#import "TgOrderShelfController.h"
#import "TgMeVaultController.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"

static CGFloat const kTgDockIconSide = 28.0;

@interface TgDockBarDelegate : NSObject <UITabBarControllerDelegate>
@end

@implementation TgDockBarDelegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    (void)tabBarController; (void)viewController;
    [UIView setAnimationsEnabled:NO];
    return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    (void)viewController;
    [UIView setAnimationsEnabled:YES];
    [TgDockBarRelay primeRootAtIndex:(TgDockTabIndex)tabBarController.selectedIndex dock:tabBarController];
}

@end

@implementation TgDockBarRelay

+ (UITabBarController *)forgeDockShell {
    UITabBarController *dock = [[UITabBarController alloc] init];
    static TgDockBarDelegate *delegate;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ delegate = [[TgDockBarDelegate alloc] init]; });
    dock.delegate = delegate;

    UINavigationController *loanNav = [self tg_navWithTitle:@"Loan"
                                                   normalIcon:@"use_loan1_tab"
                                                 selectedIcon:@"use_loan_tab"];
    UINavigationController *orderNav = [self tg_navWithTitle:@"Order"
                                                    normalIcon:@"use_order1_tab"
                                                  selectedIcon:@"use_order_tab"];
    UINavigationController *meNav = [self tg_navWithTitle:@"Me"
                                               normalIcon:@"use_me1_tab"
                                             selectedIcon:@"use_me_tab"];

    dock.viewControllers = @[loanNav, orderNav, meNav];
    [self tg_applyDockStyle:dock.tabBar];
    [self primeRootAtIndex:TgDockTabIndexLoan dock:dock];
    return dock;
}

+ (void)primeRootAtIndex:(TgDockTabIndex)index dock:(UITabBarController *)dock {
    if (!dock || index < 0 || index >= (NSInteger)dock.viewControllers.count) return;
    UINavigationController *nav = dock.viewControllers[index];
    if (![nav isKindOfClass:[UINavigationController class]]) return;
    if (nav.viewControllers.count > 0) return;
    nav.viewControllers = @[[self tg_rootForIndex:index]];
}

+ (void)primeAllRoots:(UITabBarController *)dock {
    for (NSInteger i = 0; i < 3; i++) {
        [self primeRootAtIndex:(TgDockTabIndex)i dock:dock];
    }
}

#pragma mark - Private

+ (UINavigationController *)tg_navWithTitle:(NSString *)title
                                 normalIcon:(NSString *)normalName
                               selectedIcon:(NSString *)selectedName {
    UINavigationController *nav = [[UINavigationController alloc] init];
    nav.navigationBarHidden = NO;
    nav.tabBarItem = [[UITabBarItem alloc] initWithTitle:title
                                                   image:[self tg_tabImage:normalName]
                                           selectedImage:[self tg_tabImage:selectedName]];
    return nav;
}

+ (UIImage *)tg_tabImage:(NSString *)name {
    UIImage *img = [UIImage imageNamed:name];
    if (!img) return nil;
    img = [img imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    CGSize target = CGSizeMake(kTgDockIconSide, kTgDockIconSide);
    UIGraphicsBeginImageContextWithOptions(target, NO, 0);
    [img drawInRect:CGRectMake(0, 0, target.width, target.height)];
    UIImage *scaled = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [scaled imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

+ (void)tg_applyDockStyle:(UITabBar *)bar {
    UIColor *titleNormal = [UIColor tg_toneFromHex:@"#686868"];
    UIColor *titleSelected = UIColor.blackColor;
    UIColor *iconNormal = [UIColor tg_toneFromHex:@"#99A1AF"];
    UIColor *iconSelected = [UIColor tg_accentTone];
    UIFont *font = [UIFont tg_meshGlyphWithSize:12 weight:UIFontWeightBold];

    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = UIColor.whiteColor;
    appearance.shadowColor = [UIColor colorWithWhite:0 alpha:0.08];

    UITabBarItemAppearance *item = appearance.stackedLayoutAppearance;
    item.normal.iconColor = iconNormal;
    item.selected.iconColor = iconSelected;
    item.normal.titleTextAttributes = @{ NSForegroundColorAttributeName: titleNormal, NSFontAttributeName: font };
    item.selected.titleTextAttributes = @{ NSForegroundColorAttributeName: titleSelected, NSFontAttributeName: font };

    bar.standardAppearance = appearance;
    if (@available(iOS 15.0, *)) {
        bar.scrollEdgeAppearance = appearance;
    }
}

+ (UIViewController *)tg_rootForIndex:(TgDockTabIndex)index {
    switch (index) {
        case TgDockTabIndexLoan: return [[TgLoanShellController alloc] init];
        case TgDockTabIndexOrder: return [[TgOrderShelfController alloc] init];
        case TgDockTabIndexMe: return [[TgMeVaultController alloc] init];
    }
    return [[UIViewController alloc] init];
}

@end
