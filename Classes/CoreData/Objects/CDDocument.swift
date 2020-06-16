//
//  CDDocument.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 16.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import CoreData

class CDDocument : NSManagedObject {
    
    @NSManaged var data: Data
    @NSManaged var date: Date
    @NSManaged var folder: CDFolder?
    @NSManaged var content: NSOrderedSet?
    @NSManaged var tags: NSOrderedSet?

    static let kData = "data"
    static let kDate = "date"
    static let kFolder = "folder"
    static let kContent = "content"
    static let kTags = "tags"

}
