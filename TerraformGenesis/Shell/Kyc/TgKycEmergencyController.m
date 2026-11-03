//

//

#import "TgKycEmergencyController.h"
#import "TgKycFormCell.h"
#import "TgKycPathRelay.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"
#import "TgPulseOverlay.h"
#import "TgShardFacade.h"
#import "TgTraceRelay.h"
#import "TgWireConduit.h"
#import "TgEnvelopeBase.h"
#import "NSString+TgGlyph.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Contacts/Contacts.h>
#import <ContactsUI/ContactsUI.h>
#import <Masonry/Masonry.h>

static NSString * const kTgEmergencyKycId = @"urgent_contact";
static NSString * const kTgEmergencyArrowAsset = @"use_next_loan_hong";
static CGFloat const kTgEmergencyHorzInset = 16.0;
static CGFloat const kTgEmergencyContinueHeight = 50.0;
static CGFloat const kTgEmergencyContinueWidthRatio = 0.85;
static NSString * const kTgEmergencyBodyHex = @"#F1F1F1";
static NSString * const kTgEmergencyTitleHex = @"#364153";
static NSString * const kTgEmergencyPlaceholderHex = @"#9CA3AF";
static NSString * const kTgEmergencyBusyHint = @"The system is occupied. Please retry after 2 minutes.";
static CGFloat const kTgEmergencyFieldRadius = 16.0;
static CGFloat const kTgEmergencyRowHeight = 54.0;
static CGFloat const kTgEmergencyContactCardHeight = 88.0;
static CGFloat const kTgEmergencyCardSpacing = 10.0;
static CGFloat const kTgEmergencyContentTopInset = 27.0;
static NSTimeInterval const kTgEmergencyCommitInterval = 1.0;

#pragma mark - Slot model

@interface TgKycEmergencySlot : NSObject
@property (nonatomic, copy) NSString *prefix;
@property (nonatomic, copy, nullable) NSString *relationItemCode;
@property (nonatomic, copy, nullable) NSString *nameItemCode;
@property (nonatomic, copy, nullable) NSString *phoneItemCode;
@property (nonatomic, copy) NSString *relationshipLabel;
@property (nonatomic, copy) NSString *relationshipKey;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *phone;
@property (nonatomic, copy) NSArray<NSString *> *relationLabels;
@property (nonatomic, copy) NSArray<NSString *> *relationKeys;
@end

@implementation TgKycEmergencySlot
@end

#pragma mark - Selector row

@interface TgKycEmergencyRowView : UIView
@property (nonatomic, strong) UILabel *tg_leftCaption;
@property (nonatomic, strong) UILabel *tg_valueCaption;
@property (nonatomic, strong) UIImageView *tg_arrowGlyph;
@property (nonatomic, copy, nullable) void (^tg_onTap)(void);
- (void)tg_setLeftTitle:(NSString *)title;
- (void)tg_setValueText:(nullable NSString *)text placeholder:(NSString *)placeholder;
@end

@implementation TgKycEmergencyRowView

- (void)tg_disableSubviewInteraction {
    for (UIView *sub in self.subviews) {
        sub.userInteractionEnabled = NO;
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.userInteractionEnabled || self.hidden || self.alpha < 0.01) {
        return [super hitTest:point withEvent:event];
    }
    if ([self pointInside:point withEvent:event]) {
        return self;
    }
    return nil;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.whiteColor;
        self.layer.cornerRadius = kTgEmergencyFieldRadius;
        self.clipsToBounds = YES;
        [self tg_buildUI];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tg_tapped)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)tg_buildUI {
    self.tg_leftCaption = [[UILabel alloc] init];
    self.tg_leftCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    self.tg_leftCaption.textColor = [UIColor tg_toneFromHex:kTgEmergencyTitleHex];
    [self addSubview:self.tg_leftCaption];

    self.tg_valueCaption = [[UILabel alloc] init];
    self.tg_valueCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightMedium];
    self.tg_valueCaption.textAlignment = NSTextAlignmentRight;
    self.tg_valueCaption.numberOfLines = 1;
    [self addSubview:self.tg_valueCaption];

    self.tg_arrowGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgEmergencyArrowAsset]];
    self.tg_arrowGlyph.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.tg_arrowGlyph];

    [self.tg_leftCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(14);
        make.centerY.equalTo(self);
        make.width.mas_lessThanOrEqualTo(120);
    }];
    [self.tg_arrowGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-14);
        make.centerY.equalTo(self);
        make.width.height.mas_equalTo(16);
    }];
    [self.tg_valueCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.tg_arrowGlyph.mas_left).offset(-6);
        make.centerY.equalTo(self);
        make.left.greaterThanOrEqualTo(self.tg_leftCaption.mas_right).offset(8);
    }];
    [self tg_disableSubviewInteraction];
}

