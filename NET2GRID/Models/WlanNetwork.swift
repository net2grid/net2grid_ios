//
//  WlanNetwork.swift
//  Ynni
//
//  Created by Bart Blok on 21-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import Foundation
import ObjectMapper

class WlanNetwork: Mappable {
    
    var ssid: String = ""
    var rssi: Int = 0
    var encryption: Bool = false
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        self.ssid <- (map["ssid"])
        self.rssi <- (map["rssi"])
        self.encryption <- (map["encryption"])
    }
}
