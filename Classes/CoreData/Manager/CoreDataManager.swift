//
//  CoreDataManager.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 15.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import Foundation
import CoreData
import ReactiveSwift
import ReactiveCocoa

class CoreDataManager {
    
    static let shared = CoreDataManager()
    
    private init() {}
    
    private var encryptionManager: EncryptionManager!
    private var context: NSManagedObjectContext!
    private var scheduler: CoreDataScheduler!
    private let notificationCenter = NotificationCenter.default
    
    enum CoreDataManagerError: Error, LocalizedError {
        case invalidPassword
        case unknownError
        case wrongType
        case fetchFailed
        case objectCreationFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidPassword:
                return String.localized("Invalid password")
            case .unknownError:
                return String.localized("Some error occured. Please try again later.")
            case .wrongType:
                return String.localized("Type casting error. Wrong type.")
            case .fetchFailed:
                return String.localized("Can not fetch objects.")
            case .objectCreationFailed:
                return String.localized("Can not create object.")
            }
        }
    }
    
    func setup(encryptionManager: EncryptionManager, context: NSManagedObjectContext) {
        self.encryptionManager = encryptionManager
        self.context = context
        self.scheduler = CoreDataScheduler(context: context)
    }
    
    func reset() {
        encryptionManager = nil
        context = nil
        scheduler = nil
    }
    
    func changePassword(_ password: String, to newPassword: String) -> SignalProducer<Never, CoreDataManagerError> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                guard self.encryptionManager.check(password: password) == true else {
                    observer.send(error: CoreDataManagerError.invalidPassword)
                    return
                }
                
                guard self.encryptionManager.changePassword(to: newPassword) == true else {
                    observer.send(error: CoreDataManagerError.unknownError)
                    return
                }
                
                observer.sendCompleted()
            }
        }
    }
    
}

extension CoreDataManager {
    
