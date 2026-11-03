//
//  TgKycFaceCaptureRelay.m
//

#import "TgKycFaceCaptureRelay.h"
#import <AVFoundation/AVFoundation.h>

@interface TgKycFaceCaptureRelay () <AVCapturePhotoCaptureDelegate>

@property (nonatomic, strong, nullable) AVCaptureSession *tg_session;
@property (nonatomic, strong, nullable) AVCapturePhotoOutput *tg_photoOutput;
@property (nonatomic, strong, nullable) AVCaptureVideoPreviewLayer *tg_previewLayer;
@property (nonatomic, strong) dispatch_queue_t tg_sessionQueue;
@property (nonatomic, copy, nullable) void (^tg_captureCompletion)(UIImage * _Nullable);

@end

@implementation TgKycFaceCaptureRelay

- (instancetype)init {
    self = [super init];
    if (self) {
        _tg_sessionQueue = dispatch_queue_create("com.terraformgenesis.kyc.face.capture", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - Session

- (void)tg_prepareSession {
    [self tg_prepareSessionWithCompletion:nil];
}

- (void)tg_prepareSessionWithCompletion:(void (^)(BOOL))completion {
    if (self.tg_session) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self tg_attachPreviewLayerOnMain];
            if (completion) completion(YES);
        });
        return;
    }

    __weak typeof(self) weakSelf = self;
    dispatch_async(self.tg_sessionQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            [TgKycFaceCaptureRelay tg_dispatchMainBool:NO completion:completion];
            return;
        }

        AVCaptureDevice *device = [strongSelf tg_frontCameraDevice];
        if (!device) {
            [TgKycFaceCaptureRelay tg_dispatchMainBool:NO completion:completion];
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
            [TgKycFaceCaptureRelay tg_dispatchMainBool:NO completion:completion];
            return;
        }
        [session addInput:input];
        [strongSelf tg_configureDeviceForFace:device];

        AVCapturePhotoOutput *output = [[AVCapturePhotoOutput alloc] init];
        output.highResolutionCaptureEnabled = NO;
        if (![session canAddOutput:output]) {
            [session commitConfiguration];
            [TgKycFaceCaptureRelay tg_dispatchMainBool:NO completion:completion];
            return;
        }
        [session addOutput:output];
        [session commitConfiguration];

        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.tg_session = session;
            strongSelf.tg_photoOutput = output;
            [strongSelf tg_attachPreviewLayerOnMain];
            if (completion) completion(YES);
        });
    });
}

+ (void)tg_dispatchMainBool:(BOOL)value completion:(void (^)(BOOL))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completion) completion(value);
    });
}

- (BOOL)tg_isSessionRunning {
    return self.tg_session.isRunning;
}

- (void)tg_startRunning {
    [self tg_startRunningWithCompletion:nil];
}

- (void)tg_startRunningWithCompletion:(void (^)(BOOL))completion {
    __weak typeof(self) weakSelf = self;
    if (!self.tg_session) {
        [self tg_prepareSessionWithCompletion:^(BOOL success) {
            if (success) {
                [weakSelf tg_startRunningWithCompletion:completion];
            } else if (completion) {
                completion(NO);
            }
        }];
        return;
    }
    if (self.tg_session.isRunning) {
        if (completion) completion(YES);
        return;
    }

    __block id observer = nil;
    observer = [[NSNotificationCenter defaultCenter]
        addObserverForName:AVCaptureSessionDidStartRunningNotification
                      object:self.tg_session
                       queue:[NSOperationQueue mainQueue]
                  usingBlock:^(__unused NSNotification *note) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
        if (completion) completion(YES);
    }];

    dispatch_async(self.tg_sessionQueue, ^{
        [weakSelf.tg_session startRunning];
    });
}

- (void)tg_stopRunning {
    if (!self.tg_session || !self.tg_session.isRunning) return;
    dispatch_async(self.tg_sessionQueue, ^{
        [self.tg_session stopRunning];
    });
}

#pragma mark - Preview

- (void)setTg_previewHost:(UIView *)tg_previewHost {
    _tg_previewHost = tg_previewHost;
    if (self.tg_session) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self tg_attachPreviewLayerOnMain];
        });
    }
}

