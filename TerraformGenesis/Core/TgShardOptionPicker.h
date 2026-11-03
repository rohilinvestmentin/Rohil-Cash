//

//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^TgShardOptionPickBlock)(NSInteger index, NSString *value);

@interface TgShardOptionPicker : NSObject

+ (NSString *)showWithTitle:(nullable NSString *)title
                    options:(NSArray<NSString *> *)options
              selectedIndex:(NSInteger)selectedIndex
               confirmTitle:(nullable NSString *)confirmTitle
                  onConfirm:(TgShardOptionPickBlock)onConfirm;

@end

NS_ASSUME_NONNULL_END
