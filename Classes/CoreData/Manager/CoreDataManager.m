//
//  CoreDataManager.m
//  Dokie
//
//  Created by Ashamaz Shidov on 16/03/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import "CoreDataManager.h"
#import "EncryptionManager.h"
#import "Logger.h"
#import "CoreDataInclude.h"
#import "AppDelegate.h"
#import "CoreDataScheduler.h"
#import "Constants.h"

@interface CoreDataManager ()

@property (nonatomic, strong) CoreDataScheduler *scheduler;
@property (nonatomic, strong) EncryptionManager *encryptionManager;
@property (nonatomic, strong) NSManagedObjectContext *objectContext;
@property (nonatomic, strong, readonly) NSNotificationCenter *notificationCenter;

@end

@implementation CoreDataManager

+ (instancetype)shared {
    static id toReturn = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        toReturn = [self new];
    });
    return toReturn;
}

- (void)setupWithEncryptionManager:(EncryptionManager *)encryptionManager managedObjectContext:(NSManagedObjectContext *)objectContext {
    ParameterAssert(encryptionManager);
    ParameterAssert(objectContext);

    self.encryptionManager = encryptionManager;
    self.objectContext = objectContext;
    [self setup];
}

- (void)setup {
    self.scheduler = [[CoreDataScheduler alloc] initWithManagedObjectContext:self.objectContext];
}

- (void)reset {
    self.encryptionManager = nil;
    self.objectContext = nil;
    self.scheduler = nil;
}

- (RACSignal *)changeCurrentPassword:(NSString *)password to:(NSString *)newPassword {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        return [self.scheduler scheduleWithResult:^(BOOL success) {
            @strongify(self);
            if (![self.encryptionManager checkPassword:password]) {
                NSError *error = [NSError errorWithDomain:DokieErrorDomain code:999 userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Invalid password", @"Invalid password error text.")}];
                [subscriber sendError:error];
            }
            else if (![self.encryptionManager changeToNewPassword:newPassword]) {
                NSError *error = [NSError errorWithDomain:DokieErrorDomain code:999 userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Some error occured. Please try again later.", @"Some error occured error text.")}];
                [subscriber sendError:error];
            }
            else {
                [subscriber sendCompleted];
            }
        }];
    }];
}

#pragma mark - READ

- (RACSignal<NSString *> *)folderName:(CDFolder *)folder {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        return [self.scheduler scheduleWithResult:^(BOOL success) {
            @strongify(self);
            if (!folder) {
                [subscriber sendNext:NSLocalizedString(@"Root", @"Root folder title")];
                [subscriber sendCompleted];
            }
            else {
                NSError *currentError;
                NSDictionary *json = [self.encryptionManager decryptedJsonFromData:folder.data parsingError:&currentError];
                if (currentError) {
                    [subscriber sendError:currentError];
                }
                else {
                    [subscriber sendNext:[self folderNameFromJson:json] ?: @""];
                    [subscriber sendCompleted];
                }
            }
        }];
    }];
}

- (RACSignal<NSArray<RACTuple *> *> *)subfolderNamesInFolder:(CDFolder *)folder {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        return [self.scheduler scheduleWithResult:^(BOOL success) {
            @strongify(self);
            if (!folder) {
                NSPredicate *rootFolders = [NSPredicate predicateWithFormat:@"%K == NULL", CDFolder.kParentFolder];
                NSEntityDescription *entityDescription = [NSEntityDescription entityForName:CDFolder.entity.name inManagedObjectContext:self.objectContext];
                NSFetchRequest *request = [[NSFetchRequest alloc] init];
                [request setEntity:entityDescription];
                [request setReturnsObjectsAsFaults:NO];
                [request setPredicate:rootFolders];
                
                NSError *error;
                NSArray *fetchedItems = [self.objectContext executeFetchRequest:request error:&error];
                if (error) {
                    [subscriber sendError:error];
                }
                else {
                    NSMutableArray<RACTuple *> *names = [NSMutableArray array];
                    for (CDFolder *subfolder in fetchedItems) {
                        NSError *currentError;
                        NSDictionary *json = [self.encryptionManager decryptedJsonFromData:subfolder.data parsingError:&currentError];
                        if (currentError) {
                            [names addObject:RACTuplePack(subfolder, @"", currentError)];
                        }
                        else {
                            [names addObject:RACTuplePack(subfolder, [self folderNameFromJson:json] ?: @"", nil)];
                        }
                    }
                    [subscriber sendNext:[names copy]];
                    [subscriber sendCompleted];
                }
            }
            else {
                [self fetchObjectsIfNeededFromSet:folder.subfolders entityName:CDFolder.entity.name inContext:self.objectContext];
            
                NSMutableArray<RACTuple *> *names = [NSMutableArray array];
                for (CDFolder *subfolder in folder.subfolders) {
                    NSError *currentError;
                    NSDictionary *json = [self.encryptionManager decryptedJsonFromData:subfolder.data parsingError:&currentError];
                    if (currentError) {
                        [names addObject:RACTuplePack(subfolder, @"", currentError)];
                    }
                    else {
                        [names addObject:RACTuplePack(subfolder, [self folderNameFromJson:json] ?: @"", nil)];
                    }
                }
                [subscriber sendNext:[names copy]];
                [subscriber sendCompleted];
            }
        }];
    }];
}

