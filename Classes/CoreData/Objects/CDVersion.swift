//
//  CDVersion.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 16.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import CoreData

class CDVersion : NSManagedObject {
    
    @NSManaged var info: String

    static let kInfo = "info"

}
