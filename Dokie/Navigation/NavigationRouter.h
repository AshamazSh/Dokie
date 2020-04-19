//
//  NavigationRouter.h
//  Doci
//
//  Created by Ashamaz Shidov on 02/12/2018.
//  Copyright © 2018 Ashamaz Shidov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@class EncryptionManager;
@class CDDocument;
@class CDFolder;
@class CDContent;

@interface NavigationRouter : NSObject

+ (instancetype)shared;

- (void)createLoginViewController;
- (void)pushMainMenuWithEncryptionManager:(EncryptionManager *)encryptionManager managedObjectContext:(NSManagedObjectContext *)objectContext;
- (void)pushFolder:(CDFolder * _Nullable)folder;
- (void)pushDocument:(CDDocument *)document;
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)showAlert:(UIAlertController *)alert;
- (void)showImagePicker:(UIImagePickerController *)imagePicker;
- (void)shareItems:(NSArray *)items;
- (void)showDocumentImages:(NSArray<CDContent *> *)contentImages firstIndex:(NSInteger)index;
- (void)logout;
- (void)showChangePassword;
- (void)showAbout;

- (NSString *)showLoading;
- (void)hideLoading:(NSString *)guid;
- (void)blur;
- (void)unblur;

@end

NS_ASSUME_NONNULL_END
