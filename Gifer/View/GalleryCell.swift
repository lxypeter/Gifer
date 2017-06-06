//
//  GalleryCell.swift
//  Gifer
//
//  Created by Peter Lee on 2017/5/23.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit

class GalleryCell: UICollectionViewCell {
    
    var photo: Photo? {
        didSet{
            self.contentImageView.image = self.photo?.thumbnail
        }
    }
    var isEditing: Bool = false {
        didSet{
            self.selectImageView.isHidden = !self.isEditing
        }
    }
    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var selectImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override var isSelected: Bool {
        didSet {
            if self.isSelected {
                self.selectImageView.image = #imageLiteral(resourceName: "select")
            } else {
                self.selectImageView.image = #imageLiteral(resourceName: "unselcet")
            }
        }
    }
}
