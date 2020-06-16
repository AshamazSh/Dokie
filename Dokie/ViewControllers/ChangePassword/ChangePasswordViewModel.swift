//
//  ChangePasswordViewModel.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 25.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift

class ChangePasswordViewModel: NSObject {
    
    let currentPassword = MutableProperty<String?>(nil)
    let dismiss = Signal<Bool, Never>.pipe()
    let touchIdLoginEnabled = MutableProperty<Bool>(false)
    let faceIdLoginEnabled = MutableProperty<Bool>(false)
    
    private let localAuth = LocalAuth.shared
    private let coreDataManager = CoreDataManager.shared
    private let navigationRouter = NavigationRouter.shared
    private let userDefaults = UserDefaults.standard
    
    override init() {
        super.init()
        setup()
    }
    
    private func setup() {
        touchIdLoginEnabled <~ localAuth.touchIdAvailable
        faceIdLoginEnabled <~ localAuth.faceIdAvailable
    }
    
    func changePassword(current: String, new: String) {
        coreDataManager
            .changePassword(current, to: new)
            .observe(on: UIScheduler())
            .take(during: reactive.lifetime)
            .start { [unowned self] event in
                switch event {
                case .completed:
                    self.userDefaults.set(false, forKey: C.doNotSuggestPasswordSaveKey)
                    self.dismiss.input.send(value: true)
                    self.localAuth.validPasswordEntered(new)
                    
                default:
                    self.dismiss.input.send(value: false)
                }
        }
    }
    
    func retrieveCurrentPasswordWithBiometrics() {
        localAuth
            .databasePassword()
            .observe(on: UIScheduler())
            .take(during: reactive.lifetime)
            .startWithResult { [unowned self] result in
                switch result {
                case let .success(password):
                    self.currentPassword.value = password
                default:
                    break
                }
        }
    }
    
}
