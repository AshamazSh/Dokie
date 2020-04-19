//
//  CDTag.h
//  Dokie
//
//  Created by Ashamaz Shidov on 26/12/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@class CDDocument;

@interface CDTag : NSManagedObject

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) CDDocument *document;

#pragma mark -
@property (class, nonatomic, strong, readonly) NSString *kText;
@property (class, nonatomic, strong, readonly) NSString *kDocument;

@end

NS_ASSUME_NONNULL_END
