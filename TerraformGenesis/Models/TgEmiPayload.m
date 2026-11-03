//
//  TgEmiPayload.m
//

#import "TgEmiPayload.h"
#import <math.h>

@implementation TgEmiInputBundle
@end

@implementation TgEmiResultBundle

+ (instancetype)bundleComputedFromInput:(TgEmiInputBundle *)input {
    TgEmiResultBundle *bundle = [[TgEmiResultBundle alloc] init];
    if (!input) return bundle;

    double principal = (double)input.amount;
    NSInteger months = input.durationYears * 12;
    if (months <= 0 || principal <= 0) return bundle;

    double monthlyRate = input.interestRatePercent / 12.0 / 100.0;
    double emi = 0;
    if (monthlyRate <= 0) {
        emi = principal / (double)months;
    } else {
        double factor = pow(1.0 + monthlyRate, (double)months);
        emi = principal * monthlyRate * factor / (factor - 1.0);
    }
    double totalPay = emi * (double)months;
    bundle.monthlyEmi = emi;
    bundle.totalPayment = totalPay;
    bundle.totalInterest = totalPay - principal;
    return bundle;
}

@end
