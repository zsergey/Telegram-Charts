//
//  SliderView.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/16/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class SliderView: UIView {
    
    var onChangeRange: ((Range<Int>) ->())?
    
    var chartModels: [ChartModel]? {
        didSet {
            countPoints = chartModels?.map { $0.data.count }.max() ?? 0
            let maxValue = countPoints * 25 / 100
            currentRange = maxValue > 0 ? 0..<maxValue : 0..<1
            lineGap = self.frame.size.width / (CGFloat(countPoints) - 1)
            setNeedsLayout()
        }
    }
    
    var colorScheme: ColorSchemeProtocol = DayScheme() {
        didSet {
            setNeedsLayout()
        }
    }

    private var startX: CGFloat {
        return CGFloat(Int(CGFloat(currentRange.startIndex) * lineGap))
    }

    private var sliderWidth: CGFloat {
        return CGFloat(Int(CGFloat(currentRange.endIndex - currentRange.startIndex) * lineGap))
    }

    private var countPoints: Int = 0

    private var lineGap: CGFloat = 0.0

    private var currentRange: Range<Int> = 0..<1

    private let mainLayer: CALayer = CALayer()
    
    private let widthThumb: CGFloat = 11

    private let widthArrow: CGFloat = 6
    
    private let thumbCornerRadius: CGFloat = 0.25

    private let angle: CGFloat = 56

    private enum TapPosition {
        case left
        case right
        case center
    }
    
    private var tapPosition: TapPosition = .center
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        layer.addSublayer(mainLayer)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        panGesture.maximumNumberOfTouches = 1
        addGestureRecognizer(panGesture)
    }
    
    override func layoutSubviews() {
        clean()
        drawSlider()
    }
    
    @objc private func handlePan(recognizer: UIPanGestureRecognizer) {
    }
    
    private func clean() {
        mainLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
    }

    private func drawSlider() {
        drawBackgrounds()
        drawThumb(with: CGRect(x: startX, y: 1, width: widthThumb, height: self.frame.size.height - 2))
        drawThumb(with: CGRect(x: startX + sliderWidth - widthThumb, y: 1, width: widthThumb, height: self.frame.size.height - 2))
        drawLines()
        drawArrows()
    }

    private func drawThumb(with rect: CGRect) {
        let thumb = CAShapeLayer()
        thumb.path = UIBezierPath(rect: rect).cgPath
        thumb.strokeColor = UIColor.clear.cgColor
        thumb.fillColor = colorScheme.slider.thumb.cgColor
        thumb.lineWidth = 2.0
        mainLayer.addSublayer(thumb)
    }
    
    private func drawLines() {
        let height = self.frame.size.height
        var x1 = startX
        var x2 = startX + sliderWidth
        var rect = CGRect(x: x1 + 1, y: 0, width: sliderWidth - 2, height: 1)
        drawRect(rect: rect, byRoundingCorners: [.topLeft, .topRight], strokeColor: colorScheme.slider.line)
        
        rect = CGRect(x: x1 + 1, y: height - 1, width: sliderWidth - 2, height: 1)
        drawRect(rect: rect, byRoundingCorners: [.bottomLeft, .bottomRight], strokeColor: colorScheme.slider.line)
        
        x1 = x1 + widthThumb
        x2 = x2 - widthThumb
        
        drawLine(from: CGPoint(x: x1, y: 1), to: CGPoint(x: x2, y: 1), color: colorScheme.background)
        drawLine(from: CGPoint(x: x1, y: height - 1), to: CGPoint(x: x2, y: height - 1), color: colorScheme.background)
    }
    
    private func drawBackgrounds() {
        let height = self.frame.size.height
        let width = self.frame.size.width
        let x = startX
        if x > 0 {
            let rect = CGRect(x: 0, y: 1, width: startX, height: height - 2)
            drawRect(rect: rect, fillColor: colorScheme.slider.background)
        }
        if x + sliderWidth < width {
            let x = x + sliderWidth
            let rect = CGRect(x: x, y: 1, width: width - x, height: height - 2)
            drawRect(rect: rect, fillColor: colorScheme.slider.background)
        }
    }
    
    @discardableResult
    private func drawRect(rect: CGRect, byRoundingCorners corners: UIRectCorner = [],
                          strokeColor: UIColor = UIColor.clear, fillColor: UIColor = UIColor.clear,
                          lineWidth: CGFloat = 2.0) -> CAShapeLayer {
        let cornerRadii = CGSize(width: thumbCornerRadius, height: thumbCornerRadius)
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: cornerRadii)
        
        let rect = CAShapeLayer()
        rect.path = path.cgPath
        rect.strokeColor = strokeColor.cgColor
        rect.fillColor = fillColor.cgColor
        rect.lineWidth = lineWidth
        mainLayer.addSublayer(rect)
        return rect
    }
    
    private func drawLine(from point1: CGPoint, to point2: CGPoint,
                          color: UIColor, lineWidth: CGFloat = 2.0) {
        let pathLine = UIBezierPath()
        pathLine.move(to: point1)
        pathLine.addLine(to: point2)
        
        let line = CAShapeLayer()
        line.path = pathLine.cgPath
        line.strokeColor = color.cgColor
        line.fillColor = UIColor.clear.cgColor
        line.lineWidth = lineWidth
        mainLayer.addSublayer(line)
    }
    
    private func drawArrows() {
        let height = self.frame.size.height
        drawArrow(at: CGPoint(x: startX + widthThumb / 2, y: height / 2), left: true)
        drawArrow(at: CGPoint(x: startX + sliderWidth - widthThumb / 2, y: height / 2), left: false)
    }
    
    private func drawArrow(at point: CGPoint, left: Bool) {
        let corners: UIRectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]

        let heightArrow: CGFloat = 1
        let lineWidth: CGFloat = 0.75
        let rect = CGRect(x: 0, y: 0, width: widthArrow, height: heightArrow)
        
        let line = drawRect(rect: rect, byRoundingCorners: corners,
                            strokeColor: colorScheme.slider.arrow,
                            fillColor: colorScheme.slider.arrow,
                            lineWidth: lineWidth)
        
        var radians = left ? angle.radians : (180 - angle).radians
        let deltaX: CGFloat = left ? 1.25 : -1.25 - lineWidth
        var transform = CATransform3DMakeTranslation(point.x - deltaX,
                                                     point.y - heightArrow / 4, 0)
        transform = CATransform3DRotate(transform, radians, 0.0, 0.0, 1.0)
        line.transform = transform
        
        let line2 = drawRect(rect: rect, byRoundingCorners: corners,
                             strokeColor: colorScheme.slider.arrow,
                             fillColor: colorScheme.slider.arrow,
                             lineWidth: lineWidth)
        radians = left ? (360 - angle).radians : (180 + angle).radians
        var transform2 = CATransform3DMakeTranslation(point.x - lineWidth - deltaX,
                                                      point.y - heightArrow / 4, 0)
        transform2 = CATransform3DRotate(transform2, radians, 0.0, 0.0, 1.0)
        line2.transform = transform2
    }
}
