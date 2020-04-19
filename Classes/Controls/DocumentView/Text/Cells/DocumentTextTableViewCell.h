//
//  DocumentTextTableViewCell.h
//  Dokie
//
//  Created by Ashamaz Shidov on 26.01.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Definitions.h"

NS_ASSUME_NONNULL_BEGIN

@class RACCommand;

@interface DocumentTextTableViewCell : UITableViewCell

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *detail;
@property (nonatomic) ViewMode viewMode;
@property (nonatomic) BOOL showCheckmark;
@property (nonatomic, strong) RACCommand *editCommand;

@end

NS_ASSUME_NONNULL_END
