//

//

#import "TgKycIdentityController.h"
#import "TgKycIdUploadCard.h"
#import "TgKycDocCameraController.h"
#import "TgKycPathRelay.h"
#import "TgKycFormCell.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"
#import "TgPulseOverlay.h"
#import "TgShardFacade.h"
#import "TgKycVerifyFailPanelBody.h"
#import "TgTraceRelay.h"
#import "TgWireConduit.h"
#import "TgPackEnvelope.h"
#import "UIImage+TgGlyph.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>
#import <PhotosUI/PhotosUI.h>

static NSString * const kTgKycIdIdentity = @"identity";
static NSString * const kTgIdFrontCodeDefault = @"identity_front_img";
static NSString * const kTgIdBackCodeDefault = @"identity_back_img";
static NSString * const kTgIdCardCodeDefault = @"card_no";
static NSString * const kTgIdFrontAsset = @"use_Front";
static NSString * const kTgIdBackAsset = @"use_back";
static CGFloat const kTgIdHorzInset = 16.0;
static CGFloat const kTgIdContentTopInset = 31.0;
static NSString * const kTgIdBodyHex = @"#F1F1F1";
static CGFloat const kTgIdContinueHeight = 50.0;
static CGFloat const kTgIdContinueWidthRatio = 0.85;
static NSString * const kTgIdBusyHint = @"The system is occupied. Please retry after 2 minutes.";
static NSString * const kTgIdVerifyFailIllustration = @"use_id";
static NSString * const kTgIdVerifyFailButton = @"Upload again";

typedef NS_ENUM(NSInteger, TgKycIdPickSide) {
    TgKycIdPickSideNone = 0,
    TgKycIdPickSideFront,
    TgKycIdPickSideBack,
};

@interface TgKycIdentityController () <UITextFieldDelegate, PHPickerViewControllerDelegate>

@property (nonatomic, copy) NSString *tg_frontItemCode;
@property (nonatomic, copy) NSString *tg_backItemCode;
@property (nonatomic, copy) NSString *tg_cardItemCode;
@property (nonatomic, copy) NSString *tg_cardRegex;

@property (nonatomic, assign) BOOL tg_frontUploaded;
@property (nonatomic, assign) BOOL tg_backUploaded;
@property (nonatomic, assign) TgKycIdPickSide tg_pendingPickSide;

@property (nonatomic, strong) UIView *tg_bodyVeil;
@property (nonatomic, strong) UIScrollView *tg_scrollPane;
@property (nonatomic, strong) UIStackView *tg_contentStack;
@property (nonatomic, strong) UILabel *tg_sectionTitle;
@property (nonatomic, strong) TgKycIdUploadCard *tg_frontCard;
@property (nonatomic, strong) TgKycIdUploadCard *tg_backCard;
@property (nonatomic, strong) UILabel *tg_numberTitle;
@property (nonatomic, strong) UIView *tg_numberFieldVeil;
@property (nonatomic, strong) UITextField *tg_numberField;
@property (nonatomic, strong) UILabel *tg_hintLine1;
@property (nonatomic, strong) UILabel *tg_hintLine2;
@property (nonatomic, strong) UIButton *tg_continueLatch;

@end

@implementation TgKycIdentityController

