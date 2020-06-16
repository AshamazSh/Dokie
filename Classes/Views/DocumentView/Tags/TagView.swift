//
//  TagView.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 02.06.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift

class TagView: UIView {

    private let editButton = UI.button()
    private let deleteButton = UI.button()
    private let height = CGFloat(30)
    private let viewModel: TagViewModel
    
    let removeView = MutableProperty<Bool>(false)

    init(viewModel: TagViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setup()
    }
    
    override init(frame: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = Appearance.tagBackgroundColor
        layer.masksToBounds = true
        layer.cornerRadius = 5
        
        editButton.translatesAutoresizingMaskIntoConstraints = false
        let editAction = Action<(), UIButton, Never> { _ -> SignalProducer<UIButton, Never> in
            return SignalProducer { [unowned self] (observer, disposable) in
                self.viewModel.editPressed()
                observer.sendCompleted()
            }
        }
        editButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        editButton.titleLabel?.setContentCompressionResistancePriority(.required, for: .horizontal)
        editButton.reactive.pressed = CocoaAction(editAction)

        viewModel
            .text
            .producer
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned self] text in
                self.editButton.setTitle(text, for: .normal)
                self.layoutIfNeeded()
        }

        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setImage(UIImage(named: "cross.png"), for: .normal)
        deleteButton.imageEdgeInsets = UIEdgeInsets(equal: 6)
        deleteButton.addConstraint(NSLayoutConstraint(item: deleteButton, attribute: .width, relatedBy: .equal, toItem: deleteButton, attribute: .height, multiplier: 1, constant: 0))
        let deleteAction = Action<(), UIButton, Never> { _ -> SignalProducer<UIButton, Never> in
            return SignalProducer { [unowned self] (observer, disposable) in
                self
                    .viewModel
                    .deletePressed()
                    .take(during: self.reactive.lifetime)
                    .observe(on: UIScheduler())
                    .startWithCompleted { [unowned self] in
                        self.removeView.value = true
                }
                observer.sendCompleted()
            }
        }
        deleteButton.reactive.pressed = CocoaAction(deleteAction)

        let stackView = UI.horizontalStackView(spacing: 10)
        stackView.addArrangedSubview(deleteButton)
        stackView.addArrangedSubview(editButton)
        addSubview(stackView)

        addConstraints([stackView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
                        stackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 4),
                        stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
                        stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -height/2),
                        heightAnchor.constraint(equalToConstant: height)])
    }

}
