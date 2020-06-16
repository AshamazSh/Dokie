//
//  CDContent.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 16.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import CoreData

class CDContent : NSManagedObject {
    
    @NSManaged var data: Data
    @NSManaged var document: CDDocument?

    static let kData = "data"
    static let kDocument = "document"

}
