//
//  ImagePreviewViewController.h
//  Dokie
//
//  Created by Ashamaz Shidov on 26.01.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FileImageView;

@interface ImagePreviewViewController : UIViewController

@property (nonatomic, readonly) NSInteger pageIndex;
@property (nonatomic, strong, readonly) FileImageView *imageView;

- (instancetype)initWithImageView:(FileImageView *)imageView pageIndex:(NSInteger)pageIndex;
- (void)moveScrollViewCenterToDeltaY:(CGFloat)deltaY;

@end

NS_ASSUME_NONNULL_END
