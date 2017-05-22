//
//  ViewController.swift
//  Gifer
//
//  Created by Peter Lee on 2017/5/17.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import ImageIO
import MobileCoreServices

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let kFrameCount: Int = 9;
        
        let fileProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]] as CFDictionary;
        
        let frameProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: 0.02]] as CFDictionary;
        
        let url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, "/Users/lxypeter/Desktop/gif/animated.gif" as CFString, CFURLPathStyle.cfurlposixPathStyle, false)!
        
        let destination: CGImageDestination? = CGImageDestinationCreateWithURL(url, kUTTypeGIF, kFrameCount, nil);
        
        if destination != nil {
            CGImageDestinationSetProperties(destination!, fileProperties);
            
            for index in 1 ... kFrameCount {
                let path: String = "/Users/lxypeter/Desktop/gif/\(index).jpeg";
                let image: UIImage = UIImage.init(contentsOfFile: path)!;
                CGImageDestinationAddImage(destination!, image.cgImage!, frameProperties);
            }
            
            if !CGImageDestinationFinalize(destination!) {
                print("failed to finalize image destination");
            }
        }

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

