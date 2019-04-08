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

class SliderView: UIView, Reusable, UIGestureRecognizerDelegate {
    
    var onChangeRange: ((IndexRange, CGFloat, CGFloat) ->())?
    var onBeganTouch: ((SliderDirection) ->())?
    var onEndTouch: ((SliderDirection) ->())?
    var currentRange = IndexRange(start: CGFloat(0.0), end: CGFloat(0.0))

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
    
    var sliderWidth: CGFloat = 0

    var startX: CGFloat = 0
    
    private var tapStartX: CGFloat = 0

    private var tapSliderWidth: CGFloat = 0

    private let tapSize: CGFloat = 34
    
    private var minValueSliderWidth: CGFloat = 0
    
    private var countPoints: Int = 0

    private var indexGap: CGFloat = 0.0

    private let mainLayer: CALayer = CALayer()
    
    private let thumbWidth: CGFloat = 11

    private let arrowWidth: CGFloat = 5

    private let arrowHeight: CGFloat = 0.75
    
    private let arrowCornerRadius: CGFloat = 0.25

    static let thumbCornerRadius: CGFloat = 6

    private let arrowAngle: CGFloat = 55

    private let trailingSpace: CGFloat = 16

    private let leadingSpace: CGFloat = 16
    
    private var sliderDirection: SliderDirection = .finished
    
    private var leftBackground: CAShapeLayer?

    private var rightBackground: CAShapeLayer?

    private var leftThumb: CAShapeLayer?
    
    private var rightThumb: CAShapeLayer?

    private var topLine: CAShapeLayer?
    
    private var bottomLine: CAShapeLayer?

    private var arrow1: CAShapeLayer?
    
    private var arrow2: CAShapeLayer?

    private var arrow3: CAShapeLayer?
    
