//
//  LoginViewController.h
//  Doci
//
//  Created by Ashamaz Shidov on 02/12/2018.
//  Copyright © 2018 Ashamaz Shidov. All rights reserved.
//

#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class LoginViewModel;

@interface LoginViewController : BaseViewController

- (instancetype)initWithViewModel:(LoginViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
