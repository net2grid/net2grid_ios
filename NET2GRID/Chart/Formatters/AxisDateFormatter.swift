//
//  AxisDateFormatter.swift
//  Ynni
//
//  Created by Bart Blok on 16-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import Foundation
import Charts

class AxisDateFormatter: NSObject, IAxisValueFormatter {
    
    private let formatter: DateFormatter = DateFormatter()
    var precisionComponents: Set<Calendar.Component>?
    
    var dateFormat: String? {
        
        get {
            return formatter.dateFormat
        }
        
        set {
            formatter.dateFormat = newValue
        }
    }
    
    init(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style, precisionComponents: Set<Calendar.Component>? = nil) {
        
        super.init()
        
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
    
        self.precisionComponents = precisionComponents
    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        
        let date = Date(timeIntervalSince1970: value)
        
        if let comps = precisionComponents {
            
            let components = Calendar.current.dateComponents(comps, from: date)
            return formatter.string(from: Calendar.current.date(from: components)!)
        }
        else {
            
            return formatter.string(from: date)
        }
    }
}
