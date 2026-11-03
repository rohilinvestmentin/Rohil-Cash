//
//  TgKycFormCell.m
//

#import "TgKycFormCell.h"
#import "TgPayloadModels.h"
#import "NSString+TgGlyph.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>

CGFloat const TgKycFormCellFieldHeight = 54.0;
CGFloat const TgKycFormCellStackSpacing = 22.0;
static CGFloat const kTgKycFieldRadius = 16.0;
static NSString * const kTgKycTitleHex = @"#364153";
static NSString * const kTgKycPlaceholderHex = @"#9CA3AF";
static NSString * const kTgKycLinkHex = @"#C51B12";

static NSString * const kTgKycSelectorArrowAsset = @"use_next_loan_hong";

static NSString * const kTgKycLinkArrowAsset = @"use_next_loan";
static CGFloat const kTgKycSelectorArrowSize = 16.0;
static CGFloat const kTgKycLinkArrowSize = 12.0;
static CGFloat const kTgKycLinkStackSpacing = 2.0;
static CGFloat const kTgKycWhatsAppPrefixSize = 15.0;
static CGFloat const kTgKycWhatsAppPrefixLeading = 12.0;
static CGFloat const kTgKycWhatsAppPrefixTrailing = 8.0;

NSString * const TgKycPlaceholderEnter = @"Please enter";
NSString * const TgKycPlaceholderChoose = @"Please choose";
NSString * const TgKycPlaceholderIfsc = @"Please type in or select";

@interface TgKycFormCell () <UITextFieldDelegate>
@property (nonatomic, strong) UILabel *tg_titleCaption;
@property (nonatomic, strong) UIView *tg_fieldVeil;
@property (nonatomic, strong, readwrite) UITextField *tg_textField;
@property (nonatomic, strong) UIView *tg_linkTrail;
@property (nonatomic, strong) UIStackView *tg_linkStack;
@property (nonatomic, strong) UIButton *tg_linkLatch;
@property (nonatomic, strong) UIImageView *tg_linkArrowGlyph;
@property (nonatomic, strong) UIImageView *tg_chevronGlyph;
@property (nonatomic, assign) TgKycFormCellMode tg_mode;
@property (nonatomic, assign) TgKycFormInputFilter tg_filter;
@property (nonatomic, copy) NSString *tg_boundItemCode;
@end

@implementation TgKycFormCell

