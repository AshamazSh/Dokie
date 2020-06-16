//
//  FolderViewController.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 25.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift

class FolderViewController: BaseViewController, UISearchDisplayDelegate {
    
    private let viewModel: FolderViewModel!
    private let noContentLabel = UI.label()
    private let searchBar = UISearchBar()
    
    init(viewModel: FolderViewModel) {
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchBar.resignFirstResponder()
    }
    
    private func setup() {
        viewModel
            .folderName
            .producer
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned self] name in
                self.navigationItem.title = name
        }
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonPressed))
        viewModel
            .showAddButtonBar
            .producer
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned self, addButton] show in
                self.navigationItem.rightBarButtonItems = show ? [addButton] : []
        }

        if viewModel.showMenuNavBarButton {
            let menuButton = UIBarButtonItem(image: UIImage(named: "settings_small.png"), style: .plain, target: self, action: #selector(menuButtonPressed))
            navigationItem.leftBarButtonItems = [menuButton]
        }
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.barTintColor = Appearance.backgroundColor
        searchBar.searchTextField.backgroundColor = Appearance.tagBackgroundColor
        searchBar.placeholder = String.localized("Search tags")
        searchBar.searchTextField.tintColor = .white
        searchBar.searchTextField.textColor = .white
        searchBar.delegate = self
        view.addSubview(searchBar)
        
        let tableView = UI.tableView()
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)

        noContentLabel.alpha = 0
        noContentLabel.textAlignment = .center
        view.addSubview(noContentLabel)
        viewModel
            .noContentText
            .producer
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned self] text in
                self.noContentLabel.text = text
        }

        let metrics = ["searchBarHeight"    : 44,
                       "sideMargin"         : 8]
        let views = ["searchBar" : searchBar, "tableView" : tableView, "noContentLabel" : noContentLabel]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[searchBar(searchBarHeight)][tableView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[tableView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-sideMargin-[searchBar]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[noContentLabel]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[noContentLabel]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        
        let longPress = UILongPressGestureRecognizer(target: nil, action: nil)
        longPress.minimumPressDuration = 1
        longPress.reactive.stateChanged.producer.startWithValues { [unowned self, tableView] gesture in
            guard gesture.state == .began else { return }
            let p = gesture.location(in: tableView)
            
            guard let indexPath = tableView.indexPathForRow(at: p) else { return }
            
            if indexPath.section == 0 {
                self.viewModel.longPressedSubfolder(at: indexPath)
            }
            else {
                self.viewModel.longPressedDocument(at: indexPath)
            }
        }
        tableView.addGestureRecognizer(longPress)
        
        viewModel
            .subfolders
            .producer
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned tableView] _ in
                tableView.reloadData()
        }
        
        viewModel
            .documents
            .producer
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned tableView] _ in
                tableView.reloadData()
        }
    }
    
    @objc private func addButtonPressed() {
        viewModel.addButtonPressed()
    }
    
    @objc private func menuButtonPressed() {
        viewModel.menuPressed()
    }
    
}

extension FolderViewController : UITableViewDelegate, UITableViewDataSource {
    
    var subfolderCellIdentifier: String { "subfolderCellIdentifier" }
    var documentCellIdentifier: String { "documentCellIdentifier" }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell: FolderNameTableViewCell
            if let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: subfolderCellIdentifier) as? FolderNameTableViewCell {
                cell = dequeuedCell
            }
            else {
                cell = FolderNameTableViewCell(style: .default, reuseIdentifier: subfolderCellIdentifier)
                cell.selectionStyle = .none
            }
            
            let action = Action<(), UIButton, Never> { _ -> SignalProducer<UIButton, Never> in
                return SignalProducer { [unowned self] (observer, disposable) in
                    self.viewModel.longPressedSubfolder(at: indexPath)
                    observer.sendCompleted()
                }
            }
            
            cell.editComand = CocoaAction(action)
            cell.name.value = viewModel.subfolders.value[indexPath.row]
            
            return cell
        }
        else {
            let cell: FileNameTableViewCell
            if let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: documentCellIdentifier) as? FileNameTableViewCell {
                cell = dequeuedCell
            }
            else {
                cell = FileNameTableViewCell(style: .default, reuseIdentifier: documentCellIdentifier)
                cell.selectionStyle = .none
            }
            
            let action = Action<(), UIButton, Never> { _ -> SignalProducer<UIButton, Never> in
                return SignalProducer { [unowned self] (observer, disposable) in
                    self.viewModel.longPressedDocument(at: indexPath)
                    observer.sendCompleted()
                }
            }
            
            cell.editComand = CocoaAction(action)
            cell.name.value = viewModel.documents.value[indexPath.row]
            
            return cell
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        noContentLabel.alpha = viewModel.documents.value.count + viewModel.subfolders.value.count > 0 ? 0 : 1
        
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? viewModel.subfolders.value.count : viewModel.documents.value.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            viewModel.didSelectSubfolder(at: indexPath)
        }
        else {
            viewModel.didSelectDocument(at: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        50
    }
}

extension FolderViewController : UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchText.value = searchText
    }

}

extension FolderViewController : UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }
    
}
