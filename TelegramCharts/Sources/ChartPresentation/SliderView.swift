//
//  SliderView.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/16/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

enum SliderDirection {
    case left
    case right
    case center
    case none
    case finished
}

class SliderView: UIView, Reusable {
    
    var onChangeRange: ((IndexRange) ->())?
    var onBeganTouch: ((SliderDirection) ->())?
    var onEndTouch: ((SliderDirection) ->())?
    var currentRange: IndexRange = (0, 0)

    var chartModels: [ChartModel]? {
        didSet {
            countPoints = chartModels?.map { $0.data.count }.max() ?? 0
            setNeedsLayout()
        }
    }
    
    var colorScheme: ColorSchemeProtocol = DayScheme() {
        didSet {
            setNeedsLayout()
        }
    }

    private var startX: CGFloat = 0 {
        didSet {
            calcCurrentRange()
            setNeedsLayout()
        }
    }
    
    private var sliderWidth: CGFloat = 0 {
        didSet {
            calcCurrentRange()
            setNeedsLayout()
        }
    }

    private var tapStartX: CGFloat = 0

    private var tapSliderWidth: CGFloat = 0

    private let tapSize: CGFloat = 34
    
    private var minValueSliderWidth: CGFloat = 0
    
    private var countPoints: Int = 0

    private var indexGap: CGFloat = 0.0

    private let mainLayer: CALayer = CALayer()
    
    private let thumbWidth: CGFloat = 11

    private let arrowWidth: CGFloat = 6
    
    private let thumbCornerRadius: CGFloat = 0.25

    private let arrowAngle: CGFloat = 60

    private let trailingSpace: CGFloat = 16

    private let leadingSpace: CGFloat = 16
    
