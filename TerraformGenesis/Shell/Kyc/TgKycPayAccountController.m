//

//

#import "TgKycPayAccountController.h"
#import "TgIfscPickController.h"
#import "TgKycFormCell.h"
#import "TgKycPathRelay.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"
#import "TgPulseOverlay.h"
#import "TgShardFacade.h"
#import "TgTraceRelay.h"
#import "TgWireConduit.h"
#import "TgEnvelopeBase.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>

static NSString * const kTgPayAccountKycId = @"pay_account";
static CGFloat const kTgPayAccountHorzInset = 16.0;
static CGFloat const kTgPayAccountContinueHeight = 50.0;
static CGFloat const kTgPayAccountContinueWidthRatio = 0.85;
static NSString * const kTgPayAccountBodyHex = @"#F1F1F1";
static NSString * const kTgPayAccountNoticeBgHex = @"#FCF4EE";
static NSString * const kTgPayAccountNoticeTextHex = @"#EA834C";
static NSString * const kTgPayAccountBusyHint = @"The system is occupied. Please retry after 2 minutes.";
static NSString * const kTgPayAccountValidationTemplate = @"%@ is blank or formatted incorrectly.";
static NSString * const kTgPayAccountIfscInvalidHint = @"That IFSC looks invalid. Please verify it";
static NSString * const kTgPayAccountAccountMismatchHint = @"The bank account numbers do not match";
static NSString * const kTgPayAccountTipText =
@"Please provide a correct, available, unfrozen bank account so the loan can be credited.";

@interface TgKycPayAccountController ()

@property (nonatomic, strong) UIView *tg_bodyVeil;
@property (nonatomic, strong) UIScrollView *tg_scrollPane;
@property (nonatomic, strong) UIStackView *tg_formStack;
@property (nonatomic, strong) UIButton *tg_continueLatch;

@property (nonatomic, copy) NSArray<TgKYCFormItem *> *tg_formItems;
@property (nonatomic, strong) NSMutableDictionary<NSString *, TgKycFormCell *> *tg_cellsByCode;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *tg_valuesByCode;
@property (nonatomic, assign) BOOL tg_submitBusy;

@end

@implementation TgKycPayAccountController

- (instancetype)init {
    self = [super init];
    if (self) {
        _tg_cellsByCode = [NSMutableDictionary dictionary];
        _tg_valuesByCode = [NSMutableDictionary dictionary];
        self.tg_backdropStyle = TgHullBackdropStyleUseBg0;
        self.tg_showsBackButton = YES;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self tg_setNavTitleMedium18:@"Bank information"];
    __weak typeof(self) weakSelf = self;
    self.tg_backInterceptBlock = ^BOOL {
        [weakSelf tg_showReturnConfirmDialog];
        return NO;
    };
    [self tg_buildLayout];
    [self tg_loadInitAndUserInfo];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - Layout

- (void)tg_buildLayout {
    self.tg_bodyVeil = [[UIView alloc] init];
    self.tg_bodyVeil.backgroundColor = [UIColor tg_toneFromHex:kTgPayAccountBodyHex];
    [self.view insertSubview:self.tg_bodyVeil atIndex:1];

    self.tg_continueLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_continueLatch setTitle:@"Continue" forState:UIControlStateNormal];
    [self.tg_continueLatch setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.tg_continueLatch.titleLabel.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    self.tg_continueLatch.backgroundColor = [UIColor tg_toneFromHex:@"#182040"];
    self.tg_continueLatch.layer.cornerRadius = kTgPayAccountContinueHeight / 2.0;
    self.tg_continueLatch.clipsToBounds = YES;
    [self.tg_continueLatch addTarget:self action:@selector(tg_onContinueTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.tg_continueLatch];

    self.tg_scrollPane = [[UIScrollView alloc] init];
    self.tg_scrollPane.showsVerticalScrollIndicator = NO;
    self.tg_scrollPane.alwaysBounceVertical = YES;
    self.tg_scrollPane.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tg_scrollPane.backgroundColor = UIColor.clearColor;
    [self.view addSubview:self.tg_scrollPane];

    self.tg_formStack = [[UIStackView alloc] init];
    self.tg_formStack.axis = UILayoutConstraintAxisVertical;
    self.tg_formStack.spacing = TgKycFormCellStackSpacing;
    self.tg_formStack.alignment = UIStackViewAlignmentFill;
    [self.tg_scrollPane addSubview:self.tg_formStack];

    UIView *noticeBox = [[UIView alloc] init];
    noticeBox.backgroundColor = [UIColor tg_toneFromHex:kTgPayAccountNoticeBgHex];
    noticeBox.layer.cornerRadius = 12;
    noticeBox.clipsToBounds = YES;
    UILabel *notice = [[UILabel alloc] init];
    notice.text = kTgPayAccountTipText;
    notice.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    notice.textColor = [UIColor tg_toneFromHex:kTgPayAccountNoticeTextHex];
    notice.numberOfLines = 0;
    [noticeBox addSubview:notice];
    [notice mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(noticeBox).insets(UIEdgeInsetsMake(14, 14, 14, 14));
    }];
    [self.tg_formStack addArrangedSubview:noticeBox];

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
        make.width.equalTo(self.view).multipliedBy(kTgPayAccountContinueWidthRatio);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-16);
        make.height.mas_equalTo(kTgPayAccountContinueHeight);
    }];
    [self.tg_scrollPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_bodyVeil);
    }];
    [self.tg_formStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_scrollPane).insets(UIEdgeInsetsMake(12, kTgPayAccountHorzInset, 20, kTgPayAccountHorzInset));
        make.width.equalTo(self.tg_scrollPane).offset(-kTgPayAccountHorzInset * 2);
    }];
}

