//
//  LuveUsageGraphPowerHourViewController.swift
//  Ynni
//
//  Created by Bart Blok on 16-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import UIKit
import Charts

class LiveUsageGraphPowerHourViewController: LiveUsageGraphLineViewController {

    override var quantityTitle: String { return "live-graph-power-title".localized }
    override var scaleTitle: String { return "live-graph-hour-scale".localized }
    override var refreshInterval: TimeInterval { return 10.0 }
    override var maxLabelCount: Int { return 4 }
    
    override func setupChart() {
        
        super.setupChart()
        
        lineChart.xAxis.valueFormatter = AxisDateListFormatter(dateStyle: .none, timeStyle: .short)
    }
    
    override func fetchData() {
        
        LANApiManager.sharedManger.elecPower(scale: LANApiManager.Scales.hour) { (results, error) in
            
            if results == nil {
                return
            }
            
            self.data = results
            self.updateData()
        }
    }
}
