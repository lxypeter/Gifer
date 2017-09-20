//
//  Enums.swift
//  Gifer
//
//  Created by Peter Lee on 2017/9/19.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit

enum PlaySequence {
    case normal
    case reverse
    case toAndFor
}

enum GifEditStatus {
    case normal
    case cliping
    case filtering
}

enum RatioStatus {
    case noLimit
    case fourToThree
    case sixteenToNine
    case oneToOne
    
    var floatValue: CGFloat {
        var result : CGFloat
        switch self {
        case .noLimit:
            result = 0
        case .fourToThree:
            result = 4/3
        case .sixteenToNine:
            result = 16/9
        case .oneToOne:
            result = 1/1
        }
        return result
    }
}

enum VideoProgressViewEdgeType {
    case start
    case end
}
