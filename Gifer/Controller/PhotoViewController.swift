//
//  PhotoViewController.swift
//  Gifer
//
//  Created by Peter Lee on 2017/5/25.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import SnapKit
import Photos

class PhotoViewController: BaseViewController, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    //MARK: property
    let photoCellId = "kPhotoCellId"
    
    var gifArray: [Photo] = []
    var currentIndex: Int = 0
    private var speedTimes: Double = 1
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
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: self.photoCellId)
        
        // gesture
        let singleClickGes: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(clickCollectionView))
        collectionView.addGestureRecognizer(singleClickGes)
        
        let doubleClickGes: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleClickCollectionView))
        doubleClickGes.numberOfTapsRequired = 2
        collectionView.addGestureRecognizer(doubleClickGes)
        
        singleClickGes.require(toFail: doubleClickGes)
        
        return collectionView
    }()
    private var isCollectionViewInit: Bool = false
    private var isBrowsing: Bool = false
    private lazy var bottomBar: PhotoViewBottomBar = {
        let bottomBar = PhotoViewBottomBar(frame: CGRect.zero)
        bottomBar.sliderValueChangeHandler = { [unowned self] value in
            self.speedTimes = Double(String(format: "%.2f", value))!
            for cell in self.collectionView.visibleCells {
                let photoCell = cell as! PhotoCell
                photoCell.setGifSpeedTimes(self.speedTimes)
            }
        }
        
        bottomBar.deleteButtonHandler = { [unowned self] in
            if self.collectionView.indexPathsForVisibleItems.count != 1 {
                return
            }
            let indexPath = self.collectionView.indexPathsForVisibleItems.last!
            let photo = self.gifArray[indexPath.row]
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(NSArray(array: [photo.asset]))
            }, completionHandler: { [unowned self] (success, error) in
                DispatchQueue.main.async {
                    if !success {
                        self.showNotice(message: "删除失败") 
                    } else {
                        self.gifArray.remove(at: indexPath.row)
                        self.collectionView.reloadData()
                        self.showNotice(message: "删除成功！")
                    }
                }
            })
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
        
        self.view.addSubview(self.bottomBar)
        self.bottomBar.snp.makeConstraints { (make) in
            make.bottom.equalTo(0)
            make.right.equalTo(0)
            make.left.equalTo(0)
            make.height.equalTo(PhotoViewBottomBar.height)
        }
        
        self.view.addSubview(self.collectionView)
        self.collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(kStatusBarHeight + kNavigationBarHeight)
            make.bottom.equalTo(self.bottomBar.snp.top)
            make.right.equalTo(0)
            make.left.equalTo(0)
        }
        
        self.collectionView.setNeedsLayout()
        self.collectionView.layoutIfNeeded()
        self.collectionView.scrollToItem(at: IndexPath(item: self.currentIndex, section: 0), at: [.top,.left], animated: false)
    }
    
    //MARK: delegate method
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.gifArray.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: PhotoCell = collectionView.dequeueReusableCell(withReuseIdentifier: self.photoCellId, for: indexPath) as! PhotoCell
        
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
        photoCell.resetZoomScale(animated: false)
        if self.isCollectionViewInit {
            self.title = "\(indexPath.row+1) / \(self.gifArray.count)"
        } else {
            self.isCollectionViewInit = true
        }
        photoCell.setGifSpeedTimes(self.speedTimes)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = UIScreen.main.bounds.height - kStatusBarHeight - kNavigationBarHeight - PhotoViewBottomBar.height
        return CGSize(width: kScreenWidth, height: height)
    }
    
    //MARK: events
    func clickCollectionView() {
        self.isBrowsing = !self.isBrowsing
        self.setNeedsStatusBarAppearanceUpdate()
        if self.isBrowsing {
            UIView.animate(withDuration: 0.25) {
                var naviFrame = self.navigationController!.navigationBar.frame
                naviFrame.origin.y = -64
                self.navigationController?.navigationBar.frame = naviFrame
                self.collectionView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            }
            self.bottomBar.snp.updateConstraints({ (make) in
                make.bottom.equalTo(PhotoViewBottomBar.height)
            })
            
            self.collectionView.snp.updateConstraints({ (make) in
                make.top.equalTo(0)
            })
        } else {
            UIView.animate(withDuration: 0.25) {
                var frame = self.navigationController!.navigationBar.frame
                frame.origin.y = 20
                self.navigationController?.navigationBar.frame = frame
                self.collectionView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            }
            self.bottomBar.snp.updateConstraints({ (make) in
                make.bottom.equalTo(0)
            })
            
            self.collectionView.snp.updateConstraints({ (make) in
                make.top.equalTo(kStatusBarHeight + kNavigationBarHeight)
            })
        }
    }
    
    func doubleClickCollectionView() {
        for cell in self.collectionView.visibleCells {
            let photoCell = cell as! PhotoCell
            photoCell.resetZoomScale(animated: true)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        get {
            return self.isBrowsing
        }
    }
    
}
