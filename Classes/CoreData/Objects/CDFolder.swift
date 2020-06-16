//
//  CDFolder.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 16.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import CoreData

class CDFolder : NSManagedObject {
    
    @NSManaged var data: Data
    @NSManaged var date: Date
    @NSManaged var documents: Set<CDDocument>?
    @NSManaged var parentFolder: CDFolder?
    @NSManaged var subfolders: Set<CDFolder>?

    static let kData = "data"
    static let kDate = "date"
    static let kDocuments = "documents"
    static let kParentFolder = "parentFolder"
    static let kSubfolders = "subfolders"

}
