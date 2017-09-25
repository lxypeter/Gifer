//
//  ImageFilter.swift
//  Gifer
//
//  Created by Peter Lee on 2017/9/20.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit

struct ImageFilter {
    let nickname: String
    let name: String
    let preset: [String: Any]
    
    static func supportedFilters() -> [ImageFilter] {
        return [
            ImageFilter(nickname: "怀旧", name: "CISepiaTone", preset: [:]),
            ImageFilter(nickname: "Mono", name: "CIPhotoEffectMono", preset: [:]),
            ImageFilter(nickname: "聚焦", name: "CIZoomBlur", preset: ["inputAmount": 8]),
            ImageFilter(nickname: "高亮", name: "CIHighlightShadowAdjust", preset: ["inputHighlightAmount": 0.75, "inputShadowAmount": 1.5]),
            ImageFilter(nickname: "LOMO", name: "CIColorMatrix", preset: [
                "inputRVector": CIVector(x: 1.7, y: 0.1, z: 0.1, w: 0),
                "inputGVector": CIVector(x: 0, y: 1.7, z: 0.1, w: 0),
                "inputBVector": CIVector(x: 0, y: 0.1, z: 1.6, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                "inputBiasVector": CIVector(x: -73.1 / 255, y: -73.1 / 255, z: -73.1 / 255, w: 0)]),
            ImageFilter(nickname: "哥特", name: "CIColorMatrix", preset: [
                "inputRVector": CIVector(x: 1.9, y: -0.3, z: -0.2, w: 0),
                "inputGVector": CIVector(x: -0.2, y: 1.7, z: -0.1, w: 0),
                "inputBVector": CIVector(x: -0.1, y: -0.6, z: 2, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                "inputBiasVector": CIVector(x: -87 / 255, y: -87 / 255, z: -87 / 255, w: 0)]),
            ImageFilter(nickname: "复古", name: "CIColorMatrix", preset: [
                "inputRVector": CIVector(x: 0.2, y: 0.5, z: 0.1, w: 0),
                "inputGVector": CIVector(x: 0.2, y: 0.5, z: 0.1, w: 0),
                "inputBVector": CIVector(x: 0.2, y: 0.5, z: 0.1, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                "inputBiasVector": CIVector(x: -40.8 / 255, y: -40.8 / 255, z: -40.8 / 255, w: 0)]),
            ImageFilter(nickname: "锐化", name: "CIColorMatrix", preset: [
                "inputRVector": CIVector(x: 4.8, y: -1, z: -0.1, w: 0),
                "inputGVector": CIVector(x: -0.5, y: 4.4, z: 0.1, w: 0),
                "inputBVector": CIVector(x: -0.5, y: -1.0, z: 5.2, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                "inputBiasVector": CIVector(x: -388.4 / 255, y: -388.4 / 255, z: -388.4 / 255, w: 0)]),
            ImageFilter(nickname: "淡雅", name: "CIColorMatrix", preset: [
                "inputRVector": CIVector(x: 0.6, y: 0.3, z: 0.1, w: 0),
                "inputGVector": CIVector(x: 0.2, y: 0.7, z: 0.1, w: 0),
                "inputBVector": CIVector(x: 0.2, y: 0.3, z: 0.4, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                "inputBiasVector": CIVector(x: 73.3 / 255, y: 73.3 / 255, z: 73.3 / 255, w: 0)]),
            ImageFilter(nickname: "酒红", name: "CIColorMatrix", preset: [
                "inputRVector": CIVector(x: 1.2, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 0.9, z: 0.1, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 0.8, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)]),
            ImageFilter(nickname: "清宁", name: "CIColorMatrix", preset: [
                "inputRVector": CIVector(x: 0.9, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 1.1, z: 0.1, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 0.9, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)]),
            ImageFilter(nickname: "光晕", name: "CIColorMatrix", preset: [
                "inputRVector": CIVector(x: 0.9, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 0.9, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 0.9, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                "inputBiasVector": CIVector(x: 64.9 / 255, y: 64.9 / 255, z: 64.9 / 255, w: 0)]),
            ImageFilter(nickname: "蓝调", name: "CIColorMatrix", preset: [
                "inputRVector": CIVector(x: 2.1, y: -1.4, z: 0.6, w: 0),
                "inputGVector": CIVector(x: -0.3, y: 2, z: -0.3, w: 0),
                "inputBVector": CIVector(x: -1.1, y: 0.2, z: 2.6, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                "inputBiasVector": CIVector(x: -31 / 255, y: -31 / 255, z: -31 / 255, w: 0)]),
            ImageFilter(nickname: "梦幻", name: "CIColorMatrix", preset: [
                "inputRVector": CIVector(x: 0.8, y: 0.3, z: 0.1, w: 0),
                "inputGVector": CIVector(x: 0.1, y: 0.9, z: 0, w: 0),
                "inputBVector": CIVector(x: 0.1, y: 0.3, z: 0.7, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                "inputBiasVector": CIVector(x: 46.5 / 255, y: 46.5 / 255, z: 46.5 / 255, w: 0)]),
            ImageFilter(nickname: "夜色", name: "CIColorMatrix", preset: [
                "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 1.1, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 1, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                "inputBiasVector": CIVector(x: -66.6 / 255, y: -66.6 / 255, z: -66.6 / 255, w: 0)])
        ]
    }
    
    func createImage(with image: UIImage, context: CIContext) -> UIImage? {
        guard let filter = CIFilter(name: name, withInputParameters: preset), let beginImage = CIImage(image: image, options: ["opaque": false]) else {
            return nil
        }
        filter.setValue(beginImage, forKey: kCIInputImageKey)
        
        guard let output = filter.outputImage, let cgimg = context.createCGImage(output, from: output.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgimg)
    }
    
}
