//
//  ImageFilter.swift
//  Gifer
//
//  Created by Peter Lee on 2017/9/20.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit

struct ImageFilter {
    let nickname: String
    let name: String
    let preset: [String: Any]
    
    static func supportedFilters() -> [ImageFilter] {
        return [
            ImageFilter(nickname: "Sepia", name: "CISepiaTone", preset: [:]),
            ImageFilter(nickname: "Mono", name: "CIPhotoEffectMono", preset: [:]),
            ImageFilter(nickname: "Zoom Blur", name: "CIZoomBlur", preset: [:])
            
            
            
        ]
    }
}

struct PreviewFilterModel {
    let title: String
    let previewImage: UIImage
    let filter: ImageFilter?
}
