//

//

#import "TgLoanProductCardView.h"
#import "TgPayloadModels.h"
#import "NSString+TgGlyph.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>

static CGFloat const kTgLoanCardRadius = 16.0;
static CGFloat const kTgLoanCardHorzInset = 14.0;
static CGFloat const kTgLoanCardReferTop = 14.0;
static CGFloat const kTgLoanCardReferWaveGap = 12.0;
static CGFloat const kTgLoanCardReferActionSpacing = 4.0;
static CGFloat const kTgLoanCardInfoTop = 12.0;
static CGFloat const kTgLoanCardInfoBottom = 12.0;
static CGFloat const kTgLoanCardLogoSide = 24.0;
static CGFloat const kTgLoanCardNameGap = 8.0;
static CGFloat const kTgLoanCardAmountTop = 8.0;
static CGFloat const kTgLoanCardStarWidth = 130.0;
static CGFloat const kTgLoanCardStarHeight = 99.0;
static CGFloat const kTgLoanCardTagRowHeight = 28.0;
static CGFloat const kTgLoanCardTagSpacing = 15.0;
static CGFloat const kTgLoanCardTagBottomInset = 12.0;
static NSString * const kTgLoanCardWaveAsset = @"useMaskgroup";
static NSString * const kTgLoanCardArrowAsset = @"use_next_loan_lan";
static NSString * const kTgLoanCardStarAsset = @"use_star_01";
static NSString * const kTgLoanCardLogoBgHex = @"#BFC7F5";
static NSString * const kTgLoanCardNameToneHex = @"#BFC7F5";
static NSString * const kTgLoanCardAmountToneHex = @"#C51B12";
static NSString * const kTgLoanCardTagToneHex = @"#4A59B1";

@interface TgLoanProductCardView ()

@property (nonatomic, strong) UIView *tg_referVeil;
@property (nonatomic, strong) UIView *tg_referHeaderRow;
@property (nonatomic, strong) UIView *tg_rateBox;
@property (nonatomic, strong) UILabel *tg_rateCaption;
@property (nonatomic, strong) UILabel *tg_referCaption;
@property (nonatomic, strong) UIImageView *tg_referArrowGlyph;
@property (nonatomic, strong) UIImageView *tg_waveGlyph;
@property (nonatomic, strong) UIView *tg_infoVeil;
@property (nonatomic, strong) UIImageView *tg_logoGlyph;
@property (nonatomic, strong) UILabel *tg_nameCaption;
@property (nonatomic, strong) UIImageView *tg_starGlyph;
@property (nonatomic, strong) UILabel *tg_amountCaption;
@property (nonatomic, strong) UIView *tg_tagVeil;
@property (nonatomic, strong) UIScrollView *tg_tagScroll;
@property (nonatomic, strong) UIStackView *tg_tagStack;
@property (nonatomic, strong) MASConstraint *tg_tagVeilHeightConstraint;

@end

@implementation TgLoanProductCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.whiteColor;
        self.layer.cornerRadius = kTgLoanCardRadius;
        self.clipsToBounds = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tg_tapped)];
        [self addGestureRecognizer:tap];
        [self tg_buildUI];
    }
    return self;
}

#pragma mark - Format

+ (NSString *)tg_rateDisplayFromString:(nullable NSString *)raw {
    NSString *trim = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (trim.length == 0) return @"--";
    double value = trim.doubleValue;
    if (value <= 0) return @"--";
    return [NSString stringWithFormat:@"%.2f%%", value * 100.0];
}

