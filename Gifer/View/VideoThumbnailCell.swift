//
//  VideoThumbnailCell.swift
//  Gifer
//
//  Created by Peter Lee on 2017/9/4.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit

class VideoThumbnailCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    var thumbnail: VideoThumbnail? {
        didSet {
            imageView.image = thumbnail?.thumbnail
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
