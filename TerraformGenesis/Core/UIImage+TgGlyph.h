//

//

#import <UIKit/UIKit.h>

@class TgPackEnvelope;

@interface UIImage (TgGlyph)

/// Compress for KYC / upload. Caps long side and folds into [minKB, maxKB] JPEG + base64.
- (nullable TgPackEnvelope *)tg_foldPayloadMinKB:(NSInteger)minKB maxKB:(NSInteger)maxKB;

/// Same as above; optional originalData reused when already within the size window.
- (nullable TgPackEnvelope *)tg_foldPayloadWithOriginalData:(nullable NSData *)originalData
                                                     minKB:(NSInteger)minKB
                                                     maxKB:(NSInteger)maxKB;

@end
