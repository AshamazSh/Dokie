//
//  FolderViewController.h
//  Dokie
//
//  Created by Ashamaz Shidov on 28/12/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class FolderViewModel;

@interface FolderViewController : BaseViewController

- (instancetype)initWithViewModel:(FolderViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
