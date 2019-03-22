//
//  NavigationViewController.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 21/03/2019.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class NavigationViewController: UINavigationController {

    var colorScheme: ColorSchemeProtocol = DayScheme() {
        didSet {
            let image = UIImage(named: colorScheme.separatorImageName)
            self.navigationController?.navigationBar.setBackgroundImage(image, for: .default)
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return colorScheme.statusBarStyle
    }

}
