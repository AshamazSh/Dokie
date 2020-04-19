//
//  FolderViewModel.m
//  Dokie
//
//  Created by Ashamaz Shidov on 28/12/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import "FolderViewModel.h"
#import "Logger.h"
#import "CoreDataInclude.h"
#import "Constants.h"
#import "CoreDataManager.h"
#import "NavigationRouter.h"

@interface FolderViewModel()

@property (nonatomic, strong) NSString *folderName;
@property (nonatomic, strong) CDFolder *folder;
@property (nonatomic, strong) NSArray<NSString *> *subfolders;
@property (nonatomic, strong) NSArray<CDFolder *> *subfolderObjects;
@property (nonatomic, strong) NSArray<NSString *> *documents;
@property (nonatomic, strong) NSArray<CDDocument *> *documentObjects;
@property (nonatomic) BOOL showMenuNavButton;

@property (nonatomic, strong, readonly) NSNotificationCenter *notificationCenter;
@property (nonatomic, strong, readonly) CoreDataManager *coreDataManager;
@property (nonatomic, strong, readonly) NavigationRouter *navigationRouter;

@end

@implementation FolderViewModel

- (instancetype)initWithFolder:(CDFolder *)folder {
    self = [super init];
    if (self) {
        self.folder = folder;
        [self setup];
    }
    return self;
}

- (void)setup {
    @weakify(self);
    [[[[self.notificationCenter rac_addObserverForName:kReloadFolderNotification object:nil]
       takeUntil:self.rac_willDeallocSignal]
      deliverOnMainThread]
     subscribeNext:^(NSNotification *notification) {
        @strongify(self);
        CDFolder *folder = notification.object;
        if ([folder isEqual:self.folder] || (!self.folder && !folder)) {
            [self readFolder];
        }
    }];
    [self readFolder];
    [[[self.coreDataManager folderName:self.folder] deliverOnMainThread] subscribeNext:^(NSString *folderName) {
        @strongify(self);
        self.folderName = folderName;
    }];
    self.showMenuNavButton = self.folder == nil;
}

- (void)addButtonPressed {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    @weakify(self);
    UIAlertAction *addFolder = [UIAlertAction actionWithTitle:NSLocalizedString(@"Add folder", @"Add folder button text in alert view") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        [self createSubfolder];
    }];
    [addFolder setValue:[[UIImage imageNamed:@"folder_small.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];
    [alert addAction:addFolder];
    UIAlertAction *addFile = [UIAlertAction actionWithTitle:NSLocalizedString(@"Add document", @"Add document button text in alert view") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        [self createDocument];
    }];
    [addFile setValue:[[UIImage imageNamed:@"file_small.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];
    [alert addAction:addFile];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button text in alert view") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self.navigationRouter showAlert:alert];
}

- (void)createSubfolder {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add folder", @"Add content alert title")
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = NSLocalizedString(@"Folder name", @"Folder name placeholder");
        textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    }];
    
    @weakify(self);
    UIAlertAction *save = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save", @"Save button text in alert view") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        UITextField *folderName = alert.textFields[0];
        [self createSubfolderWithName:folderName.text];
    }];
    [alert addAction:save];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button text in alert view") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self.navigationRouter showAlert:alert];
}

- (void)createSubfolderWithName:(NSString *)subfolderName {
    NSString *loadingGuid = [self.navigationRouter showLoading];
    @weakify(self);
    [[[self.coreDataManager createSubfolderInFolder:self.folder named:subfolderName]
      deliverOnMainThread]
     subscribeError:^(NSError * _Nullable error) {
        @strongify(self);
        [self.navigationRouter hideLoading:loadingGuid];
        [self.navigationRouter showAlertWithTitle:@"" message:NSLocalizedString(@"Can not create folder. Please try again later.", @"Can not create folder error alert.")];
    } completed:^{
        @strongify(self);
        [self.navigationRouter hideLoading:loadingGuid];
        [self readFolder];
    }];
}

- (void)createDocument {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add document", @"Add content alert title")
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = NSLocalizedString(@"Document name", @"Document name placeholder");
        textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    }];
    
    @weakify(self);
    UIAlertAction *save = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save", @"Save button text in alert view") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        UITextField *docName = alert.textFields[0];
        [self createDocumentWithName:docName.text];
    }];
    [alert addAction:save];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button text in alert view") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self.navigationRouter showAlert:alert];
}

