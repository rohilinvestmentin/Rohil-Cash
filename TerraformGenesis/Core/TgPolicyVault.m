//
//  TgPolicyVault.m
//

#import "TgPolicyVault.h"
#import "TgWireConduit.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"

@interface TgPolicyVault ()
@property (nonatomic, strong, readwrite, nullable) TgSystemConfigModel *cachedManifest;
@end

@implementation TgPolicyVault

+ (instancetype)shared {
    static TgPolicyVault *vault;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ vault = [[TgPolicyVault alloc] init]; });
    return vault;
}

- (nullable TgSystemConfigModel *)currentManifest {
    return self.cachedManifest;
}

- (void)ensureManifestCachedSuccess:(TgPolicySuccessBlock)success failure:(TgPolicyFailureBlock)failure {
    if (self.cachedManifest) {
        if (success) success(self.cachedManifest);
        return;
    }
    [self pullManifestSuccess:success failure:failure];
}

- (void)refreshManifestOnHomeEntrySuccess:(TgPolicySuccessBlock)success failure:(TgPolicyFailureBlock)failure {
    [self pullManifestSuccess:success failure:failure];
}

- (void)pullManifestSuccess:(TgPolicySuccessBlock)success failure:(TgPolicyFailureBlock)failure {
    [[TgWireConduit shared] relayPOST:TgLaneAppConfig
                             signData:@{}
                           nonSignData:@{}
                              success:^(id data) {
        TgSystemConfigModel *model = [TgSystemConfigModel yy_modelWithJSON:data];
        if (!model) {
            if (failure) failure();
            return;
        }
        self.cachedManifest = model;
        if (success) success(model);
    } failure:^{
        if (failure) failure();
    }];
}

- (void)purgeCache {
    self.cachedManifest = nil;
}

@end
