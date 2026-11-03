//
//  TgLoanShellController.h
//

#import "TgHullController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TgLoanShellController : TgHullController

@property (nonatomic, assign, readonly) BOOL tg_pipelineDone;

+ (void)tg_requestScrollToFirstProduct;

- (void)tg_reloadSupHomeOnly;

- (void)tg_refreshAfterAuthComplete;

/// Push precise-recommend (dcRecommend).
- (void)tg_pushDcMatchRecommend;

@end

NS_ASSUME_NONNULL_END
