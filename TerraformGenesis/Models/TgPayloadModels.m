//
//  TgPayloadModels.m
//

#import "TgPayloadModels.h"
@implementation TgLoginData
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"face": @"userId",
        @"highly": @"isRegister",
        @"rank": @"token"
    };
}
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    id uid = dic[@"userId"];
    if ([uid isKindOfClass:[NSNumber class]]) {
        self.face = [(NSNumber *)uid stringValue];
    } else if ([uid isKindOfClass:[NSString class]]) {
        self.face = uid;
    }
    return YES;
}
@end

@implementation TgLoginResponse
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"loginData": @"data"
    };
}
@end

@implementation TgOrderStatusCount
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"career": @"label",
        @"intellectual": @"orderStatus",
        @"interpret": @"orderId",
        @"resistance": @"productId"
    };
}
@end

@implementation TgAppProductBanner
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"expectation": @"relationId",
        @"region": @"bannerHref"
    };
}
@end

@implementation TgAppLabelBanner
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"expectation": @"relationId",
        @"region": @"bannerHref"
    };
}
@end

@implementation TgHomeData
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"elsewhere": @"appUserType",
        @"emergency": @"appProductBanner",
        @"fold": @"promptCopy",
        @"garden": @"firstLoanOptionLine",
        @"handsome": @"appLabelBanner",
        @"hire": @"loanSuccessRecordList",
        @"scholar": @"hasOrder",
        @"telescope": @"userStatus",
        @"utmost": @"downloadUrl"
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass { return @{@"emergency": [TgAppProductBanner class], @"handsome": [TgAppLabelBanner class]}; }
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    id amt = dic[@"maxApplyAmount"];
    if ([amt isKindOfClass:[NSNumber class]]) {
        self.maxApplyAmount = [(NSNumber *)amt stringValue];
    } else if ([amt isKindOfClass:[NSString class]]) {
        self.maxApplyAmount = amt;
    }
    return YES;
}
@end

@implementation TgHomeResponse
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"homeData": @"data"
    };
}
@end

@implementation TgUserInfoData
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"can": @"payAccountModifySwitch",
        @"elsewhere": @"appUserType",
        @"matter": @"name",
        @"node": @"desire",
        @"poisonous": @"smsSwitch",
        @"receiver": @"phone",
        @"sting": @"existsMobileContact",
        @"telescope": @"userStatus"
    };
}
@end

@implementation TgUserInfoResponse
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"trick": @"data"
    };
}
@end

@implementation TgOrderItem
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"enough": @"repayDate",
        @"face": @"userId",
        @"fierce": @"dueDate",
        @"inch": @"loanAmount",
        @"intellectual": @"orderStatus",
        @"interpret": @"orderId",
        @"other": @"productName",
        @"resistance": @"productId",
        @"resume": @"loanDate",
        @"tailor": @"applyDate"
    };
}
@end

@implementation TgOrderListData
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"vital": @"orderList"
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass { return @{@"vital": [TgOrderItem class]}; }
@end

@implementation TgOrderListResponse
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"trick": @"data"
    };
}
@end

@implementation TgProductTermItem
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"indispensable": @"repaymentAmount",
        @"inspire": @"interestAmountDue",
        @"wreck": @"principalAmountDue"
    };
}
@end

@implementation TgOrderProduct
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"green": @"productLogo",
        @"other": @"productName",
        @"resistance": @"productId"
    };
}
@end

@implementation TgOrderBankCard
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"comparison": @"bindId",
        @"effective": @"bankName",
        @"first": @"accountName",
        @"measure": @"accountNo",
        @"xRay": @"bankCode"
    };
}
@end

@implementation TgOrderDetail
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"ciphersh": @"dueExtensionFeeAmount",
        @"culture": @"loanTerm",
        @"exclude": @"ifExtension",
        @"feather": @"taxAmount",
        @"fierce": @"dueDate",
        @"husband": @"receiptAmount",
        @"ill": @"showTerm",
        @"inch": @"loanAmount",
        @"industry": @"loanTermUnit",
        @"intellectual": @"orderStatus",
        @"interpret": @"orderId",
        @"locate": @"riskDate",
        @"means": @"penaltyAmount",
        @"nationality": @"totalRepaymentAmount",
        @"pair": @"productTermItemList",
        @"pale": @"reductionAmount",
        @"pit": @"feeAmount",
        @"prison": @"penaltyDays",
        @"resident": @"payoutDate",
        @"specimen": @"repayExtensionFeeAmount",
        @"tailor": @"applyDate",
        @"typist": @"interestAmount",
        @"unity": @"repaymentDate",
        @"upright": @"EMIAmount",
        @"wire": @"alreadyRepaymentAmount"
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass { return @{@"pair": [TgProductTermItem class]}; }
@end

@implementation TgOrderDetailData
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"easy": @"isWillingRepay",
        @"hillside": @"orderDetail",
        @"invent": @"product",
        @"living": @"bankCard"
    };
}
@end

@implementation TgOrderDetailResponse
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"orderDetailData": @"data"
    };
}
@end

