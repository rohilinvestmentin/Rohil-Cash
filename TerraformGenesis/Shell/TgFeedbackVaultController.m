//

//

#import "TgFeedbackVaultController.h"
#import "TgDockBarRelay.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"
#import "TgPulseOverlay.h"
#import "TgWireConduit.h"
#import "TgEnvelopeBase.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import "NSString+TgGlyph.h"
#import "UIImage+TgGlyph.h"
#import "TgPackEnvelope.h"
#import <Masonry/Masonry.h>
#import <PhotosUI/PhotosUI.h>

static CGFloat const kTgFbHorzInset = 16.0;
static CGFloat const kTgFbSubmitHeight = 50.0;
static CGFloat const kTgFbSubmitWidthRatio = 0.8;
static NSInteger const kTgFbMaxQuestionLen = 1000;
static NSInteger const kTgFbMaxImages = 3;
static NSString * const kTgFbBodyToneHex = @"#F1F1F1";
static NSString * const kTgFbUploadToneHex = @"#C51B12";
static NSString * const kTgFbNoticeTextHex = @"#EA834C";
static NSString * const kTgFbNoticeBgHex = @"#FCF4EE";
static NSString * const kTgFbQuestionPlaceholder = @"Please type in your question";
static NSString * const kTgFbNoticeText =
@"You may describe the issue in detail here, or email us and leave your contact details - we will reach out as soon as possible!";
static NSString * const kTgFbBusyHint = @"The system is occupied. Please retry after 2 minutes.";
static NSString * const kTgFbSuccessHint = @"Thank you for your feedback!";

@interface TgFbDashPaneView : UIView
@end

@implementation TgFbDashPaneView

- (void)layoutSubviews {
    [super layoutSubviews];
    NSArray *sublayers = [self.layer.sublayers copy];
    for (CALayer *layer in sublayers) {
        if ([layer.name isEqualToString:@"tg_fb_dash"]) {
            [layer removeFromSuperlayer];
        }
    }
    CAShapeLayer *dash = [CAShapeLayer layer];
    dash.name = @"tg_fb_dash";
    dash.frame = self.bounds;
    dash.fillColor = UIColor.clearColor.CGColor;
    dash.strokeColor = [UIColor tg_toneFromHex:kTgFbUploadToneHex].CGColor;
    dash.lineWidth = 1.0;
    dash.lineDashPattern = @[@6, @4];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 0.5, 0.5) cornerRadius:12];
    dash.path = path.CGPath;
    [self.layer addSublayer:dash];
}

@end

@interface TgFeedbackVaultController () <UITextViewDelegate, PHPickerViewControllerDelegate>

@property (nonatomic, assign) BOOL tg_popToRootOnBack;
@property (nonatomic, strong) UIView *tg_bodyVeil;
@property (nonatomic, strong) UIScrollView *tg_scrollPane;
@property (nonatomic, strong) UIStackView *tg_contentStack;
@property (nonatomic, strong) UIView *tg_questionShell;
@property (nonatomic, strong) UITextView *tg_questionPane;
@property (nonatomic, strong) UILabel *tg_countCaption;
@property (nonatomic, strong) UIView *tg_imagesRail;
@property (nonatomic, strong) UIButton *tg_submitLatch;
@property (nonatomic, strong) NSMutableArray<UIImage *> *tg_pickedImages;
@property (nonatomic, copy) NSString *tg_cachedMobile;
@property (nonatomic, assign) BOOL tg_questionPlaceholderOn;
@property (nonatomic, assign) BOOL tg_submitBusy;

@end

@implementation TgFeedbackVaultController

- (instancetype)init {
    return [self initWithPopToRootOnBack:NO];
}

