//

//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^TgKycDocCameraFinishBlock)(UIImage * _Nullable image);

@interface TgKycDocCameraController : UIViewController

@property (nonatomic, copy, nullable) NSString *tg_sceneToken;
@property (nonatomic, copy, nullable) TgKycDocCameraFinishBlock tg_finishBlock;

+ (instancetype)controllerWithSceneToken:(nullable NSString *)sceneToken;

+ (void)presentFrom:(UIViewController *)host
        sceneToken:(nullable NSString *)sceneToken
        completion:(nullable TgKycDocCameraFinishBlock)completion;

@end

NS_ASSUME_NONNULL_END
