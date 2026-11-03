//
//  TgVersionPayload.h
//

#import "TgEnvelopeBase.h"

NS_ASSUME_NONNULL_BEGIN

@interface TgVersionData : NSObject <YYModel>
@property (nonatomic, copy, nullable) NSString *noticeable;  ///< latestVersion
@property (nonatomic, copy, nullable) NSString *contrast;   ///< latestVersionUrl
@property (nonatomic, copy, nullable) NSString *headache;  ///< latestVersionContent
@property (nonatomic, copy, nullable) NSString *updateType;
@end

@interface TgVersionResponse : TgEnvelopeBase
@property (nonatomic, strong, nullable) TgVersionData *versionData;
@end

NS_ASSUME_NONNULL_END
