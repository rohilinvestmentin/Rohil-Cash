//
//  TgSensorLattice.m
//

#import "TgSensorLattice.h"
#import "TgParcelRegistry.h"
#import "TgStampVault.h"
#import <CFNetwork/CFNetwork.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <NetworkExtension/NetworkExtension.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <mach/mach.h>
#import <sys/sysctl.h>
#import <sys/utsname.h>
#import <netinet/in.h>
#import <UIKit/UIKit.h>

static NSString * const kNullToken = @"null";
static NSDictionary *sWifiGlyphCache;

@implementation TgSensorLattice

+ (void)primeWifiGlyphsWithCompletion:(void (^)(void))completion {
    CLAuthorizationStatus loc = [CLLocationManager authorizationStatus];
    BOOL locOK = (loc == kCLAuthorizationStatusAuthorizedWhenInUse ||
                  loc == kCLAuthorizationStatusAuthorizedAlways);
    if (!locOK) {
        if (completion) completion();
        return;
    }

    if (@available(iOS 14.0, *)) {
        [NEHotspotNetwork fetchCurrentWithCompletionHandler:^(NEHotspotNetwork * _Nullable network) {
            NSDictionary *wifi = @{};
            if (network.SSID.length > 0 || network.BSSID.length > 0) {
                wifi = @{
                    @"ssid": network.SSID ?: @"",
                    @"bssid": network.BSSID ?: @"",
                };
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (wifi.count > 0) {
                    sWifiGlyphCache = wifi;
                }
                if (completion) completion();
            });
        }];
        return;
    }

    if (completion) completion();
}

