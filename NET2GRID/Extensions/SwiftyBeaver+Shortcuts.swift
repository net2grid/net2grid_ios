//
//  SwiftyBeaver+Shortcuts.swift
//  NET2GRID
//
//  Created by Bart Blok on 13-04-18.
//  Copyright © 2018 Wittig. All rights reserved.
//

import Foundation
import SwiftyBeaver

extension SwiftyBeaver {
    
    public class func exception(_ message: String,  _ error: NSError?, _file: String = #file, _ function: String = #function, line: Int = #line) {
        
        var resolvedMessage = message
        
        if let error = error {
            resolvedMessage += "Error: " + error.description
        }
        
        self.error(resolvedMessage, _file, function, line: line)
    }
    
    public class func exception(_ message: String,  _ error: Error?, _file: String = #file, _ function: String = #function, line: Int = #line) {
        
        var resolvedMessage = message
        
        if let error = error {
            resolvedMessage += "Error: " + error.localizedDescription
        }
        
        self.error(resolvedMessage, _file, function, line: line)
    }
}