+ (void)tg_appendTagPartsFromString:(nullable NSString *)raw intoNames:(NSMutableArray<NSString *> *)names {
    NSString *trimmed = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (trimmed.length == 0) return;
    NSString *normalized = [trimmed stringByReplacingOccurrencesOfString:@"，" withString:@","];
    for (NSString *part in [normalized componentsSeparatedByString:@","]) {
        NSString *tag = [part stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
        if (tag.length > 0) {
            [names addObject:tag];
        }
    }
}

+ (NSArray<NSString *> *)tg_tagNamesFromProduct:(TgProductInfo *)product {
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (TgProductLabelItem *item in product.flourish) {
        [self tg_appendTagPartsFromString:item.typewriter intoNames:names];
    }
    if (names.count == 0) {
        [self tg_appendTagPartsFromString:product.possession intoNames:names];
    }
    return names;
}

+ (NSString *)tg_amountRangeFromLow:(nullable NSString *)low high:(nullable NSString *)high {
    NSString *lowTrim = [low stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    NSString *highTrim = [high stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (lowTrim.length == 0 && highTrim.length == 0) return @"-";
    if (lowTrim.length > 0 && highTrim.length > 0) {
        return [NSString stringWithFormat:@"₹%@-%@",
                [NSString tg_weaveIndianDigits:lowTrim],
                [NSString tg_weaveIndianDigits:highTrim]];
    }
    NSString *single = lowTrim.length > 0 ? lowTrim : highTrim;
    return [NSString stringWithFormat:@"₹%@", [NSString tg_weaveIndianDigits:single]];
}

#pragma mark - UI

- (UILabel *)tg_labelWithSize:(CGFloat)size weight:(UIFontWeight)weight color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont tg_meshGlyphWithSize:size weight:weight];
    label.textColor = color;
    return label;
}

- (void)tg_buildUI {
    self.tg_referVeil = [[UIView alloc] init];
    self.tg_infoVeil = [[UIView alloc] init];
    self.tg_tagVeil = [[UIView alloc] init];
    [self addSubview:self.tg_referVeil];
    [self addSubview:self.tg_infoVeil];
    [self addSubview:self.tg_tagVeil];

    self.tg_referHeaderRow = [[UIView alloc] init];

    self.tg_rateBox = [[UIView alloc] init];
    self.tg_rateBox.backgroundColor = [UIColor tg_toneFromHex:@"#3D59FF"];
    self.tg_rateBox.layer.cornerRadius = 12;
    self.tg_rateBox.clipsToBounds = YES;

    self.tg_rateCaption = [self tg_labelWithSize:12 weight:UIFontWeightMedium color:UIColor.whiteColor];
    [self.tg_rateBox addSubview:self.tg_rateCaption];
    [self.tg_rateCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_rateBox).insets(UIEdgeInsetsMake(4, 10, 4, 10));
    }];

    self.tg_referCaption = [self tg_labelWithSize:16 weight:UIFontWeightMedium color:UIColor.blackColor];
    self.tg_referCaption.text = @"Refer Now";
    [self.tg_referCaption setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.tg_referCaption setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    self.tg_referArrowGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgLoanCardArrowAsset]];
    self.tg_referArrowGlyph.contentMode = UIViewContentModeScaleAspectFit;
    [self.tg_referArrowGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(16);
    }];

    UIStackView *referActionRow = [[UIStackView alloc] initWithArrangedSubviews:@[self.tg_referCaption, self.tg_referArrowGlyph]];
    referActionRow.axis = UILayoutConstraintAxisHorizontal;
    referActionRow.alignment = UIStackViewAlignmentCenter;
    referActionRow.spacing = kTgLoanCardReferActionSpacing;
    referActionRow.userInteractionEnabled = NO;

    [self.tg_referHeaderRow addSubview:self.tg_rateBox];
    [self.tg_referHeaderRow addSubview:referActionRow];

    self.tg_waveGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgLoanCardWaveAsset]];
    self.tg_waveGlyph.contentMode = UIViewContentModeScaleAspectFit;
    self.tg_waveGlyph.clipsToBounds = NO;

    self.tg_logoGlyph = [[UIImageView alloc] init];
    self.tg_logoGlyph.contentMode = UIViewContentModeScaleAspectFit;
    self.tg_logoGlyph.clipsToBounds = YES;
    self.tg_logoGlyph.layer.cornerRadius = 4;
    self.tg_logoGlyph.backgroundColor = [UIColor tg_toneFromHex:kTgLoanCardLogoBgHex];

    self.tg_nameCaption = [self tg_labelWithSize:14 weight:UIFontWeightBold color:[UIColor tg_toneFromHex:kTgLoanCardNameToneHex]];

    self.tg_starGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgLoanCardStarAsset]];
    self.tg_starGlyph.contentMode = UIViewContentModeScaleAspectFit;
    self.tg_starGlyph.clipsToBounds = NO;
    self.tg_starGlyph.userInteractionEnabled = NO;

    self.tg_amountCaption = [self tg_labelWithSize:32 weight:UIFontWeightBold color:[UIColor tg_toneFromHex:kTgLoanCardAmountToneHex]];
    self.tg_amountCaption.numberOfLines = 1;
    self.tg_amountCaption.lineBreakMode = NSLineBreakByTruncatingTail;
    self.tg_amountCaption.adjustsFontSizeToFitWidth = YES;
    self.tg_amountCaption.minimumScaleFactor = 0.5;
    self.tg_amountCaption.backgroundColor = UIColor.clearColor;

    self.tg_tagScroll = [[UIScrollView alloc] init];
    self.tg_tagScroll.showsHorizontalScrollIndicator = NO;
    self.tg_tagScroll.showsVerticalScrollIndicator = NO;
    self.tg_tagScroll.alwaysBounceHorizontal = YES;
    self.tg_tagScroll.alwaysBounceVertical = NO;

    self.tg_tagStack = [[UIStackView alloc] init];
    self.tg_tagStack.axis = UILayoutConstraintAxisHorizontal;
    self.tg_tagStack.alignment = UIStackViewAlignmentCenter;
    self.tg_tagStack.spacing = kTgLoanCardTagSpacing;

    [self.tg_referVeil addSubview:self.tg_waveGlyph];
    [self.tg_referVeil addSubview:self.tg_referHeaderRow];
    [self.tg_infoVeil addSubview:self.tg_logoGlyph];
    [self.tg_infoVeil addSubview:self.tg_nameCaption];
    [self.tg_infoVeil addSubview:self.tg_starGlyph];
    [self.tg_infoVeil addSubview:self.tg_amountCaption];
    [self.tg_tagVeil addSubview:self.tg_tagScroll];
    [self.tg_tagScroll addSubview:self.tg_tagStack];

    [self.tg_referVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
    }];
    [self.tg_infoVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_referVeil.mas_bottom);
        make.left.right.equalTo(self);
        make.height.mas_greaterThanOrEqualTo(kTgLoanCardStarHeight + kTgLoanCardInfoTop + kTgLoanCardInfoBottom);
    }];
    [self.tg_tagVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_infoVeil.mas_bottom);
        make.left.equalTo(self).offset(kTgLoanCardHorzInset);
        make.right.equalTo(self).offset(-kTgLoanCardHorzInset);
        make.bottom.equalTo(self).offset(-kTgLoanCardTagBottomInset);
        self.tg_tagVeilHeightConstraint = make.height.mas_equalTo(kTgLoanCardTagRowHeight);
    }];
    [self.tg_tagScroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_tagVeil);
        make.height.mas_equalTo(kTgLoanCardTagRowHeight);
    }];
    [self.tg_tagStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_tagScroll);
        make.height.equalTo(self.tg_tagScroll);
    }];

    [self.tg_referHeaderRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_referVeil).offset(kTgLoanCardHorzInset);
        make.right.equalTo(self.tg_referVeil).offset(-kTgLoanCardHorzInset);
        make.top.equalTo(self.tg_referVeil).offset(kTgLoanCardReferTop);
    }];
    [self.tg_rateBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(self.tg_referHeaderRow);
    }];
    [referActionRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.centerY.equalTo(self.tg_referHeaderRow);
        make.left.greaterThanOrEqualTo(self.tg_rateBox.mas_right).offset(8);
    }];

    UIImage *waveImg = [UIImage imageNamed:kTgLoanCardWaveAsset];
    CGFloat waveRatio = (waveImg.size.width > 0) ? (waveImg.size.height / waveImg.size.width) : 0.05;
    [self.tg_waveGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.tg_referVeil);
        make.top.equalTo(self.tg_referHeaderRow.mas_bottom).offset(kTgLoanCardReferWaveGap);
        make.height.equalTo(self.tg_waveGlyph.mas_width).multipliedBy(waveRatio);
        make.bottom.equalTo(self.tg_referVeil);
    }];

    [self.tg_logoGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_infoVeil).offset(kTgLoanCardHorzInset);
        make.top.equalTo(self.tg_infoVeil).offset(kTgLoanCardInfoTop);
        make.width.height.mas_equalTo(kTgLoanCardLogoSide);
    }];
    [self.tg_nameCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_logoGlyph.mas_right).offset(kTgLoanCardNameGap);
        make.right.lessThanOrEqualTo(self.tg_infoVeil).offset(-kTgLoanCardHorzInset);
        make.centerY.equalTo(self.tg_logoGlyph);
    }];
    [self.tg_starGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.tg_infoVeil).offset(-kTgLoanCardHorzInset);
        make.centerY.equalTo(self.tg_infoVeil);
        make.width.mas_equalTo(kTgLoanCardStarWidth);
        make.height.mas_equalTo(kTgLoanCardStarHeight);
    }];
    [self.tg_amountCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_logoGlyph);
        make.right.equalTo(self.tg_infoVeil).offset(-kTgLoanCardHorzInset);
        make.top.equalTo(self.tg_logoGlyph.mas_bottom).offset(kTgLoanCardAmountTop);
        make.bottom.equalTo(self.tg_infoVeil).offset(-kTgLoanCardInfoBottom);
    }];

    [self.tg_referVeil sendSubviewToBack:self.tg_waveGlyph];
}