+ (NSDictionary<NSString *, id> *)harvestPayload {
    NSString *serial = [TgStampVault serialStamp];
    NSMutableDictionary *bag = [NSMutableDictionary dictionary];
    bag[@"versionCode"] = [self pack:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    bag[@"idfv"] = [self pack:[TgStampVault vendorStamp]];
    bag[@"uuid"] = [self pack:serial];
    bag[@"ramTotal"] = [NSString stringWithFormat:@"%.6f", [self totalRamGB]];
    bag[@"ramCanUse"] = [NSString stringWithFormat:@"%.6f", [self freeRamGB]];
    bag[@"cashTotal"] = [NSString stringWithFormat:@"%.6f", [self totalDiskGB]];
    bag[@"cashCanUse"] = [NSString stringWithFormat:@"%.6f", [self freeDiskGB]];
    bag[@"totalBootTimeWake"] = [NSString stringWithFormat:@"%lld", [self wakeUptimeMS]];
    bag[@"totalBootTime"] = [NSString stringWithFormat:@"%lld", [self fullUptimeMS]];
    bag[@"batteryLevel"] = [NSString stringWithFormat:@"%d", [self batteryPercent]];
    bag[@"idfa"] = [self pack:[TgStampVault promoStamp]];
    bag[@"defaultTimeZone"] = [self pack:[NSTimeZone localTimeZone].name];
    bag[@"debugged"] = [self boolGlyph:[self isDebuggerAttached]];
    bag[@"simulated"] = [self boolGlyph:[self isSimulator]];
    bag[@"charged"] = [self boolGlyph:[self isCharging]];
    bag[@"rooted"] = [self boolGlyph:[self isJailbroken]];
    bag[@"proxied"] = [self boolGlyph:[self isProxyEnabled]];
    bag[@"isvpn"] = [self boolGlyph:[self isVPNActive]];
    bag[@"screenResolution"] = [self pack:[self screenResolutionGlyph]];
    bag[@"screenWidth"] = [NSString stringWithFormat:@"%d", (int)UIScreen.mainScreen.bounds.size.width];
    bag[@"screenHeight"] = [NSString stringWithFormat:@"%d", (int)UIScreen.mainScreen.bounds.size.height];
    bag[@"systemVersions"] = [self pack:UIDevice.currentDevice.systemVersion];
    NSDictionary *wifi = [self wifiGlyphs];
    bag[@"wifiBssid"] = wifi[@"bssid"] ?: @"";
    bag[@"wifiName"] = wifi[@"ssid"] ?: @"";
    bag[@"network"] = [self networkGlyph];
    bag[@"defaultLanguage"] = [self pack:[self primaryLanguage]];
    bag[@"phoneType"] = [self pack:[self marketingNameFor:[self machineGlyph]]];
    bag[@"cpuNum"] = [NSString stringWithFormat:@"%lu", (unsigned long)NSProcessInfo.processInfo.processorCount];
    bag[@"screenBrightness"] = [NSString stringWithFormat:@"%d", (int)(UIScreen.mainScreen.brightness * 100)];
    bag[@"lastBootTime"] = [NSString stringWithFormat:@"%lld", [self bootEpochMS]];
    bag[@"phoneMark"] = [self pack:UIDevice.currentDevice.name];
    return [self normalizePayload:bag];
}

+ (NSString *)weaveAgentString {
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    version = [[version stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] copy];
    if (version.length == 0) version = @"1.0.0";
    NSString *machine = [self machineGlyph];
    NSString *model = [self marketingNameFor:machine];
    NSString *modelSegment = [model isEqualToString:machine] ? machine : model;
    NSString *os = [UIDevice.currentDevice.systemVersion stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *osSegment = os.length > 0 ? [NSString stringWithFormat:@"iOS %@", os] : @"iOS";
    // Trailing ";" before ")" required by backend UA convention.
    return [NSString stringWithFormat:@"%@/%@ (Apple; %@; %@; %@;)", TgParcelClientAppId, version, [self agentDeviceKind], modelSegment, osSegment];
}

#pragma mark - Machine map

+ (NSString *)marketingNameFor:(NSString *)identifier {
    static NSDictionary *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
            @"i386": @"iPhone Simulator", @"x86_64": @"iPhone Simulator", @"arm64": @"iPhone Simulator",
            @"iPhone1,1": @"iPhone", @"iPhone1,2": @"iPhone 3G", @"iPhone2,1": @"iPhone 3GS",
            @"iPhone3,1": @"iPhone 4", @"iPhone4,1": @"iPhone 4S",
            @"iPhone5,1": @"iPhone 5", @"iPhone5,2": @"iPhone 5", @"iPhone5,3": @"iPhone 5c", @"iPhone5,4": @"iPhone 5c",
            @"iPhone6,1": @"iPhone 5s", @"iPhone6,2": @"iPhone 5s",
            @"iPhone7,1": @"iPhone 6 Plus", @"iPhone7,2": @"iPhone 6",
            @"iPhone8,1": @"iPhone 6s", @"iPhone8,2": @"iPhone 6s Plus", @"iPhone8,4": @"iPhone SE",
            @"iPhone9,1": @"iPhone 7", @"iPhone9,3": @"iPhone 7", @"iPhone9,2": @"iPhone 7 Plus", @"iPhone9,4": @"iPhone 7 Plus",
            @"iPhone10,1": @"iPhone 8", @"iPhone10,4": @"iPhone 8", @"iPhone10,2": @"iPhone 8 Plus", @"iPhone10,5": @"iPhone 8 Plus",
            @"iPhone10,3": @"iPhone X", @"iPhone10,6": @"iPhone X",
            @"iPhone11,8": @"iPhone XR", @"iPhone11,2": @"iPhone XS", @"iPhone11,6": @"iPhone XS Max",
            @"iPhone12,1": @"iPhone 11", @"iPhone12,3": @"iPhone 11 Pro", @"iPhone12,5": @"iPhone 11 Pro Max", @"iPhone12,8": @"iPhone SE 2",
            @"iPhone13,1": @"iPhone 12 mini", @"iPhone13,2": @"iPhone 12", @"iPhone13,3": @"iPhone 12 Pro", @"iPhone13,4": @"iPhone 12 Pro Max",
            @"iPhone14,4": @"iPhone 13 mini", @"iPhone14,5": @"iPhone 13", @"iPhone14,2": @"iPhone 13 Pro", @"iPhone14,3": @"iPhone 13 Pro Max",
            @"iPhone14,6": @"iPhone SE 3", @"iPhone14,7": @"iPhone 14", @"iPhone14,8": @"iPhone 14 Plus",
            @"iPhone15,2": @"iPhone 14 Pro", @"iPhone15,3": @"iPhone 14 Pro Max",
            @"iPhone15,4": @"iPhone 15", @"iPhone15,5": @"iPhone 15 Plus",
            @"iPhone16,1": @"iPhone 15 Pro", @"iPhone16,2": @"iPhone 15 Pro Max",
            @"iPhone17,1": @"iPhone 16 Pro", @"iPhone17,2": @"iPhone 16 Pro Max",
            @"iPhone17,3": @"iPhone 16", @"iPhone17,4": @"iPhone 16 Plus", @"iPhone17,5": @"iPhone 16e",
            @"iPhone18,1": @"iPhone 17 Pro", @"iPhone18,2": @"iPhone 17 Pro Max",
            @"iPhone18,3": @"iPhone 17", @"iPhone18,4": @"iPhone 17 Air", @"iPhone18,5": @"iPhone 17e"
        };
    });
    return map[identifier] ?: identifier;
}

