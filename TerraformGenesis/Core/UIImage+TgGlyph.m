//
//  UIImage+TgGlyph.m
//

#import "UIImage+TgGlyph.h"
#import "TgPackEnvelope.h"

static const CGFloat kTgFoldMaxSide = 1920.0;

@implementation UIImage (TgGlyph)

- (TgPackEnvelope *)tg_foldPayloadMinKB:(NSInteger)minKB maxKB:(NSInteger)maxKB {
    return [self tg_foldPayloadWithOriginalData:nil minKB:minKB maxKB:maxKB];
}

- (TgPackEnvelope *)tg_foldPayloadWithOriginalData:(NSData *)originalData minKB:(NSInteger)minKB maxKB:(NSInteger)maxKB {
    NSInteger minBytes = MIN(minKB, maxKB) * 1024;
    NSInteger maxBytes = MAX(minKB, maxKB) * 1024;

    TgPackEnvelope *(^wrap)(NSData *) = ^TgPackEnvelope *(NSData *data) {
        if (!data.length) return nil;
        UIImage *img = [UIImage imageWithData:data];
        if (!img) return nil;
        TgPackEnvelope *box = [[TgPackEnvelope alloc] init];
        box.foldedImage = img;
        box.payloadData = data;
        box.base64Payload = [data base64EncodedStringWithOptions:0];
        box.originKB = (originalData.length > 0 ? originalData.length : data.length) / 1024.0;
        box.foldedKB = data.length / 1024.0;
        return box;
    };

    // Prefer a dimension-capped source so album shots >2MB don't OOM / fail JPEG encode.
    UIImage *source = [self tg_imageCappedToMaxSide:kTgFoldMaxSide];
    NSData *seed = nil;
    if (originalData.length > 0
        && originalData.length <= (NSUInteger)maxBytes
        && source == self) {
        seed = originalData;
    }
    if (!seed) {
        CGFloat startQ = (originalData.length > (NSUInteger)(maxBytes * 2)) ? 0.7 : 0.85;
        seed = UIImageJPEGRepresentation(source, startQ);
    }
    if (!seed) {
        seed = UIImageJPEGRepresentation(source, 0.55);
    }
    if (!seed) return nil;

    if (seed.length <= (NSUInteger)maxBytes) return wrap(seed);

    NSData *packed = [source tg_jpegFoldLoopWithMaxBytes:maxBytes minBytes:minBytes];
    if (!packed) {
        UIImage *tiny = [source tg_scaleByFactor:0.25];
        packed = UIImageJPEGRepresentation(tiny ?: source, 0.3);
    }
    if (packed.length > (NSUInteger)maxBytes) {
        UIImage *tinier = [source tg_scaleByFactor:0.15];
        packed = UIImageJPEGRepresentation(tinier ?: source, 0.2);
    }
    return packed ? wrap(packed) : nil;
}

- (UIImage *)tg_imageCappedToMaxSide:(CGFloat)maxSide {
    CGFloat w = self.size.width * self.scale;
    CGFloat h = self.size.height * self.scale;
    CGFloat longSide = MAX(w, h);
    if (longSide <= maxSide || longSide <= 1) return self;
    CGFloat factor = maxSide / longSide;
    return [self tg_scaleByFactor:factor] ?: self;
}

- (NSData *)tg_jpegFoldLoopWithMaxBytes:(NSInteger)maxBytes minBytes:(NSInteger)minBytes {
    UIImage *working = self;
    NSData *estimateData = UIImageJPEGRepresentation(self, 0.85);
    if (!estimateData) {
        estimateData = UIImageJPEGRepresentation(self, 0.5);
    }
    if (estimateData.length > (NSUInteger)maxBytes * 2) {
        CGFloat factor = sqrt((maxBytes * 1.5) / MAX((CGFloat)estimateData.length, 1.0));
        factor = MAX(0.15, MIN(factor, 0.95));
        UIImage *scaled = [self tg_scaleByFactor:factor];
        if (scaled) working = scaled;
    }

    CGFloat quality = 0.85;
    NSData *best = nil;
    while (quality >= 0.1) {
        NSData *data = UIImageJPEGRepresentation(working, quality);
        if (!data) {
            quality -= 0.1;
            continue;
        }
        if (data.length <= (NSUInteger)maxBytes) {
            best = data;
            if (data.length >= (NSUInteger)minBytes) return data;
            break;
        }
        quality -= 0.1;
    }
    if (best && best.length < (NSUInteger)minBytes) {
        CGFloat bump = MIN(quality + 0.05, 0.95);
        NSData *better = UIImageJPEGRepresentation(working, bump);
        if (better.length <= (NSUInteger)maxBytes) return better;
        return best;
    }
    if (best) return best;
    return [working tg_scaleFoldLoopWithMaxBytes:maxBytes minBytes:minBytes];
}

- (UIImage *)tg_scaleByFactor:(CGFloat)factor {
    if (factor <= 0 || factor >= 1.0) return self;
    CGSize newSize = CGSizeMake(MAX(1.0, self.size.width * factor), MAX(1.0, self.size.height * factor));
    UIGraphicsBeginImageContextWithOptions(newSize, YES, 1);
    [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img ?: self;
}

- (NSData *)tg_scaleFoldLoopWithMaxBytes:(NSInteger)maxBytes minBytes:(NSInteger)minBytes {
    UIImage *current = self;
    CGFloat scaleFactor = 1.0;
    NSArray *qualities = @[@0.8, @0.6, @0.4, @0.3, @0.2];
    for (int iter = 0; iter < 20; iter++) {
        NSData *best = nil;
        for (NSNumber *qn in qualities) {
            NSData *data = UIImageJPEGRepresentation(current, qn.floatValue);
            if (!data) continue;
            if (data.length <= (NSUInteger)maxBytes) {
                if (data.length >= (NSUInteger)minBytes) return data;
                if (!best || data.length > best.length) best = data;
            }
        }
        if (best) return best;
        scaleFactor -= 0.1;
        if (scaleFactor < 0.15) {
            CGSize finalSize = CGSizeMake(MAX(1.0, self.size.width * 0.15), MAX(1.0, self.size.height * 0.15));
            UIGraphicsBeginImageContextWithOptions(finalSize, YES, 1);
            [self drawInRect:CGRectMake(0, 0, finalSize.width, finalSize.height)];
            UIImage *finalImg = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            return UIImageJPEGRepresentation(finalImg ?: self, 0.25);
        }
        CGSize newSize = CGSizeMake(MAX(1.0, self.size.width * scaleFactor), MAX(1.0, self.size.height * scaleFactor));
        UIGraphicsBeginImageContextWithOptions(newSize, YES, 1);
        [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
        current = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        if (!current) return UIImageJPEGRepresentation(self, 0.2);
    }
    return UIImageJPEGRepresentation(current ?: self, 0.2);
}

@end
