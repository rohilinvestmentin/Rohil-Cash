//
//  TgKycIdUploadCard.m
//

#import "TgKycIdUploadCard.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>

static NSString * const kTgIdBarMaskHex = @"#020A28";
static CGFloat const kTgIdBarMaskAlpha = 0.5;
static NSString * const kTgIdCameraAsset = @"use_Aadhaar";
static NSString * const kTgIdDeleteAsset = @"use_Delete";
static CGFloat const kTgIdCardRadius = 16.0;
static CGFloat const kTgIdCardBarHeight = 52.0;
static CGFloat const kTgIdCardAspectW = 343.0;
static CGFloat const kTgIdCardAspectH = 188.0;
static CGFloat const kTgIdCameraIconSize = 24.0;

@interface TgKycIdUploadCard ()

@property (nonatomic, copy) NSString *tg_placeholderAsset;
@property (nonatomic, strong) UIView *tg_imageVeil;
@property (nonatomic, strong) UIImageView *tg_placeholderGlyph;
@property (nonatomic, strong) UIImageView *tg_previewGlyph;
@property (nonatomic, strong) UIView *tg_bottomBar;
@property (nonatomic, strong) UIView *tg_bottomBarMask;
@property (nonatomic, strong) UIStackView *tg_cameraStack;
@property (nonatomic, strong) UIButton *tg_cameraLatch;
@property (nonatomic, strong) UILabel *tg_sideCaption;
@property (nonatomic, strong) UILabel *tg_hindiSideCaption;
@property (nonatomic, strong) UIButton *tg_removeLatch;

@end

@implementation TgKycIdUploadCard

- (instancetype)initWithPlaceholderAsset:(NSString *)assetName sideLabel:(NSString *)sideLabel {
    return [self initWithPlaceholderAsset:assetName sideLabel:sideLabel hindiSideLabel:nil];
}

- (instancetype)initWithPlaceholderAsset:(NSString *)assetName
                               sideLabel:(NSString *)sideLabel
                          hindiSideLabel:(NSString *)hindiSideLabel {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _tg_placeholderAsset = [assetName copy];
        self.backgroundColor = UIColor.clearColor;
        self.layer.cornerRadius = kTgIdCardRadius;
        self.clipsToBounds = YES;
        [self tg_buildUIWithSideLabel:sideLabel hindiSideLabel:hindiSideLabel];
        [self mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(self.mas_width).multipliedBy(kTgIdCardAspectH / kTgIdCardAspectW);
        }];
    }
    return self;
}

