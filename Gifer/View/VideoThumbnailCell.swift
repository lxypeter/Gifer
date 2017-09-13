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
            oldValue?.removeObserver(self, forKeyPath: "thumbnail")
            imageView.image = nil
            guard let thumbnail = thumbnail else {
                return
            }
            thumbnail.addObserver(self, forKeyPath: "thumbnail", options: .new, context: nil)
            if thumbnail.thumbnail != nil && thumbnail.state == .loaded {
                imageView.image = thumbnail.thumbnail
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let newImage = change?[NSKeyValueChangeKey.newKey] as? UIImage else {
            return
        }
        DispatchQueue.main.async {[unowned self] in
            self.imageView.image = newImage
        }
    }
    
    deinit {
        thumbnail?.removeObserver(self, forKeyPath: "thumbnail")
    }

}
