//
//  VideoPickerCell.swift
//  Gifer
//
//  Created by Peter Lee on 2017/9/6.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import AVFoundation

class VideoPickerCell: UICollectionViewCell {

    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var durationLable: UILabel!
    
    var video: Video? {
        didSet{
            contentImageView.image = video?.thumbnail
            guard let duration = video?.asset.duration else {
                durationLable.text = "00:00"
                return
            }
            durationLable.text = descriptionOfTime(CMTimeGetSeconds(duration))
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    private func descriptionOfTime(_ time: Double) -> String {
        var extraMinZero = ""
        var extraSecZero = ""
        
        if time > 3600 {
            let hour = Int(time / 3600)
            let min = Int((time - Double(hour) * 3600) / 60)
            let sec = Int(time - Double(hour) * 3600 - Double(min) * 60)
            
            if min < 10 {
                extraMinZero = "0"
            }
            if sec < 10 {
                extraSecZero = "0"
            }
            
            return "\(hour):\(extraMinZero)\(min):\(extraSecZero)\(sec)"
        } else {
            let min = Int(time / 60)
            let sec = Int(time - Double(min) * 60)
            
            if min < 10 {
                extraMinZero = "0"
            }
            if sec < 10 {
                extraSecZero = "0"
            }
            
            return "\(extraMinZero)\(min):\(extraSecZero)\(sec)"
            
        }
    }
    
}
