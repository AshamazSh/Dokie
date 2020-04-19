//
//  CDContent.m
//  Dokie
//
//  Created by Ashamaz Shidov on 18/03/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import "CDContent.h"

@implementation CDContent

@dynamic data;
@dynamic document;

#pragma mark -
static NSString *_kData = @"data";
+ (NSString *)kData { return _kData; }

static NSString *_kDocument = @"document";
+ (NSString *)kDocument { return _kDocument; }

@end
