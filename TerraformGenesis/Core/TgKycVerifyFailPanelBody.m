//
//  TgKycVerifyFailPanelBody.m
//

#import "TgKycVerifyFailPanelBody.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>

static NSString * const kTgVerifyFailMessage =
    @"Verification did not succeed. Please upload the photo once more.";
static NSString * const kTgVerifyFailTipBgHex = @"#FCF4EE";
static NSString * const kTgVerifyFailTipTextHex = @"#EA834C";
static CGFloat const kTgVerifyFailIllustWidthRatio = 0.85;
static CGFloat const kTgVerifyFailIllustAspectW = 277.0;
static CGFloat const kTgVerifyFailIllustAspectH = 349.0;

@implementation TgKycVerifyFailPanelBody

+ (UIView *)tg_buildWithIllustrationAsset:(NSString *)illustrationAsset {
    UIView *root = [[UIView alloc] init];
    root.backgroundColor = UIColor.clearColor;

    UIView *tipVeil = [[UIView alloc] init];
    tipVeil.backgroundColor = [UIColor tg_toneFromHex:kTgVerifyFailTipBgHex];
    tipVeil.layer.cornerRadius = 8.0;
    tipVeil.clipsToBounds = YES;
    [root addSubview:tipVeil];

    UILabel *tipLabel = [[UILabel alloc] init];
    tipLabel.text = kTgVerifyFailMessage;
    tipLabel.font = [UIFont tg_meshGlyphWithSize:15 weight:UIFontWeightMedium];
    tipLabel.textColor = [UIColor tg_toneFromHex:kTgVerifyFailTipTextHex];
    tipLabel.numberOfLines = 0;
    tipLabel.textAlignment = NSTextAlignmentCenter;
    [tipVeil addSubview:tipLabel];

    UIImageView *illustration = [[UIImageView alloc] initWithImage:[UIImage imageNamed:illustrationAsset]];
    illustration.contentMode = UIViewContentModeScaleAspectFit;
    illustration.clipsToBounds = YES;
    [root addSubview:illustration];

    [tipVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(root);
    }];
    [tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(tipVeil).insets(UIEdgeInsetsMake(12, 12, 12, 12));
    }];
    [illustration mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tipVeil.mas_bottom).offset(16);
        make.centerX.equalTo(root);
        make.width.equalTo(root).multipliedBy(kTgVerifyFailIllustWidthRatio);
        make.height.equalTo(illustration.mas_width).multipliedBy(kTgVerifyFailIllustAspectH / kTgVerifyFailIllustAspectW);
        make.bottom.equalTo(root);
    }];

    return root;
}

@end
