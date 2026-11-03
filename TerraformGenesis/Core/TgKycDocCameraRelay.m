//
//  TgKycDocCameraRelay.m
//

#import "TgKycDocCameraRelay.h"
#import <AVFoundation/AVFoundation.h>

@interface TgKycDocCameraRelay () <AVCapturePhotoCaptureDelegate>

@property (nonatomic, strong) AVCaptureSession *tg_session;
@property (nonatomic, strong) AVCapturePhotoOutput *tg_photoOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *tg_previewLayer;
@property (nonatomic, strong) dispatch_queue_t tg_sessionQueue;
@property (nonatomic, copy, nullable) void (^tg_captureCompletion)(UIImage * _Nullable);
@property (nonatomic, assign) BOOL tg_preparing;
@property (nonatomic, assign) BOOL tg_capturing;
@property (nonatomic, strong) NSMutableArray<void (^)(BOOL)> *tg_prepareWaiters;

@end

@implementation TgKycDocCameraRelay

- (instancetype)init {
    self = [super init];
    if (self) {
        _tg_sessionQueue = dispatch_queue_create("com.terraformgenesis.kyc.doc.capture", DISPATCH_QUEUE_SERIAL);
        _tg_prepareWaiters = [NSMutableArray array];
    }
    return self;
}

- (void)setTg_previewHost:(UIView *)tg_previewHost {
    _tg_previewHost = tg_previewHost;
    if (self.tg_session) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self tg_attachPreviewLayerOnMain];
        });
    }
}

- (void)tg_prepareSession {
    [self tg_prepareSessionWithCompletion:nil];
}

- (void)tg_prepareSessionWithCompletion:(void (^ _Nullable)(BOOL success))completion {
    if (self.tg_session) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self tg_attachPreviewLayerOnMain];
            if (completion) completion(YES);
        });
        return;
    }

    if (completion) {
        [self.tg_prepareWaiters addObject:[completion copy]];
    }
    if (self.tg_preparing) return;
    self.tg_preparing = YES;

    __weak typeof(self) weakSelf = self;
    dispatch_async(self.tg_sessionQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        AVCaptureDevice *device = [strongSelf tg_backCameraDevice];
        if (!device) {
            [strongSelf tg_finishPrepareWithSuccess:NO];
            return;
        }

        AVCaptureSession *session = [[AVCaptureSession alloc] init];
        [session beginConfiguration];
        if ([session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
            session.sessionPreset = AVCaptureSessionPreset1280x720;
        } else if ([session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
            session.sessionPreset = AVCaptureSessionPresetHigh;
        }

        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        if (!input || error || ![session canAddInput:input]) {
            [session commitConfiguration];
            [strongSelf tg_finishPrepareWithSuccess:NO];
            return;
        }
        [session addInput:input];
        [strongSelf tg_configureDeviceForDocument:device];

        AVCapturePhotoOutput *output = [[AVCapturePhotoOutput alloc] init];
        if (![session canAddOutput:output]) {
            [session commitConfiguration];
            [strongSelf tg_finishPrepareWithSuccess:NO];
            return;
        }
        [session addOutput:output];
        [session commitConfiguration];

        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.tg_session = session;
            strongSelf.tg_photoOutput = output;
            [strongSelf tg_attachPreviewLayerOnMain];
            [strongSelf tg_finishPrepareWithSuccess:YES];
        });
    });
}

- (void)tg_finishPrepareWithSuccess:(BOOL)success {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.tg_preparing = NO;
        NSArray<void (^)(BOOL)> *waiters = [self.tg_prepareWaiters copy];
        [self.tg_prepareWaiters removeAllObjects];
        for (void (^cb)(BOOL) in waiters) {
            cb(success);
        }
    });
}

- (AVCaptureDevice *)tg_backCameraDevice {
    // Prefer ultra-wide → wide → any back camera.
    if (@available(iOS 13.0, *)) {
        AVCaptureDevice *ultra = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInUltraWideCamera
                                                                    mediaType:AVMediaTypeVideo
                                                                     position:AVCaptureDevicePositionBack];
        if (ultra) return ultra;
    }

    AVCaptureDevice *wide = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
                                                               mediaType:AVMediaTypeVideo
                                                                position:AVCaptureDevicePositionBack];
    if (wide) return wide;

    AVCaptureDeviceDiscoverySession *discovery =
        [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera]
                                                               mediaType:AVMediaTypeVideo
                                                                position:AVCaptureDevicePositionBack];
    for (AVCaptureDevice *device in discovery.devices) {
        if (device.position == AVCaptureDevicePositionBack) {
            return device;
        }
    }
    return nil;
}

