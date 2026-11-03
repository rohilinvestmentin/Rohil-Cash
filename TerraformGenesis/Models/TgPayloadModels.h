//

//

#import "TgEnvelopeBase.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Login

@interface TgLoginData : NSObject <YYModel>
@property (nonatomic, copy) NSString *face;   ///< userId
@property (nonatomic, copy) NSString *rank;  ///< token
@property (nonatomic, assign) BOOL highly;   ///< isRegister
@end

@interface TgLoginResponse : TgEnvelopeBase
@property (nonatomic, strong, nullable) TgLoginData *loginData;
@end

#pragma mark - Home

@interface TgOrderStatusCount : NSObject <YYModel>
@property (nonatomic, assign) NSInteger settleOrderCount;
@property (nonatomic, assign) NSInteger repaymentOrderCount;
@property (nonatomic, assign) NSInteger payoutOrderCount;
@property (nonatomic, assign) NSInteger approveOrderCount;
@property (nonatomic, copy, nullable) NSString *interpret;      ///< orderId
@property (nonatomic, copy, nullable) NSString *intellectual;    ///< orderStatus
@property (nonatomic, copy, nullable) NSString *resistance;      ///< productId
@property (nonatomic, copy, nullable) NSString *career;          ///< label
@end

@interface TgAppProductBanner : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSString *region;       ///< bannerHref
@property (nonatomic, copy, nullable) NSString *expectation;  ///< relationId
@end

@interface TgAppLabelBanner : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSString *region;       ///< bannerHref
@property (nonatomic, copy, nullable) NSString *expectation;  ///< relationId
@end

@interface TgHomeData : NSObject <YYModel>
@property (nonatomic, assign) NSInteger telescope;  ///< userStatus
@property (nonatomic, assign) NSInteger elsewhere;  ///< appUserType
@property (nonatomic, assign) NSInteger scholar;    ///< hasOrder
@property (nonatomic, copy, nullable) NSString *garden;  ///< firstLoanOptionLine
@property (nonatomic, copy, nullable) NSArray<NSString *> *hire;  ///< loanSuccessRecordList
@property (nonatomic, copy, nullable) NSArray<TgAppProductBanner *> *emergency;  ///< appProductBanner
@property (nonatomic, copy, nullable) NSArray<TgAppLabelBanner *> *handsome;     ///< appLabelBanner
@property (nonatomic, copy, nullable) NSString *fold;   ///< promptCopy
@property (nonatomic, copy, nullable) NSString *utmost; ///< downloadUrl
@property (nonatomic, copy, nullable) NSString *maxApplyAmount; ///< cleartext; DC upgrade card / reloan amount
@property (nonatomic, strong, nullable) id withdrawalOrderId;
@property (nonatomic, strong, nullable) TgOrderStatusCount *orderStatusCount;
@end

@interface TgHomeResponse : TgEnvelopeBase
@property (nonatomic, strong, nullable) TgHomeData *homeData;
@end

#pragma mark - User Info

@interface TgUserInfoData : NSObject <YYModel>
@property (nonatomic, copy) NSString *reason;
@property (nonatomic, assign) NSInteger node;       ///< desire
@property (nonatomic, copy) NSString *receiver;     ///< phone
@property (nonatomic, assign) NSInteger telescope;  ///< userStatus
@property (nonatomic, copy) NSString *can;        ///< payAccountModifySwitch
@property (nonatomic, copy) NSString *poisonous;    ///< smsSwitch
@property (nonatomic, copy) NSString *sting;      ///< existsMobileContact
@property (nonatomic, assign) NSInteger elsewhere;  ///< appUserType
@property (nonatomic, copy) NSString *matter;     ///< name
@end

@interface TgUserInfoResponse : TgEnvelopeBase
@property (nonatomic, strong, nullable) TgUserInfoData *trick; ///< data
@end

#pragma mark - Order List

