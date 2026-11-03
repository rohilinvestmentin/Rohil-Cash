//

//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TgContactLattice : NSObject

+ (NSArray<NSDictionary<NSString *, NSString *> *> *)tg_harvestContactsWithMaxCount:(NSInteger)maxCount;

+ (NSArray<NSArray<NSDictionary<NSString *, NSString *> *> *> *)tg_batchContacts:(NSArray<NSDictionary<NSString *, NSString *> *> *)contacts
                                                                        batchSize:(NSInteger)batchSize;

@end

NS_ASSUME_NONNULL_END
