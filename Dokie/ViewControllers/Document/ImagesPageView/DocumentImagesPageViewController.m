//
//  DocumentImagesPageViewController.m
//  Dokie
//
//  Created by Ashamaz Shidov on 26.01.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import "DocumentImagesPageViewController.h"
#import "DocumentImagesPageViewModel.h"
#import "Logger.h"
#import "ImagePreviewViewController.h"
#import "FileImageView.h"
#import "AppearanceManager.h"

#import <ReactiveObjC/ReactiveObjC.h>

@interface DocumentImagesPageViewController() <UIGestureRecognizerDelegate, UIPageViewControllerDelegate,UIPageViewControllerDataSource>

@property (nonatomic, strong) DocumentImagesPageViewModel *viewModel;

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic) CGPoint startLocation;
@property (nonatomic) CGFloat deltaY;
@property (nonatomic) CGFloat lastDirection;

@property (nonatomic, strong) ImagePreviewViewController *currentVisibleViewController;

@end

@implementation DocumentImagesPageViewController

- (instancetype)initWithViewModel:(DocumentImagesPageViewModel *)viewModel {
    ParameterAssert(viewModel);
    
    self = [self initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];

    if (self) {
        self.viewModel = viewModel;
        self.dataSource = self;
        self.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)setup {
    self.view.backgroundColor = [AppearanceManager backgroundColor];
    @weakify(self);
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"Close navigation bar button text") style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.leftBarButtonItems = @[closeButton];
    closeButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id _) {
        @strongify(self);
        [self closePressed];
        return [RACSignal empty];
    }];
    
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:nil action:nil];
    self.navigationItem.rightBarButtonItems = @[shareButton];
    shareButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id _) {
        @strongify(self);
        if (self.currentVisibleViewController.imageView.image) {
            UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[self.currentVisibleViewController.imageView.image] applicationActivities:nil];
            [self presentViewController:avc animated:YES completion:nil];
        }
        return [RACSignal empty];
    }];
    
    [[RACObserve(self, viewModel.contentImages) distinctUntilChanged] subscribeNext:^(id _) {
        @strongify(self);
        if (self.currentVisibleViewController.pageIndex >= self.viewModel.contentImages.count || !self.currentVisibleViewController) {
            self.currentVisibleViewController = [self firstViewController];
        }
        else {
            self.currentVisibleViewController = [self imagePreviewViewControllerForPageIndex:self.currentVisibleViewController.pageIndex];
        }
        if (self.currentVisibleViewController) {
            self.navigationItem.title = [NSString stringWithFormat:@"%ld / %ld", (long)self.currentVisibleViewController.pageIndex+1, (long)self.viewModel.contentImages.count];
            [self setViewControllers:@[self.currentVisibleViewController]
                           direction:UIPageViewControllerNavigationDirectionForward
                            animated:YES
                          completion:NULL];
        }
    }];
    
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    self.panGesture.delegate = self;
    self.panGesture.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:self.panGesture];
}

- (ImagePreviewViewController *)firstViewController {
    if (self.viewModel.contentImages.count == 0) {
        return nil;
    }
    else if (self.viewModel.firstIndex < self.viewModel.contentImages.count) {
        return [self imagePreviewViewControllerForPageIndex:self.viewModel.firstIndex];
    }
    else {
        return [self imagePreviewViewControllerForPageIndex:0];
    }
}

- (void)hideWindow {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)closePressed {
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         CGPoint finalPoint = CGPointMake(self.navigationController.view.center.x, self.navigationController.view.frame.size.height*1.5 + 100);
                         self.view.center = finalPoint;
                         self.navigationController.view.alpha = 0.1;
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             [self hideWindow];
                         }
                     }];
}

- (void)moveScrollViewCenterToDeltaY:(CGFloat)deltaY {
    if (self.currentVisibleViewController)
        [self.currentVisibleViewController moveScrollViewCenterToDeltaY:deltaY];
}

- (void)panGesture:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.startLocation = [sender translationInView:self.view];
        self.deltaY = 0;
        self.lastDirection = 0;
    }

    CGPoint translation = [sender translationInView:self.view];
    self.deltaY += translation.y;
    if (translation.y != 0 && fabs(translation.y) > 10) {
        self.lastDirection = translation.y;
    }
    [self moveScrollViewCenterToDeltaY:self.deltaY];

    self.navigationController.view.alpha = 1.1 - fabs(2*self.deltaY)/self.view.frame.size.height;
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        BOOL movedUp = self.startLocation.y > self.deltaY;
        BOOL lastDirectionIsUp = self.lastDirection < 0;
        if (fabs(self.deltaY) > sender.view.frame.size.height/6 &&
            (movedUp == lastDirectionIsUp)) {
            [UIView animateWithDuration:0.3
                                  delay:0
                                options:UIViewAnimationOptionCurveLinear
                             animations:^{
                                 CGPoint finalPoint;
                                 if (movedUp) {
                                     finalPoint = CGPointMake(self.navigationController.view.center.x, -(sender.view.frame.size.height + 100));
                                 }
                                 else {
                                     finalPoint = CGPointMake(self.navigationController.view.center.x,   sender.view.frame.size.height + 100);
                                 }
                                 [self moveScrollViewCenterToDeltaY:finalPoint.y];
                                 self.navigationController.view.alpha = 0.1;
                             }
                             completion:^(BOOL finished) {
                                 if (finished) {
                                     [self hideWindow];
                                 }
                             }];

        }
        else {
            [UIView animateWithDuration:0.3
                                  delay:0
                                options:UIViewAnimationOptionCurveLinear
                             animations:^{
                                 [self moveScrollViewCenterToDeltaY:0];
                                 self.navigationController.view.alpha = 1;
                             }
                             completion:nil];
        }
    }
    
    [sender setTranslation:CGPointMake(0, 0) inView:self.view];
}

#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    if (completed) {
        self.currentVisibleViewController = pageViewController.viewControllers.firstObject;
        self.navigationItem.title = [NSString stringWithFormat:@"%ld / %ld", (long)(self.currentVisibleViewController.pageIndex+1), (unsigned long)self.viewModel.contentImages.count];
    }
}

#pragma mark - UIPageViewControllerDataSource

- (ImagePreviewViewController *)imagePreviewViewControllerForPageIndex:(NSInteger)index {
    if (self.viewModel.contentImages.count <= index || !self.viewModel.contentImages) {
        return nil;
    }
    
    CDContent *content = self.viewModel.contentImages[index];
    FileImageView *imageView = [FileImageView new];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [imageView updateWithContent:content];
    ImagePreviewViewController *viewController = [[ImagePreviewViewController alloc] initWithImageView:imageView pageIndex:index];
    return viewController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pvc viewControllerBeforeViewController:(ImagePreviewViewController *)vc {
    NSUInteger index = vc.pageIndex;
    return [self imagePreviewViewControllerForPageIndex:(index - 1)];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pvc viewControllerAfterViewController:(ImagePreviewViewController *)vc {
    NSUInteger index = vc.pageIndex;
    return [self imagePreviewViewControllerForPageIndex:(index + 1)];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] || [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
        return NO;
    return YES;
}

@end
