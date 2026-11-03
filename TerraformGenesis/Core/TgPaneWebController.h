//

//

#import "TgHullController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TgPaneWebController : TgHullController

@property (nonatomic, assign) BOOL tg_followsDocumentTitle;

- (instancetype)initWithPageURL:(NSURL *)pageURL navTitle:(nullable NSString *)title;
- (instancetype)initWithPageURLString:(NSString *)urlString navTitle:(nullable NSString *)title;

+ (nullable NSURL *)tg_normalizedURLFromString:(NSString *)urlString;

@end

NS_ASSUME_NONNULL_END
