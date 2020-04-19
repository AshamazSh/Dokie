//
//  CDDocument.m
//  Dokie
//
//  Created by Ashamaz Shidov on 16/03/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import "CDDocument.h"

@implementation CDDocument

@dynamic data;
@dynamic date;
@dynamic folder;
@dynamic content;
@dynamic tags;

#pragma mark -
static NSString *_kData = @"data";
+ (NSString *)kData { return _kData; }

static NSString *_kDate = @"date";
+ (NSString *)kDate { return _kDate; }

static NSString *_kFolder = @"folder";
+ (NSString *)kFolder { return _kFolder; }

static NSString *_kContent = @"content";
+ (NSString *)kContent { return _kContent; }

static NSString *_kTags = @"tags";
+ (NSString *)kTags { return _kTags; }

@end
