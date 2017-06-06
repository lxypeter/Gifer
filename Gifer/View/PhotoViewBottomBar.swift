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
        resetButton.setImage(#imageLiteral(resourceName: "undo_hl"), for: .highlighted)
        resetButton.addTarget(self, action: #selector(clickResetButton), for: .touchUpInside)
        return resetButton
    }()
    
    lazy var deleteButton: UIButton = {
        let deleteButton = UIButton(frame: CGRect.zero)
        deleteButton.setImage(#imageLiteral(resourceName: "trash"), for: .normal)
        deleteButton.setImage(#imageLiteral(resourceName: "trash_hl"), for: .highlighted)
        deleteButton.addTarget(self, action: #selector(clickDeleteButton), for: .touchUpInside)
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
    
    lazy var speedTimesLabel: UILabel = {
        let speedTimesLabel = UILabel(frame: CGRect.zero)
        speedTimesLabel.text = "速度: X\(String(format: "%.2f", self.slider.value))"
        speedTimesLabel.font = UIFont.systemFont(ofSize: 12)
        speedTimesLabel.textAlignment = .center
        speedTimesLabel.textColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return speedTimesLabel
    }()
    
    var sliderValueChangeHandler: ((Float) -> ())?
    var deleteButtonHandler: (() -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureSubviews() {
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
            make.bottom.equalTo(-5)
        }
        
        self.addSubview(self.speedTimesLabel)
        self.speedTimesLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.deleteButton.snp.right).offset(15)
            make.right.equalTo(self.resetButton.snp.left).offset(-15)
            make.centerX.equalTo(self.snp.centerX)
            make.bottom.equalTo(self.slider.snp.top).offset(0)
        }
        
    }
    
    func clickResetButton() {
        self.slider.setValue(1.0, animated: true)
        self.sliderChange(self.slider)
    }
    
    func clickDeleteButton() {
        if self.deleteButtonHandler != nil {
            self.deleteButtonHandler!()
        }
    }

    func sliderChange(_ slider: UISlider) {
        self.speedTimesLabel.text = "速度: X\(String(format: "%.2f", slider.value))"
        if self.sliderValueChangeHandler != nil {
            self.sliderValueChangeHandler!(slider.value)
        }
    }
}
