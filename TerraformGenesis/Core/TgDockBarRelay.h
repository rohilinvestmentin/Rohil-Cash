//

//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TgDockTabIndex) {
    TgDockTabIndexLoan = 0,
    TgDockTabIndexOrder = 1,
    TgDockTabIndexMe = 2,
};

@interface TgDockBarRelay : NSObject

+ (UITabBarController *)forgeDockShell;

+ (void)primeRootAtIndex:(TgDockTabIndex)index dock:(UITabBarController *)dock;

+ (void)primeAllRoots:(UITabBarController *)dock;

@end

NS_ASSUME_NONNULL_END
