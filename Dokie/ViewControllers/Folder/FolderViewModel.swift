//
//  FolderViewModel.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 25.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift

class FolderViewModel: NSObject {
    
    let folderName = MutableProperty<String>("")
    let subfolders = MutableProperty<[String]>([])
    let documents = MutableProperty<[String]>([])
    let searchText = MutableProperty<String>("")
    let showMenuNavBarButton: Bool
    let showAddButtonBar = MutableProperty<Bool>(true)
    let noContentText = MutableProperty<String>(String.localized("Folder is empty"))

    private let searchTexts = MutableProperty<[String]>([])

    private let folder: CDFolder?
    private var subfolderObjects = [CDFolder]()
    private var subfolderObjectNames = [String]()
    private var documentObjects = [CDDocument]()
    private var documentObjectNames = [String]()

    private var searchDocumentObjects = [CDDocument]()
    private var folderNameCached = ""
    private let coreDataManager = CoreDataManager.shared
    private let navigationRouter = NavigationRouter.shared
    
    @available(*, unavailable)
    override init() {
        fatalError("Not implemented")
    }
    
    init(folder: CDFolder?) {
        self.folder = folder
        self.showMenuNavBarButton = folder == nil
        super.init()
        setup()
    }
    
    private func setup() {
        NotificationCenter
            .default
            .addObserver(self, selector: #selector(reloadFolder(notification:)), name: NSNotification.Name(rawValue: C.reloadFolderNotification), object: nil)
        
        readFolder()
        
        coreDataManager
            .name(of: folder)
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithResult { [unowned self] result in
                switch result {
                case let .success(name):
                    self.folderName.value = name
                    self.folderNameCached = name
                default:
                    self.folderName.value = ""
                    self.folderNameCached = ""
                }
        }
        
        searchText
            .producer
            .take(during: reactive.lifetime)
            .throttle(1.5, on: QueueScheduler.main)
            .skipRepeats()
            .observe(on: UIScheduler())
            .startWithValues { [unowned self] text in
                if text.isEmpty {
                    self.searchTexts.value = []
                }
                else {
                    self.searchTexts.value = text.components(separatedBy: " ")
                }
        }
        
        searchTexts
            .producer
            .take(during: reactive.lifetime)
            .skipRepeats()
            .observe(on: UIScheduler())
            .startWithValues { [unowned self] texts in
                if texts.isEmpty {
                    self.subfolders.value = self.subfolderObjectNames
                    self.documents.value = self.documentObjectNames
                    self.searchDocumentObjects = []
                    self.showAddButtonBar.value = true
                    self.noContentText.value = String.localized("Folder is empty")
                    self.folderName.value = self.folderNameCached
                }
                else {
                    self.searchForDocumentsTagged(with: texts)
                }
        }
    }
    
    private func searchForDocumentsTagged(with texts: [String]) {
        self.showAddButtonBar.value = false
        self.noContentText.value = String.localized("No documents found")
        self.folderName.value = String.localized("Search...")
        
        let loadingGuid = self.navigationRouter.showLoading()
        
        self.coreDataManager
            .findDocuments(tagedWith: texts)
            .take(during: self.reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned self] decryptedDocuments in
                let (documentNames, documentObjects) = self.sortDecryptedDocuments(decryptedDocuments)
                self.subfolders.value = []
                self.documents.value = documentNames
                self.searchDocumentObjects = documentObjects

                self.navigationRouter.hideLoading(loadingGuid)
        }
    }
    
    private func sortDecryptedDocuments(_ decryptedDocuments: [CoreDataManager.DecryptedDocumentName]) -> ([String], [CDDocument]) {
        let sortedDocuments = decryptedDocuments.sorted {  (left, right) -> Bool in
            return left.name.localizedCompare(right.name) == .orderedAscending
        }
        
        var documentNames = [String]()
        var documentObjects = [CDDocument]()
        for document in sortedDocuments {
            documentNames.append(document.name)
            documentObjects.append(document.document)
        }

        return (documentNames, documentObjects)
    }
    
