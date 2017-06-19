//
//  GifEditToolBar.swift
//  Gifer
//
//  Created by Peter Lee on 2017/6/14.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit

class GifEditToolBar: UIView, CAAnimationDelegate {
    private enum EditToolBarStatus {
        case normal
        case cliping
    }
    private enum ToolBarAnimation {
        case enterCliping
        case leaveCliping
    }
    
    public static let height: CGFloat = 44
    private var status: EditToolBarStatus = .normal
    
    private lazy var baseView: UIView = {
        let baseView = UIView(frame: CGRect.zero)
        baseView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        return baseView
    }()
    private lazy var clipButton: UIButton = {
        let clipButton = UIButton(frame: CGRect.zero)
        clipButton.setImage(#imageLiteral(resourceName: "clip"), for: .normal)
        clipButton.setImage(#imageLiteral(resourceName: "clip_hl"), for: .highlighted)
        clipButton.addTarget(self, action: #selector(clickClipButton), for: .touchUpInside)
        return clipButton
    }()
    // 剪切 子目录
    private lazy var clipView: UIView = {
        let clipView = UIView(frame: CGRect.zero)
        clipView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        return clipView
    }()
    private lazy var clipConfirmButton: UIButton = {
        let confirmButton = UIButton(frame: CGRect.zero)
        confirmButton.setTitle("确定", for: .normal)
        confirmButton.setTitleColor(#colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1), for: .normal)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        confirmButton.addTarget(self, action: #selector(clickClipConfirmButton), for: .touchUpInside)
        return confirmButton
    }()
    private lazy var clipCancelButton: UIButton = {
        let clipCancelButton = UIButton(frame: CGRect.zero)
        clipCancelButton.setTitle("取消", for: .normal)
        clipCancelButton.setTitleColor(#colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1), for: .normal)
        clipCancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        clipCancelButton.addTarget(self, action: #selector(clickClipCancelButton), for: .touchUpInside)
        return clipCancelButton
    }()
    var clipButtonHandler: (() -> ())?
    var clipConfirmButtonHandler: (() -> ())?
    var clipCancelButtonHandler: (() -> ())?
    
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
            make.height.equalTo(GifEditToolBar.height)
            make.left.equalTo(0)
            make.right.equalTo(0)
        }
        self.baseView.addSubview(self.clipButton)
        self.clipButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.baseView.snp.centerY)
            make.height.equalTo(24)
            make.width.equalTo(24)
            make.right.equalTo(-15)
        }
        
        self.addSubview(self.clipView)
        self.clipView.snp.makeConstraints { (make) in
            make.top.equalTo(GifEditToolBar.height)
            make.height.equalTo(GifEditToolBar.height)
            make.left.equalTo(0)
            make.right.equalTo(0)
        }
        self.clipView.addSubview(self.clipConfirmButton)
        self.clipConfirmButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.clipView.snp.centerY)
            make.height.equalTo(40)
            make.width.equalTo(60)
            make.right.equalTo(-15)
        }
        self.clipView.addSubview(self.clipCancelButton)
        self.clipCancelButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.clipView.snp.centerY)
            make.height.equalTo(40)
            make.width.equalTo(60)
            make.left.equalTo(15)
        }
        
        let seperateLine = UIView(frame: CGRect.zero)
        seperateLine.backgroundColor = #colorLiteral(red: 0.862745098, green: 0.862745098, blue: 0.862745098, alpha: 1)
        self.addSubview(seperateLine)
        seperateLine.snp.makeConstraints { (make) in
            make.bottom.equalTo(0)
            make.right.equalTo(0)
            make.left.equalTo(0)
            make.height.equalTo(0.5)
        }
    }
    
    //MARK: events
    func clickClipButton() {
        if self.status == .cliping { return }
        self.status = .cliping
        
        self.animationOfClipSwitch(status: .enterCliping)
        
        guard let clipButtonHandler = self.clipButtonHandler else {
            return
        }
        clipButtonHandler()
        
    }
    
    func clickClipConfirmButton() {
        if self.status == .normal { return }
        self.status = .normal
        
        self.animationOfClipSwitch(status: .leaveCliping)
        
        guard let clipConfirmButtonHandler = self.clipConfirmButtonHandler else {
            return
        }
        clipConfirmButtonHandler()
    }
    
    func clickClipCancelButton() {
        if self.status == .normal { return }
        self.status = .normal
        
        self.animationOfClipSwitch(status: .leaveCliping)
        
        guard let clipCancelButtonHandler = self.clipCancelButtonHandler else {
            return
        }
        clipCancelButtonHandler()
    }
    
    //MARK: delegate method
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        switch self.status {
        case .cliping:
            self.baseView.snp.updateConstraints({ (make) in
                make.top.equalTo(-GifEditToolBar.height)
            })
            self.clipView.snp.updateConstraints({ (make) in
                make.top.equalTo(0)
            })
        default:
            self.baseView.snp.updateConstraints({ (make) in
                make.top.equalTo(0)
            })
            self.clipView.snp.updateConstraints({ (make) in
                make.top.equalTo(GifEditToolBar.height)
            })
        }
        self.baseView.layer.removeAllAnimations()
        self.clipView.layer.removeAllAnimations()
    }
    
    //MARK: animate
    private func animationOfClipSwitch(status: ToolBarAnimation) {
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "position")
        animation.delegate = self
        switch status {
        case .enterCliping:
            animation.byValue = CGPoint(x: 0, y: -GifEditToolBar.height)
        case .leaveCliping:
            animation.byValue = CGPoint(x: 0, y: GifEditToolBar.height)
        }
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards;
        animation.duration = 0.25
        self.baseView.layer.add(animation, forKey: nil)
        self.clipView.layer.add(animation, forKey: nil)
    }
}
