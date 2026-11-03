//
//  TgPulseOverlay.h — 01 Toast / Loading
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TgPulseOverlay : NSObject
+ (instancetype)shared;
- (void)whisperLine:(nullable NSString *)message duration:(NSTimeInterval)duration;
- (void)whisperLine:(nullable NSString *)message;
- (void)veilSpin:(nullable NSString *)hint;
- (void)veilSpin;
- (void)veilDismiss;
@end

NS_ASSUME_NONNULL_END
