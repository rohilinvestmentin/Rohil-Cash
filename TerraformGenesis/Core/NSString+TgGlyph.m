//
//  NSString+TgGlyph.m
//

#import "NSString+TgGlyph.h"

@implementation NSString (TgGlyph)

static NSRegularExpression *TgDialPatternExpr(void) {
    static NSRegularExpression *expr;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        expr = [NSRegularExpression regularExpressionWithPattern:@"^(91[6-9]\\d{9}|910[6-9]\\d{9}|[6-9]\\d{9}|0[6-9]\\d{9})$"
                                                         options:0
                                                           error:nil];
    });
    return expr;
}

+ (NSString *)tg_digitsOnlyFromMixed:(NSString *)raw {
    if (raw.length == 0) return @"";
    NSMutableString *out = [NSMutableString string];
    NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];
    for (NSUInteger i = 0; i < raw.length; i++) {
        unichar c = [raw characterAtIndex:i];
        if ([digits characterIsMember:c]) {
            [out appendFormat:@"%C", c];
        }
    }
    return out;
}

+ (BOOL)tg_passesDialPattern:(NSString *)digits {
    NSString *trimmed = [digits stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) return NO;
    NSRange range = NSMakeRange(0, trimmed.length);
    return [TgDialPatternExpr() firstMatchInString:trimmed options:0 range:range] != nil;
}

+ (NSString *)tg_wireReadyMobileFromLocalDigits:(NSString *)local {
    NSString *d = [self tg_digitsOnlyFromMixed:local];
    if (d.length == 0) return nil;

    NSMutableArray<NSString *> *candidates = [NSMutableArray array];
    if ([d hasPrefix:@"0"] && d.length == 11) {
        NSString *body = [d substringFromIndex:1];
        [candidates addObject:d];
        [candidates addObject:[@"91" stringByAppendingString:body]];
        [candidates addObject:body];
    } else if (d.length == 10) {
        [candidates addObject:[@"91" stringByAppendingString:d]];
        [candidates addObject:d];
    } else if ([d hasPrefix:@"91"]) {
        [candidates addObject:d];
    } else {
        [candidates addObject:[@"91" stringByAppendingString:d]];
        [candidates addObject:d];
    }

    for (NSString *c in candidates) {
        if (![self tg_passesDialPattern:c]) continue;
        if ([c hasPrefix:@"91"] && c.length >= 12) return c;
        if (c.length == 10 && [c characterAtIndex:0] >= '6' && [c characterAtIndex:0] <= '9') {
            return [@"91" stringByAppendingString:c];
        }
        if ([c hasPrefix:@"0"] && c.length == 11) {
            return [@"91" stringByAppendingString:[c substringFromIndex:1]];
        }
        return c;
    }
    return nil;
}

+ (NSString *)tg_weaveIndianDigits:(NSString *)raw {
    NSString *trimmed = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) return raw;

    BOOL negative = [trimmed hasPrefix:@"-"];
    NSString *body = negative ? [trimmed substringFromIndex:1] : trimmed;
    NSArray *parts = [body componentsSeparatedByString:@"."];
    NSString *intPart = parts.firstObject ?: @"";
    NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];
    for (NSUInteger i = 0; i < intPart.length; i++) {
        if (![digits characterIsMember:[intPart characterAtIndex:i]]) return raw;
    }

    NSString *frac = parts.count > 1 ? parts[1] : nil;
    NSString *grouped = [self tg_weaveIntegerClusters:intPart];
    NSString *mid = frac ? [NSString stringWithFormat:@"%@.%@", grouped, frac] : grouped;
    return negative ? [NSString stringWithFormat:@"-%@", mid] : mid;
}

+ (NSString *)tg_indianPhoneNormalizedFromMixed:(NSString *)raw {
    NSString *cleaned = [self tg_digitsOnlyFromMixed:raw];
    if (cleaned.length == 0) return @"";
    if ([cleaned hasPrefix:@"910"] && cleaned.length == 13) {
        cleaned = [cleaned substringFromIndex:3];
    } else if ([cleaned hasPrefix:@"91"] && cleaned.length == 12) {
        cleaned = [cleaned substringFromIndex:2];
    }
    if ([cleaned hasPrefix:@"0"] && cleaned.length == 11) {
        cleaned = [cleaned substringFromIndex:1];
    }
    return cleaned;
}

+ (BOOL)tg_isValidIndianLocalPhone:(NSString *)normalized {
    NSString *clean = [self tg_indianPhoneNormalizedFromMixed:normalized];
    if (clean.length != 10) return NO;
    unichar first = [clean characterAtIndex:0];
    return first >= '6' && first <= '9';
}

+ (NSString *)tg_weaveIntegerClusters:(NSString *)intPart {
    if (intPart.length <= 3) return intPart;
    NSMutableArray<NSString *> *chunks = [NSMutableArray array];
    NSMutableString *chars = [intPart mutableCopy];
    NSString *tail = [chars substringFromIndex:chars.length - 3];
    [chars deleteCharactersInRange:NSMakeRange(chars.length - 3, 3)];
    [chunks addObject:tail];
    while (chars.length > 0) {
        NSUInteger take = MIN(2, chars.length);
        NSUInteger start = chars.length - take;
        [chunks addObject:[chars substringWithRange:NSMakeRange(start, take)]];
        [chars deleteCharactersInRange:NSMakeRange(start, take)];
    }
    NSArray *rev = [[chunks reverseObjectEnumerator] allObjects];
    return [rev componentsJoinedByString:@","];
}

@end