- (instancetype)initWithPopToRootOnBack:(BOOL)popToRoot {
    self = [super init];
    if (self) {
        _tg_popToRootOnBack = popToRoot;
        _tg_pickedImages = [NSMutableArray array];
        _tg_questionPlaceholderOn = YES;
        self.tg_backdropStyle = TgHullBackdropStyleUseBg0;
        self.tg_showsBackButton = YES;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self tg_setNavTitleMedium18:@"Feedback"];
    __weak typeof(self) weakSelf = self;
    self.tg_backInterceptBlock = ^BOOL {
        __strong typeof(weakSelf) self = weakSelf;
        if (self.tg_popToRootOnBack) {
            [self tg_popToLoanHome];
            return NO;
        }
        return YES;
    };
    [self tg_buildLayout];
    [self tg_pullCachedMobile];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - Layout

- (void)tg_buildLayout {
    self.tg_bodyVeil = [[UIView alloc] init];
    self.tg_bodyVeil.backgroundColor = [UIColor tg_toneFromHex:kTgFbBodyToneHex];
    [self.view insertSubview:self.tg_bodyVeil atIndex:1];

    self.tg_submitLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_submitLatch setTitle:@"Submit" forState:UIControlStateNormal];
    [self.tg_submitLatch setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.tg_submitLatch.titleLabel.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    self.tg_submitLatch.backgroundColor = [UIColor tg_toneFromHex:@"#182040"];
    self.tg_submitLatch.layer.cornerRadius = kTgFbSubmitHeight / 2.0;
    self.tg_submitLatch.clipsToBounds = YES;
    [self.tg_submitLatch addTarget:self action:@selector(tg_onSubmitTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.tg_submitLatch];

    self.tg_scrollPane = [[UIScrollView alloc] init];
    self.tg_scrollPane.showsVerticalScrollIndicator = NO;
    self.tg_scrollPane.alwaysBounceVertical = YES;
    self.tg_scrollPane.backgroundColor = UIColor.clearColor;
    [self.view addSubview:self.tg_scrollPane];

    self.tg_contentStack = [[UIStackView alloc] init];
    self.tg_contentStack.axis = UILayoutConstraintAxisVertical;
    self.tg_contentStack.spacing = 12;
    self.tg_contentStack.alignment = UIStackViewAlignmentFill;
    [self.tg_scrollPane addSubview:self.tg_contentStack];

    UILabel *questionTitle = [self tg_sectionTitle:@"Your Question"];
    [self.tg_contentStack addArrangedSubview:questionTitle];
    [self.tg_contentStack addArrangedSubview:[self tg_buildQuestionPane]];
    [self.tg_contentStack addArrangedSubview:[self tg_buildImagesRail]];
    [self.tg_contentStack addArrangedSubview:[self tg_buildNoticeBox]];
    [self.tg_contentStack setCustomSpacing:16 afterView:questionTitle];
    [self.tg_imagesRail mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(72);
    }];

    [self.tg_bodyVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset([self tg_contentTopBelowNavigation]);
    }];
    [self.tg_submitLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(kTgFbSubmitWidthRatio);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-24);
        make.height.mas_equalTo(kTgFbSubmitHeight);
    }];
    [self.tg_scrollPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.tg_bodyVeil);
        make.bottom.equalTo(self.tg_submitLatch.mas_top).offset(-16);
    }];
    [self.tg_contentStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_scrollPane).insets(UIEdgeInsetsMake(32, kTgFbHorzInset, 20, kTgFbHorzInset));
        make.width.equalTo(self.tg_scrollPane).offset(-kTgFbHorzInset * 2);
    }];

    [self tg_refreshImagesRail];
}

- (UILabel *)tg_sectionTitle:(NSString *)text {
    UILabel *l = [[UILabel alloc] init];
    l.text = text;
    l.font = [UIFont tg_meshGlyphWithSize:15 weight:UIFontWeightMedium];
    l.textColor = UIColor.blackColor;
    return l;
}

- (UIView *)tg_buildQuestionPane {
    self.tg_questionShell = [[UIView alloc] init];
    self.tg_questionShell.backgroundColor = UIColor.whiteColor;
    self.tg_questionShell.layer.cornerRadius = 12;
    self.tg_questionShell.clipsToBounds = YES;

    self.tg_questionPane = [[UITextView alloc] init];
    self.tg_questionPane.delegate = self;
    self.tg_questionPane.font = [UIFont tg_meshGlyphWithSize:15 weight:UIFontWeightRegular];
    self.tg_questionPane.textColor = [UIColor tg_toneFromHex:@"#9CA3AF"];
    self.tg_questionPane.text = kTgFbQuestionPlaceholder;
    self.tg_questionPane.backgroundColor = UIColor.clearColor;
    self.tg_questionPane.textContainerInset = UIEdgeInsetsMake(12, 10, 12, 10);

    self.tg_countCaption = [[UILabel alloc] init];
    self.tg_countCaption.textAlignment = NSTextAlignmentRight;
    [self tg_updateCountCaption:0];

    [self.tg_questionShell addSubview:self.tg_questionPane];
    [self.tg_questionShell addSubview:self.tg_countCaption];
    [self.tg_questionPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.tg_questionShell);
        make.height.mas_greaterThanOrEqualTo(120);
    }];
    [self.tg_countCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_questionPane.mas_bottom).offset(4);
        make.right.equalTo(self.tg_questionShell).offset(-12);
        make.bottom.equalTo(self.tg_questionShell).offset(-10);
    }];
    return self.tg_questionShell;
}

