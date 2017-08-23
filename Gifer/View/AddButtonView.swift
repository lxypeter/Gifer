//
//  AddButtonView.swift
//  Gifer
//
//  Created by Peter Lee on 2017/8/22.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import SnapKit

class AddButtonView: UIView {
    
    let backgroundView: UIView = UIView()
    let button: UIButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.masksToBounds = true
        
        self.addSubview(backgroundView)
        backgroundView.layer.cornerRadius = 31
        backgroundView.snp.makeConstraints({ (make) in
            make.top.equalTo(0)
            make.right.equalTo(0)
            make.left.equalTo(0)
            make.bottom.equalTo(0)
        })
        
        self.addSubview(button)
        button.snp.makeConstraints({ (make) in
            make.top.equalTo(0)
            make.right.equalTo(0)
            make.left.equalTo(0)
            make.bottom.equalTo(0)
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
