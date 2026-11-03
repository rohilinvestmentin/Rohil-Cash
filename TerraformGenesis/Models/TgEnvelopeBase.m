//
//  TgEnvelopeBase.m
//

#import "TgEnvelopeBase.h"

@implementation TgEnvelopeBase

+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"cheer": @"resultCode",
        @"power": @"resultMsg",
        @"trick": @"data",
        @"radiation": @"timestamp",
    };
}

- (BOOL)isSuccess {
    return self.cheer == 200;
}

@end
