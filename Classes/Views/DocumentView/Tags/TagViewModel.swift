//
//  TagViewModel.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 02.06.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift

class TagViewModel: NSObject {

    private let tag: CDTag
    private let navigationRouter = NavigationRouter.shared
    private let coreDataManager = CoreDataManager.shared
    let text: MutableProperty<String>
    
    init(tag: CDTag) {
        self.tag = tag
        self.text = MutableProperty<String>(tag.text)
    }
    
    func editPressed() {
        let currentText = text.value
        
        let alert = UIAlertController(title: String.localized("Edit tag"), message: nil, preferredStyle: .alert)
        alert.addTextField {  textField in
            textField.placeholder = String.localized("Text")
            textField.autocapitalizationType = .sentences
            textField.text = currentText
        }
        
        let saveAction = UIAlertAction(title: String.localized("Save"), style: .default) { [unowned self] _ in
            guard let textFields = alert.textFields,
                textFields.count > 0 else { return }
            
            let loadingGuid = self.navigationRouter.showLoading()
            let textField = textFields[0]
            
            self.coreDataManager
                .rename(tag: self.tag, to: textField.text ?? "")
                .take(during: self.reactive.lifetime)
                .observe(on: UIScheduler())
                .startWithResult({ [unowned self] result in
                    switch result {
                    case let .success(tag):
                        self.text.value = tag.text
                    default:
                        break;
                    }
                    self.navigationRouter.hideLoading(loadingGuid)
                })
        }
        let cancelAction = UIAlertAction(title: String.localized("Cancel"), style: .cancel)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        self.navigationRouter.showAlert(alert)
    }
    
    func deletePressed() -> SignalProducer<Bool, Error> {
        return coreDataManager.delete(tag: tag)
    }
}
