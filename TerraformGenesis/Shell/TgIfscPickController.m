//

//

#import "TgIfscPickController.h"
#import "TgKycFormCell.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"
#import "TgPulseOverlay.h"
#import "TgShardFacade.h"
#import "TgWireConduit.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>

static CGFloat const kTgIfscHorzInset = 16.0;
static CGFloat const kTgIfscContinueHeight = 50.0;
static CGFloat const kTgIfscSubmitWidthRatio = 0.85;
static NSString * const kTgIfscBodyToneHex = @"#F1F1F1";
static NSString * const kTgIfscBusyHint = @"The system is occupied. Please retry after 2 minutes.";

@interface TgIfscPickController ()

@property (nonatomic, strong) UIView *tg_bodyVeil;
@property (nonatomic, strong) UIScrollView *tg_scrollPane;
@property (nonatomic, strong) UIStackView *tg_rowStack;
@property (nonatomic, strong) TgKycFormCell *tg_stateCell;
@property (nonatomic, strong) TgKycFormCell *tg_cityCell;
@property (nonatomic, strong) TgKycFormCell *tg_bankCell;
@property (nonatomic, strong) TgKycFormCell *tg_branchCell;
@property (nonatomic, strong) UIButton *tg_continueLatch;
@property (nonatomic, copy) NSString *tg_selectedState;
@property (nonatomic, copy) NSString *tg_selectedCity;
@property (nonatomic, copy) NSString *tg_selectedBank;
@property (nonatomic, copy) NSString *tg_selectedBranch;

@end

@implementation TgIfscPickController

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
    [self tg_setNavTitleMedium18:@"Find IFSC"];
    [self tg_buildLayout];
    [self tg_refreshSelectorDisplays];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - Layout

- (TgKycFormCell *)tg_makeSelectorCellWithTitle:(NSString *)title onTap:(void (^)(void))onTap {
    TgKycFormCell *cell = [[TgKycFormCell alloc] init];
    [cell tg_configureWithTitle:title
                    placeholder:TgKycPlaceholderChoose
                           mode:TgKycFormCellModeSelector
                         filter:TgKycFormInputFilterNone
                       keyboard:UIKeyboardTypeDefault];
    cell.tg_onRowTapped = onTap;
    return cell;
}

- (void)tg_buildLayout {
    self.tg_bodyVeil = [[UIView alloc] init];
    self.tg_bodyVeil.backgroundColor = [UIColor tg_toneFromHex:kTgIfscBodyToneHex];
    [self.view insertSubview:self.tg_bodyVeil atIndex:1];

    self.tg_continueLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_continueLatch setTitle:@"Submit" forState:UIControlStateNormal];
    [self.tg_continueLatch setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.tg_continueLatch.titleLabel.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    self.tg_continueLatch.backgroundColor = [UIColor tg_toneFromHex:@"#182040"];
    self.tg_continueLatch.layer.cornerRadius = kTgIfscContinueHeight / 2.0;
    self.tg_continueLatch.clipsToBounds = YES;
    [self.tg_continueLatch addTarget:self action:@selector(tg_onContinueTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.tg_continueLatch];

    self.tg_scrollPane = [[UIScrollView alloc] init];
    self.tg_scrollPane.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.tg_scrollPane];

    self.tg_rowStack = [[UIStackView alloc] init];
    self.tg_rowStack.axis = UILayoutConstraintAxisVertical;
    self.tg_rowStack.spacing = TgKycFormCellStackSpacing;
    [self.tg_scrollPane addSubview:self.tg_rowStack];

    __weak typeof(self) weakSelf = self;
    self.tg_stateCell = [self tg_makeSelectorCellWithTitle:@"BANK State" onTap:^{ [weakSelf tg_pickState]; }];
    self.tg_cityCell = [self tg_makeSelectorCellWithTitle:@"BANK City" onTap:^{ [weakSelf tg_pickCity]; }];
    self.tg_bankCell = [self tg_makeSelectorCellWithTitle:@"BANK Name" onTap:^{ [weakSelf tg_pickBank]; }];
    self.tg_branchCell = [self tg_makeSelectorCellWithTitle:@"BANK Branch" onTap:^{ [weakSelf tg_pickBranch]; }];
    [self.tg_rowStack addArrangedSubview:self.tg_stateCell];
    [self.tg_rowStack addArrangedSubview:self.tg_cityCell];
    [self.tg_rowStack addArrangedSubview:self.tg_bankCell];
    [self.tg_rowStack addArrangedSubview:self.tg_branchCell];

    [self.tg_bodyVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset([self tg_contentTopBelowNavigation]);
        make.bottom.equalTo(self.tg_continueLatch.mas_top).offset(-12);
    }];
    [self.tg_continueLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(kTgIfscSubmitWidthRatio);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-16);
        make.height.mas_equalTo(kTgIfscContinueHeight);
    }];
    [self.tg_scrollPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_bodyVeil);
    }];
    [self.tg_rowStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_scrollPane).insets(UIEdgeInsetsMake(12, kTgIfscHorzInset, 20, kTgIfscHorzInset));
        make.width.equalTo(self.tg_scrollPane).offset(-kTgIfscHorzInset * 2);
    }];
}

