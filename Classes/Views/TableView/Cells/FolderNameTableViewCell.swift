//
//  FolderNameTableViewCell.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 17.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift

class FolderNameTableViewCell : UITableViewCell {
    
    var name = MutableProperty<String?>(nil)
    var editComand: CocoaAction<UIButton>? {
        didSet {
            editButton.reactive.pressed = editComand
        }
    }
    
    private let nameLabel = UI.label()
    private let iconImageView = UI.imageView()
    private let editButton = UI.button()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("Not implemented")
        return nil
    }
    
    private func setup() {
        backgroundColor = Appearance.backgroundColor
        contentView.backgroundColor = Appearance.backgroundColor
        
        iconImageView.image = UIImage(named: "folder.png")?.withRenderingMode(.alwaysTemplate)
        contentView.addSubview(iconImageView)
        
        contentView.addSubview(nameLabel)
        
        editButton.setImage(UIImage(named: "pensil.png"), for: .normal)
        editButton.imageView?.contentMode = .scaleAspectFit
        contentView.addSubview(editButton)
        
        nameLabel.reactive.text <~ name
        
        let metrics = ["vMargin" : 8, "smallVMargin" : 4, "hMargin" : 16, "betweenMargin" : 10]
        let views = ["iconImageView" : iconImageView, "nameLabel" : nameLabel, "editButton" : editButton]
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-hMargin-[iconImageView]-betweenMargin-[nameLabel]-[editButton]-hMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-smallVMargin-[iconImageView]-smallVMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-vMargin-[nameLabel]-vMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        contentView.addConstraints([NSLayoutConstraint(item: iconImageView, attribute: .width, relatedBy: .equal, toItem: iconImageView, attribute: .height, multiplier: 1, constant: 0),
                                    NSLayoutConstraint(item: editButton, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0),
                                    NSLayoutConstraint(item: editButton, attribute: .height, relatedBy: .equal, toItem: contentView, attribute: .height, multiplier: 0.4, constant: 0),
                                    NSLayoutConstraint(item: editButton, attribute: .width, relatedBy: .equal, toItem: editButton, attribute: .height, multiplier: 1, constant: 0)])
    }
    
}
