//
//  ChartView.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/11/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class ChartView: UIView {
    
    var chartModels: [ChartModel]? {
        didSet {
            self.selectedIndex = nil
            cleanDots()
        }
    }

    var range: IndexRange = (0, 0) {
        didSet {
            self.selectedIndex = nil
            cleanDots()
        }
    }
    
    var drawingStyle: DrawingStyleProtocol = StandardDrawingStyle() { didSet { setNeedsLayout() } }

    var colorScheme: ColorSchemeProtocol = DayScheme() { didSet { setNeedsLayout() } }
    
    var isPreviewMode: Bool = false
    
    var animationDuration: CFTimeInterval = 0.5

    private var lineGap: CGFloat = 60.0
    
    private var topSpace: CGFloat = 40.0
    
    private var bottomSpace: CGFloat = 40.0
    
    private var topHorizontalLine: CGFloat = 95.0 / 100.0
    
    private var innerRadius: CGFloat = 6

    private var outerRadius: CGFloat = 10
    
    private var minValue: CGFloat = 0
    
    private var maxValue: CGFloat = 0

    private var targetMaxValue: CGFloat = 0

    private var deltaToTargetValue: CGFloat = 0
    
    private var frameAnimation: Int = 0
    
    private var runMaxValueAnimation: Bool = false
    
    private var countPoints: Int = 0

    private var framesInAnimationDuration: Int {
        return Int(CFTimeInterval(60) * animationDuration)
    }
    
    private let dataLayer: CALayer = CALayer()
    
    private let mainLayer: CALayer = CALayer()
    
    private let gridLayer: CALayer = CALayer()
    
    private var dataPoints: [[CGPoint]]?

    private var chartLines: [CAShapeLayer]?

    private var gridLines: [ValueLayer]?

    private var gridLinesToRemove: [ValueLayer]?
    
    private var labels: [CATextLayer]?
    
    private var selectedIndex: Int?
    
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
    
    func update() {
        guard runMaxValueAnimation else {
            return
        }
        if frameAnimation < framesInAnimationDuration {
            // Ease-in-out function from
            // https://math.stackexchange.com/questions/121720/ease-in-out-function
            var prevy: CGFloat = 0
            for time in 0..<framesInAnimationDuration {
                let x = CGFloat(time) / CGFloat(framesInAnimationDuration - 1)
                let y = (x * x) / (x * x + (1.0 - x) * (1.0 - x))
                
                let toAddValue = deltaToTargetValue * (y - prevy)
                prevy = y
                
                if time == frameAnimation {
                    maxValue = maxValue + toAddValue
                    setNeedsLayout()
                }
            }
            frameAnimation += 1
        } else {
            runMaxValueAnimation = false
        }
    }
    
    private func setMaxValue(_ newMaxValue: CGFloat, animated: Bool = false) {
        if animated {
            guard newMaxValue != targetMaxValue else {
                return
            }
            targetMaxValue = newMaxValue
            drawHorizontalLines(animated: true)
            deltaToTargetValue = newMaxValue - maxValue
            frameAnimation = 0
            runMaxValueAnimation = true
        } else {
            maxValue = newMaxValue
        }
    }
    
    private func setupView() {
        mainLayer.addSublayer(dataLayer)
        layer.addSublayer(gridLayer)
        layer.addSublayer(mainLayer)
        clipsToBounds = true
    }
    
    private func calcProperties() {
        guard let chartModels = chartModels else {
            return
        }
        let animateMaxValue = maxValue == 0 ? false : true
        if isPreviewMode {
            topSpace = 0.0
            bottomSpace = 0.0
            topHorizontalLine = 110.0 / 100.0
            
            countPoints = chartModels.map { $0.data.count }.max() ?? 0
            lineGap = self.frame.size.width / (CGFloat(countPoints) - 1)
            let max: CGFloat = chartModels.map { chartModel in
                if chartModel.isHidden {
                    return 0
                } else {
                    return CGFloat(chartModel.data.max()?.value ?? 0)
                }}.compactMap { $0 }.max() ?? 0
            setMaxValue(max, animated: animateMaxValue)
        } else {
            topSpace = 40.0
            bottomSpace = 40.0
            topHorizontalLine = 95.0 / 100.0
            lineGap = self.frame.size.width / (range.end - range.start - 1)
            var max: CGFloat = 0
            for chartModel in chartModels {
                if chartModel.isHidden { continue }
                for i in 0..<chartModel.data.count {
                    let x = (CGFloat(i) - range.start) * lineGap
                    if x >= 0, x <= self.frame.size.width {
                        let value = CGFloat(chartModel.data[i].value)
                        if value > max {
                            max = value
                        }
                    }
                }
            }
            setMaxValue(max, animated: animateMaxValue)
        }
    }
    
    override func layoutSubviews() {
        backgroundColor = colorScheme.background
        guard let chartModels = chartModels else {
            return
        }
        
        let animateMaxValue = maxValue == 0 ? false : true
        calcProperties()
        
        let width = CGFloat(countPoints) * lineGap
        let height = self.frame.size.height
        mainLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
        dataLayer.frame = CGRect(x: 0, y: topSpace, width: mainLayer.frame.width,
                                 height: mainLayer.frame.height - topSpace - bottomSpace)
        
        dataPoints = [[CGPoint]]()
        for index in 0..<chartModels.count {
            let points = convertDataEntriesToPoints(entries: chartModels[index].data)
            dataPoints?.append(points)
        }
        
        gridLayer.frame = CGRect(x: 0, y: topSpace, width: self.frame.width,
                                 height: mainLayer.frame.height - topSpace - bottomSpace)
        if !animateMaxValue {
            drawHorizontalLines(animated: false)
        }

        drawCharts()
        drawLables()
    }
    
    private func calcHeight(for value: Int, with minMaxGap: CGFloat) -> CGFloat {
        if value == 0 {
            return dataLayer.frame.height
        }
        if Int(minMaxGap) == 0 {
            return -dataLayer.frame.height
        }
        return dataLayer.frame.height * (1 - ((CGFloat(value) - CGFloat(minValue)) / minMaxGap))
    }
    
    private func calcLineValue(for value: CGFloat, with minMaxGap: CGFloat) -> Int {
        return Int((1 - value) * minMaxGap) + Int(minValue)
    }
    
    private func convertDataEntriesToPoints(entries: [PointModel]) -> [CGPoint] {
        var result: [CGPoint] = []
        let minMaxGap = CGFloat(maxValue - minValue) * topHorizontalLine
        let startFrom: CGFloat = 0 // isPreviewMode ? 0 : 20 // TODO: + 40
        
        for i in 0..<entries.count {
            let height = calcHeight(for: entries[i].value, with: minMaxGap)
            let point = CGPoint(x: CGFloat(i) * lineGap + startFrom, y: height)
            result.append(point)
        }
        return result
    }
    
    private func drawCharts() {
        guard let dataPoints = dataPoints, dataPoints.count > 0,
            let chartModels = chartModels else {
            return
        }
        
        let isUpdating = chartLines != nil
        var newChartLines = isUpdating ? nil : [CAShapeLayer]()
        
        for index in 0..<chartModels.count {
            let chartModel = chartModels[index]
            
            let lineLayer = isUpdating ? chartLines![index] : CAShapeLayer()
            
            var points = dataPoints[index]
            if !isPreviewMode {
                for i in 0..<points.count {
                    points[i] = CGPoint(x: (CGFloat(i) - range.start) * lineGap, y: points[i].y)
                }
            }
            
            if let path = drawingStyle.createPath(dataPoints: points) {
                if isUpdating {
                    lineLayer.changePath(to: path, animationDuration: animationDuration)
                    CATransaction.setDisableActions(true)
                    if chartModel.opacity != lineLayer.opacity {
                        let toValue: Float = chartModel.opacity
                        let fromValue: Float = lineLayer.opacity
                        lineLayer.changeOpacity(from: fromValue, to: toValue,
                                                animationDuration: animationDuration)
                    }
                } else {
                    lineLayer.path = path.cgPath
                    lineLayer.strokeColor = chartModel.color.cgColor
                    lineLayer.fillColor = UIColor.clear.cgColor
                    lineLayer.lineWidth = isPreviewMode ? 1.0 : 2.0
                    dataLayer.addSublayer(lineLayer)
                    newChartLines!.append(lineLayer)
                }
            }
        }
        
        if !isUpdating {
            chartLines = newChartLines
        }
    }
        
    private func drawLables() {
        guard let chartModels = chartModels, chartModels.count > 0, !isPreviewMode else {
            return
        }
        var points: [PointModel]?
        _ = chartModels.map {
            if $0.data.count > points?.count ?? 0 { points = $0.data }
        }
        
        let isUpdating = labels != nil
        var newLabels = isUpdating ? nil : [CATextLayer]()

        let textGap: CGFloat = 60
        if var points = points {
            let startFrom: CGFloat = 0 // isPreviewMode ? 0 : 20 // TODO: + 40

            var startX: CGFloat = -1
            for index in 0..<points.count {
                let textLayer = isUpdating ? labels![index] : CATextLayer()

                let x = (CGFloat(index) - range.start) * lineGap - textGap / 2 + startFrom
                
                var opacity: Float = 0
                if startX == -1 || x - startX >= textGap {
                    opacity = 1
                    startX = x
                }
                CATransaction.setDisableActions(true)
                textLayer.frame = CGRect(x: x,
                                         y: mainLayer.frame.size.height - bottomSpace / 2 - 8,
                                         width: textGap,
                                         height: 16)

                if isUpdating {
                     if textLayer.opacity != opacity {
                        textLayer.changeOpacity(from: textLayer.opacity, to: opacity,
                                                animationDuration: animationDuration)
                    }
                } else {
                    textLayer.foregroundColor = colorScheme.text.cgColor
                    textLayer.backgroundColor = UIColor.clear.cgColor
                    textLayer.alignmentMode = .center
                    textLayer.contentsScale = UIScreen.main.scale
                    textLayer.font = CTFontCreateWithName(UIFont.systemFont(ofSize: 0).fontName as CFString, 0, nil)
                    textLayer.fontSize = 11
                    textLayer.string = points[index].date
                    textLayer.opacity = opacity
                    mainLayer.addSublayer(textLayer)
                    newLabels!.append(textLayer)
                }
            }
        }

        if !isUpdating {
            labels = newLabels
        }
    }
    
    private func drawHorizontalLines(animated: Bool) {
        guard let _ = chartModels, !isPreviewMode else {
            return
        }
        
        let minMaxGap = CGFloat(maxValue - minValue) * topHorizontalLine
        let newMinMaxGap = CGFloat(targetMaxValue - minValue) * topHorizontalLine
        
        let heightGrid: CGFloat = 30
        let widthGrid: CGFloat = self.frame.size.width
        let isUpdating = self.gridLines != nil
        var newGridLines = [ValueLayer]()
        var newGridLinesToRemove = [ValueLayer]()

        _ = gridLinesToRemove?.map { $0.removeFromSuperlayer() }
        
        let gridValues: [CGFloat] = [0, 0.2, 0.4, 0.6, 0.8, 1]
        for index in 0..<gridValues.count {
            let value = gridValues[index]
            var duration: CFTimeInterval = 0
            if animated {
                duration = value == 1 ? 0 : animationDuration
            }

            let lineValue = calcLineValue(for: value, with: minMaxGap)
            let newLineValue = calcLineValue(for: value, with: newMinMaxGap)
            
            let oldValueLayer = isUpdating ? gridLines![index] : nil
            let newValueLayer = ValueLayer()

            let fromNewHeight = calcHeight(for: newLineValue, with: minMaxGap)
            let fromNewFrame = CGRect(x: 0, y: fromNewHeight, width: frame.size.width, height: heightGrid)
            let toNewHeight = calcHeight(for: newLineValue, with: newMinMaxGap) + heightGrid / 2
            let toNewPoint = CGPoint(x: widthGrid / 2, y: toNewHeight)
            newValueLayer.lineColor = colorScheme.grid
            newValueLayer.textColor = colorScheme.text
            gridLayer.addSublayer(newValueLayer)
            newGridLines.append(newValueLayer)
            
            if let oldValueLayer = oldValueLayer {
                let toHeight = calcHeight(for: lineValue, with: newMinMaxGap) + heightGrid / 2
                let toPoint = CGPoint(x: widthGrid / 2, y: toHeight)
                CATransaction.setDisableActions(true)
                oldValueLayer.moveTo(point: toPoint, animationDuration: duration)
                oldValueLayer.changeOpacity(from: 1, to: 0, animationDuration: duration)
                newGridLinesToRemove.append(oldValueLayer)
            }
            
            if isUpdating {
                newValueLayer.lineValue = newLineValue
                newValueLayer.opacity = 0
                newValueLayer.frame = fromNewFrame
                newValueLayer.moveTo(point: toNewPoint, animationDuration: duration)
                newValueLayer.changeOpacity(from: 0, to: 1, animationDuration: duration)
            } else {
                newValueLayer.lineValue = lineValue
                newValueLayer.opacity = 1
                let height = calcHeight(for: lineValue, with: minMaxGap)
                let rect = CGRect(x: 0, y: height, width: frame.size.width, height: heightGrid)
                newValueLayer.frame = rect
            }
        }
        
        gridLines = newGridLines
        gridLinesToRemove = newGridLinesToRemove
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        drawDotsIfNeeded(touches)
    }
    
    private func drawDotsIfNeeded(_ touches: Set<UITouch>) {
        guard let dataPoints = dataPoints, dataPoints.count > 0,
            !isPreviewMode, let touch = touches.first else {
                return
        }
        let location = touch.location(in: self)
        guard location.x >= 0, location.x <= frame.size.width else {
            return
        }
        
        let newSelectedIndex = Int((location.x + range.start * lineGap) / lineGap)
        var isUpdating = self.selectedIndex == nil
        if let selectedIndex = self.selectedIndex,
            selectedIndex != newSelectedIndex {
            isUpdating = true
        }
        if isUpdating {
            self.selectedIndex = newSelectedIndex
            cleanDots()
            drawDots()
        }
    }
    
    private func cleanDots() {
        CATransaction.setDisableActions(true)
        mainLayer.sublayers?.forEach {
            if $0 is DotLayer {
                $0.removeFromSuperlayer()
            }
        }
    }

    private func drawDots() {
        guard let dataPoints = dataPoints, dataPoints.count > 0, !isPreviewMode,
            let chartModels = chartModels,
            let selectedIndex = self.selectedIndex else {
            return
        }

        for index in 0..<chartModels.count {
            let chartModel = chartModels[index]
             if chartModel.isHidden { continue }
            
            var dotLayers: [DotLayer] = []
            var points = dataPoints[index]
            
            let dataPoint = points[selectedIndex]
            let xValue = (CGFloat(selectedIndex) - range.start) * lineGap - outerRadius / 2
            let yValue = dataPoint.y + bottomSpace - outerRadius / 2
            let dotLayer = DotLayer()
            dotLayer.dotInnerColor = colorScheme.background
            dotLayer.innerRadius = innerRadius
            dotLayer.backgroundColor = chartModel.color.cgColor
            dotLayer.cornerRadius = outerRadius / 2
            dotLayer.frame = CGRect(x: xValue, y: yValue, width: outerRadius, height: outerRadius)
            dotLayers.append(dotLayer)
            mainLayer.addSublayer(dotLayer)
        }
    }
    
}
