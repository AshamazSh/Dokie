//
//  EncryptionManager.h
//  Dokie
//
//  Created by Ashamaz Shidov on 24/02/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface EncryptionManager : NSObject

@property (nonatomic, readonly) BOOL isValid;

+ (BOOL)contextHasKey:(NSManagedObjectContext *)context;

- (instancetype)initWithPassword:(NSString *)password objectContext:(NSManagedObjectContext *)context;

- (BOOL)changeToNewPassword:(NSString *)newPassword;
- (BOOL)checkPassword:(NSString *)password;

- (NSData *)encryptedData:(NSData *)data;
- (NSData *)decryptedData:(NSData *)data;

- (NSDictionary<NSString *, id> *)decryptedJsonFromData:(NSData *)data parsingError:(NSError *__autoreleasing *)error;
- (NSData *)encryptedJsonFromDictionary:(NSDictionary *)json parsingError:(NSError *__autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
