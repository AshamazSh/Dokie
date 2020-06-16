//
//  DocumentTextViewModel.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 17.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import Foundation
import ReactiveCocoa
import ReactiveSwift

class DocumentTextViewModel : NSObject {
    
    struct DocumentContent : Equatable {
        
        let text: String
        let description: String
        
        func string() -> String {
            if !text.isEmpty && !description.isEmpty {
                return "\(text): \(description)"
            }
            else if !text.isEmpty {
                return text
            }
            return description
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.text == rhs.text && lhs.description == rhs.description
        }
        
    }
    
    let content = MutableProperty<[DocumentContent]>([])
    let copiedToClipboardText = MutableProperty<String?>(nil)
    var displayedObjects = [CDContent]()
    private let document: CDDocument
    private let coreDataManager = CoreDataManager.shared
    private let navigationRouter = NavigationRouter.shared
    
    @available(*, unavailable)
    override init() {
        fatalError("Not implemented")
    }
    
    init(document: CDDocument) {
        self.document = document
    }
    
    func addContent() {
        let alert = UIAlertController(title: String.localized("Add content"), message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = String.localized("Text")
            textField.autocapitalizationType = .sentences
        }
        alert.addTextField { textField in
            textField.placeholder = String.localized("Description")
            textField.autocapitalizationType = .sentences
        }
        
        let saveAction = UIAlertAction(title: String.localized("Save"), style: .default) { [unowned self] _ in
            let loadingGuid = self.navigationRouter.showLoading()
            guard let textFields = alert.textFields,
                textFields.count > 1 else { return }
            
            let textField = textFields[0]
            let detailField = textFields[1]
            self.coreDataManager
                .add(content: [C.contentTypeKey : C.contentTypeText,
                               C.contentTextKey : textField.text ?? "",
                               C.contentDescriptionKey : detailField.text ?? ""],
                     to: self.document)
                .take(during: self.reactive.lifetime)
                .observe(on: UIScheduler())
                .flatMap(.concat) { [unowned self] _ -> SignalProducer<Bool, Never> in
                    self.navigationRouter.hideLoading(loadingGuid)
                    return self.read()
            }
            .start { [unowned self] event in
                self.navigationRouter.hideLoading(loadingGuid)
                switch event {
                case .failed:
                    self.navigationRouter.showAlert(title: "", message: String.localized("Some error occured. Please try again later."))
                default:
                    break
                }
            }
        }
        let cancelAction = UIAlertAction(title: String.localized("Cancel"), style: .cancel)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        navigationRouter.showAlert(alert)
    }
    
    func didSelect(indexPath: IndexPath) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let edit = UIAlertAction(title: String.localized("Edit"), style: .default) { [unowned self] _ in
            self.edit(indexPath: indexPath)
        }
        let copy = UIAlertAction(title: String.localized("Copy"), style: .default) { [unowned self] _ in
            self.copyToClipboard(indexPath: indexPath)
        }
        let delete = UIAlertAction(title: String.localized("Delete"), style: .destructive) { [unowned self] _ in
            self.delete(indexPaths: [indexPath])
        }
        let cancel = UIAlertAction(title: String.localized("Cancel"), style: .cancel)
        
        alert.addAction(edit)
        alert.addAction(copy)
        alert.addAction(delete)
        alert.addAction(cancel)
        
        navigationRouter.showAlert(alert)
    }
    
    func delete(indexPaths: [IndexPath]) {
        let deleteSignals = indexPaths.filter { indexPath -> Bool in
            return indexPath.row < displayedObjects.count
        }
        .map { indexPath -> SignalProducer<Bool, Error> in
            coreDataManager.delete(content: displayedObjects[indexPath.row])
        }
        
        if deleteSignals.count > 0 {
            let loadingGuid = navigationRouter.showLoading()
            SignalProducer.combineLatest(deleteSignals).take(during: reactive.lifetime)
                .observe(on: UIScheduler())
                .flatMap(.concat) { [unowned self] _ -> SignalProducer<Bool, Never> in
                    self.navigationRouter.hideLoading(loadingGuid)
                    return self.read()
            }
            .start { [unowned self] event in
                self.navigationRouter.hideLoading(loadingGuid)
                switch event {
                case .failed:
                    self.navigationRouter.showAlert(title: "", message: String.localized("Some error occured. Please try again later."))
                default:
                    break
                }
            }
        }
    }
    
    func edit(indexPath: IndexPath) {
        guard indexPath.row < content.value.count,
            indexPath.row < displayedObjects.count else { return }
        
        let value = content.value[indexPath.row]
        let alert = UIAlertController(title: String.localized("Edit content"), message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = value.text
            textField.placeholder = String.localized("Text")
            textField.autocapitalizationType = .sentences
        }
        alert.addTextField { textField in
            textField.text = value.description
            textField.placeholder = String.localized("Description")
            textField.autocapitalizationType = .sentences
        }

        let save = UIAlertAction(title: String.localized("Save"), style: .default) { [unowned self] _ in
            guard let textFields = alert.textFields,
                textFields.count > 1 else { return }
            let loadingGuid = self.navigationRouter.showLoading()
            let textField = textFields[0]
            let detailField = textFields[1]

            self.coreDataManager.update(content: self.displayedObjects[indexPath.row], with: [C.contentTypeKey : C.contentTypeText,
                                                                                              C.contentTextKey : textField.text ?? "",
                                                                                              C.contentDescriptionKey : detailField.text ?? ""])
                .take(during: self.reactive.lifetime)
                .observe(on: UIScheduler())
                .flatMap(.concat) { [unowned self] _ -> SignalProducer<Bool, Never> in
                    self.navigationRouter.hideLoading(loadingGuid)
                    return self.read()
            }
            .start { [unowned self] event in
                self.navigationRouter.hideLoading(loadingGuid)
                switch event {
                case .failed:
                    self.navigationRouter.showAlert(title: "", message: String.localized("Some error occured. Please try again later."))
                default:
                    break
                }
            }
        }
        let cancel = UIAlertAction(title: String.localized("Cancel"), style: .cancel)
        
        alert.addAction(save)
        alert.addAction(cancel)
        navigationRouter.showAlert(alert)
    }
    
    func read() -> SignalProducer<Bool, Never> {
        coreDataManager
            .decrypted(document: document)
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .map { [unowned self] (decryptedDocument) -> Bool in
                var content = [DocumentContent]()
                var objects = [CDContent]()
                for decrypredContent in decryptedDocument {
                    if decrypredContent.decryptionError == nil,
                        let type = decrypredContent.decrypted[C.contentTypeKey] as? String,
                        type == C.contentTypeText {
                        content.append(DocumentContent(text: decrypredContent.decrypted[C.contentTextKey] as? String ?? "",
                                                       description: decrypredContent.decrypted[C.contentDescriptionKey] as? String ?? ""))
                        objects.append(decrypredContent.content)
                    }
                }
                self.content.value = content
                self.displayedObjects = objects
                return true
        }
    }
    
    private func copyToClipboard(indexPath: IndexPath) {
        guard indexPath.row < content.value.count else { return }
        
        let value = content.value[indexPath.row]
        copiedToClipboardText.value = value.string()
        UIPasteboard.general.string = value.string()
    }
    
}
