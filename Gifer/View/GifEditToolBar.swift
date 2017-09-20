//
//  GifEditToolBar.swift
//  Gifer
//
//  Created by Peter Lee on 2017/6/14.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit

class GifEditToolBar: UIView, CAAnimationDelegate {
    private enum ToolBarAnimation {
        case enterConfirm
        case leaveConfirm
    }
    
    public static let height: CGFloat = 44
    private var status: GifEditStatus = .normal
    private var sequence: PlaySequence = .normal {
        didSet {
            switch sequence {
            case .normal:
                seqButton.setImage(#imageLiteral(resourceName: "seq_normal"), for: .normal)
                seqButton.setImage(#imageLiteral(resourceName: "seq_normal_hl"), for: .highlighted)
            case .reverse:
                seqButton.setImage(#imageLiteral(resourceName: "seq_reverse"), for: .normal)
                seqButton.setImage(#imageLiteral(resourceName: "seq_reverse_hl"), for: .highlighted)
            case .toAndFor:
                seqButton.setImage(#imageLiteral(resourceName: "seq_toandfor"), for: .normal)
                seqButton.setImage(#imageLiteral(resourceName: "seq_toandfor_hl"), for: .highlighted)
            }
        }
    }
    
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
    private lazy var seqButton: UIButton = {
        let seqButton = UIButton(frame: CGRect.zero)
        seqButton.setImage(#imageLiteral(resourceName: "seq_normal"), for: .normal)
        seqButton.setImage(#imageLiteral(resourceName: "seq_normal_hl"), for: .highlighted)
        seqButton.addTarget(self, action: #selector(clickSeqButton), for: .touchUpInside)
        return seqButton
    }()
    private lazy var filterButton: UIButton = {
        let filterButton = UIButton(frame: CGRect.zero)
        filterButton.setImage(#imageLiteral(resourceName: "filter"), for: .normal)
        filterButton.setImage(#imageLiteral(resourceName: "filter_hl"), for: .highlighted)
        filterButton.addTarget(self, action: #selector(clickFilterButton), for: .touchUpInside)
        return filterButton
    }()
    // 剪切 滤镜 确认视图
    private lazy var confirmView: UIView = {
        let confirmView = UIView(frame: CGRect.zero)
        confirmView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        return confirmView
    }()
    private lazy var confirmButton: UIButton = {
        let confirmButton = UIButton(frame: CGRect.zero)
        confirmButton.setTitle("确定", for: .normal)
        confirmButton.setTitleColor(#colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1), for: .normal)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        confirmButton.addTarget(self, action: #selector(clickConfirmButton), for: .touchUpInside)
        return confirmButton
    }()
    private lazy var cancelButton: UIButton = {
        let cancelButton = UIButton(frame: CGRect.zero)
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.setTitleColor(#colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1), for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        cancelButton.addTarget(self, action: #selector(clickCancelButton), for: .touchUpInside)
        return cancelButton
    }()
    var clipButtonHandler: (() -> ())?
    var clipConfirmButtonHandler: (() -> ())?
    var clipCancelButtonHandler: (() -> ())?
    var seqButtonHandler: ((PlaySequence) -> ())?
    var filterButtonHandler: (() -> ())?
    var filterConfirmButtonHandler: (() -> ())?
    var filterCancelButtonHandler: (() -> ())?
    
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
        
        let buttonCount: CGFloat = 3
        let paddingHorizontal: CGFloat = 15
        let buttonWidth: CGFloat = 24
        let spacing: CGFloat = (kScreenWidth - 2 * paddingHorizontal - buttonCount * buttonWidth) / (buttonCount - 1)
        addSubview(baseView)
        baseView.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.height.equalTo(GifEditToolBar.height)
            make.left.equalTo(0)
            make.right.equalTo(0)
        }
        baseView.addSubview(seqButton)
        seqButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(baseView.snp.centerY)
            make.height.equalTo(buttonWidth)
            make.width.equalTo(buttonWidth)
            make.left.equalTo(paddingHorizontal)
        }
        baseView.addSubview(filterButton)
        filterButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(baseView.snp.centerY)
            make.height.equalTo(buttonWidth)
            make.width.equalTo(buttonWidth)
            make.left.equalTo(seqButton.snp.right).offset(spacing)
        }
        baseView.addSubview(clipButton)
        clipButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(baseView.snp.centerY)
            make.height.equalTo(buttonWidth)
            make.width.equalTo(buttonWidth)
            make.left.equalTo(filterButton.snp.right).offset(spacing)
        }
        
        addSubview(confirmView)
        confirmView.snp.makeConstraints { (make) in
            make.top.equalTo(GifEditToolBar.height)
            make.height.equalTo(GifEditToolBar.height)
            make.left.equalTo(0)
            make.right.equalTo(0)
        }
        confirmView.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(confirmView.snp.centerY)
            make.height.equalTo(40)
            make.width.equalTo(60)
            make.right.equalTo(-15)
        }
        confirmView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(confirmView.snp.centerY)
            make.height.equalTo(40)
            make.width.equalTo(60)
            make.left.equalTo(15)
        }
        
        let seperateLine = UIView(frame: CGRect.zero)
        seperateLine.backgroundColor = #colorLiteral(red: 0.862745098, green: 0.862745098, blue: 0.862745098, alpha: 1)
        addSubview(seperateLine)
        seperateLine.snp.makeConstraints { (make) in
            make.bottom.equalTo(0)
            make.right.equalTo(0)
            make.left.equalTo(0)
            make.height.equalTo(0.5)
        }
    }
    
    //MARK: events
    @objc func clickClipButton() {
        if status != .normal { return }
        status = .cliping
        animationOfStatusSwitch(status: .enterConfirm)
        guard let clipButtonHandler = clipButtonHandler else {
            return
        }
        clipButtonHandler()
    }
    @objc func clickFilterButton() {
        if status != .normal { return }
        status = .filtering
        animationOfStatusSwitch(status: .enterConfirm)
        guard let filterButtonHandler = filterButtonHandler else {
            return
        }
        filterButtonHandler()
    }
    
    @objc func clickConfirmButton() {
        switch status {
        case .cliping:
            status = .normal
            animationOfStatusSwitch(status: .leaveConfirm)
            guard let clipConfirmButtonHandler = clipConfirmButtonHandler else {
                return
            }
            clipConfirmButtonHandler()
        case .filtering:
            status = .normal
            animationOfStatusSwitch(status: .leaveConfirm)
            guard let filterConfirmButtonHandler = filterConfirmButtonHandler else {
                return
            }
            filterConfirmButtonHandler()
        default: break
        }
    }
    
    @objc func clickCancelButton() {
        switch status {
        case .cliping:
            status = .normal
            animationOfStatusSwitch(status: .leaveConfirm)
            guard let clipCancelButtonHandler = clipCancelButtonHandler else {
                return
            }
            clipCancelButtonHandler()
        case .filtering:
            status = .normal
            animationOfStatusSwitch(status: .leaveConfirm)
            guard let filterCancelButtonHandler = filterCancelButtonHandler else {
                return
            }
            filterCancelButtonHandler()
        default: break
        }
    }
    
    @objc func clickSeqButton() {
        if status != .normal { return }
        switch sequence {
        case .normal:
            sequence = .reverse
        case .reverse:
            sequence = .toAndFor
        case .toAndFor:
            sequence = .normal
        }
        guard let seqButtonHandler = seqButtonHandler else {
            return
        }
        seqButtonHandler(sequence)
    }
    
    //MARK: delegate method
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        switch status {
        case .cliping, .filtering:
            baseView.snp.updateConstraints({ (make) in
                make.top.equalTo(-GifEditToolBar.height)
            })
            confirmView.snp.updateConstraints({ (make) in
                make.top.equalTo(0)
            })
        default:
            baseView.snp.updateConstraints({ (make) in
                make.top.equalTo(0)
            })
            confirmView.snp.updateConstraints({ (make) in
                make.top.equalTo(GifEditToolBar.height)
            })
        }
        baseView.layer.removeAllAnimations()
        confirmView.layer.removeAllAnimations()
    }
    
    //MARK: animate
    private func animationOfStatusSwitch(status: ToolBarAnimation) {
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "position")
        animation.delegate = self
        switch status {
        case .enterConfirm:
            animation.byValue = CGPoint(x: 0, y: -GifEditToolBar.height)
        case .leaveConfirm:
            animation.byValue = CGPoint(x: 0, y: GifEditToolBar.height)
        }
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards;
        animation.duration = 0.25
        baseView.layer.add(animation, forKey: nil)
        confirmView.layer.add(animation, forKey: nil)
    }
}