- (void)tg_refreshSelectorDisplays {
    [self tg_updateCell:self.tg_stateCell value:self.tg_selectedState];
    [self tg_updateCell:self.tg_cityCell value:self.tg_selectedCity];
    [self tg_updateCell:self.tg_bankCell value:self.tg_selectedBank];
    [self tg_updateCell:self.tg_branchCell value:self.tg_selectedBranch];
}

- (void)tg_updateCell:(TgKycFormCell *)cell value:(NSString *)value {
    if (value.length > 0) {
        [cell tg_setDisplayText:value isPlaceholderStyle:NO];
    } else {
        [cell tg_setDisplayText:TgKycPlaceholderChoose isPlaceholderStyle:YES];
    }
}

#pragma mark - Pick flow

- (void)tg_pickState {
    [self tg_fetchListWithState:@"" city:@"" bank:@"" branch:@"" completion:^(NSArray<NSString *> *list) {
        [self tg_presentOptions:list title:@"BANK State" handler:^(NSString *value) {
            self.tg_selectedState = value;
            self.tg_selectedCity = nil;
            self.tg_selectedBank = nil;
            self.tg_selectedBranch = nil;
            [self tg_refreshSelectorDisplays];
        }];
    }];
}

- (void)tg_pickCity {
    if (self.tg_selectedState.length == 0) {
        [[TgPulseOverlay shared] whisperLine:@"Please select the bank state"];
        return;
    }
    [self tg_fetchListWithState:self.tg_selectedState city:@"" bank:@"" branch:@"" completion:^(NSArray<NSString *> *list) {
        [self tg_presentOptions:list title:@"BANK City" handler:^(NSString *value) {
            self.tg_selectedCity = value;
            self.tg_selectedBank = nil;
            self.tg_selectedBranch = nil;
            [self tg_refreshSelectorDisplays];
        }];
    }];
}

- (void)tg_pickBank {
    if (self.tg_selectedState.length == 0) {
        [[TgPulseOverlay shared] whisperLine:@"Please select the bank state"];
        return;
    }
    if (self.tg_selectedCity.length == 0) {
        [[TgPulseOverlay shared] whisperLine:@"Please select the bank city"];
        return;
    }
    [self tg_fetchListWithState:self.tg_selectedState city:self.tg_selectedCity bank:@"" branch:@"" completion:^(NSArray<NSString *> *list) {
        [self tg_presentOptions:list title:@"BANK Name" handler:^(NSString *value) {
            self.tg_selectedBank = value;
            self.tg_selectedBranch = nil;
            [self tg_refreshSelectorDisplays];
        }];
    }];
}

- (void)tg_pickBranch {
    if (self.tg_selectedState.length == 0) {
        [[TgPulseOverlay shared] whisperLine:@"Please select the bank state"];
        return;
    }
    if (self.tg_selectedCity.length == 0) {
        [[TgPulseOverlay shared] whisperLine:@"Please select the bank city"];
        return;
    }
    if (self.tg_selectedBank.length == 0) {
        [[TgPulseOverlay shared] whisperLine:@"Please select the bank name"];
        return;
    }
    NSString *state = self.tg_selectedState;
    NSString *city = self.tg_selectedCity;
    NSString *bank = self.tg_selectedBank;
    [self tg_fetchListWithState:state city:city bank:bank branch:@"" completion:^(NSArray<NSString *> *list) {
        [self tg_presentOptions:list title:@"BANK Branch" handler:^(NSString *value) {
            self.tg_selectedBranch = value;
            [self tg_refreshSelectorDisplays];
        }];
    }];
}

- (void)tg_onContinueTap {
    if (self.tg_selectedState.length == 0) {
        [[TgPulseOverlay shared] whisperLine:@"Please select the bank state"];
        return;
    }
    if (self.tg_selectedCity.length == 0) {
        [[TgPulseOverlay shared] whisperLine:@"Please select the bank city"];
        return;
    }
    if (self.tg_selectedBank.length == 0) {
        [[TgPulseOverlay shared] whisperLine:@"Please select the bank name"];
        return;
    }
    if (self.tg_selectedBranch.length == 0) {
        [[TgPulseOverlay shared] whisperLine:@"Please select the bank branch"];
        return;
    }
    [self tg_fetchIfscCodeWithState:self.tg_selectedState
                               city:self.tg_selectedCity
                               bank:self.tg_selectedBank
                             branch:self.tg_selectedBranch];
}

