//
//  DocumentFilesViewModel.m
//  Dokie
//
//  Created by Ashamaz Shidov on 21/12/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import "DocumentFilesViewModel.h"
#import "CoreDataManager.h"
#import "Constants.h"
#import "CoreDataInclude.h"
#import "NavigationRouter.h"

#import <UIKit/UIKit.h>

@interface DocumentFilesViewModel() <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) CDDocument *document;
@property (nonatomic, strong) NSArray<CDContent *> *contentFiles;

@property (nonatomic, strong, readonly) CoreDataManager *coreDataManager;
@property (nonatomic, strong, readonly) NavigationRouter *navigationRouter;

@end

@implementation DocumentFilesViewModel

- (instancetype)initWithDocument:(CDDocument *)document {
    self = [super init];
    if (self) {
        self.document = document;
        [self setup];
    }
    return self;
}

- (void)setup {
    
}

- (RACSignal *)readDocument {
    @weakify(self);
    return [[self.coreDataManager decryptedDocument:self.document]
            flattenMap:^__kindof RACSignal * _Nullable(NSArray *decrypted) {
        @strongify(self);
        NSMutableArray<CDContent *> *contentFiles = [NSMutableArray array];
        for (NSInteger i = 0; i < decrypted.count; ++i) {
            RACTuple *tuple = decrypted[i];
            RACTupleUnpack(__unused CDDocument *document, NSDictionary *json, NSError *error) = tuple;
            if (!error) {
                if ([json[kContentTypeKey] isEqual:kContentTypeFile]) {
                    [contentFiles addObject:self.document.content[i]];
                }
            }
        }
        self.contentFiles = [contentFiles copy];
        return [RACSignal empty];
    }];
}

- (void)addFile {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add file", @"Add file alert title")
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];

    @weakify(self);
    UIAlertAction *camera = [UIAlertAction actionWithTitle:NSLocalizedString(@"Camera", @"Camera button text in alert view") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        UIImagePickerController *picker = [UIImagePickerController new];
        picker.delegate = self;
        picker.allowsEditing = NO;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        [self.navigationRouter showImagePicker:picker];
    }];
    [alert addAction:camera];
    UIAlertAction *library = [UIAlertAction actionWithTitle:NSLocalizedString(@"Library", @"Library button text in alert view") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        UIImagePickerController *picker = [UIImagePickerController new];
        picker.delegate = self;
        picker.allowsEditing = NO;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        [self.navigationRouter showImagePicker:picker];
    }];
    [alert addAction:library];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button text in alert view") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self.navigationRouter showAlert:alert];
}

- (void)editContentAtIndexPath:(NSIndexPath *)indexPath {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    @weakify(self);
    UIAlertAction *delete = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"Delete button text in alert view") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        [self deleteContentAtIndexPaths:@[indexPath]];
    }];
    [alert addAction:delete];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button text in alert view") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self.navigationRouter showAlert:alert];
}

- (void)deleteContentAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    NSMutableArray *signals = [NSMutableArray array];
    for (NSIndexPath *indexPath in indexPaths) {
        if (indexPath.row < self.contentFiles.count) {
            [signals addObject:[self.coreDataManager deleteContent:self.contentFiles[indexPath.row]]];
        }
    }
    if (signals.count > 0) {
        NSString *loadingGuid = [self.navigationRouter showLoading];
        @weakify(self);
        [[[RACSignal combineLatest:signals]
          concat:[self readDocument]]
         subscribeError:^(NSError * _Nullable error) {
            @strongify(self);
            [self.navigationRouter hideLoading:loadingGuid];
            [self.navigationRouter showAlertWithTitle:@"" message:NSLocalizedString(@"Some error occured. Please try again later.", @"Some error title")];
            [[self readDocument] subscribeCompleted:^{}];
        }
         completed:^{
            @strongify(self);
            [self.navigationRouter hideLoading:loadingGuid];
        }];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    if (!image) return;
    
    NSString *loadingGuid = [self.navigationRouter showLoading];
    @weakify(self);
    [[[[self.coreDataManager createFileWithContent:UIImagePNGRepresentation(image)]
       flattenMap:^__kindof RACSignal * _Nullable(CDFile * _Nullable file) {
        @strongify(self);
        return [[self.coreDataManager addContentToDocument:self.document withDictionary:@{kContentTypeKey : kContentTypeFile,
                                                                                          kContentFileIdKey : file.identifier ?: @""
        }]
                concat:[self readDocument]];
    }]
      deliverOnMainThread]
     subscribeError:^(NSError * _Nullable error) {
        @strongify(self);
        [self.navigationRouter hideLoading:loadingGuid];
        [self.navigationRouter showAlertWithTitle:@"" message:NSLocalizedString(@"Some error occured. Please try again later.", @"Some error title")];
    }
     completed:^{
        @strongify(self);
        [self.navigationRouter hideLoading:loadingGuid];
    }];
;
}

#pragma mark -

- (CoreDataManager *)coreDataManager {
    return [CoreDataManager shared];
}

- (NavigationRouter *)navigationRouter {
    return [NavigationRouter shared];
}

@end
