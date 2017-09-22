//
//  VideoThumbnail.swift
//  Gifer
//
//  Created by Peter Lee on 2017/9/4.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import AVFoundation

enum ThumbnailState {
    case pendding
    case loading
    case loaded
    case fail
}

class VideoThumbnail: NSObject {
    let asset: AVAsset
    @objc dynamic var thumbnail: UIImage?
    let requestedTime: CMTime
    var actualTime: CMTime
    var state: ThumbnailState = .pendding
    
    init(asset: AVAsset, requestedTime: CMTime, actualTime: CMTime) {
        self.asset = asset
        self.requestedTime = requestedTime
        self.actualTime = actualTime
        super.init()
    }
    
    func generateThumbnail(completeHandler: ((ThumbnailState, UIImage?)->())?) {
        state = .loading
        
        DispatchQueue.global().async {[unowned self] in
            let imageGenerator = AVAssetImageGenerator(asset: self.asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = CGSize(width: VideoProgressView.height * 3, height: VideoProgressView.height * 3)
            let tolerance = CMTime(seconds: 0.01, preferredTimescale: 600)
            imageGenerator.requestedTimeToleranceAfter = tolerance
            imageGenerator.requestedTimeToleranceBefore = tolerance
        
            do {
                let thumbnailCgImage = try imageGenerator.copyCGImage(at: self.requestedTime, actualTime: &self.actualTime)
                let image = UIImage(cgImage: thumbnailCgImage)
                self.thumbnail = image
                self.state = .loaded
            } catch {
                self.state = .fail
            }
            
            guard let completeHandler = completeHandler else {
                return
            }
            DispatchQueue.main.async {[unowned self] in
                completeHandler(self.state, self.thumbnail)
            }
        }
    }
}
