//
//  GifAchieveViewController.swift
//  Gifer
//
//  Created by Peter Lee on 2017/6/9.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import SnapKit
import Photos

class GifAchieveViewController: BaseViewController {
    
    var imageUrl: URL?

    private lazy var imageView: GifImageView = {
        let imageView = GifImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.backgroundColor = .clear
        imageView.gifPlaceholder = NSData(contentsOf: Bundle.main.url(forResource: "loading", withExtension: "gif")!)
        imageView.gifData = NSData(contentsOf: self.imageUrl!)
        return imageView
    }()
    
    private lazy var closeButton: UIButton = {
        let closeButton = UIButton()
        closeButton.setImage(#imageLiteral(resourceName: "close"), for: .normal)
        closeButton.addTarget(self, action: #selector(dismissController), for: .touchUpInside)
        return closeButton
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureSubviews()
    }
    
    func configureSubviews() {
        view.backgroundColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        view.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.centerX.equalTo(view)
            make.centerY.equalTo(view)
            make.width.equalTo(kScreenWidth * 0.9)
            make.height.equalTo(kScreenWidth * 0.9)
        }
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.top.equalTo(kStatusBarHeight + 5)
            make.left.equalTo(25)
            make.width.equalTo(24)
            make.height.equalTo(24)
        }
    }
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
}
