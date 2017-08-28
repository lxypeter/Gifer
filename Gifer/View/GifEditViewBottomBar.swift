//
//  GifEditViewBottomBar.swift
//  Gifer
//
//  Created by Peter Lee on 2017/6/9.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit

enum GifEditViewBottomBarStatus {
    case normal
    case cliping
}

enum RatioStatus {
    case noLimit
    case fourToThree
    case sixteenToNine
    case oneToOne
    
    var floatValue: CGFloat {
        var result : CGFloat
        switch self {
        case .noLimit:
            result = 0
        case .fourToThree:
            result = 4/3
        case .sixteenToNine:
            result = 16/9
        case .oneToOne:
            result = 1/1
        }
        return result
    }
}

class GifEditViewBottomBar: UIView, CAAnimationDelegate {
    
    public static let height: CGFloat = 54
    
    public var status: GifEditViewBottomBarStatus = .normal {
        didSet {
            if self.status == oldValue { return }
            self.animationOfClipSwitch(status: self.status)
        }
    }
    public let originDuration: Double = 0.5
    public let minDuration: Float = 0.01
    public let maxDuration: Float = 1.00
    public var currentDuration: Float {
        get {
            return self.slider.value
        }
    }
    public var totalCount: Int = 0 {
        didSet {
            self.speedTimesLabel.text = "间隔: \(String(format: "%.2f", self.slider.value))秒，共\(Float(String(format: "%.2f", self.slider.value))! * Float(self.totalCount))秒"
        }
    }
    private lazy var baseView: UIView = {
        let baseView = UIView(frame: CGRect.zero)
        baseView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        return baseView
    }()
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
    private lazy var clipView: UIView = {
        let clipView = UIView(frame: CGRect.zero)
        clipView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        return clipView
    }()
    private lazy var rotateButton: UIButton = {
        let rotateButton = UIButton(frame: CGRect.zero)
        rotateButton.setImage(#imageLiteral(resourceName: "rotate"), for: .normal)
        rotateButton.setImage(#imageLiteral(resourceName: "rotate_hl"), for: .highlighted)
        rotateButton.addTarget(self, action: #selector(clickRotateButton), for: .touchUpInside)
        return rotateButton
    }()
    private lazy var ratioButton: UIButton = {
        let ratioButton = UIButton(frame: CGRect.zero)
        ratioButton.setImage(#imageLiteral(resourceName: "ratio"), for: .normal)
        ratioButton.setImage(#imageLiteral(resourceName: "ratio_hl"), for: .highlighted)
        ratioButton.addTarget(self, action: #selector(clickRatioButton), for: .touchUpInside)
        return ratioButton
    }()
    private lazy var resetButton: UIButton = {
        let resetButton = UIButton(frame: CGRect.zero)
        resetButton.setImage(#imageLiteral(resourceName: "undo"), for: .normal)
        resetButton.setImage(#imageLiteral(resourceName: "undo_hl"), for: .highlighted)
        resetButton.addTarget(self, action: #selector(clickResetButton), for: .touchUpInside)
        return resetButton
    }()
    
    var sliderValueChangeHandler: ((Float) -> ())?
    var rotateButtonHandler: (() -> ())?
    var ratioStatus: RatioStatus = .noLimit {
        didSet {
            switch ratioStatus {
            case .fourToThree:
                ratioButton.setImage(#imageLiteral(resourceName: "ratio_4_3"), for: .normal)
                ratioButton.setImage(#imageLiteral(resourceName: "ratio_4_3_hl"), for: .highlighted)
            case .sixteenToNine:
                ratioButton.setImage(#imageLiteral(resourceName: "ratio_16_9"), for: .normal)
                ratioButton.setImage(#imageLiteral(resourceName: "ratio_16_9_hl"), for: .highlighted)
            case .oneToOne:
                ratioButton.setImage(#imageLiteral(resourceName: "ratio_1_1"), for: .normal)
                ratioButton.setImage(#imageLiteral(resourceName: "ratio_1_1_hl"), for: .highlighted)
            default:
                ratioButton.setImage(#imageLiteral(resourceName: "ratio"), for: .normal)
                ratioButton.setImage(#imageLiteral(resourceName: "ratio_hl"), for: .highlighted)
            }
        }
    }
    var ratioButtonHandler: (() -> ())?
    var resetButtonHandler: (() -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureSubviews() {
        self.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        self.clipsToBounds = true
        
        self.addSubview(self.baseView)
        self.baseView.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.height.equalTo(GifEditViewBottomBar.height)
            make.left.equalTo(0)
            make.right.equalTo(0)
        }
        self.baseView.addSubview(self.minDurationLabel)
        self.baseView.addSubview(self.maxDurationLabel)
        self.baseView.addSubview(self.slider)
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
        
        self.addSubview(self.clipView)
        self.clipView.snp.makeConstraints { (make) in
            make.top.equalTo(GifEditViewBottomBar.height)
            make.height.equalTo(GifEditViewBottomBar.height)
            make.left.equalTo(0)
            make.right.equalTo(0)
        }
        self.clipView.addSubview(self.ratioButton)
        self.clipView.addSubview(self.resetButton)
        self.clipView.addSubview(self.rotateButton)
        self.ratioButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.clipView.snp.centerX)
            make.centerY.equalTo(self.clipView.snp.centerY)
            make.width.equalTo(24)
            make.height.equalTo(24)
        }
        self.rotateButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.clipView.snp.centerY)
            make.width.equalTo(24)
            make.height.equalTo(24)
            make.centerX.equalTo(self.ratioButton.snp.centerX).multipliedBy(0.5)
        }
        self.resetButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.clipView.snp.centerY)
            make.width.equalTo(24)
            make.height.equalTo(24)
            make.centerX.equalTo(self.ratioButton.snp.centerX).multipliedBy(1.5)
        }
        
        let seperateLine = UIView(frame: CGRect.zero)
        seperateLine.backgroundColor = #colorLiteral(red: 0.862745098, green: 0.862745098, blue: 0.862745098, alpha: 1)
        self.addSubview(seperateLine)
        seperateLine.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.right.equalTo(0)
            make.left.equalTo(0)
            make.height.equalTo(0.5)
        }
        
    }
    
    //MARK: events
    func sliderChange(_ slider: UISlider) {
        self.speedTimesLabel.text = "间隔: \(String(format: "%.2f", self.slider.value))秒，共\(Float(String(format: "%.2f", self.slider.value))! * Float(self.totalCount))秒"
        if self.sliderValueChangeHandler != nil {
            self.sliderValueChangeHandler!(slider.value)
        }
    }
    
    func clickRotateButton() {
        if self.status != .cliping { return }
        guard let rotateButtonHandler = self.rotateButtonHandler else {
            return
        }
        rotateButtonHandler()
    }
    
    func clickRatioButton() {
        if self.status != .cliping { return }
        guard let ratioButtonHandler = self.ratioButtonHandler else {
            return
        }
        ratioButtonHandler()
    }
    
    func clickResetButton() {
        if self.status != .cliping { return }
        guard let resetButtonHandler = self.resetButtonHandler else {
            return
        }
        resetButtonHandler()
    }
    
    //MARK: delegate method
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        switch self.status {
        case .cliping:
            self.baseView.snp.updateConstraints({ (make) in
                make.top.equalTo(-GifEditViewBottomBar.height)
            })
            self.clipView.snp.updateConstraints({ (make) in
                make.top.equalTo(0)
            })
        default:
            self.baseView.snp.updateConstraints({ (make) in
                make.top.equalTo(0)
            })
            self.clipView.snp.updateConstraints({ (make) in
                make.top.equalTo(GifEditViewBottomBar.height)
            })
        }
        self.baseView.layer.removeAllAnimations()
        self.clipView.layer.removeAllAnimations()
    }
    
    //MARK: animate
    private func animationOfClipSwitch(status: GifEditViewBottomBarStatus) {
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "position")
        animation.delegate = self
        switch status {
        case .cliping:
            animation.byValue = CGPoint(x: 0, y: -GifEditViewBottomBar.height)
        case .normal:
            animation.byValue = CGPoint(x: 0, y: GifEditViewBottomBar.height)
        }
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards;
        animation.duration = 0.25
        self.baseView.layer.add(animation, forKey: nil)
        self.clipView.layer.add(animation, forKey: nil)
    }
}
