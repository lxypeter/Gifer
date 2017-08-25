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
}

class VideoRecordViewController: BaseViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    // MARK: property
    private let kVideoDirPath = "Video/"
    
    private lazy var backButton: UIButton = {
        let backButton = UIButton()
        backButton.setBackgroundImage(#imageLiteral(resourceName: "back_white"), for: .normal)
        backButton.addTarget(self, action: #selector(backToLastController), for: .touchUpInside)
        return backButton
    }()
    private lazy var shotButton: UIButton = {
        let shotButton = UIButton()
        shotButton.setBackgroundImage(#imageLiteral(resourceName: "shotButton"), for: .normal)
        shotButton.setBackgroundImage(#imageLiteral(resourceName: "stopButton"), for: .selected)
        shotButton.addTarget(self, action: #selector(clickShotButton), for: .touchUpInside)
        return shotButton
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
        
        view.addSubview(backButton)
        backButton.snp.makeConstraints { (make) in
            make.width.equalTo(24)
            make.height.equalTo(24)
            make.left.equalTo(15)
            make.top.equalTo(25)
        }
        
        view.addSubview(shotButton)
        shotButton.snp.makeConstraints { (make) in
            make.width.equalTo(60)
            make.height.equalTo(60)
            make.centerX.equalTo(view.snp.centerX)
            make.bottom.equalTo(-25)
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
        
        captureVideoPreviewLayer!.frame = view.layer.bounds
        captureVideoPreviewLayer!.frame = CGRect(x: 0, y: 0, width: kScreenWidth, height: kScreenWidth * 3 / 4)
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
            
        } else {
            isWriting = false;
            
            captureQueue.async {[unowned self] in
                self.assetWriter?.finishWriting {
                    printLog("finish")
                    self.assetWriter = nil
                }
            }
        }
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
    
}
