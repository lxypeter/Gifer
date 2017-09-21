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
    var previewFilterModel: PreviewFilterModel? {
        didSet {
            guard let previewFilterModel = previewFilterModel else {
                return
            }
            previewImageView.image = previewFilterModel.previewImage
            titleLabel.text = previewFilterModel.title
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
