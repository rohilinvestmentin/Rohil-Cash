//
//  TgPulseOverlay.m
//

#import "TgPulseOverlay.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>

@interface TgPulseOverlay ()
@property (nonatomic, strong, nullable) UIWindow *toastHostWindow;
@property (nonatomic, weak, nullable) UIView *activeLoadingMask;
@end

@implementation TgPulseOverlay

+ (instancetype)shared {
    static TgPulseOverlay *overlay;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ overlay = [[TgPulseOverlay alloc] init]; });
    return overlay;
}

- (void)whisperLine:(NSString *)message {
    [self whisperLine:message duration:2.0];
}

- (void)whisperLine:(NSString *)message duration:(NSTimeInterval)duration {
    [self onMain:^{
        NSString *raw = message.length > 0 ? message : @"";
        NSString *text = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (text.length == 0) return;
        UIView *host = [self toastRootView] ?: [self pickHostWindow].rootViewController.view;
        if (!host) return;

        [[host viewWithTag:0x7A3C01] removeFromSuperview];

        UIView *shell = [[UIView alloc] init];
        shell.tag = 0x7A3C01;
        shell.alpha = 0;
        shell.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.78];
        shell.layer.cornerRadius = 10;
        shell.clipsToBounds = YES;
        shell.userInteractionEnabled = NO;
        shell.layer.zPosition = 9999;

        UILabel *caption = [[UILabel alloc] init];
        caption.text = text;
        caption.textColor = UIColor.whiteColor;
        caption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
        caption.numberOfLines = 0;
        caption.textAlignment = NSTextAlignmentCenter;

        [shell addSubview:caption];
        [host addSubview:shell];

        CGFloat maxW = host.bounds.size.width - 48;
        CGSize textSize = [caption sizeThatFits:CGSizeMake(maxW - 24, CGFLOAT_MAX)];
        CGFloat w = MIN(maxW, MAX(120, textSize.width + 24));
        CGFloat h = MAX(44, textSize.height + 20);
        shell.frame = CGRectMake((host.bounds.size.width - w) / 2, (host.bounds.size.height - h) / 2, w, h);
        caption.frame = CGRectMake(12, 10, w - 24, h - 20);

        [UIView animateWithDuration:0.25 animations:^{ shell.alpha = 1; }];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MAX(0.1, duration) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!shell.superview) return;
            [UIView animateWithDuration:0.25 animations:^{
                shell.alpha = 0;
            } completion:^(BOOL finished) {
                [shell removeFromSuperview];
                [self retireToastHostIfIdle];
            }];
        });
    }];
}

- (void)veilSpin {
    [self veilSpin:nil];
}

- (void)veilSpin:(NSString *)hint {
    [self onMain:^{
        UIWindow *window = [self pickHostWindow];
        if (!window) return;
        [self.activeLoadingMask removeFromSuperview];
        [[window viewWithTag:0x7A3C02] removeFromSuperview];

        UIView *mask = [[UIView alloc] initWithFrame:window.bounds];
        mask.tag = 0x7A3C02;
        mask.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        mask.alpha = 0;
        mask.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25];
        mask.userInteractionEnabled = YES;

        NSString *hintRaw = hint.length > 0 ? hint : @"";
        NSString *hintText = [hintRaw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        BOOL hasHint = hintText.length > 0;

        UIView *panel = [[UIView alloc] init];
        panel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.78];
        panel.layer.cornerRadius = 12;
        panel.clipsToBounds = YES;

        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
        spinner.color = UIColor.whiteColor;
        spinner.hidesWhenStopped = NO;
        [panel addSubview:spinner];

        UILabel *caption = nil;
        if (hasHint) {
            caption = [[UILabel alloc] init];
            caption.text = hintText;
            caption.font = [UIFont tg_meshGlyphWithSize:13 weight:UIFontWeightRegular];
            caption.textColor = UIColor.whiteColor;
            caption.textAlignment = NSTextAlignmentCenter;
            caption.numberOfLines = 2;
            [panel addSubview:caption];
        }

        [mask addSubview:panel];
        [window addSubview:mask];

        [panel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(mask);
        }];
        if (caption) {
            [panel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.mas_greaterThanOrEqualTo(120);
                make.width.mas_lessThanOrEqualTo(220);
            }];
            [spinner mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(panel).offset(20);
                make.centerX.equalTo(panel);
            }];
            [caption mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(spinner.mas_bottom).offset(12);
                make.left.equalTo(panel).offset(12);
                make.right.equalTo(panel).offset(-12);
                make.bottom.equalTo(panel).offset(-16);
            }];
        } else {
            [panel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.height.mas_equalTo(100);
            }];
            [spinner mas_makeConstraints:^(MASConstraintMaker *make) {
                make.center.equalTo(panel);
            }];
        }

        [spinner startAnimating];
        self.activeLoadingMask = mask;
        [UIView animateWithDuration:0.2 animations:^{ mask.alpha = 1; }];
    }];
}