- (instancetype)init {
    self = [super init];
    if (self) {
        _tg_frontItemCode = kTgIdFrontCodeDefault;
        _tg_backItemCode = kTgIdBackCodeDefault;
        _tg_cardItemCode = kTgIdCardCodeDefault;
        self.tg_backdropStyle = TgHullBackdropStyleUseBg0;
        self.tg_showsBackButton = YES;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self tg_setNavTitleMedium18:@"Aadhaar"];
    __weak typeof(self) weakSelf = self;
    self.tg_backInterceptBlock = ^BOOL {
        [weakSelf tg_showReturnConfirmDialog];
        return NO;
    };
    [self tg_buildLayout];
    [self tg_applyNumberFieldEnabled:NO];
    [self tg_loadKycInit];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - Layout

- (void)tg_buildLayout {
    self.tg_bodyVeil = [[UIView alloc] init];
    self.tg_bodyVeil.backgroundColor = [UIColor tg_toneFromHex:kTgIdBodyHex];
    [self.view insertSubview:self.tg_bodyVeil atIndex:1];

    self.tg_continueLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_continueLatch setTitle:@"Continue" forState:UIControlStateNormal];
    [self.tg_continueLatch setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.tg_continueLatch.titleLabel.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    self.tg_continueLatch.backgroundColor = [UIColor tg_toneFromHex:@"#182040"];
    self.tg_continueLatch.layer.cornerRadius = kTgIdContinueHeight / 2.0;
    self.tg_continueLatch.clipsToBounds = YES;
    [self.tg_continueLatch addTarget:self action:@selector(tg_onContinueTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.tg_continueLatch];

    self.tg_scrollPane = [[UIScrollView alloc] init];
    self.tg_scrollPane.showsVerticalScrollIndicator = NO;
    self.tg_scrollPane.alwaysBounceVertical = YES;
    self.tg_scrollPane.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:self.tg_scrollPane];

    self.tg_contentStack = [[UIStackView alloc] init];
    self.tg_contentStack.axis = UILayoutConstraintAxisVertical;
    self.tg_contentStack.spacing = 16;
    self.tg_contentStack.alignment = UIStackViewAlignmentFill;
    [self.tg_scrollPane addSubview:self.tg_contentStack];

    self.tg_sectionTitle = [[UILabel alloc] init];
    self.tg_sectionTitle.text = @"Please upload your Aadhaar card";
    self.tg_sectionTitle.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    self.tg_sectionTitle.textColor = [UIColor tg_toneFromHex:@"#364153"];
    self.tg_sectionTitle.numberOfLines = 0;
    [self.tg_contentStack addArrangedSubview:self.tg_sectionTitle];

    self.tg_frontCard = [[TgKycIdUploadCard alloc] initWithPlaceholderAsset:kTgIdFrontAsset sideLabel:@"Front"];
    self.tg_backCard = [[TgKycIdUploadCard alloc] initWithPlaceholderAsset:kTgIdBackAsset sideLabel:@"back"];
    [self.tg_contentStack addArrangedSubview:self.tg_frontCard];
    [self.tg_contentStack addArrangedSubview:self.tg_backCard];

    __weak typeof(self) weakSelf = self;
    self.tg_frontCard.tg_onPickTapped = ^{
        [weakSelf tg_presentSourcePickerForSide:TgKycIdPickSideFront];
    };
    self.tg_frontCard.tg_onDeleteTapped = ^{
        [weakSelf tg_clearFrontUpload];
    };
    self.tg_backCard.tg_onPickTapped = ^{
        [weakSelf tg_presentSourcePickerForSide:TgKycIdPickSideBack];
    };
    self.tg_backCard.tg_onDeleteTapped = ^{
        [weakSelf tg_clearBackUpload];
    };

    self.tg_numberTitle = [[UILabel alloc] init];
    self.tg_numberTitle.text = @"Aadhaar number";
    self.tg_numberTitle.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightMedium];
    self.tg_numberTitle.textColor = [UIColor tg_toneFromHex:@"#364153"];
    [self.tg_contentStack addArrangedSubview:self.tg_numberTitle];

    self.tg_numberFieldVeil = [[UIView alloc] init];
    self.tg_numberFieldVeil.backgroundColor = UIColor.whiteColor;
    self.tg_numberFieldVeil.layer.cornerRadius = 16.0;
    self.tg_numberFieldVeil.clipsToBounds = YES;
    [self.tg_contentStack addArrangedSubview:self.tg_numberFieldVeil];

    self.tg_numberField = [[UITextField alloc] init];
    self.tg_numberField.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    self.tg_numberField.textColor = [UIColor tg_toneFromHex:@"#364153"];
    self.tg_numberField.keyboardType = UIKeyboardTypeNumberPad;
    self.tg_numberField.delegate = self;
    self.tg_numberField.borderStyle = UITextBorderStyleNone;
    UIView *leftPad = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 10)];
    self.tg_numberField.leftView = leftPad;
    self.tg_numberField.leftViewMode = UITextFieldViewModeAlways;
    [self.tg_numberFieldVeil addSubview:self.tg_numberField];

    UIColor *hintColor = [UIColor tg_toneFromHex:@"#E67A2E"];
    self.tg_hintLine1 = [[UILabel alloc] init];
    self.tg_hintLine1.text = @"1. Please ensure the Aadhaar card you upload is authentic and valid.";
    self.tg_hintLine1.font = [UIFont tg_meshGlyphWithSize:13 weight:UIFontWeightRegular];
    self.tg_hintLine1.textColor = hintColor;
    self.tg_hintLine1.numberOfLines = 0;
    self.tg_hintLine1.textAlignment = NSTextAlignmentLeft;
    [self.tg_contentStack addArrangedSubview:self.tg_hintLine1];

    self.tg_hintLine2 = [[UILabel alloc] init];
    self.tg_hintLine2.text = @"2. Please ensure the uploaded Aadhaar photo is clear and complete; otherwise verification will fail.";
    self.tg_hintLine2.font = [UIFont tg_meshGlyphWithSize:13 weight:UIFontWeightRegular];
    self.tg_hintLine2.textColor = hintColor;
    self.tg_hintLine2.numberOfLines = 0;
    self.tg_hintLine2.textAlignment = NSTextAlignmentLeft;
    [self.tg_contentStack addArrangedSubview:self.tg_hintLine2];

    [self.tg_bodyVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset([self tg_contentTopBelowNavigation]);
        make.bottom.equalTo(self.tg_continueLatch.mas_top).offset(-12);
    }];
    [self.tg_continueLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(kTgIdContinueWidthRatio);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-16);
        make.height.mas_equalTo(kTgIdContinueHeight);
    }];
    [self.tg_scrollPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_bodyVeil);
    }];
    [self.tg_contentStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_scrollPane).insets(UIEdgeInsetsMake(kTgIdContentTopInset, kTgIdHorzInset, 24, kTgIdHorzInset));
        make.width.equalTo(self.tg_scrollPane).offset(-kTgIdHorzInset * 2);
    }];
    [self.tg_numberField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_numberFieldVeil).insets(UIEdgeInsetsMake(0, 0, 0, 12));
        make.height.mas_equalTo(TgKycFormCellFieldHeight);
    }];
}

