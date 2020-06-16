//
//  DocumentImagesPageViewController.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 25.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift

class DocumentImagesPageViewController: UIPageViewController {
    
    private let viewModel: DocumentImagesPageViewModel!
    private var startLocation = CGPoint()
    private var deltaY = CGFloat(0)
    private var lastDirection = CGFloat(0)
    
    private var currentVisibleViewController: ImagePreviewViewController?
    
    init(viewModel: DocumentImagesPageViewModel) {
        self.viewModel = viewModel
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        delegate = self
        dataSource = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    private func setup() {
        view.backgroundColor = Appearance.backgroundColor
        
        let closeButton = UIBarButtonItem(title: String.localized("Close"), style: .plain, target: self, action: #selector(closePressed))
        navigationItem.leftBarButtonItems = [closeButton]
        
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share))
        navigationItem.rightBarButtonItems = [shareButton]
        
        viewModel
            .contentImages
            .producer
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned self] images in
                if let currentVisibleViewController = self.currentVisibleViewController,
                    currentVisibleViewController.pageIndex < self.viewModel.contentImages.value.count {
                    self.currentVisibleViewController = self.imagePreviewViewController(forPage: currentVisibleViewController.pageIndex)
                }
                else {
                    self.currentVisibleViewController = self.firstViewController()
                }
                
                guard let currentVisibleViewController = self.currentVisibleViewController else { return }
                
                self.navigationItem.title = "\(currentVisibleViewController.pageIndex+1) / \(self.viewModel.contentImages.value.count)"
                self.setViewControllers([currentVisibleViewController], direction: .forward, animated: true, completion: nil)
        }
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGesture(sender:)))
        panGesture.delegate = self
        panGesture.delaysTouchesBegan = true
        view.addGestureRecognizer(panGesture)
    }
    
    private func firstViewController() -> ImagePreviewViewController? {
        if viewModel.contentImages.value.count == 0 {
            return nil
        }
        else if viewModel.firstIndex < viewModel.contentImages.value.count {
            return imagePreviewViewController(forPage: viewModel.firstIndex)
        }
        else {
            return imagePreviewViewController(forPage: 0)
        }
    }
    
    private func imagePreviewViewController(forPage index: Int) -> ImagePreviewViewController? {
        guard index < viewModel.contentImages.value.count,
            index >= 0 else {
            return nil
        }
        
        let content = viewModel.contentImages.value[index]
        let imageView = FileImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.update(content: content)
        return ImagePreviewViewController(imageView: imageView, pageIndex: index)
    }
    
    @objc func share() {
        if let image = currentVisibleViewController?.imageView.image {
            let avc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            present(avc, animated: true, completion: nil)
        }
    }
    
    @objc func closePressed() {
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       options: .curveLinear,
                       animations: { [weak self] in
                        let finalPoint = CGPoint(x: self?.navigationController?.view.center.x ?? 0, y: self?.navigationController?.view.frame.size.height ?? 0*1.5 + 100)
                        self?.view.center = finalPoint
                        self?.navigationController?.view.alpha = 0.1
        }) { [weak self] finished in
            if (finished) {
                self?.hideWindow()
            }
        }
    }
    
    @objc func panGesture(sender: UIPanGestureRecognizer) {
        defer {
            sender.setTranslation(CGPoint(x: 0, y: 0), in: view)
        }
        
        if sender.state == .began {
            startLocation = sender.location(in: view)
            deltaY = 0
            lastDirection = 0
        }
        
        let translation = sender.translation(in: view)
        deltaY += translation.y
        if translation.y != 0 && abs(translation.y) > 10 {
            lastDirection = translation.y
        }
        moveScrollViewCenter(delta: deltaY)
        
        navigationController?.view.alpha = 1.1 - abs(2*deltaY)/view.frame.height
        
        guard let senderViewFrame = sender.view?.frame else { return }
        
        if sender.state == .ended {
            let movedUp = startLocation.y > deltaY
            let lastDirectionIsUp = lastDirection < 0
            if abs(deltaY) > senderViewFrame.height/6,
                movedUp == lastDirectionIsUp {
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: { [unowned self] in
                    let finalPoint: CGPoint
                    if movedUp {
                        finalPoint = CGPoint(x: self.navigationController?.view.center.x ?? 0, y: -(senderViewFrame.height + 100))
                    }
                    else {
                        finalPoint = CGPoint(x: self.navigationController?.view.center.x ?? 0, y: senderViewFrame.height + 100)
                    }
                    self.moveScrollViewCenter(delta: finalPoint.y)
                    self.navigationController?.view.alpha = 0
                }) { [unowned self] finished in
                    if finished {
                        self.hideWindow()
                    }
                }
            }
            else {
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: { [unowned self] in
                    self.moveScrollViewCenter(delta: 0)
                    self.navigationController?.view.alpha = 1
                    }, completion: nil)
            }
        }
    }
    
    private func hideWindow() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    private func moveScrollViewCenter(delta: CGFloat) {
        currentVisibleViewController?.moveScrollViewCenter(delta: delta)
    }
    
}

extension DocumentImagesPageViewController : UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer.isKind(of: UIPinchGestureRecognizer.self) || otherGestureRecognizer.isKind(of: UIPanGestureRecognizer.self) {
            return false
        }
        return true
    }
    
}

extension DocumentImagesPageViewController : UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        currentVisibleViewController = pageViewController.viewControllers?.first as? ImagePreviewViewController
        if let currentVisibleViewController = currentVisibleViewController {
            navigationItem.title = "\(currentVisibleViewController.pageIndex + 1) / \(viewModel.contentImages.value.count)"
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let beforeVC = viewController as? ImagePreviewViewController {
            return imagePreviewViewController(forPage: beforeVC.pageIndex - 1)
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let beforeVC = viewController as? ImagePreviewViewController {
            return imagePreviewViewController(forPage: beforeVC.pageIndex + 1)
        }
        
        return nil
    }
    
}
