//
//  ChartDataSource.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/23/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class СoupleChartDataSource {
    var main: [ChartDataSource]
    var preview: [ChartDataSource]
    
    init(main: [ChartDataSource], preview: [ChartDataSource]) {
        self.main = main
        self.preview = preview
    }
} 

class ChartDataSource: Updatable {
    
    var range = IndexRange(start: CGFloat(0.0), end: CGFloat(2.0))
    
    var intRange: Range<Int> {
        let startIndex = max(Int(range.start) - 1, 0)
        let endIndex = min(Int(viewSize.width / lineGap + range.start) + 2, maxRangePoints.count)
        return startIndex..<endIndex
    }

    var sliderWidth: CGFloat = 0
    
    var startX: CGFloat = 0
    
    var viewSize: CGSize = .zero
    
    var chartModels: [ChartModel] {
        didSet {
            dataPoints = nil
            paths = nil
            findMaxRangePoints()
        }
    }
    
    var selectedIndex: Int?

    var globalSelectedIndex: Int?

    var onChangeMaxValue: (() ->())?
    
    var onSetNewTargetMaxValue: (() ->())?
    
    var name: String
    
    var isPreviewMode: Bool = false

    var isAllChartsHidden: Bool {
        var result = true
        chartModels.forEach { result = result && $0.isHidden }
        return result
    }

    private(set) var lineGap: CGFloat = 60.0
    
    private(set) var topSpace: CGFloat = 0.0
    
    private(set) var bottomSpace: CGFloat = 0.0
    
    private(set) var topHorizontalLine: CGFloat = 95.0 / 100.0
    
    private(set) var minValue: CGFloat = 0
    
    public var maxValues: [CGFloat] = []

    private(set) var targetMaxValues: [CGFloat] = []
    
    private(set) var deltaToTargetValues: [CGFloat] = []
    
    private(set) var frameAnimation: Int = 0
    
    private(set) var runMaxValueAnimation: Bool = false

    private(set) var countPoints: Int = 0
    
    private(set) var dataPoints: [[CGPoint]]?

    private(set) var paths: [CGPath]?
    
    private(set) var maxRangePoints: [PointModel] = []
    
    private var viewDataSize: CGSize = .zero

    private(set) var yScaled: Bool = false

    private(set) var stacked: Bool = false

    private(set) var singleBar: Bool = false

    private(set) var percentage: Bool = false

    public var framesInAnimationDuration: Int {
        return Int(CFTimeInterval(60) * UIView.animationDuration)
    }
    
    private var cachedPaths = [String : CGPath]()
    
    init(chartModels: [ChartModel], name: String) {
        self.name = name
        self.chartModels = chartModels
        
        chartModels.forEach {
            yScaled = $0.yScaled || yScaled
            stacked = $0.stacked || stacked
            singleBar = $0.singleBar || singleBar
            percentage = $0.percentage || percentage
        }
        
        let addZeroValue = {
            self.maxValues.append(0)
            self.targetMaxValues.append(0)
            self.deltaToTargetValues.append(0)
        }
        if yScaled {
            chartModels.forEach { _ in addZeroValue() }
        } else {
            addZeroValue()
        }
    }
    
    private func calcYScaledMaxValue(animateMaxValue value: Bool) {
        if isPreviewMode {
            // Individual maximum in full range.
            var newMaxValues = self.maxValues
            for index in 0..<chartModels.count {
                let chartModel = chartModels[index]
                if chartModel.isHidden {
                    newMaxValues[index] = 0
                } else {
                    newMaxValues[index] = CGFloat(chartModel.data.max()?.value ?? 0)
                }
            }
            setMaxValues(newMaxValues, animated: value)
        } else {
            // Individual maximum in specific range.
            var newMaxValues = self.maxValues
            let loopRange = intRange
            for index in 0..<chartModels.count {
                let chartModel = chartModels[index]
                if chartModel.isHidden {
                    newMaxValues[index] = 0
                } else {
                    var max: CGFloat = 0
                    for i in loopRange {
                        let x = (CGFloat(i) - range.start) * lineGap
                        if x >= 0, x <= viewSize.width {
                            let value = CGFloat(chartModel.data[i].value)
                            if value > max {
                                max = value
                            }
                        }
                    }
                    newMaxValues[index] = max
                }
            }
            setMaxValues(newMaxValues, animated: value)
        }
    }
    
