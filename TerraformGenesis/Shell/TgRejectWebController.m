//
//  TgRejectWebController.m
//

#import "TgRejectWebController.h"
#import "TgHostRelay.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"
#import "TgPersonaVault.h"
#import "TgPolicyVault.h"
#import "TgPulseOverlay.h"
#import "TgSensorLattice.h"
#import "TgTraceRelay.h"
#import <Masonry/Masonry.h>
#import <WebKit/WebKit.h>

static NSString * const kTgRejectHandlerName = @"iosHandler";
static NSString * const kTgRejectNavTitle = @"Accurate Recommendation";
static NSString * const kTgRejectLoadFailHint = @"Unable to open this page.";
static NSTimeInterval const kTgRejectLoadingMaxSeconds = 5.0;

#pragma mark - Weak script handler

@interface TgRejectScriptProxy : NSObject <WKScriptMessageHandler>
@property (nonatomic, weak) id<WKScriptMessageHandler> tg_target;
@end

@implementation TgRejectScriptProxy
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    [self.tg_target userContentController:userContentController didReceiveScriptMessage:message];
}
@end

#pragma mark - Controller

@interface TgRejectWebController () <WKNavigationDelegate, WKScriptMessageHandler>
@property (nonatomic, copy) NSString *tg_rejectURLString;
@property (nonatomic, strong) WKWebView *tg_webView;
@property (nonatomic, strong) TgRejectScriptProxy *tg_scriptProxy;
@property (nonatomic, assign) BOOL tg_didInjectRejectData;
@property (nonatomic, assign) BOOL tg_loadingDismissed;
@end

@implementation TgRejectWebController

- (instancetype)initWithRejectH5URLString:(NSString *)urlString {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _tg_rejectURLString = [urlString copy] ?: @"";
        self.tg_backdropStyle = TgHullBackdropStylePlain;
        self.tg_showsBackButton = YES;
    }
    return self;
}

- (void)dealloc {
    [self.tg_webView.configuration.userContentController removeScriptMessageHandlerForName:kTgRejectHandlerName];
}

+ (nullable NSString *)tg_cachedRejectH5URLString {
    NSString *raw = [[TgPolicyVault shared] currentManifest].dynamicParameter.rejectH5;
    NSString *trimmed = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    return trimmed.length > 0 ? trimmed : nil;
}

+ (BOOL)tg_tryPushFromNav:(UINavigationController *)nav unavailableToast:(NSString *)unavailableToast {
    if (!nav) return NO;
    NSString *url = [self tg_cachedRejectH5URLString];
    if (url.length == 0) {
        NSString *toast = [unavailableToast stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
        if (toast.length > 0) {
            [[TgPulseOverlay shared] whisperLine:toast];
        }
        return NO;
    }
    TgRejectWebController *vc = [[TgRejectWebController alloc] initWithRejectH5URLString:url];
    vc.hidesBottomBarWhenPushed = YES;
    [nav setNavigationBarHidden:NO animated:YES];
    [nav pushViewController:vc animated:YES];
    return YES;
}

+ (BOOL)tg_tryReplaceTopFromNav:(UINavigationController *)nav {
    if (!nav) return NO;
    NSString *url = [self tg_cachedRejectH5URLString];
    if (url.length == 0) return NO;
    TgRejectWebController *vc = [[TgRejectWebController alloc] initWithRejectH5URLString:url];
    vc.hidesBottomBarWhenPushed = YES;
    NSMutableArray *stack = [nav.viewControllers mutableCopy] ?: [NSMutableArray array];
    if (stack.count > 0) {
        [stack removeLastObject];
    }
    [stack addObject:vc];
    [nav setNavigationBarHidden:NO animated:YES];
    [nav setViewControllers:stack animated:YES];
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self tg_setNavTitle:kTgRejectNavTitle];

    TgRejectScriptProxy *proxy = [[TgRejectScriptProxy alloc] init];
    proxy.tg_target = self;
    self.tg_scriptProxy = proxy;

    WKUserContentController *ucc = [[WKUserContentController alloc] init];
    [ucc addScriptMessageHandler:proxy name:kTgRejectHandlerName];

    WKWebViewConfiguration *cfg = [[WKWebViewConfiguration alloc] init];
    cfg.userContentController = ucc;
    cfg.allowsInlineMediaPlayback = YES;
    cfg.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;

    self.tg_webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:cfg];
    self.tg_webView.navigationDelegate = self;
    self.tg_webView.backgroundColor = UIColor.clearColor;
    self.tg_webView.opaque = NO;
    self.tg_webView.allowsBackForwardNavigationGestures = YES;
    self.tg_webView.customUserAgent = [TgSensorLattice weaveAgentString];
    [self.view addSubview:self.tg_webView];

    [self.tg_webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset([self tg_contentTopBelowNavigation]);
        make.left.right.bottom.equalTo(self.view);
    }];

    [self tg_startLoading];
}