+ (NSString *)tg_placeholderIsSelector:(BOOL)isSelector frontPrompts:(NSArray<NSString *> *)prompts {
    if (prompts.count > 0 && prompts.firstObject.length > 0) {
        return prompts.firstObject;
    }
    return isSelector ? TgKycPlaceholderChoose : TgKycPlaceholderEnter;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self tg_buildUI];
    }
    return self;
}

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (void)tg_buildUI {
    self.tg_titleCaption = [[UILabel alloc] init];
    self.tg_titleCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightMedium];
    self.tg_titleCaption.textColor = [UIColor tg_toneFromHex:kTgKycTitleHex];
    self.tg_titleCaption.numberOfLines = 0;
    [self addSubview:self.tg_titleCaption];

    self.tg_fieldVeil = [[UIView alloc] init];
    self.tg_fieldVeil.backgroundColor = UIColor.whiteColor;
    self.tg_fieldVeil.layer.cornerRadius = kTgKycFieldRadius;
    self.tg_fieldVeil.clipsToBounds = YES;
    [self addSubview:self.tg_fieldVeil];

    self.tg_textField = [[UITextField alloc] init];
    self.tg_textField.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    self.tg_textField.textColor = [UIColor tg_toneFromHex:kTgKycTitleHex];
    self.tg_textField.borderStyle = UITextBorderStyleNone;
    self.tg_textField.returnKeyType = UIReturnKeyDone;
    self.tg_textField.delegate = self;
    [self.tg_textField addTarget:self action:@selector(tg_textDidChange) forControlEvents:UIControlEventEditingChanged];
    UIView *leftPad = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 10)];
    self.tg_textField.leftView = leftPad;
    self.tg_textField.leftViewMode = UITextFieldViewModeAlways;
    [self.tg_fieldVeil addSubview:self.tg_textField];

    self.tg_linkTrail = [[UIView alloc] init];
    self.tg_linkTrail.hidden = YES;
    [self.tg_fieldVeil addSubview:self.tg_linkTrail];

    self.tg_linkLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    self.tg_linkLatch.titleLabel.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightMedium];
    [self.tg_linkLatch setTitleColor:[UIColor tg_toneFromHex:kTgKycLinkHex] forState:UIControlStateNormal];
    self.tg_linkLatch.contentEdgeInsets = UIEdgeInsetsZero;
    [self.tg_linkLatch addTarget:self action:@selector(tg_linkTapped) forControlEvents:UIControlEventTouchUpInside];

    self.tg_linkArrowGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgKycLinkArrowAsset]];
    self.tg_linkArrowGlyph.contentMode = UIViewContentModeScaleAspectFit;
    self.tg_linkArrowGlyph.userInteractionEnabled = NO;

    self.tg_linkStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.tg_linkLatch, self.tg_linkArrowGlyph]];
    self.tg_linkStack.axis = UILayoutConstraintAxisHorizontal;
    self.tg_linkStack.spacing = kTgKycLinkStackSpacing;
    self.tg_linkStack.alignment = UIStackViewAlignmentCenter;
    [self.tg_linkTrail addSubview:self.tg_linkStack];

    UITapGestureRecognizer *linkTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tg_linkTapped)];
    [self.tg_linkTrail addGestureRecognizer:linkTap];

    self.tg_chevronGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgKycSelectorArrowAsset]];
    self.tg_chevronGlyph.contentMode = UIViewContentModeScaleAspectFit;
    self.tg_chevronGlyph.hidden = YES;
    self.tg_chevronGlyph.userInteractionEnabled = NO;
    [self.tg_fieldVeil addSubview:self.tg_chevronGlyph];

    UITapGestureRecognizer *rowTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tg_rowTapped)];
    [self.tg_fieldVeil addGestureRecognizer:rowTap];

    [self.tg_titleCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
    }];
    [self.tg_fieldVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_titleCaption.mas_bottom).offset(8);
        make.left.right.bottom.equalTo(self);
        make.height.mas_equalTo(TgKycFormCellFieldHeight);
    }];
    [self.tg_chevronGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.tg_fieldVeil).offset(-12);
        make.centerY.equalTo(self.tg_fieldVeil);
        make.width.height.mas_equalTo(kTgKycSelectorArrowSize);
    }];
    [self.tg_linkTrail mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.tg_fieldVeil).offset(-12);
        make.centerY.equalTo(self.tg_fieldVeil);
    }];
    [self.tg_linkStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_linkTrail);
    }];
    [self.tg_linkArrowGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(kTgKycLinkArrowSize);
    }];
    [self tg_rebuildTextTrailing];
}

- (void)tg_rebuildTextTrailing {
    [self.tg_textField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(self.tg_fieldVeil);
        if (!self.tg_linkTrail.hidden) {
            make.right.equalTo(self.tg_linkTrail.mas_left).offset(-8);
        } else if (!self.tg_chevronGlyph.hidden) {
            make.right.equalTo(self.tg_chevronGlyph.mas_left).offset(-8);
        } else {
            make.right.equalTo(self.tg_fieldVeil).offset(-12);
        }
    }];
}

- (void)tg_applyDefaultLeftPad {
    UIView *pad = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 10)];
    self.tg_textField.leftView = pad;
    self.tg_textField.leftViewMode = UITextFieldViewModeAlways;
}

- (void)tg_applyWhatsAppLeftView {
    UILabel *prefix = [[UILabel alloc] init];
    prefix.text = @"+91";
    prefix.font = [UIFont tg_meshGlyphWithSize:kTgKycWhatsAppPrefixSize weight:UIFontWeightMedium];
    prefix.textColor = [UIColor tg_toneFromHex:kTgKycLinkHex];
    prefix.textAlignment = NSTextAlignmentLeft;

    CGSize textSize = [prefix sizeThatFits:CGSizeMake(CGFLOAT_MAX, TgKycFormCellFieldHeight)];
    CGFloat width = kTgKycWhatsAppPrefixLeading + ceil(textSize.width) + kTgKycWhatsAppPrefixTrailing;
    UIView *wrap = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, TgKycFormCellFieldHeight)];
    [wrap addSubview:prefix];
    prefix.frame = CGRectMake(kTgKycWhatsAppPrefixLeading,
                            0,
                            ceil(textSize.width),
                            TgKycFormCellFieldHeight);

    self.tg_textField.leftView = wrap;
    self.tg_textField.leftViewMode = UITextFieldViewModeAlways;
}

