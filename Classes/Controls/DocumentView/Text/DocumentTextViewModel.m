//
//  DocumentTextViewModel.m
//  Dokie
//
//  Created by Ashamaz Shidov on 21/12/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import "DocumentTextViewModel.h"
#import "CoreDataInclude.h"
#import "CoreDataManager.h"
#import "Logger.h"
#import "Constants.h"
#import "NavigationRouter.h"

@interface DocumentTextViewModel()

@property (nonatomic, strong) RACSubject *copyedToClipboardSubject;

@property (nonatomic, strong) NSArray<RACTuple *> *content;
@property (nonatomic, strong) NSArray<CDContent *> *displayedObjects;
@property (nonatomic, strong) CDDocument *document;

@property (nonatomic, strong, readonly) CoreDataManager *coreDataManager;
@property (nonatomic, strong, readonly) NavigationRouter *navigationRouter;

@end

@implementation DocumentTextViewModel

- (instancetype)initWithDocument:(CDDocument *)document {
    ParameterAssert(document);
    
    self = [super init];
    if (self) {
        self.document = document;
        [self setup];
    }
    return self;
}

- (void)setup {
    self.copyedToClipboardSubject = [RACSubject new];
}

- (void)addContent {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add content", @"Add content alert title")
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = NSLocalizedString(@"Description", @"Description placeholder");
        textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = NSLocalizedString(@"Text", @"Text placeholder");
        textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    }];
    
    @weakify(self);
    UIAlertAction *save = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save", @"Save button text in alert view") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        NSString *loadingGuid = [self.navigationRouter showLoading];
        UITextField *detailField = alert.textFields[0];
        UITextField *textField = alert.textFields[1];
        [[[self.coreDataManager addContentToDocument:self.document withDictionary:@{kContentTypeKey : kContentTypeText,
                                                                                    kContentTextKey : textField.text ?: @"",
                                                                                    kContentDescriptionKey : detailField.text ?: @""
        }]
          concat:[self readDocument]]
         subscribeError:^(NSError * _Nullable error) {
            @strongify(self);
            [self.navigationRouter hideLoading:loadingGuid];
            [self.navigationRouter showAlertWithTitle:@"" message:NSLocalizedString(@"Some error occured. Please try again later.", @"Some error title")];
        }
         completed:^{
            @strongify(self);
            [self.navigationRouter hideLoading:loadingGuid];
        }];
    }];
    [alert addAction:save];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button text in alert view") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self.navigationRouter showAlert:alert];
}

- (RACSignal *)readDocument {
    @weakify(self);
    return [[self.coreDataManager decryptedDocument:self.document]
            flattenMap:^__kindof RACSignal * _Nullable(NSArray *decrypted) {
        @strongify(self);
        NSMutableArray<RACTuple *> *content = [NSMutableArray array];
        NSMutableArray<CDContent *> *objects = [NSMutableArray array];
        for (NSInteger i = 0; i < decrypted.count; ++i) {
            RACTuple *tuple = decrypted[i];
            RACTupleUnpack(__unused CDDocument *document, NSDictionary *json, NSError *error) = tuple;
            if (!error) {
                if ([json[kContentTypeKey] isEqual:kContentTypeText]) {
                    [content addObject:RACTuplePack(json[kContentTextKey], json[kContentDescriptionKey])];
                    [objects addObject:self.document.content[i]];
                }
            }
        }
        self.content = [content copy];
        self.displayedObjects = [objects copy];
        return [RACSignal empty];
    }];
}

- (void)didSelectTextAtIndexPath:(NSIndexPath *)indexPath {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    @weakify(self);
    UIAlertAction *edit = [UIAlertAction actionWithTitle:NSLocalizedString(@"Edit", @"Edit text in alert view") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        [self editContentAtIndexPath:indexPath];
    }];
    [alert addAction:edit];
    UIAlertAction *copy = [UIAlertAction actionWithTitle:NSLocalizedString(@"Copy", @"Copy button text in alert view") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        [self copyToClipboardContentAtIndexPath:indexPath];
    }];
    [alert addAction:copy];
    UIAlertAction *delete = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"Delete button text in alert view") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        [self deleteContentAtIndexPaths:@[indexPath]];
    }];
    [alert addAction:delete];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button text in alert view") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self.navigationRouter showAlert:alert];
}

- (void)copyToClipboardContentAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.content.count) {
        RACTupleUnpack(NSString *title, NSString *detail) = self.content[indexPath.row];
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        if (title.length > 0 && detail.length > 0) {
            pasteboard.string = [NSString stringWithFormat:@"%@: %@", title, detail];
        }
        else if (title.length > 0) {
            pasteboard.string = title;
        }
        else {
            pasteboard.string = detail;
        }
        [self.copyedToClipboardSubject sendNext:@YES];
    }
}

- (void)editContentAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.content.count) {
        RACTupleUnpack(NSString *title, NSString *detail) = self.content[indexPath.row];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Edit content", @"Edit content alert title")
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.text = title;
            textField.placeholder = NSLocalizedString(@"Description", @"Description placeholder");
            textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        }];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.text = detail;
            textField.placeholder = NSLocalizedString(@"Text", @"Text placeholder");
            textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        }];
        
        @weakify(self);
        UIAlertAction *save = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save", @"Save button text in alert view") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            NSString *loadingGuid = [self.navigationRouter showLoading];
            UITextField *detailField = alert.textFields[0];
            UITextField *textField = alert.textFields[1];
            [[[self.coreDataManager updateContent:self.displayedObjects[indexPath.row]
                                   withDictionary:@{kContentTypeKey : kContentTypeText,
                                                    kContentTextKey : textField.text ?: @"",
                                                    kContentDescriptionKey : detailField.text ?: @""
                                   }]
              concat:[self readDocument]]
             subscribeError:^(NSError * _Nullable error) {
                @strongify(self);
                [self.navigationRouter hideLoading:loadingGuid];
                [self.navigationRouter showAlertWithTitle:@"" message:NSLocalizedString(@"Some error occured. Please try again later.", @"Some error title")];
            }
             completed:^{
                @strongify(self);
                [self.navigationRouter hideLoading:loadingGuid];
            }];
        }];
        [alert addAction:save];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button text in alert view") style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [self.navigationRouter showAlert:alert];
    }
}

- (void)deleteContentAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    NSMutableArray *signals = [NSMutableArray array];
    for (NSIndexPath *indexPath in indexPaths) {
        if (indexPath.row < self.displayedObjects.count) {
            [signals addObject:[self.coreDataManager deleteContent:self.displayedObjects[indexPath.row]]];
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

#pragma mark -

- (CoreDataManager *)coreDataManager {
    return [CoreDataManager shared];
}

- (NavigationRouter *)navigationRouter {
    return [NavigationRouter shared];
}

@end
