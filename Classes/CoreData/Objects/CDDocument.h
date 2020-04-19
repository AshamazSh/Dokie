//
//  CDDocument.h
//  Dokie
//
//  Created by Ashamaz Shidov on 16/03/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@class CDFolder;

@interface CDDocument : NSManagedObject

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) CDFolder *folder;
@property (nonatomic, strong) NSOrderedSet *content;
@property (nonatomic, strong) NSOrderedSet *tags;

#pragma mark -
@property (class, nonatomic, strong, readonly) NSString *kData;
@property (class, nonatomic, strong, readonly) NSString *kDate;
@property (class, nonatomic, strong, readonly) NSString *kFolder;
@property (class, nonatomic, strong, readonly) NSString *kContent;
@property (class, nonatomic, strong, readonly) NSString *kTags;

@end

NS_ASSUME_NONNULL_END
