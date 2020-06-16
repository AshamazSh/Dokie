//
//  DocumentViewController.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 25.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift

class DocumentViewController: BaseViewController {
    
    private let viewModel: DocumentViewModel!
    private var textView: DocumentTextView!
    private var filesView: DocumentFilesView!
    private var tagsView: TagsScrollView!
    private var didAppearFirstTime: Bool = false
    private let navigationRouter = NavigationRouter.shared
    
    init(viewModel: DocumentViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !didAppearFirstTime {
            textView.refresh()
            filesView.refresh()
            didAppearFirstTime = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    private func setup() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonPressed))
        navigationItem.rightBarButtonItems = [addButton]
        
        viewModel
            .documentName
            .producer
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned self] name in
                self.navigationItem.title = name
        }
        
        let segmented = UI.segmentedControl(items: [String.localized("Text"), String.localized("Files")])
        view.addSubview(segmented)
        
        let separator = UI.separator()
        view.addSubview(separator)

        let bottomSeparator = UI.separator()
        view.addSubview(bottomSeparator)

        tagsView = TagsScrollView(viewModel: viewModel.tagsViewModel)
        tagsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tagsView)
        
        textView = DocumentTextView(viewModel: viewModel.textViewModel)
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        
        filesView = DocumentFilesView(viewModel: viewModel.filesViewModel)
        filesView.translatesAutoresizingMaskIntoConstraints = false
        filesView.alpha = 0
        view.addSubview(filesView)
        
        let controlView = createControlView()
        view.addSubview(controlView)
        
        let metrics = ["top"                :   10,
                       "segmentedSide"      :   30,
                       "vertical"           :   10,
                       "separatorHeight"    :   1]
        let views = ["segmented"        : segmented,
                     "separator"        : separator,
                     "textView"         : textView!,
                     "filesView"        : filesView!,
                     "tagsView"         : tagsView!,
                     "controlView"      : controlView,
                     "bottomSeparator"  : bottomSeparator]
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-top-[segmented]-vertical-[separator(separatorHeight)][textView][bottomSeparator(separatorHeight)][tagsView][controlView]", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[separator][filesView][bottomSeparator]", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-segmentedSide-[segmented]-segmentedSide-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[separator]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[tagsView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[textView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[filesView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[controlView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[bottomSeparator]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        NSLayoutConstraint.activate([controlView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)])
        
        segmented
            .reactive
            .selectedSegmentIndexes
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .observeValues { [unowned self] selectedIndex in
                if selectedIndex == 0 {
                    self.textView.alpha = 1
                    self.filesView.alpha = 0
                }
                else {
                    self.textView.alpha = 0
                    self.filesView.alpha = 1
                }
                self.view.layoutIfNeeded()
        }
        
        viewModel
            .forceSegmentedSectionSelect
            .producer
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .skip(first: 1)
            .startWithValues { [unowned segmented] index in
                segmented.selectedSegmentIndex = index
                if index == 0 {
                    self.textView.alpha = 1
                    self.filesView.alpha = 0
                }
                else {
                    self.textView.alpha = 0
                    self.filesView.alpha = 1
                }
                self.view.layoutIfNeeded()
        }

    }
    
    private func createControlView() -> UIView {
        let controlView = UI.view()
        
        let separator = UI.separator()
        controlView.addSubview(separator)
        
        let selectButton = UI.button()
        selectButton.setTitle(String.localized("Select"), for: .normal)
        controlView.addSubview(selectButton)
        
        let cancelButton = UI.button()
        cancelButton.setTitle(String.localized("Cancel"), for: .normal)
        cancelButton.alpha = 0
        controlView.addSubview(cancelButton)
        
        let shareButton = UI.button()
        shareButton.setTitle(String.localized("Share"), for: .normal)
        shareButton.alpha = 0
        controlView.addSubview(shareButton)
        
        let deleteButton = UI.button()
        deleteButton.setTitle(String.localized("Delete"), for: .normal)
        deleteButton.alpha = 0
        controlView.addSubview(deleteButton)
        
        let metrics = ["sideMargin"     :   16,
                       "vMargin"        :   4,
                       "buttonHeight"   :   44,
                       "separatorHeight":   1]
        
        let views = ["separator" : separator,
                     "selectButton" : selectButton,
                     "cancelButton" : cancelButton,
                     "shareButton" : shareButton,
                     "deleteButton" : deleteButton]
        
        controlView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-sideMargin-[deleteButton]", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        controlView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[selectButton]-sideMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        controlView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[cancelButton]-sideMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        controlView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[separator]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        controlView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[separator(separatorHeight)]-vMargin-[selectButton(buttonHeight)]-vMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        controlView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[separator]-vMargin-[cancelButton(buttonHeight)]-vMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        controlView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[separator]-vMargin-[shareButton(buttonHeight)]-vMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        controlView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[separator]-vMargin-[deleteButton(buttonHeight)]-vMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        
        controlView.addConstraints([NSLayoutConstraint(item: shareButton, attribute: .centerX, relatedBy: .equal, toItem: controlView, attribute: .centerX, multiplier: 1, constant: 0),
                                    NSLayoutConstraint(item: shareButton, attribute: .width, relatedBy: .equal, toItem: controlView, attribute: .width, multiplier: 0.4, constant: 0)])
        
        let selectButtonAction = Action<(), (), Never> { _ -> SignalProducer<(), Never> in
            return SignalProducer { [unowned self, selectButton, cancelButton, shareButton, deleteButton] (observer, disposable) in
                self.textView?.viewMode.value = .select
                self.filesView?.viewMode.value = .select
                
                selectButton.alpha = 0
                cancelButton.alpha = 1
                shareButton.alpha = 1
                deleteButton.alpha = 1
                shareButton.setTitle(String.localized("Share"), for: .normal)
                observer.sendCompleted()
            }
        }
        selectButton.reactive.pressed = CocoaAction(selectButtonAction)
        
        let cancelButtonAction = Action<(), (), Never> { _ -> SignalProducer<(), Never> in
            return SignalProducer { [unowned self, selectButton, cancelButton, shareButton, deleteButton] (observer, disposable) in
                self.textView?.viewMode.value = .display
                self.filesView?.viewMode.value = .display
                
                selectButton.alpha = 1
                cancelButton.alpha = 0
                shareButton.alpha = 0
                deleteButton.alpha = 0
                shareButton.setTitle(String.localized("Share"), for: .normal)
                observer.sendCompleted()
            }
        }
        cancelButton.reactive.pressed = CocoaAction(cancelButtonAction)
        
        let shareButtonAction = Action<(), (), Never> { _ -> SignalProducer<(), Never> in
            return SignalProducer { [unowned self, cancelButtonAction] (observer, disposable) in
                self.viewModel.share(texts: self.textView.selected, images: self.filesView.selected)
                cancelButtonAction.apply(()).startWithCompleted {}
                observer.sendCompleted()
            }
        }
        shareButton.reactive.pressed = CocoaAction(shareButtonAction)
        
        let deleteButtonAction = Action<(), (), Never> { _ -> SignalProducer<(), Never> in
            return SignalProducer { [unowned self] (observer, disposable) in
                if self.textView.selectedCount.value + self.filesView.selectedCount.value > 0 {
                    let alert = UIAlertController(title: String.localized("Delete selected content?"), message: nil, preferredStyle: .alert)
                    let delete = UIAlertAction(title: String.localized("Yes"), style: .destructive) { [unowned self, cancelButtonAction] _ in
                        self.filesView?.deleteSelected()
                        self.textView?.deleteSelected()
                        cancelButtonAction.apply(()).startWithCompleted {}
                    }
                    let cancel = UIAlertAction(title: String.localized("Cancel"), style: .cancel)
                    
                    alert.addAction(delete)
                    alert.addAction(cancel)
                    self.navigationRouter.showAlert(alert)
                }
                observer.sendCompleted()
            }
        }
        deleteButton.reactive.pressed = CocoaAction(deleteButtonAction)
        
        SignalProducer
            .combineLatest([filesView.selectedCount.producer,
                            textView.selectedCount.producer])
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned shareButton] selectedCounts in
                var total = 0
                for count in selectedCounts {
                    total += count
                }
                
                var title = String.localized("Share")
                if total > 0 {
                    title += " (\(total))"
                }
                shareButton.setTitle(title, for: .normal)
        }
        
        return controlView
    }
    
    @objc private func addButtonPressed() {
        viewModel.addButtonPressed()
    }
    
}
