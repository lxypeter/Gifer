//
//  GalleryViewController.swift
//  Gifer
//
//  Created by Peter Lee on 2017/5/23.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import Photos
import SnapKit
import MobileCoreServices

let cellId = "GalleryCell"

class GalleryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var gifArray: [Photo] = []
    lazy var collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        let itemWidth: Double =  Double((UIScreen.main.bounds.width - 5 * layout.minimumInteritemSpacing)/4)
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)

        let collectionView = UICollectionView(frame: CGRect.zero,collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        collectionView.register(UINib(nibName: "GalleryCell", bundle: nil), forCellWithReuseIdentifier: cellId)
        return collectionView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureSubviews()
        self.fetchGIFFromLibrary()
    }
    
    func configureSubviews() {
        self.title = "Gifer"
        
        self.view.addSubview(self.collectionView)
        self.collectionView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
    }
    
    func fetchGIFFromLibrary() {
        
        var gifArray: [Photo] = []
        
        let option: PHFetchOptions = PHFetchOptions()
        option.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let result: PHFetchResult = PHAsset.fetchAssets(with: .image, options: option)
        result.enumerateObjects({ (asset, index, _) in
            
            guard let uti = asset.value(forKey: "uniformTypeIdentifier"), uti as! String == "com.compuserve.gif" else {
                return
            }
            
            let photo = Photo(asset: asset)
            
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            requestOptions.deliveryMode = .highQualityFormat
            // 按比例
            requestOptions.resizeMode = .exact
            requestOptions.normalizedCropRect = CGRect(x: 0, y: 0, width: 1, height: 1)

            let itemWidth: Double = Double(UIScreen.main.bounds.width/2)
            let itemSize = CGSize(width: itemWidth, height: itemWidth)
            
            PHImageManager.default().requestImage(for: asset, targetSize: itemSize, contentMode: .aspectFill, options: requestOptions, resultHandler: { (image, info) in
                photo.thumbnail = image
                gifArray.append(photo)
            })
        })
        self.gifArray = gifArray
    }
    
    //MARK: Delegate Method
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.gifArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: GalleryCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! GalleryCell
        let photo = self.gifArray[indexPath.row]
        cell.photo = photo;
        return cell
    }
    
    
}
