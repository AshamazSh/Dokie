//
//  DocumentTextView.h
//  Dokie
//
//  Created by Ashamaz Shidov on 21/12/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Definitions.h"

NS_ASSUME_NONNULL_BEGIN

@class DocumentTextViewModel;

@interface DocumentTextView : UIView

@property (nonatomic) ViewMode viewMode;
@property (nonatomic, readonly) NSInteger selectedCount;

- (instancetype)initWithViewModel:(DocumentTextViewModel *)viewModel;
- (void)refresh;
- (NSArray<NSString *> *)selected;
- (void)deleteSelected;

@end

NS_ASSUME_NONNULL_END