    @objc private func reloadFolder(notification: Notification) {
        if let updatedFolder = notification.object as? CDFolder,
            updatedFolder == folder {
            readFolder()
        }
        else if notification.object == nil && folder == nil {
            readFolder()
        }
    }
    
    private func readFolder() {
        coreDataManager
            .subfolderNamesIn(folder: folder)
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithResult { [unowned self] result in
                switch result {
                case let .success(decryptedFolders):
                    let sortedFolders = decryptedFolders.sorted { (left, right) -> Bool in
                        return left.name.localizedCompare(right.name) == .orderedAscending
                    }
                    
                    var subfolderNames = [String]()
                    var subfolderObjects = [CDFolder]()
                    for subfolder in sortedFolders {
                        subfolderNames.append(subfolder.name)
                        subfolderObjects.append(subfolder.folder)
                    }
                    
                    self.subfolderObjectNames = subfolderNames
                    self.subfolderObjects = subfolderObjects

                default:
                    self.subfolderObjectNames = []
                    self.subfolderObjects = []
                    self.navigationRouter.showAlert(title: "", message: "Read error. Please try again later")
                }
                
                if self.searchText.value.isEmpty {
                    self.subfolders.value = self.subfolderObjectNames
                }
        }
        
        coreDataManager
            .documentNamesIn(folder: folder)
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithResult { [unowned self] result in
                switch result {
                case let .success(decryptedDocuments):
                    let (documentNames, documentObjects) = self.sortDecryptedDocuments(decryptedDocuments)
                    self.documentObjectNames = documentNames
                    self.documentObjects = documentObjects
                    
                default:
                    self.documentObjectNames = []
                    self.documentObjects = []
                    self.navigationRouter.showAlert(title: "", message: "Read error. Please try again later")
                }

                if self.searchText.value.isEmpty {
                    self.documents.value = self.documentObjectNames
                }
        }
    }
    
    func addButtonPressed() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let addFolder = UIAlertAction(title: String.localized("Add folder"), style: .default) { [unowned self] _ in
            self.createSubfolder()
        }
        addFolder.setValue(UIImage(named: "folder_small.png")?.withRenderingMode(.alwaysTemplate), forKey: "image")
        
        let addFile = UIAlertAction(title: String.localized("Add document"), style: .default) { [unowned self] _ in
            self.createDocument()
        }
        addFile.setValue(UIImage(named: "file_small.png")?.withRenderingMode(.alwaysTemplate), forKey: "image")
        
        let cancel = UIAlertAction(title: String.localized("Cancel"), style: .cancel)
        
