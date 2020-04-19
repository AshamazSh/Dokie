//
//  CoreDataScheduler.h
//  Dokie
//
//  Created by Ashamaz Shidov on 21/12/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC/ReactiveObjC.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface CoreDataScheduler : NSObject

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context;
- (RACDisposable *)scheduleWithResult:(void (^)(BOOL success))block;

@end

NS_ASSUME_NONNULL_END
