//

//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TgHullBackdropStyle) {
    TgHullBackdropStyleUseBg0 = 0,
    TgHullBackdropStyleUseBg,
    TgHullBackdropStylePlain,
};

typedef BOOL (^TgHullBackInterceptBlock)(void);

FOUNDATION_EXTERN CGFloat const TgHullContentTopBelowNavigation;

@interface TgHullController : UIViewController

@property (nonatomic, assign) TgHullBackdropStyle tg_backdropStyle;

@property (nonatomic, copy, nullable) NSString *tg_backButtonImageName;

@property (nonatomic, assign) BOOL tg_showsBackButton;

@property (nonatomic, copy, nullable) TgHullBackInterceptBlock tg_backInterceptBlock;

- (void)tg_applyBackdrop;
- (void)tg_applyTransparentNavigationBar;
- (void)tg_setNavTitle:(nullable NSString *)title;
- (void)tg_setNavTitle:(nullable NSString *)title color:(nullable UIColor *)color;
- (void)tg_setNavTitle:(nullable NSString *)title color:(nullable UIColor *)color fontSize:(CGFloat)fontSize;

- (void)tg_setNavTitleMedium18:(nullable NSString *)title;
- (void)tg_setCustomBackBarButtonItem:(nullable UIBarButtonItem *)item;
- (void)tg_setBackButtonImageName:(nullable NSString *)imageName;

- (void)tg_onBackTapped;

- (CGFloat)tg_contentTopBelowNavigation;

@end

NS_ASSUME_NONNULL_END
