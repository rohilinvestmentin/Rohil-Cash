//
//  AppDelegate.m
//

#import "AppDelegate.h"
#import "TgParcelRegistry.h"
#import "TgTraceRelay.h"
#import <IQKeyboardManager/IQKeyboardManager.h>
#import <AdjustSdk/AdjustSdk.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AdSupport/AdSupport.h>
#import <Network/Network.h>

@interface AppDelegate ()
@property (nonatomic, strong, nullable) nw_path_monitor_t pathMonitor;
@property (nonatomic, assign) BOOL adjustBooted;
@property (nonatomic, assign) BOOL attChainStarted;
@property (nonatomic, assign) BOOL networkReadyForAtt;
@property (nonatomic, assign) BOOL attFlowHandled;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    (void)launchOptions;
    [self tg_setupKeyboard];
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [self tg_clearSessionMarks];
    [self tg_beginAttributionChain];
    return YES;
}

#pragma mark - Scene

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    (void)application; (void)options;
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}

#pragma mark - Keyboard

- (void)tg_setupKeyboard {
    IQKeyboardManager *mgr = [IQKeyboardManager sharedManager];
    mgr.enable = YES;
    mgr.shouldResignOnTouchOutside = YES;
    mgr.enableAutoToolbar = YES;
    mgr.keyboardDistanceFromTextField = 20.0;
    mgr.toolbarDoneBarButtonItemText = @"Done";
}

#pragma mark - Session marks

- (void)tg_clearSessionMarks {

}

#pragma mark - ATT + Adjust

- (void)tg_beginAttributionChain {
    if (self.attChainStarted) return;
    self.attChainStarted = YES;

    nw_path_monitor_t monitor = nw_path_monitor_create();
    self.pathMonitor = monitor;
    dispatch_queue_t queue = dispatch_queue_create("tg.path.monitor", DISPATCH_QUEUE_SERIAL);
    nw_path_monitor_set_queue(monitor, queue);
    __weak typeof(self) weakSelf = self;
    nw_path_monitor_set_update_handler(monitor, ^(nw_path_t path) {
        if (nw_path_get_status(path) != nw_path_status_satisfied) return;
        nw_path_monitor_cancel(monitor);
        weakSelf.pathMonitor = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                weakSelf.networkReadyForAtt = YES;
                [weakSelf tg_tryRunAttFlow];
            });
        });
    });
    nw_path_monitor_start(monitor);
}

- (void)tg_sceneDidBecomeActive {
    [self tg_tryRunAttFlow];
}

- (void)tg_tryRunAttFlow {
    if (!self.networkReadyForAtt || self.attFlowHandled) return;
    if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return;
    self.attFlowHandled = YES;
    [self tg_requestAttIfNeeded];
}

- (void)tg_bootAdjustOnce {
    if (self.adjustBooted) return;
    if (TgParcelAdjustToken.length == 0) return;
    ADJConfig *cfg = [[ADJConfig alloc] initWithAppToken:TgParcelAdjustToken environment:ADJEnvironmentProduction];
    [Adjust initSdk:cfg];
    self.adjustBooted = YES;
}

- (void)tg_requestAttIfNeeded {
    ATTrackingManagerAuthorizationStatus status = ATTrackingManager.trackingAuthorizationStatus;
    if (status == ATTrackingManagerAuthorizationStatusNotDetermined) {
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus s) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self tg_reportIdfaStatus:s];
                [self tg_bootAdjustOnce];
            });
        }];
        return;
    }
    [self tg_reportIdfaStatus:status];
    [self tg_bootAdjustOnce];
}

- (void)tg_reportIdfaStatus:(ATTrackingManagerAuthorizationStatus)status {
    BOOL granted = (status == ATTrackingManagerAuthorizationStatusAuthorized);
    [TgTraceRelay emitPermissionGrant:TgTraceSignalIdfaGrant deny:TgTraceSignalIdfaDeny granted:granted];
}

@end
