//

//

#import "TgStarGauge.h"
#import <Masonry/Masonry.h>

static NSString * const kTgStarNormalAsset = @"gst_sel0";
static NSString * const kTgStarSelectedAsset = @"gst_sel1";
static const NSInteger kTgStarCount = 5;

@interface TgStarGauge ()

@property (nonatomic, readwrite) NSInteger tg_currentScore;
@property (nonatomic, strong) UIStackView *tg_starStack;
@property (nonatomic, copy) NSArray<UIButton *> *tg_starButtons;
@property (nonatomic, assign) BOOL tg_suppressCallback;

@end

@implementation TgStarGauge

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self tg_commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self tg_commonInit];
    }
    return self;
}

- (void)tg_commonInit {
    _tg_starSize = 36.0;
    _tg_starSpacing = 12.0;
    _tg_normalImageName = kTgStarNormalAsset;
    _tg_selectedImageName = kTgStarSelectedAsset;
    _tg_currentScore = 0;

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisHorizontal;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.distribution = UIStackViewDistributionFillEqually;
    stack.spacing = _tg_starSpacing;
    [self addSubview:stack];
    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
        make.height.mas_equalTo(_tg_starSize);
    }];
    self.tg_starStack = stack;

    NSMutableArray<UIButton *> *buttons = [NSMutableArray arrayWithCapacity:kTgStarCount];
    for (NSInteger i = 0; i < kTgStarCount; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = i + 1;
        btn.adjustsImageWhenHighlighted = NO;
        [btn addTarget:self action:@selector(tg_starTapped:) forControlEvents:UIControlEventTouchUpInside];
        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(_tg_starSize);
        }];
        [stack addArrangedSubview:btn];
        [buttons addObject:btn];
    }
    self.tg_starButtons = buttons.copy;
    [self tg_refreshStarsAnimated:NO];
}

- (CGSize)intrinsicContentSize {
    CGFloat width = self.tg_starSize * kTgStarCount + self.tg_starSpacing * (kTgStarCount - 1);
    return CGSizeMake(width, self.tg_starSize);
}

- (void)setTg_starSize:(CGFloat)tg_starSize {
    if (fabs(_tg_starSize - tg_starSize) < 0.5) return;
    _tg_starSize = tg_starSize;
    [self tg_updateMetrics];
}

- (void)setTg_starSpacing:(CGFloat)tg_starSpacing {
    if (fabs(_tg_starSpacing - tg_starSpacing) < 0.5) return;
    _tg_starSpacing = tg_starSpacing;
    [self tg_updateMetrics];
}

- (void)setTg_normalImageName:(NSString *)tg_normalImageName {
    _tg_normalImageName = tg_normalImageName.length > 0 ? tg_normalImageName : kTgStarNormalAsset;
    [self tg_refreshStarsAnimated:NO];
}

- (void)setTg_selectedImageName:(NSString *)tg_selectedImageName {
    _tg_selectedImageName = tg_selectedImageName.length > 0 ? tg_selectedImageName : kTgStarSelectedAsset;
    [self tg_refreshStarsAnimated:NO];
}

- (void)tg_setScore:(NSInteger)score animated:(BOOL)animated {
    NSInteger clamped = MAX(0, MIN(kTgStarCount, score));
    if (self.tg_currentScore == clamped) {
        [self tg_refreshStarsAnimated:animated];
        return;
    }
    self.tg_suppressCallback = YES;
    self.tg_currentScore = clamped;
    [self tg_refreshStarsAnimated:animated];
    self.tg_suppressCallback = NO;
}

- (void)tg_resetAnimated:(BOOL)animated {
    [self tg_setScore:0 animated:animated];
}

#pragma mark - Actions

- (void)tg_starTapped:(UIButton *)sender {
    if (!self.userInteractionEnabled) return;
    NSInteger score = sender.tag;
    if (score < 1 || score > kTgStarCount) return;

    self.tg_currentScore = score;
    [self tg_refreshStarsAnimated:YES];
    [self tg_emitScoreChange:score];
}

#pragma mark - Private

- (void)tg_updateMetrics {
    self.tg_starStack.spacing = self.tg_starSpacing;
    [self.tg_starStack mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(self.tg_starSize);
    }];
    for (UIButton *btn in self.tg_starButtons) {
        [btn mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(self.tg_starSize);
        }];
    }
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}

- (void)tg_refreshStarsAnimated:(BOOL)animated {
    void (^apply)(void) = ^{
        UIImage *normal = [UIImage imageNamed:self.tg_normalImageName];
        UIImage *selected = [UIImage imageNamed:self.tg_selectedImageName];
        for (NSInteger i = 0; i < self.tg_starButtons.count; i++) {
            UIButton *btn = self.tg_starButtons[i];
            BOOL on = (i + 1) <= self.tg_currentScore;
            UIImage *icon = on ? selected : normal;
            [btn setImage:icon forState:UIControlStateNormal];
        }
    };
    if (animated) {
        [UIView transitionWithView:self.tg_starStack
                          duration:0.2
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:apply
                        completion:nil];
    } else {
        apply();
    }
}

- (void)tg_emitScoreChange:(NSInteger)score {
    if (self.tg_suppressCallback) return;
    if ([self.delegate respondsToSelector:@selector(tg_starGauge:didSelectScore:)]) {
        [self.delegate tg_starGauge:self didSelectScore:score];
    }
    if (self.tg_scoreDidChange) {
        self.tg_scoreDidChange(self, score);
    }
}

@end
