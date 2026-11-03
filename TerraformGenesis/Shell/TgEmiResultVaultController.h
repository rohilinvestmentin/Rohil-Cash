//

//

#import "TgHullController.h"

@class TgEmiInputBundle;
@class TgEmiResultBundle;

NS_ASSUME_NONNULL_BEGIN

@interface TgEmiResultVaultController : TgHullController

@property (nonatomic, strong) TgEmiInputBundle *tg_inputBundle;
@property (nonatomic, strong) TgEmiResultBundle *tg_resultBundle;

@end

NS_ASSUME_NONNULL_END
