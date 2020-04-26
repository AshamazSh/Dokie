//
//  LocalAuth.h
//  Dokie
//
//  Created by Ashamaz Shidov on 26.04.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC/ReactiveObjC.h>

NS_ASSUME_NONNULL_BEGIN

@interface LocalAuth : NSObject

@property (nonatomic, readonly) BOOL touchIdAvailable;
@property (nonatomic, readonly) BOOL faceIdAvailable;

+ (instancetype)shared;

- (void)resetStoredPassword;
- (RACSignal< NSString *> *)databasePassword;
- (void)saveDatabasePassword:(NSString *)databasePassword;
- (void)validPasswordEntered:(NSString *)databasePassword;

@end

NS_ASSUME_NONNULL_END
