//
//  TgWireConduit.m
//

#import "TgWireConduit.h"
#import "TgParcelRegistry.h"
#import "TgHostRelay.h"
#import "TgEnvelopeBase.h"
#import "TgVersionPayload.h"
#import "TgPulseOverlay.h"
#import "TgShardFacade.h"
#import "TgPersonaVault.h"
#import "TgStampVault.h"
#import "TgSensorLattice.h"
#import "UIFont+TgGlyph.h"
#import "UIColor+TgGlyph.h"
#import "SceneDelegate.h"
#import <CommonCrypto/CommonDigest.h>
#import <Masonry/Masonry.h>
#import <UIKit/UIKit.h>

static NSString * const kBusyToast = @"the system is occupied. Please retry after 2 minutes.";

#if DEBUG

static const NSUInteger kTgWireLogChunk = 2800;

static void TgWireConduitLogRaw(NSString *msg) {
    if (msg.length == 0) {
        NSLog(@"[TgWireConduit] (empty)");
        return;
    }
    if (msg.length <= kTgWireLogChunk) {
        NSLog(@"[TgWireConduit] %@", msg);
        return;
    }
    NSUInteger total = (msg.length + kTgWireLogChunk - 1) / kTgWireLogChunk;
    for (NSUInteger i = 0; i < total; i++) {
        NSUInteger loc = i * kTgWireLogChunk;
        NSUInteger len = MIN(kTgWireLogChunk, msg.length - loc);
        NSString *part = [msg substringWithRange:NSMakeRange(loc, len)];
        NSLog(@"[TgWireConduit] part %lu/%lu %@", (unsigned long)(i + 1), (unsigned long)total, part);
    }
}

static void TgWireConduitLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    TgWireConduitLogRaw(msg);
}

static NSString *TgWireJSONString(id obj) {
    if (!obj) return @"(null)";
    if (![NSJSONSerialization isValidJSONObject:obj]) return [NSString stringWithFormat:@"%@", obj];
    NSData *data = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:nil];
    if (!data) return @"(json error)";
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"(utf8 error)";
}

static NSString *TgWireBodyString(NSData *data) {
    if (!data) return @"(null)";
    NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (s) return s;
    return [NSString stringWithFormat:@"(non-utf8 body, %lu bytes)", (unsigned long)data.length];
}

static NSString *TgWireErrorKind(NSError *err) {
    if (!err) return @"unknown";
    if ([err.domain isEqualToString:NSURLErrorDomain]) {
        switch (err.code) {
            case NSURLErrorTimedOut: return @"timeout";
            case NSURLErrorNotConnectedToInternet:
            case NSURLErrorNetworkConnectionLost:
            case NSURLErrorDataNotAllowed: return @"no network";
            case NSURLErrorCannotFindHost:
            case NSURLErrorDNSLookupFailed: return @"DNS";
            case NSURLErrorCannotConnectToHost: return @"cannot connect";
            case NSURLErrorSecureConnectionFailed:
            case NSURLErrorServerCertificateHasBadDate:
            case NSURLErrorServerCertificateUntrusted:
            case NSURLErrorServerCertificateHasUnknownRoot:
            case NSURLErrorServerCertificateNotYetValid:
            case NSURLErrorClientCertificateRejected:
            case NSURLErrorClientCertificateRequired: return @"TLS/SSL";
            default: break;
        }
    }
    return [NSString stringWithFormat:@"%@(%ld)", err.domain, (long)err.code];
}
#endif

@interface TgWireConduit ()
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, assign) BOOL forceUpdateFlowActive;
@property (nonatomic, assign) BOOL forceUpdateVisible;
@property (nonatomic, assign) BOOL forceVersionFetching;
@property (nonatomic, copy, nullable) NSString *forceUpdatePanelToken;
/// Snapshot at cold boot before EverLaunched is written.
/// Suppress busy toast until the first successful network response (wireless-data not granted yet).
@property (nonatomic, assign) BOOL coldStartFirstInstall;
@end

@implementation TgWireConduit