- (void)tg_setLeftTitle:(NSString *)title {
    self.tg_leftCaption.text = title;
}

- (void)tg_setValueText:(NSString *)text placeholder:(NSString *)placeholder {
    BOOL empty = text.length == 0;
    self.tg_valueCaption.text = empty ? placeholder : text;
    self.tg_valueCaption.textColor = empty
        ? [UIColor tg_toneFromHex:kTgEmergencyPlaceholderHex]
        : [UIColor tg_toneFromHex:kTgEmergencyTitleHex];
}

- (void)tg_tapped {
    if (self.tg_onTap) self.tg_onTap();
}

@end

#pragma mark - Contact card (Name + Phone)

@interface TgKycEmergencyContactCardView : UIView
@property (nonatomic, strong) UILabel *tg_nameLabelCaption;
@property (nonatomic, strong) UILabel *tg_phoneLabelCaption;
@property (nonatomic, strong) UILabel *tg_nameValueCaption;
@property (nonatomic, strong) UILabel *tg_phoneValueCaption;
@property (nonatomic, strong) UIImageView *tg_arrowGlyph;
@property (nonatomic, copy, nullable) void (^tg_onTap)(void);
- (void)tg_updateWithName:(NSString *)name phone:(NSString *)phone;
@end

@implementation TgKycEmergencyContactCardView

- (void)tg_disableSubviewInteraction {
    for (UIView *sub in self.subviews) {
        sub.userInteractionEnabled = NO;
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.userInteractionEnabled || self.hidden || self.alpha < 0.01) {
        return [super hitTest:point withEvent:event];
    }
    if ([self pointInside:point withEvent:event]) {
        return self;
    }
    return nil;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.whiteColor;
        self.layer.cornerRadius = kTgEmergencyFieldRadius;
        self.clipsToBounds = YES;
        [self tg_buildUI];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tg_tapped)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)tg_buildUI {
    self.tg_nameLabelCaption = [self tg_makeLabelWithText:@"Name"];
    self.tg_phoneLabelCaption = [self tg_makeLabelWithText:@"Phone number"];
    self.tg_nameValueCaption = [[UILabel alloc] init];
    self.tg_nameValueCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightMedium];
    self.tg_nameValueCaption.textAlignment = NSTextAlignmentRight;
    self.tg_phoneValueCaption = [[UILabel alloc] init];
    self.tg_phoneValueCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightMedium];
    self.tg_phoneValueCaption.textAlignment = NSTextAlignmentRight;

    self.tg_arrowGlyph = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kTgEmergencyArrowAsset]];
    self.tg_arrowGlyph.contentMode = UIViewContentModeScaleAspectFit;

    [self addSubview:self.tg_nameLabelCaption];
    [self addSubview:self.tg_phoneLabelCaption];
    [self addSubview:self.tg_nameValueCaption];
    [self addSubview:self.tg_phoneValueCaption];
    [self addSubview:self.tg_arrowGlyph];

    [self.tg_nameLabelCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(14);
        make.top.equalTo(self).offset(16);
    }];
    [self.tg_phoneLabelCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_nameLabelCaption);
        make.top.equalTo(self.tg_nameLabelCaption.mas_bottom).offset(12);
        make.bottom.equalTo(self).offset(-16);
    }];
    [self.tg_arrowGlyph mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-14);
        make.centerY.equalTo(self);
        make.width.height.mas_equalTo(16);
    }];
    [self.tg_nameValueCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.tg_arrowGlyph.mas_left).offset(-6);
        make.centerY.equalTo(self.tg_nameLabelCaption);
        make.left.greaterThanOrEqualTo(self.tg_nameLabelCaption.mas_right).offset(8);
    }];
    [self.tg_phoneValueCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.tg_nameValueCaption);
        make.centerY.equalTo(self.tg_phoneLabelCaption);
        make.left.greaterThanOrEqualTo(self.tg_phoneLabelCaption.mas_right).offset(8);
    }];
    [self tg_disableSubviewInteraction];
}

- (UILabel *)tg_makeLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    label.textColor = [UIColor tg_toneFromHex:kTgEmergencyTitleHex];
    return label;
}

