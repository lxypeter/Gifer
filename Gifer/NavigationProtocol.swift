//
//  NavigationProtocol.swift
//  Gifer
//
//  Created by Peter Lee on 2017/5/18.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit

protocol NavigationProtocol {
    
    func push(viewModel: ViewModel, animated: Bool)
    
    func pop(animated: Bool)
    
    func popToRootViewModel(animated: Bool)
    
    func present(viewModel: ViewModel, animated: Bool, completion: @escaping ()->())
    
    func dismissViewModel(animated: Bool, completion: @escaping ()->())
    
    func reset(rootViewModel: ViewModel)

}
