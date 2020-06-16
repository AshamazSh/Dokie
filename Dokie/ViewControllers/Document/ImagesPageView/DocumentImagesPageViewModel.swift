//
//  DocumentImagesPageViewModel.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 25.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift

class DocumentImagesPageViewModel: NSObject {

    let contentImages: MutableProperty<[CDContent]>
    let firstIndex: Int
    
    init(images: [CDContent], firstIndex: Int) {
        self.contentImages = MutableProperty<[CDContent]>(images)
        self.firstIndex = firstIndex
        super.init()
    }
    
}
