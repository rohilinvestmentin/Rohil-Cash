//
//  TgStampVault.m
//

#import "TgStampVault.h"
#import <AdSupport/AdSupport.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <CommonCrypto/CommonDigest.h>
#import <Security/Security.h>
#import <UIKit/UIKit.h>

static NSString * const kNullToken = @"null";
static NSLock *sKeychainLock;
static NSString *sIdfvKey;
static NSString *sSerialKey;

@implementation TgStampVault

+ (void)initialize {
    if (self != [TgStampVault class]) return;
    sKeychainLock = [[NSLock alloc] init];
    NSString *bid = [NSBundle mainBundle].bundleIdentifier ?: @"mesh";
    sIdfvKey = [NSString stringWithFormat:@"tg.vault.idfv.%@", bid];
    sSerialKey = [NSString stringWithFormat:@"tg.vault.serial.%@", bid];
}

+ (NSString *)vendorStamp {
    [sKeychainLock lock];
    NSString *cached = [self readVault:sIdfvKey];
    if (cached.length > 0 && ![cached isEqualToString:kNullToken]) {
        [sKeychainLock unlock];
        return cached;
    }
    NSString *raw = [[UIDevice currentDevice].identifierForVendor UUIDString];
    if (raw.length == 0) {
        [sKeychainLock unlock];
        return kNullToken;
    }
    [self writeVault:sIdfvKey value:raw];
    [sKeychainLock unlock];
    return raw;
}

+ (NSString *)promoStamp {
    if (ATTrackingManager.trackingAuthorizationStatus != ATTrackingManagerAuthorizationStatusAuthorized) {
        return kNullToken;
    }
    NSString *raw = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    return raw.length > 0 ? raw : kNullToken;
}

+ (NSString *)serialStamp {
    [sKeychainLock lock];
    NSString *cached = [self readVault:sSerialKey];
    if (cached.length > 0 && ![cached isEqualToString:kNullToken]) {
        [sKeychainLock unlock];
        return cached;
    }
    NSString *seed = [NSString stringWithFormat:@"%@_%lld", [[NSUUID UUID] UUIDString], (long long)[[NSDate date] timeIntervalSince1970]];
    NSString *md5 = [[self md5Upper:seed] copy];
    if (md5.length == 0) {
        [sKeychainLock unlock];
        return kNullToken;
    }
    [self writeVault:sSerialKey value:md5];
    [sKeychainLock unlock];
    return md5;
}

#pragma mark - Keychain

+ (void)writeVault:(NSString *)key value:(NSString *)value {
    if (key.length == 0 || value.length == 0 || [value isEqualToString:kNullToken]) return;
    NSMutableDictionary *query = [[self vaultQuery:key] mutableCopy];
    SecItemDelete((__bridge CFDictionaryRef)query);
    query[(__bridge id)kSecValueData] = [value dataUsingEncoding:NSUTF8StringEncoding];
    SecItemAdd((__bridge CFDictionaryRef)query, NULL);
}

+ (NSString *)readVault:(NSString *)key {
    if (key.length == 0) return nil;
    NSMutableDictionary *query = [[self vaultQuery:key] mutableCopy];
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    CFTypeRef item = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)query, &item) != errSecSuccess || !item) return nil;
    NSData *data = (__bridge_transfer NSData *)item;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (NSDictionary *)vaultQuery:(NSString *)key {
    return @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: key,
        (__bridge id)kSecAttrAccount: key,
        (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlock
    };
}

+ (NSString *)md5Upper:(NSString *)input {
    const char *c = input.UTF8String;
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(c, (CC_LONG)strlen(c), digest);
    NSMutableString *out = [NSMutableString stringWithCapacity:32];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [out appendFormat:@"%02X", digest[i]];
    }
    return out;
}

@end
