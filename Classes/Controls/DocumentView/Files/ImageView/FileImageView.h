//
//  FileImageView.h
//  Dokie
//
//  Created by Ashamaz Shidov on 26.01.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CDContent;

@interface FileImageView : UIImageView

- (void)updateWithContent:(CDContent *)content;

@end

NS_ASSUME_NONNULL_END
