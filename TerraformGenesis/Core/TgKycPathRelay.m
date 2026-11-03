//

//

#import "TgKycPathRelay.h"
#import "TgDockBarRelay.h"
#import "TgLoanShellController.h"
#import "TgWireConduit.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"
#import "TgPulseOverlay.h"
#import "TgKycPersonController.h"
#import "TgKycWorkController.h"
#import "TgKycQuestionnaireController.h"
#import "TgKycLivenessController.h"
#import "TgKycIdentityController.h"
#import "TgKycTaxController.h"
#import "TgKycPayAccountController.h"
#import "TgKycEmergencyController.h"

static NSString * const kTgKycStatusPending = @"0";
static NSString * const kTgKycIdPersonal = @"personal";
static NSString * const kTgKycIdWork = @"work";
static NSString * const kTgKycIdQuestionnaire = @"questionnaire";
static NSString * const kTgKycIdLiveness = @"liveness";
static NSString * const kTgKycIdIdentity = @"identity";
static NSString * const kTgKycIdTax = @"tax";
static NSString * const kTgKycIdPayAccount = @"pay_account";
static NSString * const kTgKycIdUrgentContact = @"urgent_contact";
static NSTimeInterval const kTgKycPushDebounce = 0.5;

@interface TgKycPathRelay ()
@property (nonatomic, assign) BOOL fetchingStatus;
@property (nonatomic, assign) NSTimeInterval lastPushStamp;
@end

@implementation TgKycPathRelay

+ (instancetype)shared {
    static TgKycPathRelay *relay;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ relay = [[TgKycPathRelay alloc] init]; });
    return relay;
}

+ (void)startAuthFromNav:(UINavigationController *)nav {
    [self startAuthFromNav:nav targetVC:nil];
}

+ (void)startAuthFromNav:(UINavigationController *)nav targetVC:(UIViewController *)targetVC {
    if (!nav) return;
    TgKycPathRelay *relay = [self shared];
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    if (now - relay.lastPushStamp < kTgKycPushDebounce) return;

    if (targetVC) {
        relay.lastPushStamp = now;
        [self tg_pushVC:targetVC onNav:nav replaceTop:NO];
        return;
    }
    [relay tg_fetchStatusAndNavigate:nav replaceTop:NO];
}

+ (void)continueAfterCommitFromNav:(UINavigationController *)nav {
    if (!nav) return;
    TgKycPathRelay *relay = [self shared];
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    if (now - relay.lastPushStamp < kTgKycPushDebounce) return;
    [relay tg_fetchStatusAndNavigate:nav replaceTop:YES];
}

#pragma mark - Fetch

- (void)tg_fetchStatusAndNavigate:(UINavigationController *)nav replaceTop:(BOOL)replaceTop {
    if (self.fetchingStatus) return;
    self.fetchingStatus = YES;
    [[TgPulseOverlay shared] veilSpin:nil];

    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneKycStatus
                             signData:@{}
                           nonSignData:@{}
                              success:^(id data) {
        weakSelf.fetchingStatus = NO;
        [[TgPulseOverlay shared] veilDismiss];
        TgKYCStatusData *statusData = [TgKYCStatusData yy_modelWithJSON:data];
        [weakSelf tg_handleStatus:statusData nav:nav replaceTop:replaceTop];
    } failure:^{
        weakSelf.fetchingStatus = NO;
        [[TgPulseOverlay shared] veilDismiss];
        [[TgPulseOverlay shared] whisperLine:@"the system is occupied. Please retry after 2 minutes." duration:2.0];
    }];
}

- (void)tg_handleStatus:(TgKYCStatusData *)data
                    nav:(UINavigationController *)nav
             replaceTop:(BOOL)replaceTop {
    NSArray<TgKYCItem *> *list = data.classical;
    if (list.count == 0) {
        [self tg_returnToHomeFromNav:nav];
        return;
    }

    NSArray<TgKYCItem *> *sorted = [list sortedArrayUsingComparator:^NSComparisonResult(TgKYCItem *a, TgKYCItem *b) {
        if (a.compel == b.compel) return NSOrderedSame;
        return a.compel < b.compel ? NSOrderedAscending : NSOrderedDescending;
    }];

    TgKYCItem *next = nil;
    for (TgKYCItem *item in sorted) {
        if ([item.enforce isEqualToString:kTgKycStatusPending]) {
            next = item;
            break;
        }
    }
    if (!next) {
        [self tg_returnToHomeFromNav:nav];
        return;
    }

    UIViewController *vc = [[self class] tg_buildControllerForKycId:next.great];
    if (!vc) return;

    self.lastPushStamp = NSDate.date.timeIntervalSince1970;
    [[self class] tg_pushVC:vc onNav:nav replaceTop:replaceTop];
}

- (void)tg_returnToHomeFromNav:(UINavigationController *)nav {
    dispatch_async(dispatch_get_main_queue(), ^{
        UITabBarController *dock = nav.tabBarController;
        if (!dock) {
            [nav popToRootViewControllerAnimated:YES];
            return;
        }
        for (UIViewController *vc in dock.viewControllers) {
            if ([vc isKindOfClass:[UINavigationController class]]) {
                [(UINavigationController *)vc popToRootViewControllerAnimated:NO];
            }
        }
        dock.selectedIndex = TgDockTabIndexLoan;
        [[self class] tg_refreshLoanHomeAfterAuthComplete:dock];
    });
}

+ (void)tg_refreshLoanHomeAfterAuthComplete:(UITabBarController *)dock {
    if (dock.viewControllers.count <= TgDockTabIndexLoan) return;
    UIViewController *loanNavObj = dock.viewControllers[TgDockTabIndexLoan];
    if (![loanNavObj isKindOfClass:[UINavigationController class]]) return;
    UINavigationController *loanNav = (UINavigationController *)loanNavObj;
    UIViewController *root = loanNav.viewControllers.firstObject;
    if ([root isKindOfClass:[TgLoanShellController class]]) {
        [(TgLoanShellController *)root tg_refreshAfterAuthComplete];
    }
}

#pragma mark - Mapping

+ (UIViewController *)tg_buildControllerForKycId:(NSString *)kycId {
    NSString *key = [kycId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (key.length == 0) return nil;

    if ([key isEqualToString:kTgKycIdPersonal]) return [[TgKycPersonController alloc] init];
    if ([key isEqualToString:kTgKycIdWork]) return [[TgKycWorkController alloc] init];
    if ([key isEqualToString:kTgKycIdQuestionnaire]) return [[TgKycQuestionnaireController alloc] init];
    if ([key isEqualToString:kTgKycIdLiveness]) return [[TgKycLivenessController alloc] init];
    if ([key isEqualToString:kTgKycIdIdentity]) return [[TgKycIdentityController alloc] init];
    if ([key isEqualToString:kTgKycIdTax]) return [[TgKycTaxController alloc] init];
    if ([key isEqualToString:kTgKycIdPayAccount]) return [[TgKycPayAccountController alloc] init];
    if ([key isEqualToString:kTgKycIdUrgentContact]) return [[TgKycEmergencyController alloc] init];
    return nil;
}

+ (void)tg_pushVC:(UIViewController *)vc onNav:(UINavigationController *)nav replaceTop:(BOOL)replaceTop {
    vc.hidesBottomBarWhenPushed = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (replaceTop && nav.viewControllers.count > 1) {
            NSMutableArray *stack = nav.viewControllers.mutableCopy;
            [stack removeLastObject];
            [stack addObject:vc];
            [nav setViewControllers:stack animated:YES];
        } else {
            [nav pushViewController:vc animated:YES];
        }
    });
}

@end
