//
//  FilePreviewCollectionViewCell.h
//  Dokie
//
//  Created by Ashamaz Shidov on 14/01/2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CDContent;

@interface FilePreviewCollectionViewCell : UICollectionViewCell

@property (nonatomic) BOOL showCheckmark;

- (void)updateWithContent:(CDContent *)content;

@end

NS_ASSUME_NONNULL_END