- (void)tg_updateWithName:(NSString *)name phone:(NSString *)phone {
    NSString *nameTrim = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *phoneTrim = [phone stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    BOOL bothEmpty = nameTrim.length == 0 && phoneTrim.length == 0;

    if (bothEmpty) {
        self.tg_nameValueCaption.text = TgKycPlaceholderChoose;
        self.tg_nameValueCaption.textColor = [UIColor tg_toneFromHex:kTgEmergencyPlaceholderHex];
        self.tg_phoneValueCaption.text = @"";
        self.tg_phoneValueCaption.hidden = YES;
        [self.tg_nameValueCaption mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.tg_arrowGlyph.mas_left).offset(-6);
            make.centerY.equalTo(self);
            make.left.greaterThanOrEqualTo(self.tg_nameLabelCaption.mas_right).offset(8);
        }];
        return;
    }

    self.tg_phoneValueCaption.hidden = NO;
    [self.tg_nameValueCaption mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.tg_arrowGlyph.mas_left).offset(-6);
        make.centerY.equalTo(self.tg_nameLabelCaption);
        make.left.greaterThanOrEqualTo(self.tg_nameLabelCaption.mas_right).offset(8);
    }];

    if (nameTrim.length == 0) {
        self.tg_nameValueCaption.text = @"Name";
        self.tg_nameValueCaption.textColor = [UIColor tg_toneFromHex:kTgEmergencyPlaceholderHex];
    } else {
        self.tg_nameValueCaption.text = nameTrim;
        self.tg_nameValueCaption.textColor = [UIColor tg_toneFromHex:kTgEmergencyTitleHex];
    }
    if (phoneTrim.length == 0) {
        self.tg_phoneValueCaption.text = @"Phone number";
        self.tg_phoneValueCaption.textColor = [UIColor tg_toneFromHex:kTgEmergencyPlaceholderHex];
    } else {
        self.tg_phoneValueCaption.text = phoneTrim;
        self.tg_phoneValueCaption.textColor = [UIColor tg_toneFromHex:kTgEmergencyTitleHex];
    }
}

- (void)tg_tapped {
    if (self.tg_onTap) self.tg_onTap();
}

@end

#pragma mark - Contact group

@interface TgKycEmergencyGroupView : UIView
@property (nonatomic, strong) UILabel *tg_sectionTitle;
@property (nonatomic, strong) TgKycEmergencyRowView *tg_relationRow;
@property (nonatomic, strong) TgKycEmergencyContactCardView *tg_contactCard;
@end

@implementation TgKycEmergencyGroupView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.tg_sectionTitle = [[UILabel alloc] init];
        self.tg_sectionTitle.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
        self.tg_sectionTitle.textColor = UIColor.blackColor;

        self.tg_relationRow = [[TgKycEmergencyRowView alloc] init];
        [self.tg_relationRow tg_setLeftTitle:@"Relationship"];

        self.tg_contactCard = [[TgKycEmergencyContactCardView alloc] init];

        [self addSubview:self.tg_sectionTitle];
        [self addSubview:self.tg_relationRow];
        [self addSubview:self.tg_contactCard];

        [self.tg_sectionTitle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.right.equalTo(self);
        }];
        [self.tg_relationRow mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self);
            make.top.equalTo(self.tg_sectionTitle.mas_bottom).offset(10);
            make.height.mas_equalTo(kTgEmergencyRowHeight);
        }];
        [self.tg_contactCard mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self);
            make.top.equalTo(self.tg_relationRow.mas_bottom).offset(kTgEmergencyCardSpacing);
            make.height.mas_equalTo(kTgEmergencyContactCardHeight);
        }];
    }
    return self;
}

- (void)tg_setContactIndex:(NSInteger)index {
    self.tg_sectionTitle.text = [NSString stringWithFormat:@"Contact %ld", (long)(index + 1)];
}

@end

#pragma mark - Controller

@interface TgKycEmergencyController () <CNContactPickerDelegate>

@property (nonatomic, strong) UIView *tg_bodyVeil;
@property (nonatomic, strong) UIScrollView *tg_scrollPane;
@property (nonatomic, strong) UIStackView *tg_contentStack;
@property (nonatomic, strong) UIButton *tg_applyLatch;
@property (nonatomic, strong) TgKycFormCell *tg_emailCell;

