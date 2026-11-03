//
//  SceneDelegate.h
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>

@property (strong, nonatomic, nullable) UIWindow *window;

- (void)tg_switchToMainAnimated:(BOOL)animated;
- (void)tg_switchToSignInAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
