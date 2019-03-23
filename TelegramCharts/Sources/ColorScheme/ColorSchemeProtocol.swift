//
//  ColorSchemeProtocol.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/13/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct SliderColor {
    let thumb: UIColor
    let line: UIColor
    let background: UIColor
    let arrow: UIColor
}

struct ChartColor {
    var background: UIColor
    var grid: UIColor
    var text: UIColor
}

struct SectionColor {
    var background: UIColor
    var text: UIColor
}

struct ButtonColor {
    var normal: UIColor
}

protocol ColorSchemeProtocol {
    var background: UIColor { get }
    var selectedCellView: UIView { get }
    var title: UIColor { get }
    var statusBarStyle: UIStatusBarStyle { get }
    var separator: UIColor { get }
    var separatorImageName: String { get }
    var button: ButtonColor { get }
    var section: SectionColor { get }
    var chart: ChartColor { get }
    var slider: SliderColor { get }
}

extension ColorSchemeProtocol {

    func view(by color: UIColor) -> UIView {
        let view = UIView()
        view.backgroundColor = color
        return view
    }
}
