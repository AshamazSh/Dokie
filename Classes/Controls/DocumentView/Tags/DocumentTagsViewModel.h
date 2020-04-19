//
//  DocumentTagsViewModel.h
//  Dokie
//
//  Created by Ashamaz Shidov on 26/12/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC/ReactiveObjC.h>

NS_ASSUME_NONNULL_BEGIN

@class CDDocument;

@interface DocumentTagsViewModel : NSObject

@property (nonatomic, strong, readonly) NSArray<NSString *> *tags;

- (instancetype)initWithDocument:(CDDocument *)document;

- (RACSignal *)addTagWithText:(NSString *)text;
- (RACSignal *)removeTagAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
