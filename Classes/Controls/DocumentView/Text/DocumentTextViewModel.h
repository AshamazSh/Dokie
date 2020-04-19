//
//  DocumentTextViewModel.h
//  Dokie
//
//  Created by Ashamaz Shidov on 21/12/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC/ReactiveObjC.h>

NS_ASSUME_NONNULL_BEGIN

@class CDDocument;

@interface DocumentTextViewModel : NSObject

@property (nonatomic, strong, readonly) NSArray<RACTuple *> *content;
@property (nonatomic, strong, readonly) RACSubject *copyedToClipboardSubject;

- (instancetype)initWithDocument:(CDDocument *)document;
- (void)addContent;
- (void)didSelectTextAtIndexPath:(NSIndexPath *)indexPath;
- (void)deleteContentAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;
- (void)editContentAtIndexPath:(NSIndexPath *)indexPath;
- (RACSignal *)readDocument;

@end

NS_ASSUME_NONNULL_END
