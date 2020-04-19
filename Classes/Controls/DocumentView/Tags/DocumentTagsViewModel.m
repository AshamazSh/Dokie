//
//  DocumentTagsViewModel.m
//  Dokie
//
//  Created by Ashamaz Shidov on 26/12/2019.
//  Copyright © 2019 Ashamaz Shidov. All rights reserved.
//

#import "DocumentTagsViewModel.h"
#import "CoreDataInclude.h"

@interface DocumentTagsViewModel ()

@property (nonatomic, strong) CDDocument *document;
@property (nonatomic, strong) NSArray<NSString *> *tags;

@end

@implementation DocumentTagsViewModel

- (instancetype)initWithDocument:(CDDocument *)document {
    self = [super init];
    if (self) {
        self.document = document;
        [self setup];
    }
    return self;
}

- (void)setup {
    NSMutableArray<NSString *> *tags = [NSMutableArray array];
    for (NSInteger i = 0; i < self.document.tags.count; ++i) {
        CDTag *tag = self.document.tags[i];
        [tags addObject:tag.text ?: @""];
    }
    self.tags = [tags copy];
}

- (RACSignal *)addTagWithText:(NSString *)text {
    return [RACSignal empty];
}

- (RACSignal *)removeTagAtIndex:(NSUInteger)index {
    return [RACSignal empty];
}

@end
