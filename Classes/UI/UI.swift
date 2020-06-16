//
//  UI.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 17.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit

class UI {
    
    static func label() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Appearance.tintColor
        label.font = Appearance.normalFont
        return label
    }
    
    static func detailLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Appearance.detailColor
        label.font = Appearance.smallFont
        return label
    }
    
    static func tableView() -> UITableView {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 0, height: 0), style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = UIView()
        tableView.insetsContentViewsToSafeArea = true
        tableView.separatorColor = Appearance.separatorColor
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        return tableView
        
    }
    
    static func actionButton() -> UIButton {
        let actionButton = UIButton(type: .system)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.titleLabel?.font = Appearance.actionButtonFont
        return actionButton
    }
    
    static func touchIdButton() -> UIButton {
        let touchIdButton = UI.actionButton()
        touchIdButton.setImage(UIImage(named: "touch_id.png"), for: .normal)
        touchIdButton.imageView?.contentMode = .scaleAspectFit
        return touchIdButton
        
    }
    
    static func faceIdButton() -> UIButton {
        let faceIdButton = UI.actionButton()
        faceIdButton.setImage(UIImage(named: "face_id.png"), for: .normal)
        return faceIdButton
        
    }
    
    static func button() -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = Appearance.normalFont
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }
    
    static func collectionView(lineSpacing: CGFloat, itemSpacing: CGFloat) -> UICollectionView {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = lineSpacing
        flowLayout.minimumInteritemSpacing = itemSpacing
        
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 0, height: 0), collectionViewLayout:flowLayout)
        collectionView.backgroundColor = Appearance.backgroundColor
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.alwaysBounceVertical = true
        return collectionView
        
    }
    
    static func separator() -> UIView {
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = Appearance.separatorColor
        return separator
        
    }
    
    static func view() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Appearance.backgroundColor
        return view
        
    }
    
    static func shadowView() -> UIView {
        let shadowView = UIView()
        shadowView.backgroundColor = Appearance.shadowColor
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        return shadowView
        
    }
    
    static func textField() -> UITextField {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = Appearance.loginTextFieldFont
        textField.backgroundColor = UIColor.rgb(red: 230, green: 230, blue: 230)
        textField.layer.cornerRadius = 5
        let spacingView = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: 44))
        textField.leftView = spacingView
        textField.leftViewMode = .always
        textField.textColor = UIColor.black
        return textField
    }
    
    static func imageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.tintColor = Appearance.tintColor
        return imageView
    }
    
    static func segmentedControl(items: [String]) -> UISegmentedControl {
        let segmented = UISegmentedControl(items: items)
        segmented.translatesAutoresizingMaskIntoConstraints = false
        segmented.selectedSegmentIndex = 0
        return segmented
    }
    
    static func scrollView() -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.decelerationRate = .fast
        scrollView.maximumZoomScale = 2
        scrollView.minimumZoomScale = 1
        return scrollView
    }
    
    static func fileImageView() -> FileImageView {
        let toReturn = FileImageView()
        toReturn.translatesAutoresizingMaskIntoConstraints = false
        toReturn.contentMode = .scaleAspectFit
        toReturn.clipsToBounds = true
        return toReturn
    }
    
    static func horizontalStackView(spacing: CGFloat) -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.spacing = spacing
        stackView.axis = .horizontal
        return stackView
    }

    static func verticalStackView(spacing: CGFloat) -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.spacing = spacing
        stackView.axis = .vertical
        return stackView
    }

}
