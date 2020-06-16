//
//  TagsScrollView.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 02.06.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift

class TagsScrollView: UIView {

    private let scrollView = UIScrollView()
    private let addButton = UI.button()
    private let tagsStack = UI.horizontalStackView(spacing: 12)
    private let noTagsLabel = UI.label()
    private let viewModel: TagsScrollViewModel
    
    init(viewModel: TagsScrollViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setup()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addTag(_ tag: CDTag) {
        let tagViewModel = TagViewModel(tag: tag)
        let tagView = TagView(viewModel: tagViewModel)
        tagView.translatesAutoresizingMaskIntoConstraints = false
        tagsStack.addArrangedSubview(tagView)
        noTagsLabel.isHidden = true
        
        tagView
            .removeView
            .producer
            .take(during: self.reactive.lifetime)
            .filter { $0 == true }
            .observe(on: UIScheduler())
            .take(first: 1)
            .startWithValues { [unowned self, tagView] _ in
                tagView.removeFromSuperview()
                self.noTagsLabel.isHidden = self.tagsStack.arrangedSubviews.count > 0
        }
    }
    
    private func setup() {
        noTagsLabel.translatesAutoresizingMaskIntoConstraints = false
        noTagsLabel.textColor = Appearance.detailColor
        noTagsLabel.text = String.localized("No tags")
        noTagsLabel.textAlignment = .center
        
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setImage(UIImage(named: "plus_icon.png"), for: .normal)
        let addAction = Action<(), UIButton, Never> { _ -> SignalProducer<UIButton, Never> in
            return SignalProducer { [unowned self] (observer, disposable) in
                self
                    .viewModel
                    .addTag()
                    .take(during: self.reactive.lifetime)
                    .observe(on: UIScheduler())
                    .startWithValues { [unowned self] tag in
                        self.addTag(tag)
                }
                observer.sendCompleted()
            }
        }
        addButton.reactive.pressed = CocoaAction(addAction)
        addButton.addConstraint(addButton.widthAnchor.constraint(equalToConstant: 36))

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        
        scrollView.addSubview(tagsStack)
        scrollView.addConstraints([scrollView.heightAnchor.constraint(equalToConstant: 44),
                                   tagsStack.heightAnchor.constraint(equalToConstant: 44),
                                   tagsStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
                                   tagsStack.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
                                   tagsStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                                   tagsStack.rightAnchor.constraint(equalTo: scrollView.rightAnchor)])

        let stackView = UI.horizontalStackView(spacing: 0)
        stackView.addArrangedSubview(scrollView)
        stackView.addArrangedSubview(addButton)
        stackView.backgroundColor = Appearance.backgroundColor
        addSubview(stackView)
        addSubview(noTagsLabel)

        addConstraints([heightAnchor.constraint(equalToConstant: 44),
                        stackView.topAnchor.constraint(equalTo: topAnchor),
                        stackView.leftAnchor.constraint(equalTo: leftAnchor),
                        stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
                        stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -8),
                        noTagsLabel.topAnchor.constraint(equalTo: topAnchor),
                        noTagsLabel.leftAnchor.constraint(equalTo: leftAnchor),
                        noTagsLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
                        noTagsLabel.rightAnchor.constraint(equalTo: rightAnchor)])
        
        if let tags = viewModel.document.tags {
            noTagsLabel.isHidden = tags.count > 0
            stackView.layoutMargins = .zero

            for i in 0..<tags.count {
                if let tag = tags[i] as? CDTag {
                    addTag(tag)
                }
            }
        }
        else {
            noTagsLabel.isHidden = false
        }
    }

}
