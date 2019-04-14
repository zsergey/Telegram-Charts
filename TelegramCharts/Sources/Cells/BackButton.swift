//
//  BackButton.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 4/11/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class BackButton: UIButton {
    
    var originalTintColor: UIColor!
    
    lazy var iconImage: UIImageView = {
        let image = UIImage(named: "BackIcon")?.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        let size = imageView.frame.size
        imageView.frame = CGRect(x: 0,
                                 y: (self.frame.size.height - size.height) / 2,
                                 width: size.width,
                                 height: size.height)
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                iconImage.tintColor = UIColor(hex: "#CFE3FB")!
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.iconImage.tintColor = self.originalTintColor
                }
            }
        }
    }

    func commonInit() {
        addSubview(self.iconImage)
    }
}
