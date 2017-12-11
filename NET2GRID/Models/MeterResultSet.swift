//
//  MeterResultSet.swift
//  NET2GRID
//
//  Created by Bart Blok on 14-03-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import Foundation

class MeterResultSet {
    
    var unit: String
    var results: [MeterResult]
    
    required init(results: [MeterResult], unit: String) {
        
        self.results = results
        self.unit = unit
    }
}
