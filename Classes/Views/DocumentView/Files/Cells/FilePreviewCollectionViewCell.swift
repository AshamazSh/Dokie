//
//  FilePreviewCollectionViewCell.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 24.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa

class FilePreviewCollectionViewCell: UICollectionViewCell {
    
    let showCheckmark = MutableProperty<Bool>(false)
    
    private let fileImage = UI.fileImageView()
    private let coreDataManager = CoreDataManager.shared

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        fileImage.contentMode = .scaleAspectFill
        contentView.addSubview(fileImage)
        
        let shadowView = UI.shadowView()
        shadowView.alpha = 0
        contentView.addSubview(shadowView)
        
        let checkImage = UI.imageView()
        checkImage.image = UIImage(named: "checkmark.png")?.withRenderingMode(.alwaysTemplate)
        shadowView.addSubview(checkImage)
        
        let metrics = ["imageSize" : 44]
        let views = ["fileImage" : fileImage, "shadowView" : shadowView, "checkImage" : checkImage]
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[fileImage]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[fileImage]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[shadowView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[shadowView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        shadowView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[checkImage(imageSize)]-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        shadowView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[checkImage(imageSize)]-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        
        showCheckmark
            .producer
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned shadowView] show in
                shadowView.alpha = show ? 1 : 0
        }
    }
    
    func update(content: CDContent) {
        fileImage.update(content: content)
    }
    
}
