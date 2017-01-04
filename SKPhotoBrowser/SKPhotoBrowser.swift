//
//  SKPhotoBrowser.swift
//  SKViewExample
//
//  Created by suzuki_keishi on 2015/10/01.
//  Copyright © 2015 suzuki_keishi. All rights reserved.
//

import UIKit

public let SKPHOTO_LOADING_DID_END_NOTIFICATION = "photoLoadingDidEndNotification"

// MARK: - SKPhotoBrowser
open class SKPhotoBrowser: UIViewController {
    
    let pageIndexTagOffset: Int = 1000
    
    fileprivate var closeButton: SKCloseButton!
    fileprivate var deleteButton: SKDeleteButton!
    
    // actions
    fileprivate var activityViewController: UIActivityViewController!
    open var activityItemProvider: UIActivityItemProvider? = nil
    fileprivate var panGesture: UIPanGestureRecognizer!

    // tool for controls
    fileprivate var applicationWindow: UIWindow!
    fileprivate lazy var pagingScrollView: SKPagingScrollView = SKPagingScrollView(frame: self.view.frame, browser: self)
    var backgroundView: UIView!
    
    var initialPageIndex: Int = 0
    var currentPageIndex: Int = 0
    
    // for status check property
    fileprivate var isViewActive: Bool = false
    fileprivate var isPerformingLayout: Bool = false
    
    // pangesture property
    fileprivate var firstX: CGFloat = 0.0
    fileprivate var firstY: CGFloat = 0.0
    
    // delegate
    fileprivate let animator = SKAnimator()
    open weak var delegate: SKPhotoBrowserDelegate?
    
    // photos
    var photos: [SKPhotoProtocol] = [SKPhotoProtocol]()
    var numberOfPhotos: Int {
        return photos.count
    }
    
    // MARK - Initializer
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle!) {
        super.init(nibName: nil, bundle: nil)
        setup()
    }
    
    public convenience init(photos: [SKPhotoProtocol]) {
        self.init(nibName: nil, bundle: nil)
        let pictures = photos.flatMap { $0 }
        for photo in pictures {
            photo.checkCache()
            self.photos.append(photo)
        }
    }
    
    public convenience init(originImage: UIImage, photos: [SKPhotoProtocol], animatedFromView: UIView) {
        self.init(nibName: nil, bundle: nil)
        animator.senderOriginImage = originImage
        animator.senderViewForAnimation = animatedFromView
        
        let pictures = photos.flatMap { $0 }
        for photo in pictures {
            photo.checkCache()
            self.photos.append(photo)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setup() {
        if let window = UIApplication.shared.delegate?.window {
            applicationWindow = window
        } else if let window = UIApplication.shared.keyWindow {
            applicationWindow = window
        } else {
            return
        }
        
        modalPresentationCapturesStatusBarAppearance = true
        modalPresentationStyle = .custom
        modalTransitionStyle = .crossDissolve
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleSKPhotoLoadingDidEndNotification(_:)), name: NSNotification.Name(rawValue: SKPHOTO_LOADING_DID_END_NOTIFICATION), object: nil)
    }
    
    // MARK: - override
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        configureAppearance()
        configureCloseButton()
        configureDeleteButton()
        
        animator.willPresent(self)
    }

    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        reloadData()
        
        var i = 0
        for photo: SKPhotoProtocol in photos {
            photo.index = i
            i = i + 1
        }
    }
    
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        isPerformingLayout = true
        
        closeButton.updateFrame()
        deleteButton.updateFrame()
        pagingScrollView.updateFrame(view.bounds, currentPageIndex: currentPageIndex)
        
        // where did start
        delegate?.didShowPhotoAtIndex?(currentPageIndex)
        
        isPerformingLayout = false
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        isViewActive = true
    }
    
    open override var prefersStatusBarHidden: Bool {
        get {
            return SKPhotoBrowserOptions.displayStatusbar == false
        }
    }
    
    // MARK: - Notification
    open func handleSKPhotoLoadingDidEndNotification(_ notification: Notification) {
        guard let photo = notification.object as? SKPhotoProtocol else {
            return
        }
        
        DispatchQueue.main.async(execute: {
            guard let page = self.pagingScrollView.pageDisplayingAtPhoto(photo), let photo = page.photo else {
                return
            }
            
            if photo.underlyingImage != nil {
                page.displayImage(complete: true)
                self.loadAdjacentPhotosIfNecessary(photo)
            } else {
                page.displayImageFailure()
            }
        })
    }
    
    open func loadAdjacentPhotosIfNecessary(_ photo: SKPhotoProtocol) {
        pagingScrollView.loadAdjacentPhotosIfNecessary(photo, currentPageIndex: currentPageIndex)
    }
    
    // MARK: - initialize / setup
    open func reloadData() {
        performLayout()
        view.setNeedsLayout()
    }
    
    open func performLayout() {
        isPerformingLayout = true
        
        // reset local cache
        pagingScrollView.reload()
        
        // reframe
        pagingScrollView.updateContentOffset(currentPageIndex)
        pagingScrollView.tilePages()
        
        delegate?.didShowPhotoAtIndex?(currentPageIndex)
        
        isPerformingLayout = false
    }
    
    open func prepareForClosePhotoBrowser() {
        applicationWindow.removeGestureRecognizer(panGesture)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    open func dismissPhotoBrowser(animated: Bool, completion: ((Void) -> Void)? = nil) {
        prepareForClosePhotoBrowser()

        if !animated {
            modalTransitionStyle = .crossDissolve
        }
        
        dismiss(animated: !animated) {
            completion?()
            self.delegate?.didDismissAtPageIndex?(self.currentPageIndex)
        }
    }

    open func determineAndClose() {
        delegate?.willDismissAtPageIndex?(currentPageIndex)
        animator.willDismiss(self)
    }
}

