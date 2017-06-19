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

class GifEditViewController: BaseViewController, UIScrollViewDelegate {
    //MARK: property
    var selectedArray: [Photo] = [] {
        didSet {
            if self.selectedArray.count < 1 {
                return
            }
            var maxWidth: CGFloat = self.selectedArray[0].photoHeight
            var maxHeight: CGFloat = self.selectedArray[0].photoWidth
            for index in 0 ..< self.selectedArray.count {
                let photo = self.selectedArray[index]
                if maxWidth < photo.photoWidth {
                    maxWidth = photo.photoWidth
                }
                if maxHeight < photo.photoHeight {
                    maxHeight = photo.photoHeight
                }
            }
            self.showingRect.size = CGSize(width: maxWidth, height: maxHeight)
        }
    }
    private var imageArray: [UIImage] = []
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.backgroundColor = UIColor.white
        imageView.animationDuration = self.bottomBar.originDuration * Double(self.selectedArray.count)
        return imageView
    }()
    private lazy var bottomBar: GifEditViewBottomBar = {
        let bottomBar = GifEditViewBottomBar(frame: CGRect.zero)
        bottomBar.totalCount = self.selectedArray.count
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
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: CGRect.zero)
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 50.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        scrollView.isScrollEnabled = false
        return scrollView
    }()
    private lazy var contentView: UIView = {
        let contentView = UIView(frame: CGRect.zero)
        contentView.clipsToBounds = true
        return contentView
    }()
    private lazy var maskLayer: CAShapeLayer = {
        let maskLayer = CAShapeLayer()
        maskLayer.fillColor = UIColor.red.cgColor
        maskLayer.opacity = 0.5
        return maskLayer
    }()
    private lazy var leftUpEdgeView: UIView = {
        let leftUpEdgeView = UIView(frame: CGRect(x: 0, y: 0, width: self.kEdgeViewWidth, height: self.kEdgeViewWidth))
        leftUpEdgeView.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        leftUpEdgeView.isHidden = true
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panEdgeView(recognizer:)))
        leftUpEdgeView.addGestureRecognizer(gesture)
        return leftUpEdgeView
    }()
    private lazy var rightUpEdgeView: UIView = {
        let rightUpEdgeView = UIView(frame: CGRect(x: 0, y: 0, width: self.kEdgeViewWidth, height: self.kEdgeViewWidth))
        rightUpEdgeView.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        rightUpEdgeView.isHidden = true
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panEdgeView(recognizer:)))
        rightUpEdgeView.addGestureRecognizer(gesture)
        return rightUpEdgeView
    }()
    private lazy var rightDownEdgeView: UIView = {
        let rightDownEdgeView = UIView(frame: CGRect(x: 0, y: 0, width: self.kEdgeViewWidth, height: self.kEdgeViewWidth))
        rightDownEdgeView.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        rightDownEdgeView.isHidden = true
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panEdgeView(recognizer:)))
        rightDownEdgeView.addGestureRecognizer(gesture)
        return rightDownEdgeView
    }()
    private lazy var leftDownEdgeView: UIView = {
        let leftDownEdgeView = UIView(frame: CGRect(x: 0, y: 0, width: self.kEdgeViewWidth, height: self.kEdgeViewWidth))
        leftDownEdgeView.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        leftDownEdgeView.isHidden = true
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panEdgeView(recognizer:)))
        leftDownEdgeView.addGestureRecognizer(gesture)
        return leftDownEdgeView
    }()
    
    private let kEdgeViewWidth: CGFloat = 30
    private var showingRect: CGRect = CGRect.zero
    private var kGroup: DispatchGroup = DispatchGroup()
    private var isCliping: Bool = false
    
    //MARK: life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureSubviews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.fetchFullImage()
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
        self.contentView.addSubview(self.scrollView)
        self.scrollView.snp.makeConstraints { (make) in
            make.edges.equalTo(contentView)
        }
        
        let scrollViewHeight = kScreenHeight - kStatusBarHeight - kNavigationBarHeight - GifEditViewBottomBar.height - GifEditToolBar.height
        let imageViewWidth = kScreenWidth
        let imageViewHeight = self.showingRect.size.height / self.showingRect.size.width * imageViewWidth
        self.imageView.frame.size = CGSize(width: imageViewWidth, height: imageViewHeight)

        let insetTop = (scrollViewHeight - self.imageView.frame.size.height)/2
        self.scrollView.contentInset = UIEdgeInsets(top:  insetTop, left: 0, bottom: insetTop, right: 0)
        self.scrollView.addSubview(self.imageView)
        
        //masklayer
        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: kScreenWidth, height: scrollViewHeight))
        let showRect = CGRect(x: 0, y: insetTop, width: self.imageView.frame.size.width, height: self.imageView.frame.size.height)
        let showPath = UIBezierPath(rect: showRect).reversing()
        path.append(showPath)
        self.maskLayer.path = path.cgPath
        self.contentView.layer.addSublayer(self.maskLayer)
        
        //edgeView
        self.contentView.addSubview(self.leftUpEdgeView)
        self.contentView.addSubview(self.rightUpEdgeView)
        self.contentView.addSubview(self.rightDownEdgeView)
        self.contentView.addSubview(self.leftDownEdgeView)
        
    }
    
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
    
    func panEdgeView(recognizer: UIPanGestureRecognizer) {
        if !self.isCliping { return }
        if recognizer.state == .ended {
            let leftUpPoint = self.contentView.convert(self.leftUpEdgeView.center, to: self.scrollView)
            let rightDownPoint = self.contentView.convert(self.rightDownEdgeView.center, to: self.scrollView)
            
            let scrollViewHeight = kScreenHeight - kStatusBarHeight - GifEditViewBottomBar.height - GifEditToolBar.height
            let tempWidth = self.rightUpEdgeView.center.x - self.leftUpEdgeView.center.x
            let tempHeight = self.leftDownEdgeView.center.y - self.leftUpEdgeView.center.y
            
            var maskWidth: CGFloat = 0
            var maskHeight: CGFloat = 0
            var maskX: CGFloat = 0
            var maskY: CGFloat = 0
            if tempWidth > tempHeight {
                maskWidth = kScreenWidth
                maskHeight = tempHeight / tempWidth * kScreenWidth
                maskY = (scrollViewHeight - maskHeight) / 2
            } else {
                maskHeight = scrollViewHeight
                maskWidth = tempWidth / tempHeight * maskHeight
                maskX = (kScreenWidth - maskWidth) / 2
            }
            let maskRect = CGRect(x: maskX, y: maskY, width: maskWidth, height: maskHeight)
            
            self.updateMaskAndEdgeView(with: maskRect, animated: true)
            
            self.scrollView.contentInset = UIEdgeInsets(top: maskY, left: maskX, bottom: maskY, right: maskX)
            
            let x: CGFloat = self.scrollView.contentOffset.x / self.scrollView.zoomScale + leftUpPoint.x
            let y: CGFloat = self.scrollView.contentOffset.y / self.scrollView.zoomScale + (scrollViewHeight - self.imageView.frame.height) / 2 + leftUpPoint.y
            let width: CGFloat = (rightDownPoint.x - leftUpPoint.x) / self.scrollView.zoomScale
            let heigth: CGFloat = (rightDownPoint.y - leftUpPoint.y) / self.scrollView.zoomScale
            let rect = CGRect(x: x, y: y, width: width, height: heigth)
            self.scrollView.zoom(to: rect, animated: true)
        }
        
        let translation = recognizer.translation(in: self.view)
        var centerX: CGFloat = recognizer.view!.center.x + translation.x
        var centerY: CGFloat = recognizer.view!.center.y + translation.y
        let minDistant: CGFloat = self.kEdgeViewWidth
        let contentViewHeight: CGFloat = kScreenHeight - kStatusBarHeight - GifEditViewBottomBar.height - GifEditToolBar.height
        let contentViewWidth: CGFloat = kScreenWidth
        
        if recognizer.view! === self.leftUpEdgeView {
            
            centerX = max(0, centerX)
            centerX = min(self.rightUpEdgeView.center.x - minDistant, centerX)
            centerY = max(0, centerY)
            centerY = min(self.leftDownEdgeView.center.y - minDistant, centerY)
            
            var rightUpEdgeViewCenter = self.rightUpEdgeView.center
            rightUpEdgeViewCenter.y = centerY
            self.rightUpEdgeView.center = rightUpEdgeViewCenter
            
            var leftDownEdgeViewCenter = self.leftDownEdgeView.center
            leftDownEdgeViewCenter.x = centerX
            self.leftDownEdgeView.center = leftDownEdgeViewCenter
            
        } else if recognizer.view! === self.leftDownEdgeView {
            
            centerX = max(0, centerX)
            centerX = min(self.rightDownEdgeView.center.x - minDistant, centerX)
            centerY = max(self.leftUpEdgeView.center.y + minDistant, centerY)
            centerY = min(contentViewHeight ,centerY)
            
            var rightDownEdgeViewCenter = self.rightDownEdgeView.center
            rightDownEdgeViewCenter.y = centerY
            self.rightDownEdgeView.center = rightDownEdgeViewCenter
            
            var leftUpEdgeViewCenter = self.leftUpEdgeView.center
            leftUpEdgeViewCenter.x = centerX
            self.leftUpEdgeView.center = leftUpEdgeViewCenter
            
        } else if recognizer.view! === self.rightUpEdgeView {
            
            centerX = max(self.leftUpEdgeView.center.x + minDistant, centerX)
            centerX = min(contentViewWidth, centerX)
            centerY = max(0, centerY)
            centerY = min(self.rightDownEdgeView.center.y - minDistant ,centerY)
            
            var leftUpEdgeViewViewCenter = self.leftUpEdgeView.center
            leftUpEdgeViewViewCenter.y = centerY
            self.leftUpEdgeView.center = leftUpEdgeViewViewCenter
            
            var rightDownEdgeViewCenter = self.rightDownEdgeView.center
            rightDownEdgeViewCenter.x = centerX
            self.rightDownEdgeView.center = rightDownEdgeViewCenter
            
        } else { //rightDownEdgeView
            
            centerX = max(self.leftDownEdgeView.center.x + minDistant, centerX)
            centerX = min(contentViewWidth, centerX)
            centerY = max(self.rightUpEdgeView.center.y + minDistant, centerY)
            centerY = min(contentViewHeight, centerY)
            
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
    
    //MARK: delegate method
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if self.isCliping {
            return self.imageView
        } else {
            return nil
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
    }
    
    //MARK: animate
    private func switchToClipingMode(_ isCliping: Bool) {
        
        self.scrollView.isScrollEnabled = isCliping
        self.isCliping = isCliping
        var naviBarFrame = self.navigationController!.navigationBar.frame
        let toolBarTop: CGFloat
        let scrollViewHeight: CGFloat

        if isCliping {
            naviBarFrame.origin.y = -(kNavigationBarHeight + kStatusBarHeight)
            toolBarTop = kStatusBarHeight
            scrollViewHeight = kScreenHeight - kStatusBarHeight - GifEditViewBottomBar.height - GifEditToolBar.height
            self.bottomBar.status = .cliping
        } else {
            naviBarFrame.origin.y = kStatusBarHeight
            toolBarTop = kNavigationBarHeight + kStatusBarHeight
            scrollViewHeight = kScreenHeight - kStatusBarHeight - kNavigationBarHeight - GifEditViewBottomBar.height - GifEditToolBar.height
            self.bottomBar.status = .normal
        }
        
        UIView.animate(withDuration: 0.25, animations: {
            self.navigationController?.navigationBar.frame = naviBarFrame
        })
        
        self.toolBar.snp.updateConstraints({ (make) in
            make.top.equalTo(toolBarTop)
        })
        
        let insetTop = (scrollViewHeight - self.imageView.frame.size.height)/2
        self.scrollView.contentInset = UIEdgeInsets(top:  insetTop, left: 0, bottom: insetTop, right: 0)
        //masklayer
        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: kScreenWidth, height: scrollViewHeight))
        let showRect = CGRect(x: 0, y: insetTop, width: self.imageView.frame.size.width, height: self.imageView.frame.size.height)
        let showPath = UIBezierPath(rect: showRect).reversing()
        path.append(showPath)
        self.maskLayer.path = path.cgPath
        
        //edgeView
        self.leftDownEdgeView.isHidden = !isCliping
        self.leftUpEdgeView.isHidden = !isCliping
        self.rightDownEdgeView.isHidden = !isCliping
        self.rightUpEdgeView.isHidden = !isCliping
        self.leftDownEdgeView.center = CGPoint(x: 0, y: insetTop + self.imageView.frame.height)
        self.leftUpEdgeView.center = CGPoint(x: 0, y: insetTop)
        self.rightDownEdgeView.center = CGPoint(x: self.imageView.frame.width, y: insetTop + self.imageView.frame.height)
        self.rightUpEdgeView.center = CGPoint(x: self.imageView.frame.width, y: insetTop)
    }
}
