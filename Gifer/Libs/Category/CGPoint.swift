//
//  CGPoint.swift
//  Gifer
//
//  Created by Peter Lee on 2017/8/23.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit

extension CGPoint {
    func rotate(around center: CGPoint, with degrees: CGFloat) -> CGPoint {
        let dx = self.x - center.x
        let dy = self.y - center.y
        let radius = sqrt(dx * dx + dy * dy)
        let azimuth = atan2(dy, dx) // in radians
//        let newAzimuth = azimuth + degrees * CGFloat(.pi / 180.0) // convert it to radians
        let newAzimuth = azimuth + degrees
        let x = center.x + radius * cos(newAzimuth)
        let y = center.y + radius * sin(newAzimuth)
        return CGPoint(x: x, y: y)
    }
}
