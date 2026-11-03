//

//

#import <Foundation/Foundation.h>

@class TgSystemConfigModel;

NS_ASSUME_NONNULL_BEGIN

typedef void (^TgPolicySuccessBlock)(TgSystemConfigModel *config);
typedef void (^TgPolicyFailureBlock)(void);

@interface TgPolicyVault : NSObject

+ (instancetype)shared;

@property (nonatomic, strong, readonly, nullable) TgSystemConfigModel *cachedManifest;

- (nullable TgSystemConfigModel *)currentManifest;

- (void)ensureManifestCachedSuccess:(nullable TgPolicySuccessBlock)success
                           failure:(nullable TgPolicyFailureBlock)failure;

- (void)refreshManifestOnHomeEntrySuccess:(nullable TgPolicySuccessBlock)success
                                 failure:(nullable TgPolicyFailureBlock)failure;

- (void)pullManifestSuccess:(nullable TgPolicySuccessBlock)success
                    failure:(nullable TgPolicyFailureBlock)failure;

- (void)purgeCache;

@end

NS_ASSUME_NONNULL_END
