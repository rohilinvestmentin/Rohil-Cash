//

//

#import "TgHullController.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^TgIfscPickedBlock)(NSString *ifscCode);

@interface TgIfscPickController : TgHullController

@property (nonatomic, copy, nullable) TgIfscPickedBlock tg_onPicked;

@end

NS_ASSUME_NONNULL_END
