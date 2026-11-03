//

//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^TgReviewSubmitBlock)(NSInteger score);
typedef void (^TgReviewDismissBlock)(void);

@interface TgReviewGuideRelay : NSObject

+ (instancetype)shared;

+ (void)tg_storeAppUserType:(NSInteger)userType;
+ (NSInteger)tg_cachedAppUserType;

+ (void)tg_tryShowReviewGuideOnSubmit:(nullable TgReviewSubmitBlock)submit
                            onDismiss:(nullable TgReviewDismissBlock)dismiss;

+ (void)tg_tryShowReviewGuideForUserType:(NSInteger)userType
                                onSubmit:(nullable TgReviewSubmitBlock)submit
                               onDismiss:(nullable TgReviewDismissBlock)dismiss;

+ (void)tg_showThankYouPanelWithConfirm:(nullable void (^)(void))confirmAction;

@end

NS_ASSUME_NONNULL_END
