//
//  TgPersonaVault.h
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TgPersonaVault : NSObject
+ (instancetype)shared;
@property (nonatomic, copy, readonly) NSString *holderId;
@property (nonatomic, copy, readonly) NSString *holderToken;
@property (nonatomic, copy, readonly) NSString *holderMobile;
@property (nonatomic, copy, readonly) NSString *holderSerial;
- (void)imprintUserId:(NSString *)userId token:(NSString *)token mobile:(nullable NSString *)mobile;
- (void)wipe;
@end

NS_ASSUME_NONNULL_END
