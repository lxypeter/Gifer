//
//  PhotoViewController.swift
//  Gifer
//
//  Created by Peter Lee on 2017/5/25.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import Kingfisher
import SnapKit
import Photos

class PhotoViewController: UIViewController {

    var gifArray: [Photo] = []
    var currentIndex: Int = 0
    private lazy var imageView: GifImageView = {
        return GifImageView()
    }()
    
    convenience init(gifArray: [Photo], currentIndex: Int) {
        self.init()
        self.gifArray = gifArray
        self.currentIndex = currentIndex
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureSubviews()
        self.configureImage()
    }
    
    func configureSubviews() {
        self.imageView.contentMode = .scaleAspectFit
        self.view.addSubview(self.imageView)
        self.imageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
    }
    
    func configureImage() {
        let currentPhoto = self.gifArray[currentIndex]
        if currentPhoto.fullImageData === nil {
            
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.resizeMode = .fast
            
            PHImageManager.default().requestImageData(for: currentPhoto.asset, options: requestOptions, resultHandler: { (data, type, orientation, info) in
                currentPhoto.fullImageData = data as NSData?
                self.imageView.gifData = currentPhoto.fullImageData
            })
        } else {
            self.imageView.gifData = currentPhoto.fullImageData
        }
        
    }
}
