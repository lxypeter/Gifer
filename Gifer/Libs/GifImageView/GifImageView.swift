//
//  GifImageView.swift
//  Gifer
//
//  Created by Peter Lee on 2017/5/26.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit

class GifImageView: UIImageView {
    
    // 是否自动播放
    public var autoPlayAnimatedImage = true
    // `Animator` 对象 将帧和指定图片存储内存中
    private var animator: GifAnimator?
    private var loadingAnimator: GifAnimator? {
        didSet {
            oldValue?.removeObserver(self, forKeyPath: "isFinishLoading")
        }
    }
    // displayLink 为懒加载 避免还没有加载好的时候使用了 造成异常
    private var displayLinkInitialized: Bool = false
    private lazy var displayLink: CADisplayLink = {
        self.displayLinkInitialized = true
        let displayLink = CADisplayLink(target: TargetProxy(target: self), selector: #selector(TargetProxy.onScreenUpdate))
        displayLink.add(to: RunLoop.main, forMode: self.runLoopMode)
        displayLink.isPaused = true
        return displayLink
    }()
    private var tempContentMode: UIViewContentMode = .scaleToFill
    
    public var speedTimes: Double = 1 {
        didSet {
            if self.animator != nil {
                self.animator?.speedTimes = self.speedTimes
            }
        }
    }
    public var runLoopMode: RunLoopMode = .commonModes {
        willSet {
            if runLoopMode == newValue {
                return
            } else {
                stopAnimating()
                displayLink.remove(from: RunLoop.main, forMode: runLoopMode)
                displayLink.add(to: RunLoop.main, forMode: newValue)
                startAnimating()
            }
        }
    }
    public var gifData: NSData? {
        didSet {
            animator = nil
            
            guard let gifData = gifData else {
                return
            }
            
            let newAnimator = GifAnimator(data: gifData)
            newAnimator.speedTimes = speedTimes
            
            if gifPlaceholder != nil && !newAnimator.isFinishLoading {
                newAnimator.addObserver(self, forKeyPath: "isFinishLoading", options: [.new], context: nil)
                let placeholderAnimator = GifAnimator(data: gifPlaceholder!)
                placeholderAnimator.speedTimes = 1
                animator = placeholderAnimator
                tempContentMode = contentMode
                contentMode = placeholderContentMode
                loadingAnimator = newAnimator
            } else {
                animator = newAnimator
            }
            
            didMove()
            setNeedsDisplay()
            layer.setNeedsDisplay()
        }
    }
    public var gifPlaceholder: NSData?
    public var placeholderContentMode: UIViewContentMode = .center

    func updateFrame() {
        if animator?.updateCurrentFrame(duration: displayLink.duration) == true {
            // 此方法会触发 displayLayer
            layer.setNeedsDisplay()
        }
    }
    
    func didMove() {
        if autoPlayAnimatedImage && animator != nil {
            if let _ = superview, let _ = window {
                self.startAnimating()
            } else {
                self.stopAnimating()
            }
        }
    }
    
    override func display(_ layer: CALayer) {
        if let currentImage = animator?.currentImage {
            layer.contents = currentImage.cgImage
        } else {
            layer.contents = self.image?.cgImage
        }
    }
    
    override public func didMoveToWindow() {
        super.didMoveToWindow()
        self.didMove()
    }
    
    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.didMove()
    }
    
    override var isAnimating: Bool {
        get {
            if displayLinkInitialized {
                return !displayLink.isPaused
            } else {
                return super.isAnimating
            }
        }
    }
    
    // Starts the animation.
    override public func startAnimating() {
        if self.isAnimating {
            return
        } else {
            displayLink.isPaused = false
        }
    }
    
    /// Stops the animation.
    override public func stopAnimating() {
        super.stopAnimating()
        if displayLinkInitialized {
            displayLink.isPaused = true
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object as? GifAnimator === loadingAnimator {
            let isFinishLoading = change?[NSKeyValueChangeKey.newKey] as! Bool
            if isFinishLoading {
                animator = loadingAnimator
                contentMode = tempContentMode
                loadingAnimator = nil
            }
        }
    }
    
    deinit {
        if displayLinkInitialized {
            displayLink.invalidate()
        }
        loadingAnimator = nil
    }
    
}

// 防止循环引用
class TargetProxy {
    private weak var target: GifImageView?
    
    init(target: GifImageView) {
        self.target = target
    }
    
    @objc func onScreenUpdate() {
        target?.updateFrame()
    }
}
