//
//  GifAnimator.swift
//  Gifer
//
//  Created by Peter Lee on 2017/5/25.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import ImageIO
import MobileCoreServices

struct GifFrame {
    var image: UIImage?
    var duration: TimeInterval = 0
    
    init(image: UIImage?, duration: TimeInterval) {
        self.image = image
        self.duration = duration
    }
}

class GifAnimator: NSObject {
    private let maxFrameCount: Int = 200 // 最大帧数
    private var imageSource: CGImageSource! // imageSource 处理帧相关操作
    private var animatedFrames: [GifFrame] = []
    private var frameCount = 0 // 帧的数量
    private var currentFrameIndex = 0 // 当前帧下标
    private var currentPreloadIndex = 0 // 当前预缓存帧的下标
    private var timeSinceLastFrameChange: TimeInterval = 0.0 // 距离上一帧改变的时间
    private var loopCount = 0 // 循环次数
    private let maxTimeStep: TimeInterval = 1.0 // 最大间隔
    private let isBigImage: Bool
    public var speedTimes: Double = 1 {
        didSet {
            if self.speedTimes > 3 {
                self.speedTimes = 3
            } else if self.speedTimes < 0.5 {
                self.speedTimes = 0.5
            }
        }
    }
    public var currentImage: UIImage? {
        if self.animatedFrames.count <= 0 { return nil }
        return self.animatedFrames[self.currentFrameIndex].image
    }
    dynamic public var isFinishLoading: Bool = false
    
    init(data: NSData) {
        isBigImage = data.length / 1024 / 1024 > 10
        super.init()
        createImageSource(data: data)
        prepareFrames()
    }
    
    /**
     根据data创建 CGImageSource
     
     - parameter data: gif data
     */
    private func createImageSource(data: NSData){
        let options: NSDictionary = [
            kCGImageSourceShouldCache as String: NSNumber(value: false),
            kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF
        ]
        imageSource = CGImageSourceCreateWithData(data, options)
    }
    
    /**
     预备所有frames
     */
    private func prepareFrames() {
        DispatchQueue.global().async {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.frameCount = CGImageSourceGetCount(strongSelf.imageSource)
            
            if let properties = CGImageSourceCopyProperties(strongSelf.imageSource, nil),
                let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
                let loopCount = gifInfo[kCGImagePropertyGIFLoopCount as String] as? Int {
                strongSelf.loopCount = loopCount
            }
            
            // 总共帧数
            let frameToProcess = min(strongSelf.frameCount, strongSelf.maxFrameCount)
            
            var animatedFrames: [GifFrame] = []
            animatedFrames.reserveCapacity(frameToProcess)
            
            for i in 0 ..< frameToProcess {
                animatedFrames.append(strongSelf.prepareFrame(index: i))
            }
            
            strongSelf.animatedFrames = animatedFrames
            strongSelf.isFinishLoading = true
        }
    }
    
    // 准备某帧 的 frame
    private func prepareFrame(index: Int) -> GifFrame {
        // 获取对应帧的 CGImage
        guard let imageRef = CGImageSourceCreateImageAtIndex(self.imageSource, index , nil) else {
            return GifFrame(image: nil, duration: 0)
        }
        // 获取到 gif每帧时间间隔
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index , nil),
            let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
            let delayTime = (gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber) else {
            return GifFrame(image: nil, duration: 0)
        }
        
        let unclampedDelayTime = (gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber)
        
        let frameDuration = unclampedDelayTime != nil && unclampedDelayTime!.floatValue > 0 ? unclampedDelayTime! : delayTime
        
        var image: UIImage? = UIImage(cgImage: imageRef , scale: UIScreen.main.scale, orientation: .up)
        if self.isBigImage {
            image = image?.imageKeepRatioScalingWith(targetSize: CGSize(width: 500, height: 500))
        }
        return GifFrame(image: image, duration: Double(frameDuration))
        
    }
    
    public func updateCurrentFrame(duration: CFTimeInterval) -> Bool {
        if self.animatedFrames.count <= 0 { return false }
        // 计算距离上一帧 改变的时间 每次进来都累加 直到frameDuration  <= timeSinceLastFrameChange 时候才继续走下去
        self.timeSinceLastFrameChange += min(maxTimeStep, duration)
        let frameDuration = animatedFrames[currentFrameIndex].duration / self.speedTimes
        if frameDuration > self.timeSinceLastFrameChange {
            return false
        }
        // 减掉 我们每帧间隔时间
        self.timeSinceLastFrameChange -= frameDuration
        currentFrameIndex += 1 // 一直累加
        // 这里取了余数
        currentFrameIndex = currentFrameIndex % animatedFrames.count
        return true
    }

}
