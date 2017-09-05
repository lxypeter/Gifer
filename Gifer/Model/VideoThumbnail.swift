//
//  VideoThumbnail.swift
//  Gifer
//
//  Created by Peter Lee on 2017/9/4.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import AVFoundation

struct VideoThumbnail {
    let thumbnail: UIImage
    let requestedTime: CMTime
    let actualTime: CMTime
}
