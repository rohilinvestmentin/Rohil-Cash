//
//  TgKycHullController.m
//

#import "TgKycHullController.h"
#import "TgKycFormCell.h"
#import "TgKycPathRelay.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"
#import "TgPulseOverlay.h"
#import "TgShardFacade.h"
#import "TgTraceRelay.h"
#import "TgWireConduit.h"
#import "NSString+TgGlyph.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>

static CGFloat const kTgKycFormHorzInset = 16.0;
static CGFloat const kTgKycContinueHeight = 50.0;
static CGFloat const kTgKycContinueWidthRatio = 0.85;
static NSString * const kTgKycBodyHex = @"#F1F1F1";
static NSString * const kTgKycBusyHint = @"The system is occupied. Please retry after 2 minutes.";
static NSString * const kTgKycValidationTemplate = @"%@ is blank or formatted incorrectly.";

@interface TgKycHullController ()

@property (nonatomic, copy, readwrite) NSString *tg_kycId;
@property (nonatomic, copy) NSString *tg_pageTitle;

@property (nonatomic, strong) UIView *tg_bodyVeil;
@property (nonatomic, strong) UIScrollView *tg_scrollPane;
@property (nonatomic, strong) UIStackView *tg_formStack;
@property (nonatomic, strong) UIButton *tg_continueLatch;

@property (nonatomic, copy) NSArray<TgKYCFormItem *> *tg_formItems;
@property (nonatomic, strong) NSMutableDictionary<NSString *, TgKycFormCell *> *tg_cellsByCode;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *tg_valuesByCode;

@end

@implementation TgKycHullController

