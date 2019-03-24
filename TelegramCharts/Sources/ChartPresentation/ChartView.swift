//
//  ChartView.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/11/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class ChartView: UIView, Reusable, Updatable {
    
    var dataSource: ChartDataSource?
    
    var colorScheme: ColorSchemeProtocol = DayScheme() {
        didSet {
            setNeedsLayout()
            updateColors()
        }
    }
    
    var isScrolling = false

    var sliderDirection: SliderDirection = .right
    
    private var setFinishedSliderDirection = true
    
    private var isJustReused = true
    
    private let labelWidth: CGFloat = 36
    
    private let dataLayer: CALayer = CALayer()
    
    private let mainLayer: CALayer = CALayer()
    
    private let gridLayer: CALayer = CALayer()

    private var chartLines: [CAShapeLayer]?

    private var gridLines: [ValueLayer]?

    private var gridLinesToRemove: [ValueLayer]?
    
    private var labels: [TextLayer]?
    
    private var innerRadius: CGFloat = 6
    
    private var outerRadius: CGFloat = 10

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
        dataSource?.update()
    }
    
    private func setupView() {
        mainLayer.addSublayer(dataLayer)
        layer.addSublayer(gridLayer)
        layer.addSublayer(mainLayer)
        clipsToBounds = true
    }
    
    override func layoutSubviews() {
        guard let dataSource = dataSource,
            let dataPoints = dataSource.dataPoints, dataPoints.count > 0 else {
            return
        }
        self.backgroundColor = .clear

        let width = CGFloat(dataSource.countPoints) * dataSource.lineGap
        let height = self.frame.size.height
        self.mainLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
        self.dataLayer.frame = CGRect(x: 0, y: dataSource.topSpace,
                                      width: self.mainLayer.frame.width,
                                      height: self.mainLayer.frame.height - dataSource.topSpace - dataSource.bottomSpace)
        
        self.gridLayer.frame = CGRect(x: 0, y: dataSource.topSpace,
                                      width: self.frame.width,
                                      height: self.mainLayer.frame.height - dataSource.topSpace - dataSource.bottomSpace)
        
        if isJustReused {
            self.drawHorizontalLines(animated: false)
            isJustReused = false
        }
        self.drawCharts()
        
        if !isScrolling {
            drawLabels(byScroll: false)
        }
    }
    
    private func drawCharts() {
        guard let dataSource = dataSource,
            let dataPoints = dataSource.dataPoints, dataPoints.count > 0,
            let paths = dataSource.paths else {
            return
        }
        
        let isUpdating = chartLines != nil
        var newChartLines = isUpdating ? nil : [CAShapeLayer]()
        
        for index in 0..<dataSource.chartModels.count {
            let chartModel = dataSource.chartModels[index]
            let lineLayer = isUpdating ? chartLines![index] : CAShapeLayer()
            let path = paths[index]
            if isUpdating {
                lineLayer.changePath(to: path, animationDuration: UIView.animationDuration)
                CATransaction.setDisableActions(true)
                if chartModel.opacity != lineLayer.opacity {
                    let toValue: Float = chartModel.opacity
                    let fromValue: Float = lineLayer.opacity
                    lineLayer.changeOpacity(from: fromValue, to: toValue,
                                            animationDuration: UIView.animationDuration)
                }
            } else {
                lineLayer.path = path.cgPath
                lineLayer.opacity = chartModel.opacity
                lineLayer.strokeColor = chartModel.color.cgColor
                lineLayer.fillColor = UIColor.clear.cgColor
                lineLayer.lineWidth = dataSource.isPreviewMode ? 1.0 : 2.0
                dataLayer.addSublayer(lineLayer)
                newChartLines!.append(lineLayer)
            }
        }
        
        if !isUpdating {
            chartLines = newChartLines
        }
    }
        
    func drawLabels(byScroll: Bool) {
        guard let dataSource = dataSource,
            dataSource.chartModels.count > 0,
            !dataSource.isPreviewMode else {
            return
        }
        
        let isUpdating = labels != nil
        var newLabels = isUpdating ? nil : [TextLayer]()

        let startFrom: CGFloat = 0 // isPreviewMode ? 0 : 20 // TODO: + 40
        
        for index in 0..<dataSource.maxRangePoints.count {
            let textLayer = isUpdating ? labels![index] : TextLayer()
            
            let x = (CGFloat(index) - dataSource.range.start) * dataSource.lineGap - labelWidth / 2 + startFrom
            
            CATransaction.setDisableActions(true)
            textLayer.frame = CGRect(x: x,
                                     y: mainLayer.frame.size.height - dataSource.bottomSpace / 2 - 4,
                                     width: labelWidth,
                                     height: 16)
            if !isUpdating {
                textLayer.foregroundColor = colorScheme.chart.text.cgColor
                textLayer.backgroundColor = UIColor.clear.cgColor
                textLayer.alignmentMode = .center
                textLayer.contentsScale = UIScreen.main.scale
                textLayer.font = CTFontCreateWithName(UIFont.systemFont(ofSize: 0).fontName as CFString, 0, nil)
                textLayer.fontSize = 11
                textLayer.string = dataSource.maxRangePoints[index].date
                textLayer.opacity = 0
                textLayer.toOpacity = 0
                mainLayer.addSublayer(textLayer)
                newLabels!.append(textLayer)
            }
        }

        if !isUpdating {
            labels = newLabels
        }
        
        self.hideWrongLabels(isFirstCall: true, byScroll: byScroll)
        if self.setFinishedSliderDirection {
            self.sliderDirection = .finished
            self.hideWrongLabels(isFirstCall: true, byScroll: byScroll)
            self.setFinishedSliderDirection = false
        }
    }
    
    func hideWrongLabels(isFirstCall: Bool, byScroll: Bool) {
        guard let dataSource = dataSource,
            dataSource.chartModels.count > 0,
            !dataSource.isPreviewMode else {
                return
        }
        
        let skipHidden = !isFirstCall
        
        // It's really the first call of the func.
        if isFirstCall && setFinishedSliderDirection {
            if sliderDirection == .left || sliderDirection == .right {
                _ = labels?.map { label in
                    label.toOpacity = 1
                    if !isScrolling {
                        label.opacity = 1
                    }
                }
            }
        }

        // Drop isStatic. We'll find another one next time.
        if sliderDirection != .left && sliderDirection != .right {
            _ = labels?.map { label in
                label.isStatic = false
            }
        }
        
        if sliderDirection == .left || sliderDirection == .right {
            
            var theIndex = 0
            var staticIndex: Int?
            for index in 0..<dataSource.maxRangePoints.count {
                let textLayer = labels![index]
                if textLayer.isStatic {
                    staticIndex = index
                    break
                }
            }
            
            if let staticIndex = staticIndex {
                theIndex = staticIndex
            } else {
                if setFinishedSliderDirection {
                    let x = sliderDirection == .left ? self.frame.size.width - labelWidth / 2 : labelWidth / 2
                    theIndex = Int((x + dataSource.range.start * dataSource.lineGap + labelWidth / 2) / dataSource.lineGap)
                    let textLayer = labels![theIndex]
                    textLayer.isStatic = true
                } else {
                    let range = 0..<dataSource.maxRangePoints.count
                    for index in range {
                        let aIndex = sliderDirection == .left ? range.endIndex - index - 1 : index
                        let textLayer = labels![aIndex]
                        if textLayer.toOpacity == 1 {
                            let textLayerX = (CGFloat(aIndex) - dataSource.range.start) * dataSource.lineGap - labelWidth / 2
                            if textLayerX > -labelWidth / 2 && textLayerX < self.frame.size.width - labelWidth / 2 {
                                textLayer.isStatic = true
                                theIndex = aIndex
                                break
                            }
                        }
                    }
                }
            }
            
            if sliderDirection == .left {
                let inverseRange = 0..<theIndex + 1
                doMagic(in: inverseRange, skipHidden: skipHidden, inverse: true, byScroll: byScroll)
                
                let indexRange = theIndex..<dataSource.maxRangePoints.count
                doMagic(in: indexRange, skipHidden: skipHidden, inverse: false, byScroll: byScroll)
            } else {
                let indexRange = theIndex..<dataSource.maxRangePoints.count
                doMagic(in: indexRange, skipHidden: skipHidden, inverse: false, byScroll: byScroll)
                
                let inverseRange = 0..<theIndex + 1
                doMagic(in: inverseRange, skipHidden: skipHidden, inverse: true, byScroll: byScroll)
            }
        } else if sliderDirection == .finished {
            if let labels = labels {
                for textLayer in labels {
                    if textLayer.toOpacity == 1 {
                        textLayer.opacity = textLayer.toOpacity
                        /* if byScroll {
                            textLayer.opacity = 0
                            textLayer.changeOpacity(from: textLayer.opacity, to: textLayer.toOpacity,
                                                    animationDuration: UIView.animationDuration)

                        }*/
                    } else {
                        textLayer.opacity = 0
                        /*if byScroll {
                            textLayer.opacity = 0
                        } else {
                            textLayer.opacity = textLayer.toOpacity
                            if textLayer.opacity != 0 {
                                textLayer.changeOpacity(from: textLayer.opacity, to: 0,
                                                        animationDuration: UIView.animationDuration)
                            }
                        }*/
                    }
                }
            }
        }
    }
    
    func doMagic(in range: Range<Int>, skipHidden: Bool, inverse: Bool, byScroll: Bool) {
        var lastFrame: CGRect = .zero
        
        var wereHiddenLayers = false
        for index in range {
            let inverseIndex = range.endIndex - index - 1
            let textLayer = inverse ? labels![inverseIndex] : labels![index]
            let coef: CGFloat = inverse ? -1 : 1
            
            if skipHidden, textLayer.toOpacity == 0 {
                continue
            }
            
            let startXFrame = textLayer.frame.origin.x - textLayer.frame.size.width * coef / 2
            
            if lastFrame == .zero {
                textLayer.toOpacity = 1
                if !isScrolling {
                    textLayer.opacity = 1
                }
                lastFrame = textLayer.frame
            } else {
                let endXLastFrame = lastFrame.origin.x + lastFrame.size.width * coef / 2 + labelWidth * coef
                let condition = inverse ? startXFrame < endXLastFrame : startXFrame > endXLastFrame
                if condition {
                    textLayer.toOpacity = 1
                    if !isScrolling {
                        textLayer.opacity = 1
                    }
                    lastFrame = textLayer.frame
                } else {
                    let delta = inverse ? startXFrame - endXLastFrame : endXLastFrame - startXFrame
                    let opacity = max(Float(1 - delta / textLayer.frame.size.width), 0)
                    textLayer.toOpacity = opacity
                    if !isScrolling {
                        textLayer.opacity = opacity
                    }
                    if opacity == 0 {
                        lastFrame = .zero
                        wereHiddenLayers = true
                    }
                }
            }
        }
        
        if wereHiddenLayers {
            hideWrongLabels(isFirstCall: false, byScroll: byScroll)
        }
    }
    
    func updateColors() {
        if let gridLines = gridLines {
            _ = gridLines.map { $0.updateColors(lineColor: colorScheme.chart.grid,
                                                textColor: colorScheme.chart.text)}
        }
        if let labels = labels {
            _ = labels.map { $0.changeColor(to: colorScheme.chart.text, keyPath: "foregroundColor",
                                            animationDuration: UIView.animationDuration) }
        }
    }
    
    func drawHorizontalLines(animated: Bool) {
        guard let dataSource = dataSource,
            !dataSource.isPreviewMode else {
                return
        }

        let minMaxGap = CGFloat(dataSource.maxValue - dataSource.minValue) * dataSource.topHorizontalLine
        let newMinMaxGap = CGFloat(dataSource.targetMaxValue - dataSource.minValue) * dataSource.topHorizontalLine
        
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
                duration = value == 1 ? 0 : UIView.animationDuration
            }

            let lineValue = dataSource.calcLineValue(for: value, with: minMaxGap)
            let newLineValue = dataSource.calcLineValue(for: value, with: newMinMaxGap)
            
            let oldValueLayer = isUpdating ? gridLines![index] : nil
            let newValueLayer = ValueLayer()

            let fromNewHeight = dataSource.calcHeight(for: newLineValue, with: minMaxGap)
            let fromNewFrame = CGRect(x: 0, y: fromNewHeight, width: frame.size.width, height: heightGrid)
            let toNewHeight = dataSource.calcHeight(for: newLineValue, with: newMinMaxGap) + heightGrid / 2
            let toNewPoint = CGPoint(x: widthGrid / 2, y: toNewHeight)
            newValueLayer.lineColor = colorScheme.chart.grid
            newValueLayer.textColor = colorScheme.chart.text
            gridLayer.addSublayer(newValueLayer)
            newGridLines.append(newValueLayer)
            
            if let oldValueLayer = oldValueLayer {
                let toHeight = dataSource.calcHeight(for: lineValue, with: newMinMaxGap) + heightGrid / 2
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
                let height = dataSource.calcHeight(for: lineValue, with: minMaxGap)
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
        guard let dataSource = dataSource,
            let dataPoints = dataSource.dataPoints, dataPoints.count > 0,
            !dataSource.isPreviewMode, let touch = touches.first else {
                return
        }
        let location = touch.location(in: self)
        guard location.x >= 0, location.x <= frame.size.width else {
            return
        }
        
        let newSelectedIndex = Int((location.x + dataSource.range.start * dataSource.lineGap) / dataSource.lineGap)
        var isUpdating = dataSource.selectedIndex == nil
        if let selectedIndex = dataSource.selectedIndex,
            selectedIndex != newSelectedIndex {
            isUpdating = true
        }
        if isUpdating {
            dataSource.selectedIndex = newSelectedIndex
            cleanDots()
            drawDots()
        }
    }
    
    func cleanDots() {
        CATransaction.setDisableActions(true)
        dataLayer.sublayers?.forEach {
            if $0 is DotLayer {
                $0.removeFromSuperlayer()
            }
        }
    }

    private func drawDots() {
        guard let dataSource = dataSource,
            let dataPoints = dataSource.dataPoints, dataPoints.count > 0,
            !dataSource.isPreviewMode,
            let selectedIndex = dataSource.selectedIndex else {
            return
        }

        for index in 0..<dataSource.chartModels.count {
            let chartModel = dataSource.chartModels[index]
             if chartModel.isHidden { continue }
            
            var dotLayers: [DotLayer] = []
            var points = dataPoints[index]
            
            let dataPoint = points[selectedIndex]
            let xValue = (CGFloat(selectedIndex) - dataSource.range.start) * dataSource.lineGap - outerRadius / 2
            let yValue = dataPoint.y  - outerRadius / 2

            let dotLayer = DotLayer()
            dotLayer.dotInnerColor = colorScheme.chart.background
            dotLayer.innerRadius = innerRadius
            dotLayer.backgroundColor = chartModel.color.cgColor
            dotLayer.cornerRadius = outerRadius / 2
            dotLayer.frame = CGRect(x: xValue, y: yValue, width: outerRadius, height: outerRadius)
            dotLayers.append(dotLayer)
            dataLayer.addSublayer(dotLayer)
        }
    }
    
    func prepareForReuse() {
        chartLines = nil
        gridLines = nil
        labels = nil
        dataSource = nil
        isJustReused = true
        
        sliderDirection = .right
        setFinishedSliderDirection = true
        isScrolling = true
        
        mainLayer.sublayers?.forEach {
            if $0 is TextLayer {
                $0.removeFromSuperlayer()
            }
        }

        dataLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        gridLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
    }

}
