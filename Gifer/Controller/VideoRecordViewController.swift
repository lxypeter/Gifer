//
//  VideoRecordViewController.swift
//  Gifer
//
//  Created by Peter Lee on 2017/8/24.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import AVFoundation
import SnapKit

enum VideoCaptureError: Error {
    case FailToInitSession
    case FailToInitInput
    case FailToSwitchFlashMode
    case FailToFocus
}

class VideoRecordViewController: BaseViewController, AVCaptureVideoDataOutputSampleBufferDelegate, CAAnimationDelegate {

    // MARK: property
    private let kVideoDirPath = "Video/"
    private let kMaxVideoLength: CFTimeInterval = 15
    private let kRecordingAnimation = "kRecordingAnimation"
    private let previewLayerOffsetRatio: CGFloat = -0.05
    
    private lazy var topView: VideoRecordTopView = {
        let topView = VideoRecordTopView()
        topView.backButtonHandler = { [unowned self] in self.backToLastController() }
        topView.flashSwitchHandler = { [unowned self] flashMode in
            return self.switchFlashMode(flashMode)
        }
        return topView
    }()
    private lazy var shotButton: UIButton = {
        let shotButton = UIButton()
        shotButton.setBackgroundImage(#imageLiteral(resourceName: "shotButton"), for: .normal)
        shotButton.setBackgroundImage(#imageLiteral(resourceName: "stopButton"), for: .selected)
        shotButton.addTarget(self, action: #selector(clickShotButton), for: .touchUpInside)
        return shotButton
    }()
    private lazy var camaraButton: UIButton = {
        let camaraButton = UIButton()
        camaraButton.setBackgroundImage(#imageLiteral(resourceName: "camera_switch"), for: .normal)
        camaraButton.addTarget(self, action: #selector(clickCamaraButton), for: .touchUpInside)
        return camaraButton
    }()
    private lazy var ratioButton: UIButton = {
        let ratioButton = UIButton()
        ratioButton.setBackgroundImage(#imageLiteral(resourceName: "ratio_4_3_white"), for: .normal)
        ratioButton.addTarget(self, action: #selector(clickRatioButton), for: .touchUpInside)
        return ratioButton
    }()
    private lazy var focusLayer: CAShapeLayer = {
        let focusLayer = CAShapeLayer()
        focusLayer.fillColor = UIColor.clear.cgColor
        let strokeColor = #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)
        focusLayer.strokeColor = strokeColor.cgColor
        focusLayer.lineWidth = 1.0
        focusLayer.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        let borderPath = UIBezierPath(rect: focusLayer.frame)
        let branchLength: CGFloat = 5
        borderPath.move(to: CGPoint(x: focusLayer.frame.width / 2, y: 0))
        borderPath.addLine(to: CGPoint(x: focusLayer.frame.width / 2, y: branchLength))
        borderPath.move(to: CGPoint(x: focusLayer.frame.width, y: focusLayer.frame.height / 2))
        borderPath.addLine(to: CGPoint(x: focusLayer.frame.width - branchLength, y: focusLayer.frame.height / 2))
        borderPath.move(to: CGPoint(x: focusLayer.frame.width / 2, y: focusLayer.frame.height))
        borderPath.addLine(to: CGPoint(x: focusLayer.frame.width / 2, y: focusLayer.frame.height - branchLength))
        borderPath.move(to: CGPoint(x: 0, y: focusLayer.frame.height / 2))
        borderPath.addLine(to: CGPoint(x: branchLength, y: focusLayer.frame.height / 2))
        
        focusLayer.path = borderPath.cgPath
        focusLayer.opacity = 0
        return focusLayer
    }()
    private lazy var recordingLayer: CAShapeLayer = {
        let center = CGPoint(x: self.shotButton.bounds.width / 2, y: self.shotButton.bounds.height / 2)
        let recordingLayer = CAShapeLayer()
        recordingLayer.path = UIBezierPath(arcCenter: center, radius: self.shotButton.bounds.width / 2, startAngle: -.pi / 2, endAngle: .pi / 2 * 3, clockwise: true).cgPath
        recordingLayer.strokeColor = UIColor.black.cgColor
        recordingLayer.lineWidth = 8
        recordingLayer.fillColor = UIColor.clear.cgColor
        return recordingLayer
    }()
    
    private lazy var captureQueue: DispatchQueue = {
        return DispatchQueue(label: "com.lxy.videoCapture")
    }()
    private var isWriting: Bool = false {
        didSet {
            DispatchQueue.main.async { [unowned self] in
                self.topView.isHidden = self.isWriting
                self.ratioButton.isHidden = self.isWriting
                self.camaraButton.isHidden = self.isWriting
            }
        }
    }
    private var firstSample: Bool = false
    private var currentVideoRatio: RatioStatus = .fourToThree {
        didSet {
            let layerHeight: CGFloat
            switch self.currentVideoRatio {
            case .fourToThree:
                ratioButton.setBackgroundImage(#imageLiteral(resourceName: "ratio_4_3_white"), for: .normal)
                layerHeight = kScreenWidth / RatioStatus.fourToThree.floatValue
            case .sixteenToNine:
                ratioButton.setBackgroundImage(#imageLiteral(resourceName: "ratio_16_9_white"), for: .normal)
                layerHeight = kScreenWidth / RatioStatus.sixteenToNine.floatValue
            default:
                ratioButton.setBackgroundImage(#imageLiteral(resourceName: "ratio_1_1_white"), for: .normal)
                layerHeight = kScreenWidth / RatioStatus.oneToOne.floatValue
            }
            captureVideoPreviewLayer!.frame = CGRect(x: 0, y: kScreenHeight * (0.5 + previewLayerOffsetRatio) - layerHeight / 2, width: kScreenWidth, height: layerHeight)
        }
    }
    private let captureSession: AVCaptureSession = AVCaptureSession()
    private var currentVideoInput: AVCaptureDeviceInput?
    private var assetWriter: AVAssetWriter?
    private var assetWriterVideoInput: AVAssetWriterInput?
    private var assetWriterInputPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer?
    private lazy var videoDataOutput: AVCaptureVideoDataOutput = {
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: kCVPixelFormatType_32BGRA]
        videoDataOutput.alwaysDiscardsLateVideoFrames = false
        videoDataOutput.setSampleBufferDelegate(self, queue: self.captureQueue)
        return videoDataOutput
    }()
    
    // MARK: life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        if checkCamaraAuth() {
            configureCaptureSession()
        }
        configureSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        if !captureSession.isRunning {
            captureQueue.async {[unowned self] in
                self.captureSession.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        if captureSession.isRunning {
            captureQueue.async {[unowned self] in
                self.captureSession.stopRunning()
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    func checkCamaraAuth() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        if status == .denied {
            let alertViewController = UIAlertController(title: nil, message: "请在\"设置\"中允许访问相机", preferredStyle: .alert)
            let confrimAction = UIAlertAction(title: "确定", style: .default, handler: { [unowned self](action) in
                self.navigationController!.popViewController(animated: true)
            })
            alertViewController.addAction(confrimAction)
            present(alertViewController, animated: true, completion: nil)
            return false
        }
        return true
    }
    
    func configureSubviews() {
        edgesForExtendedLayout = .all
        view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        
        view.addSubview(topView)
        topView.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.height.equalTo(VideoRecordTopView.height)
        }
        
        view.addSubview(shotButton)
        shotButton.snp.makeConstraints { (make) in
            make.width.equalTo(60)
            make.height.equalTo(60)
            make.centerX.equalTo(view.snp.centerX)
            make.bottom.equalTo(-25)
        }
        
        view.addSubview(camaraButton)
        camaraButton.snp.makeConstraints { (make) in
            make.width.equalTo(30)
            make.height.equalTo(30)
            make.right.equalTo(-30)
            make.centerY.equalTo(shotButton.snp.centerY)
        }
        
        view.addSubview(ratioButton)
        ratioButton.snp.makeConstraints { (make) in
            make.width.equalTo(30)
            make.height.equalTo(30)
            make.left.equalTo(30)
            make.centerY.equalTo(shotButton.snp.centerY)
        }
        
        captureVideoPreviewLayer?.addSublayer(focusLayer)
    }
    
    func configureCaptureSession() {
        guard let camara = getCamara(of: .back) else {
            showNotice(message: "无可用相机")
            navigationController?.popViewController(animated: true)
            return
        }
        
        do {
            currentVideoInput = try AVCaptureDeviceInput(device: camara)
            if captureSession.canAddInput(currentVideoInput) && captureSession.canAddOutput(videoDataOutput) {
                captureSession.addInput(currentVideoInput)
                captureSession.addOutput(videoDataOutput)
                
                // 防抖
                if currentVideoInput!.device.activeFormat.isVideoStabilizationModeSupported(.cinematic) {
                    let captureConnection = videoDataOutput.connection(withMediaType: AVMediaTypeVideo)
                    captureConnection?.preferredVideoStabilizationMode = .cinematic
                }
                
                guard let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession) else {
                    throw VideoCaptureError.FailToInitSession
                }
                captureVideoPreviewLayer = previewLayer
                
            } else {
                throw VideoCaptureError.FailToInitSession
            }
        } catch {
            showNotice(message: "相机初始化失败")
            navigationController?.popViewController(animated: true)
            return
        }
        
        let layerHeight = kScreenWidth / RatioStatus.fourToThree.floatValue
        captureVideoPreviewLayer!.frame = CGRect(x: 0, y: kScreenHeight * (0.5 + previewLayerOffsetRatio) - layerHeight / 2, width: kScreenWidth, height: layerHeight)
        captureVideoPreviewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(captureVideoPreviewLayer!)
        
        // 对焦手势
        let focusGest = UITapGestureRecognizer(target: self, action: #selector(tapToFocus(_:)))
        view.addGestureRecognizer(focusGest)
        
        captureQueue.async {[unowned self] in
            self.captureSession.startRunning()
        }
    }
    
    func getCamara(of position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        if #available(iOS 10.0, *) {
            let discoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: position)
            guard let devices = discoverySession?.devices else {
                return nil
            }
            for device in devices {
                if device.position == position {
                    return device
                }
            }
        } else {
            let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! [AVCaptureDevice]
            for device in devices {
                if device.position == position {
                    return device
                }
            }
        }
        return nil
    }

    // MARK: events
    func clickShotButton() {
        shotButton.isSelected = !shotButton.isSelected
        
        if shotButton.isSelected { // begin to record
            let recordingAnimation: CABasicAnimation = CABasicAnimation(keyPath: "strokeEnd")
            recordingAnimation.delegate = self
            recordingAnimation.fromValue = 0
            recordingAnimation.toValue = 1
            recordingAnimation.duration = kMaxVideoLength
            shotButton.layer.addSublayer(recordingLayer)
            recordingLayer.add(recordingAnimation, forKey: kRecordingAnimation)
            
            startRecording()
        } else {
            recordingLayer.removeAllAnimations()
        }
    }
    
    func clickCamaraButton() {
        if camaraButton.isSelected { return }
        camaraButton.isSelected = true
        switchCamara()
        camaraButton.isSelected = false
    }
    
    func clickRatioButton() {
        let alertViewController = UIAlertController(title: "视频宽高比", message: nil, preferredStyle: .actionSheet)
        let oneToOneAction = UIAlertAction(title: "1:1", style: .default, handler: { [unowned self](action) in
            self.currentVideoRatio = .oneToOne
        })
        alertViewController.addAction(oneToOneAction)
        let fourToThreeAction = UIAlertAction(title: "4:3", style: .default, handler: { [unowned self](action) in
            self.currentVideoRatio = .fourToThree
        })
        alertViewController.addAction(fourToThreeAction)
        let sixteenToNineAction = UIAlertAction(title: "16:9", style: .default, handler: { [unowned self](action) in
            self.currentVideoRatio = .sixteenToNine
        })
        alertViewController.addAction(sixteenToNineAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: { (action) in
        })
        alertViewController.addAction(cancelAction)
        present(alertViewController, animated: true, completion: nil)
    }
    
    func tapToFocus(_ recognizer: UIGestureRecognizer) {
        var touchPoint = recognizer.location(in: view)
        touchPoint.y = touchPoint.y - captureVideoPreviewLayer!.frame.minY
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        focusLayer.position = touchPoint
        CATransaction.commit()
        
        let focusAnimationGroup: CAAnimationGroup = CAAnimationGroup()
        focusAnimationGroup.isRemovedOnCompletion = false
        focusAnimationGroup.fillMode = kCAFillModeForwards;
        focusAnimationGroup.duration = 3
        
        let opacityAmt = CAKeyframeAnimation(keyPath: "opacity")
        opacityAmt.values = [1, 0]
        opacityAmt.keyTimes = [0.9, 1]
        
        let transformAmt = CAKeyframeAnimation(keyPath: "transform.scale")
        transformAmt.values = [1.5, 1, 1]
        transformAmt.keyTimes = [0, 0.05, 1]
        
        focusAnimationGroup.animations = [opacityAmt, transformAmt]
        focusLayer.add(focusAnimationGroup, forKey: nil)
        
        let capturePoint = captureVideoPreviewLayer!.captureDevicePointOfInterest(for: touchPoint)
        
        focusAtPoint(capturePoint)
    }
    
    // MARK: delegate
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if !isWriting { return }
        
        let formatDesc: CMFormatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)!
        
        let mediaType: CMMediaType = CMFormatDescriptionGetMediaType(formatDesc)
        
        if mediaType != kCMMediaType_Video { return }
        
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        if firstSample {
            if assetWriter!.startWriting() {
                assetWriter?.startSession(atSourceTime: timestamp)
            }
            firstSample = false
        }
        let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        if assetWriterVideoInput!.isReadyForMoreMediaData {
            assetWriterInputPixelBufferAdaptor?.append(imageBuffer, withPresentationTime: timestamp)
        }
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        shotButton.isSelected = false
        recordingLayer.removeFromSuperlayer()
        stopRecording()
    }
    
    // MARK: video method
    func startRecording() {
        let videoDirPath = NSTemporaryDirectory().appending(kVideoDirPath)
        let isDirExist = createFolderIfNotExist(path: videoDirPath)
        if !isDirExist {
            showNotice(message: "创建视频失败！")
            shotButton.isSelected = false
            return
        }
        let outputPath = videoDirPath.appending("\(timeStamp()).mov")
        let url = URL(fileURLWithPath: outputPath)
        printLog("\(outputPath)")
        
        captureQueue.async {[unowned self] in
            guard let aw = try? AVAssetWriter(url: url, fileType: AVFileTypeQuickTimeMovie) else {
                self.showNotice(message: "创建视频失败！")
                self.shotButton.isSelected = false
                return
            }
            self.assetWriter = aw
            
            let videoWidth: CGFloat = 1000
            let videoHeight: CGFloat
            switch self.currentVideoRatio {
            case .fourToThree:
                videoHeight = videoWidth / RatioStatus.fourToThree.floatValue
            case .sixteenToNine:
                videoHeight = videoWidth / RatioStatus.sixteenToNine.floatValue
            default:
                videoHeight = videoWidth / RatioStatus.oneToOne.floatValue
            }
            
            let outputSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecH264,
                AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
                AVVideoWidthKey: videoHeight,
                AVVideoHeightKey: videoWidth,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: videoHeight * videoWidth * 10,
                    AVVideoMaxKeyFrameIntervalKey: 10,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel
                ]
            ]
            let writerInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputSettings)
            writerInput.expectsMediaDataInRealTime = true
            let transform: CGAffineTransform
            switch UIDevice.current.orientation {
            case .landscapeRight:
                transform = CGAffineTransform(rotationAngle: .pi)
            case .portraitUpsideDown:
                transform = CGAffineTransform(rotationAngle: .pi / 2 * 3)
            case .portrait, .faceUp, .faceDown:
                transform = CGAffineTransform(rotationAngle: .pi / 2)
            default:
                transform = .identity
            }
            writerInput.transform = transform
            self.assetWriterVideoInput = writerInput
            
            if self.assetWriter!.canAdd(self.assetWriterVideoInput!) {
                self.assetWriter!.add(self.assetWriterVideoInput!)
            } else {
                self.showNotice(message: "创建视频失败！")
                self.shotButton.isSelected = false
                return
            }
            
            let bufferAttributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: 480,
                kCVPixelBufferHeightKey as String: 320,
                kCVPixelFormatOpenGLESCompatibility as String: kCFBooleanTrue
            ]
            self.assetWriterInputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: bufferAttributes)
            
            self.isWriting = true
            self.firstSample = true
        }
    }
    
    func stopRecording() {
        if !isWriting { return }
        isWriting = false;
        
        captureQueue.async {[unowned self] in
            self.assetWriter?.finishWriting {
                printLog("finish")
                let outputURL = self.assetWriter!.outputURL
                let asset = AVURLAsset(url: outputURL)
                let time = asset.duration
                
                if CMTimeGetSeconds(time) < 1 {
                    self.showNotice(message: "视频时间太短")
                } else {
                    DispatchQueue.main.async {
                        let ctrl = VideoClipViewController(videoAsset: asset)
                        self.assetWriter = nil
                        self.navigationController!.pushViewController(ctrl, animated: true)
                    }
                }
            }
        }
    }
    
    func switchCamara() {
        camaraButton.isSelected = true
        guard let currentDevice = currentVideoInput?.device else {
            showNotice(message: "相机初始化失败")
            return
        }
        let currentPosition = currentDevice.position
        let nextPosition: AVCaptureDevicePosition
        switch currentPosition {
        case .back:
            nextPosition = .front
            topView.isFlashButtonEnable = false
        default:
            nextPosition = .back
            topView.isFlashButtonEnable = true
        }
        let nextDevice = getCamara(of: nextPosition)
        do {
            let nextVideoInput = try AVCaptureDeviceInput(device: nextDevice)
            captureSession.beginConfiguration()
            captureSession.removeInput(currentVideoInput!)
            if captureSession.canAddInput(nextVideoInput) {
                captureSession.addInput(nextVideoInput)
            } else {
                throw VideoCaptureError.FailToInitInput
            }
            captureSession.commitConfiguration()
            currentVideoInput = nextVideoInput
        } catch {
            showNotice(message: "相机初始化失败")
            return
        }
        return
    }
    
    func switchFlashMode(_ flashMode: AVCaptureTorchMode) -> Bool {
        var result = false
        do {
            guard let currentDevice = currentVideoInput?.device else {
                throw VideoCaptureError.FailToSwitchFlashMode
            }
            try currentDevice.lockForConfiguration()
            if currentDevice.isTorchModeSupported(flashMode) {
                currentDevice.torchMode = flashMode
                result = true
            }
            currentDevice.unlockForConfiguration()
        } catch {
            showNotice(message: "闪光灯切换失败")
        }
        return result
    }
    
    func focusAtPoint(_ capturePoint: CGPoint) {
        do {
            guard let currentDevice = currentVideoInput?.device else {
                throw VideoCaptureError.FailToFocus
            }
            try currentDevice.lockForConfiguration()
            
            if currentDevice.isFocusPointOfInterestSupported && currentDevice.isFocusModeSupported(.continuousAutoFocus) {
                currentDevice.focusMode = .continuousAutoFocus
                currentDevice.focusPointOfInterest = capturePoint
            }
            
            if currentDevice.isExposurePointOfInterestSupported && currentDevice.isExposureModeSupported(.continuousAutoExposure) {
                currentDevice.exposureMode = .continuousAutoExposure
                currentDevice.exposurePointOfInterest = capturePoint
            }
            
            currentDevice.unlockForConfiguration()
        } catch {
            showNotice(message: "相机对焦失败")
        }
    }
}
