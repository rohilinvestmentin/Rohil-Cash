//

//

#import "TgBankVaultController.h"
#import "TgBankEditVaultController.h"
#import "TgParcelRegistry.h"
#import "TgPayloadModels.h"
#import "TgPulseOverlay.h"
#import "TgWireConduit.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import "NSString+TgGlyph.h"
#import <Masonry/Masonry.h>

static CGFloat const kTgBankHorzInset = 16.0;
static CGFloat const kTgBankCardTopInset = 20.0;
static CGFloat const kTgBankCardOverlap = 10.0;
static NSString * const kTgBankBodyToneHex = @"#F1F1F1";
static NSString * const kTgBankNoticeBgHex = @"#FCF4EE";
static NSString * const kTgBankNoticeTextHex = @"#EA834C";
static NSString * const kTgBankBusyHint = @"The system is occupied. Please retry after 2 minutes.";
static NSString * const kTgBankNoticeText =
@"Tap the bank card logo to edit the details. While your loan is under review, bank account information cannot be changed.";
static NSString * const kTgBankEmptyText = @"No Bank Account";
static NSString * const kTgBankEmptyToneHex = @"#686868";

@interface TgBankVaultController ()

@property (nonatomic, strong) UIView *tg_bodyVeil;
@property (nonatomic, strong) UILabel *tg_emptyCaption;
@property (nonatomic, strong) UIScrollView *tg_scrollPane;
@property (nonatomic, strong) UIView *tg_cardSection;
@property (nonatomic, strong) UIImageView *tg_cardTopBg;
@property (nonatomic, strong) UIImageView *tg_cardBottomCap;
@property (nonatomic, strong) UILabel *tg_nameCaption;
@property (nonatomic, strong) UILabel *tg_accountCaption;
@property (nonatomic, strong) UILabel *tg_ifscCaption;
@property (nonatomic, strong) UIButton *tg_editLatch;
@property (nonatomic, strong) UIView *tg_noticeBox;
@property (nonatomic, strong) TgBankCardInfo *tg_cardSnapshot;
@property (nonatomic, strong) TgUserInfoData *tg_userSnapshot;
@property (nonatomic, assign) BOOL tg_canModify;

@end

@implementation TgBankVaultController

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
    [self tg_setCardSectionHidden:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self tg_loadBankCardAndUserInfo];
}

#pragma mark - Layout

