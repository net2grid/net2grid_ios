//
//  UIColor+Hex.swift
//  Ynni
//
//  Created by Bart Blok on 01-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import UIKit

extension UIColor {
    
    convenience init(hex: Int) {
        
        self.init(red:CGFloat((hex >> 16) & 0xff) / 255, green:CGFloat((hex >> 8) & 0xff) / 255, blue:CGFloat(hex & 0xff) / 255, alpha: 1.0)
    }
}