- (instancetype)initWithKycId:(NSString *)kycId pageTitle:(NSString *)pageTitle {
    self = [super init];
    if (self) {
        _tg_kycId = [kycId copy];
        _tg_pageTitle = [pageTitle copy];
        _tg_cellsByCode = [NSMutableDictionary dictionary];
        _tg_valuesByCode = [NSMutableDictionary dictionary];
        self.tg_backdropStyle = TgHullBackdropStylePlain;
        self.tg_showsBackButton = YES;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self tg_setNavTitleMedium18:self.tg_pageTitle];
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
    self.tg_bodyVeil.backgroundColor = [UIColor tg_toneFromHex:kTgKycBodyHex];
    [self.view insertSubview:self.tg_bodyVeil atIndex:1];

    self.tg_continueLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_continueLatch setTitle:@"Continue" forState:UIControlStateNormal];
    [self.tg_continueLatch setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.tg_continueLatch.titleLabel.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    self.tg_continueLatch.backgroundColor = [UIColor tg_toneFromHex:@"#182040"];
    self.tg_continueLatch.layer.cornerRadius = kTgKycContinueHeight / 2.0;
    self.tg_continueLatch.clipsToBounds = YES;
    [self.tg_continueLatch addTarget:self action:@selector(tg_onContinueTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.tg_continueLatch];

    self.tg_scrollPane = [[UIScrollView alloc] init];
    self.tg_scrollPane.showsVerticalScrollIndicator = NO;
    self.tg_scrollPane.alwaysBounceVertical = YES;
    self.tg_scrollPane.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:self.tg_scrollPane];

    self.tg_formStack = [[UIStackView alloc] init];
    self.tg_formStack.axis = UILayoutConstraintAxisVertical;
    self.tg_formStack.spacing = TgKycFormCellStackSpacing;
    self.tg_formStack.alignment = UIStackViewAlignmentFill;
    [self.tg_scrollPane addSubview:self.tg_formStack];

    [self.tg_bodyVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset([self tg_contentTopBelowNavigation]);
        make.bottom.equalTo(self.tg_continueLatch.mas_top).offset(-12);
    }];
    [self.tg_continueLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(kTgKycContinueWidthRatio);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-16);
        make.height.mas_equalTo(kTgKycContinueHeight);
    }];
    [self.tg_scrollPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_bodyVeil);
    }];
    [self.tg_formStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_scrollPane).insets(UIEdgeInsetsMake(16, kTgKycFormHorzInset, 24, kTgKycFormHorzInset));
        make.width.equalTo(self.tg_scrollPane).offset(-kTgKycFormHorzInset * 2);
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
                             signData:@{ @"kycId": self.tg_kycId ?: @"" }
                           nonSignData:@{}
                              success:^(id _Nullable data) {
        fetchedInit = [TgKYCInitData yy_modelWithJSON:data];
        dispatch_group_leave(group);
    } failure:^{
        dispatch_group_leave(group);
    }];

    dispatch_group_enter(group);
    [[TgWireConduit shared] relayPOST:TgLaneUserInfo
                             signData:@{}
                           nonSignData:@{}
                              success:^(id _Nullable data) {
        TgUserInfoData *user = [TgUserInfoData yy_modelWithJSON:data];
        if (user.matter.length > 0) fetchedName = user.matter;
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
            [[TgPulseOverlay shared] whisperLine:kTgKycBusyHint];
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
    NSArray<TgKYCFormItem *> *filtered = [self tg_itemsExcludingIfsc:list];
    return [filtered sortedArrayUsingComparator:^NSComparisonResult(TgKYCFormItem *a, TgKYCFormItem *b) {
        if (a.itemSort == b.itemSort) return NSOrderedSame;
        return a.itemSort < b.itemSort ? NSOrderedAscending : NSOrderedDescending;
    }];
}

- (NSArray<TgKYCFormItem *> *)tg_itemsExcludingIfsc:(NSArray<TgKYCFormItem *> *)list {
    NSMutableArray<TgKYCFormItem *> *out = [NSMutableArray array];
    for (TgKYCFormItem *item in list) {
        if ([[item.performance lowercaseString] isEqualToString:@"ifsc"]) continue;
        [out addObject:item];
    }
    return out;
}

- (void)tg_rebuildFormStack {
    for (UIView *v in self.tg_formStack.arrangedSubviews) {
        [self.tg_formStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    [self.tg_cellsByCode removeAllObjects];

    for (TgKYCFormItem *item in self.tg_formItems) {
        NSString *codeKey = [self tg_codeKey:item.performance];
        TgKycFormCell *cell = [[TgKycFormCell alloc] init];
        [cell tg_configureForKycFormItem:item];
        self.tg_cellsByCode[codeKey] = cell;
        [self tg_bindCell:cell item:item];
        [self.tg_formStack addArrangedSubview:cell];
    }
}

- (NSString *)tg_codeKey:(NSString *)code {
    return [code lowercaseString] ?: @"";
}

- (void)tg_prefillAccountName:(NSString *)name {
    for (TgKYCFormItem *item in self.tg_formItems) {
        if (![[self tg_codeKey:item.performance] isEqualToString:@"accountname"]) continue;
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

#pragma mark - Validation & Submit

- (NSString *)tg_valueForItem:(TgKYCFormItem *)item {
    if (item.favourable != 1) {
        return self.tg_valuesByCode[[self tg_codeKey:item.performance]] ?: @"";
    }
    TgKycFormCell *cell = self.tg_cellsByCode[[self tg_codeKey:item.performance]];
    NSString *text = cell.tg_textField.text ?: @"";
    return [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL)tg_passesRegex:(NSString *)value pattern:(NSString *)pattern {
    if (pattern.length == 0) return YES;
    @try {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
        return [predicate evaluateWithObject:value ?: @""];
    } @catch (__unused NSException *exception) {
        return YES;
    }
}

- (BOOL)tg_validateFormWithToast:(BOOL)showToast {
    for (TgKYCFormItem *item in self.tg_formItems) {
        NSString *value = [self tg_valueForItem:item];
        if (value.length == 0) {
            if (showToast) {
                NSString *name = item.large.length > 0 ? item.large : (item.performance ?: @"Field");
                [[TgPulseOverlay shared] whisperLine:[NSString stringWithFormat:kTgKycValidationTemplate, name]];
            }
            return NO;
        }
        if (![self tg_passesRegex:value pattern:item.keen]) {
            if (showToast) {
                NSString *name = item.large.length > 0 ? item.large : (item.performance ?: @"Field");
                [[TgPulseOverlay shared] whisperLine:[NSString stringWithFormat:kTgKycValidationTemplate, name]];
            }
            return NO;
        }
    }
    return YES;
}

- (NSArray<NSDictionary *> *)tg_buildCommitList {
    NSMutableArray<NSDictionary *> *list = [NSMutableArray array];
    for (TgKYCFormItem *item in self.tg_formItems) {
        NSString *value = [self tg_valueForItem:item];
        if (value.length == 0) continue;
        [list addObject:@{
            @"itemCode": item.performance ?: @"",
            @"itemValue": value,
            @"itemValueType": @1
        }];
    }
    return list;
}

- (void)tg_onContinueTap {
    [self.view endEditing:YES];
    if (![self tg_validateFormWithToast:YES]) return;

    NSArray<NSDictionary *> *commitList = [self tg_buildCommitList];
    [[TgPulseOverlay shared] veilSpin];
    NSDictionary *nonSign = @{ @"kycCommitItemList": commitList };
    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneKycCommit
                             signData:@{ @"kycId": self.tg_kycId ?: @"" }
                           nonSignData:nonSign
                              success:^(__unused id _Nullable data) {
        [[TgPulseOverlay shared] veilDismiss];
        [weakSelf tg_emitSubmitTraceForKycId];
        [TgKycPathRelay continueAfterCommitFromNav:weakSelf.navigationController];
    } failure:^{
        [[TgPulseOverlay shared] veilDismiss];
        [[TgPulseOverlay shared] whisperLine:kTgKycBusyHint];
    }];
}

- (void)tg_emitSubmitTraceForKycId {
    NSString *kid = [self.tg_kycId lowercaseString] ?: @"";
    if ([kid isEqualToString:@"personal"]) {
        [TgTraceRelay emitSignal:TgTraceSignalProfileSubmit];
    } else if ([kid isEqualToString:@"work"]) {
        [TgTraceRelay emitSignal:TgTraceSignalWorkSubmit];
    } else if ([kid isEqualToString:@"questionnaire"]) {
        [TgTraceRelay emitSignal:TgTraceSignalSurveySubmit];
    }
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
