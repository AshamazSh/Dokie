//
//  CDContent.h
//  Dokie
//
//  Created by Ashamaz Shidov on 18/03/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@class CDDocument;

@interface CDContent : NSManagedObject

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) CDDocument *document;

#pragma mark -
@property (class, nonatomic, strong, readonly) NSString *kData;
@property (class, nonatomic, strong, readonly) NSString *kDocument;

@end

NS_ASSUME_NONNULL_END
