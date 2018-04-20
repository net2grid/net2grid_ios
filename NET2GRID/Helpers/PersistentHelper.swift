//
//  PersistentHelper.swift
//  Ynni
//
//  Created by Bart Blok on 21-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import Foundation
import ObjectMapper

class PersistentHelper
{
    struct Keys {
        
        static let ssid = "ssid"
    }
    
    class func ssid() -> String? {
    
        return UserDefaults.standard.string(forKey: Keys.ssid)
    }
    
    class func storeSsid(_ ssid: String) -> Bool {
        
        log.info("Storing Wlan ssid: \(ssid)")
        
        UserDefaults.standard.set(ssid, forKey: Keys.ssid)
        UserDefaults.standard.synchronize()
        
        return true
    }
}
