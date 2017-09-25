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
            oldValue?.removeObserver(self, forKeyPath: "previewImage")
            guard let previewFilterModel = previewFilterModel else {
                return
            }
            previewImageView.image = previewFilterModel.previewImage
            titleLabel.text = previewFilterModel.title
            
            previewFilterModel.addObserver(self, forKeyPath: "previewImage", options: .new, context: nil)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        previewImageView.clipsToBounds = true
        // Initialization code
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let newImage = change?[NSKeyValueChangeKey.newKey] as? UIImage else {
            return
        }
        DispatchQueue.main.async {[unowned self] in
            self.previewImageView.image = newImage
        }
    }
    
    deinit {
        previewFilterModel?.removeObserver(self, forKeyPath: "previewImage")
    }
}