#pragma mark - Load

- (void)tg_startLoading {
    NSURL *url = [self tg_normalizedURL];
    if (!url) {
        [[TgPulseOverlay shared] whisperLine:kTgRejectLoadFailHint duration:2.0];
        return;
    }
    self.tg_loadingDismissed = NO;
    [[TgPulseOverlay shared] veilSpin];
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kTgRejectLoadingMaxSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf tg_endLoading];
    });
    [self.tg_webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (nullable NSURL *)tg_normalizedURL {
    NSString *trimmed = [self.tg_rejectURLString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) return nil;
    if (![trimmed hasPrefix:@"http://"] && ![trimmed hasPrefix:@"https://"]) {
        trimmed = [@"https://" stringByAppendingString:trimmed];
    }
    return [NSURL URLWithString:trimmed];
}

- (void)tg_endLoading {
    if (self.tg_loadingDismissed) return;
    self.tg_loadingDismissed = YES;
    [[TgPulseOverlay shared] veilDismiss];
}

#pragma mark - rejectData

- (void)tg_injectRejectDataIfNeeded {
    if (self.tg_didInjectRejectData) return;
    self.tg_didInjectRejectData = YES;

    NSString *baseUrl = [TgHostRelay shared].activeHost ?: @"";
    NSDictionary *payload = @{
        @"appId": TgParcelClientAppId ?: @"",
        @"salt": TgParcelSignSalt ?: @"",
        @"mobile": [TgPersonaVault shared].holderMobile ?: @"",
        @"baseUrl": baseUrl,
        @"userId": [TgPersonaVault shared].holderId ?: @"",
        @"token": [TgPersonaVault shared].holderToken ?: @""
    };
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    NSString *json = jsonData ? [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] : @"{}";
    NSString *escaped = [self tg_escapeForJSSingleQuotedString:json];
    NSString *script = [NSString stringWithFormat:@"rejectData('%@')", escaped];
    [self.tg_webView evaluateJavaScript:script completionHandler:nil];
}

- (NSString *)tg_escapeForJSSingleQuotedString:(NSString *)raw {
    if (raw.length == 0) return @"";
    NSMutableString *s = [raw mutableCopy];
    [s replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0, s.length)];
    [s replaceOccurrencesOfString:@"'" withString:@"\\'" options:0 range:NSMakeRange(0, s.length)];
    [s replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(0, s.length)];
    [s replaceOccurrencesOfString:@"\r" withString:@"\\r" options:0 range:NSMakeRange(0, s.length)];
    [s replaceOccurrencesOfString:@"\u2028" withString:@"\\u2028" options:0 range:NSMakeRange(0, s.length)];
    [s replaceOccurrencesOfString:@"\u2029" withString:@"\\u2029" options:0 range:NSMakeRange(0, s.length)];
    return s;
}

#pragma mark - iosHandler

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    (void)userContentController;
    if (![message.name isEqualToString:kTgRejectHandlerName]) return;
    NSString *body = nil;
    if ([message.body isKindOfClass:[NSString class]]) {
        body = (NSString *)message.body;
    } else if (message.body) {
        body = [NSString stringWithFormat:@"%@", message.body];
    }
    [self tg_handleThirdURLBody:body];
}

- (void)tg_handleThirdURLBody:(NSString *)body {
    NSString *raw = [body stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (raw.length == 0) return;
    if (![raw containsString:@"thirdUrl="]) return;

    NSString *parsed = [raw stringByReplacingOccurrencesOfString:@"thirdUrl=" withString:@""];
    parsed = [parsed stringByReplacingOccurrencesOfString:@"type=" withString:@""];
    NSArray<NSString *> *parts = [parsed componentsSeparatedByString:@"&"];
    NSString *urlString = parts.count > 0 ? parts[0] : @"";
    NSString *remark = parts.count > 1 ? parts[1] : @"NULL";
    remark = [remark stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (remark.length == 0) remark = @"NULL";

    [TgTraceRelay emitSignal:TgTraceSignalRejectExternalOpen
                     content:nil
                     remark1:remark
                     remark2:nil
                     remark3:nil];

    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return;
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    (void)webView; (void)navigation;
    [self tg_endLoading];
    [self tg_injectRejectDataIfNeeded];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    (void)webView; (void)navigation; (void)error;
    [self tg_endLoading];
    [[TgPulseOverlay shared] whisperLine:kTgRejectLoadFailHint duration:2.0];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    (void)webView; (void)navigation; (void)error;
    [self tg_endLoading];
}

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    (void)webView;
    NSURL *url = navigationAction.request.URL;
    if (!url) {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    NSString *urlString = url.absoluteString ?: @"";
    if ([urlString hasPrefix:@"http"] || [urlString hasPrefix:@"about:blank"]) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    decisionHandler(WKNavigationActionPolicyCancel);
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

@end
