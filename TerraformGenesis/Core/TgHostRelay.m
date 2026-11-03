//
//  TgHostRelay.m

//

#import "TgHostRelay.h"
#import "TgPureLinks.h"

@implementation TgHostRelay

+ (instancetype)shared {
    static TgHostRelay *relay;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ relay = [[TgHostRelay alloc] init]; });
    return relay;
}

- (NSString *)activeHost {
    return [TgPureLinks apiBaseURL];
}

- (BOOL)hasActiveHost {
    return self.activeHost.length > 0;
}

- (void)purgeHost {

}

- (void)bootWarmup:(void (^)(BOOL))completion {
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{ completion(YES); });
    }
}

- (void)refetchHost:(void (^)(BOOL))completion {
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{ completion(YES); });
    }
}

- (void)fetchHost:(void (^)(BOOL))completion {
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{ completion(YES); });
    }
}

- (void)probeHost:(NSString *)host completion:(void (^)(BOOL))completion {
    (void)host;
    if (completion) completion(YES);
}

@end
