//
//  DocumentViewModel.h
//  Dokie
//
//  Created by Ashamaz Shidov on 28/12/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC/ReactiveObjC.h>

NS_ASSUME_NONNULL_BEGIN

@class CDDocument;
@class CDContent;
@class DocumentFilesViewModel;
@class DocumentTextViewModel;

@interface DocumentViewModel : NSObject

@property (nonatomic, strong, readonly) DocumentFilesViewModel *filesViewModel;
@property (nonatomic, strong, readonly) DocumentTextViewModel *textViewModel;
@property (nonatomic, strong, readonly) NSString *documentName;

- (instancetype)initWithDocument:(CDDocument *)document;
- (void)addButtonPressed;
- (void)shareText:(NSArray<NSString *> *)texts images:(NSArray<CDContent *> *)images;

@end

NS_ASSUME_NONNULL_END
