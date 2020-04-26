//
//  LocalAuth.m
//  Dokie
//
//  Created by Ashamaz Shidov on 26.04.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import "LocalAuth.h"
#import "Logger.h"
#import "Constants.h"
#import "NavigationRouter.h"

#import <LocalAuthentication/LocalAuthentication.h>

@interface LocalAuth()

@property (nonatomic) BOOL touchIdAvailable;
@property (nonatomic) BOOL faceIdAvailable;

@property (nonatomic, strong, readonly) NSString *keychainServiceName;
@property (nonatomic, strong, readonly) NSString *keychainLocalDBPasswordKey;
@property (nonatomic, strong, readonly) NavigationRouter *navigationRouter;
@property (nonatomic, strong, readonly) NSUserDefaults *userDefaults;

@end

@implementation LocalAuth

+ (instancetype)shared {
    static id sharedObject = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedObject = [LocalAuth new];
    });
    return sharedObject;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.touchIdAvailable = NO;
    self.faceIdAvailable = NO;

    LAContext *context = [LAContext new];
    NSError *error;
    BOOL biometricsAvailable = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    if (error) {
        WriteLog(kLogTypeDebug, @"Biometrics error: %@", error.localizedDescription);
        [self resetStoredPassword];
    }
    else if (biometricsAvailable) {
        [self updateBiometricsAvailability];
    }
    else {
        [self resetStoredPassword];
    }
}

- (void)updateBiometricsAvailability {
    LAContext *context = [LAContext new];
    NSString *localPassword = [self localDatabasePassword];
    self.touchIdAvailable = context.biometryType == LABiometryTypeTouchID && localPassword != nil;
    self.faceIdAvailable = context.biometryType == LABiometryTypeFaceID && localPassword != nil;
}

- (NSDictionary *)keychainRequestDictionaryForKey:(NSString *)key {
    if (!key) {
        return nil;
    }
    NSData *encodedKey = [key dataUsingEncoding:NSUTF8StringEncoding];
    return @{(id)kSecAttrService            :   self.keychainServiceName,
             (id)kSecClass                  :   (id)kSecClassGenericPassword,
             (id)kSecAttrAccount            :   encodedKey,
             (id)kSecReturnData             :   (id)kCFBooleanTrue,
             (id)kSecAttrAccessible         :   (id)kSecAttrAccessibleWhenUnlocked
             };
}

- (NSDictionary *)keychainUpdateRequestDictionaryForKey:(NSString *)key {
    if (!key) {
        return nil;
    }
    
    NSData *encodedKey = [key dataUsingEncoding:NSUTF8StringEncoding];
    return @{(id)kSecAttrService            :   self.keychainServiceName,
             (id)kSecClass                  :   (id)kSecClassGenericPassword,
             (id)kSecAttrAccount            :   encodedKey
             };
}

- (void)resetStoredPassword {
    @try {
        NSMutableDictionary *query = [[self keychainRequestDictionaryForKey:self.keychainLocalDBPasswordKey] mutableCopy];
        CFTypeRef dataTypeRef = NULL;
        if (SecItemCopyMatching((__bridge CFDictionaryRef)query, &dataTypeRef) == errSecSuccess) {
            OSStatus status = SecItemDelete((CFDictionaryRef)query);
            if (status != errSecSuccess) {
                WriteLog(kLogTypeCrash, @"Can't delete data from keychain.");
            }
        }
        [self updateBiometricsAvailability];
    } @catch (NSException *exception) {
        WriteLog(kLogTypeCrash, @"Can't save data to keychain. Error: %@", exception.reason);
    }
}

- (RACSignal<NSString *> *)databasePassword {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        return [RACScheduler.mainThreadScheduler schedule:^{
            @strongify(self);
            NSError *error = nil;
            LAContext *context = [LAContext new];
            if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
                NSString *reasonText = context.biometryType == LABiometryTypeTouchID ?
                        NSLocalizedString(@"Login with Touch ID", @"Touch ID login question") :
                        NSLocalizedString(@"Login with Face ID", @"Face ID login question");

                [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                             localizedReason:reasonText
                                       reply:^(BOOL success, NSError * _Nullable error) {
                    if (success) {
                        NSString *password = [self localDatabasePassword];
                        if (password) {
                            [subscriber sendNext:[self localDatabasePassword]];
                            [subscriber sendCompleted];
                        }
                        else {
                            [subscriber sendError:[NSError errorWithDomain:DokieErrorDomain code:9999 userInfo:@{}]];
                        }
                    }
                }];
            }
            else {
                [subscriber sendError:error];
            }
        }];
    }];
}