@interface TgOrderItem : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSString *appId;
@property (nonatomic, copy, nullable) NSString *tailor;  ///< applyDate
@property (nonatomic, assign) NSInteger companyId;
@property (nonatomic, copy, nullable) NSString *fierce;   ///< dueDate
@property (nonatomic, assign) NSInteger inch;             ///< loanAmount
@property (nonatomic, copy, nullable) NSString *resume;   ///< loanDate
@property (nonatomic, copy, nullable) NSString *interpret;    ///< orderId
@property (nonatomic, assign) NSInteger intellectual;         ///< orderStatus
@property (nonatomic, copy, nullable) NSString *resistance;   ///< productId
@property (nonatomic, copy, nullable) NSString *other;        ///< productName
@property (nonatomic, copy, nullable) NSString *enough;       ///< repayDate
@property (nonatomic, copy, nullable) NSString *face;       ///< userId
@end

@interface TgOrderListData : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSArray<TgOrderItem *> *vital; ///< orderList
@end

@interface TgOrderListResponse : TgEnvelopeBase
@property (nonatomic, strong, nullable) TgOrderListData *trick; ///< data
@end

#pragma mark - Order Detail

@interface TgProductTermItem : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSString *expirationDate;
@property (nonatomic, copy, nullable) NSString *inspire;        ///< interestAmountDue
@property (nonatomic, copy, nullable) NSString *wreck;          ///< principalAmountDue
@property (nonatomic, copy, nullable) NSString *indispensable;  ///< repaymentAmount
@end

@interface TgOrderProduct : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSString *resistance; ///< productId
@property (nonatomic, copy, nullable) NSString *green;        ///< productLogo
@property (nonatomic, copy, nullable) NSString *other;      ///< productName
@end

@interface TgOrderBankCard : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSString *first;      ///< accountName
@property (nonatomic, copy, nullable) NSString *measure;    ///< accountNo
@property (nonatomic, copy, nullable) NSString *xRay;         ///< bankCode (JSON: X-ray)
@property (nonatomic, copy, nullable) NSString *effective;  ///< bankName
@property (nonatomic, copy, nullable) NSString *comparison; ///< bindId
@end

@interface TgOrderDetail : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSString *interpret;    ///< orderId
@property (nonatomic, assign) NSInteger intellectual;         ///< orderStatus
@property (nonatomic, copy, nullable) NSString *inch;         ///< loanAmount
@property (nonatomic, assign) NSInteger culture;              ///< loanTerm
@property (nonatomic, assign) NSInteger industry;             ///< loanTermUnit
@property (nonatomic, assign) NSInteger ill;                  ///< showTerm
@property (nonatomic, copy, nullable) NSString *pit;          ///< feeAmount
@property (nonatomic, copy, nullable) NSString *feather;      ///< taxAmount
@property (nonatomic, copy, nullable) NSString *husband;      ///< receiptAmount
@property (nonatomic, copy, nullable) NSString *typist;         ///< interestAmount
@property (nonatomic, copy, nullable) NSString *nationality;  ///< totalRepaymentAmount
@property (nonatomic, copy, nullable) NSString *shouldRepaymentAmount;
@property (nonatomic, copy, nullable) NSString *wire;         ///< alreadyRepaymentAmount
@property (nonatomic, copy, nullable) NSString *pale;         ///< reductionAmount
@property (nonatomic, copy, nullable) NSString *tailor;         ///< applyDate
@property (nonatomic, copy, nullable) NSString *resident;      ///< payoutDate
@property (nonatomic, copy, nullable) NSString *fierce;         ///< dueDate
@property (nonatomic, copy, nullable) NSString *unity;         ///< repaymentDate
@property (nonatomic, copy, nullable) NSString *locate;         ///< riskDate
@property (nonatomic, copy, nullable) NSString *means;         ///< penaltyAmount
@property (nonatomic, assign) NSInteger prison;                 ///< penaltyDays
@property (nonatomic, copy, nullable) NSString *exclude;       ///< ifExtension
@property (nonatomic, copy, nullable) NSString *specimen;      ///< repayExtensionFeeAmount
@property (nonatomic, copy, nullable) NSString *ciphersh;      ///< dueExtensionFeeAmount
@property (nonatomic, copy, nullable) NSString *upright;       ///< EMIAmount
@property (nonatomic, copy, nullable) NSString *EMIRepayDate;
@property (nonatomic, assign) NSInteger EMIs;
@property (nonatomic, copy, nullable) NSArray<TgProductTermItem *> *pair; ///< productTermItemList
@end

