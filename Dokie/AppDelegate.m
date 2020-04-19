//
//  AppDelegate.m
//  Doci
//
//  Created by Ashamaz Shidov on 02/12/2018.
//  Copyright © 2018 Ashamaz Shidov. All rights reserved.
//

#import "AppDelegate.h"
#import "NavigationRouter.h"
#import "AppearanceManager.h"
#import "Logger.h"

@interface AppDelegate ()

@property (strong, nonatomic) NSManagedObjectContext *objectContext;
@property (nonatomic, strong) NSURL *modelUrl;
@property (nonatomic, strong) NSURL *storeUrl;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSPersistentStoreCoordinator *migrationPersistentStoreCoordinator;

@property (nonatomic, strong, readonly) NavigationRouter *navigationRouter;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.modelUrl = [[NSBundle mainBundle] URLForResource:@"Dokie" withExtension:@"momd"];
    self.storeUrl = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"Main.sqlite"];

    [AppearanceManager setupAppearance];
    [self configureMainCoreData];
    [self.navigationRouter createLoginViewController];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    [self.navigationRouter blur];
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self.navigationRouter unblur];
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
}


#pragma mark - Core Data stack

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:self.modelUrl];
    return _managedObjectModel;
}

- (void)clearMainCoreDataFiles {
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self.storeUrl path]]) {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtURL:self.storeUrl error:&error];
        if (error) {
            WriteLog(kLogTypeCrash, @"Can't remove main file at url %@. Error: %@", self.storeUrl.path, error.localizedDescription);
        }
        else {
            error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:[[self.storeUrl path] stringByAppendingString:@"-shm"] error:&error];
            if (error) {
                WriteLog(kLogTypeCrash, @"Can't remove main shm file. Error: %@", error.localizedDescription);
            }
            error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:[[self.storeUrl path] stringByAppendingString:@"-wal"] error:&error];
            if (error) {
                WriteLog(kLogTypeCrash, @"Can't remove main wal file. Error: %@", error.localizedDescription);
            }
        }
    }
}

- (NSPersistentStoreCoordinator *)createMainStoreCoordinator {
    NSPersistentStoreCoordinator *toReturn = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    NSError *error = nil;
    if (![toReturn addPersistentStoreWithType:NSSQLiteStoreType configuration:@"Default" URL:self.storeUrl options:options error:&error]) {
        [self clearMainCoreDataFiles];
        error = nil;
        
        if (![toReturn addPersistentStoreWithType:NSSQLiteStoreType configuration:@"Default" URL:self.storeUrl options:options error:&error]) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
            dict[NSLocalizedFailureReasonErrorKey] = @"There was an error creating or loading the application's saved data. Main context";
            dict[NSUnderlyingErrorKey] = error;
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
            WriteLog(kLogTypeCrash, @"Unresolved error %@, %@", error, [error userInfo]);
        }
    }

    return toReturn;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [self createMainStoreCoordinator];
    
#if !(TARGET_OS_EMBEDDED)  // This will work for Mac or Simulator but excludes physical iOS devices
#ifdef DEBUG
    // @(1) is NSSQLiteStoreType
    [self createCoreDataDebugProjectWithType:@(1) storeUrl:[self.storeUrl absoluteString] modelFilePath:[self.modelUrl absoluteString]];
#endif
#endif
    
    return _persistentStoreCoordinator;
}

#if !(TARGET_OS_EMBEDDED)  // This will work for Mac or Simulator but excludes physical iOS devices
- (void) createCoreDataDebugProjectWithType: (NSNumber*) storeFormat storeUrl:(NSString*) storeURL modelFilePath:(NSString*) modelFilePath {
    NSDictionary* project = @{
                              @"storeFilePath": storeURL,
                              @"storeFormat" : storeFormat,
                              @"modelFilePath": modelFilePath,
                              @"v" : @(1)
                              };
    
    NSString* projectFile = [NSString stringWithFormat:@"/tmp/%@.cdp", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey]];
    
    [project writeToFile:projectFile atomically:YES];
    
}
#endif

- (void)configureMainCoreData {
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        WriteLog(kLogTypeCrash, @"Can't create main store coordinator");
        _objectContext = nil;
        return;
    }
    
    _objectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_objectContext setPersistentStoreCoordinator:coordinator];
    [_objectContext setMergePolicy:[[NSMergePolicy alloc] initWithMergeType:NSRollbackMergePolicyType]];
    [_objectContext setUndoManager:nil];
    [_objectContext setShouldDeleteInaccessibleFaults:YES];
}

- (NavigationRouter *)navigationRouter {
    return [NavigationRouter shared];
}

@end
