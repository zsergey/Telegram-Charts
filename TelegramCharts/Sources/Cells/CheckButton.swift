//
//  CheckButton.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 4/7/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

extension UIControl.State: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }
}

class CheckButton: UIControl {
    
    var onTapButton: ((ChartModel) -> ())?
    var onLongTapButton: ((ChartModel, Bool) -> ())?

    var backgroundColors: [UIControl.State: UIColor] = [:]
    var titleColors: [UIControl.State: UIColor] = [:]
    var borderColors: [UIControl.State: UIColor] = [:]
    
    var color: UIColor {
        didSet {
            shadowTextColor = color.blackShadow
            updateStyle()
            updateState()
        }
    }
    
    var chartModel: ChartModel!
    
    var textColor: UIColor = .white {
        didSet {
            shadowTextColor = textColor.blackShadow
            updateStyle()
            updateState()
        }
    }
    
    var unCheckedBackgroundColor: UIColor = .white {
        didSet {
            shadowUnCheckedBackgroundColor = unCheckedBackgroundColor.blackShadow
            updateStyle()
            updateState()
        }
    }
    
    private var shadowColor: UIColor!
    
    private var shadowTextColor: UIColor!

    private var shadowUnCheckedBackgroundColor: UIColor!
    
    private var preferredHeight: CGFloat = 30
    
    public var title: String = "" {
        didSet {
            updateTitle()
            updateFrame()
        }
    }
    
    required init(color: UIColor) {
        self.color = color
        self.shadowColor = color.blackShadow
        self.shadowTextColor = textColor.blackShadow
        self.shadowUnCheckedBackgroundColor = unCheckedBackgroundColor.blackShadow
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: preferredHeight))
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public enum Style {
        case checked
        case unChecked
    }
    
    public var style: Style = .checked {
        didSet {
            updateStyle()
            updateTitle()
            animateChangingStyle()
        }
    }
    
    private var processedLongPressGesture: Bool = false
    
    private let textOffset: CGFloat = 21

    private let space: CGFloat = 20

    
    public var font: UIFont! {
        didSet {
            updateTitle()
            updateFrame()
        }
    }
    
    public override var isEnabled: Bool {
        didSet {
            updateState()
        }
    }
    
    public override var isHighlighted: Bool {
        didSet {
            self.updateState()
        }
    }

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    lazy var imageView: UIImageView = {
        let image = UIImage(named: "checkIcon")?.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        let size = imageView.frame.size
        imageView.frame = CGRect(x: textOffset / 2,
                                 y: (bounds.size.height - size.height) / 2,
                                 width: size.width,
                                 height: size.height)
        return imageView
    }()

    func commonInit() {
        self.addSubview(self.titleLabel)
        font = UIFont.systemFont(ofSize: 13)
        self.addSubview(self.imageView)
        addTarget(self, action: #selector(touchDownButton(_:)), for: .touchDown)
        addTarget(self, action: #selector(touchUpInside(_:)), for: .touchUpInside)
        addTarget(self, action: #selector(touchUpOutside(_:)), for: .touchUpOutside)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTapButton(_:)))
        longPressGesture.minimumPressDuration = 0.2
        addGestureRecognizer(longPressGesture)
        self.updateStyle()
        self.titleLabel.frame = self.bounds
    }

    @objc func touchDownButton(_ button: UIButton) {
        processedLongPressGesture = false
    }
    
    @objc func touchUpOutside(_ button: UIButton) {
        processedLongPressGesture = false
    }

    @objc func touchUpInside(_ button: UIButton) {
        processedLongPressGesture = false
        onTapButton?(chartModel)
    }
    
    func setNextStyle() {
        style = style == .checked ? .unChecked : .checked
    }
    
    @objc func longTapButton(_ button: UIButton) {
        onLongTapButton?(chartModel, processedLongPressGesture)
        processedLongPressGesture = true
    }
    
    func animateChangingStyle() {
        let centerX = (self.frame.width - self.titleLabel.frame.width) / 2
        UIView.animateEaseInOut(with: UIView.animationDuration) {
            switch self.style {
            case .unChecked:
                self.titleLabel.frame = CGRect(x: centerX,
                                               y: self.titleLabel.frame.origin.y,
                                               width: self.titleLabel.frame.width,
                                               height: self.titleLabel.frame.height)
                self.imageView.frame = CGRect(x: 0,
                                              y: self.imageView.frame.origin.y,
                                              width: self.imageView.frame.width,
                                              height: self.imageView.frame.height)
                self.imageView.alpha = 0
            case .checked:
                self.titleLabel.frame = CGRect(x: self.textOffset / 2 + centerX,
                                               y: self.titleLabel.frame.origin.y,
                                               width: self.titleLabel.frame.width,
                                               height: self.titleLabel.frame.height)
                self.imageView.frame = CGRect(x: self.textOffset / 2,
                                              y: self.imageView.frame.origin.y,
                                              width: self.imageView.frame.width,
                                              height: self.imageView.frame.height)
                self.imageView.alpha = 1
            }
        }
    }
    
    func updateStyle() {
        switch self.style {
        case .checked:
            self.backgroundColors[.normal] = color
            self.backgroundColors[.highlighted] = shadowColor
            self.titleColors[.normal] = textColor
            self.titleColors[.highlighted] = shadowTextColor
        case .unChecked:
            self.backgroundColors[.normal] = unCheckedBackgroundColor
            self.backgroundColors[.highlighted] = shadowUnCheckedBackgroundColor
            self.titleColors[.normal] = color
            self.titleColors[.highlighted] = shadowColor
            self.borderColors[.normal] = color
            self.borderColors[.highlighted] = shadowColor
        }
        self.layer.cornerRadius = SliderView.thumbCornerRadius
        self.layer.masksToBounds = true
        self.updateState()
    }
    
    func updateState() {
        self.updatePreference()
    }

    func updatePreference() {
        self.backgroundColor = self.backgroundColors[self.state]
        self.titleLabel.textColor = self.titleColors[self.state]
        switch self.state {
        case .normal: self.imageView.tintColor = textColor
        case .highlighted: self.imageView.tintColor = shadowTextColor
        default:
            break
        }
        self.updateBorder()
    }
    
    func updateTitle() {
        titleLabel.font = font
        titleLabel.text = title
    }
    
    func updateFrame() {
        let size = title.size(withAttributes: [.font: UIFont.systemFont(ofSize: 13)])
        let newFrame = CGRect(x: frame.origin.x,
                              y: frame.origin.y,
                              width: size.width + space + textOffset,
                              height: frame.size.height)
        frame = newFrame
        
        self.titleLabel.frame = CGRect(x: self.titleLabel.frame.origin.x,
                                       y: self.titleLabel.frame.origin.y,
                                       width: self.titleLabel.intrinsicContentSize.width,
                                       height: self.titleLabel.frame.height)
    }
    
    func updateBorder() {
        var borderWidth: CGFloat = 0.0
        var borderColor = UIColor.clear
        switch style {
        case .unChecked:
            borderWidth = 1.0
            borderColor = borderColors[state] ?? .clear
        case .checked:
            borderWidth = 0.0
            borderColor = UIColor.clear
        }
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
    }
    
    func shake() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 4
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - 4, y: self.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + 4, y: self.center.y))
        self.layer.add(animation, forKey: "position")
    }

}
