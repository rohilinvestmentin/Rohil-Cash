//

//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TgPackEnvelope : NSObject
@property (nonatomic, strong, nullable) UIImage *foldedImage;
@property (nonatomic, strong, nullable) NSData *payloadData;
@property (nonatomic, copy, nullable) NSString *base64Payload;
@property (nonatomic, assign) CGFloat originKB;
@property (nonatomic, assign) CGFloat foldedKB;
@end

NS_ASSUME_NONNULL_END
