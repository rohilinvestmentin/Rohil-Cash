//

//

#import "TgBankEditVaultController.h"
#import "TgIfscPickController.h"
#import "TgKycFormCell.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"
#import "TgPulseOverlay.h"
#import "TgWireConduit.h"
#import "TgEnvelopeBase.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import "NSString+TgGlyph.h"
#import <Masonry/Masonry.h>

static CGFloat const kTgBankEditHorzInset = 16.0;
static CGFloat const kTgBankEditSubmitHeight = 50.0;
static CGFloat const kTgBankEditSubmitWidthRatio = 0.85;
static NSString * const kTgBankEditBodyToneHex = @"#F1F1F1";
static NSString * const kTgBankEditNoticeBgHex = @"#FCF4EE";
static NSString * const kTgBankEditNoticeTextHex = @"#EA834C";
static NSString * const kTgBankEditBusyHint = @"The system is occupied. Please retry after 2 minutes.";
static NSString * const kTgBankEditTipText =
@"Please provide a correct, available, unfrozen bank account so the loan can be credited.";

@interface TgBankEditVaultController ()

@property (nonatomic, strong) UIView *tg_bodyVeil;
@property (nonatomic, strong) UIScrollView *tg_scrollPane;
@property (nonatomic, strong) UIStackView *tg_formStack;
@property (nonatomic, strong) TgKycFormCell *tg_nameCell;
@property (nonatomic, strong) TgKycFormCell *tg_ifscCell;
@property (nonatomic, strong) TgKycFormCell *tg_accountCell;
@property (nonatomic, strong) TgKycFormCell *tg_confirmCell;
@property (nonatomic, strong) TgKycFormCell *tg_creditCell;
@property (nonatomic, strong) UIButton *tg_continueLatch;
@property (nonatomic, assign) BOOL tg_submitBusy;
@property (nonatomic, assign) BOOL tg_prefillLoaded;

@end

@implementation TgBankEditVaultController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.tg_backdropStyle = TgHullBackdropStyleUseBg0;
        self.tg_showsBackButton = YES;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self tg_setNavTitleMedium18:@"Bank Account"];
    [self tg_buildLayout];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    if (!self.tg_prefillLoaded) {
        [self tg_loadPrefillData];
    }
}

#pragma mark - Layout

- (TgKycFormCell *)tg_makeInputCellWithTitle:(NSString *)title itemCode:(NSString *)itemCode placeholder:(NSString *)placeholder {
    TgKycFormCell *cell = [[TgKycFormCell alloc] init];
    [cell tg_configureWithTitle:title placeholder:placeholder mode:TgKycFormCellModeInput filter:TgKycFormInputFilterNone keyboard:UIKeyboardTypeDefault];
    [cell tg_bindItemCode:itemCode];
    return cell;
}

