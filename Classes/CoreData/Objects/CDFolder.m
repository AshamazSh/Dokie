//
//  CDFolder.m
//  Dokie
//
//  Created by Ashamaz Shidov on 16/03/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import "CDFolder.h"

@implementation CDFolder

@dynamic data;
@dynamic date;
@dynamic documents;
@dynamic parentFolder;
@dynamic subfolders;

#pragma mark -
static NSString *_kData = @"data";
+ (NSString *)kData { return _kData; }

static NSString *_kDate = @"date";
+ (NSString *)kDate { return _kDate; }

static NSString *_kDocuments = @"documents";
+ (NSString *)kDocuments { return _kDocuments; }

static NSString *_kParentFolder = @"parentFolder";
+ (NSString *)kParentFolder { return _kParentFolder; }

static NSString *_kSubfolders = @"subfolders";
+ (NSString *)kSubfolders { return _kSubfolders; }

@end