- (void)tg_buildLayout {
    self.tg_bodyVeil = [[UIView alloc] init];
    self.tg_bodyVeil.backgroundColor = [UIColor tg_toneFromHex:kTgBankBodyToneHex];
    [self.view insertSubview:self.tg_bodyVeil atIndex:1];

    self.tg_scrollPane = [[UIScrollView alloc] init];
    self.tg_scrollPane.showsVerticalScrollIndicator = NO;
    self.tg_scrollPane.alwaysBounceVertical = YES;
    self.tg_scrollPane.backgroundColor = UIColor.clearColor;
    [self.view addSubview:self.tg_scrollPane];

    self.tg_emptyCaption = [[UILabel alloc] init];
    self.tg_emptyCaption.text = kTgBankEmptyText;
    self.tg_emptyCaption.font = [UIFont tg_meshGlyphWithSize:15 weight:UIFontWeightRegular];
    self.tg_emptyCaption.textColor = [UIColor tg_toneFromHex:kTgBankEmptyToneHex];
    self.tg_emptyCaption.textAlignment = NSTextAlignmentCenter;
    self.tg_emptyCaption.hidden = YES;
    [self.view addSubview:self.tg_emptyCaption];

    self.tg_cardSection = [[UIView alloc] init];
    self.tg_cardSection.backgroundColor = UIColor.clearColor;
    self.tg_cardSection.clipsToBounds = NO;
    [self.tg_scrollPane addSubview:self.tg_cardSection];

    self.tg_cardTopBg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"use_bg_bank"]];
    self.tg_cardTopBg.contentMode = UIViewContentModeScaleToFill;
    self.tg_cardTopBg.clipsToBounds = YES;
    self.tg_cardTopBg.userInteractionEnabled = YES;
    [self.tg_cardSection addSubview:self.tg_cardTopBg];

    self.tg_nameCaption = [[UILabel alloc] init];
    self.tg_nameCaption.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    self.tg_nameCaption.textColor = UIColor.blackColor;
    self.tg_nameCaption.numberOfLines = 2;
    [self.tg_cardTopBg addSubview:self.tg_nameCaption];

    self.tg_accountCaption = [[UILabel alloc] init];
    self.tg_accountCaption.font = [UIFont tg_meshGlyphWithSize:22 weight:UIFontWeightBold];
    self.tg_accountCaption.textColor = UIColor.blackColor;
    self.tg_accountCaption.adjustsFontSizeToFitWidth = YES;
    self.tg_accountCaption.minimumScaleFactor = 0.7;
    [self.tg_cardTopBg addSubview:self.tg_accountCaption];

    self.tg_ifscCaption = [[UILabel alloc] init];
    self.tg_ifscCaption.font = [UIFont tg_meshGlyphWithSize:13 weight:UIFontWeightRegular];
    self.tg_ifscCaption.textColor = UIColor.blackColor;
    [self.tg_cardTopBg addSubview:self.tg_ifscCaption];

    self.tg_cardBottomCap = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"use_Subtract"]];
    self.tg_cardBottomCap.contentMode = UIViewContentModeScaleToFill;
    self.tg_cardBottomCap.userInteractionEnabled = YES;
    [self.tg_cardSection addSubview:self.tg_cardBottomCap];

    self.tg_editLatch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.tg_editLatch setImage:[UIImage imageNamed:@"use_edit"] forState:UIControlStateNormal];
    [self.tg_editLatch addTarget:self action:@selector(tg_onEditTap) forControlEvents:UIControlEventTouchUpInside];
    [self.tg_cardBottomCap addSubview:self.tg_editLatch];

    UITapGestureRecognizer *cardTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tg_onCardTap)];
    [self.tg_cardSection addGestureRecognizer:cardTap];

    self.tg_noticeBox = [[UIView alloc] init];
    self.tg_noticeBox.backgroundColor = [UIColor tg_toneFromHex:kTgBankNoticeBgHex];
    self.tg_noticeBox.layer.cornerRadius = 12;
    self.tg_noticeBox.clipsToBounds = YES;
    [self.tg_scrollPane addSubview:self.tg_noticeBox];

    UILabel *notice = [[UILabel alloc] init];
    notice.text = kTgBankNoticeText;
    notice.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightRegular];
    notice.textColor = [UIColor tg_toneFromHex:kTgBankNoticeTextHex];
    notice.numberOfLines = 0;
    [self.tg_noticeBox addSubview:notice];

    UIImage *topImg = [UIImage imageNamed:@"use_bg_bank"];
    UIImage *capImg = [UIImage imageNamed:@"use_Subtract"];
    CGFloat topRatio = (topImg.size.width > 0) ? (topImg.size.height / topImg.size.width) : 0.55;
    CGFloat capRatio = (capImg.size.width > 0) ? (capImg.size.height / capImg.size.width) : 0.18;

    [self.tg_bodyVeil mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset([self tg_contentTopBelowNavigation]);
    }];
    [self.tg_emptyCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.tg_bodyVeil);
        make.left.greaterThanOrEqualTo(self.tg_bodyVeil).offset(kTgBankHorzInset);
        make.right.lessThanOrEqualTo(self.tg_bodyVeil).offset(-kTgBankHorzInset);
    }];
    [self.tg_scrollPane mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_bodyVeil);
    }];
    [self.tg_cardSection mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_scrollPane).offset(kTgBankCardTopInset);
        make.left.equalTo(self.tg_scrollPane).offset(kTgBankHorzInset);
        make.width.equalTo(self.tg_scrollPane).offset(-kTgBankHorzInset * 2);
    }];
    [self.tg_cardTopBg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.tg_cardSection);
        make.height.equalTo(self.tg_cardTopBg.mas_width).multipliedBy(topRatio);
    }];
    [self.tg_cardBottomCap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.tg_cardSection);
        make.top.equalTo(self.tg_cardTopBg.mas_bottom).offset(-kTgBankCardOverlap);
        make.height.equalTo(self.tg_cardBottomCap.mas_width).multipliedBy(capRatio);
        make.bottom.equalTo(self.tg_cardSection);
    }];
    [self.tg_nameCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_cardTopBg).offset(20);
        make.left.equalTo(self.tg_cardTopBg).offset(20);
        make.right.lessThanOrEqualTo(self.tg_cardTopBg).offset(-72);
    }];
    [self.tg_accountCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_nameCaption);
        make.right.equalTo(self.tg_cardTopBg).offset(-20);
        make.centerY.equalTo(self.tg_cardTopBg).offset(-6);
    }];
    [self.tg_ifscCaption mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tg_nameCaption);
        make.bottom.equalTo(self.tg_cardTopBg).offset(-38);
        make.right.lessThanOrEqualTo(self.tg_cardTopBg).offset(-20);
    }];
    [self.tg_editLatch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.tg_cardBottomCap);
        make.width.height.mas_equalTo(44);
    }];
    [self.tg_noticeBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tg_cardSection.mas_bottom).offset(20);
        make.left.right.equalTo(self.tg_cardSection);
        make.bottom.equalTo(self.tg_scrollPane).offset(-24);
    }];
    [notice mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tg_noticeBox).insets(UIEdgeInsetsMake(14, 14, 14, 14));
    }];
}