- (void)tg_buildUIWithSideLabel:(NSString *)sideLabel hindiSideLabel:(NSString *)hindiSideLabel {
    self.tg_placeholderGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:self.tg_placeholderAsset]];
    self.tg_placeholderGlyph.contentMode = UIViewContentModeScaleAspectFill;
    self.tg_placeholderGlyph.clipsToBounds = YES;
    [self addSubview:self.tg_placeholderGlyph];

    self.tg_imageVeil = [[UIView alloc] init];
    self.tg_imageVeil.backgroundColor = UIColor.clearColor;
    self.tg_imageVeil.clipsToBounds = YES;
    [self addSubview:self.tg_imageVeil];

    self.tg_previewGlyph = [[UIImageView alloc] init];
    self.tg_previewGlyph.contentMode = UIViewContentModeScaleAspectFill;
    self.tg_previewGlyph.clipsToBounds = YES;
    self.tg_previewGlyph.hidden = YES;
    [self.tg_imageVeil addSubview:self.tg_previewGlyph];

    self.tg_removeLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_removeLatch setImage:[UIImage imageNamed:kTgIdDeleteAsset] forState:UIControlStateNormal];
    self.tg_removeLatch.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.tg_removeLatch.hidden = YES;
    [self.tg_removeLatch addTarget:self action:@selector(tg_deleteTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.tg_imageVeil addSubview:self.tg_removeLatch];

    self.tg_bottomBar = [[UIView alloc] init];
    self.tg_bottomBar.backgroundColor = UIColor.clearColor;
    [self addSubview:self.tg_bottomBar];

    self.tg_bottomBarMask = [[UIView alloc] init];
    self.tg_bottomBarMask.backgroundColor = [[UIColor tg_toneFromHex:kTgIdBarMaskHex] colorWithAlphaComponent:kTgIdBarMaskAlpha];
    [self.tg_bottomBar addSubview:self.tg_bottomBarMask];

    self.tg_cameraLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_cameraLatch setImage:[UIImage imageNamed:kTgIdCameraAsset] forState:UIControlStateNormal];
    self.tg_cameraLatch.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.tg_cameraLatch addTarget:self action:@selector(tg_pickTapped) forControlEvents:UIControlEventTouchUpInside];

    self.tg_sideCaption = [[UILabel alloc] init];
    self.tg_sideCaption.text = sideLabel;
    self.tg_sideCaption.font = [UIFont tg_meshGlyphWithSize:12 weight:UIFontWeightMedium];
    self.tg_sideCaption.textColor = UIColor.whiteColor;
    self.tg_sideCaption.textAlignment = NSTextAlignmentCenter;
    self.tg_sideCaption.numberOfLines = 2;

    NSMutableArray<UIView *> *stackItems = [NSMutableArray arrayWithObjects:self.tg_cameraLatch, self.tg_sideCaption, nil];
    if (hindiSideLabel.length > 0) {
        self.tg_hindiSideCaption = [[UILabel alloc] init];
        self.tg_hindiSideCaption.text = hindiSideLabel;
        self.tg_hindiSideCaption.font = [UIFont tg_meshGlyphWithSize:11 weight:UIFontWeightRegular];
        self.tg_hindiSideCaption.textColor = UIColor.whiteColor;
        self.tg_hindiSideCaption.textAlignment = NSTextAlignmentCenter;
        [stackItems addObject:self.tg_hindiSideCaption];
    }

    self.tg_cameraStack = [[UIStackView alloc] initWithArrangedSubviews:stackItems];
    self.tg_cameraStack.axis = UILayoutConstraintAxisVertical;
    self.tg_cameraStack.alignment = UIStackViewAlignmentCenter;
    self.tg_cameraStack.spacing = 4.0;
    self.tg_cameraStack.userInteractionEnabled = NO;
    [self.tg_bottomBar addSubview:self.tg_cameraStack];

    UITapGestureRecognizer *cardTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tg_pickTapped)];
    [self addGestureRecognizer:cardTap];

    [self.tg_imageVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    [self.tg_placeholderGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    [self.tg_previewGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_imageVeil);
    }];
    [self.tg_removeLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.right.equalTo(self).insets(UIEdgeInsetsMake(8, 0, 0, 8));
        make.width.height.mas_equalTo(28);
    }];
    [self.tg_bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.height.mas_equalTo(kTgIdCardBarHeight);
    }];
    [self.tg_bottomBarMask mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_bottomBar);
    }];
    [self.tg_cameraStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.tg_bottomBar);
    }];
    [self.tg_cameraLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(kTgIdCameraIconSize);
    }];
}

- (void)tg_setUploadedImage:(UIImage *)image {
    BOOL has = (image != nil);
    self.tg_previewGlyph.image = image;
    self.tg_previewGlyph.hidden = !has;
    self.tg_placeholderGlyph.hidden = has;
    self.tg_removeLatch.hidden = !has;
    self.tg_bottomBar.hidden = has;
    self.tg_cameraStack.hidden = has;
    self.tg_bottomBarMask.hidden = has;
    self.tg_imageVeil.backgroundColor = UIColor.clearColor;
}

- (void)tg_clearUpload {
    [self tg_setUploadedImage:nil];
}

- (void)tg_pickTapped {
    if (self.tg_onPickTapped) self.tg_onPickTapped();
}

- (void)tg_deleteTapped {
    if (self.tg_onDeleteTapped) self.tg_onDeleteTapped();
}

@end
