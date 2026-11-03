//

//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TgEmiInputBundle : NSObject
@property (nonatomic, assign) NSInteger amount;
@property (nonatomic, assign) NSInteger durationYears;
@property (nonatomic, assign) NSInteger interestRatePercent;
@end

@interface TgEmiResultBundle : NSObject
@property (nonatomic, assign) double monthlyEmi;
@property (nonatomic, assign) double totalPayment;
@property (nonatomic, assign) double totalInterest;

+ (instancetype)bundleComputedFromInput:(TgEmiInputBundle *)input;
@end

NS_ASSUME_NONNULL_END