+ (instancetype)shared {
    static TgWireConduit *conduit;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ conduit = [[TgWireConduit alloc] init]; });
    return conduit;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
        cfg.timeoutIntervalForRequest = 30;
        cfg.timeoutIntervalForResource = 60;
        _session = [NSURLSession sessionWithConfiguration:cfg];
    }
    return self;
}

+ (void)bootNetworkLayer:(void (^)(BOOL))completion {
    TgWireConduit *conduit = [self shared];
    // Capture before SceneDelegate writes TgMarkEverLaunched.
    conduit.coldStartFirstInstall = ![NSUserDefaults.standardUserDefaults boolForKey:TgMarkEverLaunched];
    [[TgHostRelay shared] bootWarmup:completion];
}

- (void)relayPOST:(NSString *)path
         signData:(NSDictionary *)signData
       nonSignData:(NSDictionary *)nonSignData
           success:(TgWireSuccessBlock)success
           failure:(TgWireFailureBlock)failure {
    [self tg_relayPOST:path signData:signData nonSignData:nonSignData dataSuccess:success envelopeSuccess:nil failure:failure];
}

- (void)relayPOST:(NSString *)path
         signData:(NSDictionary *)signData
       nonSignData:(NSDictionary *)nonSignData
  envelopeSuccess:(TgWireEnvelopeSuccessBlock)envelopeSuccess
          failure:(TgWireFailureBlock)failure {
    [self tg_relayPOST:path signData:signData nonSignData:nonSignData dataSuccess:nil envelopeSuccess:envelopeSuccess failure:failure];
}

- (void)tg_relayPOST:(NSString *)path
            signData:(NSDictionary *)signData
          nonSignData:(NSDictionary *)nonSignData
         dataSuccess:(TgWireSuccessBlock)dataSuccess
     envelopeSuccess:(TgWireEnvelopeSuccessBlock)envelopeSuccess
             failure:(TgWireFailureBlock)failure {
    [self tg_relayPOST:path
              signData:signData
            nonSignData:nonSignData
           dataSuccess:dataSuccess
       envelopeSuccess:envelopeSuccess
               failure:failure
  hostFailoverAttempted:NO];
}

- (void)tg_relayPOST:(NSString *)path
            signData:(NSDictionary *)signData
          nonSignData:(NSDictionary *)nonSignData
         dataSuccess:(TgWireSuccessBlock)dataSuccess
     envelopeSuccess:(TgWireEnvelopeSuccessBlock)envelopeSuccess
             failure:(TgWireFailureBlock)failure
