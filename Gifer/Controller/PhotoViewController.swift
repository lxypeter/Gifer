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

let kPhotoCellId = "kPhotoCellId"

class PhotoViewController: UIViewController, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    //MARK: property
    var gifArray: [Photo] = []
    var currentIndex: Int = 0
    private lazy var collectionView: UICollectionView = {
        let layout:UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        
        let collectionView:UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.white
        collectionView.isPagingEnabled = true
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: kPhotoCellId)
        return collectionView
    }()
    
    //MARK: init method
    convenience init(gifArray: [Photo], currentIndex: Int) {
        self.init()
        self.gifArray = gifArray
        self.currentIndex = currentIndex
    }
    
    //MARK: life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    func configureSubviews() {
        
        self.view.addSubview(self.collectionView)
        self.collectionView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
        
        self.collectionView.setNeedsLayout()
        self.collectionView.layoutIfNeeded()
        self.collectionView.scrollToItem(at: IndexPath(item: self.currentIndex, section: 0), at: [.top,.left], animated: false)
        
    }
    
    func loadImage(in imageView: GifImageView, with photo: Photo){
        
        if photo.fullImageData === nil {
            
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.resizeMode = .fast
            
            PHImageManager.default().requestImageData(for: photo.asset, options: requestOptions, resultHandler: { (data, type, orientation, info) in
                photo.fullImageData = data as NSData?
                imageView.gifData = photo.fullImageData
            })
        } else {
            imageView.gifData = photo.fullImageData
        }
    }
    
    //MARK: delegate method
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.gifArray.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: PhotoCell = collectionView.dequeueReusableCell(withReuseIdentifier: kPhotoCellId, for: indexPath) as! PhotoCell
        
        let photo = self.gifArray[indexPath.row]
        
        if photo.fullImageData === nil {
            
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.resizeMode = .fast
            
            PHImageManager.default().requestImageData(for: photo.asset, options: requestOptions, resultHandler: { (data, type, orientation, info) in
                photo.fullImageData = data as NSData?
                cell.photo = photo
            })
        } else {
            cell.photo = photo
        }
        
        return cell
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width, height: collectionView.frame.size.height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
}
