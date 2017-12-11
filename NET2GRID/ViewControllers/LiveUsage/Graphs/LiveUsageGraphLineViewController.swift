//
//  LiveUsageGraphLineViewController.swift
//  Ynni
//
//  Created by Bart Blok on 16-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import UIKit
import Charts

class LiveUsageGraphLineViewController: LiveUsageGraphViewController {
    
    var data: MeterResultSet?
    var valueFormatter: AxisValueFormatter?
    
    var lineChart: LineChartView {
        return chartView as! LineChartView
    }
}

extension LiveUsageGraphLineViewController {
    
    override func createChart() -> ChartViewBase {
        
        return LineChartView()
    }
    
    override func setupChart() {
        
        super.setupChart()
        
        valueFormatter = AxisValueFormatter()
        
        lineChart.pinchZoomEnabled = false
        lineChart.doubleTapToZoomEnabled = false
        lineChart.setScaleEnabled(false)
        
        // X Axis
        lineChart.xAxis.labelTextColor = UIColor.white
        lineChart.xAxis.labelPosition = .bottom
        lineChart.xAxis.drawGridLinesEnabled = false
        lineChart.xAxis.drawAxisLineEnabled = false
        lineChart.xAxis.valueFormatter = AxisDateListFormatter(dateStyle: .none, timeStyle: .short)
        
        // Left Axis
        lineChart.leftAxis.labelTextColor = UIColor.white
        lineChart.leftAxis.drawAxisLineEnabled = false
        lineChart.leftAxis.valueFormatter = valueFormatter
        
        // Right Axis
        lineChart.rightAxis.drawGridLinesEnabled = false
        lineChart.rightAxis.drawAxisLineEnabled = false
        lineChart.rightAxis.drawLabelsEnabled = false
    }
    
    func foregroundColor() -> UIColor {
        return UIColor(red: 55.0/255.0, green: 209.0/255.0, blue: 187.0/255.0, alpha: 1.0)
    }
    
    override func updateData() {
        
        super.updateData()
        
        let data = createData()
        
        lineChart.xAxis.labelCount = min(data.count, maxLabelCount)
        
        if labelMinDelta > 0, data.count > 1, let first = data.first, let last = data.last, Double(last.x) - Double(first.x) < labelMinDelta {
            lineChart.xAxis.labelCount = 1
        }
        
        if(data.count == 0){
            
            chartView.isHidden = true
            noDataView.isHidden = false
            return
        }
        
        chartView.isHidden = false
        noDataView.isHidden = true
        
        let set = LineChartDataSet(values: data, label: "data")
        set.drawValuesEnabled = false
        set.drawCirclesEnabled = false
        set.drawCircleHoleEnabled = false
        set.setColor(foregroundColor())
        
        let chartData = LineChartData(dataSet: set)
        
        if lineChart.xAxis.valueFormatter is AxisDateListFormatter, let meterData = self.data?.results {
            
            var dates = [Date]()
            
            for item in meterData {
                dates.append(item.date)
            }
            
            (lineChart.xAxis.valueFormatter as! AxisDateListFormatter).data = dates
        }
        
        if let unit = self.data?.unit {
            valueFormatter?.unit = unit
        }
        
        lineChart.data = chartData
    }
    
    func createData() -> [ChartDataEntry] {
        
        guard let data = data else {
            return []
        }
        
        if labelMinDelta > 0.0, data.results.count > 1, let first = data.results.first?.date, let last = data.results.last?.date {
            
            let delta = last.timeIntervalSince(first)
            
            if delta < labelMinDelta {
                return []
            }
        }
        
        var counter: Double = -1
        
        return data.results.map { (result) -> ChartDataEntry in
            
            counter += 1
            return ChartDataEntry(x: counter, y: Double(result.value))
        }
    }
}
