//

//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^TgKycIdUploadCardVoidBlock)(void);

@interface TgKycIdUploadCard : UIView

@property (nonatomic, copy, nullable) TgKycIdUploadCardVoidBlock tg_onPickTapped;
@property (nonatomic, copy, nullable) TgKycIdUploadCardVoidBlock tg_onDeleteTapped;

- (instancetype)initWithPlaceholderAsset:(NSString *)assetName sideLabel:(NSString *)sideLabel;

- (instancetype)initWithPlaceholderAsset:(NSString *)assetName
                               sideLabel:(NSString *)sideLabel
                          hindiSideLabel:(nullable NSString *)hindiSideLabel;

- (void)tg_setUploadedImage:(nullable UIImage *)image;
- (void)tg_clearUpload;

@end

NS_ASSUME_NONNULL_END
