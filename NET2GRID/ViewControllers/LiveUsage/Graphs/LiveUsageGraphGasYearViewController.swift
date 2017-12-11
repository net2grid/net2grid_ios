//
//  LiveUsageGraphGasYearViewController.swift
//  Ynni
//
//  Created by Bart Blok on 16-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import UIKit
import Charts

class LiveUsageGraphGasYearViewController: LiveUsageGraphBarViewController {
    
    override var quantityTitle: String { return "live-graph-gas-title".localized }
    override var scaleTitle: String { return "live-graph-year-scale".localized }
    override var refreshInterval: TimeInterval { return 60.0 * 60.0 * 24.0 * 7.0 }
    override var labelMinDelta: Double { return 60.0 * 60.0 * 24.0 * 31.0 }

    override func setupChart() {
        
        super.setupChart()
        
        let formatter = AxisDateListFormatter(dateStyle: .short, timeStyle: .none)
        formatter.dateFormat = "LLL"
        
        barChart.xAxis.valueFormatter = formatter;
    }
    
    override func foregroundColor() -> UIColor {
        return UIColor(red: 240.0/255.0, green: 99.0/255.0, blue: 110.0/255.0, alpha: 1.0)
    }
    
    override func fetchData() {
        
        LANApiManager.sharedManger.gasConsumption(scale: LANApiManager.Scales.year) { (results, error) in
            
            if results == nil {
                return
            }
            
            self.data = results
            self.updateData()
        }
    }
}