@property (nonatomic, copy) NSArray<TgKycEmergencySlot *> *tg_slots;
@property (nonatomic, copy) NSArray<TgKycEmergencyGroupView *> *tg_groupViews;
@property (nonatomic, copy) NSString *tg_emailRegex;
@property (nonatomic, strong, nullable) TgKYCFormItem *tg_emailItem;
@property (nonatomic, assign) BOOL tg_submitBusy;
@property (nonatomic, assign) NSInteger tg_pickerIndex;
@property (nonatomic, assign) NSTimeInterval tg_lastCommitTime;

@end

@implementation TgKycEmergencyController

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
    [self tg_setNavTitleMedium18:@"Emergency contact"];
    __weak typeof(self) weakSelf = self;
    self.tg_backInterceptBlock = ^BOOL {
        [weakSelf tg_showReturnConfirmDialog];
        return NO;
    };
    [self tg_buildLayout];
    [self tg_loadKycInit];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - Layout

- (void)tg_buildLayout {
    self.tg_bodyVeil = [[UIView alloc] init];
    self.tg_bodyVeil.backgroundColor = [UIColor tg_toneFromHex:kTgEmergencyBodyHex];
    [self.view insertSubview:self.tg_bodyVeil atIndex:1];

    self.tg_applyLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_applyLatch setTitle:@"Apply" forState:UIControlStateNormal];
    [self.tg_applyLatch setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.tg_applyLatch.titleLabel.font = [UIFont tg_meshGlyphWithSize:16 weight:UIFontWeightMedium];
    self.tg_applyLatch.backgroundColor = [UIColor tg_toneFromHex:@"#182040"];
    self.tg_applyLatch.layer.cornerRadius = kTgEmergencyContinueHeight / 2.0;
    self.tg_applyLatch.clipsToBounds = YES;
    [self.tg_applyLatch addTarget:self action:@selector(tg_onApplyTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.tg_applyLatch];

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

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tg_dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.tg_scrollPane addGestureRecognizer:tap];

    [self.tg_bodyVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset([self tg_contentTopBelowNavigation]);
        make.bottom.equalTo(self.tg_applyLatch.mas_top).offset(-12);
    }];
    [self.tg_applyLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(kTgEmergencyContinueWidthRatio);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-16);
        make.height.mas_equalTo(kTgEmergencyContinueHeight);
    }];
    [self.tg_scrollPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_bodyVeil);
    }];
    [self.tg_contentStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_scrollPane).insets(UIEdgeInsetsMake(kTgEmergencyContentTopInset, kTgEmergencyHorzInset, 20, kTgEmergencyHorzInset));
        make.width.equalTo(self.tg_scrollPane).offset(-kTgEmergencyHorzInset * 2);
    }];
}

#pragma mark - Init

- (void)tg_loadKycInit {
    [[TgPulseOverlay shared] veilSpin];
    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneKycInit
                             signData:@{ @"kycId": kTgEmergencyKycId }
                           nonSignData:@{}
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        __strong typeof(weakSelf) self = weakSelf;
        [[TgPulseOverlay shared] veilDismiss];
        if (!self) return;
        if (envelope.cheer != 200) {
            NSString *msg = envelope.power.length > 0 ? envelope.power : kTgEmergencyBusyHint;
            [[TgPulseOverlay shared] whisperLine:msg];
            return;
        }
        TgKYCInitData *initData = [TgKYCInitData yy_modelWithJSON:envelope.trick];
        if (!initData || initData.nevertheless.count == 0) {
            [[TgPulseOverlay shared] whisperLine:kTgEmergencyBusyHint];
            return;
        }
        NSArray<TgKYCFormItem *> *sorted = [initData.nevertheless sortedArrayUsingComparator:^NSComparisonResult(TgKYCFormItem *a, TgKYCFormItem *b) {
            if (a.itemSort == b.itemSort) return NSOrderedSame;
            return a.itemSort < b.itemSort ? NSOrderedAscending : NSOrderedDescending;
        }];
        [self tg_applyInitItems:sorted];
    } failure:^{
        [[TgPulseOverlay shared] veilDismiss];
        [[TgPulseOverlay shared] whisperLine:kTgEmergencyBusyHint];
    }];
}

