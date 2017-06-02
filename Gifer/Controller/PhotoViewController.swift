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

class PhotoViewController: BaseViewController, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    //MARK: property
    var gifArray: [Photo] = []
    var currentIndex: Int = 0
    private lazy var collectionView: UICollectionView = {
        let layout:UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets.zero
        layout.scrollDirection = .horizontal
        
        let collectionView:UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.white
        collectionView.isPagingEnabled = true
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: kPhotoCellId)
        
        let singleClickGes: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(clickCollectionView))
        collectionView.addGestureRecognizer(singleClickGes)
        
        return collectionView
    }()
    private var isCollectionViewInit: Bool = false
    private var isBrowsing: Bool = false
    private lazy var bottomBar : PhotoViewBottomBar = {
        let bottomBar = PhotoViewBottomBar(frame: CGRect.zero)
        bottomBar.sliderValueChange = { value in
            print("\(value)")
        }
        return bottomBar
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
        self.extendedLayoutIncludesOpaqueBars = true
        self.configureSubviews()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    func configureSubviews() {
        
        self.edgesForExtendedLayout = .all;
        
        self.title = "\(self.currentIndex+1) / \(self.gifArray.count)"
        
        self.view.addSubview(self.collectionView)
        self.collectionView.snp.makeConstraints { (make) in
            make.bottom.equalTo(0)
            make.right.equalTo(0)
            make.left.equalTo(0)
            make.top.equalTo(0)
        }
        
        self.view.addSubview(self.bottomBar)
        self.bottomBar.snp.makeConstraints { (make) in
            make.bottom.equalTo(0)
            make.right.equalTo(0)
            make.left.equalTo(0)
            make.height.equalTo(44)
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
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let photoCell: PhotoCell = cell as! PhotoCell
        photoCell.resetZoomScale()
        if self.isCollectionViewInit {
            self.title = "\(indexPath.row+1) / \(self.gifArray.count)"
        } else {
            self.isCollectionViewInit = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width, height: collectionView.frame.size.height)
    }
    
    func clickCollectionView() {
        self.isBrowsing = !self.isBrowsing
        self.setNeedsStatusBarAppearanceUpdate()
        if self.isBrowsing {
            UIView.animate(withDuration: 0.25) {
                var naviFrame = self.navigationController!.navigationBar.frame
                naviFrame.origin.y = -64
                self.navigationController?.navigationBar.frame = naviFrame
                self.collectionView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                
                self.bottomBar.snp.updateConstraints({ (make) in
                    make.bottom.equalTo(44)
                })
            }
        } else {
            UIView.animate(withDuration: 0.25) {
                var frame = self.navigationController!.navigationBar.frame
                frame.origin.y = 20
                self.navigationController?.navigationBar.frame = frame
                self.collectionView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
                
                self.bottomBar.snp.updateConstraints({ (make) in
                    make.bottom.equalTo(0)
                })
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        get {
            return self.isBrowsing
        }
    }
    
}
