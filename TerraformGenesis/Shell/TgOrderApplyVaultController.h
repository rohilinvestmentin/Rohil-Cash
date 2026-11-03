//

//

#import "TgHullController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TgOrderApplyVaultController : TgHullController

@property (nonatomic, copy) NSString *tg_productId;

@property (nonatomic, copy, nullable) NSDictionary *tg_preloadedTermJSON;

@end

NS_ASSUME_NONNULL_END
