//
//  CDVersion.h
//  Dokie
//
//  Created by Ashamaz Shidov on 16/03/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface CDVersion : NSManagedObject

@property (nonatomic, strong) NSString *info;

#pragma mark -
@property (class, nonatomic, strong, readonly) NSString *kInfo;

@end

NS_ASSUME_NONNULL_END
