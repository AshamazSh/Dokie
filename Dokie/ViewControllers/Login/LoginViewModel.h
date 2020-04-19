//
//  LoginViewModel.h
//  Doci
//
//  Created by Ashamaz Shidov on 02/12/2018.
//  Copyright © 2018 Ashamaz Shidov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC/ReactiveObjC.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoginViewModel : NSObject

@property (nonatomic, strong, readonly) RACSubject *enableInputSubject;
@property (nonatomic, strong, readonly) NSString *loginLabelText;
@property (nonatomic, strong, readonly) NSString *loginButtonText;

- (void)loginPressedWithPassword:(NSString *)password;
- (void)showAbout;
- (void)updateText;

@end

NS_ASSUME_NONNULL_END
