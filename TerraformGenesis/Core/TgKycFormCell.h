//

//

#import <UIKit/UIKit.h>

@class TgKYCFormItem;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const TgKycPlaceholderEnter;
FOUNDATION_EXPORT NSString * const TgKycPlaceholderChoose;
FOUNDATION_EXPORT NSString * const TgKycPlaceholderIfsc;

FOUNDATION_EXPORT CGFloat const TgKycFormCellFieldHeight;

FOUNDATION_EXPORT CGFloat const TgKycFormCellStackSpacing;

typedef NS_ENUM(NSInteger, TgKycFormCellMode) {
    TgKycFormCellModeInput = 0,
    TgKycFormCellModeSelector,
};

typedef NS_ENUM(NSInteger, TgKycFormInputFilter) {
    TgKycFormInputFilterNone = 0,
    TgKycFormInputFilterDigitsOnly,
    TgKycFormInputFilterAlphanumericsUppercased,
};

typedef void (^TgKycFormTextChangedBlock)(NSString *text);
typedef void (^TgKycFormVoidBlock)(void);

@interface TgKycFormCell : UIView

@property (nonatomic, strong, readonly) UITextField *tg_textField;
@property (nonatomic, copy, nullable) TgKycFormTextChangedBlock tg_onTextChanged;
@property (nonatomic, copy, nullable) TgKycFormVoidBlock tg_onRowTapped;
@property (nonatomic, copy, nullable) TgKycFormVoidBlock tg_onLinkTapped;

+ (NSString *)tg_placeholderIsSelector:(BOOL)isSelector frontPrompts:(nullable NSArray<NSString *> *)prompts;

- (void)tg_bindItemCode:(nullable NSString *)itemCode;

- (void)tg_configureWithTitle:(NSString *)title
                  placeholder:(NSString *)placeholder
                         mode:(TgKycFormCellMode)mode
                       filter:(TgKycFormInputFilter)filter
                     keyboard:(UIKeyboardType)keyboard;

- (void)tg_setLinkTitle:(nullable NSString *)title;

- (void)tg_setDisplayText:(nullable NSString *)text isPlaceholderStyle:(BOOL)isPlaceholderStyle;

- (void)tg_setInputEnabled:(BOOL)enabled;

- (void)tg_configureForKycFormItem:(TgKYCFormItem *)item;

@end

NS_ASSUME_NONNULL_END
