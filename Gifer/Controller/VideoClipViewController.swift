//
//  VideoClipViewController.swift
//  Gifer
//
//  Created by Peter Lee on 2017/8/30.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import AVFoundation

class VideoClipViewController: BaseViewController {
    
    // MARK: property
    private let playerLayerOffsetRatio: CGFloat = -0.05
    private let maxVideoLength: CGFloat = 15 // second
    
    private var videoAsset: AVAsset?
    private var player: AVPlayer?
    private var timer: Timer?
    private var startTime: CMTime = CMTime(value: 0, timescale: 1)
    private var endTime: CMTime = CMTime(value: 0, timescale: 1)
    
    private lazy var topView: VideoClipTopView = {
        let topView = VideoClipTopView()
        topView.backButtonHandler = { [unowned self] in self.backToLastController() }
        topView.nextButtonHandler = { [unowned self] in self.clickNextButton() }
        return topView
    }()
    private lazy var playButton: UIButton = {
        let playButton = UIButton()
        playButton.isSelected = true
        playButton.setBackgroundImage(#imageLiteral(resourceName: "play"), for: .normal)
        playButton.setBackgroundImage(#imageLiteral(resourceName: "pause"), for: .selected)
        playButton.addTarget(self, action: #selector(clickPlayButton), for: .touchUpInside)
        return playButton
    }()
    private lazy var progressView: VideoProgressView = {
        let duration = self.videoAsset!.duration
        let totalSecond = CGFloat(CMTimeGetSeconds(duration))
        let visibleDuration = totalSecond > self.maxVideoLength ? self.maxVideoLength : totalSecond
        
        let progressView = VideoProgressView(totalTime: duration, visibleDuration: visibleDuration)
        progressView.edgeChangeHandler = {[unowned self] (type, state, time) in
            switch state {
            case .began:
                self.playButton.isEnabled = false
                if self.player?.timeControlStatus == .playing {
                    self.player?.pause()
                }
            case .ended, .failed:
                self.playButton.isEnabled = true
                switch type {
                case .start:
                    self.startTime = time!
                case .end:
                    self.endTime = time!
                }
                
                self.topView.currentLength = CMTimeGetSeconds(self.endTime) - CMTimeGetSeconds(self.startTime)
                
                self.playAt(self.startTime)
            case .changed:
                self.player?.seek(to: time!)
            default: break
            }
        }
        return progressView;
    }()
    
    convenience init(videoAsset: AVAsset) {
        self.init()
        self.videoAsset = videoAsset
    }
    
    // MARK: life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
        configurePlayer()
        self.progressView.thumbnails = thumbnailsOfVideo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: OperationQueue.main) { [unowned self] (notification) in
            self.playAt(self.startTime)
        }
        
        player?.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        NotificationCenter.default.removeObserver(self)
        
        player?.pause()
    }
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    private func configureSubviews() {
        self.view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        
        view.addSubview(topView)
        topView.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.height.equalTo(VideoClipTopView.height)
        }
        
        view.addSubview(playButton)
        playButton.snp.makeConstraints { (make) in
            make.width.equalTo(32)
            make.height.equalTo(32)
            make.bottom.equalTo(-10)
            make.centerX.equalTo(view.snp.centerX)
        }
        
        view.addSubview(progressView)
        progressView.snp.makeConstraints { (make) in
            make.bottom.equalTo(playButton.snp.top).offset(-15)
            make.centerX.equalTo(view.snp.centerX)
            make.width.equalTo(VideoProgressView.width)
            make.height.equalTo(VideoProgressView.height)
        }
    }
    
