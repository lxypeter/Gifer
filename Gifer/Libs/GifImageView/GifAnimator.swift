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

class GifAnimator {
    private let maxFrameCount: Int = 100    // 最大帧数
    private var imageSource: CGImageSource!  // imageSource 处理帧相关操作
    private var animatedFrames: [GifFrame] = []  //
    private var frameCount = 0  // 帧的数量
    private var currentFrameIndex = 0   // 当前帧下标
    private var currentPreloadIndex = 0 // 当前预缓存帧的下标
    private var timeSinceLastFrameChange: TimeInterval = 0.0  // 距离上一帧改变的时间
    private var loopCount = 0 // 循环次数
    private let maxTimeStep: TimeInterval = 1.0 // 最大间隔
    public var speedTimes: Double = 1 {
        didSet {
            if self.speedTimes > 3 {
                self.speedTimes = 3
            } else if self.speedTimes < 0.5 {
                self.speedTimes = 0.5
            }
        }
    }
    
    init(data: NSData) {
        self.createImageSource(data: data)
        self.prepareFrames()
    }
    
    /**
     根据data创建 CGImageSource
     
     - parameter data: gif data
     */
    func createImageSource(data: NSData){
        let options: NSDictionary = [
            kCGImageSourceShouldCache as String: NSNumber(value: true),
            kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF
        ]
        self.imageSource = CGImageSourceCreateWithData(data, options)
    }
    
    // 准备某帧 的 frame
    func prepareFrame(index: Int) -> GifFrame {
        // 获取对应帧的 CGImage
        guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, index , nil) else {
            return GifFrame(image: nil, duration: 0)
        }
        // 获取到 gif每帧时间间隔
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index , nil),
            let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
            let frameDuration = (gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber) else {
            return GifFrame(image: nil, duration: 0)
        }
        
        let image = UIImage(cgImage: imageRef , scale: UIScreen.main.scale, orientation: .up)
        return GifFrame(image: image, duration: Double(frameDuration) )
    }
    
    /**
     预备所有frames
     */
    func prepareFrames() {
        self.frameCount = CGImageSourceGetCount(imageSource)
        
        if let properties = CGImageSourceCopyProperties(imageSource, nil),
            let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
            let loopCount = gifInfo[kCGImagePropertyGIFLoopCount as String] as? Int {
            self.loopCount = loopCount
        }
        
        // 总共帧数
        let frameToProcess = min(frameCount, maxFrameCount)
        
        self.animatedFrames.reserveCapacity(frameToProcess)
        
        for i in 0..<frameToProcess {
            self.animatedFrames.append(prepareFrame(index: i))
        }
        
    }
    
    /**
     根据下标获取帧
     */
    func frameAtIndex(index: Int) -> UIImage? {
        return animatedFrames[index].image
    }
    
    var currentFrame: UIImage? {
        return frameAtIndex(index: self.currentFrameIndex)
    }
    
    func updateCurrentFrame(duration: CFTimeInterval) -> Bool {
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
