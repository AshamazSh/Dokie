//
//  NavigationRouter.m
//  Doci
//
//  Created by Ashamaz Shidov on 02/12/2018.
//  Copyright © 2018 Ashamaz Shidov. All rights reserved.
//

#import "NavigationRouter.h"
#import "NavigationRouterInclude.h"
#import "CoreDataManager.h"

#import <UIKit/UIKit.h>

@interface NavigationRouter ()

@property (nonatomic, strong) UINavigationController *navController;
@property (nonatomic, strong) UIWindow *mainWindow;
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) NSMutableArray<NSString *> *loadingGuids;
@property (nonatomic, strong) UIBlurEffect *blurEffect;
@property (nonatomic, strong) UIVisualEffectView *blurView;

@property (nonatomic, strong, readonly) CoreDataManager *coreDataManager;

@end

@implementation NavigationRouter

+ (instancetype)shared {
    static id sharedObject = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedObject = [NavigationRouter new];
    });
    return sharedObject;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:self.blurEffect];
    
    self.loadingGuids = [NSMutableArray array];
}

- (void)createLoginViewController {
    LoginViewModel *viewModel = [LoginViewModel new];
    LoginViewController *rootViewController = [[LoginViewController alloc] initWithViewModel:viewModel];
    
    self.navController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
    self.navController.navigationBar.tintColor = [UIColor blueColor];

    self.mainWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.mainWindow setRootViewController:self.navController];
    [self.mainWindow makeKeyAndVisible];
}

- (void)pushMainMenuWithEncryptionManager:(EncryptionManager *)encryptionManager managedObjectContext:(NSManagedObjectContext *)objectContext {
    [self.coreDataManager setupWithEncryptionManager:encryptionManager managedObjectContext:objectContext];
    [self pushFolder:nil];
}

- (void)pushFolder:(CDFolder * _Nullable)folder {
    FolderViewModel *viewModel = [[FolderViewModel alloc] initWithFolder:folder];
    FolderViewController *viewController = [[FolderViewController alloc] initWithViewModel:viewModel];
    [self.navController pushViewController:viewController animated:YES];
}

- (void)pushDocument:(CDDocument *)document {
    DocumentViewModel *viewModel = [[DocumentViewModel alloc] initWithDocument:document];
    DocumentViewController *viewController = [[DocumentViewController alloc] initWithViewModel:viewModel];
    [self.navController pushViewController:viewController animated:YES];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Ok button text in alert view") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self showAlert:alert];
}

- (void)showAlert:(UIAlertController *)alert {
    UIViewController *on = self.navController.viewControllers.lastObject;
    alert.popoverPresentationController.sourceView = on.view;
    alert.popoverPresentationController.sourceRect = CGRectMake(on.view.bounds.size.width/2, on.view.bounds.size.height/2, 0, 0);
    alert.popoverPresentationController.permittedArrowDirections = 0;
    [self.navController presentViewController:alert animated:YES completion:nil];
}

- (void)showImagePicker:(UIImagePickerController *)imagePicker {
    [self.navController presentViewController:imagePicker animated:YES completion:nil];
}

- (void)shareItems:(NSArray *)items {
    UIActivityViewController * avc = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    [self.navController presentViewController:avc animated:YES completion:nil];
}

- (void)showDocumentImages:(NSArray<CDContent *> *)contentImages firstIndex:(NSInteger)index {
    DocumentImagesPageViewModel *viewModel = [[DocumentImagesPageViewModel alloc] initWithContentImages:contentImages firstIndex:index];
    DocumentImagesPageViewController *vc = [[DocumentImagesPageViewController alloc] initWithViewModel:viewModel];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    [navController setModalPresentationStyle:UIModalPresentationPageSheet];

    [self.navController presentViewController:navController animated:YES completion:nil];
}

- (void)logout {
    [self.coreDataManager reset];
    [self.navController popToRootViewControllerAnimated:YES];
}

- (void)showChangePassword {
    ChangePasswordViewModel *viewModel = [ChangePasswordViewModel new];
    ChangePasswordViewController *vc = [[ChangePasswordViewController alloc] initWithViewModel:viewModel];

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    [navController setModalPresentationStyle:UIModalPresentationPageSheet];

    [self.navController presentViewController:navController animated:YES completion:nil];
}

- (NSString *)showLoading {
    if (!self.loadingView) {
        self.loadingView = [UIView new];
        self.loadingView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        self.loadingView.translatesAutoresizingMaskIntoConstraints = NO;
        {
            UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            activity.translatesAutoresizingMaskIntoConstraints = NO;
            [activity startAnimating];
            [self.loadingView addSubview:activity];
            [self.loadingView addConstraint:[NSLayoutConstraint constraintWithItem:activity attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.loadingView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
            [self.loadingView addConstraint:[NSLayoutConstraint constraintWithItem:activity attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.loadingView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        }
        NSDictionary *views = NSDictionaryOfVariableBindings(_loadingView);
        [self.navController.view addSubview:self.loadingView];
        [self.navController.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_loadingView]|" options:0 metrics:nil views:views]];
        [self.navController.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_loadingView]|" options:0 metrics:nil views:views]];
        [self.navController.view layoutIfNeeded];
    }
    NSString *guid = [NSUUID UUID].UUIDString;
    [self.loadingGuids addObject:guid];
    return guid;
}

- (void)hideLoading:(NSString *)guid {
    [self.loadingGuids removeObject:guid];
    if (self.loadingGuids.count == 0) {
        [self.loadingView removeFromSuperview];
        self.loadingView = nil;
    }
}

- (void)blur {
    self.blurView.frame = self.mainWindow.frame;
    [self.mainWindow addSubview:self.blurView];
}

- (void)unblur {
    [self.blurView removeFromSuperview];
}

- (void)showAbout {
    AboutViewController *vc = [[AboutViewController alloc] init];

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    [navController setModalPresentationStyle:UIModalPresentationPageSheet];

    [self.navController presentViewController:navController animated:YES completion:nil];
}

#pragma mark -

- (CoreDataManager *)coreDataManager {
    return [CoreDataManager shared];
}

@end
