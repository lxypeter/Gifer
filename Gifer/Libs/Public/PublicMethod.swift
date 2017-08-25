//
//  PublicMethod.swift
//  SDClientsPlatformSwift
//
//  Created by Peter Lee on 2016/12/21.
//  Copyright © 2016年 ZTESoft. All rights reserved.
//

import Foundation

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
              line: Int = #line) {
    #if DEBUG
        print("\((file as NSString).lastPathComponent)[\(line)], \(method): \(message)")
    #endif
}

/// 当前时间戳字符串
///
/// - Returns: 时间戳字符串
func timeStamp() -> String {
    let dataFormatter = DateFormatter()
    dataFormatter.dateFormat = "YYYYMMddHHmmss"
    return dataFormatter.string(from: Date())
}


/// 确保目录路径存在
///
/// - Parameter path: 目录路径
/// - Returns: 存在与否
func createFolderIfNotExist(path: String) -> Bool {
    let fileManager = FileManager.default
    var isDir: ObjCBool = ObjCBool(false)
    let isDirExist = fileManager.fileExists(atPath: path, isDirectory: &isDir)
    if !(isDirExist && isDir.boolValue) {
        var result = false
        do {
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            result = true
        } catch {}
        return result
    } else {
        return true
    }
}
