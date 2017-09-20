//
//  ViewRecordTopView.swift
//  Gifer
//
//  Created by Peter Lee on 2017/8/28.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import AVFoundation

class VideoClipTopView: UIView {
    
    public static let height: CGFloat = 64
    private lazy var normalBackgroundView: UIView = {
        let normalBackgroundView = UIView()
        return normalBackgroundView
    }()
    private lazy var backButton: UIButton = {
        let backButton = UIButton()
        backButton.setBackgroundImage(#imageLiteral(resourceName: "back_white"), for: .normal)
        backButton.addTarget(self, action: #selector(clickBackButton), for: .touchUpInside)
        return backButton
    }()
    private lazy var nextButton: UIButton = {
        let nextButton = UIButton()
        nextButton.setTitle("下一步", for: .normal)
        nextButton.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        nextButton.addTarget(self, action: #selector(clickNextButton), for: .touchUpInside)
        return nextButton
    }()
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.text = "剪辑"
        titleLabel.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        return titleLabel
    }()
    private lazy var subTitleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 12)
        titleLabel.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        return titleLabel
    }()
    
    public var totalLength: Double = 0 {
        didSet {
            updateSubtitle()
        }
    }
    public var currentLength: Double = 0 {
        didSet {
            updateSubtitle()
        }
    }
    public var backButtonHandler: (() -> ())?
    public var nextButtonHandler: (() -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureSubviews() {
        self.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        self.clipsToBounds = true
        
        self.addSubview(normalBackgroundView)
        normalBackgroundView.snp.makeConstraints { (make) in
            make.top.equalTo(20)
            make.right.equalTo(0)
            make.left.equalTo(0)
            make.bottom.equalTo(0)
        }
        
        normalBackgroundView.addSubview(backButton)
        backButton.snp.makeConstraints { (make) in
            make.width.equalTo(24)
            make.height.equalTo(24)
            make.left.equalTo(15)
            make.centerY.equalTo(normalBackgroundView.snp.centerY)
        }
        
        normalBackgroundView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.centerX.equalTo(normalBackgroundView.snp.centerX)
        }
        
        normalBackgroundView.addSubview(subTitleLabel)
        subTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(3)
            make.centerX.equalTo(normalBackgroundView.snp.centerX)
        }
        
        normalBackgroundView.addSubview(nextButton)
        nextButton.snp.makeConstraints { (make) in
            make.width.equalTo(60)
            make.height.equalTo(24)
            make.right.equalTo(-15)
            make.centerY.equalTo(normalBackgroundView.snp.centerY)
        }
    }
    
    // MARK: event
    @objc func clickBackButton() {
        guard let backButtonHandler = self.backButtonHandler else {
            return
        }
        backButtonHandler()
    }
    
    @objc func clickNextButton() {
        guard let nextButtonHandler = self.nextButtonHandler else {
            return
        }
        nextButtonHandler()
    }
    
    func updateSubtitle() {
        let totalLengthStr = descriptionOfTime(totalLength)
        let currentLengthStr = descriptionOfTime(currentLength)
        let subtitle = "总长 \(totalLengthStr), 截取 \(currentLengthStr)"
        subTitleLabel.text = subtitle
    }
    
    func descriptionOfTime(_ time: Double) -> String {
        if time > 3600 {
            let hour = Int(time / 3600)
            let min = Int((time - Double(hour) * 3600) / 60)
            let sec = Int(time - Double(hour) * 3600 - Double(min) * 60)
            return "\(hour)小时\(min)分钟\(sec)秒"
        } else if time > 60 {
            let min = Int(time / 60)
            let sec = Int(time - Double(min) * 60)
            return "\(min)分钟\(sec)秒"
        } else {
            return String(format: "%.2f秒", time)
        }
    }
}
