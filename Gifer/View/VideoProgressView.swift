//
//  VideoProgressView.swift
//  Gifer
//
//  Created by Peter Lee on 2017/9/1.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import SnapKit
import AVFoundation

enum VideoProgressViewEdgeType {
    case start
    case end
}

class VideoProgressView: UIView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    public static let height: CGFloat = 48
    public static let width: CGFloat = kScreenWidth - 24
    public static let edgeViewWidth: CGFloat = 12
    public static let paddingVertical: CGFloat = 4
    public static let cellPerPage = (VideoProgressView.width - VideoProgressView.edgeViewWidth * 2) / (VideoProgressView.height - VideoProgressView.paddingVertical)
    
    // MARK: property
    public var thumbnails: [VideoThumbnail] = [] {
        didSet {
            DispatchQueue.main.async {[unowned self] in
                self.collectionView.reloadData()
            }
        }
    }
    public let totalTime: CMTime
    public let visibleDuration: CGFloat
    public var currentTime: CMTime = CMTime(value: 0, timescale: 1) {
        didSet {
            let showingStartTime = secPerPx * collectionView.contentOffset.x
            var cursorCenterX = (CGFloat(CMTimeGetSeconds(currentTime)) - showingStartTime) / secPerPx + VideoProgressView.edgeViewWidth
            if cursorCenterX > VideoProgressView.width - VideoProgressView.edgeViewWidth {
                cursorCenterX = VideoProgressView.width - VideoProgressView.edgeViewWidth
            }
            timeCursor.center = CGPoint(x: cursorCenterX, y: VideoProgressView.height / 2)
        }
    }
    public var edgeChangeHandler: ((VideoProgressViewEdgeType, UIGestureRecognizerState, CMTime?) -> ())?
    
    private let minEdgeDistant: CGFloat = 5
    private let timeCursorWidth: CGFloat = 8
    private let cellId = "VideoThumbnailCellId"
    private let secPerPx: CGFloat
    
    private lazy var collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets.zero
        layout.scrollDirection = .horizontal
        
        let collectionView: UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.white
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(UINib(nibName: "VideoThumbnailCell", bundle: nil), forCellWithReuseIdentifier: self.cellId)
        collectionView.isScrollEnabled = self.visibleDuration < CGFloat(CMTimeGetSeconds(self.totalTime))
        collectionView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        return collectionView
    }()
    private lazy var leftEdgeView: UIImageView = {
        let leftEdgeView = self.configureEdgeView()
        leftEdgeView.image = #imageLiteral(resourceName: "left_edge_arrow")
        return leftEdgeView
    }()
    private lazy var rightEdgeView: UIImageView = {
        let rightEdgeView = self.configureEdgeView()
        rightEdgeView.image = #imageLiteral(resourceName: "right_edge_arrow")
        return rightEdgeView
    }()
    private lazy var gapLayer: CAShapeLayer = {
        let gapLayer = CAShapeLayer()
        let fillColor = #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)
        gapLayer.strokeColor = fillColor.cgColor
        gapLayer.lineWidth = 2
        gapLayer.path = self.gapPath()
        return gapLayer
    }()
    private lazy var timeCursor: UIView = {
        let timeCursor = UIView()
        timeCursor.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        timeCursor.frame = CGRect(x: VideoProgressView.edgeViewWidth - self.timeCursorWidth / 2, y: 0, width: self.timeCursorWidth, height: VideoProgressView.height)
        timeCursor.layer.cornerRadius = self.timeCursorWidth / 2
        return timeCursor
    }()
    
    init(totalTime: CMTime, visibleDuration: CGFloat) {
        self.totalTime = totalTime
        self.visibleDuration = visibleDuration
        self.secPerPx = visibleDuration / (VideoProgressView.width - VideoProgressView.edgeViewWidth * 2)
        super.init(frame: CGRect.zero)
        configureSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureSubviews() {
        self.backgroundColor = UIColor.clear
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.snp.centerY)
            make.height.equalTo(VideoProgressView.height - VideoProgressView.paddingVertical)
            make.right.equalTo(-VideoProgressView.edgeViewWidth)
            make.left.equalTo(VideoProgressView.edgeViewWidth)
        }
        
        addSubview(leftEdgeView)
        leftEdgeView.frame.origin = CGPoint(x: 0, y: 0)
        
        addSubview(rightEdgeView)
        rightEdgeView.frame.origin = CGPoint(x: VideoProgressView.width - VideoProgressView.edgeViewWidth, y: 0)
        
        layer.addSublayer(gapLayer)
        gapLayer.frame = CGRect(x: 0, y: 0, width: VideoProgressView.width, height: VideoProgressView.height)
        
        addSubview(timeCursor)
    }
    
    private func configureEdgeView() -> UIImageView {
        let edgeView = UIImageView(frame: CGRect(x: 0, y: 0, width: VideoProgressView.edgeViewWidth, height: VideoProgressView.height))
        edgeView.backgroundColor = #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)
        edgeView.isUserInteractionEnabled = true
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panEdgeView(recognizer:)))
        edgeView.addGestureRecognizer(gesture)
        return edgeView
    }
    
    func gapPath() -> CGPath {
        let path = UIBezierPath()
        
        let startX = leftEdgeView.frame.origin.x
        let endX = rightEdgeView.frame.maxX
        let verticalOffset = VideoProgressView.paddingVertical / 4
        
        path.move(to: CGPoint(x: startX, y: verticalOffset))
        path.addLine(to: CGPoint(x: endX, y: verticalOffset))
        
        path.move(to: CGPoint(x: startX, y: VideoProgressView.height - verticalOffset))
        path.addLine(to: CGPoint(x: endX, y: VideoProgressView.height - verticalOffset))
        
        return path.cgPath
    }
    
    // MARK: events
    func panEdgeView(recognizer: UIPanGestureRecognizer) {
        let edgeType: VideoProgressViewEdgeType
        var time: CMTime? = nil
        
        if recognizer.view! === leftEdgeView {
            edgeType = .start
        } else {
            edgeType = .end
        }
        
        switch recognizer.state {
        case .began:
            timeCursor.isHidden = true
        case .ended, .failed:
            timeCursor.isHidden = false
            let edgeViewX = recognizer.view!.frame.origin.x
            switch edgeType {
            case .start:
                time = CMTime(seconds: Double(secPerPx * (collectionView.contentOffset.x + edgeViewX)), preferredTimescale: 600)
            case .end:
                time = CMTime(seconds: Double(secPerPx * (collectionView.contentOffset.x + edgeViewX - VideoProgressView.edgeViewWidth)), preferredTimescale: 600)
            }
            
        default:
            let translation = recognizer.translation(in: self)
            var newX = recognizer.view!.frame.origin.x + translation.x
            
            switch edgeType {
            case .start:
                newX = newX < 0 ? 0 : newX
                let rightEdgeViewX = rightEdgeView.frame.origin.x
                newX = newX > rightEdgeViewX - (VideoProgressView.edgeViewWidth + minEdgeDistant) ? rightEdgeViewX - (VideoProgressView.edgeViewWidth + minEdgeDistant) : newX
                time = CMTime(seconds: Double(secPerPx * (collectionView.contentOffset.x + newX)), preferredTimescale: 600)
            case .end:
                newX = newX > VideoProgressView.width - VideoProgressView.edgeViewWidth ? VideoProgressView.width - VideoProgressView.edgeViewWidth : newX
                let leftEdgeViewX = leftEdgeView.frame.origin.x
                newX = newX < leftEdgeViewX + minEdgeDistant + minEdgeDistant ? leftEdgeViewX + minEdgeDistant + minEdgeDistant : newX
                time = CMTime(seconds: Double(secPerPx * (collectionView.contentOffset.x + newX - VideoProgressView.edgeViewWidth)), preferredTimescale: 600)
            }
            
            recognizer.view!.frame = CGRect(x: newX, y: 0, width: VideoProgressView.edgeViewWidth, height: VideoProgressView.height)
            gapLayer.path = gapPath()
            recognizer.setTranslation(CGPoint.zero, in: self)
        }
        if edgeChangeHandler != nil {
            edgeChangeHandler!(edgeType, recognizer.state, time)
        }
    }
    
    // MARK: delegate
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return thumbnails.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! VideoThumbnailCell
        cell.thumbnail = thumbnails[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let length = VideoProgressView.height - VideoProgressView.paddingVertical
        if indexPath.row == thumbnails.count - 1 {
            let lastCellWidth = CGFloat(thumbnails.count) * length - CGFloat(CMTimeGetSeconds(totalTime)) / secPerPx
            if lastCellWidth > 0 {
                return CGSize(width: lastCellWidth, height: length)
            }
        }
        return CGSize(width: length, height: length)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        timeCursor.isHidden = true
        if edgeChangeHandler != nil {
            edgeChangeHandler!(.start, .began, nil)
            edgeChangeHandler!(.end, .began, nil)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        timeCursor.isHidden = false
        if edgeChangeHandler != nil {
            
            let leftViewX = leftEdgeView.frame.origin.x
            let startTime = CMTime(seconds: Double(secPerPx * (collectionView.contentOffset.x + leftViewX)), preferredTimescale: 600)
            
            let rightViewX = rightEdgeView.frame.origin.x
            let endTime = CMTime(seconds: Double(secPerPx * (collectionView.contentOffset.x + rightViewX - VideoProgressView.edgeViewWidth)), preferredTimescale: 600)
            
            edgeChangeHandler!(.start, .ended, startTime)
            edgeChangeHandler!(.end, .ended, endTime)
        }
    }
}
