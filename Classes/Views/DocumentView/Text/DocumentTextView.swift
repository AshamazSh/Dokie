//
//  DocumentTextView.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 17.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift

class DocumentTextView : UIView {
    
    let viewMode = MutableProperty<ViewMode>(.display)
    let selectedCount = MutableProperty<Int>(0)
    
    private let viewModel: DocumentTextViewModel!
    private var selectedCells = [IndexPath]()
    
    init(viewModel: DocumentTextViewModel) {
        self.viewModel = viewModel
        super.init(frame: CGRect())
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = Appearance.backgroundColor
        
        let tableView = UI.tableView()
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.delegate = self
        tableView.dataSource = self
        addSubview(tableView)
        
        let views = ["tableView" : tableView]
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[tableView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: [:], views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[tableView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: [:], views: views))
        
        let longPress = UILongPressGestureRecognizer(target: tableView, action: nil)
        longPress
            .reactive
            .stateChanged
            .producer
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned self, tableView] gesture in
                if gesture.state == .recognized {
                    let point = gesture.location(in: tableView)
                    if let indexPath = tableView.indexPathForRow(at: point) {
                        self.viewModel.edit(indexPath: indexPath)
                    }
                }
        }
        tableView.addGestureRecognizer(longPress)
        
        viewModel
            .content
            .producer
            .skip(first: 1)
            .skipRepeats({ (left, right) -> Bool in
                left == right
            })
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned tableView] _ in
                tableView.reloadData()
        }
        
        viewMode
            .producer
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned self, tableView] viewMode in
                self.selectedCells.removeAll()
                self.selectedCount.value = 0
                
                switch viewMode {
                case .display:
                    for cell in tableView.visibleCells {
                        if let tableCell = cell as? DocumentTextTableViewCell {
                            tableCell.viewMode.value = viewMode
                            tableCell.showCheckmark.value = false
                        }
                    }
                case .select:
                    for cell in tableView.visibleCells {
                        if let tableCell = cell as? DocumentTextTableViewCell {
                            tableCell.viewMode.value = viewMode
                        }
                    }
                    
                }
        }
    }
    
    func refresh() {
        viewModel.read().start { _ in }
    }
    
    var selected: [String] {
        var toReturn = [String]()
        for indexPath in selectedCells {
            let content = viewModel.content.value[indexPath.row]
            toReturn.append(content.string())
        }
        
        return toReturn
    }
    
    func deleteSelected() {
        viewModel.delete(indexPaths: selectedCells)
    }
}

extension DocumentTextView : UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.content.value.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        50
    }
    
    private static let contentCellIdentifier = "contentCellIdentifier"
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: DocumentTextTableViewCell
        if let tableCell = tableView.dequeueReusableCell(withIdentifier: DocumentTextView.contentCellIdentifier) as? DocumentTextTableViewCell {
            cell = tableCell
        }
        else {
            cell = DocumentTextTableViewCell(style: .subtitle, reuseIdentifier: DocumentTextView.contentCellIdentifier)
            cell.selectionStyle = .none
        }
        
        let value = viewModel.content.value[indexPath.row]
        cell.textProperty.value = value.text
        cell.descriptionProperty.value = value.description
        cell.viewMode.value = viewMode.value
        cell.showCheckmark.value = viewMode.value == .select && selectedCells.contains(indexPath)
        let editAction = Action<(), UIButton, Never> { _ -> SignalProducer<UIButton, Never> in
            return SignalProducer { [unowned self] (observer, disposable) in
                self.viewModel.edit(indexPath: indexPath)
                observer.sendCompleted()
            }
        }
        
        cell.editCommand = CocoaAction(editAction)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch viewMode.value {
        case .display:
            viewModel.didSelect(indexPath: indexPath)
        case .select:
            let showCheckmark: Bool
            if let index = selectedCells.firstIndex(of: indexPath) {
                selectedCells.remove(at: index)
                showCheckmark = false
            }
            else {
                selectedCells.append(indexPath)
                showCheckmark = true
            }
            
            for cell in tableView.visibleCells {
                if let tableCell = cell as? DocumentTextTableViewCell,
                    tableView.indexPath(for: cell) == indexPath {
                    tableCell.showCheckmark.value = showCheckmark
                }
            }
            selectedCount.value = selectedCells.count
        }
    }
    
}
