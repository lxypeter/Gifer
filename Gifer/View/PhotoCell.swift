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
            let photoWidth = CGFloat(self.photo!.asset.pixelWidth) / UIScreen.main.scale
            let photoHeight = CGFloat(self.photo!.asset.pixelHeight) / UIScreen.main.scale
            
            if photoWidth < self.imageView.frame.size.width && photoHeight < self.imageView.frame.size.height {
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
        scrollView.maximumZoomScale = 3.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        var screenSize = UIScreen.main.bounds.size
        return scrollView
    }()
    
    private lazy var imageView: GifImageView = {
        var imageView = GifImageView()
        imageView.contentMode = .scaleAspectFit
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
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: delegate method
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
}
