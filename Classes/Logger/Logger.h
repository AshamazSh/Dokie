//
//  Logger.h
//  Dokie
//
//  Created by Ashamaz Shidov on 24/02/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import <Foundation/Foundation.h>

#define WriteLog(__LOG_TYPE__, __FORMAT__, ...) WriteLogWithType(__LOG_TYPE__, (@"%s line %d " __FORMAT__), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

#define Assert(condition, desc, ...)    \
    do {                \
        if (!(condition)) {        \
            WriteLog(kLogTypeCrash, desc, ##__VA_ARGS__); \
        }                \
    } while(0)

#define ParameterAssert(condition) Assert((condition), @"Invalid parameter not satisfying: %s", #condition)

typedef NS_ENUM(NSInteger, LogType) {
    kLogTypeMessage = 0,
    kLogTypeDebug = 1,
    kLogTypeNetworking = 2,
    kLogTypeCrash = 3
};

NS_ASSUME_NONNULL_BEGIN

@interface Logger : NSObject

void WriteLogWithType(LogType type, NSString* format, ...) NS_FORMAT_FUNCTION(2,3);

@end

NS_ASSUME_NONNULL_END