- (void)tg_applyInitItems:(NSArray<TgKYCFormItem *> *)items {
    NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, TgKYCFormItem *> *> *groups = [NSMutableDictionary dictionary];
    NSMutableSet<NSString *> *prefixes = [NSMutableSet set];
    NSString *emailRegex = @"";
    TgKYCFormItem *emailItem = nil;

    for (TgKYCFormItem *item in items) {
        NSString *code = item.performance ?: @"";
        NSString *lower = code.lowercaseString;
        if ([lower isEqualToString:@"email"]) {
            emailRegex = item.keen ?: @"";
            emailItem = item;
            continue;
        }
        NSRange us = [code rangeOfString:@"_"];
        if (us.location == NSNotFound) continue;
        NSString *prefix = [code substringToIndex:us.location];
        NSString *suffix = [[code substringFromIndex:us.location + 1] lowercaseString];
        [prefixes addObject:prefix];
        if (!groups[prefix]) groups[prefix] = [NSMutableDictionary dictionary];
        groups[prefix][suffix] = item;
    }

    self.tg_emailRegex = emailRegex;
    self.tg_emailItem = emailItem;

    NSArray<NSString *> *sortedPrefixes = [[prefixes allObjects] sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray<TgKycEmergencySlot *> *slots = [NSMutableArray array];
    for (NSInteger i = 0; i < 3; i++) {
        NSString *prefix = i < (NSInteger)sortedPrefixes.count
            ? sortedPrefixes[i]
            : [NSString stringWithFormat:@"contact_%ld", (long)(i + 1)];
        NSDictionary<NSString *, TgKYCFormItem *> *group = groups[prefix];
        TgKYCFormItem *relItem = group[@"relation"] ?: group[@"relationship"];
        NSDictionary *opts = [self tg_relationOptionsFromItem:relItem prefix:prefix group:group];

        TgKycEmergencySlot *slot = [[TgKycEmergencySlot alloc] init];
        slot.prefix = prefix;
        slot.relationItemCode = opts[@"relationCode"];
        slot.nameItemCode = opts[@"nameCode"];
        slot.phoneItemCode = opts[@"phoneCode"];
        slot.relationshipLabel = @"";
        slot.relationshipKey = @"";
        slot.name = @"";
        slot.phone = @"";
        slot.relationLabels = opts[@"labels"];
        slot.relationKeys = opts[@"keys"];
        [slots addObject:slot];
    }
    self.tg_slots = slots;
    [self tg_mountForm];
}

- (NSDictionary *)tg_relationOptionsFromItem:(TgKYCFormItem *)item
                                        prefix:(NSString *)prefix
                                         group:(NSDictionary<NSString *, TgKYCFormItem *> *)group {
    NSMutableArray<NSString *> *labels = [NSMutableArray array];
    NSMutableArray<NSString *> *keys = [NSMutableArray array];
    if (item.radio.count > 0) {
        NSArray<TgKYCButtonItem *> *sorted = [item.radio sortedArrayUsingComparator:^NSComparisonResult(TgKYCButtonItem *a, TgKYCButtonItem *b) {
            if (a.buttonSort == b.buttonSort) return NSOrderedSame;
            return a.buttonSort < b.buttonSort ? NSOrderedAscending : NSOrderedDescending;
        }];
        for (TgKYCButtonItem *btn in sorted) {
            if (btn.purchase.length > 0) {
                [labels addObject:btn.purchase];
                [keys addObject:btn.optional.length > 0 ? btn.optional : btn.purchase];
            }
        }
    } else {
        for (NSString *s in item.squeeze) {
            if (s.length > 0) [labels addObject:s];
        }
        for (NSString *s in item.intend) {
            if (s.length > 0 && ![labels containsObject:s]) [labels addObject:s];
        }
        if (labels.count > 0) [keys addObjectsFromArray:labels];
    }

    TgKYCFormItem *nameItem = group[@"name"];
    TgKYCFormItem *phoneItem = group[@"phone"] ?: group[@"phonenumber"] ?: group[@"phone_number"];
    NSString *relCode = item.performance ?: [NSString stringWithFormat:@"%@_relation", prefix];
    NSString *nameCode = nameItem.performance ?: [NSString stringWithFormat:@"%@_name", prefix];
    NSString *phoneCode = phoneItem.performance ?: [NSString stringWithFormat:@"%@_phone", prefix];

    return @{
        @"labels": labels,
        @"keys": keys,
        @"relationCode": relCode,
        @"nameCode": nameCode,
        @"phoneCode": phoneCode
    };
}

- (void)tg_mountForm {
    for (UIView *v in self.tg_contentStack.arrangedSubviews) {
        [self.tg_contentStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }

    NSMutableArray<TgKycEmergencyGroupView *> *groups = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    for (NSInteger i = 0; i < self.tg_slots.count; i++) {
        TgKycEmergencySlot *slot = self.tg_slots[i];
        TgKycEmergencyGroupView *group = [[TgKycEmergencyGroupView alloc] init];
        [group tg_setContactIndex:i];
        [group.tg_relationRow tg_setValueText:slot.relationshipLabel placeholder:TgKycPlaceholderChoose];
        [group.tg_contactCard tg_updateWithName:slot.name phone:slot.phone];

        NSInteger idx = i;
        group.tg_relationRow.tg_onTap = ^{
            [weakSelf tg_presentRelationshipPickerAtIndex:idx];
        };
        group.tg_contactCard.tg_onTap = ^{
            [weakSelf tg_presentContactPickerAtIndex:idx];
        };

        [self.tg_contentStack addArrangedSubview:group];
        [groups addObject:group];
    }
    self.tg_groupViews = groups;

    if (self.tg_emailItem) {
        self.tg_emailCell = [[TgKycFormCell alloc] init];
        NSString *emailTitle = self.tg_emailItem.large.length > 0 ? self.tg_emailItem.large : @"E-Mail";
        [self.tg_emailCell tg_configureWithTitle:emailTitle
                                   placeholder:TgKycPlaceholderEnter
                                          mode:TgKycFormCellModeInput
                                        filter:TgKycFormInputFilterNone
                                      keyboard:UIKeyboardTypeEmailAddress];
        [self.tg_emailCell tg_bindItemCode:@"email"];
        self.tg_emailCell.tg_textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [self.tg_contentStack addArrangedSubview:self.tg_emailCell];
    }
}

- (void)tg_refreshGroupAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.tg_slots.count || index >= (NSInteger)self.tg_groupViews.count) return;
    TgKycEmergencySlot *slot = self.tg_slots[index];
    TgKycEmergencyGroupView *group = self.tg_groupViews[index];
    [group.tg_relationRow tg_setValueText:slot.relationshipLabel placeholder:TgKycPlaceholderChoose];
    [group.tg_contactCard tg_updateWithName:slot.name phone:slot.phone];
}

