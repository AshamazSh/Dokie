//
//  ChangePasswordViewController.m
//  Dokie
//
//  Created by Ashamaz Shidov on 02.02.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import "ChangePasswordViewController.h"
#import "ChangePasswordViewModel.h"
#import "UI.h"

@interface ChangePasswordViewController ()

@property (nonatomic, strong) ChangePasswordViewModel *viewModel;
@property (nonatomic, strong) UITextField *currentPasswordTextField;
@property (nonatomic, strong) UITextField *passwordTextField;

@end

@implementation ChangePasswordViewController

- (instancetype)initWithViewModel:(ChangePasswordViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)setup {
    @weakify(self);
    if (@available(iOS 13, *)) {
        self.modalInPresentation = YES;
    }
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"Cancel button text") style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.leftBarButtonItems = @[cancelButton];
    
    UILabel *currentPassLabel = [UILabel new];
    currentPassLabel.translatesAutoresizingMaskIntoConstraints = NO;
    currentPassLabel.text = NSLocalizedString(@"Current password:", @"Current password label text");
    [self.view addSubview:currentPassLabel];
    
    self.currentPasswordTextField = [UI textField];
    self.currentPasswordTextField.secureTextEntry = YES;
    [self.view addSubview:self.currentPasswordTextField];

    UILabel *newPassLabel = [UI label];
    newPassLabel.text = NSLocalizedString(@"New password:", @"Current password label text");
    [self.view addSubview:newPassLabel];
    
    self.passwordTextField = [UI textField];
    self.passwordTextField.secureTextEntry = YES;
    [self.view addSubview:self.passwordTextField];

    UIButton *changeButton = [UI actionButton];
    [changeButton setTitle:NSLocalizedString(@"Change password", @"Change password button text") forState:UIControlStateNormal];
    [self.view addSubview:changeButton];

    NSDictionary *views = NSDictionaryOfVariableBindings(currentPassLabel, _currentPasswordTextField, newPassLabel, _passwordTextField, changeButton);
    NSDictionary *metrics = @{@"topMargin"          :   @20,
                              @"betweenMargin"      :   @20,
                              @"betweenSmallMargin" :   @16,
                              @"sideMargin"         :   @25,
                              @"buttonHeight"       :   @44,
                              @"textFieldHeight"    :   @44
                              };
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-sideMargin-[currentPassLabel]-sideMargin-|" options:0 metrics:metrics views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-sideMargin-[_currentPasswordTextField]-sideMargin-|" options:0 metrics:metrics views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-sideMargin-[newPassLabel]-sideMargin-|" options:0 metrics:metrics views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-sideMargin-[_passwordTextField]-sideMargin-|" options:0 metrics:metrics views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-sideMargin-[changeButton]-sideMargin-|" options:0 metrics:metrics views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-topMargin-[currentPassLabel]-betweenSmallMargin-[_currentPasswordTextField(textFieldHeight)]-betweenMargin-[newPassLabel]-betweenSmallMargin-[_passwordTextField(textFieldHeight)]-betweenMargin-[changeButton(buttonHeight)]" options:0 metrics:metrics views:views]];

    UIView *loadingView = [UI shadowView];
    loadingView.alpha = 0;
    {
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activity.translatesAutoresizingMaskIntoConstraints = NO;
        [activity startAnimating];
        [loadingView addSubview:activity];
        [loadingView addConstraint:[NSLayoutConstraint constraintWithItem:activity attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:loadingView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [loadingView addConstraint:[NSLayoutConstraint constraintWithItem:activity attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:loadingView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        NSDictionary *views = NSDictionaryOfVariableBindings(loadingView);
        [self.view addSubview:loadingView];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[loadingView]|" options:0 metrics:nil views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[loadingView]|" options:0 metrics:nil views:views]];
        [self.view layoutIfNeeded];
    }
    
    @weakify(loadingView);
    changeButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id _) {
        @strongify(self, loadingView);
        loadingView.alpha = 1;
        [self.viewModel changePressedWithCurrentPass:self.currentPasswordTextField.text newPass:self.passwordTextField.text];
        return [RACSignal empty];
    }];
    
    cancelButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id _) {
        @strongify(self, loadingView);
        if (loadingView.alpha == 0) {
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        }
        return [RACSignal empty];
    }];

    [[[self.viewModel.dismissSubject takeUntil:self.rac_willDeallocSignal]
      deliverOnMainThread]
     subscribeNext:^(NSError *error) {
        @strongify(self, loadingView);
        loadingView.alpha = 0;
        if (error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@""
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Ok button text in alert view") style:UIAlertActionStyleCancel handler:nil];
            [alert addAction:cancel];
            [self.navigationController presentViewController:alert animated:YES completion:nil];
        }
        else {
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

@end
