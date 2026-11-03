//

//

#import "TgHullController.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TgOrderSuccessExitMode) {

    TgOrderSuccessExitModeHome = 0,

    TgOrderSuccessExitModeOrderDetail,
};

/// One order/product pair for DC multi-product success (docs 19 §7 / 50 §4.7).
@interface TgOrderSuccessPair : NSObject
@property (nonatomic, copy) NSString *orderId;
@property (nonatomic, copy) NSString *productId;
+ (instancetype)pairWithOrderId:(NSString *)orderId productId:(NSString *)productId;
@end

@interface TgOrderSuccessVaultController : TgHullController

@property (nonatomic, copy, nullable) NSString *tg_orderId;
@property (nonatomic, copy, nullable) NSString *tg_productId;
/// When non-empty, page uses DC multi-product layout (docs 19 §7); otherwise single-product §1–§6.
@property (nonatomic, copy, nullable) NSArray<TgOrderSuccessPair *> *tg_orderPairs;
@property (nonatomic, assign) TgOrderSuccessExitMode tg_exitMode;

@end

NS_ASSUME_NONNULL_END
