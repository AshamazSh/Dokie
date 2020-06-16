//
//  DocumentFilesViewModel.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 25.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa
import ImagePicker

class DocumentFilesViewModel: NSObject {
    
    let document: CDDocument
    let contentFiles = MutableProperty<[CDContent]>([CDContent]())
    private let coreDataManager = CoreDataManager.shared
    private let navigationRouter = NavigationRouter.shared
    
    
    @available(*, unavailable)
    override init() {
        fatalError("Not implemented")
    }
    
    init(document: CDDocument) {
        self.document = document
        super.init()
        setup()
    }
    
    private func setup() {}
    
    func read() -> SignalProducer<Bool, Never> {
        coreDataManager
            .decrypted(document: document)
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .map { [unowned self] (decryptedDocument) -> Bool in
                var objects = [CDContent]()
                for decrypredContent in decryptedDocument {
                    if decrypredContent.decryptionError == nil,
                        let type = decrypredContent.decrypted[C.contentTypeKey] as? String,
                        type == C.contentTypeFile {
                        objects.append(decrypredContent.content)
                    }
                }
                self.contentFiles.value = objects
                return true
        }
    }
    
    func addFile() {
        let imagePicker = ImagePickerController()
        imagePicker.delegate = self
        imagePicker.view.backgroundColor = Appearance.backgroundColor
        navigationRouter.showImagePicker(imagePicker)
    }
    
    func edit(indexPath: IndexPath) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let delete = UIAlertAction(title: String.localized("Delete"), style: .default) { [unowned self] _ in
            self.delete(indexPaths: [indexPath])
        }
        let cancel = UIAlertAction(title: String.localized("Cancel"), style: .cancel)
        
        alert.addAction(delete)
        alert.addAction(cancel)
        navigationRouter.showAlert(alert)
    }
    
    func delete(indexPaths: [IndexPath]) {
        var signals = [SignalProducer<Bool, Error>]()
        for indexPath in indexPaths {
            if indexPath.row < contentFiles.value.count {
                signals.append(coreDataManager.delete(content: contentFiles.value[indexPath.row]))
            }
        }
        
        if signals.count > 0 {
            let loadingGuid = navigationRouter.showLoading()
            SignalProducer<Bool, Error>
                .combineLatest(signals)
                .flatMap(.concat) { [unowned self] _ -> SignalProducer<Bool, Never> in
                    self.read()
            }
            .observe(on: UIScheduler())
            .take(during: reactive.lifetime)
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
    
}

extension DocumentFilesViewModel : ImagePickerDelegate {
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {}
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        imagePicker.view.isUserInteractionEnabled = false
        imagePicker.dismiss(animated: true) { [unowned self] in
            guard images.count > 0 else {
                return
            }
            var pngs = [Data]()
            for image in images {
                guard let png = image.pngData() else { return }
                
                pngs.append(png)
            }
            
            let loadingGuid = self.navigationRouter.showLoading()
            self.coreDataManager
                .createMultipleFiles(with: pngs)
                .flatMap(.concat, { [unowned self] files -> SignalProducer<[CDContent], Error> in
                    var contents = [[String : Any]]()
                    for file in files {
                        contents.append([C.contentTypeKey : C.contentTypeFile,
                                         C.contentFileIdKey : file.identifier])
                    }
                    return self.coreDataManager.addMultiple(contents: contents, to: self.document)
                })
                .flatMap(.concat, { [unowned self] _ -> SignalProducer<Bool, Never> in
                    self.read()
                })
                .take(during: self.reactive.lifetime)
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
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        imagePicker.view.isUserInteractionEnabled = false
        imagePicker.dismiss(animated: true, completion: nil)
    }

}