#pragma mark - Pickers

- (void)tg_presentRelationshipPickerAtIndex:(NSInteger)index {
    [self tg_dismissKeyboard];
    if (index >= (NSInteger)self.tg_slots.count) return;
    TgKycEmergencySlot *slot = self.tg_slots[index];
    if (slot.relationLabels.count == 0) {
        [[TgPulseOverlay shared] whisperLine:@"No relationship options are available"];
        return;
    }
    NSInteger selectedIndex = NSNotFound;
    if (slot.relationshipKey.length > 0) {
        NSUInteger idx = [slot.relationKeys indexOfObject:slot.relationshipKey];
        if (idx != NSNotFound) selectedIndex = (NSInteger)idx;
    } else if (slot.relationshipLabel.length > 0) {
        NSUInteger idx = [slot.relationLabels indexOfObject:slot.relationshipLabel];
        if (idx != NSNotFound) selectedIndex = (NSInteger)idx;
    }

    __weak typeof(self) weakSelf = self;
    [[TgShardFacade shared] showOptionPickerWithTitle:@"Relationship"
                                              options:slot.relationLabels
                                        selectedIndex:selectedIndex
                                         confirmTitle:@"Confirm"
                                            onConfirm:^(__unused NSInteger pickIndex, NSString *value) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || index >= (NSInteger)self.tg_slots.count) return;
        TgKycEmergencySlot *s = self.tg_slots[index];
        NSUInteger i = [s.relationLabels indexOfObject:value];
        if (i == NSNotFound) return;
        s.relationshipLabel = value;
        if (i < s.relationKeys.count) {
            NSString *key = s.relationKeys[i];
            s.relationshipKey = key.length > 0 ? key : value;
        } else {
            s.relationshipKey = value;
        }
        [self tg_refreshGroupAtIndex:index];
    }];
}