    private var sliderDirection: SliderDirection = .finished
    
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
        calcProperties()
        clean()
        drawSlider()
    }
    
    private func calcProperties() {
        minValueSliderWidth = 2 * thumbWidth + 2 * tapSize
        indexGap = (self.frame.size.width - trailingSpace - leadingSpace) / (CGFloat(countPoints) - 1)
        if sliderWidth == 0 {
            sliderWidth = minValueSliderWidth
        }
    }
    
    @objc private func handlePan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            tapStartX = startX
            tapSliderWidth = sliderWidth
            let point = recognizer.location(in: self)
            detectSliderTap(from: point)
            onBeganTouch?(sliderDirection)
        case .changed:
            let translation = recognizer.translation(in: self)
            switch sliderDirection {
            case .center: processCenter(translation)
            case .left: processLeft(translation)
            case .right: processRight(translation)
            default: break
            }
        case .ended:
            onEndTouch?(.finished)
        default: break
        }
    }
    
    private func processCenter(_ translation: CGPoint) {
        let minValue: CGFloat = 0
        let maxValue = self.frame.size.width - sliderWidth - trailingSpace - leadingSpace
        var value = tapStartX + translation.x
        if value < minValue {
            value = minValue
        } else if value > maxValue {
            value = maxValue
        }
        startX = value
    }
    
    private func processLeft(_ translation: CGPoint) {
        let minValueX: CGFloat = 0
        var valueX = tapStartX + translation.x
        var valueWidth = tapSliderWidth - translation.x
        if valueX < minValueX {
            valueX = minValueX
            let translationx = valueX - tapStartX
            valueWidth = tapSliderWidth - translationx
        }
        if valueWidth < minValueSliderWidth {
            valueWidth = minValueSliderWidth
            let translationx = tapSliderWidth - valueWidth
            valueX = tapStartX + translationx
        }
        startX = valueX
        sliderWidth = valueWidth
    }

    private func processRight(_ translation: CGPoint) {
        let maxValueSliderWidth = self.frame.size.width - trailingSpace - leadingSpace - tapStartX
        var valueWidth = tapSliderWidth + translation.x
        if valueWidth < minValueSliderWidth {
            valueWidth = minValueSliderWidth
        } else if valueWidth > maxValueSliderWidth {
            valueWidth = maxValueSliderWidth
        }
        sliderWidth = valueWidth
    }

    private func detectSliderTap(from point: CGPoint) {
        sliderDirection = .none
        let halfTapSize = tapSize / 2
        let x = startX + trailingSpace
        if point.x >= x - halfTapSize,
            point.x <= x + thumbWidth + halfTapSize {
            sliderDirection = .left
        } else if point.x >= x + sliderWidth - thumbWidth - halfTapSize,
            point.x <= x + sliderWidth + halfTapSize {
            sliderDirection = .right
        } else if point.x > x + thumbWidth + halfTapSize,
            point.x < x + sliderWidth - thumbWidth - halfTapSize {
            sliderDirection = .center
        }
    }
    
    private func calcCurrentRange() {
        guard indexGap != 0 else {
            return
        }
        let startIndex = startX / indexGap
        let endIndex = (startX + sliderWidth) / indexGap + 1
        currentRange = (startIndex, endIndex)
        onChangeRange?(currentRange)
    }
    
    private func clean() {
        layer.backgroundColor = colorScheme.chart.background.cgColor
        mainLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
    }

    private func drawSlider() {
        drawBackgrounds()
        drawThumb(with: CGRect(x: startX + trailingSpace, y: 1, width: thumbWidth, height: self.frame.size.height - 2))
        drawThumb(with: CGRect(x: startX + trailingSpace + sliderWidth - thumbWidth, y: 1, width: thumbWidth, height: self.frame.size.height - 2))
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
        var x1 = startX + trailingSpace
        var x2 = startX + sliderWidth + trailingSpace
        var rect = CGRect(x: x1 + 1, y: 0, width: sliderWidth - 2, height: 1)
        drawRect(rect: rect, byRoundingCorners: [.topLeft, .topRight], strokeColor: colorScheme.slider.line)
        
        rect = CGRect(x: x1 + 1, y: height - 1, width: sliderWidth - 2, height: 1)
        drawRect(rect: rect, byRoundingCorners: [.bottomLeft, .bottomRight], strokeColor: colorScheme.slider.line)
        
        x1 = x1 + thumbWidth
        x2 = x2 - thumbWidth
        
        drawLine(from: CGPoint(x: x1, y: 1), to: CGPoint(x: x2, y: 1), color: colorScheme.chart.background)
        drawLine(from: CGPoint(x: x1, y: height - 1), to: CGPoint(x: x2, y: height - 1), color: colorScheme.chart.background)
    }
    
    private func drawBackgrounds() {
        let height = self.frame.size.height
        let width = self.frame.size.width - leadingSpace
        let x = startX + trailingSpace
        if x > 0 {
            let rect = CGRect(x: trailingSpace, y: 1, width: startX, height: height - 2)
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
        drawArrow(at: CGPoint(x: startX + trailingSpace + thumbWidth / 2, y: height / 2), left: true)
        drawArrow(at: CGPoint(x: startX + trailingSpace + sliderWidth - thumbWidth / 2, y: height / 2), left: false)
    }
    
    private func drawArrow(at point: CGPoint, left: Bool) {
        let corners: UIRectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]

        let heightArrow: CGFloat = 1
        let lineWidth: CGFloat = 0.75
        let rect = CGRect(x: 0, y: 0, width: arrowWidth, height: heightArrow)
        
        let line = drawRect(rect: rect, byRoundingCorners: corners,
                            strokeColor: colorScheme.slider.arrow,
                            fillColor: colorScheme.slider.arrow,
                            lineWidth: lineWidth)
        
        var radians = left ? arrowAngle.radians : (180 - arrowAngle).radians
        let deltaX: CGFloat = left ? 1.25 : -1.25 - lineWidth
        var transform = CATransform3DMakeTranslation(point.x - deltaX,
                                                     point.y - heightArrow / 4, 0)
        transform = CATransform3DRotate(transform, radians, 0.0, 0.0, 1.0)
        line.transform = transform
        
        let line2 = drawRect(rect: rect, byRoundingCorners: corners,
                             strokeColor: colorScheme.slider.arrow,
                             fillColor: colorScheme.slider.arrow,
                             lineWidth: lineWidth)
        radians = left ? (360 - arrowAngle).radians : (180 + arrowAngle).radians
        var transform2 = CATransform3DMakeTranslation(point.x - lineWidth - deltaX,
                                                      point.y - heightArrow / 4, 0)
        transform2 = CATransform3DRotate(transform2, radians, 0.0, 0.0, 1.0)
        line2.transform = transform2
    }
    
    func prepareForReuse() {
        chartModels = nil
        sliderDirection = .finished
        sliderWidth = 0
    }

}
