//
//  UIFont+TgGlyph.m
//

#import "UIFont+TgGlyph.h"

@implementation UIFont (TgGlyph)

+ (UIFont *)tg_meshGlyphWithSize:(CGFloat)size weight:(UIFontWeight)weight {
    NSArray<NSString *> *names;
    if (weight < UIFontWeightRegular) {
        names = @[@"Ubuntu-Light"];
    } else if (weight < UIFontWeightMedium) {
        names = @[@"Ubuntu-Regular", @"Ubuntu"];
    } else if (weight < UIFontWeightBold) {
        names = @[@"Ubuntu-Medium"];
    } else {
        names = @[@"Ubuntu-Bold"];
    }
    for (NSString *name in names) {
        UIFont *f = [UIFont fontWithName:name size:size];
        if (f) return f;
    }
    return [UIFont systemFontOfSize:size weight:weight];
}

@end