- (void)createDocumentWithName:(NSString *)documentName {
    NSString *loadingGuid = [self.navigationRouter showLoading];
    @weakify(self);
    [[[self.coreDataManager createDocumentInFolder:self.folder named:documentName]
      deliverOnMainThread]
     subscribeNext:^(CDDocument *document) {
        @strongify(self);
        [self.navigationRouter hideLoading:loadingGuid];
        [self.navigationRouter pushDocument:document];
    }
     error:^(NSError * _Nullable error) {
        @strongify(self);
        [self.navigationRouter hideLoading:loadingGuid];
        [self.navigationRouter showAlertWithTitle:@"" message:NSLocalizedString(@"Can not create document. Please try again later.", @"Can not create folder error alert.")];
    }];
}

- (void)longPressedSubfolderAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.subfolders.count) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        @weakify(self);
        UIAlertAction *rename = [UIAlertAction actionWithTitle:NSLocalizedString(@"Rename", @"Rename button text in alert view") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            [self renameSubfolderAtIndexPath:indexPath];
        }];
        [alert addAction:rename];
        UIAlertAction *delete = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"Delete button text in alert view") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            [self deleteSubfolderAtIndexPath:indexPath];
        }];
        [alert addAction:delete];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button text in alert view") style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [self.navigationRouter showAlert:alert];
    }
}

- (void)longPressedDocumentAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.documents.count) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        @weakify(self);
        UIAlertAction *rename = [UIAlertAction actionWithTitle:NSLocalizedString(@"Rename", @"Rename button text in alert view") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            [self renameDocumentAtIndexPath:indexPath];
        }];
        [alert addAction:rename];
        UIAlertAction *delete = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"Delete button text in alert view") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            [self deleteDocumentAtIndexPath:indexPath];
        }];
        [alert addAction:delete];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button text in alert view") style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [self.navigationRouter showAlert:alert];
    }
}

- (void)renameSubfolderAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.subfolders.count) {
        NSString *currentName = self.subfolders[indexPath.row];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Rename folder", @"Rename folder alert title")
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = NSLocalizedString(@"Folder name", @"Folder name placeholder");
            textField.text = currentName;
            textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        }];
        
        @weakify(self);
        UIAlertAction *save = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save", @"Save button text in alert view") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            CDFolder *folder = self.subfolderObjects[indexPath.row];
            NSString *loadingGuid = [self.navigationRouter showLoading];
            UITextField *folderName = alert.textFields[0];
            [[[self.coreDataManager renameFolder:folder to:folderName.text]
              deliverOnMainThread]
             subscribeError:^(NSError * _Nullable error) {
                @strongify(self);
                [self.navigationRouter hideLoading:loadingGuid];
                [self.navigationRouter showAlertWithTitle:@"" message:NSLocalizedString(@"Can not rename folder. Please try again later.", @"Can not rename folder error alert.")];
            }
             completed:^{
                @strongify(self);
                [self readFolder];
                [self.navigationRouter hideLoading:loadingGuid];
            }];
        }];
        [alert addAction:save];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button text in alert view") style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [self.navigationRouter showAlert:alert];
    }
}

- (void)renameDocumentAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.documents.count) {
        NSString *currentName = self.documents[indexPath.row];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Rename document", @"Rename document alert title")
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = NSLocalizedString(@"Document name", @"Document name placeholder");
            textField.text = currentName;
            textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        }];
        
        @weakify(self);
        UIAlertAction *save = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save", @"Save button text in alert view") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            CDDocument *document = self.documentObjects[indexPath.row];
            NSString *loadingGuid = [self.navigationRouter showLoading];
            UITextField *docName = alert.textFields[0];
            [[[self.coreDataManager renameDocument:document to:docName.text]
              deliverOnMainThread]
             subscribeError:^(NSError * _Nullable error) {
                @strongify(self);
                [self.navigationRouter hideLoading:loadingGuid];
                [self.navigationRouter showAlertWithTitle:@"" message:NSLocalizedString(@"Can not rename folder. Please try again later.", @"Can not rename folder error alert.")];
            }
             completed:^{
                @strongify(self);
                [self readFolder];
                [self.navigationRouter hideLoading:loadingGuid];
            }];
        }];
        [alert addAction:save];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button text in alert view") style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [self.navigationRouter showAlert:alert];
    }
}

