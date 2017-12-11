//
//  MeterResult.swift
//  NET2GRID
//
//  Created by Bart Blok on 14-03-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import Foundation

class MeterResult {
    
    var value: Int
    var date: Date
    
    required init(value: Int, date: Date) {
        self.value = value
        self.date = date
    }
}
