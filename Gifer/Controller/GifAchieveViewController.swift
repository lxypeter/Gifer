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
    
    var photo: Photo? {
        didSet {
            if self.photo!.fullImageData === nil {
                
                let requestOptions = PHImageRequestOptions()
                requestOptions.isSynchronous = true
                requestOptions.deliveryMode = .highQualityFormat
                requestOptions.resizeMode = .fast
                
                PHImageManager.default().requestImageData(for: photo!.asset, options: requestOptions, resultHandler: { [unowned self](data, type, orientation, info) in
                    self.photo!.fullImageData = data as NSData?
                    self.imageView.gifData = self.photo!.fullImageData
                })
            } else {
                self.imageView.gifData = self.photo!.fullImageData
            }
        }
    }

    private lazy var imageView: GifImageView = {
        var imageView = GifImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.backgroundColor = UIColor.clear
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureSubviews()
    }
    
    func configureSubviews() {
        self.view.addSubview(self.imageView)
        self.imageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
    }

}