// MARK: - Public Function For Customizing Buttons

public extension SKPhotoBrowser {
  func updateCloseButton(_ image: UIImage, size: CGSize? = nil) {
        if closeButton == nil {
            configureCloseButton()
        }
        closeButton.setImage(image, for: UIControlState())
    
        if let size = size {
            closeButton.setFrameSize(size)
        }
    }
  
  func updateDeleteButton(_ image: UIImage, size: CGSize? = nil) {
        if deleteButton == nil {
            configureDeleteButton()
        }
        deleteButton.setImage(image, for: UIControlState())
    
        if let size = size {
            deleteButton.setFrameSize(size)
        } else {
            deleteButton.setFrameSize(image.size)
        }
    }
}

// MARK: - Public Function For Browser Control

public extension SKPhotoBrowser {
    func initializePageIndex(_ index: Int) {
        var i = index
        if index >= numberOfPhotos {
            i = numberOfPhotos - 1
        }
        
        initialPageIndex = i
        currentPageIndex = i
        
        if isViewLoaded {
            jumpToPageAtIndex(index)
            if !isViewActive {
                pagingScrollView.tilePages()
            }
        }
    }
    
    func jumpToPageAtIndex(_ index: Int) {
        if index < numberOfPhotos {
            let pageFrame = frameForPageAtIndex(index)
            pagingScrollView.animate(pageFrame)
        }
    }
    
    func photoAtIndex(_ index: Int) -> SKPhotoProtocol {
        return photos[index]
    }
    
    func gotoPreviousPage() {
        jumpToPageAtIndex(currentPageIndex - 1)
    }
    
    func gotoNextPage() {
        jumpToPageAtIndex(currentPageIndex + 1)
    }
    
    func getCurrentPageIndex() -> Int {
        return currentPageIndex
    }
}


// MARK: - Internal Function

internal extension SKPhotoBrowser {
    func showButtons() {
        if SKPhotoBrowserOptions.displayCloseButton {
            closeButton.alpha = 1
            closeButton.frame = closeButton.showFrame
        }
        if SKPhotoBrowserOptions.displayDeleteButton {
            deleteButton.alpha = 1
            deleteButton.frame = deleteButton.showFrame
        }
    }
    
    func pageDisplayedAtIndex(_ index: Int) -> SKZoomingScrollView? {
        return pagingScrollView.pageDisplayedAtIndex(index)
    }
    
