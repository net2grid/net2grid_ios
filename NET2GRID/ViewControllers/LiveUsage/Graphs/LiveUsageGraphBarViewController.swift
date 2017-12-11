//
//  LiveUsageGraphBaViewController.swift
//  Ynni
//
//  Created by Bart Blok on 16-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import UIKit
import Charts

class LiveUsageGraphBarViewController: LiveUsageGraphViewController {
    
    var data: MeterResultSet?
    var valueFormatter: AxisValueFormatter?
    
    var barChart: BarChartView {
        return chartView as! BarChartView
    }
    
    var didInitAnimation: Bool = false
}

extension LiveUsageGraphBarViewController {
    
    override func setupChart() {
        
        super.setupChart()
        
        valueFormatter = AxisValueFormatter()
        
        barChart.xAxis.labelTextColor = UIColor.white
        
        barChart.pinchZoomEnabled = false
        barChart.doubleTapToZoomEnabled = false
        barChart.setScaleEnabled(false)
        
        // xAxis
        barChart.xAxis.labelTextColor = UIColor.white
        barChart.xAxis.labelPosition = .bottom
        barChart.xAxis.drawGridLinesEnabled = false
        barChart.xAxis.drawAxisLineEnabled = false
        barChart.xAxis.valueFormatter = AxisDateListFormatter(dateStyle: .none, timeStyle: .short)
        
        // Left Axis
        barChart.leftAxis.labelTextColor = UIColor.white
        barChart.leftAxis.drawAxisLineEnabled = false
        barChart.leftAxis.valueFormatter = valueFormatter
        
        // Right Axis
        barChart.rightAxis.drawGridLinesEnabled = false
        barChart.rightAxis.drawAxisLineEnabled = false
        barChart.rightAxis.drawLabelsEnabled = false
        
        barChart.legend.enabled = false
        
        barChart.chartDescription?.enabled = false
    }
    
    override func createChart() -> ChartViewBase {
        
        return BarChartView()
    }
    
    func foregroundColor() -> UIColor {
        return UIColor(red: 55.0/255.0, green: 209.0/255.0, blue: 187.0/255.0, alpha: 1.0)
    }
    
    override func updateData() {
        
        super.updateData()
        
        let data = createData()
        
        barChart.xAxis.labelCount = min(data.count, maxLabelCount)

        if(data.count == 0){
            
            chartView.isHidden = true
            noDataView.isHidden = false
            return
        }
        
        chartView.isHidden = false
        noDataView.isHidden = true
        
        let set = BarChartDataSet(values: data, label: "data")
        set.drawValuesEnabled = false
        set.setColor(foregroundColor())
        let chartData = BarChartData(dataSet: set)
        
        if barChart.xAxis.valueFormatter is AxisDateListFormatter, let meterData = self.data?.results {
            
            var dates = [Date]()
            
            for item in meterData {
                dates.append(item.date)
            }
            
            (barChart.xAxis.valueFormatter as! AxisDateListFormatter).data = dates
        }
        
        if let unit = self.data?.unit {
            valueFormatter?.unit = unit
        }
        
        barChart.data = chartData
        
        if !didInitAnimation {
            
            barChart.animate(yAxisDuration: 1.0)
            didInitAnimation = true
        }
    }
    
    func createData() -> [BarChartDataEntry] {
        
        guard let data = data?.results else {
            return []
        }
        
        if labelMinDelta > 0.0, data.count > 1, let first = data.first?.date, let last = data.last?.date {
            
            let delta = last.timeIntervalSince(first)
            
            if delta < labelMinDelta {
                return []
            }
        }
        
        var counter: Double = -1
        
        return data.map { (result) -> BarChartDataEntry in
            
            counter += 1
            return BarChartDataEntry(x: counter, y: Double(result.value))
        }
    }
}