    private func calcStandardMaxValue(animateMaxValue value: Bool) {
        if isPreviewMode {
            // One maximum in full range.
            let max: CGFloat = chartModels.map { chartModel in
                if chartModel.isHidden {
                    return 0
                } else {
                    return CGFloat(chartModel.data.max()?.value ?? 0)
                }}.compactMap { $0 }.max() ?? 0
            setMaxValues([max], animated: value)
        } else {
            // One maximum in specific range.
            var max: CGFloat = 0
            let loopRange = intRange
            for chartModel in chartModels {
                if chartModel.isHidden { continue }
                for i in loopRange {
                    let x = (CGFloat(i) - range.start) * lineGap
                    if x >= 0, x <= viewSize.width {
                        let value = CGFloat(chartModel.data[i].value)
                        if value > max {
                            max = value
                        }
                    }
                }
            }
            setMaxValues([max], animated: value)
        }
    }
    
    private func calcStackedMaxValue(animateMaxValue value: Bool) {
        if isPreviewMode {
            // Sum all maximums in full range.
            var sumMax: CGFloat = 0
            for i in 0..<maxRangePoints.count {
                var value: Int = 0
                for chartModel in chartModels {
                    if chartModel.isHidden {
                        continue
                    }
                    value += chartModel.data[i].value
                }
                sumMax = max(sumMax, CGFloat(value))
            }
            setMaxValues([sumMax], animated: value)
        } else {
            // Sum all maximums in specific range.
            var sumMax: CGFloat = 0
            let loopRange = intRange
            for i in loopRange {
                var value: Int = 0
                for chartModel in chartModels {
                    if chartModel.isHidden {
                        continue
                    }
                    let x = (CGFloat(i) - range.start) * lineGap
                    if x >= 0, x <= viewSize.width {
                        value += chartModel.data[i].value
                    }
                }
                sumMax = max(sumMax, CGFloat(value))
            }
            setMaxValues([sumMax], animated: value)
        }
    }
    
    private func calcPercentageMaxValue(animateMaxValue value: Bool) {
        var newMaxValue: CGFloat = 0
        chartModels.forEach {
            if !$0.isHidden {
                newMaxValue = 100
            }
        }
        setMaxValues([newMaxValue], animated: value)
    }

    private func calcMaxValue(animateMaxValue value: Bool) {
        if yScaled {
            calcYScaledMaxValue(animateMaxValue: value)
        } else if percentage {
            calcPercentageMaxValue(animateMaxValue: value)
        } else if stacked {
            calcStackedMaxValue(animateMaxValue: value)
        } else {
            calcStandardMaxValue(animateMaxValue: value)
        }
    }
    
    private func calcConstants() {
        if isPreviewMode {
            topSpace = 0.0
            bottomSpace = 0.0
            topHorizontalLine = percentage ? 1 : 110.0 / 100.0
            
            countPoints = chartModels.map { $0.data.count }.max() ?? 0
            if countPoints <= 0 {
                lineGap = 0
            } else {
                lineGap = viewSize.width / (CGFloat(countPoints) - 1)
            }
        } else {
            topSpace = 40.0
            bottomSpace = 20.0
            topHorizontalLine = percentage ? 1 : 95 / 100.0
            let value = range.end - range.start - 1
            if value <= 0 {
                lineGap = 0
            } else {
                lineGap = viewSize.width / value
            }
        }
    }
    
    private func selectMaxValue(at index: Int) -> CGFloat {
        var maxValue: CGFloat = 0
        if yScaled {
            maxValue = maxValues[index]
        } else if let firstMax = maxValues.first {
            maxValue = firstMax
        }
        return maxValue
    }
    
    private var allData: [PointModel]?
    
    private func prepareStackData(chartModel: ChartModel, loopRange: Range<Int>) -> [PointModel] {
        var data = chartModel.data
        for i in loopRange {
            var dataValue = data[i].value
            if chartModel.runValueAnimation {
                if data[i].targetValue != 0 {
                    dataValue = 0
                }
                let value = Math.calcEaseInOut(for: frameAnimation, totalTime: framesInAnimationDuration)
                let toAddValue = CGFloat(data[i].deltaToTargetValue) * value
                dataValue = dataValue + Int(toAddValue)
            } else if chartModel.isHidden {
                dataValue = 0
            }
            var allDataValue: Int = 0
            if let allData = allData {
                allDataValue = allData[i].value
            }
            data[i].value = dataValue + allDataValue
        }
        allData = data
        return data
    }
    
