//

//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TgKycFaceCaptureRelay : NSObject

@property (nonatomic, weak, nullable) UIView *tg_previewHost;

- (void)tg_prepareSession;
- (void)tg_prepareSessionWithCompletion:(void (^_Nullable)(BOOL success))completion;
- (void)tg_startRunning;
- (void)tg_startRunningWithCompletion:(void (^_Nullable)(BOOL success))completion;
- (void)tg_stopRunning;
- (void)tg_updatePreviewLayout;
- (void)tg_setPreviewHidden:(BOOL)hidden;

- (BOOL)tg_isSessionRunning;

- (void)tg_capturePhoto:(void (^)(UIImage * _Nullable image))completion;

@end

NS_ASSUME_NONNULL_END
