//
//  CDChecksum.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 16.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import CoreData

class CDChecksum : NSManagedObject {
    
    @NSManaged var encryptedKey: Data
    @NSManaged var checksum: String
    @NSManaged var salt: String
    
    static let kEncryptedKey = "encryptedKey"
    static let kChecksum = "checksum"
    static let kSalt = "salt"
    
}
