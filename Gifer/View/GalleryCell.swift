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
            self.contentImageView.image = photo?.thumbnail
        }
    }
    var isEditing: Bool = false {
        didSet{
            selectImageView.isHidden = !isEditing
        }
    }
    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var selectImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                selectImageView.image = #imageLiteral(resourceName: "select")
            } else {
                selectImageView.image = #imageLiteral(resourceName: "unselcet")
            }
        }
    }
}
