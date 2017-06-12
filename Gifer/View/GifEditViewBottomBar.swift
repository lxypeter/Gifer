//
//  GifEditViewBottomBar.swift
//  Gifer
//
//  Created by Peter Lee on 2017/6/9.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit

class GifEditViewBottomBar: UIView {
    
    let originDuration: Double = 0.5
    let minDuration: Float = 0.01
    let maxDuration: Float = 1.00
    var currentDuration: Float {
        get {
            return self.slider.value
        }
    }
    var totalCount: Int = 0 {
        didSet {
            self.speedTimesLabel.text = "间隔: \(String(format: "%.2f", self.slider.value))秒，共\(Float(String(format: "%.2f", self.slider.value))! * Float(self.totalCount))秒"
        }
    }
    private lazy var minDurationLabel: UILabel = {
        let minDurationLabel = UILabel(frame: CGRect.zero)
        minDurationLabel.text = "\(String(format: "%.2f", self.minDuration))s"
        minDurationLabel.font = UIFont.systemFont(ofSize: 12)
        minDurationLabel.textAlignment = .center
        minDurationLabel.textColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return minDurationLabel
    }()
    
    private lazy var maxDurationLabel: UILabel = {
        let maxDurationLabel = UILabel(frame: CGRect.zero)
        maxDurationLabel.text = "\(String(format: "%.2f", self.maxDuration))s"
        maxDurationLabel.font = UIFont.systemFont(ofSize: 12)
        maxDurationLabel.textAlignment = .center
        maxDurationLabel.textColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return maxDurationLabel
    }()
    
    private lazy var slider: UISlider = {
        let slider = UISlider(frame: CGRect.zero)
        slider.minimumValue = self.minDuration
        slider.maximumValue = self.maxDuration
        slider.value = Float(self.originDuration)
        slider.addTarget(self, action: #selector(sliderChange(_:)), for: .valueChanged)
        return slider
    }()
    
    private lazy var speedTimesLabel: UILabel = {
        let speedTimesLabel = UILabel(frame: CGRect.zero)
        speedTimesLabel.text = "间隔: \(String(format: "%.2f", self.slider.value))秒，共\(Float(String(format: "%.2f", self.slider.value))! * Float(self.totalCount))秒"
        speedTimesLabel.font = UIFont.systemFont(ofSize: 12)
        speedTimesLabel.textAlignment = .center
        speedTimesLabel.textColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return speedTimesLabel
    }()
    
    var sliderValueChangeHandler: ((Float) -> ())?
    
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
        
        self.addSubview(self.minDurationLabel)
        self.addSubview(self.maxDurationLabel)
        self.addSubview(self.slider)
        
        self.minDurationLabel.snp.makeConstraints { (make) in
            make.width.equalTo(35)
            make.centerY.equalTo(self.slider.snp.centerY)
            make.left.equalTo(15)
        }
        
        self.maxDurationLabel.snp.makeConstraints { (make) in
            make.width.equalTo(35)
            make.centerY.equalTo(self.slider.snp.centerY)
            make.right.equalTo(-15)
        }
        
        self.slider.snp.makeConstraints { (make) in
            make.left.equalTo(self.minDurationLabel.snp.right).offset(15)
            make.right.equalTo(self.maxDurationLabel.snp.left).offset(-15)
            make.bottom.equalTo(-5)
        }
        
        self.addSubview(self.speedTimesLabel)
        self.speedTimesLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.minDurationLabel.snp.right).offset(15)
            make.right.equalTo(self.maxDurationLabel.snp.left).offset(-15)
            make.centerX.equalTo(self.snp.centerX)
            make.bottom.equalTo(self.slider.snp.top).offset(0)
        }
        
    }
    
    func sliderChange(_ slider: UISlider) {
        self.speedTimesLabel.text = "间隔: \(String(format: "%.2f", self.slider.value))秒，共\(Float(String(format: "%.2f", self.slider.value))! * Float(self.totalCount))秒"
        if self.sliderValueChangeHandler != nil {
            self.sliderValueChangeHandler!(slider.value)
        }
    }
    
}
