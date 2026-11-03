//
//  TgPersonaVault.m
//

#import "TgPersonaVault.h"
#import "TgParcelRegistry.h"
#import "TgStampVault.h"

@implementation TgPersonaVault

+ (instancetype)shared {
    static TgPersonaVault *vault;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ vault = [[TgPersonaVault alloc] init]; });
    return vault;
}

- (NSString *)holderId {
    return [[NSUserDefaults standardUserDefaults] stringForKey:TgCacheUid] ?: @"";
}

- (NSString *)holderToken {
    return [[NSUserDefaults standardUserDefaults] stringForKey:TgCacheToken] ?: @"";
}

- (NSString *)holderMobile {
    return [[NSUserDefaults standardUserDefaults] stringForKey:TgCacheMobile] ?: @"";
}

- (NSString *)holderSerial {
    return [TgStampVault serialStamp];
}

- (void)imprintUserId:(NSString *)userId token:(NSString *)token mobile:(NSString *)mobile {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:userId ?: @"" forKey:TgCacheUid];
    [defaults setObject:token ?: @"" forKey:TgCacheToken];
    NSString *trimmed = [mobile stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (trimmed.length > 0) {
        [defaults setObject:trimmed forKey:TgCacheMobile];
    } else {
        [defaults removeObjectForKey:TgCacheMobile];
    }
}

- (void)wipe {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:TgCacheUid];
    [defaults removeObjectForKey:TgCacheToken];
    [defaults removeObjectForKey:TgCacheMobile];
}

@end