- (void)tg_buildLayout {
    self.tg_bodyVeil = [[UIView alloc] init];
    self.tg_bodyVeil.backgroundColor = [UIColor tg_toneFromHex:kTgBankEditBodyToneHex];
    [self.view insertSubview:self.tg_bodyVeil atIndex:1];

    self.tg_continueLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_continueLatch setTitle:@"Submit" forState:UIControlStateNormal];
    [self.tg_continueLatch setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.tg_continueLatch.titleLabel.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    self.tg_continueLatch.backgroundColor = [UIColor tg_toneFromHex:@"#182040"];
    self.tg_continueLatch.layer.cornerRadius = kTgBankEditSubmitHeight / 2.0;
    self.tg_continueLatch.clipsToBounds = YES;
    [self.tg_continueLatch addTarget:self action:@selector(tg_onContinueTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.tg_continueLatch];

    self.tg_scrollPane = [[UIScrollView alloc] init];
    self.tg_scrollPane.showsVerticalScrollIndicator = NO;
    self.tg_scrollPane.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tg_scrollPane.backgroundColor = UIColor.clearColor;
    [self.view addSubview:self.tg_scrollPane];

    self.tg_formStack = [[UIStackView alloc] init];
    self.tg_formStack.axis = UILayoutConstraintAxisVertical;
    self.tg_formStack.spacing = TgKycFormCellStackSpacing;
    self.tg_formStack.alignment = UIStackViewAlignmentFill;
    [self.tg_scrollPane addSubview:self.tg_formStack];

    UIView *noticeBox = [[UIView alloc] init];
    noticeBox.backgroundColor = [UIColor tg_toneFromHex:kTgBankEditNoticeBgHex];
    noticeBox.layer.cornerRadius = 12;
    noticeBox.clipsToBounds = YES;
    UILabel *notice = [[UILabel alloc] init];
    notice.text = kTgBankEditTipText;
    notice.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    notice.textColor = [UIColor tg_toneFromHex:kTgBankEditNoticeTextHex];
    notice.numberOfLines = 0;
    [noticeBox addSubview:notice];
    [notice mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(noticeBox).insets(UIEdgeInsetsMake(14, 14, 14, 14));
    }];
    [self.tg_formStack addArrangedSubview:noticeBox];

    self.tg_nameCell = [self tg_makeInputCellWithTitle:@"Name" itemCode:nil placeholder:TgKycPlaceholderEnter];
    [self.tg_nameCell tg_setInputEnabled:NO];
    [self.tg_formStack addArrangedSubview:self.tg_nameCell];

    self.tg_ifscCell = [[TgKycFormCell alloc] init];
    [self.tg_ifscCell tg_configureWithTitle:@"IFSC" placeholder:TgKycPlaceholderIfsc mode:TgKycFormCellModeInput filter:TgKycFormInputFilterAlphanumericsUppercased keyboard:UIKeyboardTypeASCIICapable];
    [self.tg_ifscCell tg_bindItemCode:@"ifsc"];
    [self.tg_ifscCell tg_setLinkTitle:@"Find IFSC"];
    __weak typeof(self) weakSelf = self;
    self.tg_ifscCell.tg_onLinkTapped = ^{
        [weakSelf tg_onFindIfscTap];
    };
    [self.tg_formStack addArrangedSubview:self.tg_ifscCell];

    self.tg_accountCell = [self tg_makeInputCellWithTitle:@"Bank account number" itemCode:@"account_no" placeholder:TgKycPlaceholderEnter];
    [self.tg_formStack addArrangedSubview:self.tg_accountCell];

    self.tg_confirmCell = [self tg_makeInputCellWithTitle:@"Confirm bank account" itemCode:@"account_no_verify" placeholder:TgKycPlaceholderEnter];
    [self.tg_formStack addArrangedSubview:self.tg_confirmCell];

    self.tg_creditCell = [self tg_makeInputCellWithTitle:@"Credit card（optional）" itemCode:@"credit_card" placeholder:TgKycPlaceholderEnter];
    [self.tg_formStack addArrangedSubview:self.tg_creditCell];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tg_dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.tg_scrollPane addGestureRecognizer:tap];

    [self.tg_bodyVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset([self tg_contentTopBelowNavigation]);
        make.bottom.equalTo(self.tg_continueLatch.mas_top).offset(-12);
    }];
    [self.tg_continueLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(kTgBankEditSubmitWidthRatio);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-16);
        make.height.mas_equalTo(kTgBankEditSubmitHeight);
    }];
    [self.tg_scrollPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_bodyVeil);
    }];
    [self.tg_formStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_scrollPane).insets(UIEdgeInsetsMake(12, kTgBankEditHorzInset, 20, kTgBankEditHorzInset));
        make.width.equalTo(self.tg_scrollPane).offset(-kTgBankEditHorzInset * 2);
    }];
}

#pragma mark - Data

- (void)tg_loadPrefillData {
    [[TgPulseOverlay shared] veilSpin];
    dispatch_group_t group = dispatch_group_create();
    __block NSString *fetchedName = nil;
    __block TgBankCardInfo *fetchedCard = nil;

    dispatch_group_enter(group);
    [[TgWireConduit shared] relayPOST:TgLaneBankcardList
                             signData:@{}
                           nonSignData:@{}
                              success:^(id _Nullable data) {
        TgBankCardListData *listData = [TgBankCardListData yy_modelWithJSON:data];
        if (listData.superior.count > 0) {
            fetchedCard = listData.superior.firstObject;
        }
        dispatch_group_leave(group);
    } failure:^{
        dispatch_group_leave(group);
    }];

    dispatch_group_enter(group);
    [[TgWireConduit shared] relayPOST:TgLaneUserInfo
                             signData:@{}
                           nonSignData:@{}
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        if (envelope.cheer == 200 && envelope.trick) {
            TgUserInfoData *user = [TgUserInfoData yy_modelWithJSON:envelope.trick];
            fetchedName = [self tg_trimmed:user.matter];
        }
        dispatch_group_leave(group);
    } failure:^{
        dispatch_group_leave(group);
    }];

    __weak typeof(self) weakSelf = self;
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        [[TgPulseOverlay shared] veilDismiss];
        if (!self) return;
        self.tg_prefillLoaded = YES;
        [self tg_applyPrefillWithBankCard:fetchedCard userName:fetchedName];
    });
}