- (RACSignal<NSArray<RACTuple *> *> *)documentNamesInFolder:(CDFolder *)folder {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        return [self.scheduler scheduleWithResult:^(BOOL success) {
            @strongify(self);
            if (!folder) {
                NSPredicate *rootDocuments = [NSPredicate predicateWithFormat:@"%K == NULL", CDDocument.kFolder];
                NSEntityDescription *entityDescription = [NSEntityDescription entityForName:CDDocument.entity.name inManagedObjectContext:self.objectContext];
                NSFetchRequest *request = [[NSFetchRequest alloc] init];
                [request setEntity:entityDescription];
                [request setReturnsObjectsAsFaults:NO];
                [request setPredicate:rootDocuments];
                
                NSError *error;
                NSArray *fetchedItems = [self.objectContext executeFetchRequest:request error:&error];
                if (error) {
                    [subscriber sendError:error];
                }
                else {
                    NSMutableArray<RACTuple *> *names = [NSMutableArray array];
                    for (CDDocument *document in fetchedItems) {
                        NSError *currentError;
                        NSDictionary *json = [self.encryptionManager decryptedJsonFromData:document.data parsingError:&currentError];
                        if (currentError) {
                            [names addObject:RACTuplePack(document, @"", currentError)];
                        }
                        else {
                            [names addObject:RACTuplePack(document, [self documentNameFromJson:json] ?: @"", nil)];
                        }
                    }
                    [subscriber sendNext:[names copy]];
                    [subscriber sendCompleted];
                }
            }
            else {
                [self fetchObjectsIfNeededFromSet:folder.documents entityName:CDDocument.entity.name inContext:self.objectContext];
                
                NSMutableArray<RACTuple *> *names = [NSMutableArray array];
                for (CDDocument *document in folder.documents) {
                    NSError *currentError;
                    NSDictionary *json = [self.encryptionManager decryptedJsonFromData:document.data parsingError:&currentError];
                    if (currentError) {
                        [names addObject:RACTuplePack(document, @"", currentError)];
                    }
                    else {
                        [names addObject:RACTuplePack(document, [self documentNameFromJson:json] ?: @"", nil)];
                    }
                }
                [subscriber sendNext:[names copy]];
                [subscriber sendCompleted];
            }
        }];
    }];
}

- (RACSignal<NSArray<RACTuple *> *> *)decryptedDocument:(CDDocument *)document {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        return [self.scheduler scheduleWithResult:^(BOOL success) {
            @strongify(self);
            [self fetchObjectsIfNeededFromSet:document.content.set entityName:CDContent.entity.name inContext:self.objectContext];

            NSMutableArray<RACTuple *> *decrypted = [NSMutableArray array];
            for (NSInteger i = 0; i < document.content.count; ++i) {
                CDContent *content = document.content[i];
                NSError *currentError;
                NSDictionary *json = [self.encryptionManager decryptedJsonFromData:content.data parsingError:&currentError];
                if (currentError) {
                    [decrypted addObject:RACTuplePack(document, @{}, currentError)];
                }
                else {
                    [decrypted addObject:RACTuplePack(document, json ?: @{}, nil)];
                }
            }
            [subscriber sendNext:[decrypted copy]];
            [subscriber sendCompleted];
        }];
    }];
}

