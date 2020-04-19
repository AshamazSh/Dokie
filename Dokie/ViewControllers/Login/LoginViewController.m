//
//  LoginViewController.m
//  Doci
//
//  Created by Ashamaz Shidov on 02/12/2018.
//  Copyright © 2018 Ashamaz Shidov. All rights reserved.
//

#import "LoginViewController.h"
#import "LoginViewModel.h"
#import "UI.h"

#import <ReactiveObjC/ReactiveObjC.h>

@interface LoginViewController () <UITextFieldDelegate>

@property (nonatomic, strong) LoginViewModel *viewModel;
@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, strong) UIButton *loginButton;

@end

@implementation LoginViewController

- (instancetype)initWithViewModel:(LoginViewModel *)viewModel {
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.viewModel updateText];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.passwordTextField becomeFirstResponder];
}

- (void)setup {
    @weakify(self);
    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"About", @"About bar button text") style:UIBarButtonItemStylePlain target:nil action:nil];
    helpButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id _) {
        @strongify(self);
        [self.viewModel showAbout];
        return [RACSignal empty];
    }];
    self.navigationItem.rightBarButtonItems = @[helpButton];
    
    UILabel *loginLabel = [UI label];
    loginLabel.numberOfLines = 0;
    RAC(loginLabel, text) = RACObserve(self, viewModel.loginLabelText);
    [self.view addSubview:loginLabel];
    
    self.passwordTextField = [UI textField];
    self.passwordTextField.returnKeyType = UIReturnKeyGo;
    self.passwordTextField.delegate = self;
    self.passwordTextField.secureTextEntry = YES;
    [self.view addSubview:self.passwordTextField];
    
    self.loginButton = [UI actionButton];
    self.loginButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id _) {
        @strongify(self);
        [self loginPressed];
        return [RACSignal empty];
    }];
    [self.view addSubview:self.loginButton];
    [[RACObserve(self, viewModel.loginButtonText) deliverOnMainThread] subscribeNext:^(NSString *loginButtonText) {
        @strongify(self);
        [self.loginButton setTitle:loginButtonText forState:UIControlStateNormal];
    }];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_passwordTextField, _loginButton, loginLabel);
    NSDictionary *metrics = @{@"betweenMargin"      :   @16,
                              @"sideMargin"         :   @25,
                              @"buttonHeight"       :   @44,
                              @"textFieldHeight"    :   @44
                              };
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-sideMargin-[_passwordTextField]-sideMargin-|" options:0 metrics:metrics views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-sideMargin-[loginLabel]-sideMargin-|" options:0 metrics:metrics views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[loginLabel]-betweenMargin-[_passwordTextField(textFieldHeight)]-betweenMargin-[_loginButton(buttonHeight)]" options:0 metrics:metrics views:views]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.passwordTextField attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:0.6 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.loginButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    
    [[[self.viewModel.enableInputSubject
       takeUntil:self.rac_willDeallocSignal]
      deliverOnMainThread]
     subscribeNext:^(id _) {
        @strongify(self);
        self.loginButton.enabled = YES;
        self.passwordTextField.enabled = YES;
        self.passwordTextField.text = @"";
    }];
}

- (void)loginPressed {
    self.loginButton.enabled = NO;
    self.passwordTextField.enabled = NO;
    [self.passwordTextField endEditing:YES];
    [self.viewModel loginPressedWithPassword:self.passwordTextField.text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self loginPressed];
    return YES;
}

@end
