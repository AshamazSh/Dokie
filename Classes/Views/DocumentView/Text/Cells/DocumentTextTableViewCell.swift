//
//  DocumentTextTableViewCell.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 17.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift

class DocumentTextTableViewCell : UITableViewCell {
    
    let textProperty = MutableProperty<String?>(nil)
    let descriptionProperty = MutableProperty<String?>(nil)
    let viewMode = MutableProperty<ViewMode>(.display)
    let showCheckmark = MutableProperty<Bool>(false)
    var editCommand: CocoaAction<UIButton>? = nil {
        didSet {
            editButton.reactive.pressed = editCommand
        }
    }
    
    private let titleLabel = UI.label()
    private let detailLabel = UI.detailLabel()
    private let checkmarkImageView = UI.imageView()
    private var imageRightMargin: NSLayoutConstraint!
    private var labelLeftMargin: NSLayoutConstraint!
    private let editButton = UI.button()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.labelLeftMargin = NSLayoutConstraint(item: titleLabel, attribute: .left, relatedBy: .equal, toItem: contentView, attribute: .left, multiplier: 1, constant: 16)
        self.imageRightMargin = NSLayoutConstraint(item: checkmarkImageView, attribute: .right, relatedBy: .equal, toItem: contentView, attribute: .left, multiplier: 1, constant: 0)
        setup()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("Not implemented")
        return nil
    }
    
    private func setup() {
        backgroundColor = Appearance.backgroundColor
        contentView.backgroundColor = Appearance.backgroundColor
        
        checkmarkImageView.image = UIImage(named: "checkmark.png")?.withRenderingMode(.alwaysTemplate)
        contentView.addSubview(checkmarkImageView)
        
        contentView.addSubview(titleLabel)
        
        contentView.addSubview(detailLabel)
        
        editButton.setImage(UIImage(named: "pensil.png"), for: .normal)
        editButton.imageView?.contentMode = .scaleAspectFit
        contentView.addSubview(editButton)
        
        let metrics = ["vMargin"        : 8,
                       "hMargin"        : 16,
                       "betweenMargin"  : 4]
        let views = ["checkmarkImageView" : checkmarkImageView,
                     "titleLabel" : titleLabel,
                     "detailLabel" : detailLabel,
                     "editButton" : editButton]
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-vMargin-[titleLabel]-betweenMargin-[detailLabel]-vMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[titleLabel]-[editButton]-hMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[detailLabel]-[editButton]-hMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        
        contentView.addConstraints([NSLayoutConstraint(item: detailLabel, attribute: .left, relatedBy: .equal, toItem: titleLabel, attribute: .left, multiplier: 1, constant: 0),
                                    NSLayoutConstraint(item: checkmarkImageView, attribute: .width, relatedBy: .equal, toItem: checkmarkImageView, attribute: .height, multiplier: 1, constant: 0),
                                    NSLayoutConstraint(item: checkmarkImageView, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0),
                                    NSLayoutConstraint(item: checkmarkImageView, attribute: .height, relatedBy: .equal, toItem: contentView, attribute: .height, multiplier: 0.4, constant: 0),
                                    NSLayoutConstraint(item: editButton, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0),
                                    NSLayoutConstraint(item: editButton, attribute: .height, relatedBy: .equal, toItem: contentView, attribute: .height, multiplier: 0.4, constant: 0),
                                    NSLayoutConstraint(item: editButton, attribute: .width, relatedBy: .equal, toItem: editButton, attribute: .height, multiplier: 1, constant: 0),
                                    imageRightMargin,
                                    labelLeftMargin])
        
        titleLabel.reactive.text <~ textProperty
        detailLabel.reactive.text <~ descriptionProperty
        
        viewMode
            .producer
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .skipRepeats()
            .skip(first: 1)
            .startWithValues { [unowned self] viewMode in
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveLinear, animations: {
                    if viewMode == .display {
                        self.imageRightMargin.constant = 0
                        self.labelLeftMargin.constant = 16
                    }
                    else {
                        self.imageRightMargin.constant = 16 + self.checkmarkImageView.frame.size.width
                        self.labelLeftMargin.constant = 16 + 8 + self.checkmarkImageView.frame.size.width
                    }
                    self.contentView.layoutIfNeeded()
                }, completion: nil)
        }
        
        checkmarkImageView.reactive.alpha <~ showCheckmark.map({ showCheckmark -> CGFloat in
            showCheckmark ? 1 : 0
        })
    }
    
}
