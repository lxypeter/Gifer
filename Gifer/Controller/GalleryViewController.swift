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
    
    enum AddButtonAnimateType {
        case enter
        case quit
    }
    
    private let kCellId = "GalleryCell"
    private let kAddViewEnterAnimation = "kAddViewEnterAnimation"
    private let kAddViewQuitAnimation = "kAddViewQuitAnimation"
    private let kPhotoViewEnterAnimation = "kphotoViewEnterAnimation"
    private let kPhotoViewQuitAnimation = "kphotoViewQuitAnimation"
    private let kRecordViewEnterAnimation = "kRecordViewEnterAnimation"
    private let kRecordViewQuitAnimation = "kRecordViewQuitAnimation"
    private let kVideoViewEnterAnimation = "kVideoViewEnterAnimation"
    private let kVideoViewQuitAnimation = "kVideoViewQuitAnimation"
    private let kAddButtonDistant: CGFloat = 120
    private let kAddButtonY: CGFloat = kScreenHeight - 60
    private let kAddButtonAnimationDuration: CFTimeInterval = 0.3
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
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 120, right: 0)
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
            self.clickDeleteButton()
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
    private lazy var selectItem: UIBarButtonItem = {
        let selectItem: UIBarButtonItem = UIBarButtonItem(title: "选择", style: .plain, target: self, action: #selector(clickSelectButton))
        selectItem.tintColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        selectItem.isEnabled = false
        return selectItem
    }()
    private lazy var addView: AddButtonView = {
        let addView = AddButtonView()
        addView.backgroundView.backgroundColor = #colorLiteral(red: 0.968627451, green: 0.7921568627, blue: 0.09411764706, alpha: 1)
        addView.layer.cornerRadius = 30
        addView.button.setBackgroundImage(#imageLiteral(resourceName: "add"), for: .normal)
        addView.button.setBackgroundImage(#imageLiteral(resourceName: "add_white"), for: .selected)
        addView.button.addTarget(self, action: #selector(clickAddButton), for: .touchUpInside)
        return addView
    }()
    private lazy var photoAddView: AddButtonView = {
        let photoAddView = AddButtonView()
        photoAddView.backgroundView.backgroundColor = #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1)
        photoAddView.layer.cornerRadius = 30
        photoAddView.button.setBackgroundImage(#imageLiteral(resourceName: "photoButton"), for: .normal)
        photoAddView.button.addTarget(self, action: #selector(clickPhotoButton), for: .touchUpInside)
        return photoAddView
    }()
    private lazy var videoAddView: AddButtonView = {
        let videoAddView = AddButtonView()
        videoAddView.backgroundView.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        videoAddView.layer.cornerRadius = 30
        videoAddView.button.setBackgroundImage(#imageLiteral(resourceName: "videoButton"), for: .normal)
        videoAddView.button.addTarget(self, action: #selector(clickVideoButton), for: .touchUpInside)
        return videoAddView
    }()
    private lazy var recordAddView: AddButtonView = {
        let recordAddView = AddButtonView()
        recordAddView.backgroundView.backgroundColor = #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)
        recordAddView.layer.cornerRadius = 30
        recordAddView.button.setBackgroundImage(#imageLiteral(resourceName: "recordButton"), for: .normal)
        recordAddView.button.addTarget(self, action: #selector(clickRecordButton), for: .touchUpInside)
        return recordAddView
    }()
    private lazy var photoAddLabel: UILabel = {
        let lable = UILabel()
        lable.text = "照片生成"
        lable.font = UIFont.systemFont(ofSize: 15)
        lable.textColor = UIColor.white
        lable.isHidden = true
        return lable
    }()
    private lazy var videoAddLabel: UILabel = {
        let lable = UILabel()
        lable.text = "视频生成"
        lable.font = UIFont.systemFont(ofSize: 15)
        lable.textColor = UIColor.white
        lable.isHidden = true
        return lable
    }()
    private lazy var recordAddLabel: UILabel = {
        let lable = UILabel()
        lable.text = "录制生成"
        lable.font = UIFont.systemFont(ofSize: 15)
        lable.textColor = UIColor.white
        lable.isHidden = true
        return lable
    }()
    private lazy var coverView: UIView = {
        let coverView = UIView()
//        coverView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
        
        let veView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        coverView.addSubview(veView)
        veView.snp.makeConstraints({ (make) in
            make.edges.equalTo(coverView)
        })
        coverView.isHidden = true
        return coverView
    }()
    private var isSelecting = false {
        didSet {
            addView.isHidden = isSelecting
        }
    }
    private var isAnimating = false
    private var kGroup: DispatchGroup = DispatchGroup()

    //MARK: Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
        checkLibAuth()
        collectionView.mj_header.beginRefreshing()
        NotificationCenter.default.addObserver(self, selector: #selector(fetchGIFFromLibrary), name: NSNotification.Name(rawValue: kNotiKeyGalleryUpdate), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(gifGenerated(_:)), name: NSNotification.Name(rawValue: kNotiKeyGifGenerated), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addView.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        addView.isHidden = true
    }
    
    func configureSubviews() {
        self.title = "Gifer"
        
        navigationItem.rightBarButtonItem = selectItem;
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.right.equalTo(0)
            make.left.equalTo(0)
            make.bottom.equalTo(0)
        }
        
        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { (make) in
            make.height.equalTo(GalleryViewBottomBar.height)
            make.right.equalTo(0)
            make.left.equalTo(0)
            make.bottom.equalTo(GalleryViewBottomBar.height)
        }
        
        UIApplication.shared.keyWindow!.addSubview(coverView)
        coverView.snp.makeConstraints { (make) in
            make.edges.equalTo(UIApplication.shared.keyWindow!.snp.edges)
        }
        
        coverView.addSubview(photoAddLabel)
        coverView.addSubview(videoAddLabel)
        coverView.addSubview(recordAddLabel)
        
        coverView.addSubview(photoAddView)
        photoAddView.snp.makeConstraints { (make) in
            make.width.equalTo(60)
            make.height.equalTo(60)
            make.centerY.equalTo(kAddButtonY)
            make.centerX.equalTo(kScreenWidth / 2)
        }
        
        coverView.addSubview(videoAddView)
        videoAddView.snp.makeConstraints { (make) in
            make.width.equalTo(60)
            make.height.equalTo(60)
            make.centerY.equalTo(kAddButtonY)
            make.centerX.equalTo(kScreenWidth / 2)
        }
        
        coverView.addSubview(recordAddView)
        recordAddView.snp.makeConstraints { (make) in
            make.width.equalTo(60)
            make.height.equalTo(60)
            make.centerY.equalTo(kAddButtonY)
            make.centerX.equalTo(kScreenWidth / 2)
        }
        
        UIApplication.shared.keyWindow!.addSubview(addView)
        addView.snp.makeConstraints { (make) in
            make.width.equalTo(60)
            make.height.equalTo(60)
            make.centerY.equalTo(kAddButtonY)
            make.centerX.equalTo(UIApplication.shared.keyWindow!.snp.centerX)
        }
        
    }
    
    func checkLibAuth(){
        let photoStatus = PHPhotoLibrary.authorizationStatus()
        if photoStatus == .denied {
            let alertViewController = UIAlertController(title: nil, message: "请在\"设置\"中允许访问相册", preferredStyle: .alert)
            let confrimAction = UIAlertAction(title: "确定", style: .default, handler: nil)
            alertViewController.addAction(confrimAction)
            present(alertViewController, animated: true, completion: nil)
        }
    }
    
    func fetchGIFFromLibrary() {
        
        noRecordView.isHidden = true
        gifArray.removeAll()
        collectionView.reloadData()
        
        let option: PHFetchOptions = PHFetchOptions()
        option.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let result: PHFetchResult = PHAsset.fetchAssets(with: .image, options: option)
        
        kGroup = DispatchGroup()
        
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
        kGroup.notify(queue: DispatchQueue.main, execute: { [unowned self] in
            self.collectionView.mj_header.endRefreshing()
            if self.gifArray.count < 1 {
                self.showNotice(message: "未找到GIF图片")
                self.noRecordView.isHidden = false
                self.selectItem.isEnabled = false
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
                self.selectItem.isEnabled = true
            }
            self.collectionView.reloadData()
        })
        
    }
    
    //MARK: Delegate Method
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: GalleryCell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kCellId, for: indexPath) as! GalleryCell
        let photo = gifArray[indexPath.row]
        cell.isEditing = isSelecting
        cell.photo = photo;
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.isSelecting {
            return
        }
        
        let photoController = PhotoViewController(gifArray: gifArray, currentIndex: indexPath.row)
        self.navigationController?.pushViewController(photoController, animated: true)
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if anim.isEqual(addView.layer.animation(forKey: kAddViewEnterAnimation)) {
            
            addView.button.isSelected = true
            isAnimating = false
            addView.snp.updateConstraints({ (make) in
                make.centerY.equalTo(kScreenHeight / 2)
            })
            
        } else if anim.isEqual(addView.layer.animation(forKey: kAddViewQuitAnimation)) {
            
            addView.button.isSelected = false
            isAnimating = false
            addView.snp.updateConstraints({ (make) in
                make.centerY.equalTo(kAddButtonY)
            })
            addView.layer.removeAllAnimations()
            
            // cover view
            coverView.isHidden = true
            
        } else if anim.isEqual(photoAddView.layer.animation(forKey: kPhotoViewEnterAnimation)) {
            
            photoAddView.snp.updateConstraints({ (make) in
                make.centerY.equalTo(kScreenHeight / 2 - kAddButtonDistant)
            })
            photoAddView.layer.removeAllAnimations()
            
            // label
            photoAddLabel.isHidden = false
            photoAddLabel.snp.updateConstraints({ (make) in
                make.top.equalTo(photoAddView.snp.bottom).offset(8)
                make.centerX.equalTo(photoAddView.snp.centerX)
            })
            
        } else if anim.isEqual(photoAddView.layer.animation(forKey: kPhotoViewQuitAnimation)) {
            
            photoAddView.snp.updateConstraints({ (make) in
                make.centerY.equalTo(kAddButtonY)
            })
            photoAddView.layer.removeAllAnimations()
            
        } else if anim.isEqual(videoAddView.layer.animation(forKey: kVideoViewEnterAnimation)) {
            
            let center = CGPoint(x: kScreenWidth / 2, y: kScreenHeight / 2)
            var videoCenter = CGPoint(x: kScreenWidth / 2, y: kScreenHeight / 2 - kAddButtonDistant)
            videoCenter = videoCenter.rotate(around: center, with: .pi * 2 / 3)
            videoAddView.snp.updateConstraints({ (make) in
                make.centerY.equalTo(videoCenter.y)
                make.centerX.equalTo(videoCenter.x)
            })
            videoAddView.layer.removeAllAnimations()
            
            // label
            videoAddLabel.isHidden = false
            videoAddLabel.snp.updateConstraints({ (make) in
                make.top.equalTo(videoAddView.snp.bottom).offset(8)
                make.centerX.equalTo(videoAddView.snp.centerX)
            })
            
        } else if anim.isEqual(videoAddView.layer.animation(forKey: kVideoViewQuitAnimation)) {
            
            videoAddView.snp.updateConstraints({ (make) in
                make.centerX.equalTo(kScreenWidth / 2)
                make.centerY.equalTo(kAddButtonY)
            })
            videoAddView.layer.removeAllAnimations()
            
        } else if anim.isEqual(recordAddView.layer.animation(forKey: kRecordViewEnterAnimation)) {
            
            let center = CGPoint(x: kScreenWidth / 2, y: kScreenHeight / 2)
            var recordCenter = CGPoint(x: kScreenWidth / 2, y: kScreenHeight / 2 - kAddButtonDistant)
            recordCenter = recordCenter.rotate(around: center, with: .pi * 2 * 2 / 3)
            recordAddView.snp.updateConstraints({ (make) in
                make.centerY.equalTo(recordCenter.y)
                make.centerX.equalTo(recordCenter.x)
            })
            recordAddView.layer.removeAllAnimations()
            
            // label
            recordAddLabel.isHidden = false
            recordAddLabel.snp.updateConstraints({ (make) in
                make.top.equalTo(recordAddView.snp.bottom).offset(8)
                make.centerX.equalTo(recordAddView.snp.centerX)
            })
            
        } else if anim.isEqual(recordAddView.layer.animation(forKey: kRecordViewQuitAnimation)) {
            
            recordAddView.snp.updateConstraints({ (make) in
                make.centerX.equalTo(kScreenWidth / 2)
                make.centerY.equalTo(kAddButtonY)
            })
            recordAddView.layer.removeAllAnimations()
            
        } else {
            if isSelecting {
                collectionView.snp.updateConstraints({ (make) in
                    make.bottom.equalTo(GalleryViewBottomBar.height)
                })
                bottomBar.snp.updateConstraints({ (make) in
                    make.bottom.equalTo(0)
                })
            } else {
                collectionView.snp.updateConstraints({ (make) in
                    make.bottom.equalTo(0)
                })
                bottomBar.snp.updateConstraints({ (make) in
                    make.bottom.equalTo(GalleryViewBottomBar.height)
                })
            }
            bottomBar.layer.removeAllAnimations()
        }
    }
    
    //MARK: events
    func clickAddButton() {
        if isAnimating { return }
        isAnimating = true
        if addView.button.isSelected { // quit
            // cover view
            photoAddLabel.isHidden = true
            videoAddLabel.isHidden = true
            recordAddLabel.isHidden = true
            coverView.layer.add(animationOfButtonBackground(type: .quit), forKey: nil)
            // add button view
            addView.layer.add(animationOfAddButton(type: .quit), forKey: kAddViewQuitAnimation)
            addView.backgroundView.layer.add(animationOfButtonBackground(type: .enter), forKey: nil)
            
            // photo button view
            photoAddView.layer.add(animationOfDetailAddButton(type: .quit, angle: 0), forKey: kPhotoViewQuitAnimation)
//            photoAddView.backgroundView.layer.add(animationOfButtonBackground(type: .quit), forKey: nil)
            
            // video button view
            videoAddView.layer.add(animationOfDetailAddButton(type: .quit, angle: .pi * 2 / 3), forKey: kVideoViewQuitAnimation)
//            videoAddView.backgroundView.layer.add(animationOfButtonBackground(type: .quit), forKey: nil)
            
            // record button view
            recordAddView.layer.add(animationOfDetailAddButton(type: .quit, angle: .pi * 2 * 2 / 3), forKey: kRecordViewQuitAnimation)
//            recordAddView.backgroundView.layer.add(animationOfButtonBackground(type: .quit), forKey: nil)
        } else { //enter
            // cover view
            coverView.isHidden = false
            coverView.layer.add(animationOfButtonBackground(type: .enter), forKey: nil)
            
            // add button view
            addView.layer.add(animationOfAddButton(type: .enter), forKey: kAddViewEnterAnimation)
            addView.backgroundView.layer.add(animationOfButtonBackground(type: .quit), forKey: nil)
            
            // photo button view
            photoAddView.layer.add(animationOfDetailAddButton(type: .enter, angle: 0), forKey: kPhotoViewEnterAnimation)
//            photoAddView.backgroundView.layer.add(animationOfButtonBackground(type: .enter), forKey: nil)
            
            // video button view
            videoAddView.layer.add(animationOfDetailAddButton(type: .enter, angle: .pi * 2 / 3), forKey: kVideoViewEnterAnimation)
//            videoAddView.backgroundView.layer.add(animationOfButtonBackground(type: .enter), forKey: nil)
            
            // record button view
            recordAddView.layer.add(animationOfDetailAddButton(type: .enter, angle: .pi * 2 * 2 / 3), forKey: kRecordViewEnterAnimation)
//            recordAddView.backgroundView.layer.add(animationOfButtonBackground(type: .enter), forKey: nil)
        }
    }
    
    func clickPhotoButton() {
        if isAnimating { return }
        clickAddButton()
        let ctrl = PhotoPickerViewController()
        navigationController!.pushViewController(ctrl, animated: true)
    }
    
    func clickVideoButton() {
        if isAnimating { return }
        clickAddButton()
        let ctrl = VideoPickerViewController()
        navigationController!.pushViewController(ctrl, animated: true)
    }
    
    func clickRecordButton() {
        if isAnimating { return }
        clickAddButton()
        let ctrl = VideoRecordViewController()
        navigationController!.pushViewController(ctrl, animated: true)
    }
    
    func clickSelectButton() {
        isSelecting = !isSelecting
        
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "position")
        animation.delegate = self
        if isSelecting {
            selectItem.title = "取消"
            animation.byValue = CGPoint(x: 0, y: -GalleryViewBottomBar.height)
            collectionView.mj_header = nil
        } else {
            selectItem.title = "选择"
            animation.byValue = CGPoint(x: 0, y: GalleryViewBottomBar.height)
            collectionView.mj_header = refreshHeader
        }
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards;
        bottomBar.layer.add(animation, forKey: nil)
        collectionView.reloadData()
    }
    
    func clickDeleteButton() {
        guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems, selectedIndexPaths.count > 0 else {
            showNotice(message: "请至少选择一张照片")
            return
        }
        clickSelectButton()
        
        var preDeleteAsset: [PHAsset] = []
        for indexPath in selectedIndexPaths {
            let photo = gifArray[indexPath.row]
            preDeleteAsset.append(photo.asset)
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(NSArray(array: preDeleteAsset))
        }, completionHandler: { [unowned self] (success, error) in
            DispatchQueue.main.async {
                if !success {
                    self.showNotice(message: "删除失败")
                } else {
                    var gifArray: [Photo] = []
                    for (index, photo) in self.gifArray.enumerated() {
                        var isDeleted = false
                        for indexPath in selectedIndexPaths {
                            if indexPath.row == index {
                                isDeleted = true
                            }
                        }
                        if !isDeleted {
                            gifArray.append(photo)
                        }
                    }
                    self.gifArray = gifArray
                    self.collectionView.reloadData()
                    self.showNotice(message: "删除成功！")
                }
            }
        })
    }
    
    func gifGenerated(_ notification: NSNotification) {
        let ctrl = GifAchieveViewController()
        ctrl.imageUrl = notification.object as? URL
        UIApplication.shared.delegate?.window??.rootViewController?.present(ctrl, animated: true, completion: nil)
    }
    
    //MARK: animation
    func generateRotatePath(center: CGPoint, rotateAngle: CGFloat) -> UIBezierPath {
        let rotatePath = UIBezierPath()
        let targetDistant: CGFloat = kAddButtonDistant
        let distantUnit: CGFloat = targetDistant / 10
        rotatePath.move(to: center)
        
        let firstRadius = distantUnit * 3
        let firstCenter = CGPoint(x: center.x + firstRadius, y: center.y)
        let rotatedFirstCenter = firstCenter.rotate(around: center, with: rotateAngle)
        rotatePath.addArc(withCenter: rotatedFirstCenter, radius: firstRadius, startAngle: -.pi + rotateAngle , endAngle: -.pi / 2 * 3 + rotateAngle, clockwise: false)
        
        let secondRadius = distantUnit * 5
        let secondCenter = CGPoint(x: firstCenter.x, y: firstCenter.y - 2 * distantUnit)
        let rotatedSecondCenter = secondCenter.rotate(around: center, with: rotateAngle)
        rotatePath.addArc(withCenter: rotatedSecondCenter, radius: secondRadius, startAngle: -.pi / 2 * 3 + rotateAngle, endAngle: -.pi * 2 + rotateAngle, clockwise: false)
        
        let thirdRadius = distantUnit * 8
        var thirdCenter = CGPoint(x: center.x, y: center.y - 2 * distantUnit)
        thirdCenter = thirdCenter.rotate(around: center, with: rotateAngle)
        rotatePath.addArc(withCenter: thirdCenter, radius: thirdRadius, startAngle: rotateAngle, endAngle: -.pi / 2 + rotateAngle, clockwise: false)
        
        return rotatePath
    }
    
    func animationOfButtonBackground(type: AddButtonAnimateType) -> CABasicAnimation {
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "opacity")
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards;
        animation.duration = kAddButtonAnimationDuration
        switch type {
        case .enter:
            animation.fromValue = 0
            animation.toValue = 1
        case .quit:
            animation.fromValue = 1
            animation.toValue = 0
        }
        return animation
    }
    
    func animationOfDetailAddButton(type: AddButtonAnimateType, angle: CGFloat) -> CAAnimationGroup {
        let animationGroup: CAAnimationGroup = CAAnimationGroup()
        animationGroup.delegate = self
        animationGroup.isRemovedOnCompletion = false
        animationGroup.fillMode = kCAFillModeForwards;
        animationGroup.duration = kAddButtonAnimationDuration
        let posiAnimation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "position")
        posiAnimation.calculationMode = kCAAnimationPaced;
        let posiYAnimation: CABasicAnimation = CABasicAnimation(keyPath: "position.y")
        
        switch type {
        case .enter:
            animationGroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            posiAnimation.path = generateRotatePath(center: CGPoint(x: kScreenWidth / 2, y: kAddButtonY), rotateAngle: angle ).cgPath
            posiYAnimation.byValue = kScreenHeight / 2 - kAddButtonY
        case .quit:
            animationGroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            posiAnimation.path = generateRotatePath(center: CGPoint(x: kScreenWidth / 2, y: kScreenHeight / 2), rotateAngle: angle ).reversing().cgPath
            posiYAnimation.byValue = kAddButtonY - kScreenHeight / 2
        }
        animationGroup.animations = [posiAnimation, posiYAnimation]
        return animationGroup
    }
    
    func animationOfAddButton(type: AddButtonAnimateType) -> CAAnimationGroup {
        let animationGroup: CAAnimationGroup = CAAnimationGroup()
        animationGroup.delegate = self
        animationGroup.isRemovedOnCompletion = false
        animationGroup.fillMode = kCAFillModeForwards;
        animationGroup.duration = kAddButtonAnimationDuration
        let posiAnimation: CABasicAnimation = CABasicAnimation(keyPath: "position.y")
        let rotateAnimation: CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation")
        
        switch type {
        case .enter:
            posiAnimation.toValue = kScreenHeight / 2
            rotateAnimation.toValue = Double.pi * -2.25
        case .quit:
            animationGroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            posiAnimation.toValue = kAddButtonY
            rotateAnimation.toValue = Double.pi * 2.25
        }
        animationGroup.animations = [posiAnimation, rotateAnimation]
        return animationGroup
    }
    
}
