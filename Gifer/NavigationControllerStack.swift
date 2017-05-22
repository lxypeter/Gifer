//
//  NavigationControllerStack.swift
//  Gifer
//
//  Created by Peter Lee on 2017/5/18.
//  Copyright © 2017年 LXY. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift

class NavigationControllerStack: NSObject {
    
    let service: ViewModelService
    var navigationControllers: [UINavigationController]
    
    init(service: ViewModelService) {
        self.service = service
        self.navigationControllers = []
    }
    
    func push(navigationController: UINavigationController) {
        if self.navigationControllers.contains(navigationController) {
            return
        }
        self.navigationControllers.append(navigationController)
    }
    
    func popNavigationController() -> UINavigationController? {
        return self.navigationControllers.popLast()
    }
    
    func topNavigationController() -> UINavigationController? {
        return self.navigationControllers.last
    }

    func registerNavigationHooks() {
        self.service.reactive.trigger(for: #selector(ViewModelService.push(viewModel:animated:))).observeValues {
            params in
            print("\(params)")
        }
    }
    
}
