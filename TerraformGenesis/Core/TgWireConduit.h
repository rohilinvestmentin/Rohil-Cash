//

//

#import <Foundation/Foundation.h>

@class TgEnvelopeBase;

NS_ASSUME_NONNULL_BEGIN

typedef void (^TgWireSuccessBlock)(id _Nullable data);
typedef void (^TgWireEnvelopeSuccessBlock)(TgEnvelopeBase *envelope);
typedef void (^TgWireFailureBlock)(void);
typedef void (^TgWireProgressBlock)(double progress);

@interface TgWireConduit : NSObject

+ (instancetype)shared;

+ (void)bootNetworkLayer:(void (^)(BOOL ok))completion;

- (void)relayPOST:(NSString *)path
         signData:(nullable NSDictionary *)signData
       nonSignData:(nullable NSDictionary *)nonSignData
           success:(TgWireSuccessBlock)success
           failure:(TgWireFailureBlock)failure;

- (void)relayPOST:(NSString *)path
         signData:(nullable NSDictionary *)signData
       nonSignData:(nullable NSDictionary *)nonSignData
  envelopeSuccess:(TgWireEnvelopeSuccessBlock)envelopeSuccess
          failure:(TgWireFailureBlock)failure;

- (void)relayUpload:(NSString *)path
           signData:(nullable NSDictionary *)signData
         nonSignData:(nullable NSDictionary *)nonSignData
           fileData:(NSData *)fileData
           fileName:(NSString *)fileName
           mimeType:(NSString *)mimeType
           progress:(nullable TgWireProgressBlock)progress
            success:(TgWireSuccessBlock)success
            failure:(TgWireFailureBlock)failure;

- (BOOL)tg_shouldSuppressBusyToast;

/// YES while force-update is being fetched or shown; callers should stop further business flows.
- (BOOL)tg_isForceUpdateBlocking;

@end

NS_ASSUME_NONNULL_END
