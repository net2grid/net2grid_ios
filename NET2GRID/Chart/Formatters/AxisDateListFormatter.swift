//
//  AxisDateListFormatter.swift
//  Ynni
//
//  Created by Bart Blok on 17-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import Foundation
import Charts

class AxisDateListFormatter: AxisDateFormatter {
    
    var data: [Date]?
    
    override func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        
        let valueInt = Int(value);
        
        guard let data = data, valueInt >= 0, valueInt < data.count else {
            return ""
        }
        
        let item = data[valueInt]
        return super.stringForValue(item.timeIntervalSince1970, axis: axis)
    }
}
