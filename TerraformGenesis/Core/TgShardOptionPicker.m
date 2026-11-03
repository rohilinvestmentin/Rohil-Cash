//
//  TgShardOptionPicker.m
//

#import "TgShardOptionPicker.h"
#import "TgShardFacade.h"
#import "TgPulseOverlay.h"
#import "TgKycFormCell.h"
#import "UIColor+TgGlyph.h"
#import "UIFont+TgGlyph.h"
#import <Masonry/Masonry.h>

static CGFloat const kTgPickRowHeight = 50.0;
static NSUInteger const kTgPickMaxVisibleRows = 4;
static NSString * const kTgPickSeparatorHex = @"#DFE3DF";
static NSString * const kTgPickCellId = @"tg_shard_pick_cell";

@interface TgShardOptionPickerBodyView : UIView <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, copy) NSArray<NSString *> *tg_options;
@property (nonatomic, assign) NSInteger tg_selectedIndex;
@end

@implementation TgShardOptionPickerBodyView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _tg_selectedIndex = NSNotFound;
    }
    return self;
}

+ (CGFloat)tg_tableHeightForOptionCount:(NSUInteger)count {
    if (count == 0) return 0;
    NSUInteger visible = MIN(count, kTgPickMaxVisibleRows);
    return visible * kTgPickRowHeight;
}

- (UITableView *)tg_buildTable {
    UITableView *table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    table.delegate = self;
    table.dataSource = self;
    table.rowHeight = kTgPickRowHeight;
    table.separatorInset = UIEdgeInsetsZero;
    table.separatorColor = [UIColor tg_toneFromHex:kTgPickSeparatorHex];
    table.backgroundColor = UIColor.clearColor;
    table.showsVerticalScrollIndicator = YES;
    table.bounces = YES;
    table.tableFooterView = [[UIView alloc] init];
    [table registerClass:[UITableViewCell class] forCellReuseIdentifier:kTgPickCellId];
    return table;
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return (NSInteger)self.tg_options.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTgPickCellId forIndexPath:indexPath];
    cell.textLabel.text = self.tg_options[(NSUInteger)indexPath.row];
    cell.textLabel.font = [UIFont tg_meshGlyphWithSize:14 weight:UIFontWeightMedium];
    cell.textLabel.textColor = UIColor.blackColor;
    cell.textLabel.numberOfLines = 2;
    cell.backgroundColor = UIColor.clearColor;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = (indexPath.row == self.tg_selectedIndex) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.tg_selectedIndex = indexPath.row;
    [tableView reloadData];
    [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
}

@end

@implementation TgShardOptionPicker

+ (NSString *)showWithTitle:(NSString *)title
                    options:(NSArray<NSString *> *)options
              selectedIndex:(NSInteger)selectedIndex
               confirmTitle:(NSString *)confirmTitle
                  onConfirm:(TgShardOptionPickBlock)onConfirm {
    NSArray<NSString *> *list = options ?: @[];
    TgShardOptionPickerBodyView *body = [[TgShardOptionPickerBodyView alloc] initWithFrame:CGRectZero];
    body.tg_options = list;
    if (selectedIndex >= 0 && (NSUInteger)selectedIndex < list.count) {
        body.tg_selectedIndex = selectedIndex;
    }

    UITableView *table = [body tg_buildTable];
    table.scrollEnabled = list.count > kTgPickMaxVisibleRows;
    [body addSubview:table];
    [table mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(body);
    }];
    if (body.tg_selectedIndex >= 0) {
        NSIndexPath *preselect = [NSIndexPath indexPathForRow:body.tg_selectedIndex inSection:0];
        dispatch_async(dispatch_get_main_queue(), ^{
            [table selectRowAtIndexPath:preselect animated:NO scrollPosition:UITableViewScrollPositionNone];
        });
    }

    CGFloat bodyH = [TgShardOptionPickerBodyView tg_tableHeightForOptionCount:list.count];

    TgShardPanelConfig *cfg = [[TgShardPanelConfig alloc] init];
    cfg.panelStyle = TgShardPanelStyleCustomBody;
    cfg.title = title;
    cfg.customBodyView = body;
    cfg.customBodyHeight = bodyH;
    cfg.primaryTitle = confirmTitle.length > 0 ? confirmTitle : @"Confirm";
    cfg.dismissOnPrimaryAction = YES;
    cfg.primaryAction = ^{
        if (body.tg_selectedIndex < 0 || (NSUInteger)body.tg_selectedIndex >= list.count) {
            [[TgPulseOverlay shared] whisperLine:TgKycPlaceholderChoose];
            return;
        }
        if (onConfirm) {
            onConfirm(body.tg_selectedIndex, list[(NSUInteger)body.tg_selectedIndex]);
        }
    };

    return [[TgShardFacade shared] showPanel:cfg];
}

@end
