//
//  BaseViewController.swift
//  SDClientsPlatformSwift
//
//  Created by Peter Lee on 2016/12/19.
//  Copyright © 2016年 ZTESoft. All rights reserved.
//

import UIKit
import JGProgressHUD

class BaseViewController: UIViewController {

    lazy var hud : JGProgressHUD! = {
        let hud = JGProgressHUD(style: .dark)
        return hud
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureBackButton()
    }
    
    private func configureBackButton() {
        if (self.navigationController?.viewControllers.count)!<=1 {
            return
        }
        
        let backBtn: UIButton = UIButton()
        backBtn.setImage(UIImage(named:"back"), for: .normal)
        backBtn.bounds = CGRect(x: 0, y: 0, width: 24, height: 24)
        backBtn.addTarget(self, action: #selector(backToLastController), for: .touchUpInside)
        let backItem:UIBarButtonItem = UIBarButtonItem(customView:backBtn)
        self.navigationItem.leftBarButtonItem = backItem;
        
    }
    
    func backToLastController() {
        self.view.endEditing(true)
        self.navigationController?.popViewController(animated: true)
    }
    
    func showHudWithMsg(msg:String) {
        hud.textLabel.text = msg
        hud.show(in: UIApplication.shared.keyWindow, animated: true)
    }
    
    func showHudWithMsg(msg:String,in view: UIView!) {
        hud.textLabel.text = msg
        hud.show(in: view, animated: true)
    }
    
    func hideHud() {
        hud.dismiss()
    }

}
