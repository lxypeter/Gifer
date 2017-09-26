//
//  Timer.swift
//  Gifer
//
//  Created by Peter Lee on 2017/9/26.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit

extension Timer {
    
    static func cy_scheduledTimer(withTimeInterval interval: TimeInterval, repeats:Bool, block:(Timer)->()) -> Timer {
        return self.scheduledTimer(timeInterval: interval, target: self, selector: #selector(Timer.cy_timerBlock(_:)), userInfo: block, repeats: repeats)
    }
    
    @objc static func cy_timerBlock(_ timer:Timer) {
        
        let block:((Timer)->())? = timer.userInfo as? (Timer)->()
        if block != nil {
            block!(timer)
        }
        
    }
}
