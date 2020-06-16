//
//  NavigationRouter.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 14.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import ImagePicker

class NavigationRouter {
    private var navController: UINavigationController!
    private var mainWindow: UIWindow!
    private var loadingView: UIView? = nil
    private var loadingGuids = [String]()
    private let coreDataManager = CoreDataManager.shared

    static let shared = NavigationRouter()
    
    func createLoginViewController() {
        let viewModel = LoginViewModel()
        let viewController = LoginViewController(viewModel: viewModel)
        navController = UINavigationController(rootViewController: viewController)

        mainWindow = UIWindow(frame: UIScreen.main.bounds)
        mainWindow.rootViewController = navController
        mainWindow.makeKeyAndVisible()
    }

    
    func pushMainMenu(encryptionManager: EncryptionManager, managedObjectContext: NSManagedObjectContext) {
        coreDataManager.setup(encryptionManager: encryptionManager, context: managedObjectContext)
        push(folder: nil)
    }
    
    func push(folder: CDFolder?) {
        let viewModel = FolderViewModel(folder: folder)
        let viewController = FolderViewController(viewModel: viewModel)
        navController.pushViewController(viewController)
    }

    func push(document: CDDocument) {
        let viewModel = DocumentViewModel(document: document)
        let viewController = DocumentViewController(viewModel: viewModel)
        navController.pushViewController(viewController)
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancel = UIAlertAction(title: String.localized("OK"), style: .cancel, handler: nil)
        alert.addAction(cancel)
        showAlert(alert)
    }
    
    func showAlert(_ alert: UIAlertController) {
        guard let on = navController.viewControllers.last else { return }
        alert.popoverPresentationController?.sourceView = on.view
        alert.popoverPresentationController?.sourceRect = CGRect(x: on.view.bounds.size.width/2, y: on.view.bounds.size.height/2, width: 0, height: 0)
        alert.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        navController.present(alert)
    }
    
    func showImagePicker(_ imagePicker: UIImagePickerController) {
        navController.present(imagePicker)
    }

    func share(items: [Any]) {
        let avc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        navController.present(avc)
    }
    
    func show(images: [CDContent], firstIndex index: Int = 0) {
        let viewModel = DocumentImagesPageViewModel(images: images, firstIndex: index)
        let viewController = DocumentImagesPageViewController(viewModel: viewModel)
        
        let newNavController = UINavigationController(rootViewController: viewController)
        newNavController.modalPresentationStyle = .pageSheet
        navController.present(newNavController)
    }
    
    func logout() {
        coreDataManager.reset()
        navController.popViewController(animated: true)
    }
    
    func showChangePassword() {
        let viewModel = ChangePasswordViewModel()
        let viewController = ChangePasswordViewController(viewModel: viewModel)
        
        let newNavController = UINavigationController(rootViewController: viewController)
        newNavController.modalPresentationStyle = .pageSheet
        navController.present(newNavController)
    }

    func showLoading() -> String {
        if loadingView == nil {
            let view = UIView()
            view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            view.translatesAutoresizingMaskIntoConstraints = false
            
            let activity: UIActivityIndicatorView
            if #available(iOS 13, *) {
                activity = UIActivityIndicatorView(style: .large)
            }
            else {
                activity = UIActivityIndicatorView(style: .whiteLarge)
            }
            activity.translatesAutoresizingMaskIntoConstraints = false
            activity.startAnimating()
            view.addSubview(activity)
            
            NSLayoutConstraint.activate([activity.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                         activity.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
            
            let views = ["view" : view]
            navController.view.addSubview(view)
            navController.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
            navController.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
            
            loadingView = view
        }
        
        let guid = UUID().uuidString
        loadingGuids.append(guid)
        return guid
    }

    func hideLoading(_ guid: String) {
        if let index = loadingGuids.firstIndex(of: guid) {
            loadingGuids.remove(at: index)
        }

        if loadingGuids.count == 0 {
            loadingView?.removeFromSuperview()
            loadingView = nil
        }
    }

    func showAbout() {
        let viewController = AboutViewController()

        let newNavController = UINavigationController(rootViewController: viewController)
        newNavController.modalPresentationStyle = .pageSheet
        navController.present(newNavController)
    }

    func showImagePicker(_ picker: ImagePickerController) {
        navController.present(picker)
    }
    
}

extension UINavigationController {
    
    func pushViewController(_ viewController: UIViewController) {
        pushViewController(viewController, animated: true)
    }
    
    func present(_ viewControllerToPresent: UIViewController) {
        present(viewControllerToPresent, animated: true, completion: nil)
    }
    
}
