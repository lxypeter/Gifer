//
//  NoticeViewManager.swift
//  Gifer
//
//  Created by Peter Lee on 2017/6/5.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit

class NoticeViewManager : NSObject {
    static let shared = NoticeViewManager()
    var font: UIFont = UIFont.systemFont(ofSize: 15)
    var textColor: UIColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
    var backgroundColor: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    var duration: Double = 3.0
    
    private override init() {}
    
    func pushNoticeView(_ noticeView: NoticeView, duration: Double) {
        
        let swipeGest = UISwipeGestureRecognizer(target: self, action: #selector(swipeNoticeView))
        swipeGest.direction = .up
        noticeView.addGestureRecognizer(swipeGest)
        
        UIApplication.shared.keyWindow!.addSubview(noticeView)
        
        var noticeViewHeight: CGFloat
        if noticeView.hasStatusBar {
            noticeViewHeight = 44 + 20
        } else {
            noticeViewHeight = 20
        }
        noticeView.frame = CGRect(x: 0, y: -noticeViewHeight, width: kScreenWidth, height: noticeViewHeight)
        
        UIView.animate(withDuration: 0.3, animations: {
            noticeView.frame = CGRect(x: 0, y: 0, width: kScreenWidth, height: noticeViewHeight)
        }) { (success) in
            if noticeView.triggeredSwipeGesture { return }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+duration) {
                UIView.animate(withDuration: 0.2, animations: {
                    noticeView.frame = CGRect(x: 0, y: -noticeViewHeight, width: kScreenWidth, height: noticeViewHeight)
                }) { (success) in
                    noticeView.removeFromSuperview()
                }
            }
        }
    }
    
    func swipeNoticeView(recognizer: UISwipeGestureRecognizer) {
        let noticeView: NoticeView = recognizer.view as! NoticeView
        noticeView.triggeredSwipeGesture = true
        
        var noticeViewHeight: CGFloat
        if noticeView.hasStatusBar {
            noticeViewHeight = 44 + 20
        } else {
            noticeViewHeight = 20
        }
        
        UIView.animate(withDuration: 0.2, animations: {
            noticeView.frame = CGRect(x: 0, y: -noticeViewHeight, width: kScreenWidth, height: noticeViewHeight)
        }) { (success) in
            noticeView.removeFromSuperview()
        }
    }
}

extension UIViewController {
    
    func showNotice(message: String) {
        let manager = NoticeViewManager.shared
        self.showNotice(message: message, duration: manager.duration)
    }
    
    func showNotice(message: String, duration: Double) {
        let manager = NoticeViewManager.shared
        let noticeView = NoticeView(frame: CGRect.zero, text: message, hasStatusBar: !self.prefersStatusBarHidden)
        manager.pushNoticeView(noticeView, duration: duration)
    }
}
