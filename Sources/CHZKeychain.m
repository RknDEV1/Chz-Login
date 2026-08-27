#import "CHZKeychain.h"
#import <Security/Security.h>

static NSString * const CHZKeychainService = @"com.chzpriv.login";
static NSString * const CHZKeychainAccount = @"validated_key";

@implementation CHZKeychain

+ (NSMutableDictionary *)baseQuery {
    return [@{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: CHZKeychainService,
        (__bridge id)kSecAttrAccount: CHZKeychainAccount
    } mutableCopy];
}

+ (BOOL)saveKey:(NSString *)key error:(NSError **)error {
    if (key.length == 0) {
        if (error) *error = [NSError errorWithDomain:@"CHZKeychain" code:1 userInfo:@{NSLocalizedDescriptionKey: @"A key está vazia."}];
        return NO;
    }

    [self deleteKey:nil];
    NSMutableDictionary *query = [self baseQuery];
    query[(__bridge id)kSecValueData] = [key dataUsingEncoding:NSUTF8StringEncoding];
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    if (status != errSecSuccess && error) {
        *error = [NSError errorWithDomain:@"CHZKeychain" code:status userInfo:nil];
    }
    return status == errSecSuccess;
}

+ (NSString *)loadKey:(NSError **)error {
    NSMutableDictionary *query = [self baseQuery];
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status == errSecItemNotFound) return nil;
    if (status != errSecSuccess) {
        if (error) *error = [NSError errorWithDomain:@"CHZKeychain" code:status userInfo:nil];
        return nil;
    }

    NSData *data = CFBridgingRelease(result);
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (BOOL)deleteKey:(NSError **)error {
    NSDictionary *query = [self baseQuery];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    if (status != errSecSuccess && status != errSecItemNotFound && error) {
        *error = [NSError errorWithDomain:@"CHZKeychain" code:status userInfo:nil];
    }
    return status == errSecSuccess || status == errSecItemNotFound;
}

@end