#pragma mark - Init

- (void)tg_loadKycInit {
    [[TgPulseOverlay shared] veilSpin:nil];
    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneKycInit
                             signData:@{ @"kycId": kTgKycIdIdentity }
                           nonSignData:@{}
                              success:^(id _Nullable data) {
        TgKYCInitData *initData = [TgKYCInitData yy_modelWithJSON:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[TgPulseOverlay shared] veilDismiss];
            [weakSelf tg_applyInitData:initData];
        });
    } failure:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[TgPulseOverlay shared] veilDismiss];
            [[TgPulseOverlay shared] whisperLine:kTgIdBusyHint];
        });
    }];
}

- (void)tg_applyInitData:(TgKYCInitData *)initData {
    if (!initData || initData.nevertheless.count == 0) return;
    for (TgKYCFormItem *item in initData.nevertheless) {
        NSString *code = [item.performance lowercaseString];
        if (code.length == 0) continue;
        if ([code containsString:@"front"]) {
            self.tg_frontItemCode = item.performance;
        } else if ([code containsString:@"back"]) {
            self.tg_backItemCode = item.performance;
        } else if ([code isEqualToString:@"card_no"] || [code containsString:@"card_no"]) {
            self.tg_cardItemCode = item.performance;
            if (item.keen.length > 0) {
                self.tg_cardRegex = item.keen;
            }
        }
    }
}

#pragma mark - Upload state

- (void)tg_applyNumberFieldEnabled:(BOOL)enabled {
    self.tg_numberField.enabled = enabled;
    self.tg_numberFieldVeil.alpha = enabled ? 1.0 : 0.55;
}

- (void)tg_clearFrontUpload {
    self.tg_frontUploaded = NO;
    [self.tg_frontCard tg_clearUpload];
    self.tg_numberField.text = @"";
    [self tg_applyNumberFieldEnabled:NO];
}

- (void)tg_clearBackUpload {
    self.tg_backUploaded = NO;
    [self.tg_backCard tg_clearUpload];
}

