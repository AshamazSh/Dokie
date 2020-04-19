//
//  FileNameTableViewCell.m
//  Dokie
//
//  Created by Ashamaz Shidov on 26.01.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import "FileNameTableViewCell.h"
#import "UI.h"
#import "AppearanceManager.h"

#import <ReactiveObjC/ReactiveObjC.h>

@interface FileNameTableViewCell()

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UIButton *editButton;

@end

@implementation FileNameTableViewCell

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
    
    self.iconImageView = [UI imageView];
    self.iconImageView.image = [[UIImage imageNamed:@"file.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.contentView addSubview:self.iconImageView];
    
    self.nameLabel = [UI label];
    [self.contentView addSubview:self.nameLabel];
    
    self.editButton = [UI button];
    [self.editButton setImage:[UIImage imageNamed:@"pensil.png"] forState:UIControlStateNormal];
    self.editButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.editButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id _) {
        @strongify(self);
        [self.editCommand execute:self];
        return [RACSignal empty];
    }];
    [self.contentView addSubview:self.editButton];

    [[[RACObserve(self, name) distinctUntilChanged] deliverOnMainThread] subscribeNext:^(NSString *name) {
        @strongify(self);
        self.nameLabel.text = name;
    }];
    NSDictionary *metrics = @{@"vMargin"        : @8,
                              @"smallVMargin"   : @4,
                              @"hMargin"        : @16,
                              @"betweenMargin"  : @10
    };
    NSDictionary *views = NSDictionaryOfVariableBindings(_iconImageView, _nameLabel, _editButton);
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hMargin-[_iconImageView]-betweenMargin-[_nameLabel]-[_editButton]-hMargin-|" options:0 metrics:metrics views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-smallVMargin-[_iconImageView]-smallVMargin-|" options:0 metrics:metrics views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-vMargin-[_nameLabel]-vMargin-|" options:0 metrics:metrics views:views]];
    [self.contentView addConstraints:@[[NSLayoutConstraint constraintWithItem:self.iconImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.iconImageView attribute:NSLayoutAttributeHeight multiplier:1 constant:0],
                                       [NSLayoutConstraint constraintWithItem:self.editButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0],
                                       [NSLayoutConstraint constraintWithItem:self.editButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeHeight multiplier:0.4 constant:0],
                                       [NSLayoutConstraint constraintWithItem:self.editButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.editButton attribute:NSLayoutAttributeHeight multiplier:1 constant:0]]];
}

@end
