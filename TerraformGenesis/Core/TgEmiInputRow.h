//

//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TgEmiInputRowFormat) {
    TgEmiInputRowFormatPlainDigits = 0,
    TgEmiInputRowFormatIndianAmount,
};

@interface TgEmiInputRow : UIView

@property (nonatomic, strong, readonly) UITextField *tg_textField;
@property (nonatomic, copy, nullable) void (^tg_onTextChanged)(NSString *rawDigits);

- (void)tg_configureWithTitle:(NSString *)title
                  placeholder:(NSString *)placeholder
                         hint:(NSString *)hint
                       format:(TgEmiInputRowFormat)format
                     maxValue:(NSInteger)maxValue;

@property (nonatomic, assign) NSInteger tg_maxValue;

- (void)tg_setRawDigitsText:(NSString *)digits;
- (NSString *)tg_rawDigitsText;

@end

NS_ASSUME_NONNULL_END
