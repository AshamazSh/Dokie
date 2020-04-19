//
//  DocumentImagesPageViewModel.h
//  Dokie
//
//  Created by Ashamaz Shidov on 26.01.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CDContent;

@interface DocumentImagesPageViewModel : NSObject

@property (nonatomic, strong, readonly) NSArray<CDContent *> *contentImages;
@property (nonatomic, readonly) NSInteger firstIndex;

- (instancetype)initWithContentImages:(NSArray<CDContent *> *)contentImages firstIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
