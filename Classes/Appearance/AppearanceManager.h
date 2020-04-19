//
//  AppearanceManager.h
//  Dokie
//
//  Created by Ashamaz Shidov on 29/12/2018.
//  Copyright © 2018 Ashamaz Shidov. All rights reserved.
//

#import <UIKit/UIKit.h>

#define RGB(r,g,b)      RGBA(r,g,b,255.0)
#define RGBA(r,g,b,a)   [UIColor colorWithRed:(CGFloat)r/255.0 green:(CGFloat)g/255.0 blue:(CGFloat)b/255.0 alpha:(CGFloat)a/255.0]

NS_ASSUME_NONNULL_BEGIN

@interface AppearanceManager : NSObject

+ (void)setupAppearance;

+ (UIFont *)loginTextFieldFont;
+ (UIFont *)actionButtonFont;
+ (UIFont *)smallFont;
+ (UIFont *)normalFont;
+ (UIFont *)normalBoldFont;
+ (UIColor *)tintColor;
+ (UIColor *)detailColor;
+ (UIColor *)backgroundColor;
+ (UIColor *)separatorColor;
+ (UIColor *)shadowColor;

@end

NS_ASSUME_NONNULL_END
