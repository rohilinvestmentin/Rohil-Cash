//
//  TgAutoOrderRelay.h
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class TgHomeData;
@class TgProductInfo;

NS_ASSUME_NONNULL_BEGIN

@interface TgAutoOrderRelay : NSObject

+ (instancetype)shared;

+ (BOOL)tg_shouldAutoOrderWithHomeData:(nullable TgHomeData *)homeData;

@property (nonatomic, assign, readonly) BOOL tg_isProcessing;
@property (nonatomic, assign, readonly) BOOL tg_awaitingUserRetry;

/// DC upgrade auto-order (docs 50 §3.6 / 40): dcRecommend → full select → userSubmitDcUpgrade.
/// productList is unused for DC path (kept for call-site compatibility).
- (BOOL)tg_checkAndExecuteWithHomeData:(nullable TgHomeData *)homeData
                           productList:(nullable NSArray<TgProductInfo *> *)productList
                                hostVC:(UIViewController *)hostVC
                         userInitiated:(BOOL)userInitiated;

- (void)tg_resetProcessing;

@end

NS_ASSUME_NONNULL_END
