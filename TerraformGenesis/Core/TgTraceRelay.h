//

//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TgTraceSignal) {
    TgTraceSignalFirstOpen = 0,
    TgTraceSignalAppLaunch = 1,
    TgTraceSignalPrivacyOpen = 2,
    TgTraceSignalTermsOpen = 3,
    TgTraceSignalSmsTap = 4,
    TgTraceSignalLoginTap = 5,
    TgTraceSignalHomeApplyTap = 7,
    TgTraceSignalCameraGrant = 11,
    TgTraceSignalCameraDeny = 12,
    TgTraceSignalLocationGrant = 15,
    TgTraceSignalLocationDeny = 16,
    TgTraceSignalIdfaGrant = 17,
    TgTraceSignalIdfaDeny = 18,
    TgTraceSignalContactsGrant = 19,
    TgTraceSignalContactsDeny = 20,
    TgTraceSignalContactsPartial = 198,
    TgTraceSignalKycVerifyFail = 29,
    TgTraceSignalProfileSubmit = 30,
    TgTraceSignalWorkSubmit = 31,
    TgTraceSignalEmergencySubmit = 32,
    TgTraceSignalContactPick = 33,
    TgTraceSignalSurveySubmit = 34,
    TgTraceSignalStartTap = 35,
    TgTraceSignalLivenessFace = 39,
    TgTraceSignalPanSubmit = 40,
    TgTraceSignalPanUploadTap = 41,
    TgTraceSignalPanCameraPick = 42,
    TgTraceSignalPanCameraOpen = 43,
    TgTraceSignalPanCapture = 44,
    TgTraceSignalPanConfirm = 45,
    TgTraceSignalPanRetake = 46,
    TgTraceSignalPanCameraBack = 47,
    TgTraceSignalPanAlbumOpen = 48,
    TgTraceSignalPanAlbumPick = 49,
    TgTraceSignalIdFrontPick = 50,
    TgTraceSignalIdFrontCamera = 51,
    TgTraceSignalIdFrontAlbum = 52,
    TgTraceSignalIdFrontCameraOpen = 53,
    TgTraceSignalIdFrontCapture = 54,
    TgTraceSignalIdFrontConfirm = 55,
    TgTraceSignalIdFrontBack = 56,
    TgTraceSignalIdFrontAlbumPick = 57,
    TgTraceSignalIdBackPick = 58,
    TgTraceSignalIdBackCamera = 59,
    TgTraceSignalIdBackAlbum = 60,
    TgTraceSignalIdBackCameraOpen = 61,
    TgTraceSignalIdBackCapture = 62,
    TgTraceSignalIdBackConfirm = 63,
    TgTraceSignalIdBackBack = 64,
    TgTraceSignalIdBackAlbumPick = 65,
    TgTraceSignalIdVerifySubmit = 66,
    TgTraceSignalBankSubmit = 67,
    TgTraceSignalOrderApplyTap = 68,
    TgTraceSignalAutoOrderStart = 69,
    TgTraceSignalReloanSheetShow = 70,
    TgTraceSignalReloanOrder = 71,
    TgTraceSignalReloanSheetClose = 72,
    TgTraceSignalRejectExternalOpen = 502,
};

@interface TgTraceRelay : NSObject

+ (instancetype)shared;

+ (void)emitSignal:(TgTraceSignal)signal;
+ (void)emitSignal:(TgTraceSignal)signal content:(nullable NSString *)content;
+ (void)emitSignal:(TgTraceSignal)signal
           content:(nullable NSString *)content
           remark1:(nullable NSString *)remark1
           remark2:(nullable NSString *)remark2
           remark3:(nullable NSString *)remark3;

+ (void)emitCustomCode:(NSString *)code
               content:(nullable NSString *)content
               remark1:(nullable NSString *)remark1
               remark2:(nullable NSString *)remark2
               remark3:(nullable NSString *)remark3;

#pragma mark - 便捷

+ (void)emitFirstOpen;
+ (void)emitAppLaunch;
+ (void)emitPermissionGrant:(TgTraceSignal)grantSignal deny:(TgTraceSignal)denySignal granted:(BOOL)granted;

@end

NS_ASSUME_NONNULL_END
