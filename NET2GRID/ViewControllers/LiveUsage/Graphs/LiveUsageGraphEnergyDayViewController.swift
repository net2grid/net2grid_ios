//
//  LiveUsageGraphEnergyDayViewController.swift
//  Ynni
//
//  Created by Bart Blok on 17-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import UIKit
import Charts

class LiveUsageGraphEnergyDayViewController: LiveUsageGraphBarViewController {
    
    override var quantityTitle: String { return "live-graph-energy-title".localized }
    override var scaleTitle: String { return "live-graph-2-days-scale".localized }
    override var refreshInterval: TimeInterval { return 60.0 * 60.0 }
    override var maxLabelCount: Int { return 4 }
    override var labelMinDelta: Double { return 60.0 * 60.0 * 2.0 }
    
    override func setupChart() {
        
        super.setupChart()
        
        barChart.xAxis.valueFormatter = AxisDateListFormatter(dateStyle: .none, timeStyle: .short, precisionComponents: [.year, .month, .day, .hour])
    }
    
    override func fetchData() {
        
        LANApiManager.sharedManger.elecConsumption(scale: LANApiManager.Scales.day) { (results, error) in
            
            if results == nil {
                return
            }
            
            self.data = results
            self.updateData()
        }
    }
}
