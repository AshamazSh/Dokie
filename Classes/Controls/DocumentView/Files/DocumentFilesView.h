//
//  DocumentFilesView.h
//  Dokie
//
//  Created by Ashamaz Shidov on 21/12/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Definitions.h"

NS_ASSUME_NONNULL_BEGIN

@class DocumentFilesViewModel;
@class CDContent;

@interface DocumentFilesView : UIView

@property (nonatomic) ViewMode viewMode;
@property (nonatomic, readonly) NSInteger selectedCount;

- (instancetype)initWithViewModel:(DocumentFilesViewModel *)viewModel;
- (void)refresh;
- (NSArray<CDContent *> *)selected;
- (void)deleteSelected;

@end

NS_ASSUME_NONNULL_END
