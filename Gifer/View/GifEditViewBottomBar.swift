//
//  GifEditViewBottomBar.swift
//  Gifer
//
//  Created by Peter Lee on 2017/6/9.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit

class GifEditViewBottomBar: UIView, CAAnimationDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    public static let height: CGFloat = 54
    public static let filterViewHeight: CGFloat = 100
    public static let originInterval: Float = 0.25
    
    public var status: GifEditStatus = .normal {
        didSet {
            if status == oldValue { return }
            animationOfStatusSwitch(status: status)
        }
    }
    public let minInterval: Float = 0.01
    public let maxInterval: Float = 0.50
    public var currentInterval: Float {
        get {
            return self.slider.value
        }
    }
    public var totalCount: Int = 0 {
        didSet {
            self.speedTimesLabel.text = "间隔: \(String(format: "%.2f", self.slider.value))秒，共\(Float(String(format: "%.2f", self.slider.value))! * Float(self.totalCount))秒"
        }
    }
    private let cellId = "FilterCellId"
    
    private lazy var baseView: UIView = {
        let baseView = UIView(frame: CGRect.zero)
        baseView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        return baseView
    }()
    private lazy var minDurationLabel: UILabel = {
        let minDurationLabel = UILabel(frame: CGRect.zero)
        minDurationLabel.text = "\(String(format: "%.2f", self.minInterval))s"
        minDurationLabel.font = UIFont.systemFont(ofSize: 12)
        minDurationLabel.textAlignment = .center
        minDurationLabel.textColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return minDurationLabel
    }()
    private lazy var maxDurationLabel: UILabel = {
        let maxDurationLabel = UILabel(frame: CGRect.zero)
        maxDurationLabel.text = "\(String(format: "%.2f", self.maxInterval))s"
        maxDurationLabel.font = UIFont.systemFont(ofSize: 12)
        maxDurationLabel.textAlignment = .center
        maxDurationLabel.textColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return maxDurationLabel
    }()
    private lazy var slider: UISlider = {
        let slider = UISlider(frame: CGRect.zero)
        slider.minimumValue = self.minInterval
        slider.maximumValue = self.maxInterval
        slider.value = Float(GifEditViewBottomBar.originInterval)
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
    
    private lazy var filterView: UIView = {
        let filterView = UIView(frame: CGRect.zero)
        filterView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        return filterView
    }()
    private lazy var filterCollectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets.zero
        layout.scrollDirection = .horizontal
        
        let collectionView: UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(UINib(nibName: "FilterCell", bundle: nil), forCellWithReuseIdentifier: self.cellId)
        collectionView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        return collectionView
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
        backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        clipsToBounds = true
        
        addSubview(baseView)
        baseView.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.height.equalTo(GifEditViewBottomBar.height)
            make.left.equalTo(0)
            make.right.equalTo(0)
        }
        baseView.addSubview(minDurationLabel)
        baseView.addSubview(maxDurationLabel)
        baseView.addSubview(slider)
        minDurationLabel.snp.makeConstraints { (make) in
            make.width.equalTo(35)
            make.centerY.equalTo(slider.snp.centerY)
            make.left.equalTo(15)
        }
        maxDurationLabel.snp.makeConstraints { (make) in
            make.width.equalTo(35)
            make.centerY.equalTo(slider.snp.centerY)
            make.right.equalTo(-15)
        }
        slider.snp.makeConstraints { (make) in
            make.left.equalTo(minDurationLabel.snp.right).offset(15)
            make.right.equalTo(maxDurationLabel.snp.left).offset(-15)
            make.bottom.equalTo(-5)
        }
        baseView.addSubview(speedTimesLabel)
        speedTimesLabel.snp.makeConstraints { (make) in
            make.left.equalTo(minDurationLabel.snp.right).offset(15)
            make.right.equalTo(maxDurationLabel.snp.left).offset(-15)
            make.centerX.equalTo(snp.centerX)
            make.bottom.equalTo(slider.snp.top).offset(0)
        }
        
        addSubview(clipView)
        clipView.snp.makeConstraints { (make) in
            make.top.equalTo(GifEditViewBottomBar.height)
            make.height.equalTo(GifEditViewBottomBar.height)
            make.left.equalTo(0)
            make.right.equalTo(0)
        }
        clipView.addSubview(ratioButton)
        clipView.addSubview(resetButton)
        clipView.addSubview(rotateButton)
        ratioButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(clipView.snp.centerX)
            make.centerY.equalTo(clipView.snp.centerY)
            make.width.equalTo(24)
            make.height.equalTo(24)
        }
        rotateButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(clipView.snp.centerY)
            make.width.equalTo(24)
            make.height.equalTo(24)
            make.centerX.equalTo(ratioButton.snp.centerX).multipliedBy(0.5)
        }
        resetButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(clipView.snp.centerY)
            make.width.equalTo(24)
            make.height.equalTo(24)
            make.centerX.equalTo(ratioButton.snp.centerX).multipliedBy(1.5)
        }
        
        addSubview(filterView)
        filterView.snp.makeConstraints { (make) in
            make.top.equalTo(GifEditViewBottomBar.height)
            make.height.equalTo(GifEditViewBottomBar.filterViewHeight)
            make.left.equalTo(0)
            make.right.equalTo(0)
        }
        
        let seperateLine = UIView(frame: CGRect.zero)
        seperateLine.backgroundColor = #colorLiteral(red: 0.862745098, green: 0.862745098, blue: 0.862745098, alpha: 1)
        addSubview(seperateLine)
        seperateLine.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.right.equalTo(0)
            make.left.equalTo(0)
            make.height.equalTo(0.5)
        }
        
    }
    
    //MARK: events
    func sliderChange(_ slider: UISlider) {
        updateTimesLabel()
        guard let sliderValueChangeHandler = sliderValueChangeHandler else {
            return
        }
        sliderValueChangeHandler(slider.value)
    }
    
    func clickRotateButton() {
        if status != .cliping { return }
        guard let rotateButtonHandler = rotateButtonHandler else {
            return
        }
        rotateButtonHandler()
    }
    
    func clickRatioButton() {
        if status != .cliping { return }
        guard let ratioButtonHandler = ratioButtonHandler else {
            return
        }
        ratioButtonHandler()
    }
    
    func clickResetButton() {
        if status != .cliping { return }
        guard let resetButtonHandler = resetButtonHandler else {
            return
        }
        resetButtonHandler()
    }
    
    func setInterval(_ interval: Float) {
        slider.value = interval
        updateTimesLabel()
    }
    
    private func updateTimesLabel() {
        speedTimesLabel.text = "间隔: \(String(format: "%.2f", slider.value))秒，共\(Float(String(format: "%.2f", slider.value))! * Float(totalCount))秒"
    }
    
    //MARK: delegate method
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        switch status {
        case .cliping:
            baseView.snp.updateConstraints({ (make) in
                make.top.equalTo(-GifEditViewBottomBar.height)
            })
            clipView.snp.updateConstraints({ (make) in
                make.top.equalTo(0)
            })
        case .filtering:
            baseView.snp.updateConstraints({ (make) in
                make.top.equalTo(-GifEditViewBottomBar.height)
            })
            filterView.snp.updateConstraints({ (make) in
                make.top.equalTo(0)
            })
        case .normal:
            baseView.snp.updateConstraints({ (make) in
                make.top.equalTo(0)
            })
            clipView.snp.updateConstraints({ (make) in
                make.top.equalTo(GifEditViewBottomBar.height)
            })
            filterView.snp.updateConstraints({ (make) in
                make.top.equalTo(GifEditViewBottomBar.height)
            })
        }
        baseView.layer.removeAllAnimations()
        clipView.layer.removeAllAnimations()
        filterView.layer.removeAllAnimations()
    }
    
    //MARK: animate
    private func animationOfStatusSwitch(status: GifEditStatus) {
        let baseViewAnimation: CABasicAnimation = CABasicAnimation(keyPath: "position.y")
        baseViewAnimation.delegate = self
        baseViewAnimation.isRemovedOnCompletion = false
        baseViewAnimation.fillMode = kCAFillModeForwards;
        baseViewAnimation.duration = 0.25
        
        let otherViewAnimation: CABasicAnimation = CABasicAnimation(keyPath: "position.y")
        otherViewAnimation.isRemovedOnCompletion = false
        otherViewAnimation.fillMode = kCAFillModeForwards;
        otherViewAnimation.duration = 0.25
        
        bringSubview(toFront: baseView)
        switch status {
        case .cliping:
            clipView.isHidden = false
            
            filterView.isHidden = true
            filterView.snp.updateConstraints { (make) in
                make.top.equalTo(GifEditViewBottomBar.height)
            }
            
            baseViewAnimation.toValue = -GifEditViewBottomBar.height
            otherViewAnimation.toValue = 0
            clipView.layer.add(otherViewAnimation, forKey: nil)
        case .filtering:
            filterView.isHidden = false
            
            clipView.isHidden = true
            clipView.snp.updateConstraints { (make) in
                make.top.equalTo(GifEditViewBottomBar.height)
            }
            
            baseViewAnimation.toValue = -GifEditViewBottomBar.height
            otherViewAnimation.toValue = 0
            filterView.layer.add(otherViewAnimation, forKey: nil)
        case .normal:
            baseViewAnimation.toValue = 0
            otherViewAnimation.toValue = GifEditViewBottomBar.height
            clipView.layer.add(otherViewAnimation, forKey: nil)
            filterView.layer.add(otherViewAnimation, forKey: nil)
        }
        baseView.layer.add(baseViewAnimation, forKey: nil)
    }
}