@implementation TgWithdrawnTermDetail
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"convert": @"EMITenure",
        @"culture": @"loanTerm",
        @"feather": @"taxAmount",
        @"ill": @"showTerm",
        @"indispensable": @"repaymentAmount",
        @"minority": @"arrivalAmount",
        @"pair": @"productTermItemList",
        @"pit": @"feeAmount",
        @"postage": @"borrowingDate",
        @"realize": @"productTermUnit",
        @"typist": @"interestAmount",
        @"unity": @"repaymentDate",
        @"upright": @"EMIAmount"
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass { return @{@"pair": [TgProductTermItem class]}; }
@end

@implementation TgWithdrawnAmountDetail
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"eighth": @"termDetailList",
        @"inch": @"loanAmount"
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass { return @{@"eighth": [TgWithdrawnTermDetail class]}; }
@end

@implementation TgWithdrawnBankCard
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"comparison": @"bindId",
        @"effective": @"bankName",
        @"enquire": @"accountPhone",
        @"first": @"accountName",
        @"geometry": @"accountType",
        @"measure": @"accountNo",
        @"promise": @"currency",
        @"xRay": @"bankCode"
    };
}
@end

@implementation TgWithdrawnOrderDetailData
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"green": @"productLogo",
        @"interpret": @"orderId",
        @"lion": @"productHotline",
        @"nonsense": @"amountDetailList",
        @"other": @"productName",
        @"realize": @"productTermUnit",
        @"resistance": @"productId",
        @"superior": @"bankCardList"
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass { return @{@"nonsense": [TgWithdrawnAmountDetail class], @"superior": [TgWithdrawnBankCard class]}; }
@end

@implementation TgWithdrawnOrderDetailResponse
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"withdrawnOrderDetailData": @"data"
    };
}
@end

@implementation TgBankCardInfo
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"bdhwka": @"creditCard",
        @"comparison": @"bindId",
        @"effective": @"bankName",
        @"enquire": @"accountPhone",
        @"first": @"accountName",
        @"geometry": @"accountType",
        @"measure": @"accountNo",
        @"procedure": @"ifscCode",
        @"promise": @"currency",
        @"xRay": @"bankCode"
    };
}
@end

@implementation TgBankCardListData
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"superior": @"bankCardList"
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass { return @{@"superior": [TgBankCardInfo class]}; }
@end

@implementation TgBankCardListResponse
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"trick": @"data"
    };
}
@end

@implementation TgDynamicParameter
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"cojsemin": @"contactCount",
        @"customerH5": @"CustomerH5"
    };
}
@end

@implementation TgSystemConfigModel
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"bone": @"livenessDetectionMethod",
        @"border": @"hotline",
        @"capacity": @"pushPerCount",
        @"ceiling": @"isThirdAthena",
        @"conjunction": @"appEmail",
        @"cook": @"currencySymbol",
        @"countryside": @"agreementHref",
        @"earn": @"qaHref",
        @"former": @"newCustomerRating",
        @"garden": @"firstLoanOptionLine",
        @"general": @"kycLink",
        @"grand": @"updateBankLink",
        @"have": @"officialWebsiteUrl",
        @"hit": @"pushMaxCount",
        @"hook": @"conditionsHref",
        @"injury": @"appStatus",
        @"installApp": @"isUpdateUserInfo",
        @"mostly": @"applicationSuccessLink",
        @"mould": @"livenessDetectionProvider",
        @"nexus": @"desireHref",
        @"overseas": @"aboutUsLink",
        @"owe": @"orderDetailsLink",
        @"passport": @"problemFeedbackLink",
        @"plane": @"bankCardInfoLink",
        @"preceding": @"retrieveMobileContact",
        @"preposition": @"countryCode",
        @"registerOrLogin": @"policyHref",
        @"relativity": @"voiceAuth",
        @"seed": @"authHref",
        @"slope": @"h5ZipUrl",
        @"urban": @"attributionTimeout",
        @"vanish": @"feedbackGuidance"
    };
}
@end

@implementation TgSystemConfigResponse
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"configData": @"data"
    };
}
@end

@implementation TgKYCItem
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"compel": @"kycSort",
        @"enforce": @"kycStatus",
        @"great": @"kycId",
        @"impatient": @"kycType"
    };
}
@end

@implementation TgKYCStatusData
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"classical": @"kycList"
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass { return @{@"classical": [TgKYCItem class]}; }
@end

@implementation TgKYCStatusResponse
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"kycData": @"data"
    };
}
@end

@implementation TgKYCButtonItem
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"optional": @"buttonKey",
        @"purchase": @"buttonLabel"
    };
}
@end

@implementation TgKYCFormItem
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"borrow": @"itemStatus",
        @"favourable": @"itemType",
        @"intend": @"rearPrompts",
        @"keen": @"regularExpression",
        @"large": @"itemName",
        @"performance": @"itemCode",
        @"radio": @"buttonList",
        @"squeeze": @"frontPrompts"
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass { return @{@"radio": [TgKYCButtonItem class]}; }
@end

@implementation TgKYCInitData
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"great": @"kycId",
        @"impatient": @"kycType",
        @"nevertheless": @"kycItemList"
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass { return @{@"nevertheless": [TgKYCFormItem class]}; }
@end

