//
//  TgVersionPayload.m
//

#import "TgVersionPayload.h"

@implementation TgVersionData
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"noticeable": @"latestVersion",
        @"contrast": @"latestVersionUrl",
        @"headache": @"latestVersionContent",
    };
}
@end

@implementation TgVersionResponse
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{@"versionData": @"data"};
}
@end
