//
//  WlanInfo.swift
//  Ynni
//
//  Created by Bart Blok on 21-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import Foundation
import ObjectMapper

class WlanInfo: Mappable {
    
    struct Mode {
        static let client = "Client"
        static let accessPoint = "AccessPoint"
    }
    
    var ipAddress: String = ""
    var mac: String = ""
    var clientSsid: String = ""
    var clientKey: String = ""
    var apKey: String = ""
    var apSsid: String = ""
    var mode = ""
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        
        self.mode <- (map["mode"])
        self.ipAddress <- (map["ip_addr"])
        self.mac <- (map["mac"])
        self.clientSsid <- (map["client_ssid"])
        self.clientKey <- (map["client_key"])
        self.apKey <- (map["ap_key"])
        self.apSsid <- (map["ap_ssid"])
    }
}
