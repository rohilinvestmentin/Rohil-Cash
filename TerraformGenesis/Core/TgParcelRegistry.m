//
//  TgParcelRegistry.m
//

#import "TgParcelRegistry.h"

NSString * const TgLaneAppConfig = @"/app/v3/app/config";
NSString * const TgLaneVersionProbe = @"/app/v3/app/versionV2";
NSString * const TgLaneFeedback = @"/app/v3/user/problemFeedback";
NSString * const TgLaneMobileDevice = @"/app/v3/mobile/device";
NSString * const TgLaneMobileContact = @"/app/v3/mobile/contact";
NSString * const TgLaneAuthRegister = @"/app/v3/auth/registerOrLogin";
NSString * const TgLaneSmsVerify = @"/app/v3/sms/sendVerifySms";
NSString * const TgLaneUserSupHome = @"/app/v3/user/suphome";
NSString * const TgLaneUserInfo = @"/app/v3/user/info";
NSString * const TgLaneRegisterDevice = @"/app/v3/mobile/registerDevice";
NSString * const TgLaneProductTerm = @"/app/v3/product/termV3";
NSString * const TgLaneProductList = @"/app/v3/product/list";
NSString * const TgLaneProductState = @"/app/v3/product/state";
NSString * const TgLaneDcRecommend = @"/app/v3/product/dcRecommend";
NSString * const TgLaneOrderSubmit = @"/app/v3/order/userSubmitV3";
NSString * const TgLaneOrderSubmitDcUpgrade = @"/app/v3/order/userSubmitDcUpgrade";
NSString * const TgLaneOrderReady = @"/app/v3/order/ready";
NSString * const TgLaneOrderList = @"/app/v3/order/list";
NSString * const TgLaneOrderDetail = @"/app/v3/order/detailV2";
NSString * const TgLaneWithdrawnDetail = @"/app/v3/order/withdrawn/detail";
NSString * const TgLaneApplyWithdrawal = @"/app/v3/order/apply/withdrawal";
NSString * const TgLaneRepayConnect = @"/app/v3/order/repay/connect";
NSString * const TgLaneRepayExtension = @"/app/v3/order/repay/extension";
NSString * const TgLaneBankcardList = @"/app/v3/bankcard/list";
NSString * const TgLaneBankcardModify = @"/app/v3/bankcard/modify";
NSString * const TgLaneKycInit = @"/app/v3/kyc/init";
NSString * const TgLaneKycStatus = @"/app/v3/kyc/status";
NSString * const TgLaneKycCommit = @"/app/v3/kyc/commit";
NSString * const TgLaneKycItemCommit = @"/app/v3/kyc/item/commit";
NSString * const TgLaneKycLiveness = @"/app/v3/kyc/liveness/silent";
NSString * const TgLaneSysBank = @"/app/v3/sys/bank";
NSString * const TgLaneSysIfsc = @"/app/v3/sys/ifsc";
NSString * const TgLaneSysUpload = @"/app/v3/sys/upload";
NSString * const TgLaneAuthClose = @"/app/v3/auth/close";
NSString * const TgLaneBuryRecord = @"/app/v3/bury/record";
NSString * const TgLaneCategoryGory = @"/app/v3/category/gory";

NSString * const TgFaultTokenStale = @"2000001";
NSString * const TgFaultTokenVoid = @"2000002";
NSString * const TgFaultAccountMissing = @"2002001";
NSString * const TgFaultForceRefresh = @"2009006";
NSString * const TgFaultCertVerifyFail = @"6212011";
NSString * const TgFaultCertVerifyFailAlt = @"6212201";
NSString * const TgFaultHasOrder = @"6230002";
NSString * const TgFaultHasWithdrawOrder = @"6230003";
NSString * const TgFaultRejectQuota = @"6234303";
NSString * const TgFaultRejectNoProduct = @"4102007";

BOOL TgFaultIsCertVerifyFailed(NSInteger resultCode) {
    NSString *code = [NSString stringWithFormat:@"%ld", (long)resultCode];
    return [code isEqualToString:TgFaultCertVerifyFail] || [code isEqualToString:TgFaultCertVerifyFailAlt];
}

NSString * const TgParcelClientAppId = @"tilotcash";
NSString * const TgParcelApiVersion = @"2.0";
NSString * const TgParcelDefaultChannel = @"app_store";
NSInteger const TgParcelOsTypeIOS = 2;
NSString * const TgParcelDefaultLanguage = @"en";
NSString * const TgParcelEnvelopeKey = @"data";

NSString * const TgParcelSignSalt = @"E8Rk59rgaNWVWJ0k";
NSString * const TgParcelAdjustToken = @"j1rcgha3ipds";

NSString * const TgCacheUid = @"tg.lattice.p9.uid";
NSString * const TgCacheToken = @"tg.lattice.p9.tok";
NSString * const TgCacheMobile = @"tg.lattice.p9.mob";
NSString * const TgCacheDomain = @"tg.lattice.p9.host";
NSString * const TgCacheAppUserType = @"tg.lattice.p9.app.user.type";

NSString * const TgMarkEverLaunched = @"tg.lattice.p9.ever";
NSString * const TgMarkReviewGuideDisplayed = @"tg.lattice.p9.review.guide.shown";

NSString *TgParcelBundleVersion(void) {
    NSString *v = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    return (v.length > 0) ? v : @"1.0";
}
