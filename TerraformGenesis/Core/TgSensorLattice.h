//

//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TgSensorLattice : NSObject
+ (NSDictionary<NSString *, id> *)harvestPayload;
+ (NSString *)weaveAgentString;

+ (void)primeWifiGlyphsWithCompletion:(void (^)(void))completion;
@end

NS_ASSUME_NONNULL_END
