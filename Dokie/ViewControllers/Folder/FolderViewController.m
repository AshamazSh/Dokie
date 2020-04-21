//
//  FolderViewController.m
//  Dokie
//
//  Created by Ashamaz Shidov on 28/12/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import "FolderViewController.h"
#import "FolderViewModel.h"
#import "Logger.h"
#import "FileNameTableViewCell.h"
#import "FolderNameTableViewCell.h"
#import "UI.h"

@interface FolderViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) FolderViewModel *viewModel;

@end

@implementation FolderViewController

- (instancetype)initWithViewModel:(FolderViewModel *)viewModel {
    ParameterAssert(viewModel);
    
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)setup {
    @weakify(self);
    
    [[RACObserve(self, viewModel.folderName) deliverOnMainThread] subscribeNext:^(NSString *folderName) {
        @strongify(self);
        self.navigationItem.title = folderName;
    }];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:nil action:nil];
    self.navigationItem.rightBarButtonItems = @[addButton];
    addButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id _) {
        @strongify(self);
        [self.viewModel addButtonPressed];
        return [RACSignal empty];
    }];

    if (self.viewModel.showMenuNavButton) {
        UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings_small.png"] style:UIBarButtonItemStylePlain target:nil action:nil];
        menuButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id _) {
            @strongify(self);
            [self.viewModel menuPressed];
            return [RACSignal empty];
        }];
        self.navigationItem.leftBarButtonItems = @[menuButton];
    }
    UITableView *tableView = [UI tableView];
    tableView.delegate = self;
    tableView.dataSource = self;
    [self.view addSubview:tableView];
    
    UILabel *noContentLabel = [UI label];
    noContentLabel.text = NSLocalizedString(@"Folder is empty", @"Folder is empty content text");
    noContentLabel.alpha = 0;
    noContentLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:noContentLabel];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(tableView, noContentLabel);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[noContentLabel]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[noContentLabel]|" options:0 metrics:nil views:views]];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:tableView action:nil];
    longPress.minimumPressDuration = 1.0;
    @weakify(tableView);
    [longPress.rac_gestureSignal subscribeNext:^(__kindof UIGestureRecognizer *gestureRecognizer) {
        @strongify(self, tableView);

        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            CGPoint p = [gestureRecognizer locationInView:tableView];
            NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:p];
            if (indexPath.section == 0) {
                [self.viewModel longPressedSubfolderAtIndexPath:indexPath];
            }
            else {
                [self.viewModel longPressedDocumentAtIndexPath:indexPath];
            }
        }
    }];
    [tableView addGestureRecognizer:longPress];
    
    @weakify(noContentLabel);
    [[[RACSignal combineLatest:@[RACObserve(self, viewModel.subfolders),
                                 RACObserve(self, viewModel.documents)]]
      deliverOnMainThread]
     subscribeNext:^(RACTuple *tuple) {
        @strongify(tableView, noContentLabel);
        RACTupleUnpack(NSArray *subfolders, NSArray *documents) = tuple;
        noContentLabel.alpha = subfolders.count + documents.count > 0 ? 0 : 1;
        [tableView reloadData];
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? self.viewModel.subfolders.count : self.viewModel.documents.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

static NSString *const subfolderCellIdentifier = @"subfolderCellIdentifier";
static NSString *const documentCellIdentifier = @"documentCellIdentifier";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    @weakify(self);
    if (indexPath.section == 0) {
        FolderNameTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:subfolderCellIdentifier];
        if (!cell) {
            cell = [[FolderNameTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:subfolderCellIdentifier];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }
        cell.editCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id _) {
            @strongify(self);
            [self.viewModel longPressedSubfolderAtIndexPath:indexPath];
            return [RACSignal empty];
        }];
        cell.name = self.viewModel.subfolders[indexPath.row];
        return cell;
    }
    else {
        FileNameTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:documentCellIdentifier];
        if (!cell) {
            cell = [[FileNameTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:documentCellIdentifier];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }
        cell.name = self.viewModel.documents[indexPath.row];
        cell.editCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id _) {
            @strongify(self);
            [self.viewModel longPressedDocumentAtIndexPath:indexPath];
            return [RACSignal empty];
        }];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        [self.viewModel didSelectSubfolderAtIndexPath:indexPath];
    }
    else {
        [self.viewModel didSelectDocumentAtIndexPath:indexPath];
    }
}

@end