- (UILabel *)tg_buildTagChipWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont tg_meshGlyphWithSize:12 weight:UIFontWeightRegular];
    label.textColor = [UIColor tg_toneFromHex:kTgLoanCardTagToneHex];
    label.backgroundColor = UIColor.clearColor;
    label.numberOfLines = 1;
    [label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    return label;
}

- (void)tg_reloadTagsForProduct:(TgProductInfo *)product {
    for (UIView *v in self.tg_tagStack.arrangedSubviews) {
        [self.tg_tagStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }

    NSArray<NSString *> *names = [[self class] tg_tagNamesFromProduct:product];
    BOOL showTags = names.count > 0;
    self.tg_tagVeil.hidden = !showTags;
    [self.tg_tagVeilHeightConstraint setOffset:showTags ? kTgLoanCardTagRowHeight : 0];

    for (NSString *name in names) {
        [self.tg_tagStack addArrangedSubview:[self tg_buildTagChipWithText:name]];
    }
}

- (void)tg_configureWithProduct:(TgProductInfo *)product {
    self.tg_rateCaption.text = [[self class] tg_rateDisplayFromString:product.provided];
    self.tg_nameCaption.text = product.other.length > 0 ? product.other : @"-";
    self.tg_amountCaption.text = [[self class] tg_amountRangeFromLow:product.efficient high:product.bold];
    [self tg_reloadTagsForProduct:product];

    NSString *logoURL = [product.green stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (logoURL.length > 0) {
        [self.tg_logoGlyph sd_setImageWithURL:[NSURL URLWithString:logoURL]
                             placeholderImage:nil
                                      options:SDWebImageRetryFailed];
    } else {
        [self.tg_logoGlyph sd_cancelCurrentImageLoad];
        self.tg_logoGlyph.image = nil;
    }
}

- (void)tg_tapped {
    if (self.tg_onTap) self.tg_onTap();
}

@end
