//
//  DocumentFilesView.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 25.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa

class DocumentFilesView: UIView {
    
    let viewMode = MutableProperty<ViewMode>(.display)
    let selectedCount = MutableProperty<Int>(0)
    
    private let viewModel: DocumentFilesViewModel!
    private var selectedCells = [IndexPath]()
    
    private let navigationRouter = NavigationRouter.shared
    
    init(viewModel: DocumentFilesViewModel) {
        self.viewModel = viewModel
        super.init(frame: CGRect())
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static let contentFilePreviewCellIdentifier = "contentFilePreviewCellIdentifier"
    
    private func setup() {
        let collectionView = UI.collectionView(lineSpacing: 4, itemSpacing: 0)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        collectionView.register(FilePreviewCollectionViewCell.self, forCellWithReuseIdentifier: DocumentFilesView.contentFilePreviewCellIdentifier)
        addSubview(collectionView)
        
        let views = ["collectionView" : collectionView]
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[collectionView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[collectionView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
        
        
        let longPress = UILongPressGestureRecognizer(target: collectionView, action: nil)
        longPress.minimumPressDuration = 1.0
        longPress
            .reactive
            .stateChanged
            .producer
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned self, collectionView] gesture in
                if gesture.state == .recognized {
                    let point = gesture.location(in: collectionView)
                    if let indexPath = collectionView.indexPathForItem(at: point) {
                        self.viewModel.edit(indexPath: indexPath)
                    }
                }
        }
        collectionView.addGestureRecognizer(longPress)
        
        viewModel
            .contentFiles
            .producer
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned collectionView] _ in
                collectionView.reloadData()
        }
        
        viewMode
            .producer
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned self, collectionView] viewMode in
                self.selectedCells.removeAll()
                self.selectedCount.value = 0
                
                if viewMode == .display {
                    for cell in collectionView.visibleCells {
                        if let collectionCell = cell as? FilePreviewCollectionViewCell {
                            collectionCell.showCheckmark.value = false
                        }
                    }
                }
        }
        
    }
    
    func refresh() {
        viewModel.read().start { _ in }
    }
    
    var selected: [CDContent] {
        var toReturn = [CDContent]()
        for indexPath in selectedCells {
            toReturn.append(viewModel.contentFiles.value[indexPath.row])
        }
        return toReturn
    }
    
    func deleteSelected() {
        viewModel.delete(indexPaths: selectedCells)
        selectedCells.removeAll()
    }
    
}

extension DocumentFilesView : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.contentFiles.value.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DocumentFilesView.contentFilePreviewCellIdentifier, for: indexPath) as? FilePreviewCollectionViewCell else { return UICollectionViewCell() }
        
        cell.update(content: viewModel.contentFiles.value[indexPath.row])
        cell.showCheckmark.value = viewMode.value == .select && selectedCells.contains(indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let factor = CGFloat(1.6)
        var width = (collectionView.bounds.size.width - 16 - 3*8) / 4
        if width < 0 {
            width = 0
        }
        return CGSize(width: width, height: width * factor)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch viewMode.value {
        case .display:
            navigationRouter.show(images: viewModel.contentFiles.value, firstIndex: indexPath.row)
            
        case .select:
            if let index = selectedCells.firstIndex(of: indexPath) {
                selectedCells.remove(at: index)
                if let cell = collectionView.cellForItem(at: indexPath) as? FilePreviewCollectionViewCell {
                    cell.showCheckmark.value = false
                }
            }
            else {
                selectedCells.append(indexPath)
                if let cell = collectionView.cellForItem(at: indexPath) as? FilePreviewCollectionViewCell {
                    cell.showCheckmark.value = true
                }
            }
            selectedCount.value = selectedCells.count
        }
    }
    
}

