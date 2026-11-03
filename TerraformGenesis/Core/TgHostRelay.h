//

//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TgHostRelay : NSObject

+ (instancetype)shared;

- (nullable NSString *)activeHost;
- (BOOL)hasActiveHost;
- (void)purgeHost;
- (void)bootWarmup:(void (^)(BOOL ok))completion;
- (void)refetchHost:(void (^)(BOOL ok))completion;
- (void)fetchHost:(void (^)(BOOL ok))completion;
- (void)probeHost:(NSString *)host completion:(void (^)(BOOL valid))completion;

@end

NS_ASSUME_NONNULL_END
