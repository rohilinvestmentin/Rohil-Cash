//
//  UIColor+TgGlyph.m
//

#import "UIColor+TgGlyph.h"

static NSString * const kAccentHex = @"#182040";

@implementation UIColor (TgGlyph)

+ (UIColor *)tg_toneFromHex:(NSString *)hex {
    NSString *cleaned = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    if ([cleaned hasPrefix:@"#"]) cleaned = [cleaned substringFromIndex:1];
    if (cleaned.length != 6) return UIColor.clearColor;
    unsigned int value = 0;
    [[NSScanner scannerWithString:cleaned] scanHexInt:&value];
    CGFloat r = ((value & 0xFF0000) >> 16) / 255.0;
    CGFloat g = ((value & 0x00FF00) >> 8) / 255.0;
    CGFloat b = (value & 0x0000FF) / 255.0;
    return [UIColor colorWithRed:r green:g blue:b alpha:1];
}

+ (UIColor *)tg_accentTone {
    return [self tg_toneFromHex:kAccentHex];
}

@end
