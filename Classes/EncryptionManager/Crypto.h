//
//  Crypto.h
//  Dokie
//
//  Created by Ashamaz Shidov on 31.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Crypto : NSObject

@property (nonatomic, strong, readonly) NSString *key;

- (instancetype)initWithKey:(NSString *)key;
- (NSData * _Nullable)encrypt:(NSData *)data;
- (NSData * _Nullable)decrypt:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
