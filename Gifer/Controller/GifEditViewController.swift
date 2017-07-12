//
//  GifEditViewController.swift
//  Gifer
//
//  Created by Peter Lee on 2017/6/9.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import SnapKit
import Photos
import ImageIO
import MobileCoreServices

class GifEditViewController: BaseViewController {
    //MARK: property
    var selectedArray: [Photo] = [] {
        didSet {
            if self.selectedArray.count < 1 {
                return
            }
            let height: CGFloat = self.selectedArray[0].photoHeight
            let width: CGFloat = self.selectedArray[0].photoWidth
            for index in 0 ..< self.selectedArray.count {
                let photo = self.selectedArray[index]
                if width != photo.photoWidth || height != photo.photoHeight {
                    self.isSameSize = false
                    return
                }
            }
        }
    }
    private var imageArray: [UIImage] = []
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.backgroundColor = UIColor.white
        imageView.animationDuration = self.bottomBar.originDuration * Double(self.selectedArray.count)
        let pinchGes = UIPinchGestureRecognizer(target: self, action: #selector(pinchImageView(recognizer:)))
        imageView.addGestureRecognizer(pinchGes)
        return imageView
    }()
    private lazy var bottomBar: GifEditViewBottomBar = {
        let bottomBar = GifEditViewBottomBar(frame: CGRect.zero)
        bottomBar.totalCount = self.selectedArray.count
        bottomBar.resetButtonHandler = {
            self.imageView.transform = .identity
            //masklayer
            let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: self.contentView.frame.size.width, height: self.contentView.frame.size.height))
            let showRect = self.imageView.frame
            let showPath = UIBezierPath(rect: showRect).reversing()
            path.append(showPath)
            self.maskLayer.path = path.cgPath
            
