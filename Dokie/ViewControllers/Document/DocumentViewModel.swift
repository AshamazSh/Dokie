//
//  DocumentViewModel.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 25.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift

class DocumentViewModel: NSObject {
    
    let filesViewModel: DocumentFilesViewModel
    let textViewModel: DocumentTextViewModel
    let tagsViewModel: TagsScrollViewModel
    let documentName = MutableProperty<String>("")
    let forceSegmentedSectionSelect = MutableProperty<Int>(0)

    private let document: CDDocument
    private let navigationRouter = NavigationRouter.shared
    private let coreDataManager = CoreDataManager.shared
    
    @available(*, unavailable)
    override init() {
        fatalError("Not implemented")
    }
    
    init(document: CDDocument) {
        self.document = document
        self.filesViewModel = DocumentFilesViewModel(document: document)
        self.textViewModel = DocumentTextViewModel(document: document)
        self.tagsViewModel = TagsScrollViewModel(document: document)
        super.init()
        setup()
    }
    
    private func setup() {
        coreDataManager
            .name(of: document)
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithResult { [unowned self] result in
                switch result {
                case let .success(name):
                    self.documentName.value = name
                default:
                    self.documentName.value = ""
                }
        }
    }
    
    func addButtonPressed() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let addText = UIAlertAction(title: String.localized("Add text"), style: .default) { [unowned self] _ in
            self.forceSegmentedSectionSelect.value = 0
            self.textViewModel.addContent()
        }
        let addFile = UIAlertAction(title: String.localized("Add file"), style: .default) { [unowned self] _ in
            self.forceSegmentedSectionSelect.value = 1
            self.filesViewModel.addFile()
        }
        let cancel = UIAlertAction(title: String.localized("Cancel"), style: .cancel)
        
        alert.addAction(addText)
        alert.addAction(addFile)
        alert.addAction(cancel)
        navigationRouter.showAlert(alert)
    }
    
    func share(texts: [String], images: [CDContent]) {
        guard texts.count > 0 || images.count > 0 else { return }
        
        var string = ""
        for text in texts {
            string = string + "\(text)\n"
        }
        
        if images.count > 0 {
            let loadingGiud = navigationRouter.showLoading()
            var signals = [SignalProducer<UIImage?, Never>]()
            for content in images {
                signals.append(coreDataManager.imageFrom(content: content).flatMapError({ _ -> SignalProducer<UIImage?, Never> in
                    SignalProducer<UIImage?, Never>.empty
                }))
            }
            
            SignalProducer
                .combineLatest(signals)
                .take(during: reactive.lifetime)
                .observe(on: UIScheduler())
                .startWithValues { [unowned self] images in
                    var imagesArray = [Any]()
                    for image in images {
                        if let image = image {
                            imagesArray.append(image)
                        }
                    }
                    if !string.isEmpty {
                        imagesArray.append(string)
                    }
                    
                    self.navigationRouter.share(items: imagesArray)
                    self.navigationRouter.hideLoading(loadingGiud)
            }
        }
        else if !string.isEmpty {
            navigationRouter.share(items: [string])
        }
    }
    
}