- (RACSignal<NSDictionary<NSString *, id> *> *)decryptedContent:(CDContent *)content {
    @weakify(self);
    if (!self.encryptionManager.isValid) {
        return [RACSignal return:nil];
    }
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        return [self.scheduler scheduleWithResult:^(BOOL success) {
            @strongify(self);
            NSError *currentError;
            NSDictionary<NSString *, id> *json = [self.encryptionManager decryptedJsonFromData:content.data parsingError:&currentError];
            if (currentError) {
                [subscriber sendError:currentError];
            }
            else {
                [subscriber sendNext:json];
                [subscriber sendCompleted];
            }
        }];
    }];
}

- (RACSignal<UIImage *> *)imageFromContent:(CDContent *)content {
    @weakify(self);
    return [[self decryptedContent:content]
            flattenMap:^__kindof RACSignal * _Nullable(NSDictionary<NSString *,id> *json) {
        @strongify(self);
        if ([json[kContentTypeKey] isEqual:kContentTypeFile]) {
            NSString *fileId = json[kContentFileIdKey];
            NSError *error;
            NSArray<CDFile *> *objects = [self allObjectsForContext:self.objectContext withPredicate:[NSPredicate predicateWithFormat:@"%K == %@", CDFile.kIdentifier, fileId] withClassName:CDFile.entity.name error:&error];
            if (error) {
                return [RACSignal error:error];
            }
            else {
                CDFile *file = objects.firstObject;
                NSData *data = [self.encryptionManager decryptedData:file.data];
                return [RACSignal return:data ? [UIImage imageWithData:data] : nil];
            }
        }
        else {
            return [RACSignal return:nil];
        }
    }];
}

#pragma mark - WRITE

- (RACSignal<CDFolder *> *)createSubfolderInFolder:(CDFolder *)folder named:(NSString *)subfolderName {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        return [self.scheduler scheduleWithResult:^(BOOL success) {
            @strongify(self);
            CDFolder *subfolder = [NSEntityDescription insertNewObjectForEntityForName:CDFolder.entity.name inManagedObjectContext:self.objectContext];
            NSError *error;
            NSData *data = [self.encryptionManager encryptedJsonFromDictionary:@{kFolderNameKey : subfolderName ?: @""} parsingError:&error];
            if (error) {
                [subscriber sendError:error];
            }
            else {
                subfolder.data = data;
                subfolder.date = [NSDate date];
                subfolder.parentFolder = folder;
                NSError *saveError;
                [self.objectContext save:&saveError];
                if (saveError) {
                    [self.objectContext rollback];
                    [subscriber sendError:saveError];
                }
                else {
                    [self.notificationCenter postNotificationName:kReloadFolderNotification object:folder];
                    [subscriber sendNext:subfolder];
                    [subscriber sendCompleted];
                }
            }
        }];
    }];
}

- (RACSignal<CDFolder *> *)renameFolder:(CDFolder *)folder to:(NSString *)folderName {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        return [self.scheduler scheduleWithResult:^(BOOL success) {
            @strongify(self);
            NSError *error;
            NSData *data = [self.encryptionManager encryptedJsonFromDictionary:@{kFolderNameKey : folderName ?: @""} parsingError:&error];
            if (error) {
                [subscriber sendError:error];
            }
            else {
                folder.data = data;
                NSError *saveError;
                [self.objectContext save:&saveError];
                if (saveError) {
                    [self.objectContext rollback];
                    [subscriber sendError:saveError];
                }
                else {
                    [self.notificationCenter postNotificationName:kReloadFolderNotification object:folder.parentFolder];
                    [subscriber sendNext:folder];
                    [subscriber sendCompleted];
                }
            }
        }];
    }];
}

- (NSArray<CDDocument *> *)allDocumentsInFolder:(CDFolder *)folder {
    NSMutableArray *toReturn = [NSMutableArray array];

    [self fetchObjectsIfNeededFromSet:folder.subfolders entityName:CDFolder.entity.name];
    for (CDFolder *subfolder in folder.subfolders) {
        [toReturn addObjectsFromArray:[self allDocumentsInFolder:subfolder]];
    }
    
    [self fetchObjectsIfNeededFromSet:folder.documents entityName:CDDocument.entity.name];
    if (folder.documents.count > 0) {
        [toReturn addObjectsFromArray:folder.documents.allObjects];
    }
    return [toReturn copy];
}

