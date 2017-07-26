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
        var imageView = GifImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        imageView.gifData = NSData(contentsOf: self.imageUrl!)
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureSubviews()
    }
    
    func configureSubviews() {
        view.backgroundColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        view.addSubview(self.imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
    }

}