@interface TgOrderDetailData : NSObject <YYModel>
@property (nonatomic, strong, nullable) TgOrderProduct *invent;   ///< product
@property (nonatomic, strong, nullable) TgOrderBankCard *living;   ///< bankCard
@property (nonatomic, assign) NSInteger easy;                       ///< isWillingRepay
@property (nonatomic, strong, nullable) TgOrderDetail *hillside;    ///< orderDetail
@end

@interface TgOrderDetailResponse : TgEnvelopeBase
@property (nonatomic, strong, nullable) TgOrderDetailData *orderDetailData;
@end

#pragma mark - Withdrawn Order Detail

@interface TgWithdrawnTermDetail : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSString *minority;  ///< arrivalAmount
@property (nonatomic, copy, nullable) NSString *postage;   ///< borrowingDate
@property (nonatomic, copy, nullable) NSString *upright;   ///< EMIAmount
@property (nonatomic, copy, nullable) NSString *EMIRepayDate;
@property (nonatomic, copy, nullable) NSString *EMIs;
@property (nonatomic, copy, nullable) NSString *convert;   ///< EMITenure
@property (nonatomic, copy, nullable) NSString *pit;       ///< feeAmount
@property (nonatomic, copy, nullable) NSString *typist;    ///< interestAmount
@property (nonatomic, assign) NSInteger culture;           ///< loanTerm
@property (nonatomic, copy, nullable) NSArray<TgProductTermItem *> *pair; ///< productTermItemList
@property (nonatomic, assign) NSInteger realize;           ///< productTermUnit
@property (nonatomic, copy, nullable) NSString *indispensable; ///< repaymentAmount
@property (nonatomic, copy, nullable) NSString *unity;     ///< repaymentDate
@property (nonatomic, assign) NSInteger ill;               ///< showTerm
@property (nonatomic, copy, nullable) NSString *feather;   ///< taxAmount
@end

@interface TgWithdrawnAmountDetail : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSString *inch;  ///< loanAmount
@property (nonatomic, copy, nullable) NSArray<TgWithdrawnTermDetail *> *eighth; ///< termDetailList
@end

@interface TgWithdrawnBankCard : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSString *first;      ///< accountName
@property (nonatomic, copy, nullable) NSString *measure;    ///< accountNo
@property (nonatomic, copy, nullable) NSString *enquire;      ///< accountPhone
@property (nonatomic, copy, nullable) NSString *geometry;   ///< accountType
@property (nonatomic, copy, nullable) NSString *xRay;         ///< bankCode (JSON: X-ray)
@property (nonatomic, copy, nullable) NSString *effective;  ///< bankName
@property (nonatomic, copy, nullable) NSString *comparison; ///< bindId
@property (nonatomic, copy, nullable) NSString *promise;    ///< currency
@end

@interface TgWithdrawnOrderDetailData : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSArray<TgWithdrawnAmountDetail *> *nonsense; ///< amountDetailList
@property (nonatomic, copy, nullable) NSArray<TgWithdrawnBankCard *> *superior;      ///< bankCardList
@property (nonatomic, copy, nullable) NSString *interpret;  ///< orderId
@property (nonatomic, copy, nullable) NSString *lion;        ///< productHotline
@property (nonatomic, copy, nullable) NSString *resistance; ///< productId
@property (nonatomic, copy, nullable) NSString *green;      ///< productLogo
@property (nonatomic, copy, nullable) NSString *other;      ///< productName
@property (nonatomic, assign) NSInteger realize;           ///< productTermUnit
@property (nonatomic, copy, nullable) NSString *message;
@end

