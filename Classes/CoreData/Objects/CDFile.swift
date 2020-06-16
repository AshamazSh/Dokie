//
//  CDFile.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 16.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import CoreData

class CDFile : NSManagedObject {
    
    @NSManaged var data: Data
    @NSManaged var identifier: String

    static let kData = "data"
    static let kIdentifier = "identifier"

}
