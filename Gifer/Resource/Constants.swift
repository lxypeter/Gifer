//
//  Constants.swift
//  Gifer
//
//  Created by Peter Lee on 2017/6/5.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit

let kScreenWidth: CGFloat = UIScreen.main.bounds.size.width
let kScreenHeight: CGFloat = UIScreen.main.bounds.size.height
let kStatusBarHeight: CGFloat = UIApplication.shared.statusBarFrame.height
let kNavigationBarHeight: CGFloat = 44.0

let kNotiKeyGalleryUpdate = "kNotiKeyGalleryUpdate"
let kNotiKeyGifGenerated = "kNotiKeyGifGenerated"

let kVideoDir = "Video/"
let kShareDir = "Share/"
let kVideoDirPath = NSTemporaryDirectory().appending(kVideoDir)
let kShareDirPath = NSTemporaryDirectory().appending(kShareDir)

let kUserDefalutShareCacheKey = "kUserDefalutShareCacheKey"
