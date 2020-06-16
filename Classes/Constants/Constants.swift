//
//  Constants.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 15.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import Foundation

class C {
    static let keychainServiceName              =   "com.ashamazsh.Dokie.keychain"
    static let keychainLocalDBPasswordKey       =   "com.ashamazsh.Dokie.localDBPassword"
    static let folderNameKey                    =   "folderName"
    static let documentNameKey                  =   "documentName"
    static let dbPasswordKey                    =   "dbPassword"

    static let contentTypeKey                   =   "contentType"
    static let contentTypeText                  =   "text"
    static let contentTypeFile                  =   "file"
    static let contentTextKey                   =   "text"
    static let contentDescriptionKey            =   "description"
    static let contentFileIdKey                 =   "fileId"

    static let doNotSuggestPasswordSaveKey      =   "com:Dokie:kDoNotSuggestPasswordSaveKey"

    static let deleteFileNotification           =   "com:Dokie:kDeleteFileNotification"
    static let reloadFolderNotification         =   "com:Dokie:kReloadFolderNotification"

    static let DokieErrorDomain                 =   "com:Dokie:DokieErrorDomain"
}