    private func fetchLastVisibleIndex() -> Int? {
        let loopRange = 0..<chartModels.count
        var visibleIndex: Int?
        if percentage {
            for index in loopRange {
                let inverseIndex = loopRange.endIndex - index - 1
                if !chartModels[inverseIndex].isHidden {
                    visibleIndex = inverseIndex
                    break
                }
            }
        }
        return visibleIndex
    }

    private func calcSumValues(from data: [[PointModel]], loopRange: Range<Int>) -> [CGFloat] {
        // Sum all values in range and save it.
        var sumValues = [CGFloat]()
        for i in loopRange {
            var sumValue: Int = 0
            var previusValue: Int = 0
            for index in 0..<data.count {
                let chartModel = chartModels[index]
                if chartModel.isHidden {
                    continue
                }
                let value = data[index][i].value - previusValue // because it's stack
                sumValue += value
                previusValue = data[index][i].value
            }
            sumValues.append(CGFloat(sumValue))
        }
        return sumValues
    }

    private func calcPercentageData(from data: [PointModel],
                                    sumValues: [CGFloat],
                                    isLastVisibleChart: Bool,
                                    loopRange: Range<Int>) -> [PointModel] {
        // TODO: оптимизировать.
        var percentageData = [PointModel]()
        for index in loopRange {
            if isLastVisibleChart {
                percentageData.append(PointModel(value: 100, date: Date()))
                continue
            }
            let maxValue = sumValues[index - loopRange.startIndex]
            if maxValue == 0 {
                percentageData.append(PointModel(value: 0, date: Date()))
            } else {
                let value = Int(100 * CGFloat(data[index].value) / maxValue)
                percentageData.append(PointModel(value: value, date: Date()))
            }
        }
        return percentageData
    }
    
    private func calcPointsAndMakePaths() {
        let isUpdating = dataPoints != nil && self.paths != nil
        var newDataPoints = isUpdating ? nil : [[CGPoint]]()
        var newPaths = isUpdating ? nil : [CGPath]()
        
        // Preparing datas.
        allData = nil
        let loopRange = intRange
        var preparedData = [[PointModel]]()
        for index in 0..<chartModels.count {
            let chartModel = chartModels[index]
            if stacked {
                let data = prepareStackData(chartModel: chartModel, loopRange: loopRange)
                preparedData.append(data)
            } else {
                preparedData.append(Array(chartModel.data[loopRange]))
            }
        }
        
        var sumValues: [CGFloat]? = nil
        var lastVisibleIndex: Int? = nil
        if percentage {
            sumValues = calcSumValues(from: preparedData, loopRange: loopRange)
            lastVisibleIndex = fetchLastVisibleIndex()
        }
        
        let mapKey = chartModels.map { String(Int(truncating: $0.isHidden as NSNumber))}.reduce("", +)
        let previewKey = String(Int(truncating: isPreviewMode as NSNumber))
        
        for index in 0..<chartModels.count {
            
            let chartModel = chartModels[index]
            let maxValue = selectMaxValue(at: index)
            var data = preparedData[index]
            if percentage {
                var isLastVisibleChart = false
                if let lastVisibleIndex = lastVisibleIndex, index == lastVisibleIndex {
                    isLastVisibleChart = true
                }

                data = calcPercentageData(from: data,
                                          sumValues: sumValues!,
                                          isLastVisibleChart: isLastVisibleChart,
                                          loopRange: loopRange)
            } else if stacked {
                data = Array(data[loopRange])
            }
            let mapValue = "map: \(mapKey)"
            let previewValue = "preview: \(previewKey)"
            let nameValue = "name: \(chartModel.name)"
            let rangeValue = "range [\(loopRange.startIndex), \(loopRange.endIndex)]"
            let cachKey = mapValue + ", " + previewValue + ", " + nameValue + ", " + rangeValue
            
            let points = convertModelsToPoints(entries: data, maxValue: maxValue)
            
            if let path = fetchBezierPath(for: chartModel, points: points, key: cachKey) {
                if isUpdating {
                    self.paths?[index] = path
                } else {
                    newPaths!.append(path)
                }
            }

            if isUpdating {
                self.dataPoints?[index] = points
            } else {
                newDataPoints!.append(points)
            }
        }
        
        // Clean.
        allData = nil
        
        if !isUpdating {
            self.dataPoints = newDataPoints
            self.paths = newPaths
        }
    }
    
    private func fetchBezierPath(for chartModel: ChartModel, points: [CGPoint], key: String) -> CGPath? {
        var path: CGPath?
        if let cachedPath = cachedPaths[key] {
            path = cachedPath
        } else {
            path = chartModel.drawingStyle.createPath(dataPoints: points, lineGap: lineGap,
                                                      viewSize: viewDataSize, isPreviewMode: isPreviewMode)
            cachedPaths[key] = path
        }
        return path
    }
    