- (UIView *)tg_buildImagesRail {
    self.tg_imagesRail = [[UIView alloc] init];
    self.tg_imagesRail.backgroundColor = UIColor.clearColor;
    return self.tg_imagesRail;
}

- (UIView *)tg_buildNoticeBox {
    UIView *box = [[UIView alloc] init];
    box.backgroundColor = [UIColor tg_toneFromHex:kTgFbNoticeBgHex];
    box.layer.cornerRadius = 12;
    box.clipsToBounds = YES;

    UILabel *caption = [[UILabel alloc] init];
    caption.text = kTgFbNoticeText;
    caption.font = [UIFont tg_meshGlyphWithSize:15 weight:UIFontWeightRegular];
    caption.textColor = [UIColor tg_toneFromHex:kTgFbNoticeTextHex];
    caption.numberOfLines = 0;
    [box addSubview:caption];
    [caption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(box).insets(UIEdgeInsetsMake(14, 14, 14, 14));
    }];
    return box;
}

#pragma mark - Counter

- (void)tg_updateCountCaption:(NSInteger)count {
    NSString *text = [NSString stringWithFormat:@"%ld / 1000", (long)count];
    UIColor *tone = [UIColor tg_toneFromHex:kTgFbUploadToneHex];
    self.tg_countCaption.attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{
        NSFontAttributeName: [UIFont tg_meshGlyphWithSize:13 weight:UIFontWeightRegular],
        NSForegroundColorAttributeName: tone
    }];
}

#pragma mark - Images

- (void)tg_refreshImagesRail {
    for (UIView *child in self.tg_imagesRail.subviews) {
        [child removeFromSuperview];
    }

    CGFloat spacing = 12.0;
    NSInteger slots = kTgFbMaxImages;
    CGFloat itemW = (CGRectGetWidth(UIScreen.mainScreen.bounds) - kTgFbHorzInset * 4 - spacing * (slots - 1)) / slots;
    if (itemW < 80) itemW = 80;
    CGFloat itemH = itemW * 1.32;
    CGFloat railHeight = 0;

    if (self.tg_pickedImages.count > 0) {
        UIView *thumbRow = [[UIView alloc] init];
        [self.tg_imagesRail addSubview:thumbRow];
        [thumbRow mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self.tg_imagesRail);
            make.height.mas_equalTo(itemH);
        }];
        railHeight = itemH;

        NSInteger index = 0;
        for (UIImage *img in self.tg_pickedImages) {
            UIView *tile = [self tg_buildImageTile:img index:index size:CGSizeMake(itemW, itemH)];
            [thumbRow addSubview:tile];
            [tile mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(thumbRow).offset(index * (itemW + spacing));
                make.top.bottom.equalTo(thumbRow);
                make.width.mas_equalTo(itemW);
            }];
            index++;
        }
    }

    if (self.tg_pickedImages.count < kTgFbMaxImages) {
        UIView *addPane = [self tg_buildWideAddPane];
        [self.tg_imagesRail addSubview:addPane];
        CGFloat uploadTop = railHeight > 0 ? railHeight + 12 : 0;
        [addPane mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.tg_imagesRail);
            make.height.mas_equalTo(72);
            make.top.equalTo(self.tg_imagesRail).offset(uploadTop);
        }];
        railHeight = uploadTop + 72;
    }

    [self.tg_imagesRail mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(MAX(railHeight, 72));
    }];
}

- (UIView *)tg_buildWideAddPane {
    TgFbDashPaneView *pane = [[TgFbDashPaneView alloc] init];
    pane.backgroundColor = UIColor.whiteColor;
    pane.layer.cornerRadius = 12;
    pane.clipsToBounds = YES;
    pane.userInteractionEnabled = YES;
    [pane addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tg_onPickImages)]];

    UILabel *caption = [[UILabel alloc] init];
    caption.text = @"+ Upload Pictures";
    caption.font = [UIFont tg_meshGlyphWithSize:15 weight:UIFontWeightMedium];
    caption.textColor = [UIColor tg_toneFromHex:kTgFbUploadToneHex];
    caption.textAlignment = NSTextAlignmentCenter;
    [pane addSubview:caption];
    [caption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(pane);
    }];
    return pane;
}

