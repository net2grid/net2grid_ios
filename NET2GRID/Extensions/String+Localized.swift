//
//  String+Localized.swift
//  NET2GRID
//
//  Created by Bart Blok on 14-03-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: "Main", bundle: Bundle.main, value: "", comment: "")
    }
}