hostFailoverAttempted:(BOOL)hostFailoverAttempted {
    [self ensureHost:^(NSString *host) {
        if (!host) {
            [self notifyFailure:failure];
            return;
        }
        NSString *urlStr = [path hasPrefix:@"http"] ? path : [host stringByAppendingString:path];
        NSDictionary *payload = [self buildPayloadWithSignData:signData ?: @{} nonSignData:nonSignData ?: @{}];
        NSData *body = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
        NSString *userAgent = [TgSensorLattice weaveAgentString];
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
        req.HTTPMethod = @"POST";
        req.HTTPBody = body;
        req.timeoutInterval = 30;
        [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [req setValue:userAgent forHTTPHeaderField:@"User-Agent"];

#if DEBUG
        TgWireConduitLog(@"──── POST request ────\nurl: %@\nmethod: POST\nUser-Agent: %@\npath: %@\nsignData: %@\nnonSignData: %@\nrequestBodyJSON: %@\nbodyBytes: %lu\nhostFailoverAttempted: %@",
                         urlStr, userAgent ?: @"(null)", path,
                         TgWireJSONString(signData), TgWireJSONString(nonSignData),
                         TgWireJSONString(payload), (unsigned long)body.length,
                         hostFailoverAttempted ? @"YES" : @"NO");
#endif

        [[self.session dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *resp, NSError *err) {
            if ([self tg_shouldFailoverForError:err response:resp] && !hostFailoverAttempted) {
#if DEBUG
                NSInteger st = [resp isKindOfClass:[NSHTTPURLResponse class]] ? [(NSHTTPURLResponse *)resp statusCode] : 0;
                TgWireConduitLog(@"domain failover triggered\noldBaseURL: %@\npath: %@\nurl: %@\nhttpStatus: %ld\nerrorKind: %@\nerror: %@\nwillRetryOnce: YES",
                                 host, path, urlStr, (long)st,
                                 err ? TgWireErrorKind(err) : @"http status",
                                 err.localizedDescription ?: @"(nil)");
#endif
                [self tg_refetchHostThenRetry:^{
                    [self tg_relayPOST:path
                              signData:signData
                            nonSignData:nonSignData
                           dataSuccess:dataSuccess
                       envelopeSuccess:envelopeSuccess
                               failure:failure
                  hostFailoverAttempted:YES];
                } failure:failure];
                return;
            }
            if (err) {
#if DEBUG
                TgWireConduitLog(@"POST fail\nurl: %@\npath: %@\nerrorKind: %@\nerror: %@\ndomain: %@\ncode: %ld",
                                 urlStr, path, TgWireErrorKind(err), err.localizedDescription,
                                 err.domain, (long)err.code);
#endif
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (![self tg_shouldSuppressBusyToastForPath:path error:err]) {
                        [[TgPulseOverlay shared] whisperLine:kBusyToast duration:2.0];
                    }
                    if (failure) failure();
                });
                return;
            }
            [self tg_markNetworkUsableAfterSuccess];
            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
#if DEBUG
            NSInteger status = [(NSHTTPURLResponse *)resp statusCode];
            TgWireConduitLog(@"──── POST response ────\nurl: %@\npath: %@\nHTTP status: %ld\nresponseBody: %@",
                             urlStr, path, (long)status, TgWireBodyString(data));
#endif
            [self handleJSON:json path:path url:urlStr dataSuccess:dataSuccess envelopeSuccess:envelopeSuccess failure:failure];
        }] resume];
    }];
}

- (void)relayUpload:(NSString *)path
           signData:(NSDictionary *)signData
         nonSignData:(NSDictionary *)nonSignData
           fileData:(NSData *)fileData
           fileName:(NSString *)fileName
           mimeType:(NSString *)mimeType
           progress:(TgWireProgressBlock)progress
            success:(TgWireSuccessBlock)success
            failure:(TgWireFailureBlock)failure {
    [self tg_relayUpload:path
                signData:signData
              nonSignData:nonSignData
                fileData:fileData
                fileName:fileName
                mimeType:mimeType
                progress:progress
                 success:success
                 failure:failure
   hostFailoverAttempted:NO];
}

- (void)tg_relayUpload:(NSString *)path
              signData:(NSDictionary *)signData
            nonSignData:(NSDictionary *)nonSignData
              fileData:(NSData *)fileData
              fileName:(NSString *)fileName
              mimeType:(NSString *)mimeType
              progress:(TgWireProgressBlock)progress
               success:(TgWireSuccessBlock)success
               failure:(TgWireFailureBlock)failure
