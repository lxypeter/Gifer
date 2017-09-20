//
//  FilterCell.swift
//  Gifer
//
//  Created by Peter Lee on 2017/9/19.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit

class FilterCell: UICollectionViewCell {

    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    var imageFilter: ImageFilter? {
        didSet {
            guard let imageFilter = imageFilter else {
                return
            }
            previewImageView.image = imageFilter.previewImage
            titleLabel.text = imageFilter.title
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