- (UIView *)tg_buildImageTile:(UIImage *)image index:(NSInteger)index size:(CGSize)size {
    UIView *tile = [[UIView alloc] init];
    tile.layer.cornerRadius = 12;
    tile.clipsToBounds = YES;
    tile.backgroundColor = UIColor.whiteColor;

    UIImageView *preview = [[UIImageView alloc] initWithImage:image];
    preview.contentMode = UIViewContentModeScaleAspectFill;
    preview.clipsToBounds = YES;
    [tile addSubview:preview];
    [preview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(tile);
    }];

    UIButton *removeLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    removeLatch.tag = index;
    [removeLatch setImage:[UIImage imageNamed:@"use_Delete"] forState:UIControlStateNormal];
    [removeLatch addTarget:self action:@selector(tg_onRemoveImage:) forControlEvents:UIControlEventTouchUpInside];
    [tile addSubview:removeLatch];
    [removeLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tile).offset(4);
        make.right.equalTo(tile).offset(-4);
        make.width.height.mas_equalTo(28);
    }];
    (void)size;
    return tile;
}

- (void)tg_onPickImages {
    if (self.tg_pickedImages.count >= kTgFbMaxImages) {
        [[TgPulseOverlay shared] whisperLine:@"Maximum 3 images allowed"];
        return;
    }
    PHPickerConfiguration *cfg = [[PHPickerConfiguration alloc] init];
    cfg.selectionLimit = kTgFbMaxImages - self.tg_pickedImages.count;
    cfg.filter = [PHPickerFilter imagesFilter];
    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:cfg];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)tg_onRemoveImage:(UIButton *)sender {
    NSInteger idx = sender.tag;
    if (idx >= 0 && idx < (NSInteger)self.tg_pickedImages.count) {
        [self.tg_pickedImages removeObjectAtIndex:idx];
        [self tg_refreshImagesRail];
    }
}

#pragma mark - PHPicker

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (results.count == 0) return;

    for (PHPickerResult *result in results) {
        if (self.tg_pickedImages.count >= kTgFbMaxImages) break;
        [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(id object, NSError *error) {
            if (error || ![object isKindOfClass:[UIImage class]]) return;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.tg_pickedImages.count < kTgFbMaxImages) {
                    [self.tg_pickedImages addObject:(UIImage *)object];
                    [self tg_refreshImagesRail];
                }
            });
        }];
    }
}

#pragma mark - UITextView

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (self.tg_questionPlaceholderOn) {
        self.tg_questionPlaceholderOn = NO;
        textView.text = @"";
        textView.textColor = UIColor.blackColor;
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView.text.length == 0) {
        self.tg_questionPlaceholderOn = YES;
        textView.text = kTgFbQuestionPlaceholder;
        textView.textColor = [UIColor tg_toneFromHex:@"#9CA3AF"];
        [self tg_updateCountCaption:0];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (self.tg_questionPlaceholderOn) return YES;
    NSString *current = textView.text ?: @"";
    NSString *updated = [current stringByReplacingCharactersInRange:range withString:text];
    if (updated.length > kTgFbMaxQuestionLen) return NO;
    [self tg_updateCountCaption:updated.length];
    return YES;
}

#pragma mark - Mobile

- (void)tg_pullCachedMobile {
    [[TgWireConduit shared] relayPOST:TgLaneUserInfo
                             signData:@{}
                           nonSignData:@{}
                              success:^(id _Nullable data) {
        TgUserInfoData *info = [TgUserInfoData yy_modelWithJSON:data];
        NSString *ready = [NSString tg_wireReadyMobileFromLocalDigits:info.receiver];
        if (ready.length > 0) {
            self.tg_cachedMobile = ready;
        }
    } failure:nil];
}