- (void)tg_attachPreviewLayerOnMain {
    if (!self.tg_session || !self.tg_previewHost) return;

    if (self.tg_previewLayer) {
        [self.tg_previewLayer removeFromSuperlayer];
        self.tg_previewLayer = nil;
    }

    self.tg_previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.tg_session];
    self.tg_previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.tg_previewLayer.frame = self.tg_previewHost.bounds;
    [self.tg_previewHost.layer insertSublayer:self.tg_previewLayer atIndex:0];
    [self tg_applyFrontCameraMirroring];
}

- (void)tg_applyFrontCameraMirroring {
    AVCaptureConnection *connection = self.tg_previewLayer.connection;
    if (connection.isVideoMirroringSupported) {
        connection.automaticallyAdjustsVideoMirroring = NO;
        connection.videoMirrored = YES;
    }
}

- (void)tg_updatePreviewLayout {
    if (self.tg_previewLayer && self.tg_previewHost) {
        self.tg_previewLayer.frame = self.tg_previewHost.bounds;
    }
}

- (void)tg_setPreviewHidden:(BOOL)hidden {
    self.tg_previewLayer.hidden = hidden;
}

#pragma mark - Device

- (AVCaptureDevice *)tg_frontCameraDevice {
    NSArray<AVCaptureDeviceType> *types = @[AVCaptureDeviceTypeBuiltInWideAngleCamera];
    if (@available(iOS 13.0, *)) {
        NSMutableArray<AVCaptureDeviceType> *extended = [types mutableCopy];
        if (@available(iOS 15.4, *)) {
            [extended addObject:AVCaptureDeviceTypeBuiltInUltraWideCamera];
        }
        types = extended;
    }
    AVCaptureDeviceDiscoverySession *discovery = [AVCaptureDeviceDiscoverySession
        discoverySessionWithDeviceTypes:types
                              mediaType:AVMediaTypeVideo
                               position:AVCaptureDevicePositionFront];
    for (AVCaptureDevice *device in discovery.devices) {
        if (device.position == AVCaptureDevicePositionFront) {
            return device;
        }
    }
    return [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
                                              mediaType:AVMediaTypeVideo
                                               position:AVCaptureDevicePositionFront];
}

- (void)tg_configureDeviceForFace:(AVCaptureDevice *)device {
    if (!device) return;
    NSError *error = nil;
    if (![device lockForConfiguration:&error]) return;
    if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
    }
    if ([device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    }
    if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
        device.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
    }
    [device unlockForConfiguration];
}

#pragma mark - Capture

- (void)tg_capturePhoto:(void (^)(UIImage * _Nullable))completion {
    if (!completion) return;

    __weak typeof(self) weakSelf = self;
    dispatch_async(self.tg_sessionQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || !strongSelf.tg_session.isRunning || !strongSelf.tg_photoOutput) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil);
            });
            return;
        }

        strongSelf.tg_captureCompletion = completion;
        AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];
        if (@available(iOS 13.0, *)) {
            settings.photoQualityPrioritization = AVCapturePhotoQualityPrioritizationSpeed;
        }
        if (strongSelf.tg_photoOutput.supportedFlashModes.count > 0) {
            settings.flashMode = AVCaptureFlashModeOff;
        }
        [strongSelf.tg_photoOutput capturePhotoWithSettings:settings delegate:strongSelf];
    });
}

- (UIImage *)tg_horizontallyFlippedImage:(UIImage *)image {
    if (!image) return nil;
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = image.scale;
    format.opaque = NO;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:image.size format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        CGContextTranslateCTM(ctx.CGContext, image.size.width, 0);
        CGContextScaleCTM(ctx.CGContext, -1.0, 1.0);
        [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    }];
}

#pragma mark - AVCapturePhotoCaptureDelegate

- (void)captureOutput:(AVCapturePhotoOutput *)output
didFinishProcessingPhoto:(AVCapturePhoto *)photo
                error:(NSError *)error {
    UIImage *image = nil;
    if (!error) {
        NSData *data = [photo fileDataRepresentation];
        UIImage *raw = data ? [UIImage imageWithData:data] : nil;
        image = [self tg_horizontallyFlippedImage:raw];
    }
    void (^completion)(UIImage *) = self.tg_captureCompletion;
    self.tg_captureCompletion = nil;
    if (!completion) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        completion(image);
    });
}

@end
