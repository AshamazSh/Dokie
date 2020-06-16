//
//  EncryptionManager.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 16.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import Foundation
import CoreData
import ReactiveCocoa
import ReactiveSwift
import CommonCrypto


class EncryptionManager : NSObject {
    
    enum EncryptionManagerError : Error, LocalizedError {
        case encryptionError
        case decryptionError
        
        var errorDescription: String? {
            switch self {
            case .encryptionError:
                return String.localized("Encryption failed")
            case .decryptionError:
                return String.localized("Decryption failed")
            }
        }
    }
    
    static func keyExists(in context: NSManagedObjectContext) -> Bool {
        let request = CDChecksum.fetchRequest()
        request.returnsObjectsAsFaults = true
        
        if let sums = try? context.fetch(request) {
            return sums.count > 0
        }
        return false
    }
    
    private(set) var isValid: Bool = false
    private(set) var aes: Crypto!
    private(set) var password: String
    private(set) var context: NSManagedObjectContext
    
    init(password: String, context: NSManagedObjectContext) {
        self.context = context
        self.password = password
        super.init()
        setup()
    }
    
    private func contextChecksum() -> CDChecksum? {
        let request = CDChecksum.fetchRequest()
        request.returnsObjectsAsFaults = false
        
        do {
            if let sums = try context.fetch(request) as? [CDChecksum] {
                return sums.first
            }
        }
        catch {
            return nil
        }
        
        return nil
    }
    
    private func add(salt: String, to text: String) -> String {
        return "\(salt.prefix(salt.count/2))\(text)\(salt.suffix(salt.count/2))"
    }
    
    private func setup() {
        if let checksum = contextChecksum() {
            let toCheck = add(salt: checksum.salt, to: password)
            isValid = toCheck.sha1() == checksum.checksum
            if (isValid) {
                let checksumAes = Crypto(key: password)
                guard let decryptedKey = checksumAes.decrypt(checksum.encryptedKey),
                    let decryptedString = String(data: decryptedKey, encoding: .utf8) else {
                    isValid = false
                    return
                }
                aes = Crypto(key: decryptedString)
            }
        }
        else if let checksum = NSEntityDescription.insertNewObject(forEntityName: CDChecksum.entity().name!, into: context) as? CDChecksum {
            checksum.salt = UUID().uuidString
            checksum.checksum = add(salt: checksum.salt, to: password).sha1()
            let encryptionPassword = UUID().uuidString.replacingOccurrences(of: "-", with: "")
            let checksumAes = Crypto(key: password)
            guard let encryptionPasswordData = encryptionPassword.data(using: .utf8),
                let encryptedKey = checksumAes.encrypt(encryptionPasswordData) else {
                    isValid = false
                    context.rollback()
                    return
            }
            aes = Crypto(key: encryptionPassword)
            checksum.encryptedKey = encryptedKey
            do {
                try context.save()
                isValid = true
            }
            catch {
                isValid = false
                context.rollback()
                return
            }
        }
        else {
            isValid = false
        }
    }
    
    func changePassword(to newPassword: String) -> Bool {
        guard isValid,
            newPassword.isEmpty == false else {
                return false
        }
        if let checksum = contextChecksum() {
            let checksumAes = Crypto(key: newPassword)
            guard let key = aes.key.data(using: .utf8),
                let encryptedKey = checksumAes.encrypt(key) else {
                    return false
            }
            checksum.salt = UUID().uuidString
            checksum.checksum = add(salt: checksum.salt, to: newPassword).sha1()
            checksum.encryptedKey = encryptedKey
            password = newPassword
            do {
                try context.save()
                return true
            }
            catch {
                context.rollback()
                return false
            }
        }
        return false
    }
    
    func check(password: String) -> Bool {
        guard let checksum = contextChecksum() else {
            return false
        }
        
        let toCheck = add(salt: checksum.salt, to: password)
        return toCheck.sha1() == checksum.checksum
    }
    
    func encrypted(data: Data) throws -> Data {
        guard isValid,
            let data = aes.encrypt(data) else {
                throw EncryptionManagerError.encryptionError
        }
        
        return data
    }
    
    func decrypted(data: Data) throws -> Data? {
        guard isValid,
            let data = aes.decrypt(data) else {
                throw EncryptionManagerError.decryptionError
        }
        
        return data
    }
    
    func encryptedJson(from json: [String : Any]) throws -> Data {
        guard isValid else {
            throw EncryptionManagerError.encryptionError
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
            let encryptedJsonData = aes.encrypt(jsonData) {
            return encryptedJsonData
        }
        
        throw EncryptionManagerError.encryptionError
    }
    
    func decryptedJson(from data: Data) throws -> [String : Any] {
        guard isValid,
            let decryptedData = aes.decrypt(data) else {
                throw EncryptionManagerError.decryptionError
        }
        
        
        if let toReturn = try? JSONSerialization.jsonObject(with: decryptedData, options: []) as? [String : Any] {
            return toReturn
        }
        throw EncryptionManagerError.decryptionError
    }
    
}

extension String {
    
    func sha1() -> String {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joined()
    }

}
