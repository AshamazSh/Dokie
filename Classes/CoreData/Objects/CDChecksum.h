//
//  CDChecksum.h
//  Dokie
//
//  Created by Ashamaz Shidov on 18/03/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface CDChecksum : NSManagedObject

@property (nonatomic, strong) NSData *encryptedKey;
@property (nonatomic, strong) NSString *checksum;
@property (nonatomic, strong) NSString *salt;

#pragma mark -
@property (class, nonatomic, strong, readonly) NSString *kEncryptedKey;
@property (class, nonatomic, strong, readonly) NSString *kChecksum;
@property (class, nonatomic, strong, readonly) NSString *kSalt;

@end

NS_ASSUME_NONNULL_END