- (void)veilDismiss {
    [self onMain:^{
        NSMutableArray<UIView *> *targets = [NSMutableArray array];
        if (self.activeLoadingMask) {
            [targets addObject:self.activeLoadingMask];
        } else {
            for (UIWindow *w in [self allHostWindows]) {
                UIView *v = [w viewWithTag:0x7A3C02];
                if (v) [targets addObject:v];
            }
        }
        if (targets.count == 0) return;
        for (UIView *loading in targets) {
            [UIView animateWithDuration:0.2 animations:^{
                loading.alpha = 0;
            } completion:^(BOOL finished) {
                [loading removeFromSuperview];
            }];
        }
        self.activeLoadingMask = nil;
    }];
}

#pragma mark - Window

- (UIWindow *)pickHostWindow {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState != UISceneActivationStateForegroundActive) continue;
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        UIWindowScene *ws = (UIWindowScene *)scene;
        for (UIWindow *w in ws.windows) {
            if (w.isKeyWindow && [self isEligible:w]) return w;
        }
        for (UIWindow *w in ws.windows) {
            if ([self isEligible:w]) return w;
        }
    }
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *w in ((UIWindowScene *)scene).windows) {
            if ([self isEligible:w]) return w;
        }
    }
    return nil;
}

- (NSArray<UIWindow *> *)allHostWindows {
    NSMutableArray *arr = [NSMutableArray array];
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *w in ((UIWindowScene *)scene).windows) {
            if ([self isEligible:w]) [arr addObject:w];
        }
    }
    return arr;
}

- (BOOL)isEligible:(UIWindow *)window {
    return window.rootViewController != nil && window.bounds.size.width >= 100 && window.bounds.size.height >= 100;
}

- (UIWindowScene *)activeScene {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
            return (UIWindowScene *)scene;
        }
    }
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) return (UIWindowScene *)scene;
    }
    return nil;
}

- (UIView *)toastRootView {
    return [self obtainToastHostWindow].rootViewController.view;
}

- (UIWindow *)obtainToastHostWindow {
    if (self.toastHostWindow && self.toastHostWindow.windowScene) {
        self.toastHostWindow.hidden = NO;
        return self.toastHostWindow;
    }
    UIWindowScene *scene = [self activeScene];
    if (!scene) return nil;
    UIWindow *w = [[UIWindow alloc] initWithWindowScene:scene];
    w.windowLevel = 19500;
    w.backgroundColor = UIColor.clearColor;
    UIViewController *root = [[UIViewController alloc] init];
    root.view.backgroundColor = UIColor.clearColor;
    root.view.userInteractionEnabled = NO;
    w.rootViewController = root;
    w.hidden = NO;
    self.toastHostWindow = w;
    return w;
}

- (void)retireToastHostIfIdle {
    if (!self.toastHostWindow.rootViewController.view) return;
    if (self.toastHostWindow.rootViewController.view.subviews.count == 0) {
        self.toastHostWindow.hidden = YES;
        self.toastHostWindow.rootViewController = nil;
        self.toastHostWindow = nil;
    }
}

- (void)onMain:(dispatch_block_t)block {
    if ([NSThread isMainThread]) block();
    else dispatch_async(dispatch_get_main_queue(), block);
}

@end
