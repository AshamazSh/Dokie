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
#import "LocalAuth.h"
#import "Constants.h"

@interface ChangePasswordViewModel()

@property (nonatomic, strong) RACSubject *dismissSubject;
@property (nonatomic, strong) RACSubject *currentPasswordSubject;
@property (nonatomic) BOOL touchIdLoginEnabled;
@property (nonatomic) BOOL faceIdLoginEnabled;

@property (nonatomic, strong, readonly) LocalAuth *localAuth;
@property (nonatomic, strong, readonly) CoreDataManager *coreDataManager;
@property (nonatomic, strong, readonly) NavigationRouter *navigationRouter;
@property (nonatomic, strong, readonly) NSUserDefaults *userDefaults;

@end

@implementation ChangePasswordViewModel

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.dismissSubject = [RACSubject new];
    self.currentPasswordSubject = [RACSubject new];
    RAC(self, touchIdLoginEnabled) = [RACObserve(self, localAuth.touchIdAvailable) ignore:nil];
    RAC(self, faceIdLoginEnabled) = [RACObserve(self, localAuth.faceIdAvailable) ignore:nil];
}

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
        [self.userDefaults setBool:NO forKey:kDoNotSuggestPasswordSaveKey];
        [self.dismissSubject sendNext:nil];
        [self.localAuth validPasswordEntered:newPass];
    }];
}

- (void)retrieveCurrentPasswordWithBiometrics {
    @weakify(self);
    [[[self.localAuth databasePassword]
      deliverOnMainThread]
     subscribeNext:^(NSString *password) {
        @strongify(self);
        [self.currentPasswordSubject sendNext:password];
    }];
}

#pragma mark - Get Set

- (LocalAuth *)localAuth {
    return [LocalAuth shared];
}

- (CoreDataManager *)coreDataManager {
    return [CoreDataManager shared];
}

- (NavigationRouter *)navigationRouter {
    return [NavigationRouter shared];
}

- (NSUserDefaults *)userDefaults {
    return [NSUserDefaults standardUserDefaults];
}

@end