hostFailoverAttempted:(BOOL)hostFailoverAttempted {
    [self ensureHost:^(NSString *host) {
        if (!host) {
            [self notifyFailure:failure];
            return;
        }
        NSString *urlStr = [host stringByAppendingString:path];
        NSDictionary *payload = [self buildPayloadWithSignData:signData ?: @{} nonSignData:nonSignData ?: @{}];
        NSMutableDictionary *formFields = [NSMutableDictionary dictionary];
        for (NSString *k in payload) {
            if ([k isEqualToString:TgParcelEnvelopeKey]) continue;
            formFields[k] = [self stringValue:payload[k]];
        }
        formFields[TgParcelEnvelopeKey] = @"{}";

        NSString *boundary = [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
        NSMutableData *body = [NSMutableData data];
        for (NSString *key in formFields) {
            [body appendData:[[NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@\r\n", boundary, key, formFields[key]] dataUsingEncoding:NSUTF8StringEncoding]];
        }
        [body appendData:[[NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\nContent-Type: %@\r\n\r\n", boundary, fileName, mimeType] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:fileData];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

        NSString *userAgent = [TgSensorLattice weaveAgentString];
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
        req.HTTPMethod = @"POST";
        [req setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
        [req setValue:userAgent forHTTPHeaderField:@"User-Agent"];

#if DEBUG
        TgWireConduitLog(@"──── UPLOAD request ────\nurl: %@\nmethod: POST\nUser-Agent: %@\npath: %@\nfilename: %@\nMIME: %@\nfileBytes: %lu\nsignData: %@\nnonSignData: %@\nformFields: %@\nmultipartBodyBytes: %lu\nhostFailoverAttempted: %@",
                         urlStr, userAgent ?: @"(null)", path,
                         fileName ?: @"(null)", mimeType ?: @"(null)", (unsigned long)fileData.length,
                         TgWireJSONString(signData), TgWireJSONString(nonSignData),
                         TgWireJSONString(formFields), (unsigned long)body.length,
                         hostFailoverAttempted ? @"YES" : @"NO");
#endif

        [[self.session uploadTaskWithRequest:req fromData:body completionHandler:^(NSData *data, NSURLResponse *resp, NSError *err) {
            if ([self tg_shouldFailoverForError:err response:resp] && !hostFailoverAttempted) {
#if DEBUG
                NSInteger st = [resp isKindOfClass:[NSHTTPURLResponse class]] ? [(NSHTTPURLResponse *)resp statusCode] : 0;
                TgWireConduitLog(@"domain failover triggered\noldBaseURL: %@\npath: %@\nurl: %@\nhttpStatus: %ld\nerrorKind: %@\nerror: %@\nwillRetryOnce: YES",
                                 host, path, urlStr, (long)st,
                                 err ? TgWireErrorKind(err) : @"http status",
                                 err.localizedDescription ?: @"(nil)");
#endif
                [self tg_refetchHostThenRetry:^{
                    [self tg_relayUpload:path
                                signData:signData
                              nonSignData:nonSignData
                                fileData:fileData
                                fileName:fileName
                                mimeType:mimeType
                                progress:progress
                                 success:success
                                 failure:failure
                   hostFailoverAttempted:YES];
                } failure:failure];
                return;
            }
            if (err) {
#if DEBUG
                TgWireConduitLog(@"UPLOAD fail\nurl: %@\npath: %@\nerrorKind: %@\nerror: %@\ndomain: %@\ncode: %ld",
                                 urlStr, path, TgWireErrorKind(err), err.localizedDescription,
                                 err.domain, (long)err.code);
#endif
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (![self tg_shouldSuppressBusyToastForPath:path error:err]) {
                        [[TgPulseOverlay shared] whisperLine:kBusyToast duration:2.0];
                    }
                    if (failure) failure();
                });
                return;
            }
            [self tg_markNetworkUsableAfterSuccess];
            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
#if DEBUG
            NSInteger status = [(NSHTTPURLResponse *)resp statusCode];
            TgWireConduitLog(@"──── UPLOAD response ────\nurl: %@\npath: %@\nHTTP status: %ld\nresponseBody: %@",
                             urlStr, path, (long)status, TgWireBodyString(data));
#endif
            [self handleJSON:json path:path url:urlStr dataSuccess:success envelopeSuccess:nil failure:failure];
        }] resume];
    }];
}

#pragma mark - Payload / Sign mode 1

- (NSDictionary *)buildPayloadWithSignData:(NSDictionary *)signData nonSignData:(NSDictionary *)nonSignData {
    NSString *nonce = [self randomNonce:16];
    NSString *clientTime = [NSString stringWithFormat:@"%lld", (long long)([[NSDate date] timeIntervalSince1970] * 1000)];
    NSString *deviceId = [TgStampVault serialStamp];
    NSString *userId = [TgPersonaVault shared].holderId;
    NSString *token = [TgPersonaVault shared].holderToken;

    NSMutableDictionary *common = [@{
        @"appId": TgParcelClientAppId,
        @"deviceId": deviceId ?: @"",
        @"channel": TgParcelDefaultChannel,
        @"nonce": nonce,
        @"version": TgParcelApiVersion,
        @"clientTime": clientTime,
        @"os": @(TgParcelOsTypeIOS),
        @"clientVersion": TgParcelBundleVersion(),
        @"clientLanguage": TgParcelDefaultLanguage,
        @"userId": userId ?: @"",
        @"token": token ?: @""
    } mutableCopy];

    common[@"sign"] = [self signMode1WithCommon:common signData:signData];

    NSMutableDictionary *biz = [NSMutableDictionary dictionary];
    [biz addEntriesFromDictionary:signData];
    [biz addEntriesFromDictionary:nonSignData];
    common[TgParcelEnvelopeKey] = biz;
    return common;
}

- (NSString *)signMode1WithCommon:(NSDictionary *)common signData:(NSDictionary *)signData {
    NSArray *keys = @[@"appId", @"deviceId", @"channel", @"nonce", @"version", @"clientTime", @"os"];
    NSMutableArray<NSString *> *values = [NSMutableArray array];
    for (NSString *k in keys) {
        [values addObject:[self stringValue:common[k]]];
    }
    for (id v in signData.allValues) {
        [values addObject:[self stringValue:v]];
    }
    [values sortUsingSelector:@selector(compare:)];
    NSString *s1 = [values componentsJoinedByString:@"&"];
    NSString *s2 = [[self md5Hex:s1] uppercaseString];
    NSString *s3 = [s2 stringByAppendingString:TgParcelSignSalt];
    return [[self md5Hex:s3] uppercaseString];
}

- (NSString *)md5Hex:(NSString *)input {
    const char *c = input.UTF8String;
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(c, (CC_LONG)strlen(c), digest);
    NSMutableString *out = [NSMutableString stringWithCapacity:32];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [out appendFormat:@"%02x", digest[i]];
    }
    return out;
}

- (NSString *)randomNonce:(NSInteger)len {
    NSString *chars = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *s = [NSMutableString string];
    for (NSInteger i = 0; i < len; i++) {
        [s appendFormat:@"%C", [chars characterAtIndex:arc4random_uniform((uint32_t)chars.length)]];
    }
    return s;
}

- (NSString *)stringValue:(id)value {
    if (!value || value == [NSNull null]) return @"";
    if ([value isKindOfClass:[NSString class]]) return value;
    if ([value isKindOfClass:[NSNumber class]]) return [(NSNumber *)value stringValue];
    return [NSString stringWithFormat:@"%@", value];
}

#pragma mark - Response

- (BOOL)tg_usesLegacyEnvelopeKeysForPath:(NSString *)path {
    return [path isEqualToString:TgLaneSysUpload] || [path isEqualToString:TgLaneFeedback];
}

- (void)tg_applyLegacyEnvelopeFields:(TgEnvelopeBase *)envelope fromJSON:(NSDictionary *)json {
    if (!envelope || !json) return;
    id rc = json[@"resultCode"];
    if ([rc isKindOfClass:[NSNumber class]]) {
        envelope.cheer = [(NSNumber *)rc integerValue];
    } else if ([rc isKindOfClass:[NSString class]]) {
        envelope.cheer = [(NSString *)rc integerValue];
    }
    id msg = json[@"resultMsg"];
    if ([msg isKindOfClass:[NSString class]]) {
        envelope.power = msg;
    }
    if (json[@"data"]) {
        envelope.trick = json[@"data"];
    }
    id ts = json[@"timestamp"];
    if ([ts isKindOfClass:[NSNumber class]]) {
        envelope.radiation = [(NSNumber *)ts longLongValue];
    } else if ([ts isKindOfClass:[NSString class]]) {
        envelope.radiation = [(NSString *)ts longLongValue];
    }
}

- (void)handleJSON:(id)json
              path:(NSString *)path
               url:(NSString *)url
       dataSuccess:(TgWireSuccessBlock)dataSuccess
   envelopeSuccess:(TgWireEnvelopeSuccessBlock)envelopeSuccess
           failure:(TgWireFailureBlock)failure {
    TgEnvelopeBase *envelope = [TgEnvelopeBase yy_modelWithJSON:json];
    if (!envelope) {
#if DEBUG
        TgWireConduitLog(@"parse fail path=%@ url=%@ raw=%@", path, url, TgWireJSONString(json));
#endif
        [self notifyFailure:failure];
        return;
    }
    if ([self tg_usesLegacyEnvelopeKeysForPath:path] && [json isKindOfClass:[NSDictionary class]]) {
        [self tg_applyLegacyEnvelopeFields:envelope fromJSON:(NSDictionary *)json];
    }
    NSString *code = [NSString stringWithFormat:@"%ld", (long)envelope.cheer];
#if DEBUG
    TgWireConduitLog(@"business path=%@ url=%@ resultCode=%@ msg=%@ success=%@",
                     path, url, code, envelope.power, envelope.isSuccess ? @"YES" : @"NO");
#endif
    if ([code isEqualToString:TgFaultTokenStale] || [code isEqualToString:TgFaultTokenVoid] || [code isEqualToString:TgFaultAccountMissing]) {
        if ([TgPersonaVault shared].holderToken.length > 0) {
            [self handleTokenInvalid:failure];
            return;
        }
    }
    if ([code isEqualToString:TgFaultForceRefresh]) {
        // Avoid recursive force-update scheduling when the version probe itself is restricted.
        if (![path isEqualToString:TgLaneVersionProbe]) {
            [self tg_handleForceUpdateRequired];
        }
        [self notifyFailure:failure];
        return;
    }
    if (envelopeSuccess) {
        dispatch_async(dispatch_get_main_queue(), ^{
            envelopeSuccess(envelope);
        });
        return;
    }
    if (envelope.isSuccess) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (dataSuccess) {
                dataSuccess(envelope.trick);
            }
        });
    } else {
        NSString *msg = [envelope.power stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (msg.length > 0) {
                [[TgPulseOverlay shared] whisperLine:msg duration:2.0];
            }
            if (failure) {
                failure();
            }
        });
    }
}

- (void)handleTokenInvalid:(TgWireFailureBlock)failure {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[TgPersonaVault shared] wipe];
        failure();
        UIWindowScene *scene = nil;
        for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
            if (s.activationState == UISceneActivationStateForegroundActive && [s isKindOfClass:[UIWindowScene class]]) {
                scene = (UIWindowScene *)s;
                break;
            }
        }
        if ([scene.delegate respondsToSelector:@selector(tg_switchToSignInAnimated:)]) {
            [(SceneDelegate *)scene.delegate tg_switchToSignInAnimated:YES];
        }
    });
}

