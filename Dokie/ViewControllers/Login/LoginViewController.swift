//
//  LoginViewController.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 14.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import Foundation
import UIKit
import ReactiveCocoa
import ReactiveSwift

class LoginViewController: BaseViewController {
    
    private let viewModel: LoginViewModel!
    private let passwordTextField = UI.textField()
    private let loginButton = UI.actionButton()
    
    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    private func setup() {
        let helpButton = UIBarButtonItem(title: String.localized("About"), style: .plain, target: self, action: #selector(showAbout))
        navigationItem.rightBarButtonItems = [helpButton]
        
        let loginLabel = UI.label()
        loginLabel.numberOfLines = 0
        view.addSubview(loginLabel)
        
        viewModel
            .loginLabelText
            .producer
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned loginLabel] text in
                loginLabel.text = text
        }
        
        passwordTextField.returnKeyType = .go
        passwordTextField.delegate = self
        passwordTextField.isSecureTextEntry = true
        view.addSubview(passwordTextField)
        
        let loginButtonAction = Action<(), (), Never> { _ -> SignalProducer<(), Never> in
            return SignalProducer { [unowned self] (observer, disposable) in
                self.loginPressed()
                observer.sendCompleted()
            }
        }
        loginButton.reactive.pressed = CocoaAction(loginButtonAction)
        view.addSubview(loginButton)
        
        viewModel
            .loginButtonText
            .producer
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned self] text in
                self.loginButton.setTitle(text, for: .normal)
        }
        
        let touchIdButton = UI.touchIdButton()
        view.addSubview(touchIdButton)
        
        viewModel
            .touchIdLoginEnabled
            .producer
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned touchIdButton] available in
                touchIdButton.alpha = available ? 1 : 0
        }
        
        let faceIdButton = UI.faceIdButton()
        view.addSubview(faceIdButton)
        
        viewModel
            .faceIdLoginEnabled
            .producer
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned faceIdButton] available in
                faceIdButton.alpha = available ? 1 : 0
        }
        
        let biometricsButtonAction = Action<(), (), Never> { _ -> SignalProducer<(), Never> in
            return SignalProducer { [unowned self] (observer, disposable) in
                self.viewModel.loginWithBiometrics()
                observer.sendCompleted()
            }
        }
        touchIdButton.reactive.pressed = CocoaAction(biometricsButtonAction)
        faceIdButton.reactive.pressed = CocoaAction(biometricsButtonAction)
        
        let views = ["passwordTextField" : passwordTextField,
                     "loginButton" : loginButton,
                     "loginLabel" : loginLabel,
                     "touchIdButton" : touchIdButton,
                     "faceIdButton" : faceIdButton]
        let metrics = ["betweenMargin"      :   16,
                       "sideMargin"         :   25,
                       "buttonHeight"       :   44,
                       "textFieldHeight"    :   44,
                       "bioButtonSize"      :   30]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-sideMargin-[loginLabel][touchIdButton(bioButtonSize)]-sideMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-sideMargin-[loginLabel][faceIdButton(bioButtonSize)]-sideMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-sideMargin-[passwordTextField]-sideMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-sideMargin-[loginButton]-sideMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[loginLabel(>=bioButtonSize)]-betweenMargin-[passwordTextField(textFieldHeight)]-betweenMargin-[loginButton(buttonHeight)]", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[touchIdButton(bioButtonSize)]", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[faceIdButton(bioButtonSize)]", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraint(NSLayoutConstraint(item: passwordTextField, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 0.6, constant: 0))
        NSLayoutConstraint.activate([touchIdButton.centerYAnchor.constraint(equalTo: loginLabel.centerYAnchor),
                                     faceIdButton.centerYAnchor.constraint(equalTo: loginLabel.centerYAnchor)])
        
        viewModel
            .enableInput
            .producer
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned self] enable in
                self.loginButton.isEnabled = enable
                self.passwordTextField.isEnabled = enable
                self.passwordTextField.text = ""
        }
    }
    
    @objc private func showAbout() {
        viewModel.showAbout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.updateText()
    }
    
    private var didSuggestLoginWithBiometrics = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (!didSuggestLoginWithBiometrics) {
            didSuggestLoginWithBiometrics = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [unowned self] in
                if self.viewModel.biometricsAvailable {
                    self.viewModel.loginWithBiometrics()
                }
                else {
                    self.passwordTextField.becomeFirstResponder()
                }
            }
        }
        else {
            passwordTextField.becomeFirstResponder()
        }
    }
    
    private func loginPressed() {
        passwordTextField.endEditing(true)
        viewModel.loginPressed(password: passwordTextField.text)
    }
    
}

extension LoginViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        loginPressed()
        return true
    }
    
}
