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
        didSet{
            if self.photo != nil && self.photo!.photoWidth < self.imageView.frame.size.width && self.photo!.photoHeight < self.imageView.frame.size.height {
                imageView.contentMode = .center
            } else {
                imageView.contentMode = .scaleAspectFit
            }
            self.imageView.gifData = self.photo?.fullImageData
        }
    }
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: CGRect.zero)
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 2.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        var screenSize = UIScreen.main.bounds.size
        return scrollView
    }()
    
    private lazy var imageView: GifImageView = {
        var imageView = GifImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.backgroundColor = UIColor.clear
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(self.scrollView)
        self.scrollView.snp.makeConstraints { (make) in
            make.edges.edges.equalTo(self.contentView)
        }
        self.imageView.frame.size = frame.size
        self.scrollView.addSubview(self.imageView)
        //gesture
//        let doubleClickGes: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleClickScrollView))
//        doubleClickGes.numberOfTapsRequired = 2
//        self.imageView.addGestureRecognizer(doubleClickGes)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func doubleClickScrollView() {
        self.scrollView.setZoomScale(1.0, animated: true)
    }
    
    func resetZoomScale() {
        self.scrollView.setZoomScale(1.0, animated: false)
    }
    
    //MARK: delegate method
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }

}
