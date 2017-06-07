//
//  NoRecordView.swift
//  Gifer
//
//  Created by Peter Lee on 2017/6/7.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import SnapKit

class NoRecordView: UIView {
    
    lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.image = #imageLiteral(resourceName: "empty")
        return iconImageView
    }()
    lazy var reloadButton: UIButton = {
        let reloadButton = UIButton()
        reloadButton.setTitle("重新加载", for: .normal)
        reloadButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        reloadButton.setTitleColor(#colorLiteral(red: 0.5333333333, green: 0.5333333333, blue: 0.5333333333, alpha: 1), for: .normal)
        reloadButton.layer.cornerRadius = 15
        reloadButton.layer.borderWidth = 1
        let borderColor = #colorLiteral(red: 0.5333333333, green: 0.5333333333, blue: 0.5333333333, alpha: 1)
        reloadButton.layer.borderColor = borderColor.cgColor
        reloadButton.addTarget(self, action: #selector(clickReloadButton), for: .touchUpInside)
        return reloadButton
    }()
//    lazy var resultLabel: UILabel = {
//        let resultLabel = UILabel()
//        resultLabel.font = UIFont.systemFont(ofSize: 17)
//        resultLabel.textColor = #colorLiteral(red: 0.5333333333, green: 0.5333333333, blue: 0.5333333333, alpha: 1)
//        resultLabel.text = "未找到GIF图片"
//        return resultLabel
//    }()
    var reloadHandler: (() -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureSubviews() {
        self.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        self.addSubview(self.iconImageView)
        self.iconImageView.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.snp.centerX)
            make.centerY.equalTo(self.snp.centerY).multipliedBy(0.8)
            make.width.equalTo(150)
            make.height.equalTo(150)
        }
        
//        self.addSubview(self.resultLabel)
//        self.resultLabel.snp.makeConstraints { (make) in
//            make.top.equalTo(self.iconImageView.snp.bottom).offset(30)
//            make.centerX.equalTo(self.snp.centerX)
//        }
        
        self.addSubview(self.reloadButton)
        self.reloadButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.iconImageView.snp.bottom).offset(12)
            make.width.equalTo(80)
            make.height.equalTo(30)
            make.centerX.equalTo(self.snp.centerX)
        }
    }
    
    func clickReloadButton() {
        if self.reloadHandler != nil {
            self.reloadHandler!()
        }
    }
}
