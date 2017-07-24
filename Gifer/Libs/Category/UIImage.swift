//
//  UIImage.swift
//  Gifer
//
//  Created by Peter Lee on 2017/6/12.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit

extension UIImage {
    
    func imageKeepRatioScalingWith(targetSize: CGSize) -> UIImage? {
        let imageSize = self.size
        var scaleFactor: CGFloat = 0.0
        var scaledWidth = targetSize.width
        var scaledHeight = targetSize.height
        
        if imageSize.equalTo(targetSize) { return self }
        
        let widthFactor = targetSize.width / imageSize.width
        let heightFactor = targetSize.height / imageSize.height
        
        if widthFactor > heightFactor {
            scaleFactor = heightFactor
        } else {
            scaleFactor = widthFactor
        }
        
        scaledWidth = imageSize.width * scaleFactor;
        scaledHeight = imageSize.height * scaleFactor;
        
        UIGraphicsBeginImageContext(CGSize(width: scaledWidth, height: scaledHeight))
        var thumbnailRect = CGRect.zero
        thumbnailRect.size.width = scaledWidth;
        thumbnailRect.size.height = scaledHeight;
        
        self.draw(in: thumbnailRect)
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext();
        
        return resultImage
    }
    
    func imageScalingWith(targetSize: CGSize) -> UIImage? {
        let imageSize = self.size
        var scaleFactor: CGFloat = 0.0
        var scaledWidth = targetSize.width
        var scaledHeight = targetSize.height
        var thumbnailPoint = CGPoint.zero
        
        if imageSize.equalTo(targetSize) { return self }
        
        let widthFactor = targetSize.width / imageSize.width
        let heightFactor = targetSize.height / imageSize.height
        
        if widthFactor > heightFactor {
            scaleFactor = widthFactor
            thumbnailPoint.y = (targetSize.height - scaledHeight) * 0.5;
        } else {
            scaleFactor = heightFactor
            thumbnailPoint.x = (targetSize.width - scaledWidth) * 0.5;
        }
        
        scaledWidth = imageSize.width * scaleFactor;
        scaledHeight = imageSize.height * scaleFactor;
        
        UIGraphicsBeginImageContext(CGSize(width: scaledWidth, height: scaledHeight))
        var thumbnailRect = CGRect.zero
        thumbnailRect.size.width = scaledWidth;
        thumbnailRect.size.height = scaledHeight;
        thumbnailRect.origin = thumbnailPoint
        
        self.draw(in: thumbnailRect)
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext();
        
        return resultImage
    }
    
    func fixRotation() -> UIImage {
        if self.imageOrientation == .up { return self }
        guard let cgImage = self.cgImage else {
            return self
        }
        var transform: CGAffineTransform = .identity
        switch self.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: self.size.height)
            transform = transform.rotated(by: -.pi / 2)
        default: break
        }
        
        switch self.imageOrientation {
        case .downMirrored, .upMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: self.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default: break
        }
        
        let ctx = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: cgImage.colorSpace!, bitmapInfo: cgImage.bitmapInfo.rawValue)
        ctx?.concatenate(transform)
        switch self.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx?.draw(cgImage, in: CGRect(x: 0, y: 0, width: self.size.height, height: self.size.width))
        default:
            ctx?.draw(cgImage, in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        }
        guard let newCgImage = ctx?.makeImage() else {
            return self
        }
        ctx?.flush()
        return UIImage(cgImage: newCgImage)
    }
    
    func clipImage(in rect: CGRect) -> UIImage? {
        let newImageRef = self.cgImage!.cropping(to: rect)
        return UIImage(cgImage: newImageRef!)
    }
}
