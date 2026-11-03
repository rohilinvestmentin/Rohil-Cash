//

//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TgStarGauge;

@protocol TgStarGaugeDelegate <NSObject>
@optional
- (void)tg_starGauge:(TgStarGauge *)gauge didSelectScore:(NSInteger)score;
@end

@interface TgStarGauge : UIView

@property (nonatomic, weak, nullable) id<TgStarGaugeDelegate> delegate;

@property (nonatomic, readonly) NSInteger tg_currentScore;

@property (nonatomic, assign) CGFloat tg_starSize;

@property (nonatomic, assign) CGFloat tg_starSpacing;

@property (nonatomic, copy) NSString *tg_normalImageName;

@property (nonatomic, copy) NSString *tg_selectedImageName;

@property (nonatomic, copy, nullable) void (^tg_scoreDidChange)(TgStarGauge *gauge, NSInteger score);

- (void)tg_setScore:(NSInteger)score animated:(BOOL)animated;
- (void)tg_resetAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
