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
            if isPreviewMode {
                shadowImage.removeFromSuperview()
            }
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

    private let selectedValuesLayer: CALayer = CALayer()

    private var chartLines: [String: ChartLayer] = [:]

    private var gridLines: [String: [ValueLayer]] = [:]
    
    private var gridLinesToRemove: [String: [ValueLayer]] = [:]

    private var labels: [TextLayer]?
    
    private var innerRadius: CGFloat = 4
    
    private var outerRadius: CGFloat = 8
    
    private var verticalLine: CAShapeLayer?

    private var selectedValuesInfo: CAShapeLayer?
    
    private var dateTextLayer: BgTextLayer?

    private var valueTextLayers: [BgTextLayer]?

    private var precentegTextLayers: [BgTextLayer]?

    private var labelsTextLayers: [BgTextLayer]?

    private var dotsTextLayers: [DotLayer]?
    
    private var shadowImage = UIImageView(frame: .zero)

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
        self.backgroundColor = .clear

        mainLayer.addSublayer(dataLayer)
        layer.addSublayer(mainLayer)
        layer.addSublayer(gridLayer)
        layer.addSublayer(selectedValuesLayer)
        //addSubview(shadowImage) // TODO
                
        updateFrameShadow()
        
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
        guard let dataSource = dataSource else {
            return true
        }
        if !dataSource.isPreviewMode,
            let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = panGestureRecognizer.velocity(in: self)
            return abs(velocity.y) > abs(velocity.x)
        }
        return true
    }
    
    @objc private func handleTouch(recognizer: UIPanGestureRecognizer) {
        guard let dataSource = dataSource else {
            return
        }
        
        let location = recognizer.location(in: self)
        if let selectedValuesInfo = selectedValuesInfo {
            let frame = CGRect(x: selectedValuesInfo.frame.origin.x,
                               y: selectedValuesInfo.frame.origin.y + dataSource.topSpace,
                               width: selectedValuesInfo.frame.width,
                               height: selectedValuesInfo.frame.height)
            if location.x >= frame.origin.x, location.x <= frame.origin.x + frame.size.width,
                location.y >= frame.origin.y, location.y <= frame.origin.y + frame.size.height {
                dataSource.selectedIndex = nil
                cleanSelectedValues()
                return
            }
        }
        drawSelectedValuesIfNeeded(location: location, animated: true)
    }

    @objc private func handlePan(recognizer: UIPanGestureRecognizer) {
        guard !isScrolling else {
            return
        }
        
        let location = recognizer.location(in: self)
        drawSelectedValuesIfNeeded(location: location, animated: true)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let dataSource = dataSource else {
            return
        }

        let width = CGFloat(dataSource.countPoints) * dataSource.lineGap
        let height = self.frame.size.height
        self.mainLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
        self.dataLayer.frame = CGRect(x: 0, y: dataSource.topSpace,
                                      width: self.mainLayer.frame.width,
                                      height: self.mainLayer.frame.height - dataSource.topSpace - dataSource.bottomSpace)
        
        self.gridLayer.frame = CGRect(x: 0, y: dataSource.topSpace,
                                      width: self.frame.width,
                                      height: self.mainLayer.frame.height - dataSource.topSpace - dataSource.bottomSpace)
        self.selectedValuesLayer.frame = self.gridLayer.frame
    }
    
    func drawView() {
        
        guard let dataSource = dataSource,
            let dataPoints = dataSource.dataPoints, dataPoints.count > 0 else {
            return
        }

        if isJustReused {
            drawHorizontalLines(animated: false)
        }
        self.drawCharts()
        
        if !isScrolling {
            drawLabels(byScroll: false)
        }
        
        if isJustReused {
            isJustReused = false
        }
    }
    
    func drawCharts() {

        guard let dataSource = dataSource,
            let dataPoints = dataSource.dataPoints, dataPoints.count > 0 else {
                return
        }
        
        if isJustReused {
            // Hiding all charts when it is reusing.
            for (_, chartLayer) in chartLines{
                chartLayer.opacity = 0
            }
        }
        
        let range = 0..<dataSource.chartModels.count
        for standartIndex in range {
            var inverseIndex = range.endIndex - standartIndex - 1
            inverseIndex = dataSource.stacked ? inverseIndex : standartIndex
            
            let chartModel = dataSource.chartModels[inverseIndex]
            let key = dataSource.uniqueId + chartModel.name
            if isJustReused {
                chartLines[key]?.opacity = 1
                continue
            }
            
            let path = dataSource.paths[key]

            if let chartLayer = chartLines[key] {
                chartLayer.path = path
                CATransaction.setDisableActions(true)
                if chartModel.opacity != chartLayer.opacity {
                    let toValue: Float = chartModel.opacity
                    let fromValue: Float = chartLayer.opacity
                    chartLayer.changeOpacity(from: fromValue, to: toValue,
                                            animationDuration: UIView.animationDuration)
                }
                
            } else {
                let chartLayer = ChartLayer()
                var fillColor = UIColor.clear
                if chartModel.drawingStyle.isCustomFillColor {
                    fillColor = chartModel.color
                }
                chartLayer.path = path
                chartLayer.opacity = chartModel.opacity
                chartLayer.strokeColor = chartModel.color.cgColor
                chartLayer.fillColor = fillColor.cgColor
                if dataSource.stacked || dataSource.singleBar {
                    chartLayer.lineWidth = 0
                } else {
                    chartLayer.lineWidth = dataSource.isPreviewMode ? 1.0 : 2.0
                }
                chartLayer.lineCap = chartModel.drawingStyle.lineCap
                chartLayer.lineJoin = chartModel.drawingStyle.lineJoin
                dataLayer.addSublayer(chartLayer)
                
                chartLines[key] = chartLayer
            }

        }
    }
    
    func drawHorizontalLines(animated: Bool) {

        guard let dataSource = dataSource,
            !dataSource.isPreviewMode else {
                return
        }
        
        if isJustReused {
            // Hiding all charts when it is reusing.
            for (_, layers) in gridLinesToRemove {
                layers.forEach { $0.opacity = 0 }
            }
            for (_, layers) in gridLines {
                layers.forEach { $0.opacity = 0}
            }
        }

        // Creating ValueLayer for reusing.
        for i in 0..<dataSource.maxValues.count {
            let chartModel = dataSource.chartModels[i]
            let key = dataSource.uniqueId + chartModel.name
            if gridLines[key] == nil, gridLinesToRemove[key] == nil {
                
                var newGridLines = [ValueLayer]()
                var newGridLinesToRemove = [ValueLayer]()
                
                let gridValues: [CGFloat] = dataSource.percentage ? [0.0, 0.25, 0.5, 0.75, 1] : [0.0, 0.2, 0.4, 0.6, 0.8, 1]
                gridValues.forEach { _ in
                    let newValueLayer = ValueLayer()
                    newValueLayer.opacity = 1
                    gridLayer.addSublayer(newValueLayer)
                    newGridLines.append(newValueLayer)
                    
                    let oldValueLayer = ValueLayer()
                    oldValueLayer.opacity = 0
                    gridLayer.addSublayer(oldValueLayer)
                    newGridLinesToRemove.append(oldValueLayer)
                }
                
                gridLines[key] = newGridLines
                gridLinesToRemove[key] = newGridLinesToRemove
            }
        }
        
        for i in 0..<dataSource.maxValues.count {
            let chartModel = dataSource.chartModels[i]
            let key = dataSource.uniqueId + chartModel.name
            
            if isJustReused {
                gridLines[key]?.forEach {
                    $0.opacity = 1
                }
                continue
            }
            
            let maxValue = dataSource.maxValues[i]
            let newMaxValue = dataSource.targetMaxValues[i]
            
            let minMaxGap = CGFloat(maxValue - dataSource.minValue) * dataSource.topHorizontalLine
            let newMinMaxGap = CGFloat(newMaxValue - dataSource.minValue) * dataSource.topHorizontalLine
            
            let heightGrid: CGFloat = 1
            let widthGrid: CGFloat = self.frame.size.width
            
            var newGridLines = [ValueLayer]()
            var newGridLinesToRemove = [ValueLayer]()
            
            let gridValues: [CGFloat] = dataSource.percentage ? [0.0, 0.25, 0.5, 0.75, 1] : [0.0, 0.2, 0.4, 0.6, 0.8, 1]
            for index in 0..<gridValues.count {
                
                let value = gridValues[index]
                var duration: CFTimeInterval = 0
                if animated {
                    duration = value == 1 ? 0 : UIView.animationDuration
                }
                let lineValue = dataSource.calcLineValue(for: value, with: minMaxGap)
                let newLineValue = dataSource.calcLineValue(for: value, with: newMinMaxGap)
                
                let isZeroLine = index == gridValues.count - 1
                let newValueLayer = gridLinesToRemove[key]![index]
                let oldValueLayer = gridLines[key]![index]

                newValueLayer.fixedTextColor = dataSource.yScaled
                newValueLayer.alignment = i == 0 ? .left : .right
                newValueLayer.contentBackground = colorScheme.chart.background
                
                let fromNewHeight = dataSource.calcHeight(for: newLineValue, with: minMaxGap)
                let fromNewFrame = CGRect(x: dataSource.trailingSpace, y: fromNewHeight, width: frame.size.width - dataSource.trailingSpace - dataSource.leadingSpace, height: heightGrid)
                let toNewHeight = dataSource.calcHeight(for: newLineValue, with: newMinMaxGap) + heightGrid / 2
                let toNewPoint = CGPoint(x: widthGrid / 2, y: toNewHeight)
                newValueLayer.lineColor = isZeroLine ? colorScheme.chart.accentGrid : colorScheme.chart.grid
                newValueLayer.textColor = dataSource.yScaled ? chartModel.color : colorScheme.chart.text
                
                /* TODO: Fix a bug with zero line.
                var newValueFromOpacity: Float = 0
                var newValueToOpacity: Float = 1
                if newLineValue == 0 {
                    let isHidden = dataSource.yScaled ? chartModel.isHidden : dataSource.isAllChartsHidden
                    if isZeroLine, !isHidden {
                        // Add zero line only if a chart is showing.
                        // gridLayer.addSublayer(newValueLayer)
                    } else {
                    
                        newValueFromOpacity = 1
                        newValueToOpacity = 0
                    }
                } else {
                    // gridLayer.addSublayer(newValueLayer)
                    //newValueLayer.opacity = 1
                }*/
                
                let toHeight = dataSource.calcHeight(for: lineValue, with: newMinMaxGap) + heightGrid / 2
                let toPoint = CGPoint(x: widthGrid / 2, y: toHeight)
                CATransaction.setDisableActions(true)
                oldValueLayer.moveTo(point: toPoint, animationDuration: duration)
                oldValueLayer.changeOpacity(from: 1, to: 0, animationDuration: duration)
                
                newValueLayer.lineValue = newLineValue
                newValueLayer.opacity = 0
                newValueLayer.frame = fromNewFrame
                newValueLayer.moveTo(point: toNewPoint, animationDuration: duration)
                newValueLayer.changeOpacity(from: 0, to: 1, animationDuration: duration)

                newGridLinesToRemove.append(oldValueLayer)
                newGridLines.append(newValueLayer)
            }
            
            gridLines[key] = newGridLines
            gridLinesToRemove[key] = newGridLinesToRemove
        }
    }
    
    func drawLabels(byScroll: Bool) {
        
        return
        
        guard let dataSource = dataSource,
            dataSource.chartModels.count > 0,
            !dataSource.isPreviewMode, dataSource.maxRangePoints.count > 0 else {
            return
        }
        
        let isUpdating = labels != nil
        var newLabels = isUpdating ? nil : [TextLayer]()
        
        for index in 0..<dataSource.maxRangePoints.count {
            let textLayer = isUpdating ? labels![index] : TextLayer()
            
            let x = dataSource.trailingSpace + (CGFloat(index) - dataSource.range.lowerBound) * dataSource.lineGap - ChartContentView.labelWidth / 2
            
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
                textLayer.string = DateCache.shared.shortFormat(for: dataSource.maxRangePoints[index].date)
                textLayer.opacity = 0
                textLayer.toOpacity = 0
                mainLayer.addSublayer(textLayer)
                newLabels!.append(textLayer)
            }
        }

        if !isUpdating {
            labels = newLabels
        }

        var labelProcessor = LabelsProcessor(dataSource: dataSource, isScrolling: isScrolling, sliderDirection: sliderDirection,
                                             setFinishedSliderDirection: setFinishedSliderDirection, labels: labels, contentSize: frame.size)
        labelProcessor.hideWrongLabelsUseSliderDirection(byScroll: byScroll)
        
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
        for (_, layers) in gridLines {
            layers.forEach {
                let lineColor = $0.lineValue == 0 ? colorScheme.chart.accentGrid: colorScheme.chart.grid
                $0.updateColors(lineColor: lineColor,
                                background: colorScheme.chart.background,
                                textColor: colorScheme.chart.text)
            }
        }

        if let labels = labels {
            labels.forEach {
                $0.foregroundColor = colorScheme.chart.text.cgColor
            }
        }
        if dataSource.selectedIndex != nil {
            drawSelectedValues(animated: false)
        }
        
        if !dataSource.isPreviewMode {
            self.shadowImage.image = UIImage(size: self.shadowImage.frame.size, gradientColor: [colorScheme.chart.background, colorScheme.chart.background.withAlphaComponent(0)])
        }
    }
    
    private func drawSelectedValuesIfNeeded(location: CGPoint, animated: Bool) {
        guard let dataSource = dataSource,
            let dataPoints = dataSource.dataPoints, dataPoints.count > 0,
            !dataSource.isPreviewMode else {
                return
        }
        guard location.x >= 0, location.x <= frame.size.width else {
            return
        }
        
        var newSelectedIndex = Int((location.x - dataSource.deltaX) / dataSource.lineGap)
        if newSelectedIndex < 0 {
            newSelectedIndex = 0
        }
        if newSelectedIndex >= dataSource.maxRangePoints.count {
            newSelectedIndex = dataSource.maxRangePoints.count - 1
        }
        let newGlobalSelectedIndex = newSelectedIndex + dataSource.intRange.startIndex
        var isUpdating = dataSource.selectedIndex == nil
        if let selectedIndex = dataSource.selectedIndex,
            selectedIndex != newSelectedIndex {
            isUpdating = true
        }
        if isUpdating {
            dataSource.selectedIndex = newSelectedIndex
            dataSource.globalSelectedIndex = newGlobalSelectedIndex
            drawSelectedValues(animated: animated)
        }
    }
    
    func cleanSelectedValues() {
        verticalLine?.removeFromSuperlayer()
        selectedValuesInfo?.removeFromSuperlayer()
        dateTextLayer?.removeFromSuperlayer()
        valueTextLayers?.forEach { $0.removeFromSuperlayer() }
        labelsTextLayers?.forEach { $0.removeFromSuperlayer() }
        precentegTextLayers?.forEach { $0.removeFromSuperlayer() }
        dotsTextLayers?.forEach { $0.removeFromSuperlayer() }
        
        selectedValuesInfo = nil
        verticalLine = nil
        dateTextLayer = nil
        valueTextLayers = nil
        precentegTextLayers = nil
        labelsTextLayers = nil
        dotsTextLayers = nil

        selectedValuesLayer.sublayers?.forEach {
            $0.removeFromSuperlayer()
        }
        dataLayer.sublayers?.forEach {
            if $0 is DotLayer {
                $0.removeFromSuperlayer()
            }
        }
    }

    func drawSelectedValues(animated: Bool) {
        return
        guard let dataSource = dataSource,
            let dataPoints = dataSource.dataPoints, dataPoints.count > 0,
            !dataSource.isPreviewMode,
            let selectedIndex = dataSource.selectedIndex,
            let globalSelectedIndex = dataSource.globalSelectedIndex else {
            return
        }

        // Preparing some data.
        var countVisibleValues = 1 // for date
        var totalValue = 0
        let hasAdditionalRow = dataSource.stacked && !dataSource.singleBar && !dataSource.percentage
        if hasAdditionalRow {
            countVisibleValues += 1
        }
        var lastVisibleIndex = 0
        for index in 0..<dataSource.chartModels.count {
            let chartModel = dataSource.chartModels[index]
            let pointModel = chartModel.data[globalSelectedIndex]
            if !chartModel.isHidden {
                countVisibleValues += 1
                totalValue += pointModel.value
                lastVisibleIndex = index
            }
        }
        var percentageValues: [Int] = []
        var totalPercentage = 100
        var maxPercentageWidth: CGFloat = 0
        if dataSource.percentage {
            percentageValues = []
            for index in 0..<dataSource.chartModels.count {
                if totalValue == 0 {
                    percentageValues.append(0)
                    continue
                }
                let chartModel = dataSource.chartModels[index]
                let pointModel = chartModel.data[globalSelectedIndex]
                if index == lastVisibleIndex {
                    percentageValues.append(totalPercentage)
                } else {
                    let value = chartModel.isHidden ? 0 : pointModel.value
                    let percentageValue = Int(CGFloat(value) * CGFloat(100) / CGFloat(totalValue))
                    percentageValues.append(percentageValue)
                    totalPercentage -= percentageValue
                }
                if !chartModel.isHidden {
                    let percentageTextLayer = Painter.createText(textColor: self.colorScheme.dotInfo.text)
                    percentageTextLayer.string = "\(percentageValues[index])%"
                    let percentageWidth = percentageTextLayer.preferredFrameSize().width
                    if percentageWidth > maxPercentageWidth {
                        maxPercentageWidth = percentageWidth
                    }
                }
            }
        }

        let xValue = dataSource.deltaX + CGFloat(selectedIndex) * dataSource.lineGap - outerRadius / 2
        let xLine = xValue + outerRadius / 2

        // Line.
        var topLine = -dataSource.topSpace + 12
        if dataSource.percentage {
            topLine = 0
        }

        let needsDrawLine = dataSource.percentage || (!dataSource.singleBar && !dataSource.stacked)
        if needsDrawLine {
            let path = UIBezierPath()
            let isUpdating = verticalLine != nil
            let lineLayer = isUpdating ? verticalLine! : CAShapeLayer()
            if !isUpdating {
                lineLayer.fillColor = UIColor.clear.cgColor
                lineLayer.lineWidth = 0.5
                selectedValuesLayer.addSublayer(lineLayer)
            }
            path.move(to: CGPoint(x: xLine, y: topLine))
            path.addLine(to: CGPoint(x: xLine, y: self.frame.size.height - dataSource.topSpace - dataSource.bottomSpace))
            lineLayer.path = path.cgPath
            lineLayer.strokeColor = colorScheme.chart.accentGrid.cgColor
            if !isUpdating {
                self.verticalLine = lineLayer
            }
        }

        // Dots.
        var dotIndex = 0
        if !dataSource.stacked, !dataSource.singleBar {
            for index in 0..<dataSource.chartModels.count {
                let chartModel = dataSource.chartModels[index]
                var points = dataPoints[index]
                
                let dataPoint = points[selectedIndex]
                let yValue = dataPoint.y - outerRadius / 2
                let dotFrame = CGRect(x: xValue, y: yValue, width: outerRadius, height: outerRadius)
                
                if let dotsTextLayers = dotsTextLayers, dotIndex < dotsTextLayers.count {
                    dotsTextLayers[dotIndex].dotInnerColor = colorScheme.chart.background
                    dotsTextLayers[dotIndex].backgroundColor = chartModel.color.cgColor
                    dotsTextLayers[dotIndex].frame = dotFrame
                    dotsTextLayers[dotIndex].isHidden = chartModel.isHidden
                } else {
                    let dotLayer = DotLayer()
                    dotLayer.dotInnerColor = colorScheme.chart.background
                    dotLayer.innerRadius = innerRadius
                    dotLayer.backgroundColor = chartModel.color.cgColor
                    dotLayer.cornerRadius = outerRadius / 2
                    dotLayer.frame = dotFrame
                    selectedValuesLayer.addSublayer(dotLayer)
                    if dotsTextLayers == nil {
                        dotsTextLayers = [DotLayer]()
                    }
                    dotsTextLayers!.append(dotLayer)
                    dotLayer.isHidden = chartModel.isHidden
                }
                
                dotIndex += 1
            }
        }
        
        // View with values.
        let topDate: CGFloat = 5
        let trailingDate: CGFloat = 10
        let pointModel = dataSource.maxRangePoints[globalSelectedIndex]
        let dateTextLayer = Painter.createText(textColor: colorScheme.dotInfo.text, bold: true)
        dateTextLayer.string = DateCache.shared.fullFormat(for: pointModel.date)
        let rectWidth: CGFloat = 145

        let isUpdating = selectedValuesInfo != nil
        let textLayer = Painter.createText(textColor: .clear)
        textLayer.string = "0"
        let heightForOneLine: CGFloat = textLayer.preferredFrameSize().height
        
        var xRect = xLine - rectWidth / 2
        if xRect < 0 {
            xRect = xLine + dataSource.trailingSpace
        }
        if xRect > self.frame.size.width - rectWidth {
            xRect = xLine - rectWidth - dataSource.trailingSpace
        }

        if !animated {
            CATransaction.setDisableActions(true)
        }

        let letterSpace: CGFloat = 2
        let extraBottom: CGFloat = 3
        var heightRect = heightForOneLine * CGFloat(countVisibleValues) + 2 * topDate + extraBottom
        heightRect += CGFloat(countVisibleValues - 1) * letterSpace
        let extraTop: CGFloat = dataSource.percentage ? 4 : 0
        let rect = CGRect(x: xRect, y: topLine + extraTop,
                          width: rectWidth, height: heightRect)
        let corners: UIRectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
        
        if isUpdating {
            self.selectedValuesInfo?.path = Painter.createRectPath(rect: CGRect(x: 0, y: 0, width: rect.width, height: rect.height), byRoundingCorners: corners, cornerRadius: 6).cgPath
            self.selectedValuesInfo?.fillColor = colorScheme.dotInfo.background.cgColor
            self.selectedValuesInfo?.frame = rect
        } else {
            let dotInfo = Painter.createRect(rect: CGRect(x: 0, y: 0, width: rect.width, height: rect.height), byRoundingCorners: corners,
                                             fillColor: colorScheme.dotInfo.background,
                                             cornerRadius: 6)
            selectedValuesLayer.addSublayer(dotInfo)
            dotInfo.frame = rect
            self.selectedValuesInfo = dotInfo
        }

        // Date, labels and values.
        var drawDate = true
        var ydata: CGFloat = rect.origin.y + topDate
        let deltaY = heightForOneLine + letterSpace
        let drawLabledValue: (Int, String, Int, Bool, UIColor) -> () = { index, name, value, isHidden, valueColor in
            
            // Percentage.
            if dataSource.percentage, index < percentageValues.count {
                let updatePercentageTextLayer: (BgTextLayer) -> Void = { textLayer in
                    textLayer.string = "\(percentageValues[index])%"
                    textLayer.isHidden = isHidden
                    let x = rect.origin.x + trailingDate + maxPercentageWidth - textLayer.preferredFrameSize().width
                    let valueFrame = CGRect(x: x, y: ydata, width: maxPercentageWidth, height: 16)
                    textLayer.frame = valueFrame
                    textLayer.foregroundColor = self.colorScheme.dotInfo.text.cgColor
                }
                if let precentegTextLayers = self.precentegTextLayers, index < precentegTextLayers.count {
                    let percentageTextLayer = precentegTextLayers[index]
                    updatePercentageTextLayer(percentageTextLayer)
                } else {
                    let percentageTextLayer = Painter.createText(textColor: self.colorScheme.dotInfo.text)
                    updatePercentageTextLayer(percentageTextLayer)
                    self.selectedValuesLayer.addSublayer(percentageTextLayer)
                    if self.precentegTextLayers == nil {
                        self.precentegTextLayers = [BgTextLayer]()
                    }
                    self.precentegTextLayers!.append(percentageTextLayer)
                }
            }
            
            // Labels.
            let updateLabelTextLayer: (BgTextLayer) -> Void = { textLayer in
                textLayer.string = name
                textLayer.isHidden = isHidden
                let space: CGFloat = 5
                let trailing: CGFloat = self.dataSource?.percentage ?? false ? maxPercentageWidth + space : 0
                let x = trailing + rect.origin.x + trailingDate
                let valueFrame = CGRect(x: x, y: ydata, width: 60, height: 16)
                textLayer.frame = valueFrame
                textLayer.foregroundColor = self.colorScheme.dotInfo.text.cgColor
            }
            if let labelsTextLayers = self.labelsTextLayers, index < labelsTextLayers.count {
                let labelTextLayer = labelsTextLayers[index]
                updateLabelTextLayer(labelTextLayer)
            } else {
                let labelTextLayer = Painter.createText(textColor: self.colorScheme.dotInfo.text)
                updateLabelTextLayer(labelTextLayer)
                self.selectedValuesLayer.addSublayer(labelTextLayer)
                if self.labelsTextLayers == nil {
                    self.labelsTextLayers = [BgTextLayer]()
                }
                self.labelsTextLayers!.append(labelTextLayer)
            }
            
            // Values.
            let updateDataTextLayer: (BgTextLayer) -> Void = { textLayer in
                textLayer.string = value.format
                textLayer.isHidden = isHidden
                let x = rect.origin.x + rectWidth - trailingDate - textLayer.preferredFrameSize().width
                let valueFrame = CGRect(x: x, y: ydata, width: 50, height: 16)
                textLayer.frame = valueFrame
            }
            if let valueTextLayers = self.valueTextLayers, index < valueTextLayers.count {
                let dataTextLayer = valueTextLayers[index]
                dataTextLayer.foregroundColor = valueColor.cgColor
                updateDataTextLayer(dataTextLayer)
            } else {
                let dataTextLayer = Painter.createText(textColor: valueColor, bold: true)
                updateDataTextLayer(dataTextLayer)
                self.selectedValuesLayer.addSublayer(dataTextLayer)
                if self.valueTextLayers == nil {
                    self.valueTextLayers = [BgTextLayer]()
                }
                self.valueTextLayers!.append(dataTextLayer)
            }
            
        }
        
        for index in 0..<dataSource.chartModels.count {
            let chartModel = dataSource.chartModels[index]
            let pointModel = chartModel.data[globalSelectedIndex]
            if drawDate {
                let ydate = rect.origin.y + topDate
                let isUpdating = self.dateTextLayer != nil
                let dateFrame = CGRect(x: rect.origin.x + trailingDate,
                                       y: ydate, width: rectWidth - 2 * trailingDate, height: 16)
                let updateDateTextLayer: (BgTextLayer?) -> Void = { textLayer in
                    textLayer?.frame = dateFrame
                    textLayer?.string = DateCache.shared.fullFormat(for: pointModel.date)
                    textLayer?.foregroundColor = self.colorScheme.dotInfo.text.cgColor
                }
                if isUpdating {
                    updateDateTextLayer(self.dateTextLayer)
                } else {
                    let dateTextLayer = Painter.createText(textColor: colorScheme.dotInfo.text, bold: true)
                    updateDateTextLayer(dateTextLayer)
                    selectedValuesLayer.addSublayer(dateTextLayer)
                    self.dateTextLayer = dateTextLayer
                }
                ydata += deltaY
                drawDate = false
            }
            
            drawLabledValue(index, chartModel.name, pointModel.value, chartModel.isHidden, chartModel.color)

            if !chartModel.isHidden {
                ydata += deltaY
            }
        }
        
        drawLabledValue(dataSource.chartModels.count, "All", totalValue, !hasAdditionalRow, self.colorScheme.dotInfo.text)
        
        if !animated {
            CATransaction.setDisableActions(false)
        }
    }
    
    func prepareForReuse() {
        labels = nil
        dataSource = nil
        isJustReused = true

        sliderDirection = .right
        setFinishedSliderDirection = true
        isScrolling = true

        valueTextLayers = nil
        labelsTextLayers = nil

        mainLayer.sublayers?.forEach { //
            if $0 is TextLayer {
                $0.removeFromSuperlayer()
            }
        }

        cleanSelectedValues()
    }
    
    func updateFrameShadow() {
        let shadowFrame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: 20)
        self.shadowImage.frame = shadowFrame
    }
}
