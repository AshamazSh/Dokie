//
//  Logger.m
//  Dokie
//
//  Created by Ashamaz Shidov on 24/02/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import "Logger.h"

@interface Logger ()

@end

@implementation Logger

void WriteLogWithType(LogType type, NSString* format, ...){
    va_list ap;
    va_start(ap, format);
    
    NSString *string = [[NSString alloc] initWithFormat:format arguments:ap];
    if ([string length] > 1000) {
        string = [string substringToIndex:1000];
    }
    
#ifdef DEBUG
    NSLog(@"[%d], %@", (int)type, string);
#endif
    
    va_end(ap);
    
#ifdef DEBUG
    if (type == kLogTypeCrash) {
        abort();
    }
#endif
}

@end
