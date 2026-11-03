//

//

#import "SceneDelegate.h"
#import "AppDelegate.h"
#import "TgPersonaVault.h"
#import "TgWireConduit.h"
#import "TgTraceRelay.h"
#import "TgDockBarRelay.h"
#import "TgParcelRegistry.h"
#import "TgSignInController.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    (void)session; (void)connectionOptions;
    if (![scene isKindOfClass:[UIWindowScene class]]) return;

    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;

    BOOL signedIn = [TgPersonaVault shared].holderToken.length > 0;
    self.window.rootViewController = signedIn ? [self tg_mainRoot] : [self tg_signInRoot];
    [self.window makeKeyAndVisible];

    [TgWireConduit bootNetworkLayer:^(BOOL ok) {
        (void)ok;
        [TgTraceRelay emitAppLaunch];
    }];
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    (void)scene;
    AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
    if ([app isKindOfClass:[AppDelegate class]]) {
        [app tg_sceneDidBecomeActive];
    }
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    if (![ud boolForKey:TgMarkEverLaunched]) {
        [ud setBool:YES forKey:TgMarkEverLaunched];
        [ud synchronize];
        [TgTraceRelay emitFirstOpen];
    }
}

#pragma mark - Root switch

- (void)tg_switchToMainAnimated:(BOOL)animated {
    [self tg_replaceRoot:[self tg_mainRoot] animated:animated];
}

- (void)tg_switchToSignInAnimated:(BOOL)animated {
    [self tg_replaceRoot:[self tg_signInRoot] animated:animated];
}

- (UIViewController *)tg_mainRoot {
    return [TgDockBarRelay forgeDockShell];
}

- (UIViewController *)tg_signInRoot {
    TgSignInController *login = [[TgSignInController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:login];
    nav.navigationBarHidden = YES;
    return nav;
}

- (void)tg_replaceRoot:(UIViewController *)root animated:(BOOL)animated {
    if (!self.window || !root) return;
    if (!animated) {
        self.window.rootViewController = root;
        return;
    }
    UIView *snap = [self.window snapshotViewAfterScreenUpdates:YES];
    if (snap) {
        [root.view addSubview:snap];
    }
    self.window.rootViewController = root;
    if (snap) {
        [UIView animateWithDuration:0.28 animations:^{
            snap.alpha = 0;
        } completion:^(BOOL finished) {
            [snap removeFromSuperview];
        }];
    }
}

@end
