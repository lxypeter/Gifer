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
    
    // displayLink 为懒加载 避免还没有加载好的时候使用了 造成异常
    private var displayLinkInitialized: Bool = false
    
    private lazy var displayLink: CADisplayLink = {
        self.displayLinkInitialized = true
        let displayLink = CADisplayLink(target: TargetProxy(target: self), selector: #selector(TargetProxy.onScreenUpdate))
        displayLink.add(to: RunLoop.main, forMode: self.runLoopMode)
        displayLink.isPaused = true
        return displayLink
    }()
    
    public var runLoopMode: RunLoopMode = .commonModes {
        willSet {
            if runLoopMode == newValue {
                return
            } else {
                self.stopAnimating()
                displayLink.remove(from: RunLoop.main, forMode: runLoopMode)
                displayLink.add(to: RunLoop.main, forMode: newValue)
                self.startAnimating()
            }
        }
    }
    
    public var gifData: NSData?{
        didSet{
            if let gifData = gifData {
                animator = nil
                animator = GifAnimator(data: gifData)
                
                didMove()
                self.setNeedsDisplay()
                self.layer.setNeedsDisplay()
            }
        }
    }

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
        if let currentFrame = animator?.currentFrame {
            layer.contents = currentFrame.cgImage
        } else {
            layer.contents = image?.cgImage
        }
    }
    
    override public func didMoveToWindow() {
        super.didMoveToWindow()
        didMove()
    }
    
    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        didMove()
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
    
    deinit {
        if displayLinkInitialized {
            displayLink.invalidate()
        }
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
