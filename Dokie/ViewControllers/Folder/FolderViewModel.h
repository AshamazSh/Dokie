//
//  FolderViewModel.h
//  Dokie
//
//  Created by Ashamaz Shidov on 28/12/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC/ReactiveObjC.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CDFolder;

@interface FolderViewModel : NSObject

@property (nonatomic, strong, readonly) NSString *folderName;
@property (nonatomic, strong, readonly) NSArray<NSString *> *subfolders;
@property (nonatomic, strong, readonly) NSArray<NSString *> *documents;
@property (nonatomic, readonly) BOOL showMenuNavButton;

- (instancetype)initWithFolder:(CDFolder *)folder;

- (void)addButtonPressed;

- (void)longPressedSubfolderAtIndexPath:(NSIndexPath *)indexPath;
- (void)longPressedDocumentAtIndexPath:(NSIndexPath *)indexPath;

- (void)renameSubfolderAtIndexPath:(NSIndexPath *)indexPath;
- (void)renameDocumentAtIndexPath:(NSIndexPath *)indexPath;

- (void)deleteSubfolderAtIndexPath:(NSIndexPath *)indexPath;
- (void)deleteDocumentAtIndexPath:(NSIndexPath *)indexPath;

- (void)didSelectSubfolderAtIndexPath:(NSIndexPath *)indexPath;
- (void)didSelectDocumentAtIndexPath:(NSIndexPath *)indexPath;

- (void)menuPressed;

@end

NS_ASSUME_NONNULL_END