- (NSString *)tg_trimmed:(NSString *)text {
    return [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
}

- (void)tg_setCell:(TgKycFormCell *)cell text:(NSString *)text {
    NSString *trim = [self tg_trimmed:text];
    if (trim.length == 0) return;
    [cell tg_setDisplayText:trim isPlaceholderStyle:NO];
}

- (void)tg_applyPrefillWithBankCard:(TgBankCardInfo *)card userName:(NSString *)userName {
    NSString *name = [self tg_trimmed:card.first];
    if (name.length == 0) {
        name = userName;
    }
    [self tg_setCell:self.tg_nameCell text:name];

    if (!card) return;

    NSString *ifsc = [self tg_trimmed:card.procedure];
    if (ifsc.length == 0) {
        ifsc = [self tg_trimmed:card.xRay];
    }
    if (ifsc.length > 0) {
        [self tg_setCell:self.tg_ifscCell text:ifsc.uppercaseString];
    }

    NSString *accountNo = [self tg_trimmed:card.measure];
    if (accountNo.length > 0) {
        [self tg_setCell:self.tg_accountCell text:accountNo];
        [self tg_setCell:self.tg_confirmCell text:accountNo];
    }

    NSString *credit = [self tg_trimmed:card.bdhwka];
    if (credit.length > 0 && ![credit.lowercaseString isEqualToString:@"unknown"]) {
        [self tg_setCell:self.tg_creditCell text:credit];
    }
}

- (void)tg_dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - Actions

- (void)tg_onFindIfscTap {
    [self tg_dismissKeyboard];
    TgIfscPickController *picker = [[TgIfscPickController alloc] init];
    __weak typeof(self) weakSelf = self;
    picker.tg_onPicked = ^(NSString *ifscCode) {
        __strong typeof(weakSelf) self = weakSelf;
        [self.tg_ifscCell tg_setDisplayText:[ifscCode uppercaseString] isPlaceholderStyle:NO];
    };
    picker.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:picker animated:YES];
}

- (void)tg_onContinueTap {
    [self tg_dismissKeyboard];
    if (self.tg_submitBusy) return;

    NSString *ifscRaw = self.tg_ifscCell.tg_textField.text ?: @"";
    NSString *ifscTrimmed = [ifscRaw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *ifsc = [ifscTrimmed uppercaseString];
    NSString *accountNo = [NSString tg_digitsOnlyFromMixed:(self.tg_accountCell.tg_textField.text ?: @"")];
    NSString *accountVerify = [NSString tg_digitsOnlyFromMixed:(self.tg_confirmCell.tg_textField.text ?: @"")];
    NSString *credit = [NSString tg_digitsOnlyFromMixed:(self.tg_creditCell.tg_textField.text ?: @"")];

    if (ifsc.length == 0) {
        [[TgPulseOverlay shared] whisperLine:@"That IFSC looks invalid. Please verify it"];
        return;
    }
    if (accountNo.length == 0) {
        [[TgPulseOverlay shared] whisperLine:@"The bank account number is blank or formatted incorrectly."];
        return;
    }
    if (accountVerify.length == 0) {
        [[TgPulseOverlay shared] whisperLine:@"The confirm bank account field is blank or formatted incorrectly."];
        return;
    }
    if (![accountNo isEqualToString:accountVerify]) {
        [[TgPulseOverlay shared] whisperLine:@"The bank account numbers do not match"];
        return;
    }

    self.tg_submitBusy = YES;
    self.tg_continueLatch.enabled = NO;
    self.tg_continueLatch.alpha = 0.6;
    [[TgPulseOverlay shared] veilSpin:@"Loading..."];

    NSDictionary *sign = @{
        @"accountType": @"unknown",
        @"bankCode": ifsc,
        @"accountNo": accountNo
    };
    NSDictionary *nonSign = @{
        @"accountNoVerify": accountVerify,
        @"creditCard": credit.length > 0 ? credit : @""
    };

    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneBankcardModify
                             signData:sign
                           nonSignData:nonSign
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        __strong typeof(weakSelf) self = weakSelf;
        [[TgPulseOverlay shared] veilDismiss];
        self.tg_submitBusy = NO;
        self.tg_continueLatch.enabled = YES;
        self.tg_continueLatch.alpha = 1.0;
        if (envelope.cheer != 200) {
            NSString *msg = envelope.power.length > 0 ? envelope.power : kTgBankEditBusyHint;
            [[TgPulseOverlay shared] whisperLine:msg];
            return;
        }
        [self.navigationController popViewControllerAnimated:YES];
    } failure:^{
        __strong typeof(weakSelf) self = weakSelf;
        [[TgPulseOverlay shared] veilDismiss];
        self.tg_submitBusy = NO;
        self.tg_continueLatch.enabled = YES;
        self.tg_continueLatch.alpha = 1.0;
        [[TgPulseOverlay shared] whisperLine:kTgBankEditBusyHint];
    }];
}

@end
