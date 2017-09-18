//
//  MomentsActivity.swift
//  Gifer
//
//  Created by Peter Lee on 2017/9/14.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit

class MomentsActivity: UIActivity {
    override class var activityCategory: UIActivityCategory {
        get {
            return .share
        }
    }
    override var activityTitle: String? {
        get {
            return "朋友圈"
        }
    }
    override var activityType: UIActivityType? {
        get {
            return UIActivityType("MomentsActivity")
        }
    }
    override var activityImage: UIImage? {
        get {
            return #imageLiteral(resourceName: "moments")
        }
    }
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    override func perform() {
        
    }
}
