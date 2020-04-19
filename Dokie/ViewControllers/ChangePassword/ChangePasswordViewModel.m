//
//  ChangePasswordViewModel.m
//  Dokie
//
//  Created by Ashamaz Shidov on 02.02.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import "ChangePasswordViewModel.h"
#import "NavigationRouter.h"
#import "CoreDataManager.h"
    
@interface ChangePasswordViewModel()

@property (nonatomic, strong) RACSubject *dismissSubject;
@property (nonatomic, strong, readonly) CoreDataManager *coreDataManager;
@property (nonatomic, strong, readonly) NavigationRouter *navigationRouter;

@end

@implementation ChangePasswordViewModel

- (void)changePressedWithCurrentPass:(NSString *)currentPass newPass:(NSString *)newPass {
    @weakify(self);
    [[[self.coreDataManager changeCurrentPassword:currentPass to:newPass]
      deliverOnMainThread]
     subscribeError:^(NSError * _Nullable error) {
        @strongify(self);
        [self.dismissSubject sendNext:error];
    }
     completed:^{
        @strongify(self);
        [self.dismissSubject sendNext:nil];
    }];
}

#pragma mark - Get Set

- (RACSubject *)dismissSubject {
    if (!_dismissSubject) {
        _dismissSubject = [RACSubject new];
    }
    return _dismissSubject;
}

- (CoreDataManager *)coreDataManager {
    return [CoreDataManager shared];
}

- (NavigationRouter *)navigationRouter {
    return [NavigationRouter shared];
}

@end
