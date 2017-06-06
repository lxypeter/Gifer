//
//  PublicMethod.swift
//  SDClientsPlatformSwift
//
//  Created by Peter Lee on 2016/12/21.
//  Copyright © 2016年 ZTESoft. All rights reserved.
//

import Foundation

let ScreenWidth = UIScreen.main.bounds.size.width
let ScreenHeight = UIScreen.main.bounds.size.height

/// 控制台打印
///
/// - Parameters:
///   - message: 打印内容
///   - file: 所在文件
///   - method: 方法名
///   - line: 行号
func printLog<T>(_ message: T,
              file: String = #file,
              method: String = #function,
              line: Int = #line)
{
    #if DEBUG
        print("\((file as NSString).lastPathComponent)[\(line)], \(method): \(message)")
    #endif
}
