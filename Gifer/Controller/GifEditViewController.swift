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
    
    struct State: StateType {
        var showingRect: CGRect? = nil
        var isCliping: Bool = false
    }
    
    enum Action: ActionType {
        case switchCliping
        case panEdgeView(showingRect: CGRect)
    }
    
    enum Command: CommandType {
        case loadToDos(completion: ([String]) -> Void )
        case someOtherCommand
    }
    
    lazy var reducer: (State, Action) -> (state: State, command: Command?) = {
        [weak self] (state: State, action: Action) in
        
        var state = state
        var command: Command? = nil
        
        switch action {
        case .switchCliping:
            state.isCliping = !state.isCliping
        case .panEdgeView(let showingRect):
            state.showingRect = showingRect
        }
        return (state, command)
    }
    
    var store: Store<Action, State, Command>!
    
    //MARK: property
    private let kEdgeViewWidth: CGFloat = 30
    private var kGroup: DispatchGroup = DispatchGroup()
    private var isCliping: Bool = false
    var selectedArray: [Photo] = []
    private var imageArray: [UIImage] = []
    
    //MARK: life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
        
        store = Store<Action, State, Command>(reducer: reducer, initialState: State())
        store.subscribe { [weak self] state, previousState, command in
            self?.stateDidChanged(state: state, previousState: previousState, command: command)
        }
        stateDidChanged(state: store.state, previousState: nil, command: nil)
        
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
        
        contentView.addSubview(leftUpEdgeView)
        contentView.addSubview(rightUpEdgeView)
        contentView.addSubview(rightDownEdgeView)
        contentView.addSubview(leftDownEdgeView)
        
        contentView.layer.addSublayer(maskLayer)
        
        contentView.setNeedsLayout()
        contentView.layoutIfNeeded()
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
    
    //MARK: gesture
    func pinchImageView(recognizer: UIPinchGestureRecognizer) {
        if !store.state.isCliping { return }
        
        if recognizer.state == .ended {
            let imageLeftUpPoint = contentView.convert(leftUpEdgeView.center, to: imageView)
            let imageRightDownPoint = contentView.convert(rightDownEdgeView.center, to: imageView)
            
            let showingRect = CGRect(x: imageLeftUpPoint.x, y: imageLeftUpPoint.y, width: imageRightDownPoint.x - imageLeftUpPoint.x, height: imageRightDownPoint.y - imageLeftUpPoint.y)
            store.dispatch(.panEdgeView(showingRect: showingRect))
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
        if !store.state.isCliping { return }
        
        if recognizer.state == .ended {
            let imageLeftUpPoint = contentView.convert(leftUpEdgeView.center, to: imageView)
            let imageRightDownPoint = contentView.convert(rightDownEdgeView.center, to: imageView)
            
            let showingRect = CGRect(x: imageLeftUpPoint.x, y: imageLeftUpPoint.y, width: imageRightDownPoint.x - imageLeftUpPoint.x, height: imageRightDownPoint.y - imageLeftUpPoint.y)
            store.dispatch(.panEdgeView(showingRect: showingRect))
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
        if !store.state.isCliping { return }
        
        if recognizer.state == .ended {
            resizeShowingArea()
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
        
        if recognizer.view! === leftUpEdgeView { // 左上
            centerX = max(imageViewFrame.origin.x, kEdgeViewWidth / 2, centerX)
            centerX = min(rightUpEdgeView.center.x - minDistant, centerX)
            centerY = max(imageViewFrame.origin.y, kEdgeViewWidth / 2, centerY)
            centerY = min(leftDownEdgeView.center.y - minDistant, centerY)
            
            leftUpViewCenter = CGPoint(x: centerX, y: centerY)
        } else if recognizer.view! === leftDownEdgeView { // 左下
            centerX = max(imageViewFrame.origin.x, kEdgeViewWidth / 2, centerX)
            centerX = min(rightDownEdgeView.center.x - minDistant, centerX)
            centerY = max(leftUpEdgeView.center.y + minDistant, centerY)
            centerY = min(imageViewFrame.maxY, contentViewHeight - kEdgeViewWidth / 2 ,centerY)
            
            leftUpViewCenter.x = centerX
            rightDownViewCenter.y = centerY
        } else if recognizer.view! === rightUpEdgeView { //右上
            centerX = max(self.leftUpEdgeView.center.x + minDistant, centerX)
            centerX = min(imageViewFrame.maxX, contentViewWidth - kEdgeViewWidth / 2, centerX)
            centerY = max(imageViewFrame.origin.y, kEdgeViewWidth / 2, centerY)
            centerY = min(self.rightDownEdgeView.center.y - minDistant ,centerY)
            
            leftUpViewCenter.y = centerY
            rightDownViewCenter.x = centerX
        } else { //rightDownEdgeView 右下
            centerX = max(self.leftDownEdgeView.center.x + minDistant, centerX)
            centerX = min(imageViewFrame.maxX, contentViewWidth - kEdgeViewWidth / 2, centerX)
            centerY = max(self.rightUpEdgeView.center.y + minDistant, centerY)
            centerY = min(imageViewFrame.maxY, contentViewHeight - kEdgeViewWidth / 2, centerY)
            
            rightDownViewCenter = CGPoint(x: centerX, y: centerY)
        }
        recognizer.setTranslation(CGPoint.zero, in: self.view)
        
        let imageLeftUpPoint = contentView.convert(leftUpViewCenter, to: imageView)
        let imageRightDownPoint = contentView.convert(rightDownViewCenter, to: imageView)
        
        let showingRect = CGRect(x: imageLeftUpPoint.x, y: imageLeftUpPoint.y, width: imageRightDownPoint.x - imageLeftUpPoint.x, height: imageRightDownPoint.y - imageLeftUpPoint.y)
        store.dispatch(.panEdgeView(showingRect: showingRect))
    }
    
    //MARK: update view
    private func resizeShowingArea() {
        let leftUpPoint = contentView.convert(leftUpEdgeView.center, to: imageView)
        let rightDownPoint = contentView.convert(rightDownEdgeView.center, to: imageView)
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
            
            let sr: CGRect
            if self.store.state.showingRect == nil {
                sr = self.imageView.bounds
            } else {
                sr = self.store.state.showingRect!
            }
            let leftUpPoint = self.imageView.convert(CGPoint(x: sr.origin.x, y: sr.origin.y), to: self.contentView)
            let rightDownPoint = self.imageView.convert(CGPoint(x: sr.maxX, y: sr.maxY), to: self.contentView)
            
            //masklayer
            let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: kScreenWidth, height: kScreenHeight))
            let showRect = CGRect(x: leftUpPoint.x, y: leftUpPoint.y, width: rightDownPoint.x - leftUpPoint.x, height: rightDownPoint.y - leftUpPoint.y)
            let showPath = UIBezierPath(rect: showRect).reversing()
            path.append(showPath)
            self.maskLayer.path = path.cgPath
            
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
    
    private func clipingStateChange() {
        leftDownEdgeView.isHidden = !store.state.isCliping
        leftUpEdgeView.isHidden = !store.state.isCliping
        rightDownEdgeView.isHidden = !store.state.isCliping
        rightUpEdgeView.isHidden = !store.state.isCliping
        
        var naviBarFrame = navigationController!.navigationBar.frame
        let toolBarTop: CGFloat
        let scale: CGFloat
        
        let showingRect: CGRect
        if store.state.showingRect == nil {
            showingRect = imageView.bounds
        } else {
            showingRect = store.state.showingRect!
        }
        let showingRectRatio = showingRect.size.width / showingRect.size.height
        
        let contentViewHeight: CGFloat = kScreenHeight - kStatusBarHeight - kNavigationBarHeight - GifEditViewBottomBar.height - GifEditToolBar.height
        if store.state.isCliping {
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
    
    func stateDidChanged(state: State, previousState: State?, command: Command?) {
        
//        if let command = command {
//            switch command {
//            case .loadToDos(let handler):
//                ToDoStore.shared.getToDoItems(completionHandler: handler)
//            case .someOtherCommand:
//                // Placeholder command.
//                break
//            }
//        }
        
        if previousState != nil && previousState!.isCliping != state.isCliping {
            clipingStateChange()
        }
        
        if previousState == nil || previousState!.showingRect != state.showingRect {
            updateMaskAndEdgeView(animated: false)
        }
        
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
            self.store.dispatch(.switchCliping)
        }
        toolBar.clipConfirmButtonHandler = {[unowned self] in
            self.store.dispatch(.switchCliping)
        }
        toolBar.clipCancelButtonHandler = {[unowned self] in
            self.store.dispatch(.switchCliping)
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
        //        let fillColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
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
}
