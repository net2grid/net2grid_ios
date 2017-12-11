//
//  AxisGasFormatter.swift
//  Ynni
//
//  Created by Bart Blok on 17-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import Foundation
import Charts

class AxisValueFormatter: NSObject, IAxisValueFormatter {
    
    let formatter: NumberFormatter = NumberFormatter()
    var unit: String?
    
    override init() {
        
        super.init()
        
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        
        let unitString = unit ?? ""
        
        return (formatter.string(from: NSNumber(value: value)) ?? "-") + " " + unitString
    }
}
