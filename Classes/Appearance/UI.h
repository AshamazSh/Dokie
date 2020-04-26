//
//  UI.h
//  Dokie
//
//  Created by Ashamaz Shidov on 19.04.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UI : NSObject

+ (UILabel *)label;
+ (UILabel *)detailLabel;
+ (UITableView *)tableView;
+ (UIButton *)actionButton;
+ (UIButton *)touchIdButton;
+ (UIButton *)faceIdButton;
+ (UIButton *)button;
+ (UICollectionView *)collectionViewWithLineSpacing:(CGFloat)lineSpacing itemSpacing:(CGFloat)itemSpacing;
+ (UIView *)separator;
+ (UIView *)view;
+ (UIView *)shadowView;
+ (UITextField *)textField;
+ (UIImageView *)imageView;
+ (UISegmentedControl *)segmentedControlWithItems:(NSArray<NSString *> *)items;
+ (UIScrollView *)scrollView;

@end

NS_ASSUME_NONNULL_END
