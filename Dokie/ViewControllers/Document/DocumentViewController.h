//
//  DocumentViewController.h
//  Dokie
//
//  Created by Ashamaz Shidov on 28/12/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class DocumentViewModel;

@interface DocumentViewController : BaseViewController

- (instancetype)initWithViewModel:(DocumentViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
