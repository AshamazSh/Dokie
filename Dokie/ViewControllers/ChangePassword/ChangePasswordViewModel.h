//
//  ChangePasswordViewModel.h
//  Dokie
//
//  Created by Ashamaz Shidov on 02.02.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC/ReactiveObjC.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChangePasswordViewModel : NSObject

@property (nonatomic, strong, readonly) RACSubject *dismissSubject;
@property (nonatomic, strong, readonly) RACSubject *currentPasswordSubject;
@property (nonatomic, readonly) BOOL touchIdLoginEnabled;
@property (nonatomic, readonly) BOOL faceIdLoginEnabled;

- (void)changePressedWithCurrentPass:(NSString *)currentPass newPass:(NSString *)newPass;
- (void)retrieveCurrentPasswordWithBiometrics;

@end

NS_ASSUME_NONNULL_END