- (void)tg_setCardSectionHidden:(BOOL)hidden {
    self.tg_cardSection.hidden = hidden;
    self.tg_noticeBox.hidden = hidden;
}

#pragma mark - Data

- (void)tg_loadBankCardAndUserInfo {
    [[TgPulseOverlay shared] veilSpin];
    dispatch_group_t group = dispatch_group_create();
    __block TgUserInfoData *fetchedUser = nil;
    __block TgBankCardInfo *fetchedCard = nil;

    dispatch_group_enter(group);
    [[TgWireConduit shared] relayPOST:TgLaneUserInfo
                             signData:@{}
                           nonSignData:@{}
                              success:^(id _Nullable data) {
        fetchedUser = [TgUserInfoData yy_modelWithJSON:data];
        dispatch_group_leave(group);
    } failure:^{
        dispatch_group_leave(group);
    }];

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

    __weak typeof(self) weakSelf = self;
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        [[TgPulseOverlay shared] veilDismiss];
        if (!self) return;
        self.tg_userSnapshot = fetchedUser;
        self.tg_cardSnapshot = fetchedCard;
        self.tg_canModify = [fetchedUser.can isEqualToString:@"on"];
        [self tg_refreshCardUI];
    });
}

- (void)tg_refreshCardUI {
    if (!self.tg_cardSnapshot) {
        self.tg_emptyCaption.hidden = NO;
        [self tg_setCardSectionHidden:YES];
        return;
    }
    self.tg_emptyCaption.hidden = YES;
    TgBankCardInfo *info = self.tg_cardSnapshot;

    NSString *holder = info.first.length > 0 ? info.first : nil;
    if (!holder.length && self.tg_userSnapshot.matter.length > 0) {
        holder = self.tg_userSnapshot.matter;
    }
    self.tg_nameCaption.text = holder.length > 0 ? holder : @"--";

    NSString *account = info.measure.length > 0 ? [self tg_formatAccountNo:info.measure] : @"--";
    self.tg_accountCaption.text = account;

    NSString *ifsc = info.procedure.length > 0 ? info.procedure : info.xRay;
    self.tg_ifscCaption.text = ifsc.length > 0 ? ifsc : @"--";

    self.tg_editLatch.hidden = !self.tg_canModify;
    [self tg_setCardSectionHidden:NO];
}

- (NSString *)tg_formatAccountNo:(NSString *)raw {
    NSString *digits = [NSString tg_digitsOnlyFromMixed:raw];
    if (digits.length == 0) return raw;
    NSMutableString *out = [NSMutableString string];
    for (NSUInteger i = 0; i < digits.length; i++) {
        if (i > 0 && i % 4 == 0) [out appendString:@" "];
        [out appendFormat:@"%C", [digits characterAtIndex:i]];
    }
    return out;
}

#pragma mark - Actions

- (void)tg_onCardTap {
    if (!self.tg_canModify) return;
    [self tg_openEditPage];
}

- (void)tg_onEditTap {
    if (!self.tg_canModify) return;
    [self tg_openEditPage];
}

- (void)tg_openEditPage {
    TgBankEditVaultController *edit = [[TgBankEditVaultController alloc] init];
    edit.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:edit animated:YES];
}

@end
