//
//  ChangePasswordViewController.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 25.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift

class ChangePasswordViewController: BaseViewController {
    
    private let viewModel: ChangePasswordViewModel!
    private let currentPasswordTextField = UI.textField()
    private let passwordTextField = UI.textField()
    
    init(viewModel: ChangePasswordViewModel) {
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
        if #available(iOS 13, *) {
            isModalInPresentation = true
        }
        let cancelButton = UIBarButtonItem(title: String.localized("OK"), style: .plain, target: nil, action: nil)
        navigationItem.leftBarButtonItems = [cancelButton]
        
        let currentPassLabel = UI.label()
        currentPassLabel.text = String.localized("Current password:")
        view.addSubview(currentPassLabel)
        
        let touchIdButton = UI.touchIdButton()
        touchIdButton.reactive.alpha <~ viewModel.touchIdLoginEnabled.map { enabled -> CGFloat in
            enabled ? CGFloat(1) : CGFloat(0)
        }
        let touchIdAction = Action<(), (), Never> { _ -> SignalProducer<(), Never> in
            return SignalProducer { [unowned self] (observer, disposable) in
                self.viewModel.retrieveCurrentPasswordWithBiometrics()
                observer.sendCompleted()
            }
        }
        touchIdButton.reactive.pressed = CocoaAction(touchIdAction)
        view.addSubview(touchIdButton)
        
        let faceIdButton = UI.faceIdButton()
        faceIdButton.reactive.alpha <~ viewModel.faceIdLoginEnabled.map { enabled -> CGFloat in
            enabled ? CGFloat(1) : CGFloat(0)
        }
        let faceIdAction = Action<(), (), Never> { _ -> SignalProducer<(), Never> in
            return SignalProducer { [unowned self] (observer, disposable) in
                self.viewModel.retrieveCurrentPasswordWithBiometrics()
                observer.sendCompleted()
            }
        }
        faceIdButton.reactive.pressed = CocoaAction(faceIdAction)
        view.addSubview(faceIdButton)
        
        currentPasswordTextField.isSecureTextEntry = true
        view.addSubview(currentPasswordTextField)
        
        viewModel
            .currentPassword
            .producer
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned self] password in
                self.currentPasswordTextField.text = password
        }
        
        let newPassLabel = UI.label()
        newPassLabel.text = String.localized("New password:")
        view.addSubview(newPassLabel)
        
        passwordTextField.isSecureTextEntry = true
        view.addSubview(passwordTextField)
        
        let changeButton = UI.actionButton()
        changeButton.setTitle(String.localized("Change password"), for: .normal)
        view.addSubview(changeButton)
        
        let loadingView = UI.shadowView()
        loadingView.alpha = 0
        view.addSubview(loadingView)
        
        let views = ["currentPassLabel" : currentPassLabel,
                     "currentPasswordTextField" : currentPasswordTextField,
                     "newPassLabel" : newPassLabel,
                     "passwordTextField" : passwordTextField,
                     "changeButton" : changeButton,
                     "touchIdButton" : touchIdButton,
                     "faceIdButton" : faceIdButton,
                     "loadingView" : loadingView]
        
        let metrics = ["topMargin"          :   20,
                       "betweenMargin"      :   20,
                       "betweenSmallMargin" :   16,
                       "sideMargin"         :   25,
                       "buttonHeight"       :   44,
                       "textFieldHeight"    :   44,
                       "labelHeight"        :   30]
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-sideMargin-[currentPassLabel]-sideMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[touchIdButton(labelHeight)]-sideMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[faceIdButton(labelHeight)]-sideMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-sideMargin-[currentPasswordTextField]-sideMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-sideMargin-[newPassLabel]-sideMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-sideMargin-[passwordTextField]-sideMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-sideMargin-[changeButton]-sideMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-topMargin-[currentPassLabel(labelHeight)]-betweenSmallMargin-[currentPasswordTextField(textFieldHeight)]-betweenMargin-[newPassLabel(labelHeight)]-betweenSmallMargin-[passwordTextField(textFieldHeight)]-betweenMargin-[changeButton(buttonHeight)]", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-topMargin-[touchIdButton(labelHeight)]", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-topMargin-[faceIdButton(labelHeight)]", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[loadingView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[loadingView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        
        let activity: UIActivityIndicatorView
        if #available(iOS 13, *) {
            activity = UIActivityIndicatorView(style: .large)
        }
        else {
            activity = UIActivityIndicatorView(style: .whiteLarge)
        }
        activity.translatesAutoresizingMaskIntoConstraints = false
        activity.startAnimating()
        
        loadingView.addSubview(activity)
        NSLayoutConstraint.activate([activity.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
                                     activity.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor)])
        
        
        let changeButtonAction = Action<(), (), Never> { _ -> SignalProducer<(), Never> in
            return SignalProducer { [unowned self, loadingView] (observer, disposable) in
                loadingView.alpha = 1
                self.viewModel.changePassword(current: self.currentPasswordTextField.text ?? "", new: self.passwordTextField.text ?? "")
                observer.sendCompleted()
            }
        }
        changeButton.reactive.pressed = CocoaAction(changeButtonAction)
        
        let cancelButtonAction = Action<(), (), Never> { _ -> SignalProducer<(), Never> in
            return SignalProducer { [unowned self, loadingView] (observer, disposable) in
                if loadingView.alpha == 0 {
                    self.dismiss(animated: true, completion: nil)
                }
                observer.sendCompleted()
            }
        }
        cancelButton.reactive.pressed = CocoaAction(cancelButtonAction)
        
        viewModel
            .dismiss
            .output
            .observe(on: UIScheduler())
            .take(during: reactive.lifetime)
            .observeValues { [unowned self, loadingView] ok in
                loadingView.alpha = 0
                if ok {
                    self.dismiss(animated: true, completion: nil)
                }
                else {
                    let alert = UIAlertController(title: nil, message: String.localized("Invalid password"), preferredStyle: .alert)
                    let cancel = UIAlertAction(title: String.localized("OK"), style: .cancel, handler: nil)
                    alert.addAction(cancel)
                    self.navigationController?.present(alert)
                }
        }
    }
    
}
