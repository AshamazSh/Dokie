//
//  DocumentImagesPageViewModel.m
//  Dokie
//
//  Created by Ashamaz Shidov on 26.01.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import "DocumentImagesPageViewModel.h"
#import "CoreDataInclude.h"
#import "CoreDataManager.h"
#import "NavigationRouter.h"

@interface DocumentImagesPageViewModel()

@property (nonatomic, strong) NSArray<CDContent *> *contentImages;
@property (nonatomic) NSInteger firstIndex;

@property (nonatomic, strong, readonly) CoreDataManager *coreDataManager;
@property (nonatomic, strong, readonly) NavigationRouter *navigationRouter;

@end

@implementation DocumentImagesPageViewModel

- (instancetype)initWithContentImages:(NSArray<CDContent *> *)contentImages firstIndex:(NSInteger)index {
    self = [super init];
    if (self) {
        self.contentImages = contentImages;
        self.firstIndex = index;
    }
    return self;
}

#pragma mark - Get Set

- (CoreDataManager *)coreDataManager {
    return [CoreDataManager shared];
}

- (NavigationRouter *)navigationRouter {
    return [NavigationRouter shared];
}

@end
