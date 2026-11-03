//

//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TgOrderForgeOrigin) {
    TgOrderForgeOriginApplyPage = 0,
    TgOrderForgeOriginAutoHome,

    TgOrderForgeOriginOrderDetail,

    TgOrderForgeOriginOrderDetailReloan,
};

typedef void (^TgOrderForgeSuccessBlock)(NSString *orderId);
typedef void (^TgOrderForgeFailureBlock)(NSString * _Nullable message);
typedef void (^TgOrderForgeCancelBlock)(void);

@interface TgOrderForgeParams : NSObject

@property (nonatomic, copy) NSString *productId;
@property (nonatomic, copy) NSString *loanAmount;
@property (nonatomic, copy) NSString *showTerm;

@property (nonatomic, copy, nullable) NSString *orderType;

@end

@interface TgOrderForgeRelay : NSObject

+ (BOOL)tg_isRunning;

+ (void)tg_launchFullOrderWithParams:(TgOrderForgeParams *)params
                              hostVC:(UIViewController *)hostVC
                              origin:(TgOrderForgeOrigin)origin
                allowSecondaryPrompt:(BOOL)allowSecondaryPrompt
                             success:(nullable TgOrderForgeSuccessBlock)success
                             failure:(nullable TgOrderForgeFailureBlock)failure
                             cancelled:(nullable TgOrderForgeCancelBlock)cancelled;

+ (void)tg_resumeDataCaptureForOrderId:(NSString *)orderId
                                hostVC:(UIViewController *)hostVC
                                origin:(TgOrderForgeOrigin)origin
                allowSecondaryPrompt:(BOOL)allowSecondaryPrompt
                               success:(nullable TgOrderForgeSuccessBlock)success
                               failure:(nullable TgOrderForgeFailureBlock)failure
                             cancelled:(nullable TgOrderForgeCancelBlock)cancelled;

+ (void)tg_cancelCurrentFlow;

@end

NS_ASSUME_NONNULL_END
