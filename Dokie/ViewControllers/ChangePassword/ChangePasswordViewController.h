//
//  ChangePasswordViewController.h
//  Dokie
//
//  Created by Ashamaz Shidov on 02.02.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class ChangePasswordViewModel;

@interface ChangePasswordViewController : BaseViewController

- (instancetype)initWithViewModel:(ChangePasswordViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
