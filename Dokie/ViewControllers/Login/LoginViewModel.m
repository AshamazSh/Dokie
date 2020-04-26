//
//  LoginViewModel.m
//  Doci
//
//  Created by Ashamaz Shidov on 02/12/2018.
//  Copyright © 2018 Ashamaz Shidov. All rights reserved.
//

#import "LoginViewModel.h"
#import "NavigationRouter.h"
#import "EncryptionManager.h"
#import "AppDelegate.h"
#import "LocalAuth.h"

@interface LoginViewModel ()

@property (nonatomic, strong) RACSubject *enableInputSubject;
@property (nonatomic, strong) NSString *loginLabelText;
@property (nonatomic, strong) NSString *loginButtonText;
@property (nonatomic) BOOL touchIdLoginEnabled;
@property (nonatomic) BOOL faceIdLoginEnabled;

@property (nonatomic, strong, readonly) LocalAuth *localAuth;
@property (nonatomic, strong, readonly) NavigationRouter *navigationRouter;
@property (nonatomic, strong, readonly) NSManagedObjectContext *objectContext;

@end

@implementation LoginViewModel

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    RAC(self, touchIdLoginEnabled) = [RACObserve(self, localAuth.touchIdAvailable) ignore:nil];
    RAC(self, faceIdLoginEnabled) = [RACObserve(self, localAuth.faceIdAvailable) ignore:nil];
    self.enableInputSubject = [RACSubject new];
    [self updateText];
}

- (void)updateText {
    self.loginLabelText = [EncryptionManager contextHasKey:self.objectContext] ? NSLocalizedString(@"Password:", @"Password label text") : NSLocalizedString(@"Welcome to Dokie!\nCreate password for your database:", @"Create password label text");
    self.loginButtonText = [EncryptionManager contextHasKey:self.objectContext] ? NSLocalizedString(@"Login", @"Login button text") : NSLocalizedString(@"Create database", @"Create database button text");
    if (![EncryptionManager contextHasKey:self.objectContext]) {
        [self.localAuth resetStoredPassword];
    }
}

- (void)loginPressedWithPassword:(NSString *)password {
    NSString *loadingGuid = [self.navigationRouter showLoading];
    @weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self);
        EncryptionManager *encryptionManager = [[EncryptionManager alloc] initWithPassword:password objectContext:self.objectContext];
        if ([encryptionManager isValid]) {
            [self.navigationRouter hideLoading:loadingGuid];
            [self.navigationRouter pushMainMenuWithEncryptionManager:encryptionManager managedObjectContext:self.objectContext];
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                [self.localAuth validPasswordEntered:password];
            });
        }
        else {
            [self.navigationRouter hideLoading:loadingGuid];
            [self.navigationRouter showAlertWithTitle:@"" message:NSLocalizedString(@"Invalid password", @"Invalid password message")];
        }
        [self.enableInputSubject sendNext:nil];
    });
}

- (void)showAbout {
    [self.navigationRouter showAbout];
}

- (void)loginWithBiometrics {
    @weakify(self);
    [[[self.localAuth databasePassword]
      deliverOnMainThread]
     subscribeNext:^(NSString *password) {
        @strongify(self);
        [self loginPressedWithPassword:password];
    }
     error:^(NSError * _Nullable error) {
        @strongify(self);
        [self.navigationRouter showAlertWithTitle:@"" message:NSLocalizedString(@"Can not retrieve password from keychain", @"Keychain error")];
    }];
}

#pragma mark -

- (NavigationRouter *)navigationRouter {
    return [NavigationRouter shared];
}

- (LocalAuth *)localAuth {
    return [LocalAuth shared];
}

- (NSManagedObjectContext *)objectContext {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    return delegate.objectContext;
}

@end
