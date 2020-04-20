//
//  UI.m
//  Dokie
//
//  Created by Ashamaz Shidov on 19.04.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import "UI.h"
#import "AppearanceManager.h"

@implementation UI

+ (UILabel *)label {
    UILabel *label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.textColor = [AppearanceManager tintColor];
    label.font = [AppearanceManager normalFont];
    return label;
}

+ (UILabel *)detailLabel {
    UILabel *label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.textColor = [AppearanceManager detailColor];
    label.font = [AppearanceManager smallFont];
    return label;
}

+ (UITableView *)tableView {
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    tableView.tableFooterView = [UIView new];
    tableView.insetsContentViewsToSafeArea = YES;
    tableView.separatorColor = [AppearanceManager separatorColor];
    tableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 0);
    return tableView;
}

+ (UIButton *)button {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.titleLabel.font = [AppearanceManager normalFont];
    return button;;
}

+ (UIButton *)actionButton {
    UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    actionButton.titleLabel.font = [AppearanceManager actionButtonFont];
    return actionButton;
}

+ (UICollectionView *)collectionViewWithLineSpacing:(CGFloat)lineSpacing itemSpacing:(CGFloat)itemSpacing {
    UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.minimumLineSpacing = lineSpacing;
    flowLayout.minimumInteritemSpacing = itemSpacing;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    collectionView.backgroundColor = [AppearanceManager backgroundColor];
    collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    collectionView.alwaysBounceVertical = YES;
    return collectionView;
}

+ (UIView *)separator {
    UIView *separator = [UIView new];
    separator.translatesAutoresizingMaskIntoConstraints = NO;
    separator.backgroundColor = [AppearanceManager separatorColor];
    return separator;
}

+ (UIView *)view {
    UIView *view = [UIView new];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.backgroundColor = [AppearanceManager backgroundColor];
    return view;
}

+ (UIView *)shadowView {
    UIView *shadowView = [UIView new];
    shadowView.backgroundColor = [AppearanceManager shadowColor];
    shadowView.translatesAutoresizingMaskIntoConstraints = NO;
    return shadowView;
}

+ (UITextField *)textField {
    UITextField *textField = [UITextField new];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.font = [AppearanceManager loginTextFieldFont];
    textField.backgroundColor = RGB(230, 230, 230);
    textField.layer.cornerRadius = 5;
    UIView *spacingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 4, 44)];
    textField.leftView = spacingView;
    textField.leftViewMode = UITextFieldViewModeAlways;
    textField.textColor = [UIColor blackColor];
    return textField;
}

+ (UIImageView *)imageView {
    UIImageView *imageView = [UIImageView new];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.clipsToBounds = YES;
    imageView.tintColor = [AppearanceManager tintColor];
    return imageView;
}

+ (UISegmentedControl *)segmentedControlWithItems:(NSArray<NSString *> *)items {
    UISegmentedControl *segmented = [[UISegmentedControl alloc] initWithItems:items];
    segmented.translatesAutoresizingMaskIntoConstraints = NO;
    segmented.selectedSegmentIndex = 0;
    return segmented;
}

+ (UIScrollView *)scrollView {
    UIScrollView *scrollView = [UIScrollView new];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.bouncesZoom = YES;
    scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    scrollView.maximumZoomScale = 2;
    scrollView.minimumZoomScale = 1;
    return scrollView;
}

@end
