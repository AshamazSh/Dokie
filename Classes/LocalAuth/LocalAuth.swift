//
//  LocalAuth.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 14.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import Foundation
import LocalAuthentication
import ReactiveCocoa
import ReactiveSwift

struct LocalDBPassword : Codable {
    let dbPassword: String
}


class LocalAuth {
    
    static let shared = LocalAuth()
    
    let touchIdAvailable = MutableProperty<Bool>(false)
    let faceIdAvailable = MutableProperty<Bool>(false)
    private let navigationRouter = NavigationRouter.shared
    private let userDefaults = UserDefaults.standard
    
    private init() {
        setup()
    }
    
    private func setup() {
        let context = LAContext()
        var error: NSError?
        let biometricsAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if error == nil,
            biometricsAvailable {
            updateBiometricsAvailability()
        }
        else {
            resetStoredPassword()
        }
    }
    
    func resetStoredPassword() {
        let query = keychainRequestDictionary(forKey: C.keychainLocalDBPasswordKey)
        var dataTypeRef: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess {
            let deleteStatus = SecItemDelete(query as CFDictionary)
            assert(deleteStatus == errSecSuccess)
        }
        updateBiometricsAvailability()
    }
    
    private func updateBiometricsAvailability() {
        guard let localPassword = localDatabasePassword(),
            localPassword.isEmpty == false else {
                touchIdAvailable.value = false
                faceIdAvailable.value = false
                return
        }
        
        let context = LAContext()
        touchIdAvailable.value = context.biometryType == LABiometryType.touchID
        faceIdAvailable.value = context.biometryType == LABiometryType.faceID
    }
    
    private func localDatabasePassword() -> String? {
        return localDatabasePasswordDict()?.dbPassword
    }
    
    private func localDatabasePasswordDict() -> LocalDBPassword? {
        var query = keychainRequestDictionary(forKey: C.keychainLocalDBPasswordKey)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var dataTypeRef: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        guard status == errSecSuccess, let result = dataTypeRef as? Data else {
            return nil
        }
        if let keysDict = try? JSONDecoder().decode(LocalDBPassword.self, from: result) {
            return keysDict
        }
        // obj-c backward compatibility
        if let keysDict = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(result) as? [String : Any],
            let value = keysDict[C.dbPasswordKey] as? String {
            return LocalDBPassword(dbPassword: value)
        }
        
        return nil
    }
    
    private func keychainRequestDictionary(forKey key: String) -> [String : Any] {
        guard let encodedKey = key.data(using: .utf8) else {
            return [:]
        }
        return [kSecAttrService as String       : C.keychainServiceName,
                kSecClass as String             : kSecClassGenericPassword,
                kSecAttrAccount as String       : encodedKey,
                kSecReturnData as String        : kCFBooleanTrue!,
                kSecAttrAccessible as String    : kSecAttrAccessibleWhenUnlocked]
    }
    
    private func keychainUpdateRequestDictionary(forKey key: String) -> [String : Any] {
        guard let encodedKey = key.data(using: .utf8) else {
            return [:]
        }
        return [kSecAttrService as String       : C.keychainServiceName,
                kSecClass as String             : kSecClassGenericPassword,
                kSecAttrAccount as String       : encodedKey]
    }
    
    func databasePassword() -> SignalProducer<String?, Error> {
        return SignalProducer { [unowned self] (observer, lifetime) in
            let context = LAContext()
            var error: NSError?
            let biometricsAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            if error == nil,
                biometricsAvailable {
                let reasonText = context.biometryType == LABiometryType.touchID ?
                    String.localized("Login with Touch ID") :
                    String.localized("Login with Face ID")
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonText) { (success, error) in
                    if success {
                        observer.send(value: self.localDatabasePassword())
                        observer.sendCompleted()
                    }
                    else if let error = error {
                        observer.send(error: error)
                    }
                    else {
                        observer.sendCompleted()
                    }
                }
            }
            else if let error = error {
                observer.send(error: error)
            }
            else {
                assertionFailure("Invalid state")
                observer.sendCompleted()
            }
        }
    }
    
    func save(password: String) {
        guard password.isEmpty == false else {
            resetStoredPassword()
            return
        }
        
        let localDBDic = LocalDBPassword(dbPassword: password)
        
        do {
            let toSave = try JSONEncoder().encode(localDBDic)
            var query = keychainRequestDictionary(forKey: C.keychainLocalDBPasswordKey)
            var dataTypeRef: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
            if status == errSecSuccess {
                let updateQuery = keychainUpdateRequestDictionary(forKey: C.keychainLocalDBPasswordKey)
                let updateStatus = SecItemUpdate(updateQuery as CFDictionary, [kSecValueData as String : toSave] as CFDictionary)
                assert(updateStatus == errSecSuccess)
            }
            else {
                query[kSecValueData as String] = toSave
                let addStatus = SecItemAdd(query as CFDictionary, nil)
                assert(addStatus == errSecSuccess)
            }
            updateBiometricsAvailability()
        }
        catch let error {
            assertionFailure(error.localizedDescription)
        }
    }
    
    func validPasswordEntered(_ databasePassword: String) {
        let context = LAContext()
        var error: NSError?
        let biometricsAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if biometricsAvailable == true,
            localDatabasePassword() != databasePassword,
            userDefaults.bool(forKey: C.doNotSuggestPasswordSaveKey) == false {
            let alertTitle = context.biometryType == LABiometryType.touchID ?
                String.localized("Do you want to use Touch ID to login in future?") :
                String.localized("Do you want to use Face ID to login in future?")
            let alert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .alert)
            let yesAction = UIAlertAction(title: String.localized("Yes"), style: .default) { [unowned self] _ in
                self.save(password: databasePassword)
            }
            let noStopAction = UIAlertAction(title: String.localized("No (Do not ask again)"), style: .default) { [unowned self] _ in
                self.userDefaults.set(true, forKey: C.doNotSuggestPasswordSaveKey)
            }
            let noAction = UIAlertAction(title: String.localized("No"), style: .cancel) { [unowned self] _ in
                self.resetStoredPassword()
            }
            alert.addAction(yesAction)
            alert.addAction(noStopAction)
            alert.addAction(noAction)
            navigationRouter.showAlert(alert)
        }
    }
    
}
