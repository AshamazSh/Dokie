//
//  DocumentTextTableViewCell.m
//  Dokie
//
//  Created by Ashamaz Shidov on 26.01.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import "DocumentTextTableViewCell.h"
#import "UI.h"
#import "AppearanceManager.h"

#import <ReactiveObjC/ReactiveObjC.h>

@interface DocumentTextTableViewCell()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIImageView *checkmarkImageView;
@property (nonatomic, strong) NSLayoutConstraint *imageRightMargin;
@property (nonatomic, strong) NSLayoutConstraint *labelLeftMargin;
@property (nonatomic, strong) UIButton *editButton;

@end

@implementation DocumentTextTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    @weakify(self);
    self.backgroundColor = [AppearanceManager backgroundColor];
    self.contentView.backgroundColor = [AppearanceManager backgroundColor];
    
    self.checkmarkImageView = [UI imageView];
    self.checkmarkImageView.image = [[UIImage imageNamed:@"checkmark.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.contentView addSubview:self.checkmarkImageView];
    
    self.titleLabel = [UI label];
    [self.contentView addSubview:self.titleLabel];
    
    self.detailLabel = [UI detailLabel];
    [self.contentView addSubview:self.detailLabel];
    
    self.editButton = [UI button];
    [self.editButton setImage:[UIImage imageNamed:@"pensil.png"] forState:UIControlStateNormal];
    self.editButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.editButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id _) {
        @strongify(self);
        [self.editCommand execute:self];
        return [RACSignal empty];
    }];
    [self.contentView addSubview:self.editButton];
    
    self.labelLeftMargin = [NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:16];
    self.imageRightMargin = [NSLayoutConstraint constraintWithItem:self.checkmarkImageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:0];

    NSDictionary *metrics = @{@"vMargin"        : @8,
                              @"hMargin"        : @16,
                              @"betweenMargin"  : @4
    };
    NSDictionary *views = NSDictionaryOfVariableBindings(_checkmarkImageView, _titleLabel, _detailLabel, _editButton);
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-vMargin-[_titleLabel]-betweenMargin-[_detailLabel]-vMargin-|" options:0 metrics:metrics views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_titleLabel]-[_editButton]-hMargin-|" options:0 metrics:metrics views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_detailLabel]-[_editButton]-hMargin-|" options:0 metrics:metrics views:views]];
    [self.contentView addConstraints:@[[NSLayoutConstraint constraintWithItem:self.detailLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.titleLabel attribute:NSLayoutAttributeLeft multiplier:1 constant:0],
                                       [NSLayoutConstraint constraintWithItem:self.checkmarkImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.checkmarkImageView attribute:NSLayoutAttributeHeight multiplier:1 constant:0],
                                       [NSLayoutConstraint constraintWithItem:self.checkmarkImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0],
                                       [NSLayoutConstraint constraintWithItem:self.checkmarkImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeHeight multiplier:0.4 constant:0],
                                       [NSLayoutConstraint constraintWithItem:self.editButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0],
                                       [NSLayoutConstraint constraintWithItem:self.editButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeHeight multiplier:0.4 constant:0],
                                       [NSLayoutConstraint constraintWithItem:self.editButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.editButton attribute:NSLayoutAttributeHeight multiplier:1 constant:0],
                                       self.imageRightMargin,
                                       self.labelLeftMargin]];
    
    RAC(self.titleLabel, text) = RACObserve(self, text);
    RAC(self.detailLabel, text) = RACObserve(self, detail);
    self.viewMode = ViewModeDisplay;
    
    [[[[RACObserve(self, viewMode) distinctUntilChanged] skip:1] deliverOnMainThread] subscribeNext:^(NSNumber *viewMode) {
        @strongify(self);
        [self.contentView layoutIfNeeded];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        [UIView animateWithDuration:0.3 animations:^{
            if (viewMode.integerValue == ViewModeDisplay) {
                self.imageRightMargin.constant = 0;
                self.labelLeftMargin.constant = 16;
            }
            else {
                self.imageRightMargin.constant = 16 + self.checkmarkImageView.frame.size.width;
                self.labelLeftMargin.constant = 16 + 8 + self.checkmarkImageView.frame.size.width;
            }
            [self.contentView layoutIfNeeded];
        }];
    }];
    
    [[RACObserve(self, showCheckmark) distinctUntilChanged] subscribeNext:^(NSNumber *showCheckmark) {
        @strongify(self);
        self.checkmarkImageView.alpha = showCheckmark.boolValue ? 1 : 0;
    }];
}

@end
