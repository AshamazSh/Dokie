//
//  FileImageView.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 24.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift

class FileImageView: UIImageView {
    
    private let coreDataManager = CoreDataManager.shared
    private var disposable: Disposable?
    
    func update(content: CDContent) {
        image = nil
        disposable?.dispose()
        disposable = coreDataManager
            .imageFrom(content: content)
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithResult { [unowned self] result in
                switch result {
                case .success(let image): self.image = image
                case .failure: self.image = nil
                }
        }
    }
    
}
