//

//

#import <UIKit/UIKit.h>

@class TgOrderItem;

NS_ASSUME_NONNULL_BEGIN

@interface TgOrderStatusDisplay : NSObject

+ (NSString *)tg_titleForOrderStatus:(NSInteger)orderStatus;
+ (UIColor *)tg_colorForOrderStatus:(NSInteger)orderStatus;

+ (NSString *)tg_dateTitleForOrderStatus:(NSInteger)orderStatus;
+ (NSString *)tg_dateValueForItem:(TgOrderItem *)item;

+ (NSString *)tg_formattedAmountFromLoanAmount:(NSInteger)loanAmount;
+ (NSString *)tg_displayOrDash:(nullable NSString *)text;

@end

NS_ASSUME_NONNULL_END
