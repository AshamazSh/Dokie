//
//  FileImageView.m
//  Dokie
//
//  Created by Ashamaz Shidov on 26.01.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import "FileImageView.h"
#import "CoreDataManager.h"

#import <ReactiveObjC/ReactiveObjC.h>

@interface FileImageView()

@property (nonatomic, strong) RACSubject *stopSubject;
@property (nonatomic, strong, readonly) CoreDataManager *coreDataManager;

@end

@implementation FileImageView

- (void)updateWithContent:(CDContent *)content {
    self.image = nil;
    [self.stopSubject sendNext:nil];
    @weakify(self);
    [[[[self.coreDataManager imageFromContent:content]
       takeUntil:self.stopSubject]
      deliverOnMainThread]
     subscribeNext:^(UIImage *image) {
        @strongify(self);
        self.image = image;
    }];
}

- (RACSubject *)stopSubject {
    if (!_stopSubject) {
        _stopSubject = [RACSubject new];
    }
    return _stopSubject;
}

- (CoreDataManager *)coreDataManager {
    return [CoreDataManager shared];
}

@end
