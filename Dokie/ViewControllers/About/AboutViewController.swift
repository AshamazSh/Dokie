//
//  AboutViewController.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 25.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift

class AboutViewController: BaseViewController {
    
    init() {
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
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let cancelButton = UIBarButtonItem(title: String.localized("OK"), style: .plain, target: nil, action: nil)
        navigationItem.leftBarButtonItems = [cancelButton]
        
        let action = Action<(), (), Never> { _ -> SignalProducer<(), Never> in
            return SignalProducer { [unowned self] (observer, disposable) in
                self.navigationController?.dismiss(animated: true, completion: nil)
                observer.sendCompleted()
            }
        }
        cancelButton.reactive.pressed = CocoaAction(action)
        
        let iconImage = UI.imageView()
        iconImage.image = UIImage(named: "transparent_icon.png")
        view.addSubview(iconImage)
        
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.dataDetectorTypes = .all
        textView.text = String.localized("Q/A") + "\n\n" +
            String.localized("Q: ") + String.localized("I forgot my password. Is there any way to restore it?") + "\n\n" +
            String.localized("A: ") + String.localized("Currently no. You can use touch/face id to store and access your password via keychain.") + "\n\n" +
            
            String.localized("Q: ") + String.localized("I deleted the app. Is it possible to restore my data after that?") + "\n\n" +
            String.localized("A: ") + String.localized("There is no way to restore them. All data will be deleted as well.") + "\n\n" +
            
            String.localized("Q: ") + String.localized("Will be photos from my gallery deleted after I import them to the app?") + "\n\n" +
            String.localized("A: ") + String.localized("No. App does not delete images from your gallery.") + "\n\n" +
            
            String.localized("Q: ") + String.localized("Can I have any backups in the app?") + "\n\n" +
            String.localized("A: ") + String.localized("App does not support backups for now. But you can backup your device using iTunes or iCloud.") + "\n\n" +
            
            String.localized("Q: ") + String.localized("Are my images stored in app as separate files?") + "\n\n" +
            String.localized("A: ") + String.localized("No. All images will be encrypted and stored in one file.") + "\n\n" +
            
            String.localized("Q: ") + String.localized("Does app collect any info of stored data?") + "\n\n" +
            String.localized("A: ") + String.localized("No. App does not track any of your data.") + "\n\n" +

            "\n" +
            String.localized("Have any ideas how to make this app better? Feel free to mail me:") + " ashamazsh@gmail.com" + "\n\n" +
            String.localized("Source code:") + " https://github.com/AshamazSh/Dokie" + "\n\n" +
            String.localized("Version:") + " " + version + "\n\n" +
            "Ashamaz Shidov"

        textView.isEditable = false
        textView.textColor = Appearance.tintColor
        textView.backgroundColor = Appearance.backgroundColor
        textView.font = UIFont.systemFont(ofSize: 18)
        view.addSubview(textView)
        
        let views = ["iconImage" : iconImage,
                     "textView" : textView]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-10-[iconImage(100)]-20-[textView]", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[iconImage(100)]", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[textView]-20-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
        NSLayoutConstraint.activate([iconImage.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
                                     textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)])
    }
    
}
