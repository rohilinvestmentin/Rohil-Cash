//

//

#import <UIKit/UIKit.h>

@class TgProductInfo;

NS_ASSUME_NONNULL_BEGIN

@interface TgLoanProductCardView : UIView

@property (nonatomic, copy, nullable) void (^tg_onTap)(void);

- (void)tg_configureWithProduct:(TgProductInfo *)product;

@end

NS_ASSUME_NONNULL_END
