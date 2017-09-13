//
//  VideoPickerViewController.swift
//  Gifer
//
//  Created by Peter Lee on 2017/9/6.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import SnapKit
import Photos
import MJRefresh
import AVFoundation

class VideoPickerViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CAAnimationDelegate {

    private let kCellId = "VideoPickerCell"
    private var videoArray: [Video] = []
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
        collectionView.register(UINib(nibName: "VideoPickerCell", bundle: nil), forCellWithReuseIdentifier: self.kCellId)
        collectionView.mj_header = self.refreshHeader
        return collectionView
    }()
    private lazy var refreshHeader: MJRefreshNormalHeader = {
        let refreshHeader = MJRefreshNormalHeader(refreshingBlock: { [unowned self] in
            self.fetchPhotoFromLibrary()
        })
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
    private var kGroup: DispatchGroup = DispatchGroup()
    
    //MARK: Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
        collectionView.mj_header.beginRefreshing()
    }
    
    func configureSubviews() {
        title = "选择视频"
        
        view.addSubview(self.collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.right.equalTo(0)
            make.left.equalTo(0)
            make.bottom.equalTo(0)
        }
    }
    
    func fetchPhotoFromLibrary() {
        
        noRecordView.isHidden = true
        videoArray.removeAll()
        collectionView.reloadData()
        
        let option: PHFetchOptions = PHFetchOptions()
        option.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let result: PHFetchResult = PHAsset.fetchAssets(with: .video, options: option)
        
        kGroup = DispatchGroup()
        
        result.enumerateObjects({ (asset, index, _) in
            autoreleasepool{
                let requestOptions = PHVideoRequestOptions()
                requestOptions.deliveryMode = .highQualityFormat
                
                self.kGroup.enter()
                
                PHImageManager.default().requestAVAsset(forVideo: asset, options: requestOptions, resultHandler: { (asset, audioMix, info) in
                    guard let asset = asset else { return }
                    
                    let imageGenerator = AVAssetImageGenerator(asset: asset)
                    imageGenerator.appliesPreferredTrackTransform = true
                    
                    let cgImage = try? imageGenerator.copyCGImage(at: CMTime(value: 0, timescale: 1), actualTime: nil)
                    var thumbnail: UIImage? = nil
                    if cgImage != nil {
                        thumbnail = UIImage(cgImage: cgImage!)
                    }
                    
                    let video = Video(asset: asset, thumbnail: thumbnail)
                    self.videoArray.append(video)
                    
                    self.kGroup.leave()
                })
            }
        })
        self.kGroup.notify(queue: DispatchQueue.main, execute: { [unowned self] in
            if self.videoArray.count < 1 {
                self.noRecordView.isHidden = false
                self.showNotice(message: "未找到视频")
            } else {
                self.videoArray.sort(by: { (video1, video2) -> Bool in
                    guard let date1 = video1.asset.creationDate?.value as? Date else {
                        return false
                    }
                    guard let date2 = video2.asset.creationDate?.value as? Date else {
                        return true
                    }
                    return date1 > date2
                })
            }
            self.collectionView.mj_header.endRefreshing()
            self.collectionView.reloadData()
        })
    }
    
    //MARK: Delegate Method
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: VideoPickerCell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kCellId, for: indexPath) as! VideoPickerCell
        let video = videoArray[indexPath.row]
        cell.video = video;
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let video = videoArray[indexPath.row]
        
        let ctrl = VideoClipViewController(videoAsset: video.asset)
        self.navigationController!.pushViewController(ctrl, animated: true)
    }
    
}
