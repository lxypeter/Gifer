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
    
    //MARK: property
    var selectedArray: [Photo] = []
    private var imageArray: [UIImage] = []
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.backgroundColor = UIColor.clear
        imageView.animationDuration = self.bottomBar.originDuration * Double(self.selectedArray.count)
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

    //MARK: life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureSubviews()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
            if photo.fullImage === nil {
                let requestOptions = PHImageRequestOptions()
                requestOptions.isSynchronous = false
                requestOptions.deliveryMode = .highQualityFormat
                requestOptions.resizeMode = .none
                
                PHImageManager.default().requestImageData(for: photo.asset, options: requestOptions, resultHandler: { [unowned self](data, type, orientation, info) in
                    if let data = data {
                        photo.fullImageData = data as NSData
                    }
                    self.kGroup.leave()
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
    
    private func isSameSize() {
        
    }
    
    private func generateGif() {
        self.showHudWithMsg(msg: "正在生成...")
        
        let fileProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]] as CFDictionary;
        
        let frameProperties: CFDictionary = [
            kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: self.bottomBar.currentDuration],
            kCGImagePropertyPixelHeight as String: 400,
            kCGImagePropertyPixelWidth as String: 400
            ] as CFDictionary;
        
        let dataFormatter = DateFormatter()
        dataFormatter.dateFormat = "YYYYMMddHHmmss"
        let filename = dataFormatter.string(from: Date())
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(filename).gif")
        DispatchQueue.global().async { [unowned self] in
            let destination: CGImageDestination? = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeGIF, self.selectedArray.count, nil);
            if destination == nil { self.showNotice(message: "生成Gif失败...") }
            CGImageDestinationSetProperties(destination!, fileProperties);
            
            for photo in self.selectedArray {
                if photo.fullImage != nil {
                    let newImage = photo.fullImage?.imageKeepRatioScalingWith(targetSize: CGSize(width: 400, height: 400))
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
                DispatchQueue.main.async { [unowned self] in
                    self.hideHud()
                    self.showNotice(message: "生成Gif失败...")
                }
            }
        }
    }
    
    //MARK: event
    func clickGenerateButton() {
        let alertController = UIAlertController(title: "选择Gif画质", message: nil, preferredStyle: .actionSheet)
        let lowQualityAction = UIAlertAction(title: "低清晰度", style: .default) { [unowned self](action) in
            self.generateGif()
        }
        alertController.addAction(lowQualityAction)
        let mediumQualityAction = UIAlertAction(title: "中等清晰度", style: .default) { [unowned self](action) in
            self.generateGif()
        }
        alertController.addAction(mediumQualityAction)
        let highQualityAction = UIAlertAction(title: "高清晰度", style: .default) { [unowned self](action) in
            self.generateGif()
        }
        alertController.addAction(highQualityAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}
