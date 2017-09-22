//
//  PhotoPickerCell.swift
//  Gifer
//
//  Created by Peter Lee on 2017/6/7.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit

class PhotoPickerCell: UICollectionViewCell {

    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var selectedView: UIView!
    @IBOutlet weak var selectedRankLabel: UILabel!
    var isChoose: Bool = false{
        didSet {
            if isChoose {
                selectedView.isHidden = false
            } else {
                selectedView.isHidden = true
            }
        }
    }
    
    var photo: Photo? {
        didSet{
            contentImageView.image = photo?.thumbnail
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectedView.backgroundColor = UIColor(red: 0.25, green: 0.8, blue: 0.8, alpha: 0.5)
        selectedView.isHidden = true
    }
    
}
