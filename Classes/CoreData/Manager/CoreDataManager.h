//
//  CoreDataManager.h
//  Dokie
//
//  Created by Ashamaz Shidov on 16/03/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <ReactiveObjC/ReactiveObjC.h>

NS_ASSUME_NONNULL_BEGIN

@class EncryptionManager;
@class CDFolder;
@class CDContent;
@class CDDocument;
@class CDTag;
@class CDFile;

@interface CoreDataManager : NSObject

+ (instancetype)shared;

- (void)setupWithEncryptionManager:(EncryptionManager *)encryptionManager managedObjectContext:(NSManagedObjectContext *)objectContext;
- (void)reset;

- (RACSignal *)changeCurrentPassword:(NSString *)password to:(NSString *)newPassword;

#pragma mark - READ
- (NSSet *)fetchObjectsIfNeededFromSet:(NSSet *)objectsSet entityName:(NSString *)entityName;

- (RACSignal<NSString *> *)folderName:(CDFolder *)folder;
- (RACSignal<NSArray<RACTuple *> *> *)subfolderNamesInFolder:(CDFolder *)folder;
- (RACSignal<NSArray<RACTuple *> *> *)documentNamesInFolder:(CDFolder *)folder;
- (RACSignal<NSArray<RACTuple *> *> *)decryptedDocument:(CDDocument *)document;
- (RACSignal<NSDictionary<NSString *, id> *> *)decryptedContent:(CDContent *)content;
- (RACSignal<UIImage *> *)imageFromContent:(CDContent *)content;

#pragma mark - WRITE
- (RACSignal<CDFolder *> *)createSubfolderInFolder:(CDFolder *)folder named:(NSString *)subfolderName;
- (RACSignal<CDFolder *> *)renameFolder:(CDFolder *)folder to:(NSString *)folderName;
- (RACSignal *)deleteFolder:(CDFolder *)folder;

- (RACSignal<CDDocument *> *)createDocumentInFolder:(CDFolder *)folder named:(NSString *)documentName;
- (RACSignal<CDDocument *> *)renameDocument:(CDDocument *)document to:(NSString *)documentName;
- (RACSignal *)deleteDocument:(CDDocument *)document;
- (RACSignal<NSString *> *)documentName:(CDDocument *)document;

- (RACSignal<CDFile *> *)createFileWithContent:(NSData *)fileContent;

- (RACSignal<CDContent *> *)addContentToDocument:(CDDocument *)document withDictionary:(NSDictionary *)dictionary;
- (RACSignal<CDContent *> *)updateContent:(CDContent *)content withDictionary:(NSDictionary *)dictionary;
- (RACSignal *)deleteContent:(CDContent *)content;

- (RACSignal<CDTag *> *)addTagToDocument:(CDDocument *)document withText:(NSString *)text;
- (RACSignal<CDTag *> *)renameTag:(CDTag *)tag to:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
