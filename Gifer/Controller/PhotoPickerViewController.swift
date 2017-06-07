//
//  PhotoPickerViewController.swift
//  Gifer
//
//  Created by Peter Lee on 2017/6/7.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import SnapKit
import Photos
import MJRefresh

class PhotoPickerViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CAAnimationDelegate {
    
    private let kCellId = "PhotoPickerCell"
    private var photoArray: [Photo] = []
    private var selectdArray: [Photo] = []
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
        collectionView.register(UINib(nibName: "PhotoPickerCell", bundle: nil), forCellWithReuseIdentifier: self.kCellId)
        collectionView.mj_header = self.refreshHeader
        
        return collectionView
    }()
    private lazy var refreshHeader: MJRefreshNormalHeader = {
        let refreshHeader = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(fetchPhotoFromLibrary))
        refreshHeader?.setTitle("下拉重新加载", for: .idle)
        refreshHeader?.setTitle("松开开始加载", for: .pulling)
        refreshHeader?.setTitle("正在加载", for: .refreshing)
        refreshHeader?.lastUpdatedTimeLabel.isHidden = true
        return refreshHeader!
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
    
    //MARK: Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureSubviews()
        self.collectionView.mj_header.beginRefreshing()
    }
    
    func configureSubviews() {
        self.title = "选择图片"
        
        let nextItem: UIBarButtonItem = UIBarButtonItem(title: "下一步", style: .plain, target: self, action: #selector(clickNextButton))
        nextItem.tintColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        self.navigationItem.rightBarButtonItem = nextItem;
        
        self.view.addSubview(self.collectionView)
        self.collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.right.equalTo(0)
            make.left.equalTo(0)
            make.bottom.equalTo(0)
        }
    }
    
    func fetchPhotoFromLibrary() {
        
        self.noRecordView.isHidden = true
        
        var photoArray: [Photo] = []
        
        self.collectionView.reloadData()
        
        let option: PHFetchOptions = PHFetchOptions()
        option.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let result: PHFetchResult = PHAsset.fetchAssets(with: .image, options: option)
        result.enumerateObjects({ (asset, index, _) in
            autoreleasepool{
                guard let uti = asset.value(forKey: "uniformTypeIdentifier"), uti as! String != "com.compuserve.gif" else {
                    return
                }
                
                let photo = Photo(asset: asset)
                
                let requestOptions = PHImageRequestOptions()
                requestOptions.isSynchronous = true
                requestOptions.deliveryMode = .highQualityFormat
                // 按比例
                requestOptions.resizeMode = .exact
                requestOptions.normalizedCropRect = CGRect(x: 0, y: 0, width: 1, height: 1)
                
                let itemWidth: Double = Double(UIScreen.main.bounds.width/2)
                let itemSize = CGSize(width: itemWidth, height: itemWidth)
                
                PHImageManager.default().requestImage(for: asset, targetSize: itemSize, contentMode: .aspectFill, options: requestOptions, resultHandler: { (image, info) in
                    photo.thumbnail = image
                    photoArray.append(photo)
                })
            }
        })
        
        self.photoArray = photoArray
        self.collectionView.mj_header.endRefreshing()
        
        if self.photoArray.count < 1 {
            self.noRecordView.isHidden = false
            self.showNotice(message: "未找到图片")
        } else {
        }
        self.collectionView.reloadData()
    }
    
    //MARK: Delegate Method
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photoArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: PhotoPickerCell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kCellId, for: indexPath) as! PhotoPickerCell
        let photo = self.photoArray[indexPath.row]
        
        if self.selectdArray.contains(photo) {
            cell.isChoose = true
            let index = self.selectdArray.index(of: photo)!
            cell.selectedRankLabel.text = "\(index+1)"
        } else {
            cell.isChoose = false
        }
        cell.photo = photo;
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photo = self.photoArray[indexPath.row]
        if self.selectdArray.contains(photo) {
            let index = self.selectdArray.index(of: photo)!
            self.selectdArray.remove(at: index)
        } else {
            self.selectdArray.append(photo)
        }
        collectionView.reloadData()
    }
    
    //MARK: events
    func clickNextButton() {
        
    }
}
