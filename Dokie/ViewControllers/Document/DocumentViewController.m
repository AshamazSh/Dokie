//
//  DocumentViewController.m
//  Dokie
//
//  Created by Ashamaz Shidov on 28/12/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import "DocumentViewController.h"
#import "DocumentViewModel.h"
#import "DocumentTextView.h"
#import "DocumentFilesView.h"
#import "NavigationRouter.h"
#import "UI.h"

@interface DocumentViewController ()

@property (nonatomic, strong) DocumentViewModel *viewModel;
@property (nonatomic, strong) DocumentTextView *textView;
@property (nonatomic, strong) DocumentFilesView *filesView;

@property (nonatomic) BOOL didAppearFirstTime;

@property (nonatomic, strong, readonly) NavigationRouter *navigationRouter;

@end

@implementation DocumentViewController

- (instancetype)initWithViewModel:(DocumentViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        self.didAppearFirstTime = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.didAppearFirstTime) {
        [self.textView refresh];
        [self.filesView refresh];
        self.didAppearFirstTime = YES;
    }
}

- (void)setup {
    @weakify(self);
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:nil action:nil];
    self.navigationItem.rightBarButtonItems = @[addButton];
    addButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id _) {
        @strongify(self);
        [self.viewModel addButtonPressed];
        return [RACSignal empty];
    }];
    
    [[RACObserve(self, viewModel.documentName) deliverOnMainThread] subscribeNext:^(NSString *documentName) {
        @strongify(self);
        self.navigationItem.title = documentName;
    }];
    
    UISegmentedControl *segmented = [UI segmentedControlWithItems:@[NSLocalizedString(@"Text", @"Text segmented text"), NSLocalizedString(@"Files", @"Files  segmeted text")]];
    [self.view addSubview:segmented];
    
    UIView *separator = [UI separator];
    [self.view addSubview:separator];
    
    self.textView = [[DocumentTextView alloc] initWithViewModel:self.viewModel.textViewModel];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.textView];
    
    self.filesView = [[DocumentFilesView alloc] initWithViewModel:self.viewModel.filesViewModel];
    self.filesView.translatesAutoresizingMaskIntoConstraints = NO;
    self.filesView.alpha = 0;
    [self.view addSubview:self.filesView];
    
    UIView *controlView = [UI view];
    [self.view addSubview:controlView];
    {
        UIView *separator = [UI separator];
        [controlView addSubview:separator];
        
        UIButton *selectButton = [UI button];
        [selectButton setTitle:NSLocalizedString(@"Select", @"Select button text") forState:UIControlStateNormal];
        [controlView addSubview:selectButton];
        
        UIButton *cancelButton = [UI button];
        cancelButton.alpha = 0;
        [cancelButton setTitle:NSLocalizedString(@"Cancel", @"Cancel button text") forState:UIControlStateNormal];
        [controlView addSubview:cancelButton];
        
        UIButton *shareButton = [UI button];
        shareButton.alpha = 0;
        [shareButton setTitle:NSLocalizedString(@"Share", @"Share button text") forState:UIControlStateNormal];
        [controlView addSubview:shareButton];
        
        UIButton *deleteButton = [UI button];
        deleteButton.alpha = 0;
        [deleteButton setTitle:NSLocalizedString(@"Delete", @"Share button text") forState:UIControlStateNormal];
        [controlView addSubview:deleteButton];
        NSDictionary *metrics = @{@"sideMargin"     :   @16,
                                  @"vMargin"        :   @4,
                                  @"buttonHeight"   :   @44,
                                  @"separatorHeight":   @1
        };
        NSDictionary *views = NSDictionaryOfVariableBindings(separator, selectButton, cancelButton, shareButton, deleteButton);
        [controlView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-sideMargin-[deleteButton]" options:0 metrics:metrics views:views]];
        [controlView addConstraint:[NSLayoutConstraint constraintWithItem:shareButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:controlView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [controlView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[selectButton]-sideMargin-|" options:0 metrics:metrics views:views]];
        [controlView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[cancelButton]-sideMargin-|" options:0 metrics:metrics views:views]];
        [controlView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[separator]|" options:0 metrics:metrics views:views]];
        [controlView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[separator(separatorHeight)]-vMargin-[selectButton(buttonHeight)]-vMargin-|" options:0 metrics:metrics views:views]];
        [controlView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[separator]-vMargin-[cancelButton(buttonHeight)]-vMargin-|" options:0 metrics:metrics views:views]];
        [controlView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[separator]-vMargin-[shareButton(buttonHeight)]-vMargin-|" options:0 metrics:metrics views:views]];
        [controlView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[separator]-vMargin-[deleteButton(buttonHeight)]-vMargin-|" options:0 metrics:metrics views:views]];
        [controlView addConstraint:[NSLayoutConstraint constraintWithItem:shareButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:controlView attribute:NSLayoutAttributeWidth multiplier:0.4 constant:0]];
        
        @weakify(selectButton, cancelButton, shareButton, deleteButton);
        selectButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id _) {
            @strongify(self, selectButton, cancelButton, shareButton, deleteButton);
            self.textView.viewMode = ViewModeSelect;
            self.filesView.viewMode = ViewModeSelect;

            selectButton.alpha = 0;
            cancelButton.alpha = 1;
            shareButton.alpha = 1;
            deleteButton.alpha = 1;
            [shareButton setTitle:NSLocalizedString(@"Share", @"Share button text") forState:UIControlStateNormal];
            return [RACSignal empty];
        }];

        cancelButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id _) {
            @strongify(self, selectButton, cancelButton, shareButton, deleteButton);
            self.textView.viewMode = ViewModeDisplay;
            self.filesView.viewMode = ViewModeDisplay;
            
            selectButton.alpha = 1;
            cancelButton.alpha = 0;
            shareButton.alpha = 0;
            deleteButton.alpha = 0;
            [shareButton setTitle:NSLocalizedString(@"Share", @"Share button text") forState:UIControlStateNormal];
            return [RACSignal empty];
        }];
        
        shareButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id _) {
            @strongify(self, cancelButton);
            [self.viewModel shareText:[self.textView selected] images:[self.filesView selected]];
            [cancelButton.rac_command execute:nil];
            return [RACSignal empty];
        }];
        
        deleteButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id _) {
            @strongify(self);
            if (self.textView.selectedCount + self.filesView.selectedCount > 0) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Delete selected content?", @"Edit content alert title")
                                                                               message:nil
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                
                @weakify(self);
                UIAlertAction *delete = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"Save button text in alert view") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    @strongify(self, cancelButton);
                    [self.filesView deleteSelected];
                    [self.textView deleteSelected];
                    [cancelButton.rac_command execute:nil];
                }];
                [alert addAction:delete];
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button text in alert view") style:UIAlertActionStyleCancel handler:nil];
                [alert addAction:cancel];
                [self.navigationRouter showAlert:alert];
            }
            return [RACSignal empty];
        }];
        
        [[[RACSignal combineLatest:@[[RACObserve(self, filesView.selectedCount) distinctUntilChanged],
                                     [RACObserve(self, textView.selectedCount) distinctUntilChanged]]]
          deliverOnMainThread]
         subscribeNext:^(RACTuple * _Nullable x) {
            @strongify(shareButton);
            RACTupleUnpack(NSNumber *filesCount, NSNumber *textCount) = x;
            NSInteger count = filesCount.integerValue + textCount.integerValue;
            if (count > 0) {
                [shareButton setTitle:[NSLocalizedString(@"Share", @"Share button text") stringByAppendingFormat:@" (%ld)", count] forState:UIControlStateNormal];
            }
            else {
                [shareButton setTitle:NSLocalizedString(@"Share", @"Share button text") forState:UIControlStateNormal];
            }
        }];
    }
    
    NSDictionary *metrics = @{@"top"                :   @10,
                              @"segmentedSide"      :   @30,
                              @"vertical"           :   @10,
                              @"separatorHeight"    :   @1
    };
    NSDictionary *views = NSDictionaryOfVariableBindings(segmented, separator, _textView, _filesView, controlView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top-[segmented]-vertical-[separator(separatorHeight)][_textView][controlView]" options:0 metrics:metrics views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[separator][_filesView][controlView]" options:0 metrics:metrics views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-segmentedSide-[segmented]-segmentedSide-|" options:0 metrics:metrics views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[separator]|" options:0 metrics:metrics views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_textView]|" options:0 metrics:metrics views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_filesView]|" options:0 metrics:metrics views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[controlView]|" options:0 metrics:metrics views:views]];
    
    [NSLayoutConstraint activateConstraints:@[[controlView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]]];

    [[[RACObserve(segmented, selectedSegmentIndex) distinctUntilChanged]
      deliverOnMainThread]
     subscribeNext:^(NSNumber *index) {
        @strongify(self);
        if (index.integerValue == 0) {
            self.textView.alpha = 1;
            self.filesView.alpha = 0;
        }
        else {
            self.textView.alpha = 0;
            self.filesView.alpha = 1;
        }
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - Get Set
- (NavigationRouter *)navigationRouter {
    return [NavigationRouter shared];
}

@end