- (void)tg_attachPreviewLayerOnMain {
    if (!self.tg_session || !self.tg_previewHost) return;

    if (self.tg_previewLayer
        && self.tg_previewLayer.session == self.tg_session
        && self.tg_previewLayer.superlayer == self.tg_previewHost.layer) {
        [self tg_updatePreviewLayout];
        return;
    }

    if (self.tg_previewLayer) {
        [self.tg_previewLayer removeFromSuperlayer];
        self.tg_previewLayer = nil;
    }

    self.tg_previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.tg_session];
    self.tg_previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.tg_previewLayer.frame = self.tg_previewHost.bounds;
    [self.tg_previewHost.layer insertSublayer:self.tg_previewLayer atIndex:0];
    [self tg_applyPreviewOrientation];
}

- (void)tg_applyPreviewOrientation {
    AVCaptureConnection *connection = self.tg_previewLayer.connection;
    if (!connection) return;

    if (@available(iOS 17.0, *)) {
        if ([connection isVideoRotationAngleSupported:90.0]) {
            connection.videoRotationAngle = 90.0;
        }
    } else if (connection.isVideoOrientationSupported) {
        connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
}

- (void)tg_updatePreviewLayout {
    if (!self.tg_previewLayer || !self.tg_previewHost) return;
    CGRect bounds = self.tg_previewHost.bounds;
    if (bounds.size.width < 1 || bounds.size.height < 1) return;
    self.tg_previewLayer.frame = bounds;
    [self tg_applyPreviewOrientation];
}

- (void)tg_setPreviewHidden:(BOOL)hidden {
    self.tg_previewLayer.hidden = hidden;
}

- (void)tg_startRunning {
    __weak typeof(self) weakSelf = self;
    if (!self.tg_session) {
        [self tg_prepareSessionWithCompletion:^(BOOL success) {
            if (success) {
                [weakSelf tg_startRunning];
            }
        }];
        return;
    }
    if (self.tg_session.isRunning) return;
    dispatch_async(self.tg_sessionQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf.tg_session || strongSelf.tg_session.isRunning) return;
        [strongSelf.tg_session startRunning];
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf tg_updatePreviewLayout];
        });
    });
}

- (void)tg_stopRunning {
    if (!self.tg_session || !self.tg_session.isRunning) return;
    dispatch_async(self.tg_sessionQueue, ^{
        if (self.tg_session.isRunning) {
            [self.tg_session stopRunning];
        }
    });
}

- (void)tg_capturePhoto:(void (^)(UIImage * _Nullable))completion {
    if (!completion) return;
    if (self.tg_capturing) return;
    if (!self.tg_photoOutput || !self.tg_session.isRunning) {
        completion(nil);
        return;
    }
    self.tg_capturing = YES;
    self.tg_captureCompletion = completion;
    AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];
    if (self.tg_photoOutput.supportedFlashModes.count > 0) {
        settings.flashMode = AVCaptureFlashModeOff;
    }
    [self.tg_photoOutput capturePhotoWithSettings:settings delegate:self];
}

- (void)tg_configureDeviceForDocument:(AVCaptureDevice *)device {
    if (!device) return;
    NSError *error = nil;
    if (![device lockForConfiguration:&error]) return;
    if (device.isAutoFocusRangeRestrictionSupported) {
        device.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionNear;
    }
    if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
    }
    [device unlockForConfiguration];
}

- (UIImage *)tg_rotateCounterClockwise90:(UIImage *)image {
    if (!image) return nil;
    CGSize rotatedSize = CGSizeMake(image.size.height, image.size.width);
    UIGraphicsBeginImageContextWithOptions(rotatedSize, NO, image.scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) {
        UIGraphicsEndImageContext();
        return image;
    }
    CGContextTranslateCTM(ctx, rotatedSize.width / 2.0, rotatedSize.height / 2.0);
    CGContextRotateCTM(ctx, -(CGFloat)M_PI_2);
    [image drawInRect:CGRectMake(-image.size.width / 2.0,
                               -image.size.height / 2.0,
                               image.size.width,
                               image.size.height)];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result ?: image;
}

#pragma mark - AVCapturePhotoCaptureDelegate

- (void)captureOutput:(AVCapturePhotoOutput *)output
didFinishProcessingPhoto:(AVCapturePhoto *)photo
                error:(NSError *)error {
    UIImage *image = nil;
    if (!error) {
        NSData *data = [photo fileDataRepresentation];
        image = data ? [UIImage imageWithData:data] : nil;
    }
    void (^completion)(UIImage *) = self.tg_captureCompletion;
    self.tg_captureCompletion = nil;
    self.tg_capturing = NO;
    if (!completion) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        completion(image);
    });
}

@end
