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
    
    enum MaskFadeType {
        case fadeIn
        case fadeOut
    }
    
    enum ImageQuality {
        case low
        case medium
        case high
    }
    
    //MARK: property
    private let kEdgeViewWidth: CGFloat = 50
    private let lowQualityLength: CGFloat = 334
    private let mediumQualityLength: CGFloat = 667
    private let highQualityLength: CGFloat = 1000
    
    var selectedArray: [Photo] = []
    private var imageArray: [UIImage] = []
    private var kGroup: DispatchGroup = DispatchGroup()
    private var isCliping: Bool = false
    private var showingRect: CGRect? = nil
    private var ratioStatus: RatioStatus = .noLimit {
        didSet {
            if showingRect == nil {
                showingRect = imageView.bounds
            }
            let resizeBlock: ((CGFloat) -> ()) = {(ratio) in
                if ratio > (self.showingRect!.width / self.showingRect!.height) {
                    let resultHeight = self.showingRect!.width / ratio
                    self.showingRect!.origin.y = self.showingRect!.origin.y + (self.showingRect!.height - resultHeight) / 2
                    self.showingRect!.size.height = resultHeight
                } else {
                    let resultWidth = self.showingRect!.height * ratio
                    self.showingRect!.origin.x = self.showingRect!.origin.x + (self.showingRect!.width - resultWidth) / 2
                    self.showingRect!.size.width = resultWidth
                }
            }
            let ratio = ratioStatus.floatValue
            if ratio != 0 {
                resizeBlock(ratio)
            }
            resizeShowingArea()
        }
    }
    
    //MARK: life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
        updateMaskAndEdgeView(animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchFullImage()
    }
    
    private func configureSubviews() {
        title = "编辑"
        extendedLayoutIncludesOpaqueBars = true
        
        let generateItem: UIBarButtonItem = UIBarButtonItem(title: "生成", style: .plain, target: self, action: #selector(clickGenerateButton))
        generateItem.tintColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        navigationItem.rightBarButtonItem = generateItem;
        
        view.addSubview(toolBar)
        toolBar.snp.makeConstraints { (make) in
            make.top.equalTo(kNavigationBarHeight + kStatusBarHeight)
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.height.equalTo(GifEditToolBar.height)
        }
        
        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { (make) in
            make.bottom.equalTo(0)
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.height.equalTo(GifEditViewBottomBar.height)
        }
        
        view.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.top.equalTo(self.toolBar.snp.bottom).offset(0)
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.bottom.equalTo(self.bottomBar.snp.top).offset(0)
        }
        
        let contentViewHeight: CGFloat = kScreenHeight - kStatusBarHeight - kNavigationBarHeight - GifEditViewBottomBar.height - GifEditToolBar.height
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.center.equalTo(self.contentView.snp.center)
            var imageViewRatio: CGFloat = 1.0
            if isSameRatio() {
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
        
        contentView.layer.addSublayer(maskLayer)
        contentView.layer.addSublayer(borderLayer)
        
        contentView.addSubview(leftUpEdgeView)
        contentView.addSubview(rightUpEdgeView)
        contentView.addSubview(rightDownEdgeView)
        contentView.addSubview(leftDownEdgeView)
        
        contentView.setNeedsLayout()
        contentView.layoutIfNeeded()
    }
    
    private func configureEdgeView() -> UIImageView {
        let edgeView = UIImageView(frame: CGRect(x: 0, y: 0, width: kEdgeViewWidth, height: kEdgeViewWidth))
        edgeView.isHidden = true
        edgeView.isUserInteractionEnabled = true
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panEdgeView(recognizer:)))
        edgeView.addGestureRecognizer(gesture)
        return edgeView
    }
    
    /// 获取完整大图
    private func fetchFullImage() {
        showHudWithMsg(msg: "")
        kGroup = DispatchGroup()
        for photo in selectedArray {
            kGroup.enter()
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
                kGroup.leave()
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
    
    private func generateGif(by quality: ImageQuality) {
        self.showHudWithMsg(msg: "正在生成...")
        
        let sr: CGRect = showingRect == nil ? imageView.bounds : showingRect!
        let targetHeight: CGFloat
        let targetWidth: CGFloat
        let maxLength: CGFloat
        
        switch quality {
        case .low:
            maxLength = lowQualityLength
        case .medium:
            maxLength = mediumQualityLength
        case .high:
            maxLength = highQualityLength
        }
        if sr.size.width > sr.size.height {
            targetWidth = maxLength
            targetHeight = maxLength / sr.size.width * sr.size.height
        } else {
            targetWidth = maxLength
            targetHeight = maxLength / sr.size.height * sr.size.width
        }
        
        let fileProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]] as CFDictionary;
        
        let frameProperties: CFDictionary = [
            kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: self.bottomBar.currentDuration],
            kCGImagePropertyPixelHeight as String: targetHeight,
            kCGImagePropertyPixelWidth as String: targetWidth
            ] as CFDictionary;
        
        let filename = timeStamp()
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(filename).gif")
        
        DispatchQueue.global().async { [unowned self] in
            let destination: CGImageDestination? = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeGIF, self.selectedArray.count, nil);
            if destination == nil {
                DispatchQueue.main.async {
                    self.showNotice(message: "生成Gif失败...")
                }
            }
            CGImageDestinationSetProperties(destination!, fileProperties);
            
            let scale = targetWidth / sr.size.width
            
            for image in self.imageArray {
                let originWidth = scale * self.imageView.bounds.width
                let originHeight = scale * self.imageView.bounds.height
                
                let newImage = image.imageCenterScalingWith(targetSize: CGSize(width: originWidth, height: originHeight))?.clipImage(in: CGRect(x: sr.origin.x * scale, y: sr.origin.y * scale, width: sr.size.width * scale, height: sr.size.height * scale))
                CGImageDestinationAddImage(destination!, newImage!.cgImage!, frameProperties);
            }
            
            if CGImageDestinationFinalize(destination!) {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                }) { (success, error) in
                    DispatchQueue.main.async { [unowned self] in
                        self.hideHud()
                        if success {
                            
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: kNotiKeyGalleryUpdate), object: nil)
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: kNotiKeyGifGenerated), object: url)
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
            self.generateGif(by: .low)
        }
        alertController.addAction(lowQualityAction)
        let mediumQualityAction = UIAlertAction(title: "中等清晰度", style: .default) { [unowned self](action) in
            self.generateGif(by: .medium)
        }
        alertController.addAction(mediumQualityAction)
        let highQualityAction = UIAlertAction(title: "高清晰度", style: .default) { [unowned self](action) in
            self.generateGif(by: .high)
        }
        alertController.addAction(highQualityAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func clickRotateButton() {
        var rotateImageArray: [UIImage] = []
        for image in imageArray {
            rotateImageArray.append(image.rotate(orient: .left))
        }
        imageArray = rotateImageArray;
        
        showingRect = nil
        
        // update imageView
        let contentViewHeight: CGFloat = kScreenHeight - kStatusBarHeight - kNavigationBarHeight - GifEditViewBottomBar.height - GifEditToolBar.height
        imageView.snp.updateConstraints { (make) in
            make.center.equalTo(self.contentView.snp.center)
            var imageViewRatio: CGFloat = 1.0
            if isSameRatio() {
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
        
        imageView.animationImages = self.imageArray
        imageView.startAnimating()
        
        resizeShowingArea()
    }
    
    //MARK: gesture
    func pinchImageView(recognizer: UIPinchGestureRecognizer) {
        if !isCliping { return }
        
        if recognizer.state == .began {
            maskFade(.fadeIn)
            return
        }
        
        if recognizer.state == .ended {
            maskFade(.fadeOut)
            return
        }
        
        if recognizer.state == .ended {
            let imageLeftUpPoint = contentView.convert(leftUpEdgeView.center, to: imageView)
            let imageRightDownPoint = contentView.convert(rightDownEdgeView.center, to: imageView)
            
            let showingRect = CGRect(x: imageLeftUpPoint.x, y: imageLeftUpPoint.y, width: imageRightDownPoint.x - imageLeftUpPoint.x, height: imageRightDownPoint.y - imageLeftUpPoint.y)
            self.showingRect = showingRect
            updateMaskAndEdgeView(animated: false)
            return
        }
        
        var scale = recognizer.scale
        let location = recognizer.location(in: contentView)
        let scaleTransform = imageView.transform.scaledBy(x: scale, y: scale)
        imageView.transform = scaleTransform
        
        let edgeRect = CGRect(x: leftUpEdgeView.center.x, y: leftUpEdgeView.center.y, width: rightDownEdgeView.center.x - leftUpEdgeView.center.x, height: rightDownEdgeView.center.y - leftUpEdgeView.center.y)
        
        // 限制缩放大小
        if imageView.frame.height < edgeRect.height {
            imageView.transform = .identity
            scale = edgeRect.height / imageView.frame.height
            let scaleTransform = imageView.transform.scaledBy(x: scale, y: scale)
            imageView.transform = scaleTransform
        }
        if imageView.frame.width < edgeRect.width {
            imageView.transform = .identity
            scale = edgeRect.width / imageView.frame.width
            let scaleTransform = imageView.transform.scaledBy(x: scale, y: scale)
            imageView.transform = scaleTransform
        }
        
        let dx = imageView.frame.midX - location.x
        let dy = imageView.frame.midY - location.y
        let x = dx * scale - dx
        let y = dy * scale - dy
        
        let translationTransform = CGAffineTransform(translationX: x, y: y)
        imageView.transform = recognizer.view!.transform.concatenating(translationTransform)
        
        // 控制边界
        var adjustX: CGFloat = 0
        var adjustY: CGFloat = 0
        if imageView.frame.minX > edgeRect.minX {
            adjustX = edgeRect.minX - imageView.frame.minX
        }
        if imageView.frame.minY > edgeRect.minY {
            adjustY = edgeRect.minY - imageView.frame.minY
        }
        if imageView.frame.maxX < edgeRect.maxX {
            adjustX = edgeRect.maxX - imageView.frame.maxX
        }
        if imageView.frame.maxY < edgeRect.maxY {
            adjustY = edgeRect.maxY - imageView.frame.maxY
        }
        let adjustTranslation = CGAffineTransform(translationX: adjustX, y: adjustY)
        imageView.transform = recognizer.view!.transform.concatenating(adjustTranslation)
        
        recognizer.scale = 1
    }
    
    func panImageView(recognizer: UIPanGestureRecognizer) {
        if !isCliping { return }
        
        if recognizer.state == .began {
            maskFade(.fadeIn)
            return
        }

        if recognizer.state == .ended {
            maskFade(.fadeOut)
            
            let imageLeftUpPoint = contentView.convert(leftUpEdgeView.center, to: imageView)
            let imageRightDownPoint = contentView.convert(rightDownEdgeView.center, to: imageView)
            
            let showingRect = CGRect(x: imageLeftUpPoint.x, y: imageLeftUpPoint.y, width: imageRightDownPoint.x - imageLeftUpPoint.x, height: imageRightDownPoint.y - imageLeftUpPoint.y)
            self.showingRect = showingRect
            updateMaskAndEdgeView(animated: false)
            return
        }
        
        // 触碰点是否在ImageView
        if !imageView.point(inside: recognizer.location(in: imageView), with: nil) { return }
        
        let translation = recognizer.translation(in: view)
        let lastScale = imageView.frame.size.width / imageView.bounds.size.width
        var translationX = translation.x / lastScale
        var translationY = translation.y / lastScale
        
        let edgeRect = CGRect(x: leftUpEdgeView.center.x, y: leftUpEdgeView.center.y, width: rightDownEdgeView.center.x - leftUpEdgeView.center.x, height: rightDownEdgeView.center.y - leftUpEdgeView.center.y)
        
        // 控制边界
        if imageView.frame.minX + translationX > edgeRect.minX {
            translationX = edgeRect.minX - imageView.frame.minX
        }
        if imageView.frame.minY + translationY > edgeRect.minY {
            translationY = edgeRect.minY - imageView.frame.minY
        }
        if imageView.frame.maxX + translationX < edgeRect.maxX {
            translationX = edgeRect.maxX - imageView.frame.maxX
        }
        if imageView.frame.maxY + translationY < edgeRect.maxY {
            translationY = edgeRect.maxY - imageView.frame.maxY
        }
        
        let transform = imageView.transform.translatedBy(x: translationX, y: translationY)
        imageView.transform = transform
        
        recognizer.setTranslation(CGPoint.zero, in: self.view)
    }
    
    func panEdgeView(recognizer: UIPanGestureRecognizer) {
        if !isCliping { return }
        
        if recognizer.state == .began {
            maskFade(.fadeIn)
            return
        }
        
        if recognizer.state == .ended {
            resizeShowingArea()
            maskFade(.fadeOut)
            return
        }
        
        let translation = recognizer.translation(in: view)
        var centerX: CGFloat = recognizer.view!.center.x + translation.x
        var centerY: CGFloat = recognizer.view!.center.y + translation.y
        
        var leftUpViewCenter = leftUpEdgeView.center
        var rightDownViewCenter = rightDownEdgeView.center
        
        let minDistant: CGFloat = kEdgeViewWidth
        
        let contentViewHeight: CGFloat = contentView.frame.size.height
        let contentViewWidth: CGFloat = contentView.frame.size.width
        
        let imageViewFrame = imageView.frame
        
        let ratio = ratioStatus.floatValue
        
        if recognizer.view! === leftUpEdgeView { // 左上
            centerX = max(imageViewFrame.origin.x, kEdgeViewWidth / 2, centerX)
            centerX = min(rightUpEdgeView.center.x - minDistant, centerX)
            centerY = max(imageViewFrame.origin.y, kEdgeViewWidth / 2, centerY)
            centerY = min(leftDownEdgeView.center.y - minDistant, centerY)
            
            if ratio != 0 {
                if abs(translation.x) > (translation.y) {
                    centerY = rightDownViewCenter.y - (rightDownViewCenter.x - centerX) / ratio
                } else {
                    centerX = rightDownViewCenter.x - (rightDownViewCenter.y - centerY) * ratio
                }
            }
            leftUpViewCenter = CGPoint(x: centerX, y: centerY)
        } else if recognizer.view! === leftDownEdgeView { // 左下
            centerX = max(imageViewFrame.origin.x, kEdgeViewWidth / 2, centerX)
            centerX = min(rightDownEdgeView.center.x - minDistant, centerX)
            centerY = max(leftUpEdgeView.center.y + minDistant, centerY)
            centerY = min(imageViewFrame.maxY, contentViewHeight - kEdgeViewWidth / 2 ,centerY)
            
            if ratio != 0 {
                if abs(translation.x) > (translation.y) {
                    centerY = leftUpViewCenter.y + (rightDownViewCenter.x - centerX) / ratio
                } else {
                    centerX = rightDownViewCenter.x - (centerY - leftUpViewCenter.y) * ratio
                }
            }
            leftUpViewCenter.x = centerX
            rightDownViewCenter.y = centerY
        } else if recognizer.view! === rightUpEdgeView { //右上
            centerX = max(self.leftUpEdgeView.center.x + minDistant, centerX)
            centerX = min(imageViewFrame.maxX, contentViewWidth - kEdgeViewWidth / 2, centerX)
            centerY = max(imageViewFrame.origin.y, kEdgeViewWidth / 2, centerY)
            centerY = min(self.rightDownEdgeView.center.y - minDistant ,centerY)
            
            if ratio != 0 {
                if abs(translation.x) > (translation.y) {
                    centerY = rightDownViewCenter.y - (centerX - leftUpViewCenter.x) / ratio
                } else {
                    centerX = leftUpViewCenter.x + (rightDownViewCenter.y - centerY) * ratio
                }
            }
            leftUpViewCenter.y = centerY
            rightDownViewCenter.x = centerX
        } else { //rightDownEdgeView 右下
            centerX = max(self.leftDownEdgeView.center.x + minDistant, centerX)
            centerX = min(imageViewFrame.maxX, contentViewWidth - kEdgeViewWidth / 2, centerX)
            centerY = max(self.rightUpEdgeView.center.y + minDistant, centerY)
            centerY = min(imageViewFrame.maxY, contentViewHeight - kEdgeViewWidth / 2, centerY)
            
            if ratio != 0 {
                if abs(translation.x) > (translation.y) {
                    centerY = leftUpViewCenter.y + (centerX - leftUpViewCenter.x) / ratio
                } else {
                    centerX = leftUpViewCenter.x + (centerY - leftUpViewCenter.y) * ratio
                }
            }
            rightDownViewCenter = CGPoint(x: centerX, y: centerY)
        }
        recognizer.setTranslation(CGPoint.zero, in: self.view)
        
        let imageLeftUpPoint = contentView.convert(leftUpViewCenter, to: imageView)
        let imageRightDownPoint = contentView.convert(rightDownViewCenter, to: imageView)
        
        let showingRect = CGRect(x: imageLeftUpPoint.x, y: imageLeftUpPoint.y, width: imageRightDownPoint.x - imageLeftUpPoint.x, height: imageRightDownPoint.y - imageLeftUpPoint.y)
        self.showingRect = showingRect
        updateMaskAndEdgeView(animated: false)
    }
    
    //MARK: update view
    private func resizeShowingArea() {
        let sr: CGRect = showingRect == nil ? imageView.bounds : showingRect!
        let leftUpPoint = sr.origin
        let rightDownPoint = CGPoint(x: sr.maxX, y: sr.maxY)
        
        let contentViewHeight: CGFloat = kScreenHeight - kStatusBarHeight - kNavigationBarHeight - GifEditViewBottomBar.height - GifEditToolBar.height
        
        let targetWidth = rightDownPoint.x - leftUpPoint.x
        let targetHeight = rightDownPoint.y - leftUpPoint.y
        var scale: CGFloat = 1
        if targetHeight / targetWidth < contentViewHeight / kScreenWidth {
            scale = (kScreenWidth - kEdgeViewWidth) / targetWidth
        } else {
            scale = (contentViewHeight - kEdgeViewWidth) / targetHeight
        }
        
        // 缩放
        imageView.transform = .identity
        let scaleTransform = imageView.transform.scaledBy(x: scale, y: scale)
        imageView.transform = scaleTransform
        
        // 位移
        let targetCenterX = (leftUpPoint.x + rightDownPoint.x) / 2
        let targetCenterY = (leftUpPoint.y + rightDownPoint.y) / 2
        let dx = imageView.bounds.midX - targetCenterX
        let dy = imageView.bounds.midY - targetCenterY
        let x = dx * scale
        let y = dy * scale
        
        let translationTransform = CGAffineTransform(translationX: x, y: y)
        imageView.transform = imageView.transform.concatenating(translationTransform)
        
        updateMaskAndEdgeView(animated: true)
    }
    
    /// 更新显示区域
    ///
    /// - Parameters:
    ///   - showingRect: 显示区域
    ///   - animated: 是否有动画
    private func updateMaskAndEdgeView(animated: Bool) {
        let block: () -> () = {
            self.contentView.setNeedsLayout()
            self.contentView.layoutIfNeeded()
            
            let sr: CGRect = self.showingRect == nil ? self.imageView.bounds : self.showingRect!
            let leftUpPoint = self.imageView.convert(CGPoint(x: sr.origin.x, y: sr.origin.y), to: self.contentView)
            let rightDownPoint = self.imageView.convert(CGPoint(x: sr.maxX, y: sr.maxY), to: self.contentView)
            
            //maskLayer
            let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: kScreenWidth, height: kScreenHeight))
            let showRect = CGRect(x: leftUpPoint.x, y: leftUpPoint.y, width: rightDownPoint.x - leftUpPoint.x, height: rightDownPoint.y - leftUpPoint.y)
            let showPath = UIBezierPath(rect: showRect).reversing()
            path.append(showPath)
            self.maskLayer.path = path.cgPath
            
            //borderLayer
            let borderPath = UIBezierPath(rect: CGRect(x: leftUpPoint.x, y: leftUpPoint.y, width: rightDownPoint.x - leftUpPoint.x, height: rightDownPoint.y - leftUpPoint.y))
            let oneThirdX = (rightDownPoint.x - leftUpPoint.x) / 3 + leftUpPoint.x
            let twoThirdX = (rightDownPoint.x - leftUpPoint.x) / 3 * 2 + leftUpPoint.x
            let oneThirdY = (rightDownPoint.y - leftUpPoint.y) / 3 + leftUpPoint.y
            let twoThirdY = (rightDownPoint.y - leftUpPoint.y) / 3 * 2 + leftUpPoint.y
            borderPath.move(to: CGPoint(x: oneThirdX, y: leftUpPoint.y))
            borderPath.addLine(to: CGPoint(x: oneThirdX, y: rightDownPoint.y))
            borderPath.move(to: CGPoint(x: twoThirdX, y: leftUpPoint.y))
            borderPath.addLine(to: CGPoint(x: twoThirdX, y: rightDownPoint.y))
            borderPath.move(to: CGPoint(x: leftUpPoint.x, y: oneThirdY))
            borderPath.addLine(to: CGPoint(x: rightDownPoint.x, y: oneThirdY))
            borderPath.move(to: CGPoint(x: leftUpPoint.x, y: twoThirdY))
            borderPath.addLine(to: CGPoint(x: rightDownPoint.x, y: twoThirdY))
            self.borderLayer.path = borderPath.cgPath
            
            //edgeView
            self.leftUpEdgeView.center = CGPoint(x: leftUpPoint.x, y: leftUpPoint.y)
            self.leftDownEdgeView.center = CGPoint(x: leftUpPoint.x, y: rightDownPoint.y)
            self.rightUpEdgeView.center = CGPoint(x: rightDownPoint.x, y: leftUpPoint.y)
            self.rightDownEdgeView.center = CGPoint(x: rightDownPoint.x, y: rightDownPoint.y)
            
        }
        
        if animated {
            UIView.animate(withDuration: 0.25, animations: block)
        } else {
            block()
        }
    }
    
    private func clipingStateChange(to nextState: Bool) {
        isCliping = nextState
        leftDownEdgeView.isHidden = !isCliping
        leftUpEdgeView.isHidden = !isCliping
        rightDownEdgeView.isHidden = !isCliping
        rightUpEdgeView.isHidden = !isCliping
        
        var naviBarFrame = navigationController!.navigationBar.frame
        let toolBarTop: CGFloat
        let scale: CGFloat
        
        let showingRect: CGRect
        if self.showingRect == nil {
            showingRect = imageView.bounds
        } else {
            showingRect = self.showingRect!
        }
        let showingRectRatio = showingRect.size.width / showingRect.size.height
        
        let contentViewHeight: CGFloat = kScreenHeight - kStatusBarHeight - kNavigationBarHeight - GifEditViewBottomBar.height - GifEditToolBar.height
        if isCliping {
            bottomBar.status = .cliping
            naviBarFrame.origin.y = -(kNavigationBarHeight + kStatusBarHeight)
            toolBarTop = kStatusBarHeight
            // 缩
            if showingRectRatio >= kScreenWidth / contentViewHeight {
                scale = (kScreenWidth - kEdgeViewWidth) / showingRect.width
            } else {
                scale = (contentViewHeight - kEdgeViewWidth) / showingRect.height
            }
        } else {
            bottomBar.status = .normal
            naviBarFrame.origin.y = kStatusBarHeight
            toolBarTop = kNavigationBarHeight + kStatusBarHeight
            // 放
            if showingRectRatio >= kScreenWidth / contentViewHeight {
                scale = kScreenWidth / showingRect.width
            } else {
                scale = contentViewHeight / showingRect.height
            }
        }
        
        // 缩放
        imageView.transform = .identity
        let scaleTransform = imageView.transform.scaledBy(x: scale, y: scale)
        imageView.transform = scaleTransform
        
        // 位移
        let targetCenterX = showingRect.midX
        let targetCenterY = showingRect.midY
        let dx = imageView.bounds.midX - targetCenterX
        let dy = imageView.bounds.midY - targetCenterY
        let x = dx * scale
        let y = dy * scale
        let translationTransform = CGAffineTransform(translationX: x, y: y)
        imageView.transform = imageView.transform.concatenating(translationTransform)
        
        UIView.animate(withDuration: 0.25, animations: {
            self.navigationController?.navigationBar.frame = naviBarFrame
        })
        
        toolBar.snp.updateConstraints({ (make) in
            make.top.equalTo(toolBarTop)
        })
        
        updateMaskAndEdgeView(animated: false)
    }
    
    //MARK: Assist Method
    func isSameRatio() -> Bool {
        let height: CGFloat = selectedArray[0].photoHeight
        let width: CGFloat = selectedArray[0].photoWidth
        let fistRatio = height / width
        for index in 0 ..< selectedArray.count {
            let photo = selectedArray[index]
            if photo.photoHeight / photo.photoWidth != fistRatio {
                return false
            }
        }
        return true
    }
    
    func maskFade(_ fadeType: MaskFadeType) {
        let maskAnimation: CABasicAnimation = CABasicAnimation(keyPath: "opacity")
        maskAnimation.isRemovedOnCompletion = false
        maskAnimation.fillMode = kCAFillModeForwards;
        maskAnimation.duration = 0.25
        
        let borderAnimation: CABasicAnimation = CABasicAnimation(keyPath: "opacity")
        borderAnimation.isRemovedOnCompletion = false
        borderAnimation.fillMode = kCAFillModeForwards;
        borderAnimation.duration = 0.25
        
        switch fadeType {
        case .fadeIn:
            maskAnimation.toValue = 0.5
            borderAnimation.toValue = 1
        default:
            maskAnimation.toValue = 1
            borderAnimation.toValue = 0
        }
        
        maskLayer.add(maskAnimation, forKey: nil)
        borderLayer.add(borderAnimation, forKey: nil)
    }
    
    //MARK: UI property
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
            // 恢复cliping模式初始状态
            self.showingRect = nil
            self.resizeShowingArea()
        }
        bottomBar.sliderValueChangeHandler = { [unowned self] value in
            self.imageView.animationDuration = Double(String(format: "%.2f", value))! * Double(self.selectedArray.count)
            self.imageView.startAnimating()
        }
        bottomBar.ratioButtonHandler = {
            let alertViewController = UIAlertController(title: "图像宽高比", message: nil, preferredStyle: .actionSheet)
            let oneToOneAction = UIAlertAction(title: "1:1", style: .default, handler: { [unowned self](action) in
                self.ratioStatus = .oneToOne
                bottomBar.ratioStatus = .oneToOne
            })
            alertViewController.addAction(oneToOneAction)
            let fourToThreeAction = UIAlertAction(title: "4:3", style: .default, handler: { [unowned self](action) in
                self.ratioStatus = .fourToThree
                bottomBar.ratioStatus = .fourToThree
            })
            alertViewController.addAction(fourToThreeAction)
            let sixteenToNineAction = UIAlertAction(title: "16:9", style: .default, handler: { [unowned self](action) in
                self.ratioStatus = .sixteenToNine
                bottomBar.ratioStatus = .sixteenToNine
            })
            alertViewController.addAction(sixteenToNineAction)
            let noLimitAction = UIAlertAction(title: "无限制", style: .default, handler: { [unowned self](action) in
                self.ratioStatus = .noLimit
                bottomBar.ratioStatus = .noLimit
            })
            alertViewController.addAction(noLimitAction)
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: { (action) in
            })
            alertViewController.addAction(cancelAction)
            self.present(alertViewController, animated: true, completion: nil)
        }
        bottomBar.rotateButtonHandler = {
            self.clickRotateButton()
        }
        return bottomBar
    }()
    private lazy var toolBar: GifEditToolBar = {
        let toolBar = GifEditToolBar(frame: CGRect.zero)
        toolBar.clipButtonHandler = {[unowned self] in
            self.clipingStateChange(to:true)
        }
        toolBar.clipConfirmButtonHandler = {[unowned self] in
            self.clipingStateChange(to:false)
        }
        toolBar.clipCancelButtonHandler = {[unowned self] in
            self.clipingStateChange(to:false)
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
        maskLayer.opacity = 1
        return maskLayer
    }()
    private lazy var borderLayer: CAShapeLayer = {
        let borderLayer = CAShapeLayer()
        borderLayer.fillColor = UIColor.clear.cgColor
        let strokeColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        borderLayer.strokeColor = strokeColor.cgColor
        borderLayer.lineWidth = 1.0
        borderLayer.opacity = 0
        return borderLayer
    }()
    private lazy var leftUpEdgeView: UIImageView = {
        let leftUpEdgeView = self.configureEdgeView()
        leftUpEdgeView.image = #imageLiteral(resourceName: "leftUpBorder")
        return leftUpEdgeView
    }()
    private lazy var rightUpEdgeView: UIView = {
        let rightUpEdgeView = self.configureEdgeView()
        rightUpEdgeView.image = #imageLiteral(resourceName: "rightUpBorder")
        return rightUpEdgeView
    }()
    private lazy var rightDownEdgeView: UIView = {
        let rightDownEdgeView = self.configureEdgeView()
        rightDownEdgeView.image = #imageLiteral(resourceName: "rightDownBorder")
        return rightDownEdgeView
    }()
    private lazy var leftDownEdgeView: UIView = {
        let leftDownEdgeView = self.configureEdgeView()
        leftDownEdgeView.image = #imageLiteral(resourceName: "leftDownBorder")
        return leftDownEdgeView
    }()
}
