//
//  FileNameTableViewCell.h
//  Dokie
//
//  Created by Ashamaz Shidov on 26.01.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RACCommand;

@interface FileNameTableViewCell : UITableViewCell

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) RACCommand *editCommand;

@end

NS_ASSUME_NONNULL_END
