//
//  GalleryViewBottomBar.swift
//  Gifer
//
//  Created by Peter Lee on 2017/6/6.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit

class GalleryViewBottomBar: UIView {

    public static let height: CGFloat = 44
    lazy var shareButton: UIButton = {
        let shareButton = UIButton(frame: CGRect.zero)
        shareButton.setImage(#imageLiteral(resourceName: "share"), for: .normal)
        shareButton.setImage(#imageLiteral(resourceName: "share_hl"), for: .highlighted)
        shareButton.addTarget(self, action: #selector(clickShareButton), for: .touchUpInside)
        return shareButton
    }()
    
    lazy var deleteButton: UIButton = {
        let deleteButton = UIButton(frame: CGRect.zero)
        deleteButton.setImage(#imageLiteral(resourceName: "trash"), for: .normal)
        deleteButton.setImage(#imageLiteral(resourceName: "trash_hl"), for: .highlighted)
        deleteButton.addTarget(self, action: #selector(clickDeleteButton), for: .touchUpInside)
        return deleteButton
    }()
    
    var shareButtonHandler: (() -> ())?
    var deleteButtonHandler: (() -> ())?
    
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
        
        self.addSubview(self.deleteButton)
        self.deleteButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.snp.centerY)
            make.height.equalTo(24)
            make.width.equalTo(24)
            make.right.equalTo(-15)
        }
        
        self.addSubview(self.shareButton)
        self.shareButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.snp.centerY)
            make.height.equalTo(24)
            make.width.equalTo(24)
            make.left.equalTo(15)
        }
        
    }
    
    func clickShareButton() {
        if self.shareButtonHandler != nil {
            self.shareButtonHandler!()
        }
    }
    
    func clickDeleteButton() {
        if self.deleteButtonHandler != nil {
            self.deleteButtonHandler!()
        }
    }
    
}
