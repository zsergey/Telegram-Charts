//
//  LabelsProcessor.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 4/12/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct LabelsProcessor {
    
    var isScrolling: Bool
    
    var sliderDirection: SliderDirection
    
    var setFinishedSliderDirection: Bool
    
    var labels: [TextLayer]?
    
    var dataSource: ChartDataSource?
    
    var contentSize: CGSize
    
    private let trailingSpace: CGFloat = 16
    
    private let leadingSpace: CGFloat = 16

    init(dataSource: ChartDataSource?, isScrolling: Bool, sliderDirection: SliderDirection,
         setFinishedSliderDirection: Bool, labels: [TextLayer]?, contentSize: CGSize) {
        self.dataSource = dataSource
        self.isScrolling = isScrolling
        self.sliderDirection = sliderDirection
        self.setFinishedSliderDirection = setFinishedSliderDirection
        self.labels = labels
        self.contentSize = contentSize
    }

    mutating func hideWrongLabelsUseSliderDirection(byScroll: Bool) {
        switch sliderDirection {
        case .center, .finished, .none:
            self.hideWrongLabels(isFirstCall: false, byScroll: byScroll)
        case .left, .right:
            self.hideWrongLabels(isFirstCall: true, byScroll: byScroll)
        }
    }
    
    mutating func hideWrongLabels(isFirstCall: Bool, byScroll: Bool) {
        guard let dataSource = dataSource,
            dataSource.chartModels.count > 0,
            !dataSource.isPreviewMode, dataSource.maxRangePoints.count > 0 else {
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
                    let x = sliderDirection == .left ? contentSize.width - ChartContentView.labelWidth / 2 : ChartContentView.labelWidth / 2
                    theIndex = Int((x + dataSource.range.start * dataSource.lineGap + ChartContentView.labelWidth / 2) / dataSource.lineGap)
                    let textLayer = labels![theIndex]
                    textLayer.isStatic = true
                } else {
                    let range = 0..<dataSource.maxRangePoints.count
                    for index in range {
                        let aIndex = sliderDirection == .left ? range.endIndex - index - 1 : index
                        let textLayer = labels![aIndex]
                        if textLayer.toOpacity == 1 {
                            let textLayerX = (CGFloat(aIndex) - dataSource.range.start) * dataSource.lineGap - ChartContentView.labelWidth / 2
                            if textLayerX > -ChartContentView.labelWidth / 2 && textLayerX < contentSize.width - ChartContentView.labelWidth / 2 {
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
    
    mutating func doMagic(in range: Range<Int>, skipHidden: Bool, inverse: Bool, byScroll: Bool) {
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
                let endXLastFrame = lastFrame.origin.x + lastFrame.size.width * coef / 2 + ChartContentView.labelWidth * coef
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
}
