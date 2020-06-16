//
//  Error.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 16.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import Foundation

protocol DokieError : Error {
    var localizedDescription: String { get }
}
