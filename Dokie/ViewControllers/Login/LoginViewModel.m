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

@interface LoginViewModel ()

@property (nonatomic, strong) RACSubject *enableInputSubject;
@property (nonatomic, strong) NSString *loginLabelText;
@property (nonatomic, strong) NSString *loginButtonText;

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
    self.enableInputSubject = [RACSubject new];
    [self updateText];
}

- (void)updateText {
    self.loginLabelText = [EncryptionManager contextHasKey:self.objectContext] ? NSLocalizedString(@"Password:", @"Password label text") : NSLocalizedString(@"Welcome to Dokie!\nCreate password for your database:", @"Create password label text");
    self.loginButtonText = [EncryptionManager contextHasKey:self.objectContext] ? NSLocalizedString(@"Login", @"Login button text") : NSLocalizedString(@"Create database", @"Create database button text");
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

#pragma mark -

- (NavigationRouter *)navigationRouter {
    return [NavigationRouter shared];
}

- (NSManagedObjectContext *)objectContext {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    return delegate.objectContext;
}

@end