- (void)deleteSubfolderAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.subfolders.count) {
        NSString *loadingGuid = [self.navigationRouter showLoading];
        @weakify(self);
        [[[self.coreDataManager deleteFolder:self.subfolderObjects[indexPath.row]]
          deliverOnMainThread]
         subscribeError:^(NSError * _Nullable error) {
            @strongify(self);
            [self.navigationRouter hideLoading:loadingGuid];
            [self.navigationRouter showAlertWithTitle:@"" message:NSLocalizedString(@"Some error occured. Please try again later.", @"Try again later text")];
        }
         completed:^{
            @strongify(self);
            [self.navigationRouter hideLoading:loadingGuid];
        }];
    }
}

- (void)deleteDocumentAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.documents.count) {
        NSString *loadingGuid = [self.navigationRouter showLoading];
        @weakify(self);
        [[[self.coreDataManager deleteDocument:self.documentObjects[indexPath.row]]
          deliverOnMainThread]
         subscribeError:^(NSError * _Nullable error) {
            @strongify(self);
            [self.navigationRouter hideLoading:loadingGuid];
            [self.navigationRouter showAlertWithTitle:@"" message:NSLocalizedString(@"Some error occured. Please try again later.", @"Try again later text")];
        }
         completed:^{
            @strongify(self);
            [self.navigationRouter hideLoading:loadingGuid];
        }];
    }
}

- (void)didSelectSubfolderAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.subfolders.count) {
        CDFolder *folder = self.subfolderObjects[indexPath.row];
        [self.navigationRouter pushFolder:folder];
    }
}

- (void)didSelectDocumentAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.documents.count) {
        CDDocument *document = self.documentObjects[indexPath.row];
        [self.navigationRouter pushDocument:document];
    }
}

- (void)readFolder {
    @weakify(self);
    [[[RACSignal combineLatest:@[[self.coreDataManager subfolderNamesInFolder:self.folder],
                                 [self.coreDataManager documentNamesInFolder:self.folder]]]
      deliverOnMainThread]
     subscribeNext:^(RACTuple *tuple) {
        @strongify(self);
        RACTupleUnpack(NSArray<RACTuple *> *folders, NSArray<RACTuple *> *docs) = tuple;
        folders = [folders sortedArrayUsingComparator:^NSComparisonResult(RACTuple *obj1, RACTuple *obj2) {
            NSString *name1 = obj1.second;
            NSString *name2 = obj2.second;
            return [name1 localizedCompare:name2];
        }];
        docs = [docs sortedArrayUsingComparator:^NSComparisonResult(RACTuple *obj1, RACTuple *obj2) {
            NSString *name1 = obj1.second;
            NSString *name2 = obj2.second;
            return [name1 localizedCompare:name2];
        }];
        
        NSMutableArray<NSString *> *subfolders = [NSMutableArray array];
        NSMutableArray<NSString *> *subfolderObjects = [NSMutableArray array];
        for (NSInteger i = 0; i < folders.count; ++i) {
            RACTuple *tuple = folders[i];
            [subfolderObjects addObject:tuple.first];
            [subfolders addObject:tuple.second];
        }
        self.subfolders = [subfolders copy];
        self.subfolderObjects = [subfolderObjects copy];

        NSMutableArray<NSString *> *documents = [NSMutableArray array];
        NSMutableArray<NSString *> *documentObjects = [NSMutableArray array];
        for (NSInteger i = 0; i < docs.count; ++i) {
            RACTuple *tuple = docs[i];
            [documentObjects addObject:tuple.first];
            [documents addObject:tuple.second];
        }
        self.documents = [documents copy];
        self.documentObjects = [documentObjects copy];
    }
     error:^(NSError * _Nullable error) {
        @strongify(self);
        self.documents = nil;
        self.subfolderObjects = nil;
        [self.navigationRouter showAlertWithTitle:@"" message:NSLocalizedString(@"Read error. Please try again later", @"Read error alert text")];
    }];
}

- (void)menuPressed {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    @weakify(self);
    UIAlertAction *changePassword = [UIAlertAction actionWithTitle:NSLocalizedString(@"Change password", @"Change password button text in alert view") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        [self.navigationRouter showChangePassword];
    }];
    [alert addAction:changePassword];
    UIAlertAction *logout = [UIAlertAction actionWithTitle:NSLocalizedString(@"Logout", @"Logout button text in alert view") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        [self.navigationRouter logout];
    }];
    [alert addAction:logout];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button text in alert view") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self.navigationRouter showAlert:alert];
}

#pragma mark -

- (NSNotificationCenter *)notificationCenter {
    return [NSNotificationCenter defaultCenter];
}

- (CoreDataManager *)coreDataManager {
    return [CoreDataManager shared];
}

- (NavigationRouter *)navigationRouter {
    return [NavigationRouter shared];
}

@end
