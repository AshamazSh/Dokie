//
//  DocumentFilesViewModel.h
//  Dokie
//
//  Created by Ashamaz Shidov on 21/12/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC/ReactiveObjC.h>

NS_ASSUME_NONNULL_BEGIN

@class CDDocument;
@class CDContent;

@interface DocumentFilesViewModel : NSObject

@property (nonatomic, strong, readonly) NSArray<CDContent *> *contentFiles;
@property (nonatomic, strong, readonly) CDDocument *document;

- (instancetype)initWithDocument:(CDDocument *)document;

- (RACSignal *)readDocument;
- (void)addFile;
- (void)editContentAtIndexPath:(NSIndexPath *)indexPath;
- (void)deleteContentAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;

@end

NS_ASSUME_NONNULL_END
