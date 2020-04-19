//
//  CDFolder.h
//  Dokie
//
//  Created by Ashamaz Shidov on 16/03/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@class CDDocument;

@interface CDFolder : NSManagedObject

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSSet<CDDocument *> *documents;
@property (nonatomic, strong) CDFolder *parentFolder;
@property (nonatomic, strong) NSSet<CDFolder *> *subfolders;

#pragma mark -
@property (class, nonatomic, strong, readonly) NSString *kData;
@property (class, nonatomic, strong, readonly) NSString *kDate;
@property (class, nonatomic, strong, readonly) NSString *kDocuments;
@property (class, nonatomic, strong, readonly) NSString *kParentFolder;
@property (class, nonatomic, strong, readonly) NSString *kSubfolders;

@end

NS_ASSUME_NONNULL_END
