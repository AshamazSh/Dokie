//
//  DocumentViewModel.m
//  Dokie
//
//  Created by Ashamaz Shidov on 28/12/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import "DocumentViewModel.h"
#import "DocumentFilesViewModel.h"
#import "DocumentTextViewModel.h"
#import "CoreDataInclude.h"
#import "NavigationRouter.h"
#import "CoreDataManager.h"

#import <UIKit/UIKit.h>

@interface DocumentViewModel()

@property (nonatomic, strong) CDDocument *document;
@property (nonatomic, strong) NSString *documentName;
@property (nonatomic, strong) DocumentFilesViewModel *filesViewModel;
@property (nonatomic, strong) DocumentTextViewModel *textViewModel;

@property (nonatomic, strong, readonly) NavigationRouter *navigationRouter;
@property (nonatomic, strong, readonly) CoreDataManager *coreDataManager;

@end

@implementation DocumentViewModel

- (instancetype)initWithDocument:(CDDocument *)document {
    self = [super init];
    if (self) {
        self.document = document;
        [self setup];
    }
    return self;
}

- (void)setup {
    self.filesViewModel = [[DocumentFilesViewModel alloc] initWithDocument:self.document];
    self.textViewModel = [[DocumentTextViewModel alloc] initWithDocument:self.document];
    @weakify(self);
    [[[self.coreDataManager documentName:self.document] deliverOnMainThread] subscribeNext:^(NSString * _Nullable x) {
        @strongify(self);
        self.documentName = x;
    }];
}

- (void)addButtonPressed {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    @weakify(self);
    UIAlertAction *addText = [UIAlertAction actionWithTitle:NSLocalizedString(@"Add text", @"Add text button text in alert view") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        [self.textViewModel addContent];
    }];
    [alert addAction:addText];
    UIAlertAction *addFile = [UIAlertAction actionWithTitle:NSLocalizedString(@"Add file", @"Add file button text in alert view") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        [self.filesViewModel addFile];
    }];
    [alert addAction:addFile];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button text in alert view") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self.navigationRouter showAlert:alert];

}

- (void)shareText:(NSArray<NSString *> *)texts images:(NSArray<CDContent *> *)images {
    if (texts.count == 0 && images.count == 0) return;
    
    NSMutableString *string = [NSMutableString string];
    for (NSString *text in texts) {
        [string appendFormat:@"%@\n", text];
    }

    if (images.count > 0) {
        NSString *loadingGuid = [self.navigationRouter showLoading];
        NSMutableArray *signals = [NSMutableArray array];
        for (CDContent *content in images) {
            [signals addObject:[self.coreDataManager imageFromContent:content]];
        }
        
        @weakify(self);
        [[[RACSignal combineLatest:signals] deliverOnMainThread] subscribeNext:^(RACTuple * _Nullable x) {
            @strongify(self);
            NSMutableArray *imagesArray = [NSMutableArray array];
            for (UIImage *image in x) {
                [imagesArray addObject:image];
            }
            
            if (string.length > 0) {
                [imagesArray addObject:[string copy]];
            }
            [self.navigationRouter shareItems:imagesArray];
            [self.navigationRouter hideLoading:loadingGuid];
        }];
    }
    else {
        [self.navigationRouter shareItems:@[[string copy]]];
    }
}

#pragma mark - Get Set

- (NavigationRouter *)navigationRouter {
    return [NavigationRouter shared];
}

- (CoreDataManager *)coreDataManager {
    return [CoreDataManager shared];
}

@end
