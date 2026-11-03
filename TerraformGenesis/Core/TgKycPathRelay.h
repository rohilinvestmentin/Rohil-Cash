//

//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TgKycPathRelay : NSObject

+ (instancetype)shared;

+ (void)startAuthFromNav:(UINavigationController *)nav;

+ (void)startAuthFromNav:(UINavigationController *)nav targetVC:(nullable UIViewController *)targetVC;

+ (void)continueAfterCommitFromNav:(UINavigationController *)nav;

@end

NS_ASSUME_NONNULL_END
