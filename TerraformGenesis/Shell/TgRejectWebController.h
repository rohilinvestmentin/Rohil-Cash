//
//  TgRejectWebController.h
//

#import "TgHullController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TgRejectWebController : TgHullController

- (instancetype)initWithRejectH5URLString:(NSString *)urlString;

+ (BOOL)tg_tryPushFromNav:(nullable UINavigationController *)nav
         unavailableToast:(nullable NSString *)unavailableToast;

+ (BOOL)tg_tryReplaceTopFromNav:(nullable UINavigationController *)nav;

+ (nullable NSString *)tg_cachedRejectH5URLString;

@end

NS_ASSUME_NONNULL_END
