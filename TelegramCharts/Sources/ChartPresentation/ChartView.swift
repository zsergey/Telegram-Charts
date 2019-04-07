//
//  ChartView.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/11/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class ChartView: UIView, Reusable, Updatable, UIGestureRecognizerDelegate {
    
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
    
    private var innerRadius: CGFloat = 4
    
    private var outerRadius: CGFloat = 8
    
    private var verticalLine: CAShapeLayer?

    private var dotInfo: CAShapeLayer?
    
    private var dateTextLayer: CATextLayer?

    private var yearTextLayer: CATextLayer?
    
    private var valueTextLayers: [CATextLayer]?

    private var dotsTextLayers: [DotLayer]?

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
        layer.cornerRadius = SliderView.thumbCornerRadius // TODO: fix
        
        mainLayer.addSublayer(dataLayer)
        layer.addSublayer(gridLayer)
        layer.addSublayer(mainLayer)
        clipsToBounds = true
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        panGesture.maximumNumberOfTouches = 1
        panGesture.minimumNumberOfTouches = 1
        panGesture.delegate = self
        addGestureRecognizer(panGesture)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    @objc private func handlePan(recognizer: UIPanGestureRecognizer) {
        let point = recognizer.location(in: self)
        drawDotsIfNeeded(location: point)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
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
                CATransaction.setDisableActions(true)
                lineLayer.path = path.cgPath
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
                lineLayer.lineCap = .round
                lineLayer.lineJoin = .round
                dataLayer.addSublayer(lineLayer)
                newChartLines!.append(lineLayer)
            }
        }
        
        if !isUpdating {
            chartLines = newChartLines
        }
    }
        
    func drawLabels(byScroll: Bool) {
        // TODO:
        return
        
        guard let dataSource = dataSource,
            dataSource.chartModels.count > 0,
            !dataSource.isPreviewMode else {
            return
        }
        
        let isUpdating = labels != nil
        var newLabels = isUpdating ? nil : [TextLayer]()

        for index in 0..<dataSource.maxRangePoints.count {
            let textLayer = isUpdating ? labels![index] : TextLayer()
            
            let x = (CGFloat(index) - dataSource.range.start) * dataSource.lineGap - labelWidth / 2
            
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
                textLayer.string = dataSource.maxRangePoints[index].stringDate
                textLayer.opacity = 0
                textLayer.toOpacity = 0
                mainLayer.addSublayer(textLayer)
                newLabels!.append(textLayer)
            }
        }

        if !isUpdating {
            labels = newLabels
        }
        
        hideWrongLabelsUseSliderDirection(byScroll: byScroll)
        if self.setFinishedSliderDirection {
            self.sliderDirection = .finished
            hideWrongLabelsUseSliderDirection(byScroll: byScroll)
            self.setFinishedSliderDirection = false
        }
    }
    
    func hideWrongLabelsUseSliderDirection(byScroll: Bool) {
        switch sliderDirection {
        case .center, .finished, .none:
            self.hideWrongLabels(isFirstCall: false, byScroll: byScroll)
        case .left, .right:
            self.hideWrongLabels(isFirstCall: true, byScroll: byScroll)
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
                labels?.forEach { label in
                    label.toOpacity = 1
                    if !isScrolling {
                        label.opacity = 1
                    }
                }
            }
        }

        // Drop isStatic. We'll find another one next time.
        if sliderDirection != .left && sliderDirection != .right {
            labels?.forEach { $0.isStatic = false }
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
                    let toOpacity: Float = textLayer.toOpacity >= 0.5 ? 1 : 0
                    if textLayer.opacity != toOpacity {
                        if byScroll && toOpacity == 0 {
                            textLayer.opacity = 0
                        } else {
                            textLayer.changeOpacity(from: textLayer.opacity, to: toOpacity,
                                                    animationDuration: UIView.animationDuration)
                        }
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
                    var opacity = max(Float(1 - delta / textLayer.frame.size.width), 0)
                    
                    if sliderDirection == .center ||
                        sliderDirection == .none,
                        opacity >= 0.5 {
                        opacity = 1
                    }
                    
                    if sliderDirection == .finished, opacity >= 0.5 {
                        // nothing to change.
                    } else {
                        textLayer.toOpacity = opacity
                        if !isScrolling {
                            textLayer.opacity = opacity
                        }
                    }
                    
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
            gridLines.forEach {
                let color = $0.lineValue == 0 ? colorScheme.chart.accentGrid: colorScheme.chart.grid
                $0.updateColors(lineColor: color, textColor: colorScheme.chart.text)
            }
        }
        if let labels = labels {
            labels.forEach {
                $0.changeColor(to: colorScheme.chart.text,
                               keyPath: "foregroundColor",
                               animationDuration: UIView.animationDuration)
            }
        }
        if dataSource?.selectedIndex != nil {
            drawDots()
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

        gridLinesToRemove?.forEach { $0.removeFromSuperlayer() }
        
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
            newValueLayer.contentBackground = colorScheme.chart.background
            
            let fromNewHeight = dataSource.calcHeight(for: newLineValue, with: minMaxGap)
            let fromNewFrame = CGRect(x: 0, y: fromNewHeight, width: frame.size.width, height: heightGrid)
            let toNewHeight = dataSource.calcHeight(for: newLineValue, with: newMinMaxGap) + heightGrid / 2
            let toNewPoint = CGPoint(x: widthGrid / 2, y: toNewHeight)
            newValueLayer.lineColor = index == gridValues.count - 1 ? colorScheme.chart.accentGrid: colorScheme.chart.grid
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

    private func drawDotsIfNeeded(location: CGPoint) {
        guard let dataSource = dataSource,
            let dataPoints = dataSource.dataPoints, dataPoints.count > 0,
            !dataSource.isPreviewMode else {
                return
        }
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
            drawDots()
        }
    }
    
    func cleanDots() {
        verticalLine?.removeFromSuperlayer()
        dotInfo?.removeFromSuperlayer()
        dateTextLayer?.removeFromSuperlayer()
        yearTextLayer?.removeFromSuperlayer()
        valueTextLayers?.forEach { $0.removeFromSuperlayer() }
        dotsTextLayers?.forEach { $0.removeFromSuperlayer() }
        
        dotInfo = nil
        verticalLine = nil
        dateTextLayer = nil
        yearTextLayer = nil
        valueTextLayers = nil
        dotsTextLayers = nil

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
        
        var visibleChartModels = [ChartModel]()
        for index in 0..<dataSource.chartModels.count {
            let chartModel = dataSource.chartModels[index]
            if !chartModel.isHidden {
                visibleChartModels.append(chartModel)
            }
        }

        guard visibleChartModels.count > 0 else {
            return
        }
        
        CATransaction.setDisableActions(true)

        // Line.
        let path = UIBezierPath()
        
        let isUpdating = verticalLine != nil
        let lineLayer = isUpdating ? verticalLine! : CAShapeLayer()
        if !isUpdating {
            lineLayer.fillColor = UIColor.clear.cgColor
            lineLayer.lineWidth = 0.5
            dataLayer.addSublayer(lineLayer)
        }
        
        // Dots.
        var xLine: CGFloat = 0
        var dotIndex = 0
        for index in 0..<dataSource.chartModels.count {
            let chartModel = dataSource.chartModels[index]
            if chartModel.isHidden { continue }
            
            var points = dataPoints[index]
            
            let dataPoint = points[selectedIndex]
            let xValue = (CGFloat(selectedIndex) - dataSource.range.start) * dataSource.lineGap - outerRadius / 2
            let yValue = dataPoint.y  - outerRadius / 2
            let dotFrame = CGRect(x: xValue, y: yValue, width: outerRadius, height: outerRadius)
            
            if let dotsTextLayers = dotsTextLayers, dotIndex < dotsTextLayers.count {
                dotsTextLayers[dotIndex].dotInnerColor = colorScheme.chart.background
                dotsTextLayers[dotIndex].backgroundColor = chartModel.color.cgColor
                dotsTextLayers[dotIndex].frame = dotFrame
            } else {
                let dotLayer = DotLayer()
                dotLayer.dotInnerColor = colorScheme.chart.background
                dotLayer.innerRadius = innerRadius
                dotLayer.backgroundColor = chartModel.color.cgColor
                dotLayer.cornerRadius = outerRadius / 2
                dotLayer.frame = dotFrame
                dataLayer.addSublayer(dotLayer)
                if dotsTextLayers == nil {
                    dotsTextLayers = [DotLayer]()
                }
                dotsTextLayers!.append(dotLayer)
            }
            dotIndex += 1
            xLine = xValue + outerRadius / 2
        }
        
        // Path line.
        path.move(to: CGPoint(x: xLine, y: -dataSource.topSpace / 2))
        path.addLine(to: CGPoint(x: xLine, y: self.frame.size.height - dataSource.topSpace - dataSource.bottomSpace))
        lineLayer.path = path.cgPath
        lineLayer.strokeColor = colorScheme.chart.accentGrid.cgColor
        if !isUpdating {
            self.verticalLine = lineLayer
        }

        // Rect.
        var rectWidth: CGFloat = 80
        var maxString = ""
        for chartModel in visibleChartModels {
            let data = chartModel.data[selectedIndex]
            let format = data.value.format
            if maxString.count < format.count {
                maxString = format
            }
        }
        rectWidth = rectWidth + CGFloat(max((maxString.count - 2), 0) * 5)
        
        let space: CGFloat = 5
        let oneLine: CGFloat = 20
        let lines = max(visibleChartModels.count, 2)
        var rectHeight = CGFloat(lines) * oneLine
        rectHeight = rectHeight - CGFloat(max((lines - 2), 0) * 2)
        var xRect = xLine - rectWidth / 2
        if xRect < 0 {
            xRect = 0
        }
        if xRect > self.frame.size.width - rectWidth {
            xRect = self.frame.size.width - rectWidth
        }
        let rect = CGRect(x: xRect, y: -dataSource.topSpace + space,
                          width: rectWidth, height: rectHeight)
        let corners: UIRectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
        
        if isUpdating {
            self.dotInfo?.path = Painter.createRectPath(rect: rect, byRoundingCorners: corners, cornerRadius: 4).cgPath
            self.dotInfo?.fillColor = colorScheme.dotInfo.background.cgColor
        } else {
            let dotInfo = Painter.createRect(rect: rect, byRoundingCorners: corners,
                                             fillColor: colorScheme.dotInfo.background,
                                             cornerRadius: 4)
            dataLayer.addSublayer(dotInfo)
            self.dotInfo = dotInfo
        }

        // Date and numbers.
        var drawDate = true
        let xdata: CGFloat = rect.origin.x + 8 + 80 * 0.6
        var ydata: CGFloat = rect.origin.y + 5
        let deltaY = oneLine - 3
        for index in 0..<visibleChartModels.count {
            let chartModel = visibleChartModels[index]
            let data = chartModel.data[selectedIndex]
            if drawDate {
                let ydate = rect.origin.y + 5
                let isUpdating = self.dateTextLayer != nil
                let dateFrame = CGRect(x: rect.origin.x + 8,
                                       y: ydate, width: 50, height: 16)
                if isUpdating {
                    self.dateTextLayer?.frame = dateFrame
                    self.dateTextLayer?.string = data.dateDot
                } else {
                    let dateTextLayer = Painter.createText(textColor: colorScheme.dotInfo.text, bold: true)
                    dateTextLayer.frame = dateFrame
                    dateTextLayer.string = data.dateDot
                    dataLayer.addSublayer(dateTextLayer)
                    self.dateTextLayer = dateTextLayer
                }

                let yearFrame = CGRect(x: rect.origin.x + 8,
                                       y: ydate + deltaY, width: 50, height: 16)
                if isUpdating {
                    self.yearTextLayer?.frame = yearFrame
                    self.yearTextLayer?.string = data.year
                } else {
                    let yaerTextLayer = Painter.createText(textColor: colorScheme.dotInfo.text)
                    yaerTextLayer.frame = yearFrame
                        yaerTextLayer.string = data.year
                    dataLayer.addSublayer(yaerTextLayer)
                    self.yearTextLayer = yaerTextLayer
                }

                drawDate = false
            }
            
            let valueFrame = CGRect(x: xdata,
                                    y: ydata, width: 50, height: 16)
            
            if let valueTextLayers = valueTextLayers, index < valueTextLayers.count {
                valueTextLayers[index].frame = valueFrame
                valueTextLayers[index].string = data.value.format
            } else {
                let dataTextLayer = Painter.createText(textColor: chartModel.color, bold: true)
                dataTextLayer.frame = valueFrame
                dataTextLayer.string = data.value.format
                dataLayer.addSublayer(dataTextLayer)
                if self.valueTextLayers == nil {
                    self.valueTextLayers = [CATextLayer]()
                }
                self.valueTextLayers!.append(dataTextLayer)
            }
            ydata += deltaY

        }
        CATransaction.setDisableActions(false)

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