- (NSArray<CDDocument *> *)allSubfoldersInFolder:(CDFolder *)folder {
    NSMutableArray *toReturn = [NSMutableArray array];

    [self fetchObjectsIfNeededFromSet:folder.subfolders entityName:CDFolder.entity.name];
    for (CDFolder *subfolder in folder.subfolders) {
        [toReturn addObjectsFromArray:[self allSubfoldersInFolder:subfolder]];
    }
    if (folder.subfolders.count > 0) {
        [toReturn addObjectsFromArray:folder.subfolders.allObjects];
    }
    return [toReturn copy];
}

- (RACSignal<CDFolder *> *)deleteFolder:(CDFolder *)folder {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        return [self.scheduler scheduleWithResult:^(BOOL success) {
            @strongify(self);
            NSArray *allDocuments = [self allDocumentsInFolder:folder];
            for (CDDocument *document in allDocuments) {
                NSError *error;
                [self deleteDocumentContent:document error:&error];
                if (error) {
                    [self.objectContext rollback];
                    [subscriber sendError:error];
                    return;
                }
                [self.objectContext deleteObject:document];
            }
            NSArray *allFolders = [self allSubfoldersInFolder:folder];
            for (CDFolder *subfolder in allFolders) {
                [self.objectContext deleteObject:subfolder];
            }
            
            CDFolder *parent = folder.parentFolder;
            [self.objectContext deleteObject:folder];
            NSError *saveError;
            [self.objectContext save:&saveError];
            if (saveError) {
                [self.objectContext rollback];
                [subscriber sendError:saveError];
            }
            else {
                [self.notificationCenter postNotificationName:kReloadFolderNotification object:parent];
                [subscriber sendCompleted];
            }
        }];
    }];
}

- (RACSignal<CDDocument *> *)createDocumentInFolder:(CDFolder *)folder named:(NSString *)documentName {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        return [self.scheduler scheduleWithResult:^(BOOL success) {
            @strongify(self);
            CDDocument *document = [NSEntityDescription insertNewObjectForEntityForName:CDDocument.entity.name inManagedObjectContext:self.objectContext];
            NSError *error;
            NSData *data = [self.encryptionManager encryptedJsonFromDictionary:@{kDocumentNameKey : documentName ?: @""} parsingError:&error];
            if (error) {
                [subscriber sendError:error];
            }
            else {
                document.data = data;
                document.date = [NSDate date];
                document.folder = folder;
                NSError *saveError;
                [self.objectContext save:&saveError];
                if (saveError) {
                    [self.objectContext rollback];
                    [subscriber sendError:saveError];
                }
                else {
                    [self.notificationCenter postNotificationName:kReloadFolderNotification object:folder];
                    [subscriber sendNext:document];
                    [subscriber sendCompleted];
                }
            }
        }];
    }];
}

- (RACSignal<CDDocument *> *)renameDocument:(CDDocument *)document to:(NSString *)documentName {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        return [self.scheduler scheduleWithResult:^(BOOL success) {
            @strongify(self);
            NSError *error;
            NSData *data = [self.encryptionManager encryptedJsonFromDictionary:@{kDocumentNameKey : documentName ?: @""} parsingError:&error];
            if (error) {
                [subscriber sendError:error];
            }
            else {
                document.data = data;
                NSError *saveError;
                [self.objectContext save:&saveError];
                if (saveError) {
                    [self.objectContext rollback];
                    [subscriber sendError:saveError];
                }
                else {
                    [self.notificationCenter postNotificationName:kReloadFolderNotification object:document.folder];
                    [subscriber sendNext:document];
                    [subscriber sendCompleted];
                }
            }
        }];
    }];
}