#pragma mark - Helpers

+ (NSDictionary *)normalizePayload:(NSDictionary *)raw {
    NSMutableDictionary *out = [NSMutableDictionary dictionary];
    [raw enumerateKeysAndObjectsUsingBlock:^(NSString *k, id v, BOOL *stop) {
        if ([v isKindOfClass:[NSString class]]) {
            NSString *t = [v stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            out[k] = t.length > 0 ? t : kNullToken;
        } else {
            out[k] = v;
        }
    }];
    return out;
}

+ (NSString *)pack:(NSString *)value {
    NSString *raw = value.length > 0 ? value : @"";
    NSString *t = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return t.length > 0 ? t : kNullToken;
}

+ (NSString *)boolGlyph:(BOOL)flag {
    return flag ? @"true" : @"false";
}

+ (NSString *)machineGlyph {
    struct utsname sys;
    uname(&sys);
    return [NSString stringWithCString:sys.machine encoding:NSUTF8StringEncoding];
}

+ (NSString *)agentDeviceKind {
    return UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad ? @"Tablet" : @"Mobile";
}

+ (double)totalRamGB {
    return NSProcessInfo.processInfo.physicalMemory / 1073741824.0;
}

+ (double)freeRamGB {
    vm_statistics64_data_t stats;
    mach_msg_type_number_t count = HOST_VM_INFO64_COUNT;
    if (host_statistics64(mach_host_self(), HOST_VM_INFO64, (host_info64_t)&stats, &count) != KERN_SUCCESS) return -1;
    return (double)stats.free_count * vm_kernel_page_size / 1073741824.0;
}

+ (double)totalDiskGB {
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    return [attrs[NSFileSystemSize] doubleValue] / 1073741824.0;
}

+ (double)freeDiskGB {
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    return [attrs[NSFileSystemFreeSize] doubleValue] / 1073741824.0;
}

+ (long long)wakeUptimeMS {
    return (long long)(NSProcessInfo.processInfo.systemUptime * 1000);
}

+ (long long)fullUptimeMS {
    struct timeval boot;
    size_t size = sizeof(boot);
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    if (sysctl(mib, 2, &boot, &size, NULL, 0) != 0 || boot.tv_sec <= 0) return -1;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval bootAt = boot.tv_sec + boot.tv_usec / 1000000.0;
    return (long long)((now - bootAt) * 1000);
}

+ (long long)bootEpochMS {
    long long ms = [self fullUptimeMS];
    if (ms < 0) return -1;
    return (long long)([[NSDate date] timeIntervalSince1970] * 1000) - ms;
}

+ (int)batteryPercent {
    UIDevice.currentDevice.batteryMonitoringEnabled = YES;
    float level = UIDevice.currentDevice.batteryLevel;
    return level < 0 ? -1 : (int)(level * 100);
}

+ (BOOL)isSimulator {
#if TARGET_OS_SIMULATOR
    return YES;
#else
    return NO;
#endif
}

+ (BOOL)isDebuggerAttached {
    struct kinfo_proc info;
    size_t size = sizeof(info);
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()};
    if (sysctl(mib, 4, &info, &size, NULL, 0) != 0) return NO;
    return (info.kp_proc.p_flag & P_TRACED) != 0;
}

+ (BOOL)isCharging {
    UIDevice.currentDevice.batteryMonitoringEnabled = YES;
    UIDeviceBatteryState s = UIDevice.currentDevice.batteryState;
    return s == UIDeviceBatteryStateCharging || s == UIDeviceBatteryStateFull;
}