- (NSString *)tg_trimmedQuestion {
    if (self.tg_questionPlaceholderOn) return @"";
    return [self.tg_questionPane.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

#pragma mark - Submit

- (void)tg_onSubmitTap {
    if (self.tg_submitBusy) return;

    NSString *mobile = self.tg_cachedMobile;
    if (mobile.length == 0) {
        [[TgPulseOverlay shared] whisperLine:@"Type in your phone number"];
        return;
    }
    if (![NSString tg_passesDialPattern:mobile]) {
        [[TgPulseOverlay shared] whisperLine:@"That phone number looks invalid. Please verify it."];
        return;
    }

    NSString *question = [self tg_trimmedQuestion];
    if (question.length == 0) {
        [[TgPulseOverlay shared] whisperLine:@"Please type in your question"];
        return;
    }

    self.tg_submitBusy = YES;
    self.tg_submitLatch.enabled = NO;
    if (self.tg_pickedImages.count == 0) {
        [self tg_sendFeedbackWithMobile:mobile question:question imageUrls:@[]];
    } else {
        [self tg_uploadImagesThenSendWithMobile:mobile question:question];
    }
}

- (void)tg_uploadImagesThenSendWithMobile:(NSString *)mobile question:(NSString *)question {
    [[TgPulseOverlay shared] veilSpin:@"Loading..."];
    NSMutableArray<NSString *> *urls = [NSMutableArray array];
    __block BOOL failed = NO;
    dispatch_group_t group = dispatch_group_create();

    [self.tg_pickedImages enumerateObjectsUsingBlock:^(UIImage *img, NSUInteger idx, BOOL *stop) {
        (void)stop;
        TgPackEnvelope *pack = [img tg_foldPayloadMinKB:200 maxKB:800];
        if (!pack.payloadData) {
            failed = YES;
            return;
        }
        dispatch_group_enter(group);
        NSString *fileName = [NSString stringWithFormat:@"fb_%lld_%lu.jpg", (long long)(NSDate.date.timeIntervalSince1970 * 1000), (unsigned long)idx];
        [[TgWireConduit shared] relayUpload:TgLaneSysUpload
                                   signData:@{}
                                 nonSignData:@{}
                                   fileData:pack.payloadData
                                   fileName:fileName
                                   mimeType:@"image/jpeg"
                                   progress:nil
                                    success:^(id _Nullable data) {
            NSString *src = [self tg_uploadSrcFromPayload:data];
            if (src.length > 0) {
                @synchronized (urls) {
                    [urls addObject:src];
                }
            } else {
                failed = YES;
            }
            dispatch_group_leave(group);
        } failure:^{
            failed = YES;
            dispatch_group_leave(group);
        }];
    }];

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (failed || urls.count != self.tg_pickedImages.count) {
            [[TgPulseOverlay shared] veilDismiss];
            self.tg_submitBusy = NO;
            self.tg_submitLatch.enabled = YES;
            [[TgPulseOverlay shared] whisperLine:@"Some images could not be uploaded"];
            return;
        }
        [self tg_sendFeedbackWithMobile:mobile question:question imageUrls:urls];
    });
}

- (void)tg_sendFeedbackWithMobile:(NSString *)mobile question:(NSString *)question imageUrls:(NSArray<NSString *> *)imageUrls {
    [[TgPulseOverlay shared] veilSpin:@"Loading..."];
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"description"] = question;
    body[@"userMobile"] = mobile;
    if (imageUrls.count > 0) {
        body[@"pictureUrl"] = [imageUrls componentsJoinedByString:@","];
    }

    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneFeedback
                             signData:@{}
                           nonSignData:body
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        __strong typeof(weakSelf) self = weakSelf;
        [[TgPulseOverlay shared] veilDismiss];
        self.tg_submitBusy = NO;
        self.tg_submitLatch.enabled = YES;
        if (envelope.cheer != 200) {
            [[TgPulseOverlay shared] whisperLine:kTgFbBusyHint];
            return;
        }
        [[TgPulseOverlay shared] whisperLine:kTgFbSuccessHint];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.tg_popToRootOnBack) {
                [self tg_popToLoanHome];
            } else {
                [self.navigationController popViewControllerAnimated:YES];
            }
        });
    } failure:^{
        __strong typeof(weakSelf) self = weakSelf;
        [[TgPulseOverlay shared] veilDismiss];
        self.tg_submitBusy = NO;
        self.tg_submitLatch.enabled = YES;
        [[TgPulseOverlay shared] whisperLine:kTgFbBusyHint];
    }];
}

- (void)tg_popToLoanHome {
    UITabBarController *dock = self.tabBarController;
    if (dock) {
        dock.selectedIndex = TgDockTabIndexLoan;
        UINavigationController *loanNav = (UINavigationController *)dock.viewControllers[TgDockTabIndexLoan];
        if ([loanNav isKindOfClass:[UINavigationController class]]) {
            [loanNav popToRootViewControllerAnimated:NO];
        }
    }
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (nullable NSString *)tg_uploadSrcFromPayload:(id)data {
    if ([data isKindOfClass:[NSString class]]) {
        return [(NSString *)data stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if ([data isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)data;
        id src = dict[@"src"];
        if ([src isKindOfClass:[NSString class]]) {
            NSString *trim = [(NSString *)src stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (trim.length > 0) return trim;
        }
    }
    TgUploadSrcData *payload = [TgUploadSrcData yy_modelWithJSON:data];
    return [payload.bucket stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
