//
//  TgOrderStatusDisplay.m
//

#import "TgOrderStatusDisplay.h"
#import "TgPayloadModels.h"
#import "NSString+TgGlyph.h"
#import "UIColor+TgGlyph.h"

@implementation TgOrderStatusDisplay

+ (NSString *)tg_titleForOrderStatus:(NSInteger)orderStatus {
    switch (orderStatus) {
        case 10: return @"Unfinished Application";
        case 30: return @"Under review";
        case 31: return @"Reject";
        case 32: return @"Pending";
        case 36: return @"Change bank account";
        case 50: return @"Loan processing";
        case 60: return @"Repayment Due";
        case 61: return @"Overdue";
        case 70: return @"Pay off";
        case 99: return @"Cancel";
        default: return @"-";
    }
}

+ (UIColor *)tg_colorForOrderStatus:(NSInteger)orderStatus {
    switch (orderStatus) {
        case 10: return [UIColor tg_toneFromHex:@"#229B53"]; // Unfinished Application
        case 30: return [UIColor tg_toneFromHex:@"#A2A018"]; // Under review
        case 31: return [UIColor tg_toneFromHex:@"#C300FF"]; // Reject
        case 32: return [UIColor tg_toneFromHex:@"#4808EC"]; // Pending
        case 36: return [UIColor tg_toneFromHex:@"#9B2241"]; // Change bank account
        case 50: return [UIColor tg_toneFromHex:@"#97229B"]; // Loan processing
        case 60: return [UIColor tg_toneFromHex:@"#D01114"]; // Repayment Due
        case 61: return [UIColor tg_toneFromHex:@"#897000"]; // Overdue
        case 70: return [UIColor tg_toneFromHex:@"#1190D0"]; // Pay off
        case 99: return [UIColor tg_toneFromHex:@"#636363"]; // Cancel
        default: return [UIColor tg_toneFromHex:@"#364153"];
    }
}

+ (NSString *)tg_dateTitleForOrderStatus:(NSInteger)orderStatus {
    if (orderStatus == 60 || orderStatus == 61) {
        return @"Due date";
    }
    return @"Date of application";
}

+ (NSString *)tg_dateValueForItem:(TgOrderItem *)item {
    if (![item isKindOfClass:[TgOrderItem class]]) return @"-";
    NSInteger status = item.intellectual;
    NSString *raw = nil;
    if (status == 60 || status == 61) {
        raw = item.fierce;
    } else {
        raw = item.tailor;
    }
    return [self tg_displayOrDash:raw];
}

+ (NSString *)tg_formattedAmountFromLoanAmount:(NSInteger)loanAmount {
    NSString *digits = [NSString tg_weaveIndianDigits:[NSString stringWithFormat:@"%ld", (long)loanAmount]];
    return [NSString stringWithFormat:@"₹%@", digits];
}

+ (NSString *)tg_displayOrDash:(NSString *)text {
    NSString *trim = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trim.length > 0 ? trim : @"-";
}

@end
