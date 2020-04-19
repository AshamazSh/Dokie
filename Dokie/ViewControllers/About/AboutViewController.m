//
//  AboutViewController.m
//  Dokie
//
//  Created by Ashamaz Shidov on 19.04.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

#import "AboutViewController.h"
#import "UI.h"
#import "AppearanceManager.h"

#import <ReactiveObjC/ReactiveObjC.h>

@interface AboutViewController ()

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)setup {
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"OK", @"OK button text") style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.leftBarButtonItems = @[cancelButton];
    @weakify(self);
    cancelButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id _) {
        @strongify(self);
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        return [RACSignal empty];
    }];

    UIImageView *iconImage = [UI imageView];
    iconImage.image = [UIImage imageNamed:@"transparent_icon.png"];
    [self.view addSubview:iconImage];
    
    UITextView *textView = [UITextView new];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.dataDetectorTypes = UIDataDetectorTypeAll;
    textView.text = [NSString stringWithFormat:@"%@\n\n%@ %@\n\n%@ %@\n\n\n\n%@ %@", NSLocalizedString(@"Dokie is free and open source application.", @"Dokie info text"), NSLocalizedString(@"Source code:", @"Source code text"), @"https://github.com/AshamazSh/Dokie", NSLocalizedString(@"Contacts:", @"Contacts text"), @"ashamazsh@gmail.com", NSLocalizedString(@"Version:", @"Version text"), [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    textView.editable = NO;
    textView.textColor = [AppearanceManager tintColor];
    textView.backgroundColor = [AppearanceManager backgroundColor];
    textView.font = [UIFont systemFontOfSize:18];
    [self.view addSubview:textView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(iconImage, textView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[iconImage(100)]-20-[textView]" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[iconImage(100)]" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[textView]-20-|" options:0 metrics:nil views:views]];
    [NSLayoutConstraint activateConstraints:@[[iconImage.centerXAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.centerXAnchor],
                                              [textView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]]];
}

@end
