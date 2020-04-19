//
//  AppearanceManager.m
//  Dokie
//
//  Created by Ashamaz Shidov on 29/12/2018.
//  Copyright © 2018 Ashamaz Shidov. All rights reserved.
//

#import "AppearanceManager.h"

@implementation AppearanceManager

+ (void)setupAppearance {
    [UINavigationBar appearance].translucent = NO;
    [UINavigationBar appearance].tintColor = [UIColor whiteColor];
    [UINavigationBar appearance].titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    [UINavigationBar appearance].barTintColor = self.backgroundColor;
    [UINavigationBar appearance].barStyle = UIBarStyleBlack;
    [UIBarButtonItem appearance].tintColor = [UIColor whiteColor];

    [UILabel appearance].font = [AppearanceManager normalFont];
    [UITextField appearance].font = [AppearanceManager normalFont];
    [UIButton appearance].titleLabel.font = [AppearanceManager normalFont];
    [UILabel appearance].textColor = [AppearanceManager tintColor];
    [UIButton appearance].tintColor = [AppearanceManager tintColor];
    [UITableView appearance].backgroundColor = [AppearanceManager backgroundColor];
    [[UISegmentedControl appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor blackColor] } forState:UIControlStateSelected];
    [[UISegmentedControl appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor whiteColor] } forState:UIControlStateNormal];
    [UISegmentedControl appearance].tintColor = [AppearanceManager tintColor];
    if (@available(iOS 13, *)) {
        [UISegmentedControl appearance].selectedSegmentTintColor = [AppearanceManager tintColor];
    }
    [UITableViewCell appearance].contentView.backgroundColor = [AppearanceManager backgroundColor];
}

+ (UIFont *)loginTextFieldFont {
    return [UIFont systemFontOfSize:20];
}

+ (UIFont *)actionButtonFont {
    return [UIFont boldSystemFontOfSize:20];
}

+ (UIFont *)smallFont {
    return [UIFont systemFontOfSize:12];
}

+ (UIFont *)normalFont {
    return [UIFont systemFontOfSize:14];
}

+ (UIFont *)normalBoldFont {
    return [UIFont boldSystemFontOfSize:14];
}

+ (UIColor *)tintColor {
    return [UIColor whiteColor];
}

+ (UIColor *)detailColor {
    return [UIColor lightGrayColor];
}

+ (UIColor *)backgroundColor {
    return RGB(50, 72, 78);
}

+ (UIColor *)separatorColor {
    return [UIColor whiteColor];
}

+ (UIColor *)shadowColor {
    return [[UIColor blackColor] colorWithAlphaComponent:0.7];
}

@end