@interface TgWithdrawnOrderDetailResponse : TgEnvelopeBase
@property (nonatomic, strong, nullable) TgWithdrawnOrderDetailData *withdrawnOrderDetailData;
@end

#pragma mark - Bank Card

@interface TgBankCardInfo : NSObject <YYModel>
@property (nonatomic, copy) NSString *comparison; ///< bindId
@property (nonatomic, copy) NSString *geometry; ///< accountType
@property (nonatomic, copy) NSString *xRay;       ///< bankCode (JSON: X-ray)
@property (nonatomic, copy) NSString *effective;  ///< bankName
@property (nonatomic, copy) NSString *measure;    ///< accountNo
@property (nonatomic, copy) NSString *first;      ///< accountName
@property (nonatomic, copy) NSString *procedure;  ///< ifscCode
@property (nonatomic, copy) NSString *bdhwka;     ///< creditCard
@property (nonatomic, copy) NSString *enquire;    ///< accountPhone
@property (nonatomic, copy) NSString *promise;    ///< currency
@end

@interface TgBankCardListData : NSObject <YYModel>
@property (nonatomic, copy) NSArray<TgBankCardInfo *> *superior; ///< bankCardList
@end

@interface TgBankCardListResponse : TgEnvelopeBase
@property (nonatomic, strong, nullable) TgBankCardListData *trick; ///< data
@end

#pragma mark - System Config

@interface TgDynamicParameter : NSObject <YYModel>
@property (nonatomic, copy) NSString *fjtip;
@property (nonatomic, copy) NSString *cojsemin; ///< contactCount
@property (nonatomic, copy) NSString *invite_url;
@property (nonatomic, copy) NSString *invite_switch;
@property (nonatomic, copy) NSString *AIService;
@property (nonatomic, copy) NSString *customerH5;
@property (nonatomic, copy) NSString *rejectH5;
@end

@interface TgSystemConfigModel : NSObject <YYModel>
@property (nonatomic, strong, nullable) TgDynamicParameter *dynamicParameter;
@property (nonatomic, copy) NSString *border;       ///< hotline
@property (nonatomic, copy) NSString *conjunction;  ///< appEmail
@property (nonatomic, assign) NSInteger urban;      ///< attributionTimeout
@property (nonatomic, copy) NSString *have;         ///< officialWebsiteUrl
@property (nonatomic, copy) NSString *hook;         ///< conditionsHref
@property (nonatomic, copy) NSString *countryside;  ///< agreementHref
@property (nonatomic, copy) NSString *registerOrLogin; ///< policyHref
@property (nonatomic, copy) NSString *seed;         ///< authHref
@property (nonatomic, copy) NSString *earn;         ///< qaHref
@property (nonatomic, copy) NSString *contactHref;
@property (nonatomic, copy) NSString *aboutHref;
@property (nonatomic, copy) NSString *nexus;        ///< desireHref
@property (nonatomic, copy) NSString *buryChannel;
@property (nonatomic, copy) NSString *bone;         ///< livenessDetectionMethod
@property (nonatomic, copy) NSString *mould;        ///< livenessDetectionProvider
@property (nonatomic, assign) NSInteger capacity;   ///< pushPerCount
@property (nonatomic, assign) NSInteger hit;        ///< pushMaxCount
@property (nonatomic, copy) NSString *reloanSelfCheckType;
@property (nonatomic, copy) NSString *garden;       ///< firstLoanOptionLine
@property (nonatomic, copy) NSString *former;       ///< customerRating / newCustomerRating
@property (nonatomic, assign) NSInteger installApp;  ///< isUpdateUserInfo
@property (nonatomic, copy) NSString *preposition;  ///< countryCode
@property (nonatomic, copy) NSString *cook;         ///< currencySymbol
@property (nonatomic, assign) NSInteger ceiling;    ///< isThirdAthena
@property (nonatomic, assign) NSInteger preceding;  ///< retrieveMobileContact
@property (nonatomic, copy) NSString *relativity;   ///< voiceAuth
@property (nonatomic, assign) NSInteger injury;     ///< appStatus
@property (nonatomic, copy) NSString *general;      ///< kycLink
@property (nonatomic, copy) NSString *productApplyLink;
@property (nonatomic, copy) NSString *owe;          ///< orderDetailsLink
@property (nonatomic, copy) NSString *passport;     ///< problemFeedbackLink
@property (nonatomic, copy) NSString *grand;        ///< updateBankLink
@property (nonatomic, copy) NSString *mostly;       ///< applicationSuccessLink
@property (nonatomic, copy) NSString *plane;        ///< bankCardInfoLink
@property (nonatomic, copy) NSString *overseas;     ///< aboutUsLink
@property (nonatomic, copy) NSString *vanish;       ///< feedbackGuidance
@property (nonatomic, copy) NSString *slope;        ///< h5ZipUrl
@end

