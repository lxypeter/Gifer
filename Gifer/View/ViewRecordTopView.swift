//
//  ViewRecordTopView.swift
//  Gifer
//
//  Created by Peter Lee on 2017/8/28.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import AVFoundation

class ViewRecordTopView: UIView {
    
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
    private lazy var flashButton: UIButton = {
        let flashButton = UIButton()
        flashButton.setBackgroundImage(#imageLiteral(resourceName: "flash"), for: .normal)
        flashButton.addTarget(self, action: #selector(clickFlashButton), for: .touchUpInside)
        return flashButton
    }()
    private lazy var flashBackgroundView: UIView = {
        let flashBackgroundView = UIView()
        flashBackgroundView.isHidden = true
        return flashBackgroundView
    }()
    private lazy var flashAutoButton: UIButton = {
        let flashAutoButton = UIButton()
        flashAutoButton.setTitle("自动", for: .normal)
        flashAutoButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        flashAutoButton.setTitleColor(UIColor.white, for: .normal)
        flashAutoButton.addTarget(self, action: #selector(clickFlashSwitchButton(_:)), for: .touchUpInside)
        return flashAutoButton
    }()
    private lazy var flashEnableButton: UIButton = {
        let flashEnableButton = UIButton()
        flashEnableButton.setTitle("打开", for: .normal)
        flashEnableButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        flashEnableButton.setTitleColor(UIColor.white, for: .normal)
        flashEnableButton.addTarget(self, action: #selector(clickFlashSwitchButton(_:)), for: .touchUpInside)
        return flashEnableButton
    }()
    private lazy var flashDisableButton: UIButton = {
        let flashDisableButton = UIButton()
        flashDisableButton.setTitle("关闭", for: .normal)
        flashDisableButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        flashDisableButton.setTitleColor(UIColor.white, for: .normal)
        flashDisableButton.addTarget(self, action: #selector(clickFlashSwitchButton(_:)), for: .touchUpInside)
        return flashDisableButton
    }()
    
    var flashMode: AVCaptureTorchMode = .auto {
        didSet {
            switch flashMode {
            case .auto:
                flashButton.setBackgroundImage(#imageLiteral(resourceName: "flash"), for: .normal)
            case .on:
                flashButton.setBackgroundImage(#imageLiteral(resourceName: "flash_enable"), for: .normal)
            default:
                flashButton.setBackgroundImage(#imageLiteral(resourceName: "flash_disable"), for: .normal)
            }
        }
    }
    var isFlashButtonEnable = false {
        didSet {
            if !isFlashButtonEnable {
                flashMode = .auto
            }
            flashButton.isEnabled = isFlashButtonEnable
        }
    }
    var backButtonHandler: (() -> ())?
    var flashSwitchHandler: ((AVCaptureTorchMode) -> Bool)?
    
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
        
        normalBackgroundView.addSubview(flashButton)
        flashButton.snp.makeConstraints { (make) in
            make.width.equalTo(30)
            make.height.equalTo(30)
            make.right.equalTo(-15)
            make.centerY.equalTo(normalBackgroundView.snp.centerY)
        }
        
        self.addSubview(flashBackgroundView)
        flashBackgroundView.snp.makeConstraints { (make) in
            make.top.equalTo(20)
            make.right.equalTo(0)
            make.left.equalTo(0)
            make.bottom.equalTo(0)
        }
        
        flashBackgroundView.addSubview(flashEnableButton)
        flashEnableButton.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.bottom.equalTo(0)
            make.width.equalTo(80)
            make.centerX.equalTo(flashBackgroundView.snp.centerX)
        }
        
        flashBackgroundView.addSubview(flashAutoButton)
        flashAutoButton.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.bottom.equalTo(0)
            make.width.equalTo(80)
            make.right.equalTo(flashEnableButton.snp.left)
        }
        
        flashBackgroundView.addSubview(flashDisableButton)
        flashDisableButton.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.bottom.equalTo(0)
            make.width.equalTo(80)
            make.left.equalTo(flashEnableButton.snp.right)
        }
        
    }
    
    // MARK: event
    func clickBackButton() {
        guard let backButtonHandler = self.backButtonHandler else {
            return
        }
        backButtonHandler()
    }
    
    func clickFlashButton() {
        normalBackgroundView.isHidden = true
        flashBackgroundView.isHidden = false
    }
    
    func clickFlashSwitchButton(_ button: UIButton) {
        normalBackgroundView.isHidden = false
        flashBackgroundView.isHidden = true
        
        let tempFlashMode: AVCaptureTorchMode
        if button === flashAutoButton {
            tempFlashMode = .auto
        } else if button === flashEnableButton {
            tempFlashMode = .on
        } else {
            tempFlashMode = .off
        }
        guard let flashSwitchHandler = self.flashSwitchHandler else {
            return
        }
        if !flashSwitchHandler(tempFlashMode) { return }
        flashMode = tempFlashMode
    }
    
}