#pragma mark - Data

- (void)tg_loadInitAndUserInfo {
    [[TgPulseOverlay shared] veilSpin];
    dispatch_group_t group = dispatch_group_create();
    __block TgKYCInitData *fetchedInit = nil;
    __block NSString *fetchedName = nil;

    dispatch_group_enter(group);
    [[TgWireConduit shared] relayPOST:TgLaneKycInit
                             signData:@{ @"kycId": kTgPayAccountKycId }
                           nonSignData:@{}
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        if (envelope.cheer == 200) {
            fetchedInit = [TgKYCInitData yy_modelWithJSON:envelope.trick];
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
        if (envelope.cheer == 200) {
            TgUserInfoData *user = [TgUserInfoData yy_modelWithJSON:envelope.trick];
            if (user.matter.length > 0) fetchedName = user.matter;
        }
        dispatch_group_leave(group);
    } failure:^{
        dispatch_group_leave(group);
    }];

    __weak typeof(self) weakSelf = self;
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [[TgPulseOverlay shared] veilDismiss];
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (!fetchedInit || fetchedInit.nevertheless.count == 0) {
            [[TgPulseOverlay shared] whisperLine:kTgPayAccountBusyHint];
            return;
        }
        self.tg_formItems = [self tg_sortedItemsFromList:fetchedInit.nevertheless];
        [self tg_rebuildFormStack];
        if (fetchedName.length > 0) {
            [self tg_prefillAccountName:fetchedName];
        }
    });
}

- (NSArray<TgKYCFormItem *> *)tg_sortedItemsFromList:(NSArray<TgKYCFormItem *> *)list {
    return [list sortedArrayUsingComparator:^NSComparisonResult(TgKYCFormItem *a, TgKYCFormItem *b) {
        if (a.itemSort == b.itemSort) return NSOrderedSame;
        return a.itemSort < b.itemSort ? NSOrderedAscending : NSOrderedDescending;
    }];
}