- (void)tg_presentContactPickerAtIndex:(NSInteger)index {
    [self tg_dismissKeyboard];
    [TgTraceRelay emitSignal:TgTraceSignalContactPick content:@"Emergency contact select"];
    self.tg_pickerIndex = index;
    CNContactPickerViewController *picker = [[CNContactPickerViewController alloc] init];
    picker.delegate = self;
    picker.predicateForEnablingContact = [NSPredicate predicateWithFormat:@"phoneNumbers.@count > 0"];
    picker.predicateForSelectionOfProperty = [NSPredicate predicateWithFormat:@"key == %@", CNContactPhoneNumbersKey];
    picker.displayedPropertyKeys = @[CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey];
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - CNContactPickerDelegate

- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContactProperty:(CNContactProperty *)contactProperty {
    CNContact *contact = contactProperty.contact;
    NSString *first = contact.givenName ?: @"";
    NSString *last = contact.familyName ?: @"";
    NSString *fullName = [[NSString stringWithFormat:@"%@ %@", first, last]
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *rawPhone = @"";
    if ([contactProperty.value isKindOfClass:[CNPhoneNumber class]]) {
        rawPhone = ((CNPhoneNumber *)contactProperty.value).stringValue;
    }
    NSString *cleaned = [NSString tg_indianPhoneNormalizedFromMixed:rawPhone];
    NSInteger idx = self.tg_pickerIndex;
    if (idx < 0 || idx >= (NSInteger)self.tg_slots.count) return;
    if (![self tg_validatePickedContactName:fullName phone:cleaned atIndex:idx]) return;
    TgKycEmergencySlot *slot = self.tg_slots[idx];
    slot.name = fullName;
    slot.phone = cleaned;
    [self tg_refreshGroupAtIndex:idx];
}

- (void)contactPickerDidCancel:(CNContactPickerViewController *)picker {
}

#pragma mark - Validation

- (BOOL)tg_isDuplicatePhone:(NSString *)phone excludingIndex:(NSInteger)exclude {
    NSString *a = [NSString tg_indianPhoneNormalizedFromMixed:phone];
    if (a.length == 0) return NO;
    for (NSInteger i = 0; i < (NSInteger)self.tg_slots.count; i++) {
        if (i == exclude) continue;
        NSString *b = [NSString tg_indianPhoneNormalizedFromMixed:self.tg_slots[i].phone];
        if (b.length > 0 && [a isEqualToString:b]) return YES;
    }
    return NO;
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

- (BOOL)tg_validatePickedContactName:(NSString *)name phone:(NSString *)phone atIndex:(NSInteger)index {
    NSInteger n = index + 1;
    NSString *trimName = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *cleaned = [NSString tg_indianPhoneNormalizedFromMixed:phone];

    if (trimName.length == 0) {
        [[TgPulseOverlay shared] whisperLine:[NSString stringWithFormat:@"Contact%ld - The name field cannot be left empty", (long)n]];
        return NO;
    }
    if (cleaned.length == 0) {
        [[TgPulseOverlay shared] whisperLine:[NSString stringWithFormat:@"Contact%ld - Please add your emergency contact.", (long)n]];
        return NO;
    }
    if (![NSString tg_isValidIndianLocalPhone:cleaned]) {
        [[TgPulseOverlay shared] whisperLine:[NSString stringWithFormat:@"Contact%ld - The contact phone number is invalid; please verify it", (long)n]];
        return NO;
    }
    if ([self tg_isDuplicatePhone:cleaned excludingIndex:index]) {
        [[TgPulseOverlay shared] whisperLine:[NSString stringWithFormat:@"Contact%ld - This contact was already submitted; please enter a different one", (long)n]];
        return NO;
    }
    return YES;
}

- (BOOL)tg_validateAllWithToast:(BOOL)showToast {
    for (NSInteger i = 0; i < (NSInteger)self.tg_slots.count; i++) {
        NSInteger n = i + 1;
        TgKycEmergencySlot *slot = self.tg_slots[i];
        NSString *rel = [slot.relationshipLabel stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *name = [slot.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *phone = [NSString tg_indianPhoneNormalizedFromMixed:slot.phone];

        if (rel.length == 0) {
            if (showToast) {
                [[TgPulseOverlay shared] whisperLine:[NSString stringWithFormat:@"Contact%ld - Relationship is not selected. Please choose one before submitting.", (long)n]];
            }
            return NO;
        }
        if (name.length == 0 && phone.length == 0) {
            if (showToast) {
                [[TgPulseOverlay shared] whisperLine:[NSString stringWithFormat:@"Contact%ld - Please add your emergency contact.", (long)n]];
            }
            return NO;
        }
        if (phone.length > 0 && name.length == 0) {
            if (showToast) {
                [[TgPulseOverlay shared] whisperLine:[NSString stringWithFormat:@"Contact%ld - The name field cannot be left empty", (long)n]];
            }
            return NO;
        }
        if (phone.length > 0 && ![NSString tg_isValidIndianLocalPhone:phone]) {
            if (showToast) {
                [[TgPulseOverlay shared] whisperLine:[NSString stringWithFormat:@"Contact%ld - The contact phone number is invalid; please verify it", (long)n]];
            }
            return NO;
        }
        if (phone.length > 0 && [self tg_isDuplicatePhone:phone excludingIndex:i]) {
            if (showToast) {
                [[TgPulseOverlay shared] whisperLine:[NSString stringWithFormat:@"Contact%ld - This contact was already submitted; please enter a different one", (long)n]];
            }
            return NO;
        }
    }

    if (self.tg_emailCell) {
        NSString *email = [self.tg_emailCell.tg_textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
        if (email.length == 0) {
            if (showToast) [[TgPulseOverlay shared] whisperLine:@"Please type in your email"];
            return NO;
        }
        if (self.tg_emailRegex.length > 0 && ![self tg_passesRegex:email pattern:self.tg_emailRegex]) {
            if (showToast) [[TgPulseOverlay shared] whisperLine:@"Please enter a valid email"];
            return NO;
        }
    }
    return YES;
}

#pragma mark - Submit

- (NSArray<NSDictionary *> *)tg_buildCommitList {
    NSMutableArray<NSDictionary *> *list = [NSMutableArray array];
    if (self.tg_emailCell) {
        NSString *email = [self.tg_emailCell.tg_textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
        NSString *emailCode = self.tg_emailItem.performance.length > 0 ? self.tg_emailItem.performance : @"email";
        [list addObject:@{ @"itemCode": emailCode, @"itemValue": email, @"itemValueType": @1 }];
    }

    for (TgKycEmergencySlot *slot in self.tg_slots) {
        NSString *relValue = slot.relationshipKey.length > 0 ? slot.relationshipKey : slot.relationshipLabel;
        NSString *nameValue = [slot.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *phoneValue = [NSString tg_indianPhoneNormalizedFromMixed:slot.phone];
        if (slot.relationItemCode.length > 0) {
            [list addObject:@{ @"itemCode": slot.relationItemCode, @"itemValue": relValue ?: @"", @"itemValueType": @1 }];
        }
        if (slot.nameItemCode.length > 0) {
            [list addObject:@{ @"itemCode": slot.nameItemCode, @"itemValue": nameValue, @"itemValueType": @1 }];
        }
        if (slot.phoneItemCode.length > 0) {
            [list addObject:@{ @"itemCode": slot.phoneItemCode, @"itemValue": phoneValue, @"itemValueType": @1 }];
        }
    }
    return list;
}

- (void)tg_dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)tg_onApplyTap {
    [self tg_dismissKeyboard];
    NSTimeInterval now = [NSDate date].timeIntervalSince1970;
    if (now - self.tg_lastCommitTime < kTgEmergencyCommitInterval) return;
    if (self.tg_submitBusy) return;
    if (![self tg_validateAllWithToast:YES]) return;

    self.tg_lastCommitTime = now;
    self.tg_submitBusy = YES;
    self.tg_applyLatch.enabled = NO;
    self.tg_applyLatch.alpha = 0.6;
    [TgTraceRelay emitSignal:TgTraceSignalEmergencySubmit content:@"Emergency contact submit"];
    [[TgPulseOverlay shared] veilSpin];

    NSDictionary *nonSign = @{ @"kycCommitItemList": [self tg_buildCommitList] };
    __weak typeof(self) weakSelf = self;
    [[TgWireConduit shared] relayPOST:TgLaneKycCommit
                             signData:@{ @"kycId": kTgEmergencyKycId }
                           nonSignData:nonSign
                      envelopeSuccess:^(TgEnvelopeBase *envelope) {
        __strong typeof(weakSelf) self = weakSelf;
        [[TgPulseOverlay shared] veilDismiss];
        self.tg_submitBusy = NO;
        self.tg_applyLatch.enabled = YES;
        self.tg_applyLatch.alpha = 1.0;
        if (envelope.cheer != 200) {
            NSString *msg = envelope.power.length > 0 ? envelope.power : kTgEmergencyBusyHint;
            [[TgPulseOverlay shared] whisperLine:msg];
            return;
        }
        [TgKycPathRelay continueAfterCommitFromNav:self.navigationController];
    } failure:^{
        __strong typeof(weakSelf) self = weakSelf;
        [[TgPulseOverlay shared] veilDismiss];
        self.tg_submitBusy = NO;
        self.tg_applyLatch.enabled = YES;
        self.tg_applyLatch.alpha = 1.0;
        [[TgPulseOverlay shared] whisperLine:kTgEmergencyBusyHint];
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