- (void)tg_markNetworkUsableAfterSuccess {
    if (!self.coldStartFirstInstall) return;
    self.coldStartFirstInstall = NO;
}

- (BOOL)tg_shouldSuppressBusyToast {
    if (self.forceUpdateFlowActive || self.forceUpdateVisible || self.forceVersionFetching) return YES;
    // First install before wireless-data / network is authorized: no busy toast.
    if (self.coldStartFirstInstall) return YES;
    return NO;
}

- (BOOL)tg_shouldSuppressBusyToastForPath:(NSString *)path error:(NSError *)err {
    (void)err;
    if ([self tg_shouldSuppressBusyToast]) return YES;
    if ([path isEqualToString:TgLaneBuryRecord]) return YES;
    return NO;
}

- (BOOL)tg_isForceUpdateBlocking {
    return self.forceUpdateFlowActive || self.forceUpdateVisible || self.forceVersionFetching;
}

- (void)tg_handleForceUpdateRequired {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.forceUpdateFlowActive = YES;
        [self scheduleForceUpdate];
    });
}

- (void)scheduleForceUpdate {
    // Must run on main to avoid concurrent schedule races from URLSession callbacks.
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self scheduleForceUpdate];
        });
        return;
    }
    if (self.forceUpdateVisible || self.forceVersionFetching) return;
    self.forceVersionFetching = YES;
    self.forceUpdateFlowActive = YES;

    __weak typeof(self) weakSelf = self;
    [self relayPOST:TgLaneVersionProbe signData:@{} nonSignData:@{} success:^(id data) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.forceVersionFetching = NO;
        TgVersionData *vd = [TgVersionData yy_modelWithJSON:data];
        if (![vd.updateType isEqualToString:@"2"]) {
            self.forceUpdateFlowActive = NO;
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentForceUpdate:vd];
        });
    } failure:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.forceVersionFetching = NO;
        // Keep forceUpdateFlowActive; a later 2009006 will retry scheduleForceUpdate.
    }];
}