            //edgeView
            self.leftUpEdgeView.center = showRect.origin
            self.leftDownEdgeView.center = CGPoint(x: showRect.minX, y: showRect.maxY)
            self.rightUpEdgeView.center = CGPoint(x: showRect.maxX, y: showRect.minY)
            self.rightDownEdgeView.center = CGPoint(x: showRect.maxX, y: showRect.maxY)
        }
        bottomBar.sliderValueChangeHandler = { [unowned self] value in
            self.imageView.animationDuration = Double(String(format: "%.2f", value))! * Double(self.selectedArray.count)
            self.imageView.startAnimating()
        }
        return bottomBar
    }()
    private lazy var toolBar: GifEditToolBar = {
        let toolBar = GifEditToolBar(frame: CGRect.zero)
        toolBar.clipButtonHandler = {[unowned self] in
            self.switchToClipingMode(true)
        }
        toolBar.clipConfirmButtonHandler = {[unowned self] in
            self.switchToClipingMode(false)
        }
        toolBar.clipCancelButtonHandler = {[unowned self] in
            self.switchToClipingMode(false)
        }
        return toolBar
    }()
    private lazy var contentView: UIView = {
        let contentView = UIView(frame: CGRect.zero)
        contentView.clipsToBounds = true
        contentView.backgroundColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        // ImageView拖放手势
        let panGes = UIPanGestureRecognizer(target: self, action: #selector(panImageView(recognizer:)))
        contentView.addGestureRecognizer(panGes)
        return contentView
    }()
    private lazy var maskLayer: CAShapeLayer = {
        let maskLayer = CAShapeLayer()
        let fillColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        maskLayer.fillColor = fillColor.cgColor
        maskLayer.opacity = 0.5
        return maskLayer
    }()
    private lazy var leftUpEdgeView: UIView = {
        let leftUpEdgeView = self.configureEdgeView()
        return leftUpEdgeView
    }()
    private lazy var rightUpEdgeView: UIView = {
        let rightUpEdgeView = self.configureEdgeView()
        return rightUpEdgeView
    }()
    private lazy var rightDownEdgeView: UIView = {
        let rightDownEdgeView = self.configureEdgeView()
        return rightDownEdgeView
    }()
    private lazy var leftDownEdgeView: UIView = {
        let leftDownEdgeView = self.configureEdgeView()
        return leftDownEdgeView
    }()
    
    private let kEdgeViewWidth: CGFloat = 30
    private var isSameSize = true
    private var showingRect: CGRect = CGRect.zero
    private var kGroup: DispatchGroup = DispatchGroup()
    private var isCliping: Bool = false
    
    //MARK: life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureSubviews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.fetchFullImage()
        
        //masklayer
        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: self.contentView.frame.size.width, height: self.contentView.frame.size.height))
        let showRect = self.imageView.frame
        let showPath = UIBezierPath(rect: showRect).reversing()
        path.append(showPath)
        self.maskLayer.path = path.cgPath
        
        //edgeView
        self.leftUpEdgeView.center = showRect.origin
        self.leftDownEdgeView.center = CGPoint(x: showRect.minX, y: showRect.maxY)
        self.rightUpEdgeView.center = CGPoint(x: showRect.maxX, y: showRect.minY)
        self.rightDownEdgeView.center = CGPoint(x: showRect.maxX, y: showRect.maxY)
        
    }
    
    private func configureSubviews() {
        self.title = "编辑"
        self.extendedLayoutIncludesOpaqueBars = true
        
        let generateItem: UIBarButtonItem = UIBarButtonItem(title: "生成", style: .plain, target: self, action: #selector(clickGenerateButton))
        generateItem.tintColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        self.navigationItem.rightBarButtonItem = generateItem;
        
        self.view.addSubview(self.toolBar)
        self.toolBar.snp.makeConstraints { (make) in
            make.top.equalTo(kNavigationBarHeight + kStatusBarHeight)
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.height.equalTo(GifEditToolBar.height)
        }
        
        self.view.addSubview(self.bottomBar)
        self.bottomBar.snp.makeConstraints { (make) in
            make.bottom.equalTo(0)
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.height.equalTo(GifEditViewBottomBar.height)
        }
        
        self.view.addSubview(self.contentView)
        self.contentView.snp.makeConstraints { (make) in
            make.top.equalTo(self.toolBar.snp.bottom).offset(0)
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.bottom.equalTo(self.bottomBar.snp.top).offset(0)
        }
        
        let contentViewHeight: CGFloat = kScreenHeight - kStatusBarHeight - kNavigationBarHeight - GifEditViewBottomBar.height - GifEditToolBar.height
        self.contentView.addSubview(self.imageView)
        self.imageView.snp.makeConstraints { (make) in
            make.center.equalTo(self.contentView.snp.center)
            var imageViewRatio: CGFloat = 1.0
            if self.isSameSize {
                let width: CGFloat = self.selectedArray[0].photoWidth
                let height: CGFloat = self.selectedArray[0].photoHeight
                imageViewRatio = width / height
            }
            if imageViewRatio >= kScreenWidth / contentViewHeight {
                make.width.equalTo(kScreenWidth)
                make.height.equalTo(self.imageView.snp.width).multipliedBy(1/imageViewRatio)
            } else {
                make.height.equalTo(contentViewHeight)
                make.width.equalTo(self.imageView.snp.height).multipliedBy(imageViewRatio)
            }
        }
        
        self.contentView.addSubview(self.leftUpEdgeView)
        self.contentView.addSubview(self.rightUpEdgeView)
        self.contentView.addSubview(self.rightDownEdgeView)
        self.contentView.addSubview(self.leftDownEdgeView)
        
        self.contentView.layer.addSublayer(self.maskLayer)
        
    }
    
    private func configureEdgeView() -> UIView {
        let edgeView = UIView(frame: CGRect(x: 0, y: 0, width: self.kEdgeViewWidth, height: self.kEdgeViewWidth))
        edgeView.isHidden = true
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panEdgeView(recognizer:)))
        edgeView.addGestureRecognizer(gesture)
        edgeView.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        return edgeView
    }
    
    /// 获取完整大图
    private func fetchFullImage() {
        self.showHudWithMsg(msg: "")
        self.kGroup = DispatchGroup()
        for photo in self.selectedArray {
            self.kGroup.enter()
            if photo.fullImage === nil {
                let requestOptions = PHImageRequestOptions()
                requestOptions.isSynchronous = false
                requestOptions.deliveryMode = .opportunistic
                requestOptions.resizeMode = .none
                
                PHImageManager.default().requestImageData(for: photo.asset, options: requestOptions, resultHandler: { [unowned self](data, type, orientation, info) in
                    if let data = data {
                        photo.fullImageData = data as NSData
                    }
                    self.kGroup.leave()
                })
            } else {
                self.kGroup.leave()
            }
        }
        self.kGroup.notify(queue: DispatchQueue.main) { [unowned self] in 
            self.hideHud()
            for  photo in self.selectedArray {
                if photo.fullImage != nil {
                    self.imageArray.append(photo.fullImage!)
                }
            }
            self.imageView.animationImages = self.imageArray
            self.imageView.startAnimating()
        }
    }
    
    private func generateGif() {
        self.showHudWithMsg(msg: "正在生成...")
        
        let fileProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]] as CFDictionary;
        
        let frameProperties: CFDictionary = [
            kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: self.bottomBar.currentDuration],
            kCGImagePropertyPixelHeight as String: 400,
            kCGImagePropertyPixelWidth as String: 400
            ] as CFDictionary;
        
        let dataFormatter = DateFormatter()
        dataFormatter.dateFormat = "YYYYMMddHHmmss"
        let filename = dataFormatter.string(from: Date())
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(filename).gif")
        DispatchQueue.global().async { [unowned self] in
            let destination: CGImageDestination? = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeGIF, self.selectedArray.count, nil);
            if destination == nil { self.showNotice(message: "生成Gif失败...") }
            CGImageDestinationSetProperties(destination!, fileProperties);
            
            for photo in self.selectedArray {
                if photo.fullImage != nil {
                    let newImage = photo.fullImage?.imageKeepRatioScalingWith(targetSize: CGSize(width: 400, height: 400))
                    CGImageDestinationAddImage(destination!, newImage!.cgImage!, frameProperties);
                }
            }
            
            if CGImageDestinationFinalize(destination!) {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                }) { (success, error) in
                    DispatchQueue.main.async { [unowned self] in
                        self.hideHud()
                        if success {
                            self.navigationController?.popToRootViewController(animated: true)
                            self.showNotice(message: "生成Gif成功！")
                        }
                    }
                }
            } else {
                DispatchQueue.main.async { [unowned self] in
                    self.hideHud()
                    self.showNotice(message: "生成Gif失败...")
                }
            }
        }
    }
    
    //MARK: event
    func clickGenerateButton() {
        let alertController = UIAlertController(title: "选择Gif画质", message: nil, preferredStyle: .actionSheet)
        let lowQualityAction = UIAlertAction(title: "低清晰度", style: .default) { [unowned self](action) in
            self.generateGif()
        }
        alertController.addAction(lowQualityAction)
        let mediumQualityAction = UIAlertAction(title: "中等清晰度", style: .default) { [unowned self](action) in
            self.generateGif()
        }
        alertController.addAction(mediumQualityAction)
        let highQualityAction = UIAlertAction(title: "高清晰度", style: .default) { [unowned self](action) in
            self.generateGif()
        }
        alertController.addAction(highQualityAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func pinchImageView(recognizer: UIPinchGestureRecognizer) {
        if !self.isCliping { return }
        if recognizer.state != .changed {
            return
        }
        let scale = recognizer.scale
        let location = recognizer.location(in: self.contentView)
        
        let scaleTransform = self.imageView.transform.scaledBy(x: scale, y: scale)
        recognizer.view!.transform = scaleTransform
        
        if self.imageView.frame.size.height < self.imageView.bounds.size.height {
            recognizer.view!.transform = .identity
            return
        }
        
        let dx = recognizer.view!.frame.midX - location.x
        let dy = recognizer.view!.frame.midY - location.y
        let x = dx * scale - dx
        let y = dy * scale - dy
        
        let translationTransform = CGAffineTransform(translationX: x, y: y)
        recognizer.view!.transform = recognizer.view!.transform.concatenating(translationTransform)
        
        recognizer.scale = 1
    }
    
    func panImageView(recognizer: UIPanGestureRecognizer) {
        
        if !self.isCliping { return }
        
        let frame = self.imageView.frame
        let touchPoint = recognizer.location(in: self.imageView)
        
        // 触碰点是否在ImageView
        let isInFrame = touchPoint.x > 0 && touchPoint.y > 0 && touchPoint.x < frame.size.width && touchPoint.y < frame.size.height
        if !isInFrame { return }
        
        let translation = recognizer.translation(in: self.view)
        let contentViewHeight = self.contentView.frame.size.height
        let lastScale = self.imageView.frame.size.width / self.imageView.bounds.size.width
        var translationX = translation.x
        var translationY = translation.y / lastScale
        
        let verticalEdge = (contentViewHeight - (self.rightDownEdgeView.center.y - self.leftUpEdgeView.center.y)) / 2
        let horizontalEdge = (kScreenWidth - (self.rightDownEdgeView.center.x - self.leftUpEdgeView.center.x)) / 2
        
        // 控制边界
        if frame.origin.x + translationX > horizontalEdge { translationX = horizontalEdge - frame.origin.x } // 左
        if frame.origin.y + translationY > verticalEdge { translationY = verticalEdge - frame.origin.y } // 上
        if frame.maxX + translationX < kScreenWidth - horizontalEdge { translationX = kScreenWidth - horizontalEdge - frame.maxX  } // 右
        if frame.maxY + translationY < contentViewHeight - verticalEdge { translationY  = contentViewHeight - verticalEdge - frame.maxY } // 下
        
        let transform = self.imageView.transform.translatedBy(x: translationX / lastScale, y: translationY)
        imageView.transform = transform
        
        recognizer.setTranslation(CGPoint.zero, in: self.view)
    }
    
    func panEdgeView(recognizer: UIPanGestureRecognizer) {
        if !self.isCliping { return }
        
        if recognizer.state == .ended {
            let leftUpPoint = self.contentView.convert(self.leftUpEdgeView.center, to: self.imageView)
            let rightDownPoint = self.contentView.convert(self.rightDownEdgeView.center, to: self.imageView)
            
            let contentViewHeight = self.contentView.frame.size.height
            
            let targetWidth = rightDownPoint.x - leftUpPoint.x
            let targetHeight = rightDownPoint.y - leftUpPoint.y
            
            var maskWidth: CGFloat = 0
            var maskHeight: CGFloat = 0
            var maskX: CGFloat = 0
            var maskY: CGFloat = 0
            var scale: CGFloat = 1
            if targetHeight / targetWidth < contentViewHeight / kScreenWidth {
                maskWidth = kScreenWidth
                maskHeight = targetHeight / targetWidth * kScreenWidth
                maskY = (contentViewHeight - maskHeight) / 2
                scale = kScreenWidth / targetWidth
            } else {
                maskHeight = contentViewHeight
                maskWidth = targetWidth / targetHeight * maskHeight
                maskX = (kScreenWidth - maskWidth) / 2
                scale = contentViewHeight / targetHeight
            }
            
            let maskRect = CGRect(x: maskX, y: maskY, width: maskWidth, height: maskHeight)
            
            self.updateMaskAndEdgeView(with: maskRect, animated: true)
            
            // 缩放
            self.imageView.transform = .identity
            let scaleTransform = self.imageView.transform.scaledBy(x: scale, y: scale)
            self.imageView.transform = scaleTransform
            
            // 位移
            let targetCenterX = (leftUpPoint.x + rightDownPoint.x) / 2
            let targetCenterY = (leftUpPoint.y + rightDownPoint.y) / 2
            let dx = self.imageView.bounds.midX - targetCenterX
            let dy = self.imageView.bounds.midY - targetCenterY
            let x = dx * scale
            let y = dy * scale
            
            let translationTransform = CGAffineTransform(translationX: x, y: y)
            self.imageView.transform = self.imageView.transform.concatenating(translationTransform)
        }
        
        let translation = recognizer.translation(in: self.view)
        var centerX: CGFloat = recognizer.view!.center.x + translation.x
        var centerY: CGFloat = recognizer.view!.center.y + translation.y
        let minDistant: CGFloat = self.kEdgeViewWidth
        let contentViewHeight: CGFloat = kScreenHeight - kStatusBarHeight - GifEditViewBottomBar.height - GifEditToolBar.height
        let contentViewWidth: CGFloat = kScreenWidth
        let imageViewFrame = self.imageView.frame
        
        if recognizer.view! === self.leftUpEdgeView { // 左上
            centerX = max(imageViewFrame.origin.x, 0, centerX)
            centerX = min(self.rightUpEdgeView.center.x - minDistant, centerX)
            centerY = max(imageViewFrame.origin.y, 0, centerY)
            centerY = min(self.leftDownEdgeView.center.y - minDistant, centerY)
            
            var rightUpEdgeViewCenter = self.rightUpEdgeView.center
            rightUpEdgeViewCenter.y = centerY
            self.rightUpEdgeView.center = rightUpEdgeViewCenter
            
            var leftDownEdgeViewCenter = self.leftDownEdgeView.center
            leftDownEdgeViewCenter.x = centerX
            self.leftDownEdgeView.center = leftDownEdgeViewCenter
            
        } else if recognizer.view! === self.leftDownEdgeView { // 左下
            centerX = max(imageViewFrame.origin.x, 0, centerX)
            centerX = min(self.rightDownEdgeView.center.x - minDistant, centerX)
            centerY = max(self.leftUpEdgeView.center.y + minDistant, centerY)
            centerY = min(imageViewFrame.maxY, contentViewHeight ,centerY)
            
            var rightDownEdgeViewCenter = self.rightDownEdgeView.center
            rightDownEdgeViewCenter.y = centerY
            self.rightDownEdgeView.center = rightDownEdgeViewCenter
            
            var leftUpEdgeViewCenter = self.leftUpEdgeView.center
            leftUpEdgeViewCenter.x = centerX
            self.leftUpEdgeView.center = leftUpEdgeViewCenter
            
        } else if recognizer.view! === self.rightUpEdgeView { //右上
            centerX = max(self.leftUpEdgeView.center.x + minDistant, centerX)
            centerX = min(imageViewFrame.maxX, contentViewWidth, centerX)
            centerY = max(imageViewFrame.origin.y, 0, centerY)
            centerY = min(self.rightDownEdgeView.center.y - minDistant ,centerY)
            
            var leftUpEdgeViewViewCenter = self.leftUpEdgeView.center
            leftUpEdgeViewViewCenter.y = centerY
            self.leftUpEdgeView.center = leftUpEdgeViewViewCenter
            
            var rightDownEdgeViewCenter = self.rightDownEdgeView.center
            rightDownEdgeViewCenter.x = centerX
            self.rightDownEdgeView.center = rightDownEdgeViewCenter
            
        } else { //rightDownEdgeView 右下
            centerX = max(self.leftDownEdgeView.center.x + minDistant, centerX)
            centerX = min(imageViewFrame.maxX, contentViewWidth, centerX)
            centerY = max(self.rightUpEdgeView.center.y + minDistant, centerY)
            centerY = min(imageViewFrame.maxY, contentViewHeight, centerY)
            
            var leftDownEdgeViewCenter = self.leftDownEdgeView.center
            leftDownEdgeViewCenter.y = centerY
            self.leftDownEdgeView.center = leftDownEdgeViewCenter
            
            var rightUpEdgeViewCenter = self.rightUpEdgeView.center
            rightUpEdgeViewCenter.x = centerX
            self.rightUpEdgeView.center = rightUpEdgeViewCenter
        }
        
        let newCenter = CGPoint(x: centerX, y: centerY)
        recognizer.view!.center = newCenter
        recognizer.setTranslation(CGPoint.zero, in: self.view)
        
        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: kScreenWidth, height: contentViewHeight))
        let showRectX = self.leftUpEdgeView.center.x
        let showRectY = self.leftUpEdgeView.center.y
        let showRectWidth = self.rightUpEdgeView.center.x - self.leftUpEdgeView.center.x
        let showRectHeight = self.leftDownEdgeView.center.y - self.leftUpEdgeView.center.y
        
        let showPath = UIBezierPath(rect: CGRect(x: showRectX, y: showRectY, width: showRectWidth, height: showRectHeight)).reversing()
        path.append(showPath)
        self.maskLayer.path = path.cgPath
    
    }
    
    /// 更新显示区域
    ///
    /// - Parameters:
    ///   - rect: 显示区域
    ///   - animated: 是否有动画
    private func updateMaskAndEdgeView(with rect: CGRect, animated: Bool) {
        let block: () -> () = {
            //edgeView
            self.leftUpEdgeView.center = CGPoint(x: rect.origin.x, y: rect.origin.y)
            self.leftDownEdgeView.center = CGPoint(x: rect.origin.x, y: rect.maxY)
            self.rightUpEdgeView.center = CGPoint(x: rect.maxX, y: rect.origin.y)
            self.rightDownEdgeView.center = CGPoint(x: rect.maxX, y: rect.maxY)
            
            //masklayer
            let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: kScreenWidth, height: kScreenHeight))
            let showRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width, height: rect.size.height)
            let showPath = UIBezierPath(rect: showRect).reversing()
            path.append(showPath)
            self.maskLayer.path = path.cgPath
        }
        
        if animated {
            UIView.animate(withDuration: 0.25, animations: block)
        } else {
            block()
        }
    }
    
    //MARK: animate
    private func switchToClipingMode(_ isCliping: Bool) {
        
        self.isCliping = isCliping
        var naviBarFrame = self.navigationController!.navigationBar.frame
        let toolBarTop: CGFloat
        let contentViewHeight: CGFloat
        var leftDownCenter = self.leftDownEdgeView.center
        var leftUpCenter = self.leftUpEdgeView.center
        var rightDownCenter = self.rightDownEdgeView.center
        var rightUpCenter = self.rightUpEdgeView.center

        if isCliping {
            naviBarFrame.origin.y = -(kNavigationBarHeight + kStatusBarHeight)
            toolBarTop = kStatusBarHeight
            contentViewHeight = kScreenHeight - kStatusBarHeight - GifEditViewBottomBar.height - GifEditToolBar.height
            self.bottomBar.status = .cliping
            leftDownCenter.y = kNavigationBarHeight / 2 + leftDownCenter.y
            leftUpCenter.y = kNavigationBarHeight/2 + leftUpCenter.y
            rightDownCenter.y = kNavigationBarHeight/2 + rightDownCenter.y
            rightUpCenter.y = kNavigationBarHeight/2 + rightUpCenter.y
        } else {
            naviBarFrame.origin.y = kStatusBarHeight
            toolBarTop = kNavigationBarHeight + kStatusBarHeight
            contentViewHeight = kScreenHeight - kStatusBarHeight - kNavigationBarHeight - GifEditViewBottomBar.height - GifEditToolBar.height
            self.bottomBar.status = .normal
            leftDownCenter.y = -kNavigationBarHeight / 2 + leftDownCenter.y
            leftUpCenter.y = -kNavigationBarHeight/2 + leftUpCenter.y
            rightDownCenter.y = -kNavigationBarHeight/2 + rightDownCenter.y
            rightUpCenter.y = -kNavigationBarHeight/2 + rightUpCenter.y
        }

        UIView.animate(withDuration: 0.25, animations: {
            self.navigationController?.navigationBar.frame = naviBarFrame
        })
        
        self.toolBar.snp.updateConstraints({ (make) in
            make.top.equalTo(toolBarTop)
        })
        
        //edgeView
        self.leftDownEdgeView.isHidden = !isCliping
        self.leftUpEdgeView.isHidden = !isCliping
        self.rightDownEdgeView.isHidden = !isCliping
        self.rightUpEdgeView.isHidden = !isCliping

        self.leftDownEdgeView.center = leftDownCenter
        self.leftUpEdgeView.center = leftUpCenter
        self.rightDownEdgeView.center = rightDownCenter
        self.rightUpEdgeView.center = rightUpCenter
        
        //masklayer
        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: kScreenWidth, height: contentViewHeight))
        let showRect = CGRect(x: leftUpCenter.x, y: leftUpCenter.y, width: rightUpCenter.x-leftUpCenter.x, height: leftDownCenter.y - leftUpCenter.y)
        let showPath = UIBezierPath(rect: showRect).reversing()
        path.append(showPath)
        self.maskLayer.path = path.cgPath
    }
}