- (void)tg_rebuildFormStack {
    UIView *noticeView = self.tg_formStack.arrangedSubviews.firstObject;
    for (UIView *v in self.tg_formStack.arrangedSubviews) {
        if (v == noticeView) continue;
        [self.tg_formStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    [self.tg_cellsByCode removeAllObjects];
    [self.tg_valuesByCode removeAllObjects];

    for (TgKYCFormItem *item in self.tg_formItems) {
        NSString *codeKey = [self tg_codeKey:item.performance];
        TgKycFormCell *cell = [[TgKycFormCell alloc] init];
        if ([codeKey isEqualToString:@"credit_card"]) {
            [cell tg_configureWithTitle:@"Credit card(optional)"
                            placeholder:TgKycPlaceholderEnter
                                   mode:TgKycFormCellModeInput
                                 filter:TgKycFormInputFilterDigitsOnly
                               keyboard:UIKeyboardTypeNumberPad];
            [cell tg_bindItemCode:@"credit_card"];
        } else {
            [cell tg_configureForKycFormItem:item];
        }
        if ([self tg_isAccountNameCode:codeKey]) {
            [cell tg_setInputEnabled:NO];
        }
        if (item.favourable == 1 && [codeKey isEqualToString:@"ifsc"]) {
            [cell tg_setLinkTitle:@"Find IFSC"];
            __weak typeof(self) weakSelf = self;
            cell.tg_onLinkTapped = ^{
                [weakSelf tg_onFindIfscTap];
            };
        }
        self.tg_cellsByCode[codeKey] = cell;
        [self tg_bindCell:cell item:item];
        [self.tg_formStack addArrangedSubview:cell];
    }
}

- (NSString *)tg_codeKey:(NSString *)code {
    return [code lowercaseString] ?: @"";
}

- (BOOL)tg_isAccountNameCode:(NSString *)codeKey {
    return [codeKey isEqualToString:@"accountname"] || [codeKey isEqualToString:@"account_name"];
}

- (BOOL)tg_isOptionalCode:(NSString *)codeKey {
    return [codeKey isEqualToString:@"credit_card"];
}

- (void)tg_prefillAccountName:(NSString *)name {
    for (TgKYCFormItem *item in self.tg_formItems) {
        if (![self tg_isAccountNameCode:[self tg_codeKey:item.performance]]) continue;
        NSString *key = [self tg_codeKey:item.performance];
        self.tg_valuesByCode[key] = name;
        TgKycFormCell *cell = self.tg_cellsByCode[key];
        [cell tg_setDisplayText:name isPlaceholderStyle:NO];
        break;
    }
}

- (void)tg_bindCell:(TgKycFormCell *)cell item:(TgKYCFormItem *)item {
    NSString *codeKey = [self tg_codeKey:item.performance];
    BOOL isSelector = item.favourable != 1;
    __weak typeof(self) weakSelf = self;

    if (isSelector) {
        cell.tg_onRowTapped = ^{
            [weakSelf tg_presentSelectorForItem:item];
        };
        return;
    }

    NSString *existing = self.tg_valuesByCode[codeKey];
    if (existing.length > 0) {
        [cell tg_setDisplayText:existing isPlaceholderStyle:NO];
    }

    cell.tg_onTextChanged = ^(NSString *text) {
        NSString *trim = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([codeKey isEqualToString:@"ifsc"]) {
            trim = [trim uppercaseString];
        }
        if (trim.length > 0) {
            weakSelf.tg_valuesByCode[codeKey] = trim;
        } else {
            [weakSelf.tg_valuesByCode removeObjectForKey:codeKey];
        }
    };
}

#pragma mark - Selector

- (NSArray<NSString *> *)tg_selectorLabelsForItem:(TgKYCFormItem *)item {
    if (item.radio.count > 0) {
        NSArray<TgKYCButtonItem *> *sorted = [item.radio sortedArrayUsingComparator:^NSComparisonResult(TgKYCButtonItem *a, TgKYCButtonItem *b) {
            if (a.buttonSort == b.buttonSort) return NSOrderedSame;
            return a.buttonSort < b.buttonSort ? NSOrderedAscending : NSOrderedDescending;
        }];
        NSMutableArray<NSString *> *labels = [NSMutableArray array];
        for (TgKYCButtonItem *btn in sorted) {
            if (btn.purchase.length > 0) [labels addObject:btn.purchase];
        }
        return labels;
    }
    NSMutableArray<NSString *> *options = [NSMutableArray array];
    for (NSString *s in item.squeeze) {
        if (s.length > 0) [options addObject:s];
    }
    for (NSString *s in item.intend) {
        if (s.length > 0 && ![options containsObject:s]) [options addObject:s];
    }
    return options;
}

- (NSString *)tg_commitValueForItem:(TgKYCFormItem *)item selectedLabel:(NSString *)label {
    if (item.radio.count > 0) {
        for (TgKYCButtonItem *btn in item.radio) {
            if ([btn.purchase isEqualToString:label]) {
                return btn.optional.length > 0 ? btn.optional : label;
            }
        }
    }
    return label;
}

- (NSInteger)tg_selectedIndexForItem:(TgKYCFormItem *)item options:(NSArray<NSString *> *)options {
    NSString *stored = self.tg_valuesByCode[[self tg_codeKey:item.performance]];
    if (stored.length == 0) return NSNotFound;
    NSString *display = [self tg_displayLabelForItem:item storedValue:stored];
    NSUInteger idx = [options indexOfObject:display];
    return idx == NSNotFound ? NSNotFound : (NSInteger)idx;
}

- (NSString *)tg_displayLabelForItem:(TgKYCFormItem *)item storedValue:(NSString *)value {
    if (item.radio.count > 0) {
        for (TgKYCButtonItem *btn in item.radio) {
            if ([btn.optional isEqualToString:value] || [btn.purchase isEqualToString:value]) {
                return btn.purchase ?: value;
            }
        }
    }
    return value;
}

- (void)tg_presentSelectorForItem:(TgKYCFormItem *)item {
    [self.view endEditing:YES];
    NSArray<NSString *> *options = [self tg_selectorLabelsForItem:item];
    if (options.count == 0) return;

    NSString *codeKey = [self tg_codeKey:item.performance];
    TgKycFormCell *cell = self.tg_cellsByCode[codeKey];
    NSInteger selectedIndex = [self tg_selectedIndexForItem:item options:options];
    NSString *title = item.large.length > 0 ? item.large : @"Please choose";

    __weak typeof(self) weakSelf = self;
    [[TgShardFacade shared] showOptionPickerWithTitle:title
                                              options:options
                                        selectedIndex:selectedIndex
                                         confirmTitle:@"Confirm"
                                            onConfirm:^(__unused NSInteger index, NSString *value) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !cell) return;
        NSString *commit = [self tg_commitValueForItem:item selectedLabel:value];
        self.tg_valuesByCode[codeKey] = commit;
        [cell tg_setDisplayText:value isPlaceholderStyle:NO];
    }];
}

