//
//  VideoProgressView.swift
//  Gifer
//
//  Created by Peter Lee on 2017/9/1.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import SnapKit

class VideoProgressView: UIView {
    
    public static let height: CGFloat = 48
    public static let width: CGFloat = kScreenWidth - 16
    
    // MARK: property
    private let kEdgeViewWidth: CGFloat = 12
    private let minEdgeDistant: CGFloat = 5
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        return scrollView
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
        gapLayer.fillColor = fillColor.cgColor
        return gapLayer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureSubviews() {
        self.backgroundColor = UIColor.clear
        
        addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.snp.centerY)
            make.height.equalTo(VideoProgressView.height - 4)
            make.right.equalTo(0)
            make.left.equalTo(0)
        }
        
        layer.addSublayer(gapLayer)
        gapLayer.frame = CGRect(x: 0, y: 0, width: VideoProgressView.width, height: VideoProgressView.height)
        
        addSubview(leftEdgeView)
        leftEdgeView.frame.origin = CGPoint(x: 0, y: 0)
        
        addSubview(rightEdgeView)
        rightEdgeView.frame.origin = CGPoint(x: VideoProgressView.width - kEdgeViewWidth, y: 0)
    }
    
    private func configureEdgeView() -> UIImageView {
        let edgeView = UIImageView(frame: CGRect(x: 0, y: 0, width: kEdgeViewWidth, height: VideoProgressView.height))
        edgeView.backgroundColor = #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)
        edgeView.isUserInteractionEnabled = true
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panEdgeView(recognizer:)))
        edgeView.addGestureRecognizer(gesture)
        return edgeView
    }
    
    // MARK: events
    func panEdgeView(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self)
        var newX = recognizer.view!.frame.origin.x + translation.x
        
        if recognizer.view! === leftEdgeView {
            newX = newX < 0 ? 0 : newX
            let rightEdgeViewX = rightEdgeView.frame.origin.x
            newX = newX > rightEdgeViewX - (kEdgeViewWidth + minEdgeDistant) ? rightEdgeViewX - (kEdgeViewWidth + minEdgeDistant) : newX
        } else {
            newX = newX > VideoProgressView.width - kEdgeViewWidth ? VideoProgressView.width - kEdgeViewWidth : newX
            let leftEdgeViewX = leftEdgeView.frame.origin.x
            newX = newX < leftEdgeViewX + minEdgeDistant + minEdgeDistant ? leftEdgeViewX + minEdgeDistant + minEdgeDistant : newX
        }
        
        recognizer.view!.frame = CGRect(x: newX, y: 0, width: kEdgeViewWidth, height: VideoProgressView.height)
        recognizer.setTranslation(CGPoint.zero, in: self)
    }
}
