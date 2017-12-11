//
//  LiveUsageGraphEnergyTwoWeeksViewController.swift
//  Ynni
//
//  Created by Bart Blok on 17-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import UIKit
import Charts

class LiveUsageGraphEnergyMonthViewController: LiveUsageGraphBarViewController {
    
    override var quantityTitle: String { return "live-graph-energy-title".localized }
    override var scaleTitle: String { return "live-graph-month-scale".localized }
    override var refreshInterval: TimeInterval { return 60.0 * 60.0 * 24.0 }
    override var labelMinDelta: Double { return 60.0 * 60.0 * 24.0 * 2.0 }
    
    override func setupChart() {
        
        super.setupChart()
        
        let formatter = AxisDateListFormatter(dateStyle: .short, timeStyle: .none)
        formatter.dateFormat = "d"
        
        barChart.xAxis.valueFormatter = formatter;
    }
    
    override func fetchData() {
        
        LANApiManager.sharedManger.elecConsumption(scale: LANApiManager.Scales.month) { (results, error) in
            
            if results == nil {
                return
            }
            
            self.data = results
            self.updateData()
        }
    }
}