+ (BOOL)isJailbroken {
#if TARGET_OS_SIMULATOR
    return NO;
#else
    NSArray *paths = @[
        @"/Applications/Cydia.app", @"/Library/MobileSubstrate/MobileSubstrate.dylib",
        @"/bin/bash", @"/usr/sbin/sshd", @"/etc/apt", @"/private/var/lib/apt/"
    ];
    for (NSString *p in paths) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:p]) return YES;
    }
    return NO;
#endif
}

+ (BOOL)isProxyEnabled {
    NSDictionary *settings = (__bridge_transfer NSDictionary *)CFNetworkCopySystemProxySettings();
    NSURL *url = [NSURL URLWithString:@"https://www.apple.com"];
    NSArray *proxies = (__bridge_transfer NSArray *)CFNetworkCopyProxiesForURL((__bridge CFURLRef)url, (__bridge CFDictionaryRef)settings);
    NSDictionary *first = proxies.firstObject;
    NSString *type = first[(NSString *)kCFProxyTypeKey];
    return type.length > 0 && ![type isEqualToString:(NSString *)kCFProxyTypeNone];
}

+ (BOOL)isVPNActive {
    NSDictionary *settings = (__bridge_transfer NSDictionary *)CFNetworkCopySystemProxySettings();
    NSDictionary *scoped = settings[@"__SCOPED__"];
    if (![scoped isKindOfClass:[NSDictionary class]]) return NO;
    for (NSString *key in scoped) {
        if ([key containsString:@"tap"] || [key containsString:@"tun"] || [key containsString:@"ipsec"] || [key containsString:@"ppp"]) {
            return YES;
        }
    }
    return NO;
}

+ (NSString *)screenResolutionGlyph {
    CGRect b = UIScreen.mainScreen.bounds;
    CGFloat scale = UIScreen.mainScreen.scale;
    return [NSString stringWithFormat:@"%d-%d", (int)(b.size.width * scale), (int)(b.size.height * scale)];
}

+ (NSString *)primaryLanguage {
    NSString *raw = NSLocale.preferredLanguages.firstObject ?: @"en";
    return [[raw componentsSeparatedByString:@"-"].firstObject copy] ?: @"en";
}

+ (NSString *)networkGlyph {
    struct sockaddr_in addr;
    bzero(&addr, sizeof(addr));
    addr.sin_len = sizeof(addr);
    addr.sin_family = AF_INET;
    SCNetworkReachabilityRef reach = SCNetworkReachabilityCreateWithAddress(NULL, (const struct sockaddr *)&addr);
    if (!reach) return @"-99";
    SCNetworkReachabilityFlags flags;
    if (!SCNetworkReachabilityGetFlags(reach, &flags)) {
        CFRelease(reach);
        return @"-99";
    }
    CFRelease(reach);
    if (!(flags & kSCNetworkReachabilityFlagsReachable) || (flags & kSCNetworkReachabilityFlagsConnectionRequired)) return @"-99";
    if (flags & kSCNetworkReachabilityFlagsIsWWAN) return [self cellularGlyph];
    return @"1";
}

+ (NSString *)cellularGlyph {
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    NSString *radio = info.serviceCurrentRadioAccessTechnology.allValues.firstObject;
    if (!radio) return @"-99";
    if ([radio isEqualToString:CTRadioAccessTechnologyNR] || [radio isEqualToString:CTRadioAccessTechnologyNRNSA]) {
        return @"5";
    }
    if ([radio isEqualToString:CTRadioAccessTechnologyLTE]) return @"4";
    if ([radio isEqualToString:CTRadioAccessTechnologyWCDMA] ||
        [radio isEqualToString:CTRadioAccessTechnologyHSDPA] ||
        [radio isEqualToString:CTRadioAccessTechnologyHSUPA] ||
        [radio isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0] ||
        [radio isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA] ||
        [radio isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB] ||
        [radio isEqualToString:CTRadioAccessTechnologyeHRPD]) return @"3";
    if ([radio isEqualToString:CTRadioAccessTechnologyEdge] ||
        [radio isEqualToString:CTRadioAccessTechnologyGPRS] ||
        [radio isEqualToString:CTRadioAccessTechnologyCDMA1x]) return @"2";
    return @"0";
}

+ (NSDictionary *)wifiGlyphs {
    if (sWifiGlyphCache.count > 0) return sWifiGlyphCache;
    return @{};
}

@end
