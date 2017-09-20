//
//  VideoUtil.swift
//  Gifer
//
//  Created by Peter Lee on 2017/9/14.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import AVFoundation
import ImageIO
import MobileCoreServices

struct VideoUtil {
    
    static func video(with gifData: NSData, completeHandler: @escaping (Bool, URL?) -> ()) {
        let options: NSDictionary = [
            kCGImageSourceShouldCache as String: NSNumber(value: false),
            kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF
        ]
        guard let imageSource = CGImageSourceCreateWithData(gifData, options) else {
            completeHandler(false, nil)
            return
        }
        
        
        DispatchQueue.global().async {
            let frameCount = CGImageSourceGetCount(imageSource)
            
            var animatedFrames: [GifFrame] = []
            animatedFrames.reserveCapacity(frameCount)
            
            for i in 0 ..< frameCount {
                guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, i , nil) else {
                    DispatchQueue.main.async {
                        completeHandler(false, nil)
                    }
                    return
                }
                // 获取到 gif每帧时间间隔
                if let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, i , nil),
                    let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
                let delayTime = (gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber) {
                    let unclampedDelayTime = (gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber)
                    let frameDuration = unclampedDelayTime != nil && unclampedDelayTime!.floatValue > 0 ? unclampedDelayTime! : delayTime
                    
                    let image = UIImage(cgImage: imageRef , scale: UIScreen.main.scale, orientation: .up)
                    animatedFrames.append(GifFrame(image: image, duration: Double(frameDuration)))
                }
            }
            let firstImage = animatedFrames[0].image!
            let size = CGSize(width: firstImage.size.width * firstImage.scale, height: firstImage.size.height * firstImage.scale)
            
            VideoUtil.video(with: animatedFrames, size: size, completeHandler: { (result, url) in
                DispatchQueue.main.async {
                    completeHandler(result, url)
                }
            })
        }
    }
    
    static func video(with images: [GifFrame], size: CGSize, completeHandler: @escaping (Bool, URL?) -> ()) {
        let videoDirPath = kVideoDirPath
        let isDirExist = createFolderIfNotExist(path: videoDirPath)
        if !isDirExist {
            completeHandler(false, nil)
            return
        }
        let outputPath = videoDirPath.appending("\(timeStamp()).mp4")
        let url = URL(fileURLWithPath: outputPath)
        
        guard let assetWriter = try? AVAssetWriter(url: url, fileType: AVFileType.mov) else {
            completeHandler(false, nil)
            return
        }
        
        // 视频
        let outputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
            AVVideoWidthKey: size.width,
            AVVideoHeightKey: size.height,
        ]
        let writerInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        writerInput.expectsMediaDataInRealTime = true
        
        if assetWriter.canAdd(writerInput) {
            assetWriter.add(writerInput)
        } else {
            completeHandler(false, nil)
            return
        }
        
        let bufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelFormatOpenGLESCompatibility as String: kCFBooleanTrue
        ]
        let assetWriterInputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: bufferAttributes)
        
        if assetWriter.startWriting() {
            assetWriter.startSession(atSourceTime: kCMTimeZero)
        }
        
        let captureQueue = DispatchQueue(label: "com.lxy.videoCapture")
            
        writerInput.requestMediaDataWhenReady(on: captureQueue) {
            var presentationTime: Double = 0
            var indexGoingToAdd = 0
            for (index, frame) in images.enumerated() {
                while index == indexGoingToAdd {
                    if writerInput.isReadyForMoreMediaData {
                        if let cgImage = frame.image?.cgImage, let buffer = VideoUtil.pixelBuffer(from: cgImage, size: size) {
                            presentationTime += frame.duration
                            assetWriterInputPixelBufferAdaptor.append(buffer, withPresentationTime: CMTime(seconds: presentationTime, preferredTimescale: 600))
                        }
                        indexGoingToAdd += 1
                    }
                }
            }
                
            writerInput.markAsFinished()
            assetWriter.finishWriting {
                DispatchQueue.main.async {
                    completeHandler(true, url)
                }
            }
        }
    }
    
    static func pixelBuffer(from cgImage: CGImage, size: CGSize) -> CVPixelBuffer? {
        let options: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        var pxbuffer: CVPixelBuffer?
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, options as CFDictionary?, &pxbuffer)
        assert(status == kCVReturnSuccess && pxbuffer != nil, "newPixelBuffer failed")
        
        CVPixelBufferLockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pxdata = CVPixelBufferGetBaseAddress(pxbuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pxdata, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pxbuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        assert(context != nil, "context is nil")
        
        context!.concatenate(CGAffineTransform.identity)
        context!.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        CVPixelBufferUnlockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
        return pxbuffer
    }

}