- (void)presentForceUpdate:(TgVersionData *)data {
    if (self.forceUpdateVisible) return;
    NSString *ver = [data.noticeable stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (ver.length == 0) return;

    self.forceUpdateVisible = YES;

    TgShardPanelConfig *cfg = [[TgShardPanelConfig alloc] init];
    cfg.panelStyle = TgShardPanelStyleText;
    cfg.title = @"Upgrade";
    cfg.content = @"New version found";
    cfg.detailText = [NSString stringWithFormat:@"V%@", ver];
    cfg.primaryTitle = @"Upgrade";
    cfg.dismissOnPrimaryAction = NO;
    cfg.tier = TgShardTierHigh;
    cfg.mount = TgShardMountWindow;

    __weak typeof(self) weakSelf = self;
    NSString *urlStr = data.contrast;
    cfg.primaryAction = ^{
        NSURL *url = urlStr.length > 0 ? [NSURL URLWithString:urlStr] : nil;
        if (url && [UIApplication.sharedApplication canOpenURL:url]) {
            [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
        } else {
            [[TgPulseOverlay shared] whisperLine:@"The download link is not available." duration:2.0];
        }
    };

    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.forceUpdatePanelToken = [[TgShardFacade shared] showPanel:cfg];
    });
}

#pragma mark - Host

