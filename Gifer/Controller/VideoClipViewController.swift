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
    
    private var videoAsset: AVURLAsset?
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
            default: break
            }
        }
        return progressView;
    }()
    
    convenience init(videoAsset: AVURLAsset) {
        self.init()
        self.videoAsset = videoAsset
    }
    
    // MARK: life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
        configurePlayer()
        thumbnailsOfVideo(){ [unowned self] thumbnails in
            self.progressView.thumbnails = thumbnails
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: OperationQueue.main) { [unowned self] (notification) in
            self.playAt(self.startTime)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        NotificationCenter.default.removeObserver(self)
        if player?.timeControlStatus == .playing {
            player?.pause()
        }
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
        guard let url = videoAsset?.url else {
            navigationController!.popViewController(animated: true)
            return
        }
        
        // configure endtime
        let validEndSecond = CMTimeGetSeconds(videoAsset!.duration) > Double(maxVideoLength) ? Double(maxVideoLength) : CMTimeGetSeconds(videoAsset!.duration)
        endTime = CMTime(seconds: validEndSecond, preferredTimescale: 10)
        
        // update topView
        topView.totalLength = CMTimeGetSeconds(videoAsset!.duration)
        topView.currentLength = validEndSecond
        
        // configure player
        player = AVPlayer(url: url)
        player?.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 10), queue: DispatchQueue.main, using: { [unowned self](time) in
            self.progressView.currentTime = time
            
            if time >= self.endTime {
                self.playAt(self.startTime)
            }
        })
        
        // preview layer
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = CGRect(x: 0, y: kScreenHeight * (0.5 + playerLayerOffsetRatio) - kScreenHeight / 2, width: kScreenWidth, height: kScreenHeight)
        view.layer.addSublayer(playerLayer)
        
        player!.play()
    }
    
    // MARK: events
    func clickPlayButton() {
        playButton.isSelected = !playButton.isSelected
        
        if !playButton.isSelected {
            player!.pause()
        } else {
            player!.play()
        }
    }
    
    func clickNextButton() {
//        let ctrl = GifEditViewController()
//        ctrl.selectedArray = selectedArray
//        navigationController?.pushViewController(ctrl, animated: true)
    }
    
    // MARK: video method
    func playAt(_ time: CMTime) {
        player?.seek(to: time)
        player?.play()
        playButton.isSelected = true
    }
    
    func thumbnailsOfVideo(completionHandler handler: @escaping ([VideoThumbnail])->()) {
        guard let videoAsset = videoAsset else {
            return
        }
        
        let imageGenerator = AVAssetImageGenerator(asset: videoAsset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 0, height: VideoProgressView.height * 3)
        
        let totalSecond = CGFloat(CMTimeGetSeconds(videoAsset.duration))
        let interval = progressView.visibleDuration / VideoProgressView.cellPerPage
        
        var totalCount = (totalSecond / interval) > (CGFloat(Int(totalSecond / interval))) ? Int(totalSecond / interval) + 1 : Int(totalSecond / interval)
        
        var times: [NSValue] = []
        for count in 0 ... totalCount {
            times.append(CMTime(value: CMTimeValue(interval * CGFloat(count)), timescale: 1) as NSValue)
        }
        
        showHudWithMsg(msg: "正在加载...")
        var thumbnails: [VideoThumbnail] = []
        imageGenerator.generateCGImagesAsynchronously(forTimes: times) {[unowned self](requestedTime, cgImage, actualTime, result, error) in
            if result == .succeeded {
                totalCount -= 1
                guard let thumbnailCgImage = cgImage else {
                    return
                }
                let image = UIImage(cgImage: thumbnailCgImage)
                let thumbnail = VideoThumbnail(thumbnail: image, requestedTime: requestedTime, actualTime: actualTime)
                thumbnails.append(thumbnail)
                
                if totalCount == 0 {
                    self.hideHud()
                    thumbnails.sort(by: { (firstThumbnail, secThumbnail) -> Bool in
                        return CMTimeGetSeconds(firstThumbnail.actualTime) > CMTimeGetSeconds(secThumbnail.actualTime)
                    })
                    handler(thumbnails)
                }
            }
        }
    }
}