#pragma mark - IFSC

- (void)tg_onFindIfscTap {
    [self tg_dismissKeyboard];
    TgIfscPickController *picker = [[TgIfscPickController alloc] init];
    __weak typeof(self) weakSelf = self;
    picker.tg_onPicked = ^(NSString *ifscCode) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        NSString *upper = [ifscCode uppercaseString];
        TgKycFormCell *cell = self.tg_cellsByCode[@"ifsc"];
        cell.tg_textField.text = upper;
        cell.tg_textField.textColor = [UIColor tg_toneFromHex:@"#364153"];
        self.tg_valuesByCode[@"ifsc"] = upper;
    };
    picker.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:picker animated:YES];
}

- (void)tg_dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - Validation & Submit

- (NSString *)tg_valueForItem:(TgKYCFormItem *)item {
    NSString *codeKey = [self tg_codeKey:item.performance];
    if (item.favourable != 1) {
        return self.tg_valuesByCode[codeKey] ?: @"";
    }
    TgKycFormCell *cell = self.tg_cellsByCode[codeKey];
    NSString *text = cell.tg_textField.text ?: @"";
    NSString *trim = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([codeKey isEqualToString:@"ifsc"]) {
        return [trim uppercaseString];
    }
    return trim;
}

- (BOOL)tg_passesRegex:(NSString *)value pattern:(NSString *)pattern {
    if (pattern.length == 0 || value.length == 0) return YES;
    @try {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
        return [predicate evaluateWithObject:value];
    } @catch (__unused NSException *exception) {
        return YES;
    }
}