    func getImageFromView(_ sender: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(sender.frame.size, true, 0.0)
        sender.layer.render(in: UIGraphicsGetCurrentContext()!)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
}

// MARK: - Internal Function For Frame Calc

internal extension SKPhotoBrowser {
    func frameForPageAtIndex(_ index: Int) -> CGRect {
        let bounds = pagingScrollView.bounds
        var pageFrame = bounds
        pageFrame.size.width -= (2 * 10)
        pageFrame.origin.x = (bounds.size.width * CGFloat(index)) + 10
        return pageFrame
    }
}

// MARK: - Internal Function For Button Pressed, UIGesture Control

internal extension SKPhotoBrowser {
    func panGestureRecognized(_ sender: UIPanGestureRecognizer) {
        guard let zoomingScrollView: SKZoomingScrollView = pagingScrollView.pageDisplayedAtIndex(currentPageIndex) else {
            return
        }
        
        backgroundView.isHidden = true
        
        let viewHeight: CGFloat = zoomingScrollView.frame.size.height
        let viewHalfHeight: CGFloat = viewHeight/2
        var translatedPoint: CGPoint = sender.translation(in: self.view)
        
        // gesture began
        if sender.state == .began {
            firstX = zoomingScrollView.center.x
            firstY = zoomingScrollView.center.y
            
            setNeedsStatusBarAppearanceUpdate()
        }
        
        translatedPoint = CGPoint(x: firstX, y: firstY + translatedPoint.y)
        zoomingScrollView.center = translatedPoint
        
        let minOffset: CGFloat = viewHalfHeight / 4
        let offset: CGFloat = 1 - (zoomingScrollView.center.y > viewHalfHeight
            ? zoomingScrollView.center.y - viewHalfHeight
            : -(zoomingScrollView.center.y - viewHalfHeight)) / viewHalfHeight
        
        view.backgroundColor = UIColor.black.withAlphaComponent(max(0.7, offset))
        
        // gesture end
        if sender.state == .ended {
            
            if zoomingScrollView.center.y > viewHalfHeight + minOffset
                || zoomingScrollView.center.y < viewHalfHeight - minOffset {
                
                backgroundView.backgroundColor = view.backgroundColor
                determineAndClose()
                
            } else {
                // Continue Showing View
                setNeedsStatusBarAppearanceUpdate()
                
                let velocityY: CGFloat = CGFloat(0.35) * sender.velocity(in: self.view).y
                let finalX: CGFloat = firstX
                let finalY: CGFloat = viewHalfHeight
                
                let animationDuration: Double = Double(abs(velocityY) * 0.0002 + 0.2)
                
                UIView.beginAnimations(nil, context: nil)
                UIView.setAnimationDuration(animationDuration)
                UIView.setAnimationCurve(UIViewAnimationCurve.easeIn)
                view.backgroundColor = UIColor.black
                zoomingScrollView.center = CGPoint(x: finalX, y: finalY)
                UIView.commitAnimations()
            }
        }
    }
    
    func deleteButtonPressed(_ sender: UIButton) {
        delegate?.removePhoto?(self, index: currentPageIndex) { [weak self] in
            self?.deleteImage()
        }
    }
    
    func closeButtonPressed(_ sender: UIButton) {
        determineAndClose()
    }
}

// MARK: - Private Function 
private extension SKPhotoBrowser {
    func configureAppearance() {
        view.backgroundColor = UIColor.black
        view.clipsToBounds = true
        view.isOpaque = false
        
        backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: SKMesurement.screenWidth, height: SKMesurement.screenHeight))
        backgroundView.backgroundColor = UIColor.black
        backgroundView.alpha = 0.0
        applicationWindow.addSubview(backgroundView)
        
        pagingScrollView.delegate = self
        view.addSubview(pagingScrollView)
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(SKPhotoBrowser.panGestureRecognized(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        if !SKPhotoBrowserOptions.disableVerticalSwipe {
            view.addGestureRecognizer(panGesture)
        }
    }
    
    func configureCloseButton() {
        closeButton = SKCloseButton(frame: .zero)
        closeButton.addTarget(self, action: #selector(closeButtonPressed(_:)), for: .touchUpInside)
        closeButton.isHidden = !SKPhotoBrowserOptions.displayCloseButton
        closeButton.frame = closeButton.showFrame
        closeButton.tintColor = .white
        closeButton.imageView?.contentMode = .center
        view.addSubview(closeButton)
    }
    
    func configureDeleteButton() {
        deleteButton = SKDeleteButton(frame: .zero)
        deleteButton.addTarget(self, action: #selector(deleteButtonPressed(_:)), for: .touchUpInside)
        deleteButton.isHidden = !SKPhotoBrowserOptions.displayDeleteButton
        deleteButton.frame = deleteButton.showFrame
        deleteButton.tintColor = .white
        deleteButton.imageView?.contentMode = .center
        view.addSubview(deleteButton)
    }
    
    func deleteImage() {
        defer {
            reloadData()
        }
        
        if photos.count > 1 {
            pagingScrollView.deleteImage()
            
            photos.remove(at: currentPageIndex)
            if currentPageIndex != 0 {
                gotoPreviousPage()
            }
            
        } else if photos.count == 1 {
            dismissPhotoBrowser(animated: true)
        }
    }
}

// MARK: -  UIScrollView Delegate

extension SKPhotoBrowser: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard isViewActive else {
            return
        }
        guard !isPerformingLayout else {
            return
        }
        
        // tile page
        pagingScrollView.tilePages()
        
        // Calculate current page
        let previousCurrentPage = currentPageIndex
        let visibleBounds = pagingScrollView.bounds
        currentPageIndex = min(max(Int(floor(visibleBounds.midX / visibleBounds.width)), 0), numberOfPhotos - 1)
        
        if currentPageIndex != previousCurrentPage {
            delegate?.didShowPhotoAtIndex?(currentPageIndex)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {        
        let currentIndex = pagingScrollView.contentOffset.x / pagingScrollView.frame.size.width
        delegate?.didScrollToIndex?(Int(currentIndex))
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    }
}
