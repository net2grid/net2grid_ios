//
//  LANApiManager.swift
//  Ynni
//
//  Created by Bart Blok on 16-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import Foundation

import ObjectMapper
import SwiftyBeaver

private struct LANApiManagerConsts {
    
    static let ssidKey = "ssid"
    static let 🔑Key = "key"
    
    static let infoPath = "wlan/info"
    
    static let nowPath = "meter/now"
    static let elecPowerPath = "meter/elec/power"
    static let elecConsumptionPath = "meter/elec/consumption"
    static let gasConsumptionPath = "meter/gas/consumption"
}

class LANApiManager: LANBaseApiManager {
    
    struct Scales {
        static let hour = "hour"
        static let day = "day"
        static let month = "month"
        static let year = "year"
    }
    
    static let sharedManger = LANApiManager()

    typealias meterCallback = (_ power: MeterResultSet?, _ error: NSError?) -> ()
    
    
    func info(_ completion: @escaping (_ info: WlanInfo?, _ error: NSError?) -> ()) {
        
        get(path: LANApiManagerConsts.infoPath) { (response, error) in
            
            guard let responseDictionary: [String: AnyObject] = response as? [String: AnyObject] else {
                return completion(nil, error ?? NSError(domain: LANRouter.Consts.domainError, code: LANRouter.Consts.defaultError, userInfo: nil))
            }
            
            let info = Mapper<WlanInfo>().map(JSON: responseDictionary)
            completion(info, nil)
        }
    }
    
    func now(_ completion: @escaping (_ result: [String: AnyObject]?, _ error: NSError?) -> ()) {
        
        get(path: LANApiManagerConsts.nowPath) { (response, error) in
            
            guard let responseDictionary: [String: AnyObject] = response as? [String: AnyObject] else {
                return completion(nil, error ?? NSError(domain: LANRouter.Consts.domainError, code: LANRouter.Consts.defaultError, userInfo: nil))
            }
            
            guard let status = responseDictionary["status"] as? String, status == "ok" else {
                return completion(nil, NSError(domain: LANRouter.Consts.domainError, code: LANRouter.Consts.parseResponseCodeError, userInfo: nil))
            }
            
            completion(responseDictionary, nil)
        }
    }
    
    func elecPower(scale: String, _ completion: @escaping meterCallback) {
        
        get(path: LANApiManagerConsts.elecPowerPath.appendingPathComponent(scale)) { (response, error) in
        
            guard let responseDictionary: [String: AnyObject] = response as? [String: AnyObject] else {
                return completion(nil, error ?? NSError(domain: LANRouter.Consts.domainError, code: LANRouter.Consts.defaultError, userInfo: nil))
            }
            
            guard let results = responseDictionary["elec"]?["power"] as? [String: AnyObject] else {
                return completion(nil, NSError(domain: LANRouter.Consts.domainError, code: LANRouter.Consts.parseResponseCodeError, userInfo: nil))
            }
            
            completion(self.createMeterResultSet(results), nil)
        }
    }
    
    func elecConsumption(scale: String, _ completion: @escaping meterCallback) {
        
        get(path: LANApiManagerConsts.elecConsumptionPath.appendingPathComponent(scale)) { (response, error) in
            
            guard let responseDictionary: [String: AnyObject] = response as? [String: AnyObject] else {
                return completion(nil, error ?? NSError(domain: LANRouter.Consts.domainError, code: LANRouter.Consts.defaultError, userInfo: nil))
            }
            
            guard let results = responseDictionary["elec"]?["consumption"] as? [String: AnyObject] else {
                return completion(nil, NSError(domain: LANRouter.Consts.domainError, code: LANRouter.Consts.parseResponseCodeError, userInfo: nil))
            }
            
            completion(self.createMeterResultSet(results), nil)
        }
    }
    
    func gasConsumption(scale: String, _ completion: @escaping meterCallback) {
        
        get(path: LANApiManagerConsts.gasConsumptionPath.appendingPathComponent(scale)) { (response, error) in
            
            guard let responseDictionary: [String: AnyObject] = response as? [String: AnyObject] else {
                return completion(nil, error ?? NSError(domain: LANRouter.Consts.domainError, code: LANRouter.Consts.defaultError, userInfo: nil))
            }
            
            guard let results = responseDictionary["gas"]?["consumption"] as? [String: AnyObject] else {
                return completion(nil, NSError(domain: LANRouter.Consts.domainError, code: LANRouter.Consts.parseResponseCodeError, userInfo: nil))
            }
            
            completion(self.createMeterResultSet(results), nil)
        }
    }
    
    
    fileprivate func createMeterResultSet(_ data: [String: AnyObject]) -> MeterResultSet? {
        
        guard let startDateInterval = data["start_time"] as? TimeInterval, let values = data["results"] as? [Int], let interval = data["interval"] as? TimeInterval else {
            return nil
        }
        
        let startDate = Date(timeIntervalSince1970: startDateInterval)
        var results = [MeterResult]()
        
        var counter = 0;
        
        for value in values {
            
            let date = startDate.addingTimeInterval(interval * TimeInterval(counter))
            results.append(MeterResult(value: value, date: date))
            
            counter += 1
        }
        
        let unit = data["unit"] as? String ?? ""
        
        return MeterResultSet(results: results, unit: unit)
    }
}