- (void)tg_configureWithTitle:(NSString *)title
                  placeholder:(NSString *)placeholder
                         mode:(TgKycFormCellMode)mode
                       filter:(TgKycFormInputFilter)filter
                     keyboard:(UIKeyboardType)keyboard {
    self.tg_mode = mode;
    self.tg_filter = filter;
    self.tg_boundItemCode = nil;
    self.tg_titleCaption.text = title;
    self.tg_textField.keyboardType = keyboard;
    self.tg_textField.autocapitalizationType = (filter == TgKycFormInputFilterAlphanumericsUppercased)
        ? UITextAutocapitalizationTypeAllCharacters : UITextAutocapitalizationTypeNone;
    self.tg_textField.userInteractionEnabled = (mode == TgKycFormCellModeInput);
    self.tg_chevronGlyph.hidden = (mode != TgKycFormCellModeSelector);
    self.tg_linkTrail.hidden = YES;
    [self tg_applyDefaultLeftPad];
    [self tg_applyPlaceholder:placeholder];
    [self tg_rebuildTextTrailing];
}

- (void)tg_bindItemCode:(NSString *)itemCode {
    self.tg_boundItemCode = [itemCode lowercaseString];
    if (self.tg_boundItemCode.length == 0) return;

    if ([self.tg_boundItemCode isEqualToString:@"ifsc"]) {
        self.tg_filter = TgKycFormInputFilterAlphanumericsUppercased;
        self.tg_textField.keyboardType = UIKeyboardTypeASCIICapable;
        self.tg_textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        [self tg_applyDefaultLeftPad];
        return;
    }
    if ([self.tg_boundItemCode isEqualToString:@"whatsapp"]) {
        self.tg_filter = TgKycFormInputFilterDigitsOnly;
        self.tg_textField.keyboardType = UIKeyboardTypeNumberPad;
        [self tg_applyWhatsAppLeftView];
        return;
    }
    if ([self.tg_boundItemCode isEqualToString:@"child_count"]
        || [self.tg_boundItemCode isEqualToString:@"account_no"]
        || [self.tg_boundItemCode isEqualToString:@"account_no_verify"]
        || [self.tg_boundItemCode isEqualToString:@"credit_card"]) {
        self.tg_filter = TgKycFormInputFilterDigitsOnly;
        self.tg_textField.keyboardType = UIKeyboardTypeNumberPad;
        [self tg_applyDefaultLeftPad];
        return;
    }
    if ([self.tg_boundItemCode isEqualToString:@"email"]) {
        self.tg_filter = TgKycFormInputFilterNone;
        self.tg_textField.keyboardType = UIKeyboardTypeEmailAddress;
        self.tg_textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [self tg_applyDefaultLeftPad];
        return;
    }
    [self tg_applyDefaultLeftPad];
}

- (void)tg_setLinkTitle:(NSString *)title {
    BOOL show = title.length > 0;
    self.tg_linkTrail.hidden = !show;
    self.tg_chevronGlyph.hidden = show || (self.tg_mode != TgKycFormCellModeSelector);
    if (show) {
        [self.tg_linkLatch setTitle:title forState:UIControlStateNormal];
        self.tg_linkArrowGlyph.image = [UIImage imageNamed:kTgKycLinkArrowAsset];
    }
    [self tg_rebuildTextTrailing];
}

- (void)tg_setDisplayText:(NSString *)text isPlaceholderStyle:(BOOL)isPlaceholderStyle {
    self.tg_textField.text = text;
    self.tg_textField.textColor = isPlaceholderStyle
        ? [UIColor tg_toneFromHex:kTgKycPlaceholderHex]
        : [UIColor tg_toneFromHex:kTgKycTitleHex];
}

- (void)tg_setInputEnabled:(BOOL)enabled {
    self.tg_textField.userInteractionEnabled = enabled && (self.tg_mode == TgKycFormCellModeInput);
    self.tg_fieldVeil.alpha = enabled ? 1.0 : 0.85;
}