- (void)ensureHost:(void (^)(NSString *host))completion {
    NSString *host = [TgHostRelay shared].activeHost;
    if (host.length > 0) {
#if DEBUG
        TgWireConduitLog(@"ensureHost hit cache=%@", host);
#endif
        completion(host);
        return;
    }
#if DEBUG
    TgWireConduitLog(@"ensureHost cache miss, fetch domain...");
#endif
    [[TgHostRelay shared] fetchHost:^(BOOL ok) {
#if DEBUG
        TgWireConduitLog(@"ensureHost fetch done ok=%@ host=%@", ok ? @"YES" : @"NO", [TgHostRelay shared].activeHost ?: @"(nil)");
#endif
        completion(ok ? [TgHostRelay shared].activeHost : nil);
    }];
}

- (BOOL)tg_shouldFailoverForError:(NSError *)err response:(NSURLResponse *)resp {
    if (err) return YES;
    if (![resp isKindOfClass:[NSHTTPURLResponse class]]) return YES;
    NSInteger code = [(NSHTTPURLResponse *)resp statusCode];
    return code >= 500;
}

- (void)tg_refetchHostThenRetry:(void (^)(void))retry failure:(TgWireFailureBlock)failure {
    NSString *oldHost = [TgHostRelay shared].activeHost ?: @"";
    [[TgHostRelay shared] refetchHost:^(BOOL ok) {
        NSString *newHost = [TgHostRelay shared].activeHost ?: @"";
#if DEBUG
        TgWireConduitLog(@"domain re-fetch result\nok: %@\noldBaseURL: %@\nnewBaseURL: %@\nretryOnce: %@",
                         ok ? @"YES" : @"NO",
                         oldHost.length ? oldHost : @"(nil)",
                         newHost.length ? newHost : @"(nil)",
                         ok ? @"YES" : @"NO");
#endif
        if (!ok) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (![self tg_shouldSuppressBusyToast]) {
                    [[TgPulseOverlay shared] whisperLine:kBusyToast duration:2.0];
                }
                if (failure) failure();
            });
            return;
        }
        if (retry) retry();
    }];
}

- (void)notifyFailure:(TgWireFailureBlock)failure {
    if (!failure) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (failure) failure();
    });
}

@end
