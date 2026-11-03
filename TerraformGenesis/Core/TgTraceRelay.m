//
//  TgTraceRelay.m
//

#import "TgTraceRelay.h"
#import "TgWireConduit.h"
#import "TgParcelRegistry.h"

static NSString * const kTgTraceNullToken = @"NULL";
static NSString * const kTgTraceCustomPrefix = @"custom_";
static const NSUInteger kTgTraceContentMaxLen = 1024;

@implementation TgTraceRelay

+ (instancetype)shared {
    static TgTraceRelay *relay;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ relay = [[TgTraceRelay alloc] init]; });
    return relay;
}

+ (void)emitSignal:(TgTraceSignal)signal {
    [self emitSignal:signal content:nil remark1:nil remark2:nil remark3:nil];
}

+ (void)emitSignal:(TgTraceSignal)signal content:(NSString *)content {
    [self emitSignal:signal content:content remark1:nil remark2:nil remark3:nil];
}

+ (void)emitSignal:(TgTraceSignal)signal
           content:(NSString *)content
           remark1:(NSString *)remark1
           remark2:(NSString *)remark2
           remark3:(NSString *)remark3 {
    [self postEventCode:[NSString stringWithFormat:@"%ld", (long)signal]
                content:[self resolvedContent:content forSignal:signal]
                remark1:remark1
                remark2:remark2
                remark3:remark3];
}

+ (void)emitCustomCode:(NSString *)code
               content:(NSString *)content
               remark1:(NSString *)remark1
               remark2:(NSString *)remark2
               remark3:(NSString *)remark3 {
    if (code.length == 0) return;
    NSString *eventCode = [code hasPrefix:kTgTraceCustomPrefix] ? code : [kTgTraceCustomPrefix stringByAppendingString:code];
    [self postEventCode:eventCode content:content remark1:remark1 remark2:remark2 remark3:remark3];
}

+ (void)emitFirstOpen {
    [self emitSignal:TgTraceSignalFirstOpen];
}

+ (void)emitAppLaunch {
    [self emitSignal:TgTraceSignalAppLaunch];
}

+ (void)emitPermissionGrant:(TgTraceSignal)grantSignal deny:(TgTraceSignal)denySignal granted:(BOOL)granted {
    [self emitSignal:granted ? grantSignal : denySignal];
}

#pragma mark - Private

+ (NSString *)resolvedContent:(NSString *)content forSignal:(TgTraceSignal)signal {
    NSString *trimmed = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length > 0) return trimmed;
    return [self defaultEnglishContentForSignal:signal];
}

