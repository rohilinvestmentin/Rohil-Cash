//

//

#import <Foundation/Foundation.h>
#import <YYModel/YYModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface TgEnvelopeBase : NSObject <YYModel>

@property (nonatomic, assign) NSInteger cheer;      ///< resultCode
@property (nonatomic, copy) NSString *power;      ///< resultMsg
@property (nonatomic, strong, nullable) id trick; ///< data
@property (nonatomic, assign) long long radiation; ///< timestamp

- (BOOL)isSuccess;

@end

NS_ASSUME_NONNULL_END
