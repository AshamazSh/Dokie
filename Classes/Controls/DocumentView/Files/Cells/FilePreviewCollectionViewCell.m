//
//  FilePreviewCollectionViewCell.m
//  Dokie
//
//  Created by Ashamaz Shidov on 14/01/2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import "FilePreviewCollectionViewCell.h"
#import "CoreDataInclude.h"
#import "CoreDataManager.h"
#import "FileImageView.h"
#import "UI.h"

#import <ReactiveObjC/ReactiveObjC.h>

@interface FilePreviewCollectionViewCell()

@property (nonatomic, strong) FileImageView *fileImage;

@property (nonatomic, strong, readonly) CoreDataManager *coreDataManager;

@end

@implementation FilePreviewCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.fileImage = [FileImageView new];
    self.fileImage.translatesAutoresizingMaskIntoConstraints = NO;
    self.fileImage.contentMode = UIViewContentModeScaleAspectFill;
    self.fileImage.clipsToBounds = YES;
    [self.contentView addSubview:self.fileImage];
    
    UIView *shadowView = [UI shadowView];
    shadowView.alpha = 0;
    [self.contentView addSubview:shadowView];
    
    UIImageView *checkImage = [UI imageView];
    checkImage.image = [[UIImage imageNamed:@"checkmark.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [shadowView addSubview:checkImage];
    
    NSDictionary *metrics = @{@"imageSize"  :   @44};
    NSDictionary *views = NSDictionaryOfVariableBindings(_fileImage, shadowView, checkImage);
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_fileImage]|" options:0 metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_fileImage]|" options:0 metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[shadowView]|" options:0 metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[shadowView]|" options:0 metrics:nil views:views]];
    [shadowView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[checkImage(imageSize)]-|" options:0 metrics:metrics views:views]];
    [shadowView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[checkImage(imageSize)]-|" options:0 metrics:metrics views:views]];
    
    @weakify(shadowView);
    [[[RACObserve(self, showCheckmark) distinctUntilChanged] deliverOnMainThread] subscribeNext:^(NSNumber *showCheckmark) {
        @strongify(shadowView);
        shadowView.alpha = showCheckmark.boolValue ? 1 : 0;
    }];
}

- (void)updateWithContent:(CDContent *)content {
    [self.fileImage updateWithContent:content];
}

#pragma mark - Get Set

- (CoreDataManager *)coreDataManager {
    return [CoreDataManager shared];
}

@end