- (void)deleteDocumentContent:(CDDocument *)document error:(NSError *__autoreleasing *)error {
    [self fetchObjectsIfNeededFromSet:document.content.set entityName:CDContent.entity.name];
    for (CDContent *content in document.content) {
        NSError *currentError;
        [self deleteContentFiles:content error:&currentError];
        if (currentError) {
            if (error) {
                *error = currentError;
                return;
            }
        }
        [self.objectContext deleteObject:content];
    }
}

- (RACSignal *)deleteDocument:(CDDocument *)document {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        return [self.scheduler scheduleWithResult:^(BOOL success) {
            @strongify(self);
            NSError *error;
            [self deleteDocumentContent:document error:&error];
            if (error) {
                [self.objectContext rollback];
                [subscriber sendError:error];
            }
            else {
                CDFolder *folder = document.folder;
                [self.objectContext deleteObject:document];
                NSError *saveError;
                [self.objectContext save:&saveError];
                if (saveError) {
                    [self.objectContext rollback];
                    [subscriber sendError:saveError];
                }
                else {
                    [self.notificationCenter postNotificationName:kReloadFolderNotification object:folder];
                    [subscriber sendCompleted];
                }
            }
        }];
    }];
}

- (RACSignal<NSString *> *)documentName:(CDDocument *)document {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        return [self.scheduler scheduleWithResult:^(BOOL success) {
            @strongify(self);
            NSError *currentError;
            NSDictionary *json = [self.encryptionManager decryptedJsonFromData:document.data parsingError:&currentError];
            if (currentError) {
                [subscriber sendError:currentError];
            }
            else {
                [subscriber sendNext:[self documentNameFromJson:json] ?: @""];
                [subscriber sendCompleted];
            }
        }];
    }];
}

- (RACSignal<CDFile *> *)createFileWithContent:(NSData *)fileContent {
    if (!fileContent) {
        return [RACSignal return:nil];
    }
    
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        return [self.scheduler scheduleWithResult:^(BOOL success) {
            @strongify(self);
            CDFile *file = [NSEntityDescription insertNewObjectForEntityForName:CDFile.entity.name inManagedObjectContext:self.objectContext];
            NSData *data = [self.encryptionManager encryptedData:fileContent];
            file.data = data;
            file.identifier = [[NSUUID UUID] UUIDString];
            NSError *saveError;
            [self.objectContext save:&saveError];
            if (saveError) {
                [self.objectContext rollback];
                [subscriber sendError:saveError];
            }
            else {
                [subscriber sendNext:file];
                [subscriber sendCompleted];
            }
        }];
    }];
}

- (RACSignal<CDContent *> *)addContentToDocument:(CDDocument *)document withDictionary:(NSDictionary *)dictionary {
    if (!document) {
        return [RACSignal empty];
    }
    
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        return [self.scheduler scheduleWithResult:^(BOOL success) {
            @strongify(self);
            CDContent *content = [NSEntityDescription insertNewObjectForEntityForName:CDContent.entity.name inManagedObjectContext:self.objectContext];
            NSError *error;
            NSData *data = [self.encryptionManager encryptedJsonFromDictionary:dictionary parsingError:&error];
            if (error) {
                [subscriber sendError:error];
            }
            else {
                content.data = data;
                content.document = document;
                NSError *saveError;
                [self.objectContext save:&saveError];
                if (saveError) {
                    [self.objectContext rollback];
                    [subscriber sendError:saveError];
                }
                else {
                    [subscriber sendNext:content];
                    [subscriber sendCompleted];
                }
            }
        }];
    }];
}

- (RACSignal<CDContent *> *)updateContent:(CDContent *)content withDictionary:(NSDictionary *)dictionary {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        return [self.scheduler scheduleWithResult:^(BOOL success) {
            @strongify(self);
            NSError *error;
            NSData *data = [self.encryptionManager encryptedJsonFromDictionary:dictionary parsingError:&error];
            if (error) {
                [subscriber sendError:error];
            }
            else {
                content.data = data;
                NSError *saveError;
                [self.objectContext save:&saveError];
                if (saveError) {
                    [self.objectContext rollback];
                    [subscriber sendError:saveError];
                }
                else {
                    [subscriber sendNext:content];
                    [subscriber sendCompleted];
                }
            }
        }];
    }];
}

