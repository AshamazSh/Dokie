//
//  LoginViewModel.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 14.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import Foundation
import ReactiveCocoa
import ReactiveSwift
import CoreData

class LoginViewModel : NSObject {
    
    let enableInput = MutableProperty<Bool>(true)
    let loginLabelText = MutableProperty<String>("")
    let loginButtonText = MutableProperty<String>("")
    let touchIdLoginEnabled = MutableProperty<Bool>(false)
    let faceIdLoginEnabled = MutableProperty<Bool>(false)
    var biometricsAvailable: Bool {
        touchIdLoginEnabled.value || faceIdLoginEnabled.value
    }
    private let localAuth = LocalAuth.shared
    private let objectContext: NSManagedObjectContext!
    private let navigationRouter = NavigationRouter.shared
    
    override init() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.objectContext = appDelegate.objectContext
        }
        else {
            self.objectContext = nil
        }
        super.init()
        setup()
    }
    
    private func setup() {
        touchIdLoginEnabled <~ localAuth.touchIdAvailable
        faceIdLoginEnabled <~ localAuth.faceIdAvailable
        updateText()
    }
    
    func loginPressed(password: String?) {
        guard let password = password else {
            navigationRouter.showAlert(title: "", message: String.localized("Invalid password"))
            return
        }
        
        enableInput.value = false
        let loadingGuid = navigationRouter.showLoading()
        DispatchQueue.main.async { [unowned self] in
            let encryptionManager = EncryptionManager(password: password, context: self.objectContext)
            self.navigationRouter.hideLoading(loadingGuid)
            if encryptionManager.isValid {
                self.navigationRouter.pushMainMenu(encryptionManager: encryptionManager, managedObjectContext: self.objectContext)
                DispatchQueue.main.async { [unowned self] in
                    self.localAuth.validPasswordEntered(password)
                }
            }
            else {
                self.navigationRouter.showAlert(title: "", message: String.localized("Invalid password"))
            }
            self.enableInput.value = true
        }
    }
    
    func loginWithBiometrics() {
        localAuth
            .databasePassword()
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithResult { [unowned self] result in
                switch result {
                case let .success(password):
                    self.loginPressed(password: password)
                default:
                    self.navigationRouter.showAlert(title: "", message: String.localized("Can not retrieve password from keychain"))
                }
        }
    }
    
    func showAbout() {
        navigationRouter.showAbout()
    }
    
    func updateText() {
        let hasKey = EncryptionManager.keyExists(in: objectContext)
        loginLabelText.value = hasKey ? String.localized("Password:") : String.localized("Welcome to Dokie!\nCreate password for your database:")
        loginButtonText.value = hasKey ? String.localized("Login") : String.localized("Create database")
        if hasKey == false {
            localAuth.resetStoredPassword()
        }
    }
    
}
