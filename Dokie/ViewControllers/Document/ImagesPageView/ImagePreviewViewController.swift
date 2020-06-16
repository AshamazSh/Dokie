//
//  ImagePreviewViewController.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 25.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa

class ImagePreviewViewController: BaseViewController {
    
    let imageView: FileImageView
    private(set) var pageIndex: Int
    
    private let scrollView = UI.scrollView()
    private var scrollTopConstraint: NSLayoutConstraint?
    private var scrollBottomConstraint: NSLayoutConstraint?
    private var scrollViewContentInset = UIEdgeInsets()
    private let scrollViewContent = UI.view()
    
    init(imageView: FileImageView, pageIndex: Int) {
        self.imageView = imageView
        self.pageIndex = pageIndex
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
        view.backgroundColor = Appearance.backgroundColor
        
        imageView.removeFromSuperview()
        
        scrollView.delegate = self
        scrollView.backgroundColor = Appearance.backgroundColor
        view.addSubview(scrollView)
        
        let views = ["scrollView" : scrollView]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[scrollView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
        let topConstraint = NSLayoutConstraint(item: scrollView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: scrollView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        view.addConstraints([topConstraint, bottomConstraint])
        scrollTopConstraint = topConstraint
        scrollBottomConstraint = bottomConstraint
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(sender:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
        
        setupScrollViewContent()
    }
    
    private func setupScrollViewContent() {
        scrollView.addSubview(scrollViewContent)
        scrollViewContent.addSubview(imageView)
        
        let views = ["scrollViewContent" : scrollViewContent]
        scrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[scrollViewContent]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
        scrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[scrollViewContent]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
        NSLayoutConstraint.activate([scrollViewContent.widthAnchor.constraint(equalTo: view.widthAnchor),
                                     scrollViewContent.heightAnchor.constraint(equalTo: view.heightAnchor)])
        
        let imageH = NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: view.frame.height)
        let imageW = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: view.frame.width)
        view.addConstraints([imageH,
                             imageW,
                             NSLayoutConstraint(item: imageView, attribute: .centerX, relatedBy: .equal, toItem: scrollViewContent, attribute: .centerX, multiplier: 1, constant: 0),
                             NSLayoutConstraint(item: imageView, attribute: .centerY, relatedBy: .equal, toItem: scrollViewContent, attribute: .centerY, multiplier: 1, constant: 0)])
        
        let frameProducer = view.reactive.producer(for: \UIView.frame)
        let boundsProducer = view.reactive.producer(for: \UIView.bounds)
        
        SignalProducer.combineLatest([frameProducer, boundsProducer])
            .take(during: reactive.lifetime)
            .observe(on: UIScheduler())
            .startWithValues { [unowned self, imageH, imageW] _ in
                imageH.constant = self.view.frame.height
                imageW.constant = self.view.frame.width
                
                self.view.layoutIfNeeded()
                self.scrollViewContentInset = self.scrollView.contentInset
        }
    }
    
    func moveScrollViewCenter(delta: CGFloat) {
        if abs(delta) > 1000 { return }
        
        scrollTopConstraint?.constant = delta
        scrollBottomConstraint?.constant = delta
        view.layoutIfNeeded()
    }
    
    @objc func doubleTap(sender: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
        else {
            scrollView.setZoomScale(scrollView.maximumZoomScale, animated: true)
        }
    }
    
}

extension ImagePreviewViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        scrollViewContent
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard self.scrollView == scrollView else { return }
        
        if scrollView.zoomScale < 1 {
            var top = CGFloat(0)
            var left = CGFloat(0)
            if scrollView.contentSize.width < scrollView.bounds.width {
                left = (scrollView.bounds.width - scrollView.contentSize.width) * 0.5
            }
            else {
                top = (scrollView.bounds.height - scrollView.contentSize.height) * 0.5
            }
            
            scrollView.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
            view.layoutIfNeeded()
        }
        else if scrollViewContentInset != scrollView.contentInset {
            scrollView.contentInset = scrollViewContentInset
            view.layoutIfNeeded()
        }
    }
    
}