@interface TgSystemConfigResponse : TgEnvelopeBase
@property (nonatomic, strong, nullable) TgSystemConfigModel *configData;
@end

#pragma mark - KYC

@interface TgKYCItem : NSObject <YYModel>
@property (nonatomic, copy) NSString *great;    ///< kycId
@property (nonatomic, assign) NSInteger compel; ///< kycSort
@property (nonatomic, copy) NSString *enforce;  ///< kycStatus
@property (nonatomic, assign) NSInteger impatient; ///< kycType
@end

@interface TgKYCStatusData : NSObject <YYModel>
@property (nonatomic, copy) NSArray<TgKYCItem *> *classical; ///< kycList
@end

@interface TgKYCStatusResponse : TgEnvelopeBase
@property (nonatomic, strong, nullable) TgKYCStatusData *kycData;
@end

@interface TgKYCButtonItem : NSObject <YYModel>
@property (nonatomic, assign) NSInteger buttonSort;
@property (nonatomic, copy) NSString *purchase; ///< buttonLabel
@property (nonatomic, copy) NSString *optional; ///< buttonKey
@end

@interface TgKYCFormItem : NSObject <YYModel>
@property (nonatomic, assign) NSInteger favourable; ///< itemType
@property (nonatomic, copy) NSArray<NSString *> *intend;  ///< rearPrompts
@property (nonatomic, copy) NSString *performance;       ///< itemCode
@property (nonatomic, copy) NSArray<TgKYCButtonItem *> *radio; ///< buttonList
@property (nonatomic, copy) NSString *large;            ///< itemName
@property (nonatomic, assign) NSInteger borrow;           ///< itemStatus
@property (nonatomic, copy) NSArray<NSString *> *squeeze; ///< frontPrompts
@property (nonatomic, assign) NSInteger itemSort;
@property (nonatomic, copy) NSString *keen;             ///< regularExpression
@property (nonatomic, copy, nullable) NSString *itemCommit;
@end

@interface TgKYCInitData : NSObject <YYModel>
@property (nonatomic, copy) NSString *great;    ///< kycId
@property (nonatomic, copy) NSArray<TgKYCFormItem *> *nevertheless; ///< kycItemList
@property (nonatomic, copy) NSString *impatient; ///< kycType
@end

@interface TgKYCInitResponse : TgEnvelopeBase
@property (nonatomic, strong, nullable) TgKYCInitData *kycInitData;
@end

#pragma mark - IFSC / Repay / KYC commit echo