    private func calcNewTargetsValuesIfNeeded() {
        guard stacked else {
            return
        }
        
        frameAnimation = 0
        
        for i in 0..<chartModels.count {
            let chartModel = chartModels[i]
            if chartModel.isHidden && chartModel.targetDirection != .toZero {
                var data = chartModel.data
                for index in 0..<data.count {
                    var pointModel = data[index]
                    pointModel.targetValue = 0
                    pointModel.deltaToTargetValue = -pointModel.value
                    data[index] = pointModel
                }
                chartModel.data = data
                chartModel.targetDirection = .toZero
                chartModel.runValueAnimation = true
            }
            
            if !chartModel.isHidden && chartModel.targetDirection != .toValue {
                var data = chartModel.data
                for index in 0..<data.count {
                    var pointModel = data[index]
                    pointModel.targetValue = pointModel.value
                    pointModel.deltaToTargetValue = pointModel.value
                    data[index] = pointModel
                }
                chartModel.data = data
                chartModel.targetDirection = .toValue
                chartModel.runValueAnimation = true
            }
        }
    }
    
    func calcProperties(shouldCalcMaxValue: Bool = true,
                        animateMaxValue: Bool,
                        changedIsHidden: Bool) {
        findMaxRangePoints()
        calcConstants()

        if shouldCalcMaxValue {
            calcMaxValue(animateMaxValue: animateMaxValue)
        }
        
        if changedIsHidden {
            calcNewTargetsValuesIfNeeded()
        }
        viewDataSize = CGSize(width: viewSize.width,
                              height: viewSize.height - topSpace - bottomSpace)
        calcPointsAndMakePaths()
    }
    
    func calcHeight(for value: Int, with minMaxGap: CGFloat) -> CGFloat {
        if value == 0 {
            return viewDataSize.height
        }
        if Int(minMaxGap) == 0 {
            return -viewDataSize.height
        }
        return viewDataSize.height * (1 - ((CGFloat(value) - CGFloat(minValue)) / minMaxGap))
    }

    func calcLineValue(for value: CGFloat, with minMaxGap: CGFloat) -> Int {
        return Int((1 - value) * minMaxGap) + Int(minValue)
    }
    
    private func setMaxValues(_ newMaxValues: [CGFloat], animated: Bool = false) {
        if animated {
            guard !Math.isEqualArrays(newMaxValues, targetMaxValues),
                !Math.isEqualArrays(newMaxValues, maxValues) else {
                    return
            }
            targetMaxValues = newMaxValues
            for index in 0..<maxValues.count {
                deltaToTargetValues[index] = newMaxValues[index] - maxValues[index]
            }
            frameAnimation = 0
            runMaxValueAnimation = true
            onSetNewTargetMaxValue?()
        } else {
            maxValues = newMaxValues
            targetMaxValues = newMaxValues
            onSetNewTargetMaxValue?()
        }
    }

    private func convertModelsToPoints(entries: [PointModel], maxValue: CGFloat) -> [CGPoint] {
        var result: [CGPoint] = []
        let minMaxGap = CGFloat(maxValue - minValue) * topHorizontalLine
        for i in 0..<entries.count {
            let height = calcHeight(for: entries[i].value, with: minMaxGap)
            let point = CGPoint(x: CGFloat(i) * lineGap, y: height)
            result.append(point)
        }
        return result
    }

    private func findMaxRangePoints() {
        // TODO: спорный метод удалить
        var points: [PointModel] = []
        chartModels.forEach {
            if $0.data.count > points.count {
                points = $0.data
            }
        }
        self.maxRangePoints = points
    }

    func update() {
        guard frameAnimation < framesInAnimationDuration else {
            return
        }
        
        if runMaxValueAnimation {
            let value = Math.calcDeltaEaseInOut(for: frameAnimation,
                                                totalTime: framesInAnimationDuration)
            for index in 0..<deltaToTargetValues.count {
                let toAddValue = deltaToTargetValues[index] * value
                maxValues[index] = maxValues[index] + toAddValue
            }
            onChangeMaxValue?()
        }
        
        frameAnimation += 1
        if frameAnimation >= framesInAnimationDuration {
            runMaxValueAnimation = false
            chartModels.forEach { $0.runValueAnimation = false }
        }
    }
    
}
