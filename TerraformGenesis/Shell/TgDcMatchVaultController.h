//
//  TgDcMatchVaultController.h
//

#import "TgHullController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TgDcMatchVaultController : TgHullController

/// promptCopy from home; used for other-error copy.
@property (nonatomic, copy, nullable) NSString *tg_promptCopy;
/// userStatus from home; 80 shows View Now.
@property (nonatomic, assign) NSInteger tg_userStatus;

@end

NS_ASSUME_NONNULL_END
