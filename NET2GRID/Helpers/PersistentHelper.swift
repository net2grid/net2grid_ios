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
        
        static let wlanInfo = "wlanInfo"
    }
    
    class func wlanInfo() -> WlanInfo? {
    
        if let json = UserDefaults.standard.string(forKey: Keys.wlanInfo) {
            
            return Mapper<WlanInfo>().map(JSONString: json)
        }
        
        return nil
    }
    
    class func storeWlanInfo(_ info: WlanInfo) -> Bool {
        
        if let json = info.toJSONString() {
            
            log.info("Storing Wlan info: \(json)")
            
            UserDefaults.standard.set(json, forKey: Keys.wlanInfo)
            UserDefaults.standard.synchronize()
            
            return true
        }
        
        return false
    }
}
