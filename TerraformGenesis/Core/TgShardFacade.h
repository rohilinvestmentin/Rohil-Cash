//

//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TgShardTier) {
    TgShardTierFloor = 0,
    TgShardTierLow,
    TgShardTierMid,
    TgShardTierHigh,
};

typedef NS_ENUM(NSInteger, TgShardMount) {
    TgShardMountWindow = 0,
    TgShardMountView,
};

typedef NS_ENUM(NSInteger, TgShardPanelStyle) {
    TgShardPanelStyleText = 0,
    TgShardPanelStyleCustomBody,
};

@interface TgShardPanelConfig : NSObject

@property (nonatomic, assign) TgShardPanelStyle panelStyle;

@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *content;
@property (nonatomic, copy, nullable) NSString *detailText;

@property (nonatomic, strong, nullable) UIView *customBodyView;

@property (nonatomic, assign) CGFloat customBodyHeight;

@property (nonatomic, copy, nullable) NSString *primaryTitle;
@property (nonatomic, copy, nullable) NSString *secondaryTitle;

@property (nonatomic, copy, nullable) void (^primaryAction)(void);
@property (nonatomic, copy, nullable) void (^secondaryAction)(void);

@property (nonatomic, assign) BOOL dismissOnPrimaryAction;
@property (nonatomic, assign) BOOL dismissOnSecondaryAction;

@property (nonatomic, assign) TgShardTier tier;
@property (nonatomic, assign) TgShardMount mount;
@property (nonatomic, weak, nullable) UIView *hostView;

@end

@interface TgShardFacade : NSObject

+ (instancetype)shared;

#pragma mark - 遮罩层（loading.gif + 文案）

- (NSString *)showVeilText:(nullable NSString *)text;
- (NSString *)showVeilText:(nullable NSString *)text tier:(TgShardTier)tier;
- (NSString *)showVeilText:(nullable NSString *)text inView:(UIView *)hostView;

- (void)dismissVeilToken:(nullable NSString *)token;
- (void)dismissAllVeils;

#pragma mark - 统一弹窗

- (NSString *)showPanel:(TgShardPanelConfig *)config;

- (NSString *)showOptionPickerWithTitle:(nullable NSString *)title
                                options:(NSArray<NSString *> *)options
                          selectedIndex:(NSInteger)selectedIndex
                           confirmTitle:(nullable NSString *)confirmTitle
                              onConfirm:(void (^)(NSInteger index, NSString *value))onConfirm;

- (NSString *)showTextPanelWithContent:(nullable NSString *)content
                          primaryTitle:(nullable NSString *)primaryTitle
                        secondaryTitle:(nullable NSString *)secondaryTitle
                          primaryAction:(nullable void (^)(void))primaryAction
                        secondaryAction:(nullable void (^)(void))secondaryAction;

- (NSString *)showCustomBodyPanel:(UIView *)bodyView
                            title:(nullable NSString *)title
                    primaryTitle:(nullable NSString *)primaryTitle
                  secondaryTitle:(nullable NSString *)secondaryTitle
                    primaryAction:(nullable void (^)(void))primaryAction
                  secondaryAction:(nullable void (^)(void))secondaryAction;

- (void)dismissPanelToken:(nullable NSString *)token;
- (void)dismissTopPanel;
- (void)dismissAllPanels;

@end

NS_ASSUME_NONNULL_END