- (void)deleteContentFiles:(CDContent *)content error:(NSError *__autoreleasing *)error {
    NSError *currentError;
    NSDictionary *json = [self.encryptionManager decryptedJsonFromData:content.data parsingError:&currentError];
    if (currentError) {
        if (error) {
            *error = currentError;
            return;
        }
    }
    
    if ([json[kContentTypeKey] isEqual:kContentTypeFile]) {
        NSString *fileId = json[kContentTypeFile];
        NSError *currentError;
        NSArray<CDFile *> *objects = [self allObjectsForContext:self.objectContext withPredicate:[NSPredicate predicateWithFormat:@"%K == %@", CDFile.kIdentifier, fileId] withClassName:CDFile.entity.name error:&currentError];
        if (currentError) {
            if (error) {
                *error = currentError;
                return;
            }
        }
        
        CDFile *file = objects.firstObject;
        if (file) {
            [self.objectContext deleteObject:file];
        }
    }
}

- (RACSignal *)deleteContent:(CDContent *)content {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        return [self.scheduler scheduleWithResult:^(BOOL success) {
            @strongify(self);
            NSError *error;
            [self deleteContentFiles:content error:&error];
            if (error) {
                [subscriber sendError:error];
            }
            else {
                [self.objectContext deleteObject:content];
                NSError *saveError;
                [self.objectContext save:&saveError];
                if (saveError) {
                    [self.objectContext rollback];
                    [subscriber sendError:saveError];
                }
                [subscriber sendCompleted];
            }
        }];
    }];
}

- (RACSignal<CDTag *> *)addTagToDocument:(CDDocument *)document withText:(NSString *)text {
    if (!document) {
        return [RACSignal empty];
    }
    
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        return [self.scheduler scheduleWithResult:^(BOOL success) {
            @strongify(self);
            CDTag *tag = [NSEntityDescription insertNewObjectForEntityForName:CDTag.entity.name inManagedObjectContext:self.objectContext];
            tag.text = text;
            tag.document = document;
            NSError *saveError;
            [self.objectContext save:&saveError];
            if (saveError) {
                [self.objectContext rollback];
                [subscriber sendError:saveError];
            }
            else {
                [subscriber sendNext:tag];
                [subscriber sendCompleted];
            }
        }];
    }];
}

- (RACSignal<CDTag *> *)renameTag:(CDTag *)tag to:(NSString *)text {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        return [self.scheduler scheduleWithResult:^(BOOL success) {
            @strongify(self);
            tag.text = text;
            NSError *saveError;
            [self.objectContext save:&saveError];
            if (saveError) {
                [self.objectContext rollback];
                [subscriber sendError:saveError];
            }
            else {
                [subscriber sendNext:tag];
                [subscriber sendCompleted];
            }
        }];
    }];
}

- (NSSet *)fetchObjectsIfNeededFromSet:(NSSet *)objectsSet entityName:(NSString *)entityName {
    return [self fetchObjectsIfNeededFromSet:objectsSet entityName:entityName inContext:self.objectContext];
}