- (BOOL)tg_validateFormWithToast:(BOOL)showToast {
    NSString *accountNo = @"";
    NSString *accountNoVerify = @"";

    for (TgKYCFormItem *item in self.tg_formItems) {
        NSString *codeKey = [self tg_codeKey:item.performance];
        NSString *value = [self tg_valueForItem:item];
        BOOL optional = [self tg_isOptionalCode:codeKey];

        if (optional && value.length == 0) continue;

        if (!optional && value.length == 0) {
            if (showToast) {
                NSString *name = item.large.length > 0 ? item.large : (item.performance ?: @"Field");
                [[TgPulseOverlay shared] whisperLine:[NSString stringWithFormat:kTgPayAccountValidationTemplate, name]];
            }
            return NO;
        }

        if (![self tg_passesRegex:value pattern:item.keen]) {
            if (showToast) {
                if ([codeKey isEqualToString:@"ifsc"]) {
                    [[TgPulseOverlay shared] whisperLine:kTgPayAccountIfscInvalidHint];
                } else {
                    NSString *name = item.large.length > 0 ? item.large : (item.performance ?: @"Field");
                    [[TgPulseOverlay shared] whisperLine:[NSString stringWithFormat:kTgPayAccountValidationTemplate, name]];
                }
            }
            return NO;
        }

        if ([codeKey isEqualToString:@"account_no"]) accountNo = value;
        if ([codeKey isEqualToString:@"account_no_verify"]) accountNoVerify = value;
    }

    if (accountNo.length > 0 && accountNoVerify.length > 0 && ![accountNo isEqualToString:accountNoVerify]) {
        if (showToast) {
            [[TgPulseOverlay shared] whisperLine:kTgPayAccountAccountMismatchHint];
        }
        return NO;
    }

    return YES;
}

- (NSArray<NSDictionary *> *)tg_buildCommitList {
    NSMutableArray<NSDictionary *> *list = [NSMutableArray array];
    for (TgKYCFormItem *item in self.tg_formItems) {
        NSString *value = [self tg_valueForItem:item];
        [list addObject:@{
            @"itemCode": item.performance ?: @"",
            @"itemValue": value,
            @"itemValueType": @1
        }];
    }
    return list;
}

- (void)tg_onContinueTap {
    [self tg_dismissKeyboard];
    if (self.tg_submitBusy) return;
    if (![self tg_validateFormWithToast:YES]) return;

    self.tg_submitBusy = YES;
    self.tg_continueLatch.enabled = NO;
    self.tg_continueLatch.alpha = 0.6;
    [[TgPulseOverlay shared] veilSpin];

    NSArray<NSDictionary *> *commitList = [self tg_buildCommitList];
    NSDictionary *nonSign = @{ @"kycCommitItemList": commitList };
    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneKycCommit
                             signData:@{ @"kycId": kTgPayAccountKycId }
                           nonSignData:nonSign
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        __strong typeof(weakSelf) self = weakSelf;
        [[TgPulseOverlay shared] veilDismiss];
        self.tg_submitBusy = NO;
        self.tg_continueLatch.enabled = YES;
        self.tg_continueLatch.alpha = 1.0;
        if (envelope.cheer != 200) {
            NSString *msg = envelope.power.length > 0 ? envelope.power : kTgPayAccountBusyHint;
            [[TgPulseOverlay shared] whisperLine:msg];
            return;
        }
        [TgTraceRelay emitSignal:TgTraceSignalBankSubmit];
        [TgKycPathRelay continueAfterCommitFromNav:self.navigationController];
    } failure:^{
        __strong typeof(weakSelf) self = weakSelf;
        [[TgPulseOverlay shared] veilDismiss];
        self.tg_submitBusy = NO;
        self.tg_continueLatch.enabled = YES;
        self.tg_continueLatch.alpha = 1.0;
        [[TgPulseOverlay shared] whisperLine:kTgPayAccountBusyHint];
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
