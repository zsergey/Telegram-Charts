//
//  ChartContentView.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/11/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class ChartContentView: UIView, Reusable, Updatable, UIGestureRecognizerDelegate {
    
    var dataSource: ChartDataSource? {
        didSet {
            let isPreviewMode = dataSource?.isPreviewMode ?? false
            layer.cornerRadius = isPreviewMode ? SliderView.thumbCornerRadius : 0 // TODO: Performance
        }
    }
    
    var colorScheme: ColorSchemeProtocol = DayScheme() {
        didSet {
            updateColors()
        }
    }
    
    var isScrolling = false

    var sliderDirection: SliderDirection = .left
    
    private var setFinishedSliderDirection = true
    
    private var isJustReused = true
    
    static let labelWidth: CGFloat = 40
    
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
        mainLayer.addSublayer(dataLayer)
        layer.addSublayer(mainLayer)
        layer.addSublayer(gridLayer)
        
        clipsToBounds = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTouch))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        panGesture.maximumNumberOfTouches = 1
        panGesture.minimumNumberOfTouches = 1
        panGesture.delegate = self
        addGestureRecognizer(panGesture)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc private func handleTouch(recognizer: UIPanGestureRecognizer) {
        let point = recognizer.location(in: self)
        drawDotsIfNeeded(location: point)
    }

    @objc private func handlePan(recognizer: UIPanGestureRecognizer) {
        let point = recognizer.location(in: self)
        drawDotsIfNeeded(location: point)
    }
    
    func drawView() {
        
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
            drawHorizontalLines(animated: false)
            isJustReused = false
        }
        self.drawCharts()
        
        if !isScrolling {
            drawLabels(byScroll: false)
        }
    }
    
    func drawCharts() {

        guard let dataSource = dataSource,
            let dataPoints = dataSource.dataPoints, dataPoints.count > 0,
            let paths = dataSource.paths else {
                return
        }
        
        let isUpdating = chartLines != nil
        var newChartLines = isUpdating ? nil : [CAShapeLayer]()

        let range = 0..<dataSource.chartModels.count
        for standartIndex in range {
            var inverseIndex = range.endIndex - standartIndex - 1
            inverseIndex = dataSource.stacked ? inverseIndex : standartIndex
            
            let chartModel = dataSource.chartModels[inverseIndex]
            let lineLayer = isUpdating ? chartLines![standartIndex] : CAShapeLayer()
            let path = paths[inverseIndex]
            
            if isUpdating {
                lineLayer.path = path
                CATransaction.setDisableActions(true)
                if chartModel.opacity != lineLayer.opacity {
                    let toValue: Float = chartModel.opacity
                    let fromValue: Float = lineLayer.opacity
                    lineLayer.changeOpacity(from: fromValue, to: toValue,
                                            animationDuration: UIView.animationDuration)
                }
            } else {
                var fillColor = UIColor.clear
                if chartModel.drawingStyle.isCustomFillColor {
                    fillColor = chartModel.color
                }
                lineLayer.path = path
                lineLayer.opacity = chartModel.opacity
                lineLayer.strokeColor = chartModel.color.cgColor
                lineLayer.fillColor = fillColor.cgColor
                lineLayer.lineWidth = dataSource.isPreviewMode ? 1.0 : 2.0
                lineLayer.lineCap = chartModel.drawingStyle.lineCap
                lineLayer.lineJoin = chartModel.drawingStyle.lineJoin
                dataLayer.addSublayer(lineLayer)

                newChartLines!.append(lineLayer)
            }
        }
        
        if !isUpdating {
            chartLines = newChartLines
        }
    }
    
    func drawLabels(byScroll: Bool) {
        
        // return
        guard let dataSource = dataSource,
            dataSource.chartModels.count > 0,
            !dataSource.isPreviewMode, dataSource.maxRangePoints.count > 0 else {
            return
        }
        
        let isUpdating = labels != nil
        var newLabels = isUpdating ? nil : [TextLayer]()
        
        for index in 0..<dataSource.maxRangePoints.count {
            let textLayer = isUpdating ? labels![index] : TextLayer()
            
            let x = (CGFloat(index) - dataSource.range.start) * dataSource.lineGap - ChartContentView.labelWidth / 2
            
            // Changing only frame when is updating.
            CATransaction.setDisableActions(true)
            textLayer.frame = CGRect(x: x,
                                     y: mainLayer.frame.size.height - dataSource.bottomSpace / 2 - 4,
                                     width: ChartContentView.labelWidth,
                                     height: 16)
            if !isUpdating {
                textLayer.foregroundColor = colorScheme.chart.text.cgColor
                textLayer.backgroundColor = UIColor.clear.cgColor
                textLayer.alignmentMode = .center
                textLayer.contentsScale = UIScreen.main.scale
                textLayer.font = CTFontCreateWithName(UIFont.systemFont(ofSize: 0).fontName as CFString, 0, nil)
                textLayer.fontSize = 12
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

//        var labelProcessor = LabelsProcessor(dataSource: dataSource, isScrolling: isScrolling, sliderDirection: sliderDirection,
//                                             setFinishedSliderDirection: setFinishedSliderDirection, labels: labels, contentSize: frame.size)
//        labelProcessor.hideWrongLabelsUseSliderDirection(byScroll: byScroll)
        
        /*
            self.hideWrongLabelsUseSliderDirection(byScroll: byScroll)
            if self.setFinishedSliderDirection {
                self.sliderDirection = .finished
                self.hideWrongLabelsUseSliderDirection(byScroll: byScroll)
                self.setFinishedSliderDirection = false
            }
        }*/
    }
    
    
    func updateColors() {
        guard let dataSource = dataSource else {
            return
        }
        // TODO: here you should update colors.
        if let gridLines = gridLines {
            gridLines.forEach {
                
                let lineColor = $0.lineValue == 0 ? colorScheme.chart.accentGrid: colorScheme.chart.grid
                let textColor = dataSource.yScaled ? nil : colorScheme.chart.text
                $0.updateColors(lineColor: lineColor,
                                background: colorScheme.chart.background,
                                textColor: textColor)
            }
        }
        if let labels = labels {
            labels.forEach {
                $0.foregroundColor = colorScheme.chart.text.cgColor
            }
        }
        if dataSource.selectedIndex != nil {
            drawDots()
        }
    }
    
    func drawHorizontalLines(animated: Bool) {
        
        guard let dataSource = dataSource,
            !dataSource.isPreviewMode else {
                return
        }

        gridLinesToRemove?.forEach { $0.removeFromSuperlayer() }
        var newGridLines = [ValueLayer]()
        var newGridLinesToRemove = [ValueLayer]()

        for i in 0..<dataSource.maxValues.count {
            
            let maxValue = dataSource.maxValues[i]
            let newMaxValue = dataSource.targetMaxValues[i]
            
            let minMaxGap = CGFloat(maxValue - dataSource.minValue) * dataSource.topHorizontalLine
            let newMinMaxGap = CGFloat(newMaxValue - dataSource.minValue) * dataSource.topHorizontalLine
            
            let heightGrid: CGFloat = 30
            let widthGrid: CGFloat = self.frame.size.width
            let isUpdating = self.gridLines != nil
            
            let gridValues: [CGFloat] = dataSource.percentage ? [0.0, 0.25, 0.5, 0.75, 1] : [0.0, 0.2, 0.4, 0.6, 0.8, 1]
            for index in 0..<gridValues.count {
                
                let value = gridValues[index]
                var duration: CFTimeInterval = 0
                if animated {
                    duration = value == 1 ? 0 : UIView.animationDuration
                }
                
                let lineValue = dataSource.calcLineValue(for: value, with: minMaxGap)
                let newLineValue = dataSource.calcLineValue(for: value, with: newMinMaxGap)
                
                let indexOldValue = index + i * gridValues.count
                var oldValueLayer: ValueLayer? = nil
                if isUpdating {
                    if indexOldValue < gridLines!.count {
                        oldValueLayer = gridLines![indexOldValue]
                    }
                }
                
                let newValueLayer = ValueLayer()
                newValueLayer.alignment = i == 0 ? .left : .right
                newValueLayer.contentBackground = colorScheme.chart.background
                
                let fromNewHeight = dataSource.calcHeight(for: newLineValue, with: minMaxGap)
                let fromNewFrame = CGRect(x: 0, y: fromNewHeight, width: frame.size.width, height: heightGrid)
                let toNewHeight = dataSource.calcHeight(for: newLineValue, with: newMinMaxGap) + heightGrid / 2
                var toNewPoint = CGPoint(x: widthGrid / 2, y: toNewHeight)
                newValueLayer.lineColor = index == gridValues.count - 1 ? colorScheme.chart.accentGrid : colorScheme.chart.grid
                newValueLayer.textColor = dataSource.yScaled ? dataSource.chartModels[i].color : colorScheme.chart.text

                // Correct last and first lines.
                var onePixel: CGFloat = 0
                if index == 0 { onePixel = -1 }
                if index == gridValues.count - 1 { onePixel = 1 }
                toNewPoint = CGPoint(x: toNewPoint.x, y: toNewPoint.y + onePixel)
                
                if newLineValue == 0 {
                    let isHidden = dataSource.yScaled ? dataSource.chartModels[i].isHidden : dataSource.isAllChartsHidden
                    if index == gridValues.count - 1, !isHidden {
                        // Add zero line only if a chart is showing.
                        gridLayer.addSublayer(newValueLayer)
                    }
                } else {
                    gridLayer.addSublayer(newValueLayer)
                }
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
                    let rect = CGRect(x: 0, y: height + onePixel, width: frame.size.width, height: heightGrid)
                    newValueLayer.frame = rect
                }
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
        
        // TODO: Текушие значения не правильно отображаются
        let newSelectedIndex = Int(location.x / dataSource.lineGap)
        // let newGlobalSelectedIndex = Int((location.x + dataSource.range.start * dataSource.lineGap) / dataSource.lineGap)
        let newGlobalSelectedIndex = newSelectedIndex + Int(dataSource.range.start)
        var isUpdating = dataSource.selectedIndex == nil
        if let selectedIndex = dataSource.selectedIndex,
            selectedIndex != newSelectedIndex {
            isUpdating = true
        }
        if isUpdating {
            dataSource.selectedIndex = newSelectedIndex
            dataSource.globalSelectedIndex = newGlobalSelectedIndex
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
            let selectedIndex = dataSource.selectedIndex,
            let globalSelectedIndex = dataSource.globalSelectedIndex else {
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
            gridLayer.addSublayer(lineLayer)
        }
        
        // Dots.
        var xLine: CGFloat = 0
        var dotIndex = 0
        for index in 0..<dataSource.chartModels.count {
            let chartModel = dataSource.chartModels[index]
            if chartModel.isHidden { continue }
            
            var points = dataPoints[index]
            
            let dataPoint = points[selectedIndex]
//            let xValue = (CGFloat(selectedIndex) - dataSource.range.start) * dataSource.lineGap - outerRadius / 2
            let xValue = CGFloat(selectedIndex) * dataSource.lineGap - outerRadius / 2
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
                gridLayer.addSublayer(dotLayer)
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
        let theOnePixel: CGFloat = 1 // from drawing horizontal lines
        path.addLine(to: CGPoint(x: xLine, y: self.frame.size.height - dataSource.topSpace - dataSource.bottomSpace + theOnePixel))
        lineLayer.path = path.cgPath
        lineLayer.strokeColor = colorScheme.chart.accentGrid.cgColor
        if !isUpdating {
            self.verticalLine = lineLayer
        }

        // Rect.
        var rectWidth: CGFloat = 80
        var maxString = ""
        for chartModel in visibleChartModels {
            let data = chartModel.data[globalSelectedIndex]
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
            gridLayer.addSublayer(dotInfo)
            self.dotInfo = dotInfo
        }

        // Date and numbers.
        var drawDate = true
        let xdata: CGFloat = rect.origin.x + 8 + 80 * 0.6
        var ydata: CGFloat = rect.origin.y + 5
        let deltaY = oneLine - 3
        for index in 0..<visibleChartModels.count {
            let chartModel = visibleChartModels[index]
            let data = chartModel.data[globalSelectedIndex]
            if drawDate {
                let ydate = rect.origin.y + 5
                let isUpdating = self.dateTextLayer != nil
                let dateFrame = CGRect(x: rect.origin.x + 8,
                                       y: ydate, width: 50, height: 16)
                if isUpdating {
                    self.dateTextLayer?.frame = dateFrame
                    self.dateTextLayer?.string = data.dateDot
                    self.dateTextLayer?.foregroundColor = colorScheme.dotInfo.text.cgColor
                } else {
                    let dateTextLayer = Painter.createText(textColor: colorScheme.dotInfo.text, bold: true)
                    dateTextLayer.frame = dateFrame
                    dateTextLayer.string = data.dateDot
                    gridLayer.addSublayer(dateTextLayer)
                    self.dateTextLayer = dateTextLayer
                }

                let yearFrame = CGRect(x: rect.origin.x + 8,
                                       y: ydate + deltaY, width: 50, height: 16)
                if isUpdating {
                    self.yearTextLayer?.frame = yearFrame
                    self.yearTextLayer?.string = data.year
                    self.yearTextLayer?.foregroundColor = colorScheme.dotInfo.text.cgColor
                } else {
                    let yaerTextLayer = Painter.createText(textColor: colorScheme.dotInfo.text)
                    yaerTextLayer.frame = yearFrame
                        yaerTextLayer.string = data.year
                    gridLayer.addSublayer(yaerTextLayer)
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
                gridLayer.addSublayer(dataTextLayer)
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
