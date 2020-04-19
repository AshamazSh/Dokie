//
//  ImagePreviewViewController.m
//  Dokie
//
//  Created by Ashamaz Shidov on 26.01.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import "ImagePreviewViewController.h"
#import "CoreDataInclude.h"
#import "Logger.h"
#import "CoreDataInclude.h"
#import "FileImageView.h"
#import "UI.h"
#import "AppearanceManager.h"

#import <ReactiveObjC/ReactiveObjC.h>

@interface ImagePreviewViewController() <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSLayoutConstraint *scrollTopConstraint;
@property (nonatomic, strong) NSLayoutConstraint *scrollBottomConstraint;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTap;
@property (nonatomic) UIEdgeInsets scrollViewContentInset;

@property (nonatomic, strong) UIView *scrollViewContent;
@property (nonatomic, strong) FileImageView *imageView;
@property (nonatomic) NSInteger pageIndex;

@end

@implementation ImagePreviewViewController

- (instancetype)initWithImageView:(FileImageView *)imageView pageIndex:(NSInteger)pageIndex {
    ParameterAssert(imageView);
    
    self = [super init];
    if (self) {
        self.pageIndex = pageIndex;
        self.imageView = imageView;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.scrollView.zoomScale = 1;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)setup {
    [self.imageView removeFromSuperview];
    self.view.backgroundColor = [AppearanceManager backgroundColor];
    
    self.scrollView = [UI scrollView];
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = [AppearanceManager backgroundColor];
    [self.view addSubview:self.scrollView];
    {
        NSDictionary *views = NSDictionaryOfVariableBindings(_scrollView);
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_scrollView]|" options:0 metrics:nil views:views]];
        self.scrollTopConstraint = [NSLayoutConstraint constraintWithItem:self.scrollView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0];
        self.scrollBottomConstraint = [NSLayoutConstraint constraintWithItem:self.scrollView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
        [self.view addConstraints:@[self.scrollTopConstraint, self.scrollBottomConstraint]];
    }
    self.doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapOnScrollView:)];
    self.doubleTap.numberOfTapsRequired = 2;
    [self.scrollView addGestureRecognizer:self.doubleTap];
    
    self.scrollViewContent = [UI view];
    [self.scrollView addSubview:self.scrollViewContent];
    {
        NSDictionary *views = NSDictionaryOfVariableBindings(_scrollViewContent);
        [self.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_scrollViewContent]|" options:0 metrics:nil views:views]];
        [self.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_scrollViewContent]|" options:0 metrics:nil views:views]];

        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.scrollViewContent attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.scrollViewContent attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
    }
    
    [self.scrollViewContent addSubview:self.imageView];
    
    NSLayoutConstraint *imageW = [NSLayoutConstraint constraintWithItem:self.imageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:self.view.frame.size.width];
    NSLayoutConstraint *imageH = [NSLayoutConstraint constraintWithItem:self.imageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:self.view.frame.size.height];
    [self.view addConstraints:@[imageW, imageH]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.scrollViewContent attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.scrollViewContent attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    @weakify(self);
    [[RACSignal combineLatest:@[[RACObserve(self, view.frame) distinctUntilChanged],
                                [RACObserve(self, view.bounds) distinctUntilChanged]]]
     subscribeNext:^(id _) {
         @strongify(self);
         imageH.constant = self.view.frame.size.height;
         imageW.constant = self.view.frame.size.width;
         
         [self.view layoutIfNeeded];
         
         self.scrollViewContentInset = self.scrollView.contentInset;
     }];
}

- (void)moveScrollViewCenterToDeltaY:(CGFloat)deltaY {
    // sometimes it causes a problem :)
    if (fabs(deltaY) > 1000)
        return;

    self.scrollTopConstraint.constant = deltaY;
    self.scrollBottomConstraint.constant = deltaY;
    [self.view layoutIfNeeded];
}

- (void)doubleTapOnScrollView:(UIGestureRecognizer *)gestureRecognizer {
    if(self.scrollView.zoomScale > self.scrollView.minimumZoomScale)
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
    else
        [self.scrollView setZoomScale:self.scrollView.maximumZoomScale animated:YES];
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.scrollViewContent;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if (scrollView.zoomScale < 1) {
        CGFloat top = 0, left = 0;
        if (self.scrollView.contentSize.width < self.scrollView.bounds.size.width) {
            left = (self.scrollView.bounds.size.width-self.scrollView.contentSize.width) * 0.5f;
        }
        if (self.scrollView.contentSize.height < self.scrollView.bounds.size.height) {
            top = (self.scrollView.bounds.size.height-self.scrollView.contentSize.height) * 0.5f;
        }
        self.scrollView.contentInset = UIEdgeInsetsMake(top, left, top, left);

        [self.view layoutIfNeeded];
    }
    else {
        if (!UIEdgeInsetsEqualToEdgeInsets(self.scrollViewContentInset, self.scrollView.contentInset)) {
            self.scrollView.contentInset = self.scrollViewContentInset;
            [self.view layoutIfNeeded];
        }
    }
}

@end