    func name(of folder: CDFolder?) -> SignalProducer<String, Error> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                if let folder = folder {
                    do {
                        let json = try self.encryptionManager.decryptedJson(from: folder.data)
                        observer.send(value: self.folderName(from: json) ?? "")
                        observer.sendCompleted()
                    }
                    catch let error {
                        observer.send(error: error)
                    }
                }
                else {
                    observer.send(value: String.localized("Root"))
                }
            }
        }
    }
    
    struct DecryptedFolderName {
        let folder: CDFolder
        let name: String
        let decryptionError: Error?
    }
    
    func subfolderNamesIn(folder: CDFolder?) -> SignalProducer<[DecryptedFolderName], CoreDataManagerError> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                if let folder = folder {
                    guard let subfolders = folder.subfolders else {
                        observer.send(value: [])
                        observer.sendCompleted()
                        return
                    }
                    
                    subfolders.fetchObjectsIfNeeded(context: self.context)
                    var names = [DecryptedFolderName]()
                    for subfolder in subfolders {
                        do {
                            let json = try self.encryptionManager.decryptedJson(from: subfolder.data)
                            names.append(DecryptedFolderName(folder: subfolder,
                                                             name: self.folderName(from: json) ?? "",
                                                             decryptionError: nil))
                        }
                        catch let error {
                            names.append(DecryptedFolderName(folder: subfolder,
                                                             name: "",
                                                             decryptionError: error))
                        }
                    }
                    observer.send(value: names)
                    observer.sendCompleted()
                }
                else {
                    let predicate = NSPredicate(format: "%K == NULL", CDFolder.kParentFolder)
                    let request = CDFolder.fetchRequest()
                    request.returnsObjectsAsFaults = false
                    request.predicate = predicate
                    
                    do {
                        guard let fetchedItems = try self.context.fetch(request) as? [CDFolder] else {
                            observer.send(error: CoreDataManagerError.wrongType)
                            return
                        }
                        var names = [DecryptedFolderName]()
                        for subfolder in fetchedItems {
                            do {
                                let json = try self.encryptionManager.decryptedJson(from: subfolder.data)
                                names.append(DecryptedFolderName(folder: subfolder,
                                                                 name: self.folderName(from: json) ?? "",
                                                                 decryptionError: nil))
                            }
                            catch let error {
                                names.append(DecryptedFolderName(folder: subfolder,
                                                                 name: "",
                                                                 decryptionError: error))
                            }
                        }
                        observer.send(value: names)
                        observer.sendCompleted()
                    }
                    catch {
                        observer.send(error: CoreDataManagerError.fetchFailed)
                    }
                }
            }
        }
    }
    
    struct DecryptedDocumentName {
        let document: CDDocument
        let name: String
        let decryptionError: Error?
    }
    
    func documentNamesIn(folder: CDFolder?) -> SignalProducer<[DecryptedDocumentName], CoreDataManagerError> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                if let folder = folder {
                    guard let documents = folder.documents else {
                        observer.send(value: [])
                        observer.sendCompleted()
                        return
                    }
                    
                    documents.fetchObjectsIfNeeded(context: self.context)
                    var names = [DecryptedDocumentName]()
                    for document in documents {
                        do {
                            let json = try self.encryptionManager.decryptedJson(from: document.data)
                            names.append(DecryptedDocumentName(document: document,
                                                               name: self.documentName(from: json) ?? "",
                                                               decryptionError: nil))
                        }
                        catch let error {
                            names.append(DecryptedDocumentName(document: document,
                                                               name: "",
                                                               decryptionError: error))
                        }
                    }
                    observer.send(value: names)
                    observer.sendCompleted()
                }
                else {
                    let predicate = NSPredicate(format: "%K == NULL", CDDocument.kFolder)
                    let request = CDDocument.fetchRequest()
                    request.returnsObjectsAsFaults = false
                    request.predicate = predicate
                    
                    do {
                        guard let fetchedItems = try self.context.fetch(request) as? [CDDocument] else {
                            observer.send(error: CoreDataManagerError.wrongType)
                            return
                        }
                        var names = [DecryptedDocumentName]()
                        for document in fetchedItems {
                            do {
                                let json = try self.encryptionManager.decryptedJson(from: document.data)
                                names.append(DecryptedDocumentName(document: document,
                                                                   name: self.documentName(from: json) ?? "",
                                                                   decryptionError: nil))
                            }
                            catch let error {
                                names.append(DecryptedDocumentName(document: document,
                                                                   name: "",
                                                                   decryptionError: error))
                            }
                        }
                        observer.send(value: names)
                        observer.sendCompleted()
                    }
                    catch {
                        observer.send(error: CoreDataManagerError.fetchFailed)
                    }
                }
            }
        }
    }
    
    struct DecryptedDocumentContent {
        let content: CDContent
        let decrypted: [String : Any]
        let decryptionError: Error?
    }
    
    func decrypted(document: CDDocument) -> SignalProducer<[DecryptedDocumentContent], Never> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                guard let contents = document.content else {
                    observer.send(value: [])
                    observer.sendCompleted()
                    return
                }
                
                var decrypted = [DecryptedDocumentContent]()
                for i in 0..<contents.count {
                    if let content = contents[i] as? CDContent {
                        do {
                            let json = try self.encryptionManager.decryptedJson(from: content.data)
                            decrypted.append(DecryptedDocumentContent(content: content,
                                                                      decrypted: json,
                                                                      decryptionError: nil))
                        }
                        catch let error {
                            decrypted.append(DecryptedDocumentContent(content: content,
                                                                      decrypted: [:],
                                                                      decryptionError: error))
                        }
                    }
                }
                
                observer.send(value: decrypted)
                observer.sendCompleted()
            }
        }
    }
    
    func decrypted(content: CDContent) -> SignalProducer<[String : Any], Error> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                do {
                    let json = try self.encryptionManager.decryptedJson(from: content.data)
                    observer.send(value: json)
                    observer.sendCompleted()
                }
                catch let error {
                    observer.send(error: error)
                }
            }
        }
    }
    
    func imageFrom(content: CDContent) -> SignalProducer<UIImage?, Error> {
        return decrypted(content: content).flatMap(.latest) { [unowned self] (json) -> SignalProducer<UIImage?, Error> in
            if let type = json[C.contentTypeKey] as? String,
                type == C.contentTypeFile,
                let fileId = json[C.contentFileIdKey] as? String {
                do {
                    if let objects = try self.allObjects(className: CDFile.entity().name!, predicate: NSPredicate(format: "%K == %@", CDFile.kIdentifier, fileId), in: self.context) as? [CDFile],
                        objects.isEmpty == false {
                        let file = objects[0]
                        if let data = try self.encryptionManager.decrypted(data: file.data) {
                            return SignalProducer<UIImage?, Error>(value: UIImage(data: data))
                        }
                    }
                }
                catch {
                    return SignalProducer<UIImage?, Error>(value: nil)
                }
            }
            
            return SignalProducer<UIImage?, Error>(value: nil)
        }
    }
    
}