@interface TgIfscData : NSObject <YYModel>
@property (nonatomic, copy) NSArray<NSString *> *list;
@end

@interface TgIfscResponse : TgEnvelopeBase
@property (nonatomic, strong, nullable) TgIfscData *ifscData;
@end

@interface TgIdCardEchoMap : NSObject <YYModel>
@property (nonatomic, strong) id cardNo;
@property (nonatomic, copy, nullable) NSString *matter; ///< name
@property (nonatomic, copy, nullable) NSString *gender;
@property (nonatomic, copy, nullable) NSString *birthday;
@end

@interface TgKycItemCommitData : NSObject <YYModel>
@property (nonatomic, strong, nullable) TgIdCardEchoMap *history; ///< echoMap
@property (nonatomic, copy, nullable) NSArray *nevertheless;      ///< kycItemList
@end

@interface TgKycItemCommitResponse : TgEnvelopeBase
@property (nonatomic, strong, nullable) TgKycItemCommitData *itemCommitData;
@end

@interface TgRepayConnectData : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSString *lest; ///< connect
@end

@interface TgRepayConnectResponse : TgEnvelopeBase
@property (nonatomic, strong, nullable) TgRepayConnectData *repayConnectData;
@end

#pragma mark - Product Term / List / State

@interface TgTermDetail : NSObject <YYModel>
@property (nonatomic, assign) NSInteger culture;  ///< loanTerm
@property (nonatomic, assign) NSInteger ill;        ///< showTerm
@property (nonatomic, assign) NSInteger realize;  ///< productTermUnit
@property (nonatomic, copy, nullable) NSString *pit;       ///< feeAmount
@property (nonatomic, copy, nullable) NSString *feather;   ///< taxAmount
@property (nonatomic, copy, nullable) NSString *minority;  ///< arrivalAmount
@property (nonatomic, copy, nullable) NSString *typist;    ///< interestAmount
@property (nonatomic, copy, nullable) NSString *indispensable; ///< repaymentAmount
@property (nonatomic, copy, nullable) NSString *postage;   ///< borrowingDate
@property (nonatomic, copy, nullable) NSString *unity;     ///< repaymentDate
@property (nonatomic, assign) double loanDayInterestRate;
@property (nonatomic, assign) NSInteger convert;  ///< EMITenure
@property (nonatomic, assign) NSInteger EMIs;
@property (nonatomic, copy, nullable) NSString *upright;   ///< EMIAmount
@property (nonatomic, copy, nullable) NSString *EMIRepayDate;
@property (nonatomic, copy, nullable) NSArray<TgProductTermItem *> *pair; ///< productTermItemList
@end

@interface TgAmountDetail : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSString *inch;  ///< loanAmount
@property (nonatomic, copy, nullable) NSArray<TgTermDetail *> *eighth; ///< termDetailList
@end

@interface TgCardInfo : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSString *comparison; ///< bindId
@property (nonatomic, copy, nullable) NSString *geometry;   ///< accountType
@property (nonatomic, copy, nullable) NSString *xRay;         ///< bankCode (JSON: X-ray)
@property (nonatomic, copy, nullable) NSString *effective;  ///< bankName
@property (nonatomic, copy, nullable) NSString *measure;    ///< accountNo
@property (nonatomic, copy, nullable) NSString *first;      ///< accountName
@property (nonatomic, copy, nullable) NSString *enquire;    ///< accountPhone
@property (nonatomic, copy, nullable) NSString *promise;    ///< currency
@end

@interface TgProductTermData : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSString *resistance; ///< productId
@property (nonatomic, copy, nullable) NSString *other;        ///< productName
@property (nonatomic, copy, nullable) NSString *green;        ///< productLogo
@property (nonatomic, assign) NSInteger realize;              ///< productTermUnit
@property (nonatomic, copy, nullable) NSString *lion;         ///< productHotline
@property (nonatomic, copy, nullable) NSArray<TgAmountDetail *> *nonsense; ///< amountDetailList
@property (nonatomic, copy, nullable) NSArray<TgCardInfo *> *superior;   ///< bankCardList
@end

