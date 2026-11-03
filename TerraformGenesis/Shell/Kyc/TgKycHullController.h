//

//

#import "TgHullController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TgKycHullController : TgHullController

@property (nonatomic, copy, readonly) NSString *tg_kycId;

- (instancetype)initWithKycId:(NSString *)kycId pageTitle:(NSString *)pageTitle;

@end

NS_ASSUME_NONNULL_END
