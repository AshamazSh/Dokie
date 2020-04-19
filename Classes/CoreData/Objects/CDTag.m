//
//  CDTag.m
//  Dokie
//
//  Created by Ashamaz Shidov on 26/12/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import "CDTag.h"

@implementation CDTag

@dynamic text;
@dynamic document;

#pragma mark -
static NSString *_kText = @"text";
+ (NSString *)kText { return _kText; }

static NSString *_kDocument = @"document";
+ (NSString *)kDocument { return _kDocument; }

@end