- (void)tg_configureForKycFormItem:(TgKYCFormItem *)item {
    BOOL isSelector = item.favourable != 1;
    NSString *code = [item.performance lowercaseString];
    NSString *placeholder = [[self class] tg_placeholderIsSelector:isSelector frontPrompts:item.squeeze];
    if (!isSelector && [code isEqualToString:@"ifsc"]) {
        placeholder = TgKycPlaceholderIfsc;
    }
    if (isSelector && item.radio.count > 0) {
        placeholder = TgKycPlaceholderChoose;
    }

    TgKycFormInputFilter filter = TgKycFormInputFilterNone;
    UIKeyboardType keyboard = UIKeyboardTypeDefault;
    if (!isSelector) {
        if ([code isEqualToString:@"ifsc"]) {
            filter = TgKycFormInputFilterAlphanumericsUppercased;
        } else if ([code isEqualToString:@"whatsapp"] || [code isEqualToString:@"child_count"]
                   || [code isEqualToString:@"account_no"] || [code isEqualToString:@"account_no_verify"]
                   || [code isEqualToString:@"credit_card"]) {
            filter = TgKycFormInputFilterDigitsOnly;
            keyboard = UIKeyboardTypeNumberPad;
        } else if ([code isEqualToString:@"email"]) {
            keyboard = UIKeyboardTypeEmailAddress;
        }
    }

    [self tg_configureWithTitle:item.large ?: @""
                    placeholder:placeholder
                           mode:isSelector ? TgKycFormCellModeSelector : TgKycFormCellModeInput
                         filter:filter
                       keyboard:keyboard];
    if (!isSelector) {
        [self tg_bindItemCode:code];
        if ([code isEqualToString:@"email"]) {
            self.tg_textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        }
    }
}

- (void)tg_applyPlaceholder:(NSString *)placeholder {
    self.tg_textField.attributedPlaceholder = [[NSAttributedString alloc]
        initWithString:placeholder ?: @""
            attributes:@{ NSForegroundColorAttributeName: [UIColor tg_toneFromHex:kTgKycPlaceholderHex] }];
}

#pragma mark - Limits

- (NSInteger)tg_maxLengthForItemCode:(NSString *)code {
    if ([code isEqualToString:@"child_count"]) return 3;
    if ([code isEqualToString:@"whatsapp"]) return 11;
    if ([code isEqualToString:@"ifsc"]) return 11;
    if ([code isEqualToString:@"account_no"] || [code isEqualToString:@"account_no_verify"]) return 18;
    if ([code isEqualToString:@"credit_card"]) return 32;
    if ([code isEqualToString:@"email"]) return 128;
    return NSIntegerMax;
}

#pragma mark - Actions

- (void)tg_textDidChange {
    if (self.tg_onTextChanged) {
        self.tg_onTextChanged(self.tg_textField.text ?: @"");
    }
}

- (void)tg_dismissKeyboardIfNeeded {
    UIView *root = self.window ?: self.superview ?: self;
    [root endEditing:YES];
}

- (void)tg_linkTapped {
    [self tg_dismissKeyboardIfNeeded];
    if (self.tg_onLinkTapped) self.tg_onLinkTapped();
}

- (void)tg_rowTapped {
    if (self.tg_mode == TgKycFormCellModeSelector && self.tg_onRowTapped) {
        [self tg_dismissKeyboardIfNeeded];
        self.tg_onRowTapped();
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *current = textField.text ?: @"";
    NSString *proposed = [current stringByReplacingCharactersInRange:range withString:string];

    NSString *code = self.tg_boundItemCode;
    if (code.length > 0) {
        NSInteger maxLen = [self tg_maxLengthForItemCode:code];
        if ((NSInteger)proposed.length > maxLen) return NO;
    }

    if (string.length == 0) return YES;

    switch (self.tg_filter) {
        case TgKycFormInputFilterNone:
            return YES;
        case TgKycFormInputFilterDigitsOnly: {
            NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
            if ([string rangeOfCharacterFromSet:nonDigits].location != NSNotFound) return NO;
            NSString *digits = [NSString tg_digitsOnlyFromMixed:proposed];
            if (![textField.text isEqualToString:digits]) {
                textField.text = digits;
                textField.textColor = [UIColor tg_toneFromHex:kTgKycTitleHex];
                if (self.tg_onTextChanged) self.tg_onTextChanged(digits);
            }
            return NO;
        }
        case TgKycFormInputFilterAlphanumericsUppercased: {
            NSCharacterSet *allowed = [NSCharacterSet alphanumericCharacterSet];
            for (NSUInteger i = 0; i < string.length; i++) {
                unichar ch = [string characterAtIndex:i];
                if (![allowed characterIsMember:ch]) return NO;
            }
            NSString *upper = [proposed uppercaseString];
            textField.text = upper;
            textField.textColor = [UIColor tg_toneFromHex:kTgKycTitleHex];
            if (self.tg_onTextChanged) self.tg_onTextChanged(upper);
            return NO;
        }
    }
}

@end