@interface TgProductTermResponse : TgEnvelopeBase
@property (nonatomic, strong, nullable) TgProductTermData *productTermData;
@end

@interface TgProductLabelItem : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSString *specify;    ///< labelId
@property (nonatomic, copy, nullable) NSString *typewriter; ///< labelName
@end

@interface TgProductInfo : NSObject <YYModel>
@property (nonatomic, assign) NSInteger companyId;
@property (nonatomic, assign) NSInteger defaultLoanDayInterestRate;
@property (nonatomic, assign) NSInteger defaultLoanTerm;
@property (nonatomic, assign) NSInteger defaultTaxRate;
@property (nonatomic, copy, nullable) NSString *bold;       ///< highAmount
@property (nonatomic, copy, nullable) NSString *remote;     ///< highestTerm
@property (nonatomic, copy, nullable) NSString *inch;       ///< loanAmount
@property (nonatomic, copy, nullable) NSString *efficient;  ///< lowAmount
@property (nonatomic, copy, nullable) NSString *provided;   ///< lowestLoanInterestRate
@property (nonatomic, assign) NSInteger nature;
@property (nonatomic, copy, nullable) NSString *partnerId;
@property (nonatomic, copy, nullable) NSString *finger;     ///< productApplicantsNumber
@property (nonatomic, copy, nullable) NSString *resistance;   ///< productId
@property (nonatomic, copy, nullable) NSString *possession;  ///< productLabel
@property (nonatomic, copy, nullable) NSArray<TgProductLabelItem *> *flourish; ///< productLabelList
@property (nonatomic, copy, nullable) NSString *green;        ///< productLogo
@property (nonatomic, copy, nullable) NSString *other;        ///< productName
@property (nonatomic, assign) NSInteger productType;
@property (nonatomic, copy, nullable) NSString *reloanAmount;
/// Nested termV3 payload from dcRecommend (JSON key productTermV3Response).
@property (nonatomic, strong, nullable) TgProductTermData *productTermV3Response;
@end

@interface TgProductListData : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSArray<NSNumber *> *amountList;
@property (nonatomic, copy, nullable) NSArray<TgProductInfo *> *portrait; ///< productInfoList
@property (nonatomic, copy, nullable) NSArray<TgProductLabelItem *> *flourish; ///< productLabelList
@end

@interface TgProductListResponse : TgEnvelopeBase
@property (nonatomic, strong, nullable) TgProductListData *productData;
@end

#pragma mark - DcUpgrade submit

@interface TgDcUpgradeOrderItem : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSString *interpret; ///< orderId
@property (nonatomic, assign) NSInteger resign;            ///< isFirst
@property (nonatomic, assign) NSInteger easy;              ///< isWillingRepay
@end

@interface TgDcUpgradeSubmitData : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSArray<TgDcUpgradeOrderItem *> *list;
@end

@interface TgApplyAgainProduct : NSObject <YYModel>
@property (nonatomic, copy) NSString *inch;       ///< loanAmount
@property (nonatomic, copy) NSString *resistance; ///< productId
@property (nonatomic, copy, nullable) NSString *green; ///< productLogo
@property (nonatomic, copy) NSString *other;      ///< productName
@property (nonatomic, assign) NSInteger userType;
@end

@interface TgProductStateData : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSArray<TgApplyAgainProduct *> *nonsense; ///< amountDetailList
@end

@interface TgProductStateResponse : TgEnvelopeBase
@property (nonatomic, strong, nullable) TgProductStateData *productStateData;
@end

#pragma mark - Upload

@interface TgUploadSrcData : NSObject <YYModel>
@property (nonatomic, copy) NSString *bucket; ///< src
@end

NS_ASSUME_NONNULL_END
