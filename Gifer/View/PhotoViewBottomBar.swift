//
//  PhotoViewBottomBar.swift
//  Gifer
//
//  Created by Peter Lee on 2017/6/2.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import SnapKit

class PhotoViewBottomBar: UIView {

    lazy var resetButton: UIButton = {
        let resetButton = UIButton(frame: CGRect.zero)
        resetButton.setImage(#imageLiteral(resourceName: "undo"), for: .normal)
        resetButton.addTarget(self, action: #selector(clickResetButton), for: .touchUpInside)
        return resetButton
    }()
    
    lazy var deleteButton: UIButton = {
        let deleteButton = UIButton(frame: CGRect.zero)
        deleteButton.setImage(#imageLiteral(resourceName: "trash"), for: .normal)
        return deleteButton
    }()
    
    lazy var slider: UISlider = {
        let slider = UISlider(frame: CGRect.zero)
        slider.minimumValue = 0.5
        slider.maximumValue = 3
        slider.value = 1
        slider.addTarget(self, action: #selector(sliderChange(_:)), for: .valueChanged)
        return slider
    }()
    
    var sliderValueChange: ((Float) -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureSubviews() {
        self.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        let seperateLine = UIView(frame: CGRect.zero)
        seperateLine.backgroundColor = #colorLiteral(red: 0.862745098, green: 0.862745098, blue: 0.862745098, alpha: 1)
        self.addSubview(seperateLine)
        seperateLine.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.right.equalTo(0)
            make.left.equalTo(0)
            make.height.equalTo(0.5)
        }
        
        self.addSubview(self.deleteButton)
        self.deleteButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.snp.centerY)
            make.height.equalTo(24)
            make.width.equalTo(24)
            make.left.equalTo(15)
        }
        
        self.addSubview(self.resetButton)
        self.resetButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.snp.centerY)
            make.height.equalTo(24)
            make.width.equalTo(24)
            make.right.equalTo(-15)
        }
        
        self.addSubview(self.slider)
        self.slider.snp.makeConstraints { (make) in
            make.left.equalTo(self.deleteButton.snp.right).offset(15)
            make.right.equalTo(self.resetButton.snp.left).offset(-15)
            make.centerY.equalTo(self.snp.centerY)
        }
        
    }
    
    func clickResetButton() {
        self.slider.setValue(1.0, animated: true)
    }

    func sliderChange(_ slider: UISlider) {
        if self.sliderValueChange != nil {
            self.sliderValueChange!(slider.value)
        }
    }
}
