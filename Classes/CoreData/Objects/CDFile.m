//
//  CDFile.m
//  Dokie
//
//  Created by Ashamaz Shidov on 18/01/2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import "CDFile.h"

@implementation CDFile

@dynamic identifier;
@dynamic data;

#pragma mark -
static NSString *_kIdentifier = @"identifier";
+ (NSString *)kIdentifier { return _kIdentifier; }

static NSString *_kData = @"data";
+ (NSString *)kData { return _kData; }

@end
