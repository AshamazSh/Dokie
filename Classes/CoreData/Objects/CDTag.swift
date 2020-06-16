//
//  CDTag.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 16.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import CoreData

class CDTag : NSManagedObject {
    
    @NSManaged var text: String
    @NSManaged var document: CDDocument?

    static let kText = "text"
    static let kDocument = "document"

}
