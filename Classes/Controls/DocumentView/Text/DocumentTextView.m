//
//  DocumentTextView.m
//  Dokie
//
//  Created by Ashamaz Shidov on 21/12/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import "DocumentTextView.h"
#import "DocumentTextViewModel.h"
#import "Definitions.h"
#import "DocumentTextTableViewCell.h"
#import "UI.h"
#import "AppearanceManager.h"

@interface DocumentTextView() <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) DocumentTextViewModel *viewModel;
@property (nonatomic, strong) NSMutableArray<NSIndexPath *> *selectedCells;
@property (nonatomic) NSInteger selectedCount;

@end

@implementation DocumentTextView

- (instancetype)initWithViewModel:(DocumentTextViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        [self setup];
    }
    return self;
}

- (void)setup {
    @weakify(self);
    self.selectedCells = [NSMutableArray array];
    self.selectedCount = self.selectedCells.count;
    self.backgroundColor = [AppearanceManager backgroundColor];
    
    UITableView *tableView = [UI tableView];
    tableView.allowsMultipleSelectionDuringEditing = NO;
    tableView.delegate = self;
    tableView.dataSource = self;
    [self addSubview:tableView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(tableView);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:nil views:views]];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:tableView action:nil];
    longPress.minimumPressDuration = 1.0;
    @weakify(tableView);
    [longPress.rac_gestureSignal subscribeNext:^(__kindof UIGestureRecognizer *gestureRecognizer) {
        @strongify(self, tableView);

        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            CGPoint p = [gestureRecognizer locationInView:tableView];
            NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:p];
            [self.viewModel editContentAtIndexPath:indexPath];
        }
    }];
    [tableView addGestureRecognizer:longPress];
    
    [[RACObserve(self, viewModel.content) deliverOnMainThread] subscribeNext:^(id _) {
        @strongify(tableView);
        [tableView reloadData];
    }];
    
    [[[RACObserve(self, viewMode) distinctUntilChanged] deliverOnMainThread] subscribeNext:^(NSNumber *viewMode) {
        @strongify(self, tableView);
        [self.selectedCells removeAllObjects];
        self.selectedCount = self.selectedCells.count;
        if (viewMode.integerValue == ViewModeDisplay) {
            [self.selectedCells removeAllObjects];
            self.selectedCount = self.selectedCells.count;
            for (DocumentTextTableViewCell *cell in tableView.visibleCells) {
                cell.viewMode = self.viewMode;
                cell.showCheckmark = NO;
            }
        }
        else {
            [self.selectedCells removeAllObjects];
            self.selectedCount = self.selectedCells.count;
            for (DocumentTextTableViewCell *cell in tableView.visibleCells) {
                cell.viewMode = self.viewMode;
            }
        }
    }];
}

- (void)refresh {
    [[self.viewModel readDocument] subscribeCompleted:^{}];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.content.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

static NSString *const contentCellIdentifier = @"contentCellIdentifier";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DocumentTextTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:contentCellIdentifier];
    if (!cell) {
        cell = [[DocumentTextTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:contentCellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    RACTupleUnpack(NSString *title, NSString *detail) = self.viewModel.content[indexPath.row];
    cell.text = title;
    cell.detail = detail;
    cell.viewMode = self.viewMode;
    cell.showCheckmark = self.viewMode == ViewModeSelect && [self.selectedCells containsObject:indexPath];
    @weakify(self);
    cell.editCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id _) {
        @strongify(self);
        [self.viewModel editContentAtIndexPath:indexPath];
        return [RACSignal empty];
    }];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.viewMode == ViewModeDisplay) {
        [self.viewModel didSelectTextAtIndexPath:indexPath];
    }
    else {
        if ([self.selectedCells containsObject:indexPath]) {
            [self.selectedCells removeObject:indexPath];
        }
        else {
            [self.selectedCells addObject:indexPath];
        }
        for (DocumentTextTableViewCell *cell in tableView.visibleCells) {
            if ([[tableView indexPathForCell:cell] isEqual:indexPath]) {
                cell.showCheckmark = [self.selectedCells containsObject:indexPath];
            }
        }
        self.selectedCount = self.selectedCells.count;
    }
}

- (NSArray<NSString *> *)selected {
    NSMutableArray *toReturn = [NSMutableArray array];
    for (NSIndexPath *indexPath in self.selectedCells) {
        RACTupleUnpack(NSString *title, NSString *detail) = self.viewModel.content[indexPath.row];
        if (title.length > 0 && detail.length > 0) {
            [toReturn addObject:[NSString stringWithFormat:@"%@: %@", title, detail]];
        }
        else if (title.length > 0) {
            [toReturn addObject:title];
        }
        else {
            [toReturn addObject:detail];
        }
    }
    return [toReturn copy];
}

- (void)deleteSelected {
    [self.viewModel deleteContentAtIndexPaths:self.selectedCells];
}

@end