- (NSString *)localDatabasePassword {
    NSDictionary *passwordDict = [self localDatabasePasswordDict];
    return passwordDict[kDBPasswordKey];
}

- (NSDictionary *)localDatabasePasswordDict {
    @try {
        NSMutableDictionary *query = [[self keychainRequestDictionaryForKey:self.keychainLocalDBPasswordKey] mutableCopy];
        query[(id)kSecMatchLimit] = (id)kSecMatchLimitOne;
        CFTypeRef dataTypeRef = NULL;
        OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, &dataTypeRef);
        NSData *result;
        if (dataTypeRef) {
            result = (__bridge NSData *)dataTypeRef;
            CFRelease(dataTypeRef);
        }
        if (status != noErr || result.length == 0) {
            return nil;
        }
        
        NSDictionary *keysDic = [NSKeyedUnarchiver unarchiveObjectWithData:result];
        if ([keysDic isKindOfClass:[NSDictionary class]]) {
            return keysDic;
        }
        WriteLog(kLogTypeCrash, @"Stored valie in keychain is not a dictionary");
        return nil;
    } @catch (NSException *exception) {
        WriteLog(kLogTypeCrash, @"Can't parse data from keychain. Error: %@", exception.reason);
        return nil;
    }
}

- (void)saveDatabasePassword:(NSString *)databasePassword {
    if (!databasePassword) {
        [self resetStoredPassword];
    }
    
    NSMutableDictionary *localDBDic = [[self localDatabasePasswordDict] mutableCopy];
    if (!localDBDic) {
        localDBDic = [NSMutableDictionary dictionary];
    }
    localDBDic[kDBPasswordKey] = databasePassword;
    
    @try {
        NSData *toSave = [NSKeyedArchiver archivedDataWithRootObject:[localDBDic copy]];
        NSMutableDictionary *query = [[self keychainRequestDictionaryForKey:self.keychainLocalDBPasswordKey] mutableCopy];
        CFTypeRef dataTypeRef = NULL;
        if (SecItemCopyMatching((__bridge CFDictionaryRef)query, &dataTypeRef) == errSecSuccess) {
            OSStatus status = SecItemUpdate((CFDictionaryRef)[self keychainUpdateRequestDictionaryForKey:self.keychainLocalDBPasswordKey], (CFDictionaryRef)@{(id)kSecValueData : toSave});
            if (status != errSecSuccess) {
                WriteLog(kLogTypeCrash, @"Can't save data to keychain.");
            }
        }
        else {
            query[(id)kSecValueData] = toSave;
            OSStatus status = SecItemAdd((CFDictionaryRef)query, nil);
            if (status != errSecSuccess) {
                WriteLog(kLogTypeCrash, @"Can't save data to keychain.");
            }
        }
        [self updateBiometricsAvailability];
    } @catch (NSException *exception) {
        WriteLog(kLogTypeCrash, @"Can't save data to keychain. Error: %@", exception.reason);
    }
}

- (void)validPasswordEntered:(NSString *)databasePassword {
    NSError *error;
    LAContext *context = [LAContext new];
    BOOL biometricsAvailable = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    if (![[self localDatabasePassword] isEqual:databasePassword] && biometricsAvailable && ![self.userDefaults boolForKey:kDoNotSuggestPasswordSaveKey]) {
        NSString *alertTitle = context.biometryType == LABiometryTypeTouchID ?
        NSLocalizedString(@"Do you want to use Touch ID to login in future?", @"Touch ID assign question") :
        NSLocalizedString(@"Do you want to use Face ID to login in future?", @"Face ID assign question");
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleAlert];

        @weakify(self);
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"Yes button text in alert view") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            [self saveDatabasePassword:databasePassword];
        }];
        [alert addAction:yesAction];
        
        UIAlertAction *noStopAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No (Do not ask again)", @"Do not ask button text in alert view") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            [self.userDefaults setBool:YES forKey:kDoNotSuggestPasswordSaveKey];
        }];
        [alert addAction:noStopAction];

        UIAlertAction *noAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"No button text in alert view") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            [self resetStoredPassword];
        }];
        [alert addAction:noAction];
        [self.navigationRouter showAlert:alert];
    }
}

#pragma mark -

- (NSString *)keychainServiceName {
    return @"com.ashamazsh.Dokie.keychain";
}

- (NSString *)keychainLocalDBPasswordKey {
    return @"com.ashamazsh.Dokie.localDBPassword";
}

- (NavigationRouter *)navigationRouter {
    return [NavigationRouter shared];
}

- (NSUserDefaults *)userDefaults {
    return [NSUserDefaults standardUserDefaults];
}

@end
