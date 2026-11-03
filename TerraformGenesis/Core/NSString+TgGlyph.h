//

//

#import <Foundation/Foundation.h>

@interface NSString (TgGlyph)
+ (NSString *)tg_weaveIndianDigits:(NSString *)raw;

+ (NSString *)tg_digitsOnlyFromMixed:(NSString *)raw;

+ (BOOL)tg_passesDialPattern:(NSString *)digits;

+ (nullable NSString *)tg_wireReadyMobileFromLocalDigits:(NSString *)local;

+ (NSString *)tg_indianPhoneNormalizedFromMixed:(NSString *)raw;

+ (BOOL)tg_isValidIndianLocalPhone:(NSString *)normalized;
@end
