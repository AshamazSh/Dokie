//
//  Appearance.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 14.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit

class Appearance {
    
    static func setDefaultColors() {
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().barStyle = .black
        UINavigationBar.appearance().barTintColor = Appearance.backgroundColor
        
        UILabel.appearance().font = Appearance.normalFont
        UILabel.appearance().textColor = Appearance.tintColor
        UITextField.appearance().font = Appearance.normalFont
        UIButton.appearance().titleLabel?.font = Appearance.normalFont
        UIButton.appearance().tintColor = Appearance.tintColor
        UITableView.appearance().backgroundColor = Appearance.backgroundColor
        UISegmentedControl.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.white] , for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.black] , for: .selected)
        UISegmentedControl.appearance().tintColor = Appearance.tintColor
        if #available(iOS 13, *) {
            UISegmentedControl.appearance().selectedSegmentTintColor = Appearance.tintColor
        }
        UITableViewCell.appearance().contentView.backgroundColor = Appearance.backgroundColor
    }
    
    static var loginTextFieldFont: UIFont {
        UIFont.systemFont(ofSize: 20)
    }
    
    static var actionButtonFont: UIFont {
        UIFont.systemFont(ofSize: 20)
    }
    
    static var smallFont: UIFont {
        UIFont.systemFont(ofSize: 12)
    }
    
    static var normalFont: UIFont {
        UIFont.systemFont(ofSize: 14)
    }
    
    
    static var tintColor: UIColor {
        .white
    }
    
    static var detailColor: UIColor {
        .lightGray
    }
    
    static var backgroundColor: UIColor {
        UIColor.rgb(red: 50, green: 72, blue: 78)
    }
    
    static var separatorColor: UIColor {
        UIColor.rgb(red: 220, green: 220, blue: 220)
    }
    
    static var shadowColor: UIColor {
        UIColor.black.withAlphaComponent(0.7)
    }
    
    static var tagBackgroundColor: UIColor {
        UIColor.lightGray.withAlphaComponent(0.5)
    }
    
}

extension UIColor {
    
    static func rgba(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> UIColor {
        UIColor(red: red/255, green: green/255, blue: blue/255, alpha: alpha/255)
    }
    
    static func rgb(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        rgba(red: red, green: green, blue: blue, alpha: 255)
    }
    
}
