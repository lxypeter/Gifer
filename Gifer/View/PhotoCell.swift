//
//  PhotoCell.swift
//  Gifer
//
//  Created by Peter Lee on 2017/6/1.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import SnapKit

class PhotoCell: UICollectionViewCell, UIScrollViewDelegate {
    var photo: Photo? {
        didSet {
            guard let photo = photo else {
                return
            }
            
            if photo.fullImageData != nil {
                if photo.photoWidth < self.imageView.frame.size.width && photo.photoHeight < imageView.frame.size.height {
                    imageView.contentMode = .center
                } else {
                    imageView.contentMode = .scaleAspectFit
                }
                imageView.gifData = photo.fullImageData
            }
            
            if oldValue != nil {
                oldValue!.removeObserver(self, forKeyPath: "fullImageData")
            }
            photo.addObserver(self, forKeyPath: "fullImageData", options: .new, context: nil)
        }
    }
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: CGRect.zero)
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 2.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private lazy var imageView: GifImageView = {
        var imageView = GifImageView()
        imageView.contentMode = .center
        imageView.isUserInteractionEnabled = true
        imageView.backgroundColor = UIColor.clear
        imageView.gifPlaceholder = NSData(contentsOf: Bundle.main.url(forResource: "loading", withExtension: "gif")!)
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.edges.edges.equalTo(contentView)
        }
        imageView.frame.size = frame.size
        scrollView.addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        guard let photo = photo else {
            return
        }
        photo.removeObserver(self, forKeyPath: "fullImageData")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        let newImageData = change?[NSKeyValueChangeKey.newKey] as? NSData
        
        if photo!.photoWidth < self.imageView.frame.size.width && photo!.photoHeight < imageView.frame.size.height {
            imageView.contentMode = .center
        } else {
            imageView.contentMode = .scaleAspectFit
        }
        imageView.gifData = newImageData
    }
    
    func setGifSpeedTimes(_ speedTimes: Double) {
        imageView.speedTimes = speedTimes
    }
    
    func resetZoomScale(animated: Bool) {
        scrollView.setZoomScale(1.0, animated: animated)
    }
    
    //MARK: delegate method
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

}