+ (NSString *)defaultEnglishContentForSignal:(TgTraceSignal)signal {
    switch (signal) {
        case TgTraceSignalFirstOpen: return @"First open";
        case TgTraceSignalAppLaunch: return @"App launch";
        case TgTraceSignalPrivacyOpen: return @"Open privacy policy";
        case TgTraceSignalTermsOpen: return @"Open terms of service";
        case TgTraceSignalSmsTap: return @"Tap send SMS";
        case TgTraceSignalLoginTap: return @"Tap login";
        case TgTraceSignalHomeApplyTap: return @"Tap apply on home";
        case TgTraceSignalCameraGrant: return @"Camera permission granted";
        case TgTraceSignalCameraDeny: return @"Camera permission denied";
        case TgTraceSignalLocationGrant: return @"Location permission granted";
        case TgTraceSignalLocationDeny: return @"Location permission denied";
        case TgTraceSignalIdfaGrant: return @"IDFA authorized";
        case TgTraceSignalIdfaDeny: return @"IDFA denied";
        case TgTraceSignalContactsGrant: return @"Contacts permission granted";
        case TgTraceSignalContactsDeny: return @"Contacts permission denied";
        case TgTraceSignalContactsPartial: return @"Contacts partial access";
        case TgTraceSignalKycVerifyFail: return @"KYC verification failed";
        case TgTraceSignalProfileSubmit: return @"Personal profile submitted";
        case TgTraceSignalWorkSubmit: return @"Work information submitted";
        case TgTraceSignalEmergencySubmit: return @"Emergency contacts submitted";
        case TgTraceSignalContactPick: return @"Contact picker used";
        case TgTraceSignalSurveySubmit: return @"Survey submitted";
        case TgTraceSignalStartTap: return @"Tap start";
        case TgTraceSignalLivenessFace: return @"Liveness face scan";
        case TgTraceSignalPanSubmit: return @"PAN submitted";
        case TgTraceSignalPanUploadTap: return @"PAN tap upload";
        case TgTraceSignalPanCameraPick: return @"PAN choose camera";
        case TgTraceSignalPanCameraOpen: return @"PAN open camera";
        case TgTraceSignalPanCapture: return @"PAN capture photo";
        case TgTraceSignalPanConfirm: return @"PAN confirm";
        case TgTraceSignalPanRetake: return @"PAN retake";
        case TgTraceSignalPanCameraBack: return @"PAN camera back";
        case TgTraceSignalPanAlbumOpen: return @"PAN open album";
        case TgTraceSignalPanAlbumPick: return @"PAN pick from album";
        case TgTraceSignalIdFrontPick: return @"ID front pick";
        case TgTraceSignalIdFrontCamera: return @"ID front camera";
        case TgTraceSignalIdFrontAlbum: return @"ID front album";
        case TgTraceSignalIdFrontCameraOpen: return @"ID front open camera";
        case TgTraceSignalIdFrontCapture: return @"ID front capture";
        case TgTraceSignalIdFrontConfirm: return @"ID front confirm";
        case TgTraceSignalIdFrontBack: return @"ID front back";
        case TgTraceSignalIdFrontAlbumPick: return @"ID front pick from album";
        case TgTraceSignalIdBackPick: return @"ID back pick";
        case TgTraceSignalIdBackCamera: return @"ID back camera";
        case TgTraceSignalIdBackAlbum: return @"ID back album";
        case TgTraceSignalIdBackCameraOpen: return @"ID back open camera";
        case TgTraceSignalIdBackCapture: return @"ID back capture";
        case TgTraceSignalIdBackConfirm: return @"ID back confirm";
        case TgTraceSignalIdBackBack: return @"ID back back";
        case TgTraceSignalIdBackAlbumPick: return @"ID back pick from album";
        case TgTraceSignalIdVerifySubmit: return @"ID verification submitted";
        case TgTraceSignalBankSubmit: return @"Bank card submitted";
        case TgTraceSignalOrderApplyTap: return @"Tap apply order";
        case TgTraceSignalAutoOrderStart: return @"Auto order started";
        case TgTraceSignalReloanSheetShow: return @"Re-apply sheet shown";
        case TgTraceSignalReloanOrder: return @"Re-apply order";
        case TgTraceSignalReloanSheetClose: return @"Re-apply sheet closed";
        case TgTraceSignalRejectExternalOpen: return @"Reject H5 open external browser";
    }
    return [NSString stringWithFormat:@"Unknown event (%ld)", (long)signal];
}

+ (void)postEventCode:(NSString *)eventCode
              content:(NSString *)content
              remark1:(NSString *)remark1
              remark2:(NSString *)remark2
              remark3:(NSString *)remark3 {
    NSDictionary *signData = @{
        @"eventCode": eventCode,
        @"eventContent": [self normalizedField:content],
        @"remark1": [self normalizedField:remark1],
        @"remark2": [self normalizedField:remark2],
        @"remark3": [self normalizedField:remark3],
    };
    // Fire-and-forget: never surface bury failures as busy toasts.
    [[TgWireConduit shared] relayPOST:TgLaneBuryRecord
                             signData:signData
                           nonSignData:@{}
                      envelopeSuccess:^(TgEnvelopeBase *envelope) { (void)envelope; }
                              failure:^{ }];
}

+ (NSString *)normalizedField:(NSString *)value {
    NSString *raw = value.length > 0 ? value : @"";
    NSString *trimmed = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) return kTgTraceNullToken;
    if (trimmed.length > kTgTraceContentMaxLen) {
        return [trimmed substringToIndex:kTgTraceContentMaxLen];
    }
    return trimmed;
}

@end