- (NSString *)tg_cardNumberText {
    return [[self.tg_numberField.text ?: @"" stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
            stringByReplacingOccurrencesOfString:@" " withString:@""];
}

- (void)tg_fillCardNumberFromEcho:(TgIdCardEchoMap *)echo {
    if (!echo.cardNo) return;
    NSString *text = nil;
    if ([echo.cardNo isKindOfClass:[NSString class]]) {
        text = (NSString *)echo.cardNo;
    } else if ([echo.cardNo isKindOfClass:[NSNumber class]]) {
        text = [(NSNumber *)echo.cardNo stringValue];
    }
    if (text.length > 0) {
        self.tg_numberField.text = text;
        [self tg_applyNumberFieldEnabled:YES];
    }
}

#pragma mark - Source picker

- (void)tg_presentSourcePickerForSide:(TgKycIdPickSide)side {
    self.tg_pendingPickSide = side;
    if (side == TgKycIdPickSideFront) {
        [TgTraceRelay emitSignal:TgTraceSignalIdFrontPick];
    } else if (side == TgKycIdPickSideBack) {
        [TgTraceRelay emitSignal:TgTraceSignalIdBackPick];
    }

    __weak typeof(self) weakSelf = self;
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil
                                                                 message:nil
                                                          preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Open the photo library"
                                              style:UIAlertActionStyleDefault
                                            handler:^(__unused UIAlertAction *action) {
        if (side == TgKycIdPickSideFront) {
            [TgTraceRelay emitSignal:TgTraceSignalIdFrontAlbum];
        } else {
            [TgTraceRelay emitSignal:TgTraceSignalIdBackAlbum];
        }
        [weakSelf tg_openPhotoLibrary];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Enable the camera"
                                              style:UIAlertActionStyleDefault
                                            handler:^(__unused UIAlertAction *action) {
        if (side == TgKycIdPickSideFront) {
            [TgTraceRelay emitSignal:TgTraceSignalIdFrontCamera];
        } else {
            [TgTraceRelay emitSignal:TgTraceSignalIdBackCamera];
        }
        NSString *token = (side == TgKycIdPickSideFront) ? @"front" : @"back";
        [TgKycDocCameraController presentFrom:weakSelf sceneToken:token completion:^(UIImage *image) {
            if (image) {
                [weakSelf tg_uploadImage:image forSide:side];
            }
        }];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    if (sheet.popoverPresentationController) {
        TgKycIdUploadCard *card = (side == TgKycIdPickSideFront) ? self.tg_frontCard : self.tg_backCard;
        sheet.popoverPresentationController.sourceView = card;
        sheet.popoverPresentationController.sourceRect = card.bounds;
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)tg_openPhotoLibrary {
    PHPickerConfiguration *cfg = [[PHPickerConfiguration alloc] init];
    cfg.selectionLimit = 1;
    cfg.filter = [PHPickerFilter imagesFilter];
    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:cfg];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - PHPicker

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (results.count == 0 || self.tg_pendingPickSide == TgKycIdPickSideNone) return;
    TgKycIdPickSide side = self.tg_pendingPickSide;
    if (side == TgKycIdPickSideFront) {
        [TgTraceRelay emitSignal:TgTraceSignalIdFrontAlbumPick];
    } else if (side == TgKycIdPickSideBack) {
        [TgTraceRelay emitSignal:TgTraceSignalIdBackAlbumPick];
    }
    self.tg_pendingPickSide = TgKycIdPickSideNone;

    PHPickerResult *result = results.firstObject;
    __weak typeof(self) weakSelf = self;
    [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(id object, NSError *error) {
        if (error || ![object isKindOfClass:[UIImage class]]) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf tg_uploadImage:(UIImage *)object forSide:side];
        });
    }];
}

#pragma mark - Item commit

- (BOOL)tg_isVerifyFailedCode:(NSInteger)code {
    return TgFaultIsCertVerifyFailed(code);
}

- (void)tg_showVerifyFailedPanel {
    [TgTraceRelay emitSignal:TgTraceSignalKycVerifyFail];
    UIView *body = [TgKycVerifyFailPanelBody tg_buildWithIllustrationAsset:kTgIdVerifyFailIllustration];
    TgShardPanelConfig *cfg = [[TgShardPanelConfig alloc] init];
    cfg.panelStyle = TgShardPanelStyleCustomBody;
    cfg.customBodyView = body;
    cfg.customBodyHeight = 0;
    cfg.primaryTitle = kTgIdVerifyFailButton;
    cfg.primaryAction = ^{
        [[TgShardFacade shared] dismissTopPanel];
    };
    [[TgShardFacade shared] showPanel:cfg];
}

- (NSString *)tg_base64FromImage:(UIImage *)image {
    TgPackEnvelope *pack = [image tg_foldPayloadMinKB:200 maxKB:800];
    return pack.base64Payload ?: @"";
}

- (TgIdCardEchoMap *)tg_echoMapFromEnvelope:(TgEnvelopeBase *)envelope {
    TgKycItemCommitData *commit = [TgKycItemCommitData yy_modelWithJSON:envelope.trick];
    if (commit.history) return commit.history;
    if (![envelope.trick isKindOfClass:[NSDictionary class]]) return nil;
    return [TgIdCardEchoMap yy_modelWithJSON:[(NSDictionary *)envelope.trick objectForKey:@"echoMap"]];
}

