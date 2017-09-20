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
    var reloadHandler: (() -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureSubviews() {
        backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.centerX.equalTo(snp.centerX)
            make.centerY.equalTo(snp.centerY).multipliedBy(0.8)
            make.width.equalTo(150)
            make.height.equalTo(150)
        }
        
        addSubview(reloadButton)
        reloadButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.iconImageView.snp.bottom).offset(12)
            make.width.equalTo(80)
            make.height.equalTo(30)
            make.centerX.equalTo(self.snp.centerX)
        }
    }
    
    @objc func clickReloadButton() {
        if reloadHandler != nil {
            reloadHandler!()
        }
    }
}
