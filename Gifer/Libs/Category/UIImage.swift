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
}
