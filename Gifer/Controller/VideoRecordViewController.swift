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
}

class VideoRecordViewController: BaseViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    // MARK: property
    private let kVideoDirPath = "Video/"
    
    private lazy var topView: ViewRecordTopView = {
        let topView = ViewRecordTopView()
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
    
    private lazy var captureQueue: DispatchQueue = {
        return DispatchQueue(label: "com.lxy.videoCapture")
    }()
    private var isWriting: Bool = false
    private var firstSample: Bool = false
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
        configureCaptureSession()
        configureSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
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
    
    func configureSubviews() {
        edgesForExtendedLayout = .all
        view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        
        view.addSubview(topView)
        topView.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.height.equalTo(ViewRecordTopView.height)
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
        
        let layerHeight = kScreenWidth * 3 / 4
        captureVideoPreviewLayer!.frame = CGRect(x: 0, y: (kScreenHeight - layerHeight) / 2, width: kScreenWidth, height: layerHeight)
        captureVideoPreviewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(captureVideoPreviewLayer!)
        
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
            startRecording()
        } else {
            stopRecording()
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
        let oneToOneAction = UIAlertAction(title: "1:1", style: .default, handler: { (action) in
//            self.ratioStatus = .oneToOne
//            bottomBar.ratioStatus = .oneToOne
        })
        alertViewController.addAction(oneToOneAction)
        let fourToThreeAction = UIAlertAction(title: "4:3", style: .default, handler: { (action) in
//            self.ratioStatus = .fourToThree
//            bottomBar.ratioStatus = .fourToThree
        })
        alertViewController.addAction(fourToThreeAction)
        let sixteenToNineAction = UIAlertAction(title: "16:9", style: .default, handler: { (action) in
//            self.ratioStatus = .sixteenToNine
//            bottomBar.ratioStatus = .sixteenToNine
        })
        alertViewController.addAction(sixteenToNineAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: { (action) in
        })
        alertViewController.addAction(cancelAction)
        self.present(alertViewController, animated: true, completion: nil)
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
            
            let outputSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecH264,
                AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
                AVVideoWidthKey: 240,
                AVVideoHeightKey: 320,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 240 * 320 * 10,
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
        isWriting = false;
        
        captureQueue.async {[unowned self] in
            self.assetWriter?.finishWriting {
                printLog("finish")
                self.assetWriter = nil
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
}
