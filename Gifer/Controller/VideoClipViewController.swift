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
    
    var videoUrl: URL?
    var player: AVPlayer?
    
    private lazy var backButton: UIButton = {
        let backButton = UIButton()
        backButton.setBackgroundImage(#imageLiteral(resourceName: "back_white"), for: .normal)
        backButton.addTarget(self, action: #selector(backToLastController), for: .touchUpInside)
        return backButton
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
        let progressView = VideoProgressView()
        return progressView;
    }()
    
    convenience init(videoUrl: URL) {
        self.init()
        self.videoUrl = videoUrl
    }
    
    // MARK: life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
        configurePlayer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: OperationQueue.main) { [unowned self] (notification) in
            self.player?.seek(to: CMTime(value: 0, timescale: 1))
            self.player?.play()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    private func configureSubviews() {
        self.view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        
        view.addSubview(backButton)
        backButton.snp.makeConstraints { (make) in
            make.width.equalTo(24)
            make.height.equalTo(24)
            make.left.equalTo(15)
            make.top.equalTo(30)
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
        guard let url = videoUrl else {
            return
        }
        player = AVPlayer(url: url)
        
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
}
