//
//  AppDelegate.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 14.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    lazy private var modelUrl: URL! = Bundle.main.url(forResource: "Dokie", withExtension: "momd")
    lazy private var storeUrl: URL! = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last?.appendingPathComponent("Main.sqlite")
    private(set) var objectContext: NSManagedObjectContext!
    private var managedObjectModel: NSManagedObjectModel!
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator!
    private let navigationRouter = NavigationRouter.shared
    private let localAuth = LocalAuth.shared
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Appearance.setDefaultColors()
        configureMainCoreData()
        navigationRouter.createLoginViewController()
        return true
    }

    func clearMainCoreDataFiles() {
        if (FileManager.default.fileExists(atPath: storeUrl.path)) {
            do {
                try FileManager.default.removeItem(atPath: storeUrl.path)
                try FileManager.default.removeItem(atPath: storeUrl.path.appending("-shm"))
                try FileManager.default.removeItem(atPath: storeUrl.path.appending("-wal"))
            }
            catch let error {
                fatalError("Unresolved error \(error)")
            }
        }

    }
    
    func configureMainCoreData() {
        managedObjectModel = NSManagedObjectModel(contentsOf: modelUrl)
        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        let description = NSPersistentStoreDescription()
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                              configurationName: "Default",
                                                              at: storeUrl,
                                                              options: [NSMigratePersistentStoresAutomaticallyOption : true,
                                                                        NSInferMappingModelAutomaticallyOption : true])
        }
        catch {
            clearMainCoreDataFiles()
            do {
                try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                                  configurationName: "Default",
                                                                  at: storeUrl,
                                                                  options: [NSMigratePersistentStoresAutomaticallyOption : true,
                                                                            NSInferMappingModelAutomaticallyOption : true])
            }
            catch let error {
                fatalError("Unresolved error \(error)")
            }
        }
        
        objectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        objectContext.persistentStoreCoordinator = persistentStoreCoordinator
        objectContext.mergePolicy = NSMergePolicy(merge: .rollbackMergePolicyType)
        objectContext.undoManager = nil
        objectContext.shouldDeleteInaccessibleFaults = true
    }
    
}

