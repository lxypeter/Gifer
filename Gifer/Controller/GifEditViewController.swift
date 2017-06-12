//
//  GifEditViewController.swift
//  Gifer
//
//  Created by Peter Lee on 2017/6/9.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import SnapKit
import Photos
import ImageIO
import MobileCoreServices

class GifEditViewController: BaseViewController {
    
    var selectedArray: [Photo] = []
    private var imageArray: [UIImage] = []
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.backgroundColor = UIColor.clear
        imageView.animationDuration = self.bottomBar.originDuration
        return imageView
    }()
    private lazy var bottomBar: GifEditViewBottomBar = {
        let bottomBar = GifEditViewBottomBar(frame: CGRect.zero)
        bottomBar.totalCount = self.selectedArray.count
        bottomBar.sliderValueChangeHandler = { [unowned self] value in
            self.imageView.animationDuration = Double(String(format: "%.2f", value))! * Double(self.selectedArray.count)
            self.imageView.startAnimating()
        }
        return bottomBar
    }()
    private let bottomBarHeight = 54
    private var kGroup: DispatchGroup = DispatchGroup()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureSubviews()
        self.fetchFullImage()
    }
    
    private func configureSubviews() {
        self.title = "编辑"
        
        let generateItem: UIBarButtonItem = UIBarButtonItem(title: "生成", style: .plain, target: self, action: #selector(clickGenerateButton))
        generateItem.tintColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        self.navigationItem.rightBarButtonItem = generateItem;
        
        self.view.addSubview(self.bottomBar)
        self.bottomBar.snp.makeConstraints { (make) in
            make.bottom.equalTo(0)
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.height.equalTo(bottomBarHeight)
        }
        
        self.view.addSubview(self.imageView)
        self.imageView.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.bottom.equalTo(self.bottomBar.snp.top).offset(0)
        }
        
    }
    
    private func fetchFullImage() {
        self.showHudWithMsg(msg: "")
        self.kGroup = DispatchGroup()
        for photo in self.selectedArray {
            self.kGroup.enter()
            if photo.fullImageData === nil {
                let requestOptions = PHImageRequestOptions()
                requestOptions.isSynchronous = false
                requestOptions.deliveryMode = .highQualityFormat
                requestOptions.resizeMode = .none
                
                PHImageManager.default().requestImageData(for: photo.asset, options: requestOptions, resultHandler: { [unowned self](data, type, orientation, info) in
                    self.kGroup.leave()
                    photo.fullImageData = data as NSData?
                })
            } else {
                self.kGroup.leave()
            }
        }
        self.kGroup.notify(queue: DispatchQueue.main) { [unowned self] in 
            self.hideHud()
            for  photo in self.selectedArray {
                if photo.fullImage != nil {
                    self.imageArray.append(photo.fullImage!)
                }
            }
            self.imageView.animationImages = self.imageArray
            self.imageView.startAnimating()
        }
    }
    
    func clickGenerateButton() {
        
        let fileProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]] as CFDictionary;

        let frameProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: self.bottomBar.currentDuration]] as CFDictionary;
        
        let dataFormatter = DateFormatter()
        dataFormatter.dateFormat = "YYYYMMddHHmmss"
        let filename = dataFormatter.string(from: Date())
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(filename).gif")
        
        self.showHudWithMsg(msg: "正在生成...")
        
        let destination: CGImageDestination? = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeGIF, self.selectedArray.count, nil);

        if destination != nil {
            
            CGImageDestinationSetProperties(destination!, fileProperties);

            for photo in self.selectedArray {
                if photo.fullImage != nil {
                    
                    let imageData = UIImageJPEGRepresentation(photo.fullImage!, 0.3)
                    let newImage = UIImage(data: imageData!)
                    
                    
                    CGImageDestinationAddImage(destination!, newImage!.cgImage!, frameProperties);
                }
            }

            if CGImageDestinationFinalize(destination!) {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                }) { (success, error) in
                    DispatchQueue.main.async { [unowned self] in
                        self.hideHud()
                        if success {
                            self.navigationController?.popToRootViewController(animated: true)
                            self.showNotice(message: "生成Gif成功！")
                        }
                    }
                }
            } else {
                self.hideHud()
                self.showNotice(message: "生成Gif失败...")
            }
        }

    }
    
}
