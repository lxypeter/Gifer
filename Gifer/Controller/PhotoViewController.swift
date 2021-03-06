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
            self.clickDeleteButton()
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
        extendedLayoutIncludesOpaqueBars = true
        configureSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    func configureSubviews() {
        
        edgesForExtendedLayout = .all
        
        title = "\(currentIndex+1) / \(gifArray.count)"
        
        let shareButton: UIButton = UIButton()
        shareButton.setImage(#imageLiteral(resourceName: "share"), for: .normal)
        shareButton.imageView?.contentMode = .scaleAspectFit
        shareButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        let widthConstraint = shareButton.widthAnchor.constraint(equalToConstant: 24)
        let heightConstraint = shareButton.heightAnchor.constraint(equalToConstant: 24)
        heightConstraint.isActive = true
        widthConstraint.isActive = true
        shareButton.addTarget(self, action: #selector(clickShareButton), for: .touchUpInside)
        let shareItem: UIBarButtonItem = UIBarButtonItem(customView:shareButton)
        navigationItem.rightBarButtonItem = shareItem;
        
        view.addSubview(self.bottomBar)
        bottomBar.snp.makeConstraints { (make) in
            make.bottom.equalTo(0)
            make.right.equalTo(0)
            make.left.equalTo(0)
            make.height.equalTo(PhotoViewBottomBar.height)
        }
        
        view.addSubview(self.collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(kStatusBarHeight + kNavigationBarHeight)
            make.bottom.equalTo(bottomBar.snp.top)
            make.right.equalTo(0)
            make.left.equalTo(0)
        }
        
        collectionView.setNeedsLayout()
        collectionView.layoutIfNeeded()
        collectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: [.top,.left], animated: false)
    }
    
    //MARK: delegate method
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifArray.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: PhotoCell = collectionView.dequeueReusableCell(withReuseIdentifier: self.photoCellId, for: indexPath) as! PhotoCell
        
        let photo = gifArray[indexPath.row]
        cell.photo = photo
        
        if photo.fullImageData === nil {
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.resizeMode = .fast
            
            PHImageManager.default().requestImageData(for: photo.asset, options: requestOptions, resultHandler: { (data, type, orientation, info) in
                photo.fullImageData = data as NSData?
            })
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let photoCell: PhotoCell = cell as! PhotoCell
        photoCell.resetZoomScale(animated: false)
        if isCollectionViewInit {
            title = "\(indexPath.row+1) / \(self.gifArray.count)"
        } else {
            isCollectionViewInit = true
        }
        photoCell.setGifSpeedTimes(speedTimes)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = UIScreen.main.bounds.height - kStatusBarHeight - kNavigationBarHeight - PhotoViewBottomBar.height
        return CGSize(width: kScreenWidth, height: height)
    }
    
    //MARK: events
    @objc func clickCollectionView() {
        isBrowsing = !isBrowsing
        setNeedsStatusBarAppearanceUpdate()
        if isBrowsing {
            UIView.animate(withDuration: 0.25) {
                var naviFrame = self.navigationController!.navigationBar.frame
                naviFrame.origin.y = -64
                self.navigationController?.navigationBar.frame = naviFrame
                self.collectionView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            }
            bottomBar.snp.updateConstraints({ (make) in
                make.bottom.equalTo(PhotoViewBottomBar.height)
            })
            
            collectionView.snp.updateConstraints({ (make) in
                make.top.equalTo(0)
            })
        } else {
            UIView.animate(withDuration: 0.25) {
                var frame = self.navigationController!.navigationBar.frame
                frame.origin.y = 20
                self.navigationController?.navigationBar.frame = frame
                self.collectionView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            }
            bottomBar.snp.updateConstraints({ (make) in
                make.bottom.equalTo(0)
            })
            
            collectionView.snp.updateConstraints({ (make) in
                make.top.equalTo(kStatusBarHeight + kNavigationBarHeight)
            })
        }
    }
    
    @objc func doubleClickCollectionView() {
        for cell in collectionView.visibleCells {
            let photoCell = cell as! PhotoCell
            photoCell.resetZoomScale(animated: true)
        }
    }
    
    @objc func clickDeleteButton() {
        if collectionView.indexPathsForVisibleItems.count != 1 {
            return
        }
        let indexPath = collectionView.indexPathsForVisibleItems.last!
        let photo = gifArray[indexPath.row]
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(NSArray(array: [photo.asset]))
        }, completionHandler: { [unowned self] (success, error) in
            DispatchQueue.main.async {
                if !success {
                    self.showNotice(message: "删除失败")
                } else {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: kNotiKeyGalleryUpdate), object: nil)
                    self.gifArray.remove(at: indexPath.row)
                    self.collectionView.reloadData()
                    self.showNotice(message: "删除成功！")
                }
            }
        })
    }
    
    @objc func clickShareButton() {
        if collectionView.indexPathsForVisibleItems.count != 1 {
            return
        }
        let indexPath = collectionView.indexPathsForVisibleItems.last!
        let photo = gifArray[indexPath.row]
        
        var cache = UserDefaults.standard.object(forKey: kUserDefalutShareCacheKey) as? [String: String]
        if cache == nil {
            cache = [:]
        }
        
        let shareHandler: (URL) -> () = {url in
            let ctrl = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            ctrl.excludedActivityTypes = [
                .postToFacebook,
                .postToTwitter,
                .postToWeibo,
                .message,
                .mail,
                .print,
                .copyToPasteboard,
                .assignToContact,
                .saveToCameraRoll,
                .addToReadingList,
                .postToFlickr,
                .postToVimeo,
                .postToTencentWeibo,
                .openInIBooks,
                .remindersEditorExtension,
                .googleDriveShareExtension,
                .streamShareService,
                .appleNote,
            ]
            self.present(ctrl, animated: true, completion: nil)
        }
        
        let generateVideoHandler: (NSData, String) -> () = {(data, localIdentifier) in
            VideoUtil.video(with: data, completeHandler: { (result, url) in
                if result, let url = url {
                    let filename = url.path.components(separatedBy: "/").last!
                    cache![localIdentifier] = filename
                    UserDefaults.standard.set(cache, forKey: kUserDefalutShareCacheKey)
                    
                    shareHandler(url)
                }
            })
        }
        
        if let cache = cache, let filename = cache[photo.asset.localIdentifier] { // 有缓存
            let videoDirPath = kVideoDirPath
            let outputPath = videoDirPath.appending("\(filename)")
            shareHandler(URL(fileURLWithPath: outputPath))
        } else { // 无缓存
            if let fullImageData = photo.fullImageData {
                generateVideoHandler(fullImageData, photo.asset.localIdentifier)
            } else {
                if !isHudVisible {
                    showHudWithMsg(msg: "请稍候")
                }
                let requestOptions = PHImageRequestOptions()
                requestOptions.isSynchronous = false
                requestOptions.deliveryMode = .highQualityFormat
                requestOptions.resizeMode = .fast
                PHImageManager.default().requestImageData(for: photo.asset, options: requestOptions, resultHandler: {(data, type, orientation, info) in
                    if let fullImageData = data as NSData? {
                        photo.fullImageData = fullImageData
                        generateVideoHandler(fullImageData, photo.asset.localIdentifier)
                    }
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