    func configurePlayer() {
        
        guard let videoAsset = videoAsset else {
            navigationController!.popViewController(animated: true)
            return
        }
        
        // configure endtime
        let validEndSecond = CMTimeGetSeconds(videoAsset.duration) > Double(maxVideoLength) ? Double(maxVideoLength) : CMTimeGetSeconds(videoAsset.duration)
        endTime = CMTime(seconds: validEndSecond, preferredTimescale: 600)
        
        // update topView
        topView.totalLength = CMTimeGetSeconds(videoAsset.duration)
        topView.currentLength = validEndSecond
        
        // configure player
        let playItem = AVPlayerItem(asset: videoAsset)
        player = AVPlayer(playerItem: playItem)
        player?.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 600), queue: DispatchQueue.main, using: { [unowned self](time) in
            self.progressView.currentTime = time
            
            if time >= self.endTime {
                self.playAt(self.startTime)
            }
        })
        
        // preview layer
        var videoWidthHeightRatio: CGFloat = 1
        for track in videoAsset.tracks {
            if track.mediaType == AVMediaType.video {
                let realSize = track.naturalSize.applying(track.preferredTransform)
                videoWidthHeightRatio = fabs(realSize.width) / fabs(realSize.height)
            }
        }
        let playerLayer = AVPlayerLayer(player: player)
        let y = kScreenHeight * (0.5 + playerLayerOffsetRatio) - kScreenWidth / 2
        if videoWidthHeightRatio > 1 {
            playerLayer.frame = CGRect(x: 0, y: y, width: kScreenWidth, height: kScreenWidth)
        } else {
            let width = videoWidthHeightRatio * kScreenWidth
            playerLayer.frame = CGRect(x: (kScreenWidth - width) / 2, y: y, width: width, height: kScreenWidth)
        }
        
        view.layer.addSublayer(playerLayer)
        
        player!.play()
    }
    
    // MARK: events
    @objc func clickPlayButton() {
        playButton.isSelected = !playButton.isSelected
        
        if !playButton.isSelected {
            player!.pause()
        } else {
            player!.play()
        }
    }
    
    func clickNextButton() {
        guard let videoAsset = videoAsset else {
            return
        }
        
        let imageGenerator = AVAssetImageGenerator(asset: videoAsset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 500, height: 500)
        let tolerance = CMTime(seconds: 0.01, preferredTimescale: 600)
        imageGenerator.requestedTimeToleranceAfter = tolerance
        imageGenerator.requestedTimeToleranceBefore = tolerance
        
        let duration = CMTimeGetSeconds(self.endTime) - CMTimeGetSeconds(self.startTime)
        let framePerSec: Double = 10

        var totalCount = Int(duration * framePerSec)
        
        showHudWithMsg(msg: "正在处理...")
        var photos: [Photo] = []
        
        var times: [NSValue] = []
        for count in 0 ..< totalCount {
            times.append(CMTime(seconds: 1 / framePerSec * Double(count) + CMTimeGetSeconds(self.startTime), preferredTimescale: 600) as NSValue)
        }
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: times) {[unowned self](requestedTime, cgImage, actualTime, result, error) in
            autoreleasepool {
                totalCount -= 1
                
                if result == .succeeded {
                    guard let videoFrame = cgImage else {
                        return
                    }
                    let image = UIImage(cgImage: videoFrame)
                    let photo = Photo(fullImage: image)
                    photo.videoFrameTime = actualTime
                    photos.append(photo)
                }
                
                if totalCount == 0 {
                    photos.sort(by: { (firstThumbnail, secThumbnail) -> Bool in
                        return CMTimeGetSeconds(firstThumbnail.videoFrameTime!) < CMTimeGetSeconds(secThumbnail.videoFrameTime!)
                    })
                    DispatchQueue.main.async {[unowned self] in
                        self.hideHud()
                        let ctrl = GifEditViewController()
                        ctrl.selectedArray = photos
                        ctrl.frameInterval = Float(1 / framePerSec)
                        self.navigationController?.pushViewController(ctrl, animated: true)
                    }
                }
            }
        }
    }
    
    // MARK: video method
    func playAt(_ time: CMTime) {
        player?.seek(to: time)
        player?.play()
        playButton.isSelected = true
    }
    
    func thumbnailsOfVideo() -> [VideoThumbnail] {
        guard let videoAsset = videoAsset else {
            return []
        }
        let totalSecond = CGFloat(CMTimeGetSeconds(videoAsset.duration))
        let interval = progressView.visibleDuration / VideoProgressView.cellPerPage
        
        let totalCount = (totalSecond / interval) > (CGFloat(Int(totalSecond / interval))) ? Int(totalSecond / interval) + 1 : Int(totalSecond / interval)
        
        var thumbnails: [VideoThumbnail] = []
        for count in 0 ..< totalCount {
            let time = CMTime(seconds: Double(interval * CGFloat(count)), preferredTimescale: 600)
            let thumbnail = VideoThumbnail(asset: videoAsset, requestedTime: time, actualTime: time)
            thumbnails.append(thumbnail)
        }
        
        return thumbnails
    }
}
