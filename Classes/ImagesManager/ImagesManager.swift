//
//  ImagesManager.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 14.06.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import Photos
import ReactiveCocoa
import ReactiveSwift

class ImagesManager: NSObject {
    
    static let shared = ImagesManager()
    
    private let imageManager = PHImageManager.default()
    
    private override init() {
        super.init()
    }
    
    func thubnailSignal(for asset: PHAsset) -> SignalProducer<UIImage, Never> {
        var requestId: PHImageRequestID?
        let producer = SignalProducer<UIImage, Never> { [unowned self] (observer, lifetime) in
            QueueScheduler.main.schedule { [unowned self] in
                guard lifetime.hasEnded == false else {
                    return
                }
                
                let option = PHImageRequestOptions()
                option.isSynchronous = false
                requestId = self.imageManager.requestImage(for: asset,
                                                           targetSize: CGSize(width: 100, height: 100),
                                                           contentMode: .aspectFit,
                                                           options: option,
                                                           resultHandler: { (image, info) in
                                                            if let image = image {
                                                                observer.send(value: image)
                                                            }
                                                            
                                                            observer.sendCompleted()
                })
            }
        }
        
        return producer.on(starting: nil,
                           started: nil,
                           event: nil,
                           failed: nil,
                           completed: nil,
                           interrupted: { [unowned self] in
                            guard let requestId = requestId else { return }
                            self.imageManager.cancelImageRequest(requestId)
            },
                           terminated: { [unowned self] in
                            guard let requestId = requestId else { return }
                            self.imageManager.cancelImageRequest(requestId)
            },
                           disposed: { [unowned self] in
                            guard let requestId = requestId else { return }
                            self.imageManager.cancelImageRequest(requestId)
            },
                           value: nil)
    }
    
}