#pragma mark - Private
- (NSSet *)fetchObjectsIfNeededFromSet:(NSSet *)objectsSet entityName:(NSString *)entityName inContext:(NSManagedObjectContext *)context {
    ParameterAssert(context);
    ParameterAssert(entityName);
    
    if (!context || objectsSet.count == 0) {
        return nil;
    }
    
    if (!entityName) {
        return objectsSet;
    }
    
    NSMutableSet *persistantObjects = [NSMutableSet set];
    NSMutableSet *inMemoryObjects = [NSMutableSet set];
    NSMutableSet *persistantObjectIds = [NSMutableSet set];
    for (NSManagedObject *object in objectsSet) {
        if (!object.objectID.isTemporaryID) {
            [persistantObjects addObject:object];
            [persistantObjectIds addObject:object.objectID];
        }
        else {
            [inMemoryObjects addObject:object];
        }
    }
    if (persistantObjects.count == 0) {
        return objectsSet;
    }
    
    BOOL fetchFromDB = NO;
    for (NSManagedObject *object in persistantObjects) {
        if (object.isFault) {
            fetchFromDB = YES;
            break;
        }
    }
    
    if (fetchFromDB) {
        BOOL executeOnContextQueue = NO;
        NSManagedObjectContext *contextForFetch = context;
        if (contextForFetch.parentContext) {
            while (contextForFetch.parentContext) {
                contextForFetch = contextForFetch.parentContext;
            }
            
            if (contextForFetch.concurrencyType != NSMainQueueConcurrencyType || context.concurrencyType != NSMainQueueConcurrencyType) {
                executeOnContextQueue = YES;
            }
        }
        
        NSArray *(^executionBlock)(void) = ^NSArray *(){
            NSEntityDescription *entityDescription = [NSEntityDescription entityForName:entityName inManagedObjectContext:contextForFetch];
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            [request setEntity:entityDescription];
            [request setReturnsObjectsAsFaults:NO];
            [request setPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", objectsSet]];
            
            NSError *error;
            NSArray *fetchedItems = [contextForFetch executeFetchRequest:request error:&error];
            if (error) {
                WriteLog(kLogTypeCrash, @"Some error occured. Error: %@", error.localizedDescription);
                return nil;
            }
            return fetchedItems;
        };
        
        NSArray *toReturn;
        
        if (context.parentContext) {
            __block NSArray *objectIds;
            NSArray *(^objectIdsFromObjects)(NSArray *) = ^NSArray *(NSArray *objects) {
                NSMutableArray *objectIdsMut = [NSMutableArray array];
                for (NSManagedObject *object in objects) {
                    [objectIdsMut addObject:object.objectID];
                }
                return [objectIdsMut copy];
            };
            
            if (executeOnContextQueue) {
                [contextForFetch performBlockAndWait:^{
                    objectIds = objectIdsFromObjects(executionBlock());
                }];
            }
            else {
                objectIds = objectIdsFromObjects(executionBlock());
            }
            
            NSMutableArray *toReturnMut = [NSMutableArray array];
            NSError *error;
            for (NSManagedObjectID *objectId in objectIds) {
                error = nil;
                NSManagedObject *object = [context existingObjectWithID:objectId error:&error];
                if (error) {
                    WriteLog(kLogTypeCrash, @"Can't retrieve object from DB. Error: %@", error.localizedDescription);
                }
                if (object) {
                    [toReturnMut addObject:object];
                }
            }
            toReturn = [toReturnMut copy];
        }
        else {
            toReturn = executionBlock();
        }
        
        if (toReturn) {
            [inMemoryObjects addObjectsFromArray:toReturn];
        }
        if (inMemoryObjects.count == 0) {
            return nil;
        }
        return [inMemoryObjects copy];
    }
    return objectsSet;
}

- (NSArray *)allObjectsForContext:(NSManagedObjectContext *)context withClassName:(NSString *)className error:(NSError *__autoreleasing *)error {
    return [self allObjectsForContext:context withPredicate:nil withClassName:className error:error];
}

- (NSArray *)allObjectsForContext:(NSManagedObjectContext *)context withPredicate:(NSPredicate *)predicate withClassName:(NSString *)className error:(NSError *__autoreleasing *)error {
    return [self allObjectsForContext:context withPredicate:predicate withClassName:className withSortDescriptors:nil error:error];
}

- (NSArray *)allObjectsForContext:(NSManagedObjectContext *)context withPredicate:(NSPredicate *)predicate withClassName:(NSString *)className withSortDescriptors:(NSArray *)sortDescriptors error:(NSError *__autoreleasing *)error {
    ParameterAssert(context);
    ParameterAssert(className && [className length] > 0);
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:className inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    [request setReturnsObjectsAsFaults:NO];
    
    if (predicate) {
        [request setPredicate:predicate];
    }
    
    if (sortDescriptors && [sortDescriptors count] > 0) {
        [request setSortDescriptors:sortDescriptors];
    }
    
    NSError *currentError;
    NSArray *array = [context executeFetchRequest:request error:&currentError];
    if (currentError) {
        if (error) {
            *error = currentError;
        }
        return nil;
    }
    return array;
}

- (NSString *)folderNameFromJson:(NSDictionary *)json {
    return json[kFolderNameKey];
}

- (NSString *)documentNameFromJson:(NSDictionary *)json {
    return json[kDocumentNameKey];
}

#pragma mark -

- (NSNotificationCenter *)notificationCenter {
    return [NSNotificationCenter defaultCenter];
}

@end
