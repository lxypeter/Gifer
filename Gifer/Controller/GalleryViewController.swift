//
//  GalleryViewController.swift
//  Gifer
//
//  Created by Peter Lee on 2017/5/23.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import Photos
import SnapKit
import MobileCoreServices
import MJRefresh

class GalleryViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CAAnimationDelegate {
    
    private let kCellId = "GalleryCell"
    private var gifArray: [Photo] = []
    private lazy var collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        let itemWidth: Double =  Double((UIScreen.main.bounds.width - 3 * layout.minimumInteritemSpacing)/4)
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)

        let collectionView = UICollectionView(frame: CGRect.zero,collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        collectionView.register(UINib(nibName: "GalleryCell", bundle: nil), forCellWithReuseIdentifier: self.kCellId)
        collectionView.allowsMultipleSelection = true
        collectionView.allowsSelection = true
        collectionView.mj_header = self.refreshHeader
        
        return collectionView
    }()
    private lazy var refreshHeader: MJRefreshNormalHeader = {
        let refreshHeader = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(fetchGIFFromLibrary))
        refreshHeader?.setTitle("下拉重新加载", for: .idle)
        refreshHeader?.setTitle("松开开始加载", for: .pulling)
        refreshHeader?.setTitle("正在加载", for: .refreshing)
        refreshHeader?.lastUpdatedTimeLabel.isHidden = true
        return refreshHeader!
    }()
    private lazy var bottomBar: GalleryViewBottomBar = {
        let bottomBar = GalleryViewBottomBar()
        
        bottomBar.deleteButtonHandler = { [unowned self] in
            guard let selectedIndexPaths = self.collectionView.indexPathsForSelectedItems, selectedIndexPaths.count > 0 else {
                self.showNotice(message: "请至少选择一张照片")
                return
            }
            
            var preDeleteAsset: [PHAsset] = []
            for indexPath in selectedIndexPaths {
                let photo = self.gifArray[indexPath.row]
                preDeleteAsset.append(photo.asset)
            }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(NSArray(array: preDeleteAsset))
            }, completionHandler: { [unowned self] (success, error) in
                DispatchQueue.main.async {
                    if !success {
                        self.showNotice(message: "删除失败")
                    } else {
                        for indexPath in selectedIndexPaths {
                            self.gifArray.remove(at: indexPath.row)
                        }
                        self.collectionView.reloadData()
                        self.showNotice(message: "删除成功！")
                    }
                }
            })
        }
        bottomBar.shareButtonHandler = {
            printLog("click share")
        }
        return bottomBar;
    }()
    private lazy var noRecordView: NoRecordView = {
        let noRecordView = NoRecordView()
        self.view.addSubview(noRecordView)
        self.view.bringSubview(toFront: noRecordView)
        noRecordView.snp.makeConstraints({ (make) in
            make.edges.equalTo(self.view)
        })
        noRecordView.reloadHandler = { [unowned self] in
            self.collectionView.mj_header.beginRefreshing()
        }
        return noRecordView
    }()
    private let kBottomBarHeight = 44
    private var isSelecting = false
    private var kGroup: DispatchGroup = DispatchGroup()

    //MARK: Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureSubviews()
        self.collectionView.mj_header.beginRefreshing()
    }
    
    func configureSubviews() {
        self.title = "Gifer"
        
        let selectItem: UIBarButtonItem = UIBarButtonItem(title: "选择", style: .plain, target: self, action: #selector(clickSelectButton))
        selectItem.tintColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        selectItem.isEnabled = false
        self.navigationItem.leftBarButtonItem = selectItem;
        
        let addItem: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(clickAddButton))
        addItem.tintColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        self.navigationItem.rightBarButtonItem = addItem;
        
        self.view.addSubview(self.collectionView)
        self.collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.right.equalTo(0)
            make.left.equalTo(0)
            make.bottom.equalTo(0)
        }
        
        self.view.addSubview(self.bottomBar)
        self.bottomBar.snp.makeConstraints { (make) in
            make.height.equalTo(kBottomBarHeight)
            make.right.equalTo(0)
            make.left.equalTo(0)
            make.bottom.equalTo(kBottomBarHeight)
        }
    }
    
    func fetchGIFFromLibrary() {
        
        self.noRecordView.isHidden = true
        self.gifArray.removeAll()
        self.collectionView.reloadData()
        
        let option: PHFetchOptions = PHFetchOptions()
        option.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let result: PHFetchResult = PHAsset.fetchAssets(with: .image, options: option)
        
        self.kGroup = DispatchGroup()
        
        result.enumerateObjects({ (asset, index, _) in
            autoreleasepool{
                guard let uti = asset.value(forKey: "uniformTypeIdentifier"), uti as! String == "com.compuserve.gif" else {
                    return
                }
                
                let photo = Photo(asset: asset)
                
                let requestOptions = PHImageRequestOptions()
                requestOptions.isSynchronous = false
                requestOptions.deliveryMode = .highQualityFormat
                // 按比例
                requestOptions.resizeMode = .exact
                requestOptions.normalizedCropRect = CGRect(x: 0, y: 0, width: 1, height: 1)
                
                let itemWidth: Double = Double(UIScreen.main.bounds.width/2)
                let itemSize = CGSize(width: itemWidth, height: itemWidth)
                
                self.kGroup.enter()
                
                PHImageManager.default().requestImage(for: asset, targetSize: itemSize, contentMode: .aspectFill, options: requestOptions, resultHandler: { [unowned self] (image, info) in
                    photo.thumbnail = image
                    self.gifArray.append(photo)
                    
                    self.kGroup.leave()
                })
            }
        })
        self.kGroup.notify(queue: DispatchQueue.main, execute: { [unowned self] in
            self.collectionView.mj_header.endRefreshing()
            if self.gifArray.count < 1 {
                self.noRecordView.isHidden = false
                self.navigationItem.leftBarButtonItem?.isEnabled = false
                self.showNotice(message: "未找到GIF图片")
            } else {
                self.gifArray.sort(by: { (photo1, photo2) -> Bool in
                    guard let date1 = photo1.asset.creationDate else {
                        return false
                    }
                    guard let date2 = photo2.asset.creationDate else {
                        return true
                    }
                    return date1 > date2
                })
                self.navigationItem.leftBarButtonItem?.isEnabled = true
            }
            self.collectionView.reloadData()
        })
        
    }
    
    //MARK: Delegate Method
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.gifArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: GalleryCell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kCellId, for: indexPath) as! GalleryCell
        let photo = self.gifArray[indexPath.row]
        cell.isEditing = self.isSelecting
        cell.photo = photo;
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.isSelecting {
            return
        }
        
        let photoController = PhotoViewController(gifArray: self.gifArray, currentIndex: indexPath.row)
        self.navigationController?.pushViewController(photoController, animated: true)
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if self.isSelecting {
            self.collectionView.snp.updateConstraints({ (make) in
                make.bottom.equalTo(kBottomBarHeight)
            })
            self.bottomBar.snp.updateConstraints({ (make) in
                make.bottom.equalTo(0)
            })
        } else {
            self.collectionView.snp.updateConstraints({ (make) in
                make.bottom.equalTo(0)
            })
            self.bottomBar.snp.updateConstraints({ (make) in
                make.bottom.equalTo(kBottomBarHeight)
            })
        }
        self.bottomBar.layer.removeAllAnimations()
    }
    
    //MARK: events
    func clickSelectButton() {
        self.isSelecting = !self.isSelecting
        
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "position")
        animation.delegate = self
        if self.isSelecting {
            self.navigationItem.leftBarButtonItem?.title = "取消"
            animation.byValue = CGPoint(x: 0, y: -kBottomBarHeight)
            self.collectionView.mj_header = nil
        } else {
            self.navigationItem.leftBarButtonItem?.title = "选择"
            animation.byValue = CGPoint(x: 0, y: kBottomBarHeight)
            self.collectionView.mj_header = self.refreshHeader
        }
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards;
        self.bottomBar.layer.add(animation, forKey: nil)
        self.collectionView.reloadData()
    }
    
    func clickAddButton() {
        let ctrl = PhotoPickerViewController()
        self.navigationController?.pushViewController(ctrl, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        for photo in self.gifArray {
            photo.fullImageData = nil
        }
    }
}