- (void)tg_uploadImage:(UIImage *)image forSide:(TgKycIdPickSide)side {
    NSString *itemCode = (side == TgKycIdPickSideFront) ? self.tg_frontItemCode : self.tg_backItemCode;
    NSString *base64 = [self tg_base64FromImage:image];
    if (base64.length == 0) {
        [[TgPulseOverlay shared] whisperLine:kTgIdBusyHint];
        return;
    }

    [[TgPulseOverlay shared] veilSpin:nil];
    NSDictionary *sign = @{
        @"kycId": kTgKycIdIdentity,
        @"itemCode": itemCode ?: @"",
        @"itemValueType": @2,
        @"itemValue": base64
    };
    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneKycItemCommit
                             signData:sign
                           nonSignData:@{}
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        [[TgPulseOverlay shared] veilDismiss];
        if ([weakSelf tg_isVerifyFailedCode:envelope.cheer]) {
            [weakSelf tg_showVerifyFailedPanel];
            return;
        }
        if (!envelope.isSuccess) {
            if (envelope.power.length > 0) {
                [[TgPulseOverlay shared] whisperLine:envelope.power];
            }
            return;
        }
        if (side == TgKycIdPickSideFront) {
            weakSelf.tg_frontUploaded = YES;
            [weakSelf.tg_frontCard tg_setUploadedImage:image];
            [weakSelf tg_applyNumberFieldEnabled:YES];
            [weakSelf tg_fillCardNumberFromEcho:[weakSelf tg_echoMapFromEnvelope:envelope]];
            [TgTraceRelay emitSignal:TgTraceSignalIdFrontCapture];
        } else {
            weakSelf.tg_backUploaded = YES;
            [weakSelf.tg_backCard tg_setUploadedImage:image];
            [TgTraceRelay emitSignal:TgTraceSignalIdBackCapture];
        }
    } failure:^{
        [[TgPulseOverlay shared] veilDismiss];
        [[TgPulseOverlay shared] whisperLine:kTgIdBusyHint];
    }];
}

#pragma mark - Continue

- (BOOL)tg_passesRegex:(NSString *)value pattern:(NSString *)pattern {
    if (pattern.length == 0) return YES;
    @try {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
        return [predicate evaluateWithObject:value ?: @""];
    } @catch (__unused NSException *exception) {
        return YES;
    }
}

- (BOOL)tg_validateBeforeContinue {
    if (!self.tg_frontUploaded) {
        [[TgPulseOverlay shared] whisperLine:@"Please upload the front side of your Aadhaar"];
        return NO;
    }
    if (!self.tg_backUploaded) {
        [[TgPulseOverlay shared] whisperLine:@"Please upload the back side of your Aadhaar"];
        return NO;
    }
    NSString *number = [self tg_cardNumberText];
    if (number.length == 0) {
        [[TgPulseOverlay shared] whisperLine:@"Please type in your Aadhaar number"];
        return NO;
    }
    if (![self tg_passesRegex:number pattern:self.tg_cardRegex]) {
        [[TgPulseOverlay shared] whisperLine:@"The Aadhaar number format is invalid"];
        return NO;
    }
    return YES;
}

- (void)tg_onContinueTap {
    [self.view endEditing:YES];
    if (![self tg_validateBeforeContinue]) return;

    NSString *number = [self tg_cardNumberText];
    [[TgPulseOverlay shared] veilSpin:nil];
    NSDictionary *sign = @{
        @"kycId": kTgKycIdIdentity,
        @"itemCode": self.tg_cardItemCode ?: kTgIdCardCodeDefault,
        @"itemValueType": @1,
        @"itemValue": number
    };
    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneKycItemCommit
                             signData:sign
                           nonSignData:@{}
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        [[TgPulseOverlay shared] veilDismiss];
        if ([weakSelf tg_isVerifyFailedCode:envelope.cheer]) {
            [weakSelf tg_showVerifyFailedPanel];
            return;
        }
        if (!envelope.isSuccess) {
            if (envelope.power.length > 0) {
                [[TgPulseOverlay shared] whisperLine:envelope.power];
            }
            return;
        }
        [TgTraceRelay emitSignal:TgTraceSignalIdVerifySubmit];
        [TgKycPathRelay continueAfterCommitFromNav:weakSelf.navigationController];
    } failure:^{
        [[TgPulseOverlay shared] veilDismiss];
        [[TgPulseOverlay shared] whisperLine:kTgIdBusyHint];
    }];
}

#pragma mark - Back

- (void)tg_showReturnConfirmDialog {
    TgShardPanelConfig *cfg = [[TgShardPanelConfig alloc] init];
    cfg.title = @"Confirm to return?";
    cfg.content = @"Do you want to pause authentication and go back";
    cfg.secondaryTitle = @"Cancel";
    cfg.primaryTitle = @"Confirm";
    cfg.secondaryAction = ^{
        [[TgShardFacade shared] dismissTopPanel];
    };
    __weak typeof(self) weakSelf = self;
    cfg.primaryAction = ^{
        [[TgShardFacade shared] dismissTopPanel];
        [weakSelf.navigationController popViewControllerAnimated:YES];
    };
    [[TgShardFacade shared] showPanel:cfg];
}

@end