extension CoreDataManager {
    
    func createSubfolder(name subfolderName: String, in folder: CDFolder?) -> SignalProducer<CDFolder, Error> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                guard let subfolder = NSEntityDescription.insertNewObject(forEntityName: CDFolder.entity().name!, into: self.context) as? CDFolder else {
                    observer.send(error: CoreDataManagerError.objectCreationFailed)
                    return
                }
                do {
                    let data = try self.encryptionManager.encryptedJson(from: [C.folderNameKey : subfolderName])
                    subfolder.data = data
                    subfolder.date = Date()
                    subfolder.parentFolder = folder
                    
                    do {
                        try self.context.save()
                        self.notificationCenter.post(name: NSNotification.Name(rawValue: C.reloadFolderNotification), object: subfolder)
                        
                        observer.send(value: subfolder)
                        observer.sendCompleted()
                    }
                    catch let error {
                        self.context.rollback()
                        observer.send(error: error)
                    }
                }
                catch let error {
                    observer.send(error: error)
                }
            }
        }
    }
    
    func rename(folder: CDFolder, to folderName: String) -> SignalProducer<CDFolder, Error> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                do {
                    let data = try self.encryptionManager.encryptedJson(from: [C.folderNameKey : folderName])
                    folder.data = data
                    
                    do {
                        try self.context.save()
                        self.notificationCenter.post(name: NSNotification.Name(rawValue: C.reloadFolderNotification), object: folder)
                        
                        observer.send(value: folder)
                        observer.sendCompleted()
                    }
                    catch let error {
                        self.context.rollback()
                        observer.send(error: error)
                    }
                }
                catch let error {
                    observer.send(error: error)
                }
            }
        }
    }
    
    private func allDocuments(in folder: CDFolder) -> [CDDocument] {
        var toReturn = [CDDocument]()
        if let subfolders = folder.subfolders {
            subfolders.fetchObjectsIfNeeded(context: context)
            for subfolder in subfolders {
                toReturn.append(contentsOf: allDocuments(in: subfolder))
            }
        }
        
        if let documents = folder.documents {
            documents.fetchObjectsIfNeeded(context: context)
            toReturn.append(contentsOf: documents)
        }
        
        return toReturn
    }
    
    private func allSubfolders(in folder: CDFolder) -> [CDFolder] {
        var toReturn = [CDFolder]()
        if let subfolders = folder.subfolders {
            subfolders.fetchObjectsIfNeeded(context: context)
            toReturn.append(contentsOf: subfolders)
        }
        
        return toReturn
    }
    
    func delete(folder: CDFolder) -> SignalProducer<Bool, Error> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                do {
                    let allDocuments = self.allDocuments(in: folder)
                    for document in allDocuments {
                        try self.deleteContentFiles(in: document)
                    }
                    let parent = folder.parentFolder
                    self.context.delete(folder)
                    do {
                        try self.context.save()
                        self.notificationCenter.post(name: NSNotification.Name(rawValue: C.reloadFolderNotification), object: parent)
                        observer.send(value: true)
                        observer.sendCompleted()
                    }
                    catch let error {
                        self.context.rollback()
                        observer.send(error: error)
                    }
                }
                catch let error {
                    observer.send(error: error)
                }
            }
        }
    }
    
}

extension CoreDataManager {
    
