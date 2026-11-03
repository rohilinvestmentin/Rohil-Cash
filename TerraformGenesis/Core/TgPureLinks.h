//
//  TgPureLinks.h

//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TgPureLinks : NSObject

#pragma mark - API

+ (NSString *)apiBaseURL;

#pragma mark - 协议 / 联系我们

+ (NSString *)privacyPolicy;
+ (NSString *)serviceAgreement;
+ (NSString *)contactUs;
+ (NSString *)loanTerms;

#pragma mark - H5 业务页（原生未接 H5 时可为占位；不可从接口取）

+ (NSString *)kyc;
+ (NSString *)productApply;
+ (NSString *)orderDetail;
+ (NSString *)updateBank;
+ (NSString *)feedback;
+ (NSString *)applicationSuccess;

@end

NS_ASSUME_NONNULL_END
