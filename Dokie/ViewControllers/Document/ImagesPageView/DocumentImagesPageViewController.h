//
//  DocumentImagesPageViewController.h
//  Dokie
//
//  Created by Ashamaz Shidov on 26.01.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class DocumentImagesPageViewModel;

@interface DocumentImagesPageViewController : UIPageViewController

- (instancetype)initWithViewModel:(DocumentImagesPageViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
