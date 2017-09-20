//
//  WeChatActivity.swift
//  Gifer
//
//  Created by Peter Lee on 2017/9/14.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import MonkeyKing

class WeChatActivity: UIActivity {
    override class var activityCategory: UIActivityCategory {
        get {
            return .share
        }
    }
    override var activityTitle: String? {
        get {
            return "微信"
        }
    }
    override var activityType: UIActivityType? {
        get {
            return UIActivityType("WeChatActivity")
        }
    }
    override var activityImage: UIImage? {
        get {
            return #imageLiteral(resourceName: "wechat")
        }
    }
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    override func perform() {
        MonkeyKing.registerAccount(.weChat(appID: "xxx", appKey: "yyy"))
        
        let message = MonkeyKing.Message.weChat(.session(info: (
            title: "Session",
            description: "Hello Session",
            thumbnail: UIImage(named: "rabbit"),
            media: .url(URL(string: "http://www.apple.com/cn")!)
        )))
        
        MonkeyKing.deliver(message) { success in
//            self.activityDidFinish(success)
            print("shareURLToWeChatSession success: \(success)")
        }
    }
}
