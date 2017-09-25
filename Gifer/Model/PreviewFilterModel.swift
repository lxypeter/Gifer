//
//  PreviewFilterModel.swift
//  Gifer
//
//  Created by Peter Lee on 2017/9/25.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit

class PreviewFilterModel: NSObject {
    let title: String
    @objc dynamic var previewImage: UIImage?
    let originImage: UIImage
    let filter: ImageFilter?
    
    init(title: String, originImage: UIImage, filter: ImageFilter?, filterContext: CIContext) {
        self.title = title
        self.originImage = originImage
        self.filter = filter
        super.init()
        if let filter = filter {
            DispatchQueue.global().async {[unowned self] in
                self.previewImage = filter.createImage(with: originImage, context: filterContext)
            }
        } else {
            self.previewImage = originImage
        }
    }
}
