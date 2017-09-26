//
//  VideoZoomView.swift
//  Gifer
//
//  Created by Peter Lee on 2017/9/26.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import SnapKit

class VideoZoomView: UIView {

    public static let height: CGFloat = 44
    
    lazy var addButton: UIButton = {
        let addButton = UIButton(frame: CGRect.zero)
        addButton.setTitle("+", for: .normal)
        addButton.setTitleColor(UIColor.white, for: .normal)
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: 25)
        addButton.addTarget(self, action: #selector(clickAddButton), for: .touchUpInside)
        return addButton
    }()
    
    lazy var reduceButton: UIButton = {
        let reduceButton = UIButton(frame: CGRect.zero)
        reduceButton.setTitle("-", for: .normal)
        reduceButton.setTitleColor(UIColor.white, for: .normal)
        reduceButton.titleLabel?.font = UIFont.systemFont(ofSize: 25)
        reduceButton.addTarget(self, action: #selector(clickReduceButton), for: .touchUpInside)
        return reduceButton
    }()
    
    lazy var slider: UISlider = {
        let slider = UISlider(frame: CGRect.zero)
        slider.minimumValue = 1
        slider.maximumValue = 3
        slider.value = 1
        slider.addTarget(self, action: #selector(sliderChange(_:)), for: .valueChanged)
        slider.minimumTrackTintColor = UIColor.lightGray
        slider.maximumTrackTintColor = UIColor.lightGray
        return slider
    }()
    
    var valueChangedHandler: ((CGFloat) -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureSubviews() {
        backgroundColor = UIColor.clear
        
        addSubview(addButton)
        addButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.snp.centerY)
            make.height.equalTo(24)
            make.width.equalTo(24)
            make.right.equalTo(-15)
        }
        
        addSubview(reduceButton)
        reduceButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.snp.centerY)
            make.height.equalTo(24)
            make.width.equalTo(24)
            make.left.equalTo(15)
        }
        
        addSubview(slider)
        slider.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.snp.centerY)
            make.left.equalTo(reduceButton.snp.right).offset(15)
            make.right.equalTo(addButton.snp.left).offset(-15)
        }
        
    }
    
    @objc func clickAddButton() {
        let newValue = slider.value + 0.1 > slider.maximumValue ? slider.maximumValue : slider.value + 0.1
        slider.setValue(newValue, animated: true)
        sliderChange(slider)
    }
    
    @objc func clickReduceButton() {
        let newValue = slider.value - 0.1 < slider.minimumValue ? slider.minimumValue : slider.value - 0.1
        slider.setValue(newValue, animated: true)
        sliderChange(slider)
    }
    
    @objc func sliderChange(_ slider: UISlider) {
        if let valueChangedHandler = valueChangedHandler {
            valueChangedHandler(CGFloat(slider.value))
        }
    }
}