    func createDocument(name documentName: String, in folder: CDFolder?) -> SignalProducer<CDDocument, Error> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                guard let document = NSEntityDescription.insertNewObject(forEntityName: CDDocument.entity().name!, into: self.context) as? CDDocument else {
                    observer.send(error: CoreDataManagerError.objectCreationFailed)
                    return
                }
                do {
                    let data = try self.encryptionManager.encryptedJson(from: [C.documentNameKey : documentName])
                    document.data = data
                    document.date = Date()
                    document.folder = folder
                    
                    do {
                        try self.context.save()
                        self.notificationCenter.post(name: NSNotification.Name(rawValue: C.reloadFolderNotification), object: folder)
                        
                        observer.send(value: document)
                        observer.sendCompleted()
                    }
                    catch let error {
                        self.context.rollback()
                        observer.send(error: error)
                    }
                }
                catch let error {
                    observer.send(error: error)
                }
            }
        }
    }
    
    func rename(document: CDDocument, to documentName: String) -> SignalProducer<CDDocument, Error> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                do {
                    let data = try self.encryptionManager.encryptedJson(from: [C.documentNameKey : documentName])
                    document.data = data
                    
                    do {
                        try self.context.save()
                        self.notificationCenter.post(name: NSNotification.Name(rawValue: C.reloadFolderNotification), object: document.folder)
                        
                        observer.send(value: document)
                        observer.sendCompleted()
                    }
                    catch let error {
                        self.context.rollback()
                        observer.send(error: error)
                    }
                }
                catch let error {
                    observer.send(error: error)
                }
            }
        }
    }
    
    func delete(document: CDDocument) -> SignalProducer<Bool, Error> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                do {
                    try self.deleteContentFiles(in: document)
                    let folder = document.folder
                    self.context.delete(document)
                    do {
                        try self.context.save()
                        self.notificationCenter.post(name: NSNotification.Name(rawValue: C.reloadFolderNotification), object: folder)
                        observer.send(value: true)
                        observer.sendCompleted()
                    }
                    catch let error {
                        self.context.rollback()
                        observer.send(error: error)
                    }
                }
                catch let error {
                    observer.send(error: error)
                }
            }
        }
    }
    
    func name(of document: CDDocument) -> SignalProducer<String, Error> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                do {
                    let json = try self.encryptionManager.decryptedJson(from: document.data)
                    observer.send(value: self.documentName(from: json) ?? "")
                    observer.sendCompleted()
                }
                catch let error {
                    observer.send(error: error)
                }
            }
        }
    }
    
    fileprivate func deleteContentFiles(in document: CDDocument) throws {
        if let contents = document.content?.set as? Set<CDContent>  {
            contents.fetchObjectsIfNeeded(context: context)
            for content in contents {
                try deleteFile(in: content)
            }
        }
    }
    
}

extension CoreDataManager {
    
    func createFile(with fileContent: Data) -> SignalProducer<CDFile, Error> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                guard let file = NSEntityDescription.insertNewObject(forEntityName: CDFile.entity().name!, into: self.context) as? CDFile else {
                    observer.send(error: CoreDataManagerError.objectCreationFailed)
                    return
                }
                
                do {
                    let data = try self.encryptionManager.encrypted(data: fileContent)
                    file.data = data
                    file.identifier = UUID().uuidString
                    
                    do {
                        try self.context.save()
                        observer.send(value: file)
                        observer.sendCompleted()
                    }
                    catch let error {
                        self.context.rollback()
                        observer.send(error: error)
                    }
                }
                catch let error {
                    observer.send(error: error)
                }
            }
        }
    }

    func createMultipleFiles(with fileContents: [Data]) -> SignalProducer<[CDFile], Error> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                var files = [CDFile]()
                for fileContent in fileContents {
                    guard let file = NSEntityDescription.insertNewObject(forEntityName: CDFile.entity().name!, into: self.context) as? CDFile else {
                        observer.send(error: CoreDataManagerError.objectCreationFailed)
                        return
                    }
                    
                    do {
                        let data = try self.encryptionManager.encrypted(data: fileContent)
                        file.data = data
                        file.identifier = UUID().uuidString
                        files.append(file)
                    }
                    catch let error {
                        observer.send(error: error)
                    }
                }
                
                do {
                    try self.context.save()
                    observer.send(value: files)
                    observer.sendCompleted()
                }
                catch let error {
                    self.context.rollback()
                    observer.send(error: error)
                }
            }
        }
    }

    func add(content: [String : Any], to document:CDDocument) -> SignalProducer<CDContent, Error> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                guard let contentObject = NSEntityDescription.insertNewObject(forEntityName: CDContent.entity().name!, into: self.context) as? CDContent else {
                    observer.send(error: CoreDataManagerError.objectCreationFailed)
                    return
                }
                do {
                    let data = try self.encryptionManager.encryptedJson(from: content)
                    contentObject.data = data
                    contentObject.document = document
                    
                    do {
                        try self.context.save()
                        observer.send(value: contentObject)
                        observer.sendCompleted()
                    }
                    catch let error {
                        self.context.rollback()
                        observer.send(error: error)
                    }
                }
                catch let error {
                    observer.send(error: error)
                }
            }
        }
    }

    func addMultiple(contents: [[String : Any]], to document:CDDocument) -> SignalProducer<[CDContent], Error> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                var result = [CDContent]()
                for content in contents {
                    guard let contentObject = NSEntityDescription.insertNewObject(forEntityName: CDContent.entity().name!, into: self.context) as? CDContent else {
                        observer.send(error: CoreDataManagerError.objectCreationFailed)
                        return
                    }
                    do {
                        let data = try self.encryptionManager.encryptedJson(from: content)
                        contentObject.data = data
                        contentObject.document = document
                        result.append(contentObject)
                    }
                    catch let error {
                        observer.send(error: error)
                    }
                }
                
                do {
                    try self.context.save()
                    observer.send(value: result)
                    observer.sendCompleted()
                }
                catch let error {
                    self.context.rollback()
                    observer.send(error: error)
                }
            }
        }
    }

    func update(content: CDContent, with dictionary:[String : Any]) -> SignalProducer<CDContent, Error> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                do {
                    let data = try self.encryptionManager.encryptedJson(from: dictionary)
                    content.data = data
                    
                    do {
                        try self.context.save()
                        observer.send(value: content)
                        observer.sendCompleted()
                    }
                    catch let error {
                        self.context.rollback()
                        observer.send(error: error)
                    }
                }
                catch let error {
                    observer.send(error: error)
                }
            }
        }
    }
    
    func delete(content: CDContent) -> SignalProducer<Bool, Error> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                do {
                    try self.deleteFile(in: content)
                    self.context.delete(content)
                    do {
                        try self.context.save()
                        observer.send(value: true)
                        observer.sendCompleted()
                    }
                    catch let error {
                        self.context.rollback()
                        observer.send(error: error)
                    }
                    
                }
                catch let error {
                    observer.send(error: error)
                }
            }
        }
    }
    
    fileprivate func deleteFile(in content: CDContent) throws {
        let json = try encryptionManager.decryptedJson(from: content.data)
        if let type = json[C.contentTypeKey] as? String,
            type == C.contentTypeFile,
            let fileId = json[C.contentTypeFile] as? String,
            let objects = try allObjects(className: CDFile.entity().name!, predicate: NSPredicate(format: "%K == %@", CDFile.kIdentifier, fileId), in: context) as? [CDFile] {
            let file = objects[0]
            
            context.delete(file)
        }
        
    }
}

