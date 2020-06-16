//
//  TagsScrollViewModel.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 02.06.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift

class TagsScrollViewModel: NSObject {

    let document: CDDocument
    private let coreDataManager = CoreDataManager.shared
    private let navigationRouter = NavigationRouter.shared
    
    init(document: CDDocument) {
        self.document = document
    }
    
    func addTag() -> SignalProducer<CDTag, Never> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            UIScheduler().schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                let alert = UIAlertController(title: String.localized("Add tag"), message: nil, preferredStyle: .alert)
                alert.addTextField { textField in
                    textField.placeholder = String.localized("Text")
                    textField.autocapitalizationType = .sentences
                }
                
                let addAction = UIAlertAction(title: String.localized("Add"), style: .default) { [unowned self] _ in
                    guard let textFields = alert.textFields,
                        textFields.count > 0 else { return }
                    
                    let loadingGuid = self.navigationRouter.showLoading()
                    let textField = textFields[0]
                    
                    self.coreDataManager
                        .add(tag: textField.text ?? "", to: self.document)
                        .take(during: self.reactive.lifetime)
                        .observe(on: UIScheduler())
                        .startWithResult({ [unowned self, observer] result in
                            switch result {
                            case let .success(tag):
                                observer.send(value: tag)
                            default:
                                break;
                            }
                            self.navigationRouter.hideLoading(loadingGuid)
                            observer.sendCompleted()
                        })
                }
                let cancelAction = UIAlertAction(title: String.localized("Cancel"), style: .cancel) { [unowned observer] _ in
                    observer.sendCompleted()
                }
                
                alert.addAction(addAction)
                alert.addAction(cancelAction)
                self.navigationRouter.showAlert(alert)
            }
        }
    }
    
}
