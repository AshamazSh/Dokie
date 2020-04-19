//
//  DocumentFilesView.m
//  Dokie
//
//  Created by Ashamaz Shidov on 21/12/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import "DocumentFilesView.h"
#import "DocumentFilesViewModel.h"
#import "FilePreviewCollectionViewCell.h"
#import "DocumentImagesPageViewController.h"
#import "DocumentImagesPageViewModel.h"
#import "Definitions.h"
#import "NavigationRouter.h"
#import "UI.h"

@interface DocumentFilesView() <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) DocumentFilesViewModel *viewModel;
@property (nonatomic, strong) NSMutableArray<NSIndexPath *> *selectedCells;
@property (nonatomic) NSInteger selectedCount;

@property (nonatomic, strong, readonly) NavigationRouter *navigationRouter;

@end

@implementation DocumentFilesView

- (instancetype)initWithViewModel:(DocumentFilesViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        [self setup];
    }
    return self;
}

static NSString *const contentFilePreviewCellIdentifier = @"contentFilePreviewCellIdentifier";

- (void)setup {
    @weakify(self);
    self.selectedCells = [NSMutableArray array];
    self.selectedCount = self.selectedCells.count;
    
    UICollectionView *collectionView = [UI collectionViewWithLineSpacing:4 itemSpacing:0];
    collectionView.delegate = self;
    collectionView.dataSource = self;
    collectionView.contentInset = UIEdgeInsetsMake(4, 8, 4, 8);
    [collectionView registerClass:[FilePreviewCollectionViewCell class] forCellWithReuseIdentifier:contentFilePreviewCellIdentifier];
    [self addSubview:collectionView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(collectionView);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[collectionView]|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[collectionView]|" options:0 metrics:nil views:views]];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:collectionView action:nil];
    longPress.minimumPressDuration = 1.0;
    @weakify(collectionView);
    [longPress.rac_gestureSignal subscribeNext:^(__kindof UIGestureRecognizer *gestureRecognizer) {
        @strongify(self, collectionView);

        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            CGPoint p = [gestureRecognizer locationInView:collectionView];
            NSIndexPath *indexPath = [collectionView indexPathForItemAtPoint:p];
            [self.viewModel editContentAtIndexPath:indexPath];
        }
    }];
    [collectionView addGestureRecognizer:longPress];
    
    [[RACObserve(self, viewModel.contentFiles) deliverOnMainThread] subscribeNext:^(id _) {
        @strongify(collectionView);
        [collectionView reloadData];
    }];
    
    [[[RACObserve(self, viewMode) distinctUntilChanged] deliverOnMainThread] subscribeNext:^(NSNumber *viewMode) {
        @strongify(self, collectionView);
        [self.selectedCells removeAllObjects];
        self.selectedCount = self.selectedCells.count;
        if (viewMode.integerValue == ViewModeDisplay) {
            for (FilePreviewCollectionViewCell *cell in collectionView.visibleCells) {
                cell.showCheckmark = NO;
            }
        }
    }];
}

- (void)refresh {
    [[self.viewModel readDocument] subscribeCompleted:^{}];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.viewModel.contentFiles.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FilePreviewCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:contentFilePreviewCellIdentifier forIndexPath:indexPath];
    CDContent *content = self.viewModel.contentFiles[indexPath.row];
    [cell updateWithContent:content];
    cell.showCheckmark = self.viewMode == ViewModeSelect && [self.selectedCells containsObject:indexPath];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat factor = 1.6;
    CGFloat width = (collectionView.bounds.size.width - 16 - 3*8) / 4;
    if (width < 0) width = 0;
    return CGSizeMake(width, width * factor);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.viewMode == ViewModeDisplay) {
        [self.navigationRouter showDocumentImages:self.viewModel.contentFiles firstIndex:indexPath.row];
    }
    else {
        if ([self.selectedCells containsObject:indexPath]) {
            [self.selectedCells removeObject:indexPath];
            FilePreviewCollectionViewCell *cell = (FilePreviewCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
            cell.showCheckmark = NO;
        }
        else {
            [self.selectedCells addObject:indexPath];
            FilePreviewCollectionViewCell *cell = (FilePreviewCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
            cell.showCheckmark = YES;
        }
        self.selectedCount = self.selectedCells.count;
    }
}

- (NSArray<CDContent *> *)selected {
    NSMutableArray *toReturn = [NSMutableArray array];
    for (NSIndexPath *indexPath in self.selectedCells) {
        [toReturn addObject:self.viewModel.contentFiles[indexPath.row]];
    }
    return [toReturn copy];
}

- (void)deleteSelected {
    [self.viewModel deleteContentAtIndexPaths:self.selectedCells];
}

#pragma mark - Get Set

- (NavigationRouter *)navigationRouter {
    return [NavigationRouter shared];
}

@end
