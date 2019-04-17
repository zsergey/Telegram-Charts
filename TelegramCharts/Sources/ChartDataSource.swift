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
    
    var range: Range<CGFloat> = 0.0..<2.0
    
    var uniqueId: String = ""
    
    var intRange: Range<Int> {
        let startIndex = max(Int(range.lowerBound - leadingSpace / lineGap), 0)
        let endIndex = min(Int(viewSize.width / lineGap + range.lowerBound) + 2, maxRangePoints.count)
        return startIndex..<endIndex
    }
    
    var deltaX: CGFloat {
        return (CGFloat(intRange.startIndex) - range.lowerBound) * lineGap + trailingSpace
    }
    
    var selectedPeriod: String {
        let loopRange = intRange
        guard maxRangePoints.count > 0,
            loopRange.startIndex < maxRangePoints.count,
            loopRange.endIndex - 1 < maxRangePoints.count else {
            return ""
        }
        let startDate = DateCache.shared.fullFormat(for: maxRangePoints[loopRange.startIndex].date)
        let endDate = DateCache.shared.fullFormat(for: maxRangePoints[loopRange.endIndex - 1].date)
        return startDate + " - " + endDate
    }

    var sliderWidth: CGFloat = 0
    
    var startX: CGFloat = 0
    
    var viewSize: CGSize = .zero 
    
    var chartModels: [ChartModel] {
        didSet {
            dataPoints = nil
            paths.removeAll()
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

    var needsAnimatePath: Bool = false
    
    var isOneChartsVisible: Bool = false

    var isDetailedView: Bool = false
    
    let trailingSpace: CGFloat = 16
    
    let leadingSpace: CGFloat = 16

    private(set) var lineGap: CGFloat = 60.0
    
    private(set) var topSpace: CGFloat = 0.0
    
    private(set) var bottomSpace: CGFloat = 0.0
    
    private(set) var topHorizontalLine: CGFloat = 95.0 / 100.0
    
    public var maxValues: [CGFloat] = []

    private(set) var targetMaxValues: [CGFloat] = []
    
    private(set) var deltaToTargetMaxValues: [CGFloat] = []

    public var minValues: [CGFloat] = []

    private(set) var targetMinValues: [CGFloat] = []

    private(set) var deltaToTargetMinValues: [CGFloat] = []
    
    private(set) var frameAnimation: Int = 0
    
    private(set) var runMaxValueAnimation: Bool = false

    private(set) var countPoints: Int = 0
    
    private(set) var dataPoints: [[CGPoint]]?

    private(set) var paths: [String: CGPath] = [:]
    
    private(set) var maxRangePoints: [PointModel] = []
    
    private var viewDataSize: CGSize = .zero

    private(set) var yScaled: Bool = false

    private(set) var stacked: Bool = false

    private(set) var singleBar: Bool = false

    private(set) var percentage: Bool = false

    public var framesInAnimationDuration: Int {
        return Int(CFTimeInterval(60) * UIView.animationDuration)
    }
    
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
            self.deltaToTargetMaxValues.append(0)
            self.minValues.append(0)
            self.targetMinValues.append(0)
            self.deltaToTargetMinValues.append(0)
        }
        if yScaled {
            chartModels.forEach { _ in addZeroValue() }
        } else {
            addZeroValue()
        }
    }

    var mapKey: String {
        var result = ""
        for i in 0..<chartModels.count {
            let chartModel = chartModels[i]
            result = result + String(Int(truncating: chartModel.isHidden as NSNumber))
        }
        return result
    }
    
    typealias RangePath = [Range<CGFloat>: CGPath]
    var cachedPaths = [String: RangePath]()
    
    typealias RangeValue = [Range<CGFloat>: CGFloat]
    typealias RangeValues = [Range<CGFloat>: [CGFloat]]

    var cachedStandardMaxValues = [String: RangeValue]()
    var cachedStackedMaxValues = [String: RangeValue]()
    var cachedYScaledMaxValues = [String: RangeValues]()
    var cachedYScaledMinValues = [String: RangeValues]()

    private func calcYScaledMaxMinValue(animateMaxValue value: Bool) {
        if isPreviewMode {
            // Individual maximum in full range.
            var newMaxValues = self.maxValues
            var newMinValues = self.minValues
            for index in 0..<chartModels.count {
                let chartModel = chartModels[index]
                if chartModel.isHidden {
                    newMaxValues[index] = 0
                    newMinValues[index] = 0
                } else {
                    newMaxValues[index] = CGFloat(chartModel.data.max()?.value ?? 0)
                    newMinValues[index] = CGFloat(chartModel.data.min()?.value ?? 0)
                }
            }
            setMaxMinValues(newMaxValues, newMinValues, animated: value)
        } else {
            // Individual maximum in specific range.
            if let cachedMaxValues = cachedYScaledMaxValues[mapKey],
                let maxValues = cachedMaxValues[range],
                let cachedMinValues = cachedYScaledMinValues[mapKey],
                let minValues = cachedMinValues[range] {
                setMaxMinValues(maxValues, minValues, animated: value)
            } else {
                var newMaxValues = self.maxValues
                var newMinValues = self.maxValues
                let loopRange = intRange
                for index in 0..<chartModels.count {
                    let chartModel = chartModels[index]
                    if chartModel.isHidden {
                        newMaxValues[index] = 0
                        newMinValues[index] = 0
                    } else {
                        var maxValue: CGFloat = 0
                        var minValue: CGFloat = CGFloat(Int.max)
                        for i in loopRange {
                            let x = (CGFloat(i) - range.lowerBound) * lineGap
                            if x >= -trailingSpace, x <= viewSize.width - leadingSpace {
                                let value = CGFloat(chartModel.data[i].value)
                                if value > maxValue {
                                    maxValue = value
                                }
                                if value < minValue {
                                    minValue = value
                                }
                            }
                        }
                        newMaxValues[index] = maxValue
                        newMinValues[index] = minValue
                    }
                }

                var dictionaryMax = cachedYScaledMaxValues[mapKey] == nil ? RangeValues() : cachedYScaledMaxValues[mapKey]!
                dictionaryMax[range] = newMaxValues
                cachedYScaledMaxValues[mapKey] = dictionaryMax

                var dictionaryMin = cachedYScaledMinValues[mapKey] == nil ? RangeValues() : cachedYScaledMinValues[mapKey]!
                dictionaryMin[range] = newMinValues
                cachedYScaledMinValues[mapKey] = dictionaryMin

                setMaxMinValues(newMaxValues, newMinValues, animated: value)
            }
        }
    }
    
    private func calcStandardMaxValue(animateMaxValue value: Bool) {
        if isPreviewMode {
            // One maximum in full range.
            let maxValue: CGFloat = chartModels.map { chartModel in
                if chartModel.isHidden {
                    return 0
                } else {
                    return CGFloat(chartModel.data.max()?.value ?? 0)
                }}.compactMap { $0 }.max() ?? 0
            setMaxMinValues([maxValue], [0], animated: value)
        } else {
            // One maximum in specific range.
            if let cachedValues = cachedStandardMaxValues[mapKey],
                let maxValue = cachedValues[range] {
                setMaxMinValues([maxValue], [0], animated: value)
            } else {
                var maxValue: CGFloat = 0
                let loopRange = intRange
                for chartModel in chartModels {
                    if chartModel.isHidden { continue }
                    for i in loopRange {
                        let x = (CGFloat(i) - range.lowerBound) * lineGap
                        if x >= -trailingSpace, x <= viewSize.width - leadingSpace {
                            let value = CGFloat(chartModel.data[i].value)
                            if value > maxValue {
                                maxValue = value
                            }
                        }
                    }
                }
                
                var dictionary = cachedStandardMaxValues[mapKey] == nil ? RangeValue() : cachedStandardMaxValues[mapKey]!
                dictionary[range] = maxValue
                cachedStandardMaxValues[mapKey] = dictionary
                
                setMaxMinValues([maxValue], [0], animated: value)
            }
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
            setMaxMinValues([sumMax], [0], animated: value)
        } else {
            // Sum all maximums in specific range.
            if let cachedValues = cachedStackedMaxValues[mapKey],
                let maxValue = cachedValues[range] {
                setMaxMinValues([maxValue], [0], animated: value)
            } else {

                var maxValue: CGFloat = 0
                let loopRange = intRange
                for i in loopRange {
                    var value: Int = 0
                    for chartModel in chartModels {
                        if chartModel.isHidden {
                            continue
                        }
                        let x = (CGFloat(i) - range.lowerBound) * lineGap
                        if x >= -trailingSpace, x <= viewSize.width - leadingSpace {
                            value += chartModel.data[i].value
                        }
                    }
                    maxValue = max(maxValue, CGFloat(value))
                }
                
                var dictionary = cachedStackedMaxValues[mapKey] == nil ? RangeValue() : cachedStackedMaxValues[mapKey]!
                dictionary[range] = maxValue
                cachedStackedMaxValues[mapKey] = dictionary

                setMaxMinValues([maxValue], [0], animated: value)
            }
        }
    }
    
    private func calcPercentageMaxValue(animateMaxValue value: Bool) {
        var newMaxValue: CGFloat = 0
        chartModels.forEach {
            if !$0.isHidden {
                newMaxValue = 100
            }
        }
        setMaxMinValues([newMaxValue], [0], animated: value)
    }

    private func calcMaxValue(animateMaxValue value: Bool) {
        if yScaled {
            calcYScaledMaxMinValue(animateMaxValue: value)
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
                var count = CGFloat(countPoints) - 1
                if stacked, !percentage {
                    count = CGFloat(countPoints)
                }
                lineGap = viewSize.width / count
            }
        } else {
            topSpace = 30.0 // 40
            bottomSpace = 20.0
            topHorizontalLine = percentage ? 1 : 95 / 100.0
            var value = range.upperBound - range.lowerBound - 1
            if stacked, !percentage {
                value = range.upperBound - range.lowerBound
            }
            if value <= 0 {
                lineGap = 0
            } else {
                lineGap = (viewSize.width - leadingSpace - trailingSpace) / value
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

    private func selectMinValue(at index: Int) -> CGFloat {
        var minValue: CGFloat = 0
        if yScaled {
            minValue = minValues[index]
        } else if let firstMin = minValues.first {
            minValue = firstMin
        }
        return minValue
    }

    private func calcPointsAndMakePaths() {
        
        let isUpdatingPoints = dataPoints != nil
        var newDataPoints = isUpdatingPoints ? nil : [[CGPoint]]()
        let loopRange = intRange
        let delta = deltaX
        
        for index in 0..<chartModels.count {
            
            let chartModel = chartModels[index]
            let maxValue = selectMaxValue(at: index)
            let minValue = selectMinValue(at: index)
            
            var data = Array(chartModel.data[loopRange])
            if stacked {
                data = Array(chartModel.stackData[mapKey]![loopRange])
            }
            
            var points = convertModelsToPoints(entries: data, maxValue: maxValue, minValue: minValue)

            if !isPreviewMode {
                // Correct x for smoth scrolling of charts.
                for i in 0..<points.count {
                    points[i] = CGPoint(x: points[i].x + delta, y: points[i].y)
                }
            }
            
            /*let cacheKey = uniqueId + chartModel.name + mapKey
            if let rangePath = cachedPaths[cacheKey], let path = rangePath[range] {
                paths[uniqueId + chartModel.name] = path
            } else {*/
            if let path = chartModel.drawingStyle.createPath(dataPoints: points, lineGap: lineGap,
                                                             viewSize: viewDataSize, isPreviewMode: isPreviewMode) {
                paths[uniqueId + chartModel.name] = path
            }
            /*        let rangePath: RangePath = [range: path]
             cachedPaths[cacheKey] = rangePath
             }
             }*/


            if isUpdatingPoints {
                self.dataPoints?[index] = points
            } else {
                newDataPoints!.append(points)
            }
        }
        
        if !isUpdatingPoints {
            self.dataPoints = newDataPoints
        }
    }
    
    func calcProperties(shouldCalcMaxValue: Bool = true,
                        animateMaxValue: Bool,
                        changedIsHidden: Bool) {
        findMaxRangePoints()
        calcConstants()
        
        var animateMaxValue = animateMaxValue
        needsAnimatePath = false
        if stacked || (name == "CALLS") {
            needsAnimatePath = changedIsHidden
            if changedIsHidden {
                animateMaxValue = false
            }
        }
        
        if shouldCalcMaxValue {
            calcMaxValue(animateMaxValue: animateMaxValue)
        }
        
        viewDataSize = CGSize(width: viewSize.width,
                              height: viewSize.height - topSpace - bottomSpace)
        calcPointsAndMakePaths()
    }
    
    func calcHeight(for value: Int, with minMaxGap: CGFloat, minValue: CGFloat) -> CGFloat {
        if value == 0 {
            return viewDataSize.height
        }
        if Int(minMaxGap) == 0 {
            return -viewDataSize.height
        }
        return viewDataSize.height * (1 - ((CGFloat(value) - CGFloat(minValue)) / minMaxGap))
    }

    func calcLineValue(for value: CGFloat, with minMaxGap: CGFloat, minValue: CGFloat) -> Int {
        return Int((1 - value) * minMaxGap) + Int(minValue)
    }
    
    private func setMaxMinValues(_ newMaxValues: [CGFloat], _ newMinValues: [CGFloat], animated: Bool = false) {
        if animated {
            let changedMaxValues = !Math.isEqualArrays(newMaxValues, targetMaxValues) &&
                                   !Math.isEqualArrays(newMaxValues, maxValues)
            let changedMinValues = !Math.isEqualArrays(newMinValues, targetMinValues) &&
                                   !Math.isEqualArrays(newMinValues, minValues)
            guard changedMaxValues || changedMinValues else {
                return
            }
            targetMaxValues = newMaxValues
            targetMinValues = newMinValues
            for index in 0..<maxValues.count {
                deltaToTargetMaxValues[index] = newMaxValues[index] - maxValues[index]
                deltaToTargetMinValues[index] = newMinValues[index] - minValues[index]
            }
            
            frameAnimation = 0
            runMaxValueAnimation = true
            onSetNewTargetMaxValue?()
        } else {
            maxValues = newMaxValues
            targetMaxValues = newMaxValues
            minValues = newMinValues
            targetMinValues = newMinValues
            onSetNewTargetMaxValue?()
        }
    }

    private func convertModelsToPoints(entries: [PointModel], maxValue: CGFloat, minValue: CGFloat) -> [CGPoint] {
        var result: [CGPoint] = []
        let minMaxGap = CGFloat(maxValue - minValue) * topHorizontalLine
        for i in 0..<entries.count {
            let height = calcHeight(for: entries[i].value, with: minMaxGap, minValue: minValue)
            let point = CGPoint(x: CGFloat(i) * lineGap, y: height)
            result.append(point)
        }
        return result
    }

    private func findMaxRangePoints() {
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
            
            for index in 0..<deltaToTargetMaxValues.count {
                let toAddMaxValue = deltaToTargetMaxValues[index] * value
                maxValues[index] = maxValues[index] + toAddMaxValue
                
                let toAddMinValue = deltaToTargetMinValues[index] * value
                minValues[index] = minValues[index] + toAddMinValue
            }
        }
        
        onChangeMaxValue?()

        frameAnimation += 1
        if frameAnimation >= framesInAnimationDuration {
            runMaxValueAnimation = false
            chartModels.forEach { $0.runValueAnimation = false }
        }
    }
    
}