        alert.addAction(addFolder)
        alert.addAction(addFile)
        alert.addAction(cancel)
        navigationRouter.showAlert(alert)
    }
    
    private func createSubfolder() {
        let alert = UIAlertController(title: String.localized("Add folder"), message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = String.localized("Folder name")
            textField.autocapitalizationType = .sentences
        }
        
        let save = UIAlertAction(title: String.localized("Save"), style: .default) { [unowned self, alert] _ in
            let textField = alert.textFields![0]
            self.createSubfolder(name: textField.text ?? "")
        }
        
        let cancel = UIAlertAction(title: String.localized("Cancel"), style: .cancel)
        
        alert.addAction(save)
        alert.addAction(cancel)
        navigationRouter.showAlert(alert)
    }
    
    private func createSubfolder(name: String) {
        let loadingGuid = navigationRouter.showLoading()
        coreDataManager
            .createSubfolder(name: name, in: folder)
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithResult { [unowned self] result in
                self.navigationRouter.hideLoading(loadingGuid)
                switch result {
                case .success:
                    self.readFolder()
                case .failure:
                    self.navigationRouter.showAlert(title: "", message: String.localized("Can not create folder. Please try again later."))
                }
        }
    }
    
    private func createDocument() {
        let alert = UIAlertController(title: String.localized("Add document"), message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = String.localized("Document name")
            textField.autocapitalizationType = .sentences
        }
        
        let save = UIAlertAction(title: String.localized("Save"), style: .default) { [unowned self, alert] _ in
            let textField = alert.textFields![0]
            self.createDocument(name: textField.text ?? "")
        }
        
        let cancel = UIAlertAction(title: String.localized("Cancel"), style: .cancel)
        
        alert.addAction(save)
        alert.addAction(cancel)
        navigationRouter.showAlert(alert)
    }
    
    private func createDocument(name: String) {
        let loadingGuid = navigationRouter.showLoading()
        coreDataManager
            .createDocument(name: name, in: folder)
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithResult { [unowned self] result in
                self.navigationRouter.hideLoading(loadingGuid)
                switch result {
                case let .success(document):
                    self.navigationRouter.push(document: document)
                case .failure:
                    self.navigationRouter.showAlert(title: "", message: String.localized("Can not create document. Please try again later."))
                }
        }
    }
    
    func longPressedSubfolder(at indexPath: IndexPath) {
        if indexPath.row < subfolderObjects.count {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let rename = UIAlertAction(title: String.localized("Rename"), style: .default) { [unowned self] _ in
                self.renameSubfolder(at: indexPath)
            }
            let delete = UIAlertAction(title: String.localized("Delete"), style: .destructive) { [unowned self] _ in
                self.deleteSubfolder(at: indexPath)
            }
            
            let cancel = UIAlertAction(title: String.localized("Cancel"), style: .cancel)
            
            alert.addAction(rename)
            alert.addAction(delete)
            alert.addAction(cancel)
            navigationRouter.showAlert(alert)
        }
    }
    
    func longPressedDocument(at indexPath: IndexPath) {
        let objects = searchTexts.value.isEmpty ? documentObjects : searchDocumentObjects
        if indexPath.row < objects.count {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let rename = UIAlertAction(title: String.localized("Rename"), style: .default) { [unowned self] _ in
                self.renameDocument(at: indexPath)
            }
            let delete = UIAlertAction(title: String.localized("Delete"), style: .destructive) { [unowned self] _ in
                self.deleteDocument(at: indexPath)
            }
            
            let cancel = UIAlertAction(title: String.localized("Cancel"), style: .cancel)
            
            alert.addAction(rename)
            alert.addAction(delete)
            alert.addAction(cancel)
            navigationRouter.showAlert(alert)
        }
    }
    
    func renameSubfolder(at indexPath: IndexPath) {
        if indexPath.row < subfolderObjects.count {
            let currentName = subfolders.value[indexPath.row]
            let alert = UIAlertController(title: String.localized("Rename folder"), message: nil, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.placeholder = String.localized("Folder name")
                textField.text = currentName
                textField.autocapitalizationType = .sentences
            }
            
            let save = UIAlertAction(title: String.localized("Save"), style: .default) { [unowned self, alert] _ in
                let folder = self.subfolderObjects[indexPath.row]
                let loadingGuid = self.navigationRouter.showLoading()
                let folderName = alert.textFields![0].text
                self.coreDataManager
                    .rename(folder: folder, to: folderName ?? "")
                    .take(during: self.reactive.lifetime)
                    .observe(on: UIScheduler())
                    .startWithResult { [unowned self] result in
                        self.navigationRouter.hideLoading(loadingGuid)
                        switch result {
                        case .success:
                            self.readFolder()
                        case .failure:
                            self.navigationRouter.showAlert(title: "", message: String.localized("Can not rename folder. Please try again later."))
                        }
                }
            }
            
            let cancel = UIAlertAction(title: String.localized("Cancel"), style: .cancel)
            
            alert.addAction(save)
            alert.addAction(cancel)
            navigationRouter.showAlert(alert)
        }
    }
    
    func renameDocument(at indexPath: IndexPath) {
        let objects = searchTexts.value.isEmpty ? documentObjects : searchDocumentObjects
        if indexPath.row < objects.count {
            let currentName = documents.value[indexPath.row]
            let alert = UIAlertController(title: String.localized("Rename document"), message: nil, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.placeholder = String.localized("Document name")
                textField.text = currentName
                textField.autocapitalizationType = .sentences
            }
            
            let save = UIAlertAction(title: String.localized("Save"), style: .default) { [unowned self, alert] _ in
                let document = objects[indexPath.row]
                let loadingGuid = self.navigationRouter.showLoading()
                let documentName = alert.textFields![0].text
                self.coreDataManager
                    .rename(document: document, to: documentName ?? "")
                    .take(during: self.reactive.lifetime)
                    .observe(on: UIScheduler())
                    .startWithResult { [unowned self] result in
                        self.navigationRouter.hideLoading(loadingGuid)
                        switch result {
                        case .success:
                            self.readFolder()
                            if !self.searchTexts.value.isEmpty {
                                self.searchForDocumentsTagged(with: self.searchTexts.value)
                            }
                        case .failure:
                            self.navigationRouter.showAlert(title: "", message: String.localized("Can not rename document. Please try again later."))
                        }
                }
            }
            
            let cancel = UIAlertAction(title: String.localized("Cancel"), style: .cancel)
            
            alert.addAction(save)
            alert.addAction(cancel)
            navigationRouter.showAlert(alert)
        }
    }
    
    func deleteSubfolder(at indexPath: IndexPath) {
        if indexPath.row < subfolderObjects.count {
            let loadingGuid = navigationRouter.showLoading()
            coreDataManager
                .delete(folder: subfolderObjects[indexPath.row])
                .take(during: reactive.lifetime)
                .observe(on: UIScheduler())
                .startWithResult { [unowned self] result in
                    self.navigationRouter.hideLoading(loadingGuid)
                    switch result {
                    case .failure:
                        self.navigationRouter.showAlert(title: "", message: String.localized("Some error occured. Please try again later."))
                    default:
                        break
                    }
            }
        }
    }
    
    func deleteDocument(at indexPath: IndexPath) {
        let objects = searchTexts.value.isEmpty ? documentObjects : searchDocumentObjects
        if indexPath.row < objects.count {
            let loadingGuid = navigationRouter.showLoading()
            coreDataManager
                .delete(document: objects[indexPath.row])
                .take(during: reactive.lifetime)
                .observe(on: UIScheduler())
                .startWithResult { [unowned self] result in
                    self.navigationRouter.hideLoading(loadingGuid)
                    switch result {
                    case .failure:
                        self.navigationRouter.showAlert(title: "", message: String.localized("Some error occured. Please try again later."))
                    default:
                        if !self.searchTexts.value.isEmpty {
                            self.searchForDocumentsTagged(with: self.searchTexts.value)
                        }
                        break
                    }
            }
        }
    }
    
    func didSelectSubfolder(at indexPath: IndexPath) {
        if indexPath.row < subfolderObjects.count {
            let folder = subfolderObjects[indexPath.row]
            navigationRouter.push(folder: folder)
        }
    }
    
    func didSelectDocument(at indexPath: IndexPath) {
        let objects = searchTexts.value.isEmpty ? documentObjects : searchDocumentObjects
        if indexPath.row < objects.count {
            let document = objects[indexPath.row]
            navigationRouter.push(document: document)
        }
    }
    
    func menuPressed() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let changePassword = UIAlertAction(title: String.localized("Change password"), style: .default) { [unowned self] _ in
            self.navigationRouter.showChangePassword()
        }
        let logout = UIAlertAction(title: String.localized("Logout"), style: .destructive) { [unowned self] _ in
            self.navigationRouter.logout()
        }
        
        let cancel = UIAlertAction(title: String.localized("Cancel"), style: .cancel)
        
        alert.addAction(changePassword)
        alert.addAction(logout)
        alert.addAction(cancel)
        navigationRouter.showAlert(alert)
    }
    
}
