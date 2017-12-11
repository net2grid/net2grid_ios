//
//  WiFiHelper.swift
//  Ynni
//
//  Created by Bart Blok on 01-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import Foundation
import SystemConfiguration.CaptiveNetwork

class WiFiHelper {
    
    class func getCurrentSSID() -> String? {
        
        var currentSSID: String?
        
        if let interfaces = CNCopySupportedInterfaces() {
            for i in 0..<CFArrayGetCount(interfaces) {
                
                let interfaceName: UnsafeRawPointer = CFArrayGetValueAtIndex(interfaces, i)
                let rec = unsafeBitCast(interfaceName, to: AnyObject.self)
                let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)" as CFString)
                if let interfaceData = unsafeInterfaceData as? [String: AnyObject] {
                    currentSSID = interfaceData["SSID"] as? String
                }
            }
        }
        
        return currentSSID
    }
    
    class func isOnSmartBridgeNetwork() -> Bool {
        
        let network = WiFiHelper.getCurrentSSID()
        if network == nil {
            return false
        }
        
        if let info = PersistentHelper.wlanInfo() {
            
            return info.clientSsid == network;
        }
        
        return true
    }
}