#pragma mark - API

- (NSDictionary *)tg_ifscPayloadWithState:(NSString *)state city:(NSString *)city bank:(NSString *)bank branch:(NSString *)branch {
    // Docs 07/29: fields live under request `data` via nonSignData — do not nest another `data` key.
    return @{
        @"state": state ?: @"",
        @"city": city ?: @"",
        @"bank": bank ?: @"",
        @"branch": branch ?: @""
    };
}

- (BOOL)tg_isValidIfscCode:(NSString *)code {
    NSString *trim = [[code stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    if (trim.length == 0 || trim.length > 11) return NO;
    if ([trim rangeOfString:@" "].location != NSNotFound) return NO;
    NSCharacterSet *allowed = [NSCharacterSet alphanumericCharacterSet];
    return [trim rangeOfCharacterFromSet:[allowed invertedSet]].location == NSNotFound;
}

- (void)tg_fetchListWithState:(NSString *)state
                         city:(NSString *)city
                         bank:(NSString *)bank
                       branch:(NSString *)branch
                   completion:(void (^)(NSArray<NSString *> *list))completion {
    [[TgPulseOverlay shared] veilSpin];
    NSDictionary *payload = [self tg_ifscPayloadWithState:state city:city bank:bank branch:branch];
    [[TgWireConduit shared] relayPOST:TgLaneSysIfsc
                             signData:@{}
                           nonSignData:payload
                              success:^(id _Nullable data) {
        [[TgPulseOverlay shared] veilDismiss];
        TgIfscData *ifscData = [TgIfscData yy_modelWithJSON:data];
        if (completion) completion(ifscData.list ?: @[]);
    } failure:^{
        [[TgPulseOverlay shared] veilDismiss];
        [[TgPulseOverlay shared] whisperLine:kTgIfscBusyHint];
        if (completion) completion(@[]);
    }];
}

- (void)tg_fetchIfscCodeWithState:(NSString *)state city:(NSString *)city bank:(NSString *)bank branch:(NSString *)branch {
    [[TgPulseOverlay shared] veilSpin];
    NSDictionary *payload = [self tg_ifscPayloadWithState:state city:city bank:bank branch:branch];
    [[TgWireConduit shared] relayPOST:TgLaneSysIfsc
                             signData:@{}
                           nonSignData:payload
                              success:^(id _Nullable data) {
        [[TgPulseOverlay shared] veilDismiss];
        TgIfscData *ifscData = [TgIfscData yy_modelWithJSON:data];
        NSString *code = nil;
        for (NSString *item in ifscData.list) {
            NSString *trim = [item stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([self tg_isValidIfscCode:trim]) {
                code = [trim uppercaseString];
                break;
            }
        }
        if (code.length == 0) {
            [[TgPulseOverlay shared] whisperLine:@"Please select the bank branch again to obtain a valid IFSC"];
            return;
        }
        if (self.tg_onPicked) {
            self.tg_onPicked(code);
        }
        [self.navigationController popViewControllerAnimated:YES];
    } failure:^{
        [[TgPulseOverlay shared] veilDismiss];
        [[TgPulseOverlay shared] whisperLine:kTgIfscBusyHint];
    }];
}

- (NSInteger)tg_selectedIndexInOptions:(NSArray<NSString *> *)options currentValue:(NSString *)value {
    if (value.length == 0) return NSNotFound;
    NSUInteger idx = [options indexOfObject:value];
    return idx == NSNotFound ? NSNotFound : (NSInteger)idx;
}

- (NSString *)tg_currentValueForPickerTitle:(NSString *)title {
    if ([title isEqualToString:@"BANK State"]) return self.tg_selectedState;
    if ([title isEqualToString:@"BANK City"]) return self.tg_selectedCity;
    if ([title isEqualToString:@"BANK Name"]) return self.tg_selectedBank;
    if ([title isEqualToString:@"BANK Branch"]) return self.tg_selectedBranch;
    return nil;
}

- (void)tg_presentOptions:(NSArray<NSString *> *)options
                    title:(NSString *)title
                  handler:(void (^)(NSString *value))handler {
    if (options.count == 0) {
        [[TgPulseOverlay shared] whisperLine:kTgIfscBusyHint];
        return;
    }
    NSInteger selectedIndex = [self tg_selectedIndexInOptions:options
                                                 currentValue:[self tg_currentValueForPickerTitle:title]];
    [[TgShardFacade shared] showOptionPickerWithTitle:title
                                              options:options
                                        selectedIndex:selectedIndex
                                         confirmTitle:@"Confirm"
                                            onConfirm:^(__unused NSInteger index, NSString *value) {
        if (handler) handler(value);
    }];
}

@end
