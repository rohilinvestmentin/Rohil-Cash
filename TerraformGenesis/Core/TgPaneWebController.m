//
//  TgPaneWebController.m
//

#import "TgPaneWebController.h"
#import "TgPulseOverlay.h"
#import <Masonry/Masonry.h>
#import <WebKit/WebKit.h>

static NSString * const kTgPaneDefaultTitle = @"Web Page";
static NSString * const kTgPaneLoadFailHint = @"Unable to open this page.";
static NSString * const kTgPaneSchemeFailHint = @"Please install the application before continuing.";
static NSString * const kTgPaneKVOProgress = @"estimatedProgress";

@interface TgPaneWebController () <WKNavigationDelegate>
@property (nonatomic, copy) NSURL *tg_pageURL;
@property (nonatomic, copy, nullable) NSString *tg_navTitleText;
@property (nonatomic, strong) WKWebView *tg_webView;
@property (nonatomic, strong) UIProgressView *tg_progressView;
@property (nonatomic, assign) BOOL tg_observingProgress;
@end

@implementation TgPaneWebController

- (instancetype)initWithPageURL:(NSURL *)pageURL navTitle:(NSString *)title {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _tg_pageURL = pageURL;
        _tg_navTitleText = title.length > 0 ? [title copy] : kTgPaneDefaultTitle;
    }
    return self;
}

- (instancetype)initWithPageURLString:(NSString *)urlString navTitle:(NSString *)title {
    return [self initWithPageURL:[self.class tg_normalizedURLFromString:urlString] navTitle:title];
}

- (void)dealloc {
    if (_tg_observingProgress) {
        [_tg_webView removeObserver:self forKeyPath:kTgPaneKVOProgress];
        _tg_observingProgress = NO;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tg_backdropStyle = TgHullBackdropStylePlain;
    [self tg_setNavTitle:self.tg_navTitleText];

    WKWebViewConfiguration *cfg = [[WKWebViewConfiguration alloc] init];
    cfg.allowsInlineMediaPlayback = YES;
    cfg.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;

    self.tg_webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:cfg];
    self.tg_webView.navigationDelegate = self;
    self.tg_webView.backgroundColor = UIColor.clearColor;
    self.tg_webView.opaque = NO;
    [self.view addSubview:self.tg_webView];

    self.tg_progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    self.tg_progressView.progressTintColor = [UIColor colorWithRed:24/255.0 green:32/255.0 blue:64/255.0 alpha:1];
    self.tg_progressView.trackTintColor = UIColor.clearColor;
    self.tg_progressView.hidden = YES;
    [self.view addSubview:self.tg_progressView];

    [self.tg_progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset([self tg_contentTopBelowNavigation]);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(2);
    }];
    [self.tg_webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_progressView.mas_bottom);
        make.left.right.bottom.equalTo(self.view);
    }];

    [self.tg_webView addObserver:self forKeyPath:kTgPaneKVOProgress options:NSKeyValueObservingOptionNew context:nil];
    self.tg_observingProgress = YES;

    [self tg_reloadPage];
}

#pragma mark - Load

- (void)tg_reloadPage {
    if (!self.tg_pageURL) {
        [[TgPulseOverlay shared] whisperLine:kTgPaneLoadFailHint duration:2.0];
        return;
    }
    [[TgPulseOverlay shared] veilSpin];
    self.tg_progressView.hidden = NO;
    self.tg_progressView.progress = 0;
    [self.tg_webView loadRequest:[NSURLRequest requestWithURL:self.tg_pageURL]];
}

+ (NSURL *)tg_normalizedURLFromString:(NSString *)urlString {
    NSString *trimmed = [urlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) return nil;
    if (![trimmed hasPrefix:@"http://"] && ![trimmed hasPrefix:@"https://"]) {
        trimmed = [@"https://" stringByAppendingString:trimmed];
    }
    return [NSURL URLWithString:trimmed];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if (object == self.tg_webView && [keyPath isEqualToString:kTgPaneKVOProgress]) {
        float progress = self.tg_webView.estimatedProgress;
        self.tg_progressView.progress = progress;
        if (progress >= 1.0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.tg_progressView.hidden = YES;
                self.tg_progressView.progress = 0;
            });
        } else {
            self.tg_progressView.hidden = NO;
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    (void)webView; (void)navigation;
    self.tg_progressView.hidden = NO;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    (void)navigation;
    [[TgPulseOverlay shared] veilDismiss];
    if (self.tg_followsDocumentTitle && webView.title.length > 0) {
        [self tg_setNavTitle:webView.title];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    (void)webView; (void)navigation; (void)error;
    [self tg_handleLoadFailure];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    (void)webView; (void)navigation; (void)error;
    [self tg_handleLoadFailure];
}

- (void)tg_handleLoadFailure {
    [[TgPulseOverlay shared] veilDismiss];
    self.tg_progressView.hidden = YES;
    self.tg_progressView.progress = 0;
    [[TgPulseOverlay shared] whisperLine:kTgPaneLoadFailHint duration:2.0];
}

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    if (!url) {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    NSString *urlString = url.absoluteString;
    if ([urlString hasPrefix:@"http://"] || [urlString hasPrefix:@"https://"]) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    decisionHandler(WKNavigationActionPolicyCancel);
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
        if (!success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[TgPulseOverlay shared] whisperLine:kTgPaneSchemeFailHint duration:2.0];
            });
        }
    }];
}

@end
