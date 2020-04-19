//
//  CoreDataScheduler.m
//  Dokie
//
//  Created by Ashamaz Shidov on 21/12/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import "CoreDataScheduler.h"
#import "Logger.h"

@interface CoreDataScheduler ()

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation CoreDataScheduler

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context {
    ParameterAssert(context);
    self = [super init];
    if (self) {
        self.context = context;
    }
    return self;
}

- (RACDisposable *)scheduleWithResult:(void (^)(BOOL))block {
    ParameterAssert(block);
    NSManagedObjectContext *context = self.context;
    RACDisposable *disposable = [RACDisposable new];
    if (!context) {
        block(NO);
    }
    else {
        @weakify(context);
        [self.context performBlock:^{
            if (disposable.disposed) {
                return;
            }
            
            @strongify(context);
            block(context.persistentStoreCoordinator.persistentStores.count > 0);
        }];
    }
    return disposable;
}

@end
