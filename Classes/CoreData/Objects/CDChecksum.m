//
//  CDChecksum.m
//  Dokie
//
//  Created by Ashamaz Shidov on 18/03/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import "CDChecksum.h"

@implementation CDChecksum

@dynamic encryptedKey;
@dynamic checksum;
@dynamic salt;

#pragma mark -
static NSString *_kEncryptedKey = @"encryptedKey";
+ (NSString *)kEncryptedKey { return _kEncryptedKey; }

static NSString *_kChecksum = @"checksum";
+ (NSString *)kChecksum { return _kChecksum; }

static NSString *_kSalt = @"salt";
+ (NSString *)kSalt { return _kSalt; }

@end
