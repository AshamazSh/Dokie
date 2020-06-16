//
//  String+Dokie.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 15.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import Foundation

extension String {
    
    static func localized(_ string: String) -> String {
        return NSLocalizedString(string, comment: "")
    }
    
}
