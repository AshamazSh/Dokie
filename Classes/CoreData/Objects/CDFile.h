//
//  CDFile.h
//  Dokie
//
//  Created by Ashamaz Shidov on 18/01/2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface CDFile : NSManagedObject

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSData *data;

#pragma mark -
@property (class, nonatomic, strong, readonly) NSString *kIdentifier;
@property (class, nonatomic, strong, readonly) NSString *kData;

@end

NS_ASSUME_NONNULL_END
