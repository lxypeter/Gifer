//
//  NoticeView.swift
//  Gifer
//
//  Created by Peter Lee on 2017/6/5.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import SnapKit

let kNoticeViewKey = "kNoticeViewKey"

class NoticeView: UIView {
    
    private lazy var label: UILabel = {
        let manager = NoticeViewManager.shared
        var label = UILabel(frame: CGRect.zero)
        label.textColor = manager.textColor
        label.font = manager.font
        return label
    }()
    var hasStatusBar = false
    var triggeredSwipeGesture = false
    
    convenience init(frame: CGRect, text: String, hasStatusBar: Bool) {
        self.init(frame: frame)
        self.hasStatusBar = hasStatusBar
        configureSubviews(with: text)
    }
    
    private func configureSubviews(with text: String) {
        let manager = NoticeViewManager.shared
        backgroundColor = manager.backgroundColor
        
        label.text = text
        addSubview(self.label)
        label.snp.makeConstraints { (make) in
            if hasStatusBar {
                make.top.equalTo(25)
            } else {
                make.top.equalTo(5)
            }
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.bottom.equalTo(-5)
        }
    }
}
