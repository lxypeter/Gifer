//
//  Photo.swift
//  Gifer
//
//  Created by Peter Lee on 2017/5/24.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import Photos

class Photo: NSObject {
    var asset: PHAsset
    var thumbnail: UIImage?
    var fullImageData: NSData?
    
    init(asset: PHAsset) {
        self.asset = asset
    }
}
