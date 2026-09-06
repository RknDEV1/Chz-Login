#import "CHZKeychain.h"
#import <Security/Security.h>

static NSString * const CHZKeychainService = @"com.chzpriv.login";
static NSString * const CHZKeychainAccount = @"validated_key";
static NSString * const CHZKeychainSessionAccount = @"validated_session_v1";
static NSString * const CHZLocalSessionMarker = @"com.chzpriv.login.session_available";

@interface CHZKeychain ()
+ (NSMutableDictionary *)queryForAccount:(NSString *)account;
@end

@implementation CHZKeychain

+ (NSMutableDictionary *)baseQuery {
    return [self queryForAccount:CHZKeychainAccount];
}

+ (NSMutableDictionary *)queryForAccount:(NSString *)account {
    return [@{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: CHZKeychainService,
        (__bridge id)kSecAttrAccount: account
    } mutableCopy];
}

+ (BOOL)saveKey:(NSString *)key error:(NSError **)error {
    if (key.length == 0) {
        if (error) *error = [NSError errorWithDomain:@"CHZKeychain" code:1 userInfo:@{NSLocalizedDescriptionKey: @"A key está vazia."}];
        return NO;
    }

    NSData *valueData = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *query = [self baseQuery];
    query[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlock;
    query[(__bridge id)kSecValueData] = valueData;

    // Atualiza a key existente; se ainda não existir, cria um novo item.
    NSDictionary *update = @{(__bridge id)kSecValueData: valueData};
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)[self baseQuery],
                                    (__bridge CFDictionaryRef)update);
    if (status == errSecItemNotFound) {
        status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    }
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
        if (error) *error = [NSError errorWithDomain:@"CHZKeychain" code:status userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Keychain load failed (%d)", (int)status]}];
        return nil;
    }

    NSData *data = CFBridgingRelease(result);
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (BOOL)saveSessionForKey:(NSString *)key expiry:(NSString *)expiry error:(NSError **)error {
    if (![key isKindOfClass:[NSString class]] || key.length == 0) {
        if (error) *error = [NSError errorWithDomain:@"CHZKeychain" code:1 userInfo:@{NSLocalizedDescriptionKey: @"A key está vazia."}];
        return NO;
    }

    NSDictionary *session = @{
        @"key": key,
        @"expiry": [expiry isKindOfClass:[NSString class]] ? expiry : @""
    };
    NSError *jsonError = nil;
    NSData *valueData = [NSJSONSerialization dataWithJSONObject:session options:0 error:&jsonError];
    if (!valueData) {
        if (error) *error = jsonError;
        return NO;
    }

    NSMutableDictionary *query = [self queryForAccount:CHZKeychainSessionAccount];
    query[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlock;
    query[(__bridge id)kSecValueData] = valueData;
    NSDictionary *update = @{(__bridge id)kSecValueData: valueData};
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)[self queryForAccount:CHZKeychainSessionAccount], (__bridge CFDictionaryRef)update);
    if (status == errSecItemNotFound) {
        status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    }
    if (status == errSecSuccess) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:CHZLocalSessionMarker];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else if (error) {
        *error = [NSError errorWithDomain:@"CHZKeychain" code:status userInfo:nil];
    }
    return status == errSecSuccess;
}

+ (NSDictionary *)loadSession:(NSError **)error {
    NSMutableDictionary *query = [self queryForAccount:CHZKeychainSessionAccount];
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
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    return [object isKindOfClass:[NSDictionary class]] ? object : nil;
}

+ (BOOL)deleteKey:(NSError **)error {
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)[self baseQuery]);
    OSStatus sessionStatus = SecItemDelete((__bridge CFDictionaryRef)[self queryForAccount:CHZKeychainSessionAccount]);
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CHZLocalSessionMarker];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (status == errSecItemNotFound) status = errSecSuccess;
    if (sessionStatus != errSecSuccess && sessionStatus != errSecItemNotFound) status = sessionStatus;
    if (status != errSecSuccess && status != errSecItemNotFound && error) {
        *error = [NSError errorWithDomain:@"CHZKeychain" code:status userInfo:nil];
    }
    return status == errSecSuccess || status == errSecItemNotFound;
}

@end