@implementation TgKYCInitResponse
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"kycInitData": @"data"
    };
}
@end

@implementation TgIfscData
@end

@implementation TgIfscResponse
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"ifscData": @"data"
    };
}
@end

@implementation TgIdCardEchoMap
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"matter": @"name"
    };
}
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    id card = dic[@"cardNo"];
    if ([card isKindOfClass:[NSNumber class]]) {
        self.cardNo = [(NSNumber *)card stringValue];
    } else if ([card isKindOfClass:[NSString class]]) {
        self.cardNo = card;
    }
    return YES;
}
@end

@implementation TgKycItemCommitData
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"history": @"echoMap",
        @"nevertheless": @"kycItemList"
    };
}
@end

@implementation TgKycItemCommitResponse
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"itemCommitData": @"data"
    };
}
@end

@implementation TgRepayConnectData
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"lest": @"connect"
    };
}
@end

@implementation TgRepayConnectResponse
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"repayConnectData": @"data"
    };
}
@end

@implementation TgTermDetail
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"convert": @"EMITenure",
        @"culture": @"loanTerm",
        @"feather": @"taxAmount",
        @"ill": @"showTerm",
        @"indispensable": @"repaymentAmount",
        @"minority": @"arrivalAmount",
        @"pair": @"productTermItemList",
        @"pit": @"feeAmount",
        @"postage": @"borrowingDate",
        @"realize": @"productTermUnit",
        @"typist": @"interestAmount",
        @"unity": @"repaymentDate",
        @"upright": @"EMIAmount"
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass { return @{@"pair": [TgProductTermItem class]}; }
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    id emis = dic[@"EMIs"];
    if ([emis isKindOfClass:[NSString class]] || [emis isKindOfClass:[NSNumber class]]) {
        self.EMIs = (NSInteger)[emis integerValue];
    }
    id tenure = dic[@"EMITenure"];
    if (!tenure) tenure = dic[@"convert"];
    if ([tenure isKindOfClass:[NSString class]] || [tenure isKindOfClass:[NSNumber class]]) {
        self.convert = (NSInteger)[tenure integerValue];
    }
    return YES;
}
@end

@implementation TgAmountDetail
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"eighth": @"termDetailList",
        @"inch": @"loanAmount"
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass { return @{@"eighth": [TgTermDetail class]}; }
@end

@implementation TgCardInfo
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"comparison": @"bindId",
        @"effective": @"bankName",
        @"enquire": @"accountPhone",
        @"first": @"accountName",
        @"geometry": @"accountType",
        @"measure": @"accountNo",
        @"promise": @"currency",
        @"xRay": @"bankCode"
    };
}
@end

@implementation TgProductTermData
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"green": @"productLogo",
        @"lion": @"productHotline",
        @"nonsense": @"amountDetailList",
        @"other": @"productName",
        @"realize": @"productTermUnit",
        @"resistance": @"productId",
        @"superior": @"bankCardList"
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass { return @{@"nonsense": [TgAmountDetail class], @"superior": [TgCardInfo class]}; }
@end

@implementation TgProductTermResponse
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"productTermData": @"data"
    };
}
@end

@implementation TgProductLabelItem
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"specify": @"labelId",
        @"typewriter": @"labelName"
    };
}
@end

@implementation TgProductInfo
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"bold": @"highAmount",
        @"efficient": @"lowAmount",
        @"finger": @"productApplicantsNumber",
        @"flourish": @"productLabelList",
        @"green": @"productLogo",
        @"inch": @"loanAmount",
        @"other": @"productName",
        @"possession": @"productLabel",
        @"provided": @"lowestLoanInterestRate",
        @"remote": @"highestTerm",
        @"resistance": @"productId"
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass { return @{@"flourish": [TgProductLabelItem class], @"productTermV3Response": [TgProductTermData class]}; }
@end

@implementation TgProductListData
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"flourish": @"productLabelList",
        @"portrait": @"productInfoList"
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass { return @{@"portrait": [TgProductInfo class], @"flourish": [TgProductLabelItem class]}; }
@end

@implementation TgProductListResponse
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"productData": @"data"
    };
}
@end

@implementation TgDcUpgradeOrderItem
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"easy": @"isWillingRepay",
        @"interpret": @"orderId",
        @"resign": @"isFirst"
    };
}
@end

@implementation TgDcUpgradeSubmitData
+ (NSDictionary *)modelContainerPropertyGenericClass { return @{@"list": [TgDcUpgradeOrderItem class]}; }
@end

@implementation TgApplyAgainProduct
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"green": @"productLogo",
        @"inch": @"loanAmount",
        @"other": @"productName",
        @"resistance": @"productId"
    };
}
@end

@implementation TgProductStateData
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"nonsense": @"amountDetailList"
    };
}
+ (NSDictionary *)modelContainerPropertyGenericClass { return @{@"nonsense": [TgApplyAgainProduct class]}; }
@end

@implementation TgProductStateResponse
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"productStateData": @"data"
    };
}
@end

@implementation TgUploadSrcData
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"bucket": @"src"
    };
}
@end

