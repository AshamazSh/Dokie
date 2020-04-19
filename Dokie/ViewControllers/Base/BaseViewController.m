//
//  BaseViewController.m
//  Dokie
//
//  Created by Ashamaz Shidov on 30/12/2018.
//  Copyright © 2018 Ashamaz Shidov. All rights reserved.
//

#import "BaseViewController.h"
#import "AppearanceManager.h"

@interface BaseViewController ()
@end

@implementation BaseViewController

- (instancetype)initWithViewModel:(id)viewModel {
    return nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [AppearanceManager backgroundColor];
}

@end