    private var arrow4: CAShapeLayer?

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
        panGesture.minimumNumberOfTouches = 1
        panGesture.delegate = self
        addGestureRecognizer(panGesture)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGestureRecognizer.translation(in: self)
            return abs(translation.y) > abs(translation.x)
        }
        return true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.backgroundColor = .clear
        self.calcProperties()
        self.drawSlider()
    }
    
    private func calcProperties() {
        minValueSliderWidth = 2 * thumbWidth + 2 * tapSize
        indexGap = (self.frame.size.width - trailingSpace - leadingSpace) / (CGFloat(countPoints) - 1)
        if sliderWidth == 0 {
            sliderWidth = minValueSliderWidth
            updateCurrentRange()
        }
    }
    
    private func updateCurrentRange() {
        calcCurrentRange()
        setNeedsLayout()
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
        updateCurrentRange()
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
        updateCurrentRange()
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
        updateCurrentRange()
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
        currentRange.start = startIndex
        currentRange.end = endIndex
        onChangeRange?(currentRange, sliderWidth, startX)
    }
    
    private func drawSlider() {
        CATransaction.setDisableActions(true)
        drawBackgrounds()
        drawThumbs()
        drawLines()
        drawArrows()
    }
    
    private func drawThumbs() {
        // Left Thumb.
        let color = colorScheme.slider.thumb
        let height = self.frame.size.height + 1
        var rect = CGRect(x: startX + trailingSpace, y: -0.5, width: thumbWidth, height: height)
        var corners: UIRectCorner = [.topLeft, .bottomLeft]
        if let leftThumb = leftThumb {
            let path = Painter.createRectPath(rect: rect, byRoundingCorners: corners, cornerRadius: SliderView.thumbCornerRadius)
            leftThumb.path = path.cgPath
            leftThumb.fillColor = color.cgColor
        } else {
            let leftThumb = Painter.createRect(rect: rect, byRoundingCorners: corners,
                                     fillColor: color, lineWidth: 1.0, cornerRadius: SliderView.thumbCornerRadius)
            mainLayer.addSublayer(leftThumb)
            self.leftThumb = leftThumb
        }

        // Right Thumb.
        corners = [.topRight, .bottomRight]
        rect = CGRect(x: startX + trailingSpace + sliderWidth - thumbWidth, y: -0.5, width: thumbWidth, height: height)
        if let rightThumb = rightThumb {
            let path = Painter.createRectPath(rect: rect, byRoundingCorners: corners, cornerRadius: SliderView.thumbCornerRadius)
            rightThumb.path = path.cgPath
            rightThumb.fillColor = color.cgColor
        } else {
            let rightThumb = Painter.createRect(rect: rect, byRoundingCorners: corners,
                                      fillColor: color, lineWidth: 1.0, cornerRadius: SliderView.thumbCornerRadius)
            mainLayer.addSublayer(rightThumb)
            self.rightThumb = rightThumb
        }
    }
    
    private func drawLines() {
        let height = self.frame.size.height
        let x = startX + trailingSpace + thumbWidth
        
        // Top Line.
        let lineWidth = sliderWidth - 2 * thumbWidth
        var rect = CGRect(x: x, y: -0.25, width: lineWidth, height: 0.5)
        let color = colorScheme.slider.thumb
        if let topLine = topLine {
            let path = Painter.createRectPath(rect: rect)
            topLine.path = path.cgPath
            topLine.strokeColor = color.cgColor
        } else {
            let topLine = Painter.createRect(rect: rect, strokeColor: color, lineWidth: 0.5)
            mainLayer.addSublayer(topLine)
            self.topLine = topLine
        }
        
        // Bottom Line.
        rect = CGRect(x: x, y: height - 0.25, width: lineWidth, height: 0.5)
        if let bottomLine = bottomLine {
            let path = Painter.createRectPath(rect: rect)
            bottomLine.path = path.cgPath
            bottomLine.strokeColor = color.cgColor
        } else {
            let bottomLine = Painter.createRect(rect: rect, strokeColor: color, lineWidth: 0.5)
            mainLayer.addSublayer(bottomLine)
            self.bottomLine = bottomLine
        }
    }
    
    private func drawBackgrounds() {
        let height = self.frame.size.height
        let width = self.frame.size.width - leadingSpace
        let x = startX + trailingSpace
        
        // Left background.
        var rect = CGRect(x: trailingSpace, y: 1, width: 0, height: height - 2) // .zero
        if x > 0 {
            rect = CGRect(x: trailingSpace, y: 1, width: startX + thumbWidth / 2, height: height - 2)
        }
        
        let leftСorners: UIRectCorner = [.topLeft, .bottomLeft]
        if let leftBackground = leftBackground {
            let path = Painter.createRectPath(rect: rect, byRoundingCorners: leftСorners, cornerRadius: SliderView.thumbCornerRadius)
            leftBackground.path = path.cgPath
            leftBackground.fillColor = colorScheme.slider.background.cgColor
        } else {
            let leftBackground = Painter.createRect(rect: rect, byRoundingCorners: leftСorners,
                                                    fillColor: colorScheme.slider.background,
                                                    cornerRadius: SliderView.thumbCornerRadius)
            mainLayer.addSublayer(leftBackground)
            self.leftBackground = leftBackground
        }
        
        // Right background.
        rect = CGRect(x: width, y: 1, width: 0, height: height - 2) // .zero
        if x + sliderWidth < width {
            let x = x + sliderWidth - thumbWidth / 2
            rect = CGRect(x: x, y: 1, width: width - x, height: height - 2)
        }
        let rightСorners: UIRectCorner = [.topRight, .bottomRight]
        if let rightBackground = rightBackground {
            let path = Painter.createRectPath(rect: rect, byRoundingCorners: rightСorners, cornerRadius: SliderView.thumbCornerRadius)
            rightBackground.path = path.cgPath
            rightBackground.fillColor = colorScheme.slider.background.cgColor
        } else {
            let rightBackground = Painter.createRect(rect: rect,
                                                     byRoundingCorners: rightСorners,
                                                     fillColor: colorScheme.slider.background,
                                                     cornerRadius: SliderView.thumbCornerRadius)
            mainLayer.addSublayer(rightBackground)
            self.rightBackground = rightBackground
        }
    }
    
    private func drawArrows() {
        let height = self.frame.size.height
        let point1 = CGPoint(x: startX + trailingSpace + thumbWidth / 2, y: height / 2)
        let point2 = CGPoint(x: startX + trailingSpace + sliderWidth - thumbWidth / 2, y: height / 2)
        drawArrow(at: point1, left: true)
        drawArrow(at: point2, left: false)
    }
    
    private func drawArrow(at point: CGPoint, left: Bool) {
        let corners: UIRectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]

        let lineWidth: CGFloat = 0.75
        let rect = CGRect(x: 0, y: 0, width: arrowWidth, height: arrowHeight)
        
        // Bottom arrow.
        var bottomArrow = left ? arrow1 : arrow2
        if bottomArrow == nil {
            let line = Painter.createRect(rect: rect, byRoundingCorners: corners,
                                strokeColor: colorScheme.slider.arrow,
                                fillColor: colorScheme.slider.arrow,
                                lineWidth: lineWidth, cornerRadius: arrowCornerRadius)
            mainLayer.addSublayer(line)

            if left {
                self.arrow1 = line
            } else {
                self.arrow2 = line
            }
            bottomArrow = line
        }
        
        var radians = left ? arrowAngle.radians : (180 - arrowAngle).radians
        let deltaX: CGFloat = left ? 1.25 : -1.25 - lineWidth
        var transform = CATransform3DMakeTranslation(point.x - deltaX,
                                                     point.y - arrowHeight / 4, 0)
        transform = CATransform3DRotate(transform, radians, 0.0, 0.0, 1.0)
        CATransaction.setDisableActions(true)
        bottomArrow!.transform = transform

        // Top arrow.
        var topArrow = left ? arrow3 : arrow4
        if topArrow == nil {
            let line2 = Painter.createRect(rect: rect, byRoundingCorners: corners,
                                 strokeColor: colorScheme.slider.arrow,
                                 fillColor: colorScheme.slider.arrow,
                                 lineWidth: lineWidth)
            mainLayer.addSublayer(line2)

            if left {
                self.arrow3 = line2
            } else {
                self.arrow4 = line2
            }
            topArrow = line2
        }

        radians = left ? (360 - arrowAngle).radians : (180 + arrowAngle).radians
        var transform2 = CATransform3DMakeTranslation(point.x - lineWidth - deltaX,
                                                      point.y - arrowHeight / 4, 0)
        transform2 = CATransform3DRotate(transform2, radians, 0.0, 0.0, 1.0)
        topArrow!.transform = transform2
    }
    
    func prepareForReuse() {
        chartModels = nil
        sliderDirection = .finished
        sliderWidth = 0
        startX = 0
        currentRange = IndexRange(start: CGFloat(0.0), end: CGFloat(0.0))
    }
}
