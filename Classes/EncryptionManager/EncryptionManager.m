//
//  EncryptionManager.m
//  Dokie
//
//  Created by Ashamaz Shidov on 24/02/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import "EncryptionManager.h"
#import <CommonCrypto/CommonCryptor.h>
#import "Logger.h"
#import "CoreDataInclude.h"

#import <CommonCrypto/CommonCrypto.h>
#import <CoreData/CoreData.h>

@interface EncryptionManager ()

@property (nonatomic) BOOL isValid;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation EncryptionManager

+ (BOOL)contextHasKey:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest new];
    [request setEntity:CDChecksum.entity];
    [request setReturnsObjectsAsFaults:YES];
    
    NSError *error;
    NSArray *sums = [context executeFetchRequest:request error:&error];
    return sums.count > 0;
}

- (instancetype)initWithPassword:(NSString *)password objectContext:(NSManagedObjectContext *)context {
    ParameterAssert(password);
    ParameterAssert(context);
    
    self = [super init];
    if (self) {
        self.password = password;
        self.context = context;
        [self setup];
    }
    return self;
}

- (CDChecksum *)contextChecksum {
    NSFetchRequest *request = [NSFetchRequest new];
    [request setEntity:CDChecksum.entity];
    [request setReturnsObjectsAsFaults:YES];
    
    NSError *error;
    NSArray *sums = [self.context executeFetchRequest:request error:&error];
    if (error || sums.count != 1) {
        return nil;
    }
    
    return sums.firstObject;
}

- (void)setup {
    if (!self.context || self.password.length == 0) {
        self.isValid = NO;
        return;
    }
    
    CDChecksum *checksum = [self contextChecksum];
    if (!checksum) {
        checksum = [NSEntityDescription insertNewObjectForEntityForName:CDChecksum.entity.name inManagedObjectContext:self.context];
        checksum.salt = [NSUUID UUID].UUIDString;
        checksum.checksum = [self sha1FromString:[self addSalt:checksum.salt toText:self.password]];
        self.key = [[NSUUID UUID].UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@""];
        checksum.encryptedKey = [self encryptedData:[self.key dataUsingEncoding:NSUTF8StringEncoding] usingKey:self.password];
        NSError *error;
        [self.context save:&error];
        if (error) {
            [self.context rollback];
            self.isValid = NO;
            return;
        }
        self.isValid =  YES;
        return;
    }

    if (checksum.salt.length > 0 && checksum.checksum.length > 0) {
        NSString *toCheck = [self addSalt:checksum.salt toText:self.password];
        self.isValid = [[self sha1FromString:toCheck] isEqual:checksum.checksum];
        if (self.isValid) {
            self.key = [[NSString alloc] initWithData:[self decryptedData:checksum.encryptedKey usingKey:self.password] encoding:NSUTF8StringEncoding];
        }
    }
    else {
        self.isValid = NO;
    }
}

- (NSString *)addSalt:(NSString *)salt toText:(NSString *)text {
    ParameterAssert(salt.length > 0);
    ParameterAssert(text.length > 0);
    
    if (salt.length > 0 && text.length > 0) {
        return [NSString stringWithFormat:@"%@%@%@", [salt substringToIndex:salt.length/2], text, [salt substringFromIndex:salt.length/2]];
    }
    return nil;
}

- (BOOL)changeToNewPassword:(NSString *)newPassword {
    if ([self isValid] && newPassword.length > 0) {
        CDChecksum *sum = [self contextChecksum];
        if (sum) {
            sum.salt = [NSUUID UUID].UUIDString;
            sum.checksum = [self sha1FromString:[self addSalt:sum.salt toText:newPassword]];
            sum.encryptedKey = [self encryptedData:[self.key dataUsingEncoding:NSUTF8StringEncoding] usingKey:newPassword];
            NSError *error;
            [self.context save:&error];
            if (error) {
                return NO;
            }
            self.password = newPassword;
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)checkPassword:(NSString *)password {
    CDChecksum *checksum = [self contextChecksum];
    if (!checksum) {
        return NO;
    }

    if (checksum.salt.length > 0 && checksum.checksum.length > 0) {
        NSString *toCheck = [self addSalt:checksum.salt toText:password];
        return [[self sha1FromString:toCheck] isEqual:checksum.checksum];
    }
    
    return NO;
}

- (NSString *)sha1FromString:(NSString *)string {
    ParameterAssert(string);
    
    if (string.length == 0) {
        return nil;
    }
    
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t sha[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, (CC_LONG)data.length, sha);
    
    NSMutableString* hash = [NSMutableString string];
    for(unsigned i = 0; i < sizeof(sha); i++)
    {
        [hash appendFormat:@"%02x", sha[i]];
    }
    
    return [hash copy];
}

- (NSData *)decryptedData:(NSData *)data {
    return [self decryptedData:data usingKey:self.key];
}

- (NSData *)decryptedData:(NSData *)data usingKey:(NSString *)key {
    ParameterAssert(data);
    ParameterAssert(key);
    
    if (key.length == 0 || data.length == 0) {
        return nil;
    }
    
    // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [data length];
    
    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    
    
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES, kCCOptionECBMode | kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES256,
                                          NULL /* initialization vector (optional) */,
                                          [data bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesDecrypted);
    
    if (cryptStatus == kCCSuccess) {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    
    free(buffer);
    return nil;
}

- (NSData *)encryptedData:(NSData *)data {
    return [self encryptedData:data usingKey:self.key];
}

- (NSData *)encryptedData:(NSData *)data usingKey:(NSString *)key {
    ParameterAssert(data);
    ParameterAssert(key);
    
    if (key.length == 0 || data.length == 0) {
        return nil;
    }
    
    // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [data length];
    
    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionECBMode | kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES256,
                                          NULL /* initialization vector (optional) */,
                                          [data bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    
    free(buffer);
    return nil;
}

- (NSDictionary<NSString *, id> *)decryptedJsonFromData:(NSData *)data parsingError:(NSError *__autoreleasing *)error {
    if (!self.isValid) {
        return nil;
    }
    
    NSData *decrypted = [self decryptedData:data];
    
    NSError *currentError;
    NSDictionary<NSString *, id> *json = [NSJSONSerialization JSONObjectWithData:decrypted options:NSJSONReadingAllowFragments error:&currentError];
    if (currentError) {
        if (error) {
            *error = currentError;
        }
        return nil;
    }
    
    return json;
}

- (NSData *)encryptedJsonFromDictionary:(NSDictionary *)json parsingError:(NSError *__autoreleasing *)error {
    if (!self.isValid) {
        return nil;
    }
    
    NSError *currentError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingFragmentsAllowed error:&currentError];
    if (currentError) {
        if (error) {
            *error = currentError;
        }
        return nil;
    }
    
    return [self encryptedData:jsonData];
}

@end
