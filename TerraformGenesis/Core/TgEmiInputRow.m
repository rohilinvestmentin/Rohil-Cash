//
//  TgEmiInputRow.m
//

#import "TgEmiInputRow.h"
#import "NSString+TgGlyph.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>

static CGFloat const kTgEmiRowFieldHeight = 54.0;
static CGFloat const kTgEmiRowFieldRadius = 16.0;
static NSString * const kTgEmiRowTitleHex = @"#364153";
static NSString * const kTgEmiRowHintHex = @"#C51B12";
static NSString * const kTgEmiRowPlaceholderHex = @"#9CA3AF";

@interface TgEmiInputRow () <UITextFieldDelegate>
@property (nonatomic, strong) UILabel *tg_titleCaption;
@property (nonatomic, strong) UIView *tg_fieldVeil;
@property (nonatomic, strong, readwrite) UITextField *tg_textField;
@property (nonatomic, strong) UILabel *tg_hintCaption;
@property (nonatomic, assign) TgEmiInputRowFormat tg_format;
@end

@implementation TgEmiInputRow

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self tg_buildUI];
    return self;
}

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (void)tg_buildUI {
    self.tg_titleCaption = [[UILabel alloc] init];
    self.tg_titleCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightMedium];
    self.tg_titleCaption.textColor = [UIColor tg_toneFromHex:kTgEmiRowTitleHex];
    [self addSubview:self.tg_titleCaption];

    self.tg_fieldVeil = [[UIView alloc] init];
    self.tg_fieldVeil.backgroundColor = UIColor.whiteColor;
    self.tg_fieldVeil.layer.cornerRadius = kTgEmiRowFieldRadius;
    self.tg_fieldVeil.clipsToBounds = YES;
    [self addSubview:self.tg_fieldVeil];

    self.tg_textField = [[UITextField alloc] init];
    self.tg_textField.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    self.tg_textField.textColor = [UIColor tg_toneFromHex:kTgEmiRowTitleHex];
    self.tg_textField.borderStyle = UITextBorderStyleNone;
    self.tg_textField.keyboardType = UIKeyboardTypeNumberPad;
    self.tg_textField.delegate = self;
    [self.tg_textField addTarget:self action:@selector(tg_textDidChange) forControlEvents:UIControlEventEditingChanged];
    UIView *leftPad = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 10)];
    self.tg_textField.leftView = leftPad;
    self.tg_textField.leftViewMode = UITextFieldViewModeAlways;
    [self.tg_fieldVeil addSubview:self.tg_textField];

    self.tg_hintCaption = [[UILabel alloc] init];
    self.tg_hintCaption.font = [UIFont tg_meshGlyphWithSize:12 weight:UIFontWeightRegular];
    self.tg_hintCaption.textColor = [UIColor tg_toneFromHex:kTgEmiRowHintHex];
    self.tg_hintCaption.textAlignment = NSTextAlignmentRight;
    [self.tg_fieldVeil addSubview:self.tg_hintCaption];

    [self.tg_titleCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
    }];
    [self.tg_fieldVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_titleCaption.mas_bottom).offset(8);
        make.left.right.bottom.equalTo(self);
        make.height.mas_equalTo(kTgEmiRowFieldHeight);
    }];
    [self.tg_hintCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.tg_fieldVeil).offset(-12);
        make.centerY.equalTo(self.tg_fieldVeil);
        make.width.mas_lessThanOrEqualTo(120);
    }];
    [self.tg_textField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(self.tg_fieldVeil);
        make.right.equalTo(self.tg_hintCaption.mas_left).offset(-8);
    }];
}

- (void)tg_configureWithTitle:(NSString *)title
                  placeholder:(NSString *)placeholder
                         hint:(NSString *)hint
                       format:(TgEmiInputRowFormat)format
                     maxValue:(NSInteger)maxValue {
    self.tg_format = format;
    self.tg_maxValue = maxValue;
    self.tg_titleCaption.text = title;
    self.tg_hintCaption.text = hint;
    self.tg_textField.attributedPlaceholder = [[NSAttributedString alloc]
        initWithString:placeholder ?: @""
            attributes:@{ NSForegroundColorAttributeName: [UIColor tg_toneFromHex:kTgEmiRowPlaceholderHex] }];
}

- (long long)tg_parseRawDigits:(NSString *)raw {
    if (raw.length == 0) return 0;
    return strtoll(raw.UTF8String, NULL, 10);
}

- (BOOL)tg_wouldExceedMaxWithText:(NSString *)text range:(NSRange)range replacement:(NSString *)replacement {
    if (self.tg_maxValue <= 0) return NO;
    NSMutableString *next = [text mutableCopy] ?: [NSMutableString string];
    if (range.location <= next.length) {
        [next replaceCharactersInRange:range withString:replacement];
    }
    NSString *raw = [NSString tg_digitsOnlyFromMixed:next];
    if (raw.length == 0) return NO;
    return [self tg_parseRawDigits:raw] > (long long)self.tg_maxValue;
}

- (NSString *)tg_clampedRawDigits:(NSString *)raw {
    if (raw.length == 0 || self.tg_maxValue <= 0) return raw;
    long long value = [self tg_parseRawDigits:raw];
    if (value <= (long long)self.tg_maxValue) return raw;
    return [NSString stringWithFormat:@"%ld", (long)self.tg_maxValue];
}

- (void)tg_setRawDigitsText:(NSString *)digits {
    NSString *raw = [self tg_clampedRawDigits:[NSString tg_digitsOnlyFromMixed:digits ?: @""]];
    if (self.tg_format == TgEmiInputRowFormatIndianAmount) {
        self.tg_textField.text = raw.length > 0 ? [NSString tg_weaveIndianDigits:raw] : @"";
    } else {
        self.tg_textField.text = raw;
    }
}

- (NSString *)tg_rawDigitsText {
    return [NSString tg_digitsOnlyFromMixed:self.tg_textField.text ?: @""];
}

- (void)tg_textDidChange {
    NSString *raw = [self tg_clampedRawDigits:[NSString tg_digitsOnlyFromMixed:self.tg_textField.text ?: @""]];
    if (self.tg_format == TgEmiInputRowFormatIndianAmount) {
        NSString *formatted = raw.length > 0 ? [NSString tg_weaveIndianDigits:raw] : @"";
        if (![formatted isEqualToString:self.tg_textField.text]) {
            self.tg_textField.text = formatted;
        }
    } else if (![raw isEqualToString:self.tg_textField.text]) {
        self.tg_textField.text = raw;
    }
    if (self.tg_onTextChanged) self.tg_onTextChanged(raw);
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (string.length > 0) {
        NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];
        for (NSUInteger i = 0; i < string.length; i++) {
            if (![digits characterIsMember:[string characterAtIndex:i]]) return NO;
        }
    }
    if ([self tg_wouldExceedMaxWithText:textField.text ?: @"" range:range replacement:string]) {
        return NO;
    }
    return YES;
}

@end
