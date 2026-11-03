//
//  TgDcApplyVaultController.h
//

#import "TgHullController.h"

@class TgProductInfo;

NS_ASSUME_NONNULL_BEGIN

@interface TgDcApplyVaultController : TgHullController

/// Products from dcRecommend (with nested productTermV3Response).
@property (nonatomic, copy) NSArray<TgProductInfo *> *tg_products;

@end

NS_ASSUME_NONNULL_END
