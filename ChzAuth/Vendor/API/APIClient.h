// APIClient.h — Logos API Authentication / Lite Secure
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface APIClient : NSObject
- (void)paid:(void (^)(void))execute;
- (void)start:(void (^)(void))onStart init:(void (^)(void))init;
- (void)setToken:(NSString *)token;
- (void)setUDID:(NSString *)uid;
- (void)setLanguage:(NSString *)language;
- (void)hideUI:(BOOL)isHide;
- (void)strictMode:(BOOL)isStrictMode;
- (void)silentMode:(BOOL)isSilentMode;
- (id)getPackageDataWithKey:(NSString *)key;
- (NSString *)getKey;
- (NSString *)getExpiryDate;
- (NSString *)getExpiredAt;
- (NSString *)getUDID;
- (NSString *)getDeviceModel;
- (NSString *)getLoginIP;
- (NSString *)getPackageName;
- (void)onCheckPackage:(void (^)(NSDictionary *header))success
            onFailure:(void (^)(NSDictionary *error))failure;
- (void)onCheckDevice:(void (^)(NSDictionary *data))success
            onFailure:(void (^)(NSDictionary *error))failure;
- (void)onLogin:(NSString *)inputKey
      onSuccess:(void (^)(NSDictionary *data))success
      onFailure:(void (^)(NSDictionary *error))failure;
+ (instancetype)sharedAPIClient;
@end

NS_ASSUME_NONNULL_END
