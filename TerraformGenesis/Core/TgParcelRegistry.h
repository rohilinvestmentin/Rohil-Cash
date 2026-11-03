//
//  TgParcelRegistry.h

//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Path

FOUNDATION_EXPORT NSString * const TgLaneAppConfig;
FOUNDATION_EXPORT NSString * const TgLaneVersionProbe;
FOUNDATION_EXPORT NSString * const TgLaneFeedback;
FOUNDATION_EXPORT NSString * const TgLaneMobileDevice;
FOUNDATION_EXPORT NSString * const TgLaneMobileContact;
FOUNDATION_EXPORT NSString * const TgLaneAuthRegister;
FOUNDATION_EXPORT NSString * const TgLaneSmsVerify;
FOUNDATION_EXPORT NSString * const TgLaneUserSupHome;
FOUNDATION_EXPORT NSString * const TgLaneUserInfo;
FOUNDATION_EXPORT NSString * const TgLaneRegisterDevice;
FOUNDATION_EXPORT NSString * const TgLaneProductTerm;
FOUNDATION_EXPORT NSString * const TgLaneProductList;
FOUNDATION_EXPORT NSString * const TgLaneProductState;
FOUNDATION_EXPORT NSString * const TgLaneDcRecommend; ///< /app/v3/product/dcRecommend
FOUNDATION_EXPORT NSString * const TgLaneOrderSubmit;
FOUNDATION_EXPORT NSString * const TgLaneOrderSubmitDcUpgrade; ///< /app/v3/order/userSubmitDcUpgrade
FOUNDATION_EXPORT NSString * const TgLaneOrderReady;
FOUNDATION_EXPORT NSString * const TgLaneOrderList;
FOUNDATION_EXPORT NSString * const TgLaneOrderDetail;
FOUNDATION_EXPORT NSString * const TgLaneWithdrawnDetail;
FOUNDATION_EXPORT NSString * const TgLaneApplyWithdrawal;
FOUNDATION_EXPORT NSString * const TgLaneRepayConnect;
FOUNDATION_EXPORT NSString * const TgLaneRepayExtension;
FOUNDATION_EXPORT NSString * const TgLaneBankcardList;
FOUNDATION_EXPORT NSString * const TgLaneBankcardModify;
FOUNDATION_EXPORT NSString * const TgLaneKycInit;
FOUNDATION_EXPORT NSString * const TgLaneKycStatus;
FOUNDATION_EXPORT NSString * const TgLaneKycCommit;
FOUNDATION_EXPORT NSString * const TgLaneKycItemCommit;
FOUNDATION_EXPORT NSString * const TgLaneKycLiveness;
FOUNDATION_EXPORT NSString * const TgLaneSysBank;
FOUNDATION_EXPORT NSString * const TgLaneSysIfsc;
FOUNDATION_EXPORT NSString * const TgLaneSysUpload;
FOUNDATION_EXPORT NSString * const TgLaneAuthClose;
FOUNDATION_EXPORT NSString * const TgLaneBuryRecord;
FOUNDATION_EXPORT NSString * const TgLaneCategoryGory;

#pragma mark - Fault / Persona

FOUNDATION_EXPORT NSString * const TgFaultTokenStale;
FOUNDATION_EXPORT NSString * const TgFaultTokenVoid;
FOUNDATION_EXPORT NSString * const TgFaultAccountMissing;
FOUNDATION_EXPORT NSString * const TgFaultForceRefresh;

FOUNDATION_EXPORT NSString * const TgFaultCertVerifyFail;
FOUNDATION_EXPORT NSString * const TgFaultCertVerifyFailAlt;

FOUNDATION_EXPORT NSString * const TgFaultHasOrder;
FOUNDATION_EXPORT NSString * const TgFaultHasWithdrawOrder;
FOUNDATION_EXPORT NSString * const TgFaultRejectQuota;
FOUNDATION_EXPORT NSString * const TgFaultRejectNoProduct;

FOUNDATION_EXPORT BOOL TgFaultIsCertVerifyFailed(NSInteger resultCode);

#pragma mark - App parcel

FOUNDATION_EXPORT NSString * const TgParcelClientAppId;
FOUNDATION_EXPORT NSString * const TgParcelSignSalt;
FOUNDATION_EXPORT NSString * const TgParcelApiVersion;
FOUNDATION_EXPORT NSString * const TgParcelDefaultChannel;
FOUNDATION_EXPORT NSInteger const TgParcelOsTypeIOS;
FOUNDATION_EXPORT NSString * const TgParcelDefaultLanguage;
FOUNDATION_EXPORT NSString * const TgParcelEnvelopeKey;

#pragma mark - Host bootstrap

#pragma mark - Cache keys

FOUNDATION_EXPORT NSString * const TgCacheUid;
FOUNDATION_EXPORT NSString * const TgCacheToken;
FOUNDATION_EXPORT NSString * const TgCacheMobile;
FOUNDATION_EXPORT NSString * const TgCacheDomain;

FOUNDATION_EXPORT NSString * const TgCacheAppUserType;

#pragma mark - Marks / third-party

FOUNDATION_EXPORT NSString * const TgParcelAdjustToken;
FOUNDATION_EXPORT NSString * const TgMarkEverLaunched;

FOUNDATION_EXPORT NSString * const TgMarkReviewGuideDisplayed;

FOUNDATION_EXPORT NSString *TgParcelBundleVersion(void);

NS_ASSUME_NONNULL_END