extension CoreDataManager {

    func add(tag: String, to document: CDDocument) -> SignalProducer<CDTag, Error> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                guard let tagObject = NSEntityDescription.insertNewObject(forEntityName: CDTag.entity().name!, into: self.context) as? CDTag else {
                    observer.send(error: CoreDataManagerError.objectCreationFailed)
                    return
                }
                
                tagObject.document = document
                tagObject.text = tag
                do {
                    try self.context.save()
                    observer.send(value: tagObject)
                    observer.sendCompleted()
                }
                catch let error {
                    self.context.rollback()
                    observer.send(error: error)
                }
            }
        }
    }

    func rename(tag: CDTag, to text: String) -> SignalProducer<CDTag, Error> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                tag.text = text
                do {
                    try self.context.save()
                    observer.send(value: tag)
                    observer.sendCompleted()
                }
                catch let error {
                    self.context.rollback()
                    observer.send(error: error)
                }
            }
        }
    }

    func delete(tag: CDTag) -> SignalProducer<Bool, Error> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                self.context.delete(tag)
                do {
                    try self.context.save()
                    observer.send(value: true)
                    observer.sendCompleted()
                }
                catch let error {
                    self.context.rollback()
                    observer.send(error: error)
                }
            }
        }
    }
    
    func findDocuments(tagedWith searchTexts: [String]) -> SignalProducer<[DecryptedDocumentName], Never> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            self.scheduler.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                var predicates = [NSPredicate]()
                for text in searchTexts {
                    predicates.append(NSPredicate(format: "%K CONTAINS[c] %@", CDTag.kText, text))
                }
                
                let request = CDTag.fetchRequest()
                request.returnsObjectsAsFaults = false
                request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
                
                if let tags = try? self.context.fetch(request) as? [CDTag] {
                    var documentsToFetch = Set<CDDocument>()
                    for tag in tags {
                        if let document = tag.document {
                            documentsToFetch.insert(document)
                        }
                    }
                    
                    documentsToFetch.fetchObjectsIfNeeded(context: self.context)
                    var names = [DecryptedDocumentName]()
                    for document in documentsToFetch {
                        do {
                            let json = try self.encryptionManager.decryptedJson(from: document.data)
                            names.append(DecryptedDocumentName(document: document,
                                                               name: self.documentName(from: json) ?? "",
                                                               decryptionError: nil))
                        }
                        catch let error {
                            names.append(DecryptedDocumentName(document: document,
                                                               name: "",
                                                               decryptionError: error))
                        }
                    }
                    observer.send(value: names)
                }
                else {
                    observer.send(value: [])
                }
                
                observer.sendCompleted()
            }
        }
    }
    
}


extension CoreDataManager {
    
    fileprivate func folderName(from json: [String : Any]) -> String? {
        return json[C.folderNameKey] as? String
    }
    
    fileprivate func documentName(from json: [String : Any]) -> String? {
        return json[C.documentNameKey] as? String
    }
    
}

extension CoreDataManager {
    
    fileprivate func allObjects<T: NSManagedObject>(className: String, in context: NSManagedObjectContext) throws -> [T] {
        return try allObjects(className: className, predicate: nil, in: context)
    }
    
    fileprivate func allObjects<T: NSManagedObject>(className: String, predicate: NSPredicate?, in context: NSManagedObjectContext) throws -> [T] {
        return try allObjects(className: className, predicate: predicate, sortDescriptors: nil, in: context)
    }
    
    fileprivate func allObjects<T: NSManagedObject>(className: String, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?, in context: NSManagedObjectContext) throws -> [T] {
        let entityDescription = NSEntityDescription.entity(forEntityName: className, in: context)
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = entityDescription
        request.returnsObjectsAsFaults = false
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        if let objects = try context.fetch(request) as? [T] {
            return objects
        }
        throw CoreDataManagerError.fetchFailed
    }
    
}

extension Set where Element: NSManagedObject {
    
    @discardableResult func fetchObjectsIfNeeded(context: NSManagedObjectContext) -> Set<Element> {
        var persistantObjects = Set<Element>()
        var inMemoryObjects = Set<Element>()
        
        for object in self {
            if object.objectID.isTemporaryID {
                inMemoryObjects.insert(object)
            }
            else {
                persistantObjects.insert(object)
            }
        }
        
        if persistantObjects.count == 0 { return self }
        
        var fetchFromDb = false
        for object in persistantObjects {
            if object.isFault == true {
                fetchFromDb = true
                break
            }
        }
        
        if fetchFromDb == false { return self }
        
        var contextForFetch = context
        while let parentContext = contextForFetch.parent {
            contextForFetch = parentContext
        }
        
        var fetchedObjects = Set<Element>()
        if context != contextForFetch {
            var objectIds = [NSManagedObjectID]()
            if contextForFetch.concurrencyType != .mainQueueConcurrencyType || Thread.isMainThread == false {
                contextForFetch.performAndWait {
                    objectIds = persistantObjects.fetchObjects(context: contextForFetch).map{ $0.objectID }
                }
            }
            else {
                objectIds = persistantObjects.fetchObjects(context: contextForFetch).map{ $0.objectID }
            }
            
            fetchedObjects = Set(objectIds.compactMap{
                do {
                    guard let object = try context.existingObject(with: $0) as? Element else { return nil }
                    return object
                }
                catch let error {
                    assertionFailure(error.localizedDescription)
                    return nil
                }
            })
        }
        else {
            fetchedObjects = persistantObjects.fetchObjects(context: context)
        }
        
        if fetchedObjects.count > 0 {
            inMemoryObjects = inMemoryObjects.union(Set(fetchedObjects))
        }
        return inMemoryObjects
    }
    
    private func fetchObjects(context: NSManagedObjectContext) -> Set<Element> {
        var fetchedObjects = Set<Element>()
        do {
            fetchedObjects = try context.fireFaults(objects: self)
        }
        catch let error {
            assertionFailure(error.localizedDescription)
        }
        
        return fetchedObjects
    }
    
}

extension NSManagedObjectContext {
    
    enum FetchErrors: Error, LocalizedError {
        case wrongType
        
        var errorDescription: String? {
            switch self {
            case .wrongType:
                return "Type casting error. Wrong type."
            }
        }
    }
    
    func fireFaults<T: NSManagedObject>(objects: Set<T>) throws -> Set<T> {
        guard let anyObject = objects.first,
            let entityName = anyObject.entity.name else {
                return objects
        }
        
        let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: self)
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = entityDescription
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "SELF IN %@", objects)
        
        guard let toReturn = try fetch(request) as? [T] else { throw FetchErrors.wrongType }
        return Set(toReturn)
    }
    
}
