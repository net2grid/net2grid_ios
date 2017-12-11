//
//  OnboardingApiManager.swift
//  Ynni
//
//  Created by Bart Blok on 07-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import Foundation

import ObjectMapper
import SwiftyBeaver

private struct OnboardingApiManagerConsts {
    
    static let ssidKey = "ssid"
    static let 🔑Key = "key"
    
    static let scanPath = "wlan/scan"
    static let joinPath = "wlan/join"
    static let infoPath = "wlan/info"
    static let pingPath = "wlan/ping"
    static let disablePath = "wlan/disable"
    
    struct PingResponse {
        static let connected = "ok"
        static let notConnected = "error"
    }
}

class OnboardingApiManager: OnboardingBaseApiManager {
    
    static let sharedManger = OnboardingApiManager()
    
    func ping(_ completion: @escaping (_ connected: Bool?, _ error: NSError?) -> Void) {
        
        post(path: OnboardingApiManagerConsts.pingPath, parameters: [:]) { (response, error) in
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            if let res = response as? [String:AnyObject], let value = res["result"] as? String {
                
                if value == OnboardingApiManagerConsts.PingResponse.connected {
                    completion(true, nil)
                }
                else {
                    completion(false, nil)
                }
            }
            else {
                completion(false, nil)
            }
        }
    }
    
    func disable(_ completion: @escaping (_ error: NSError?) -> Void) {
        
        post(path: OnboardingApiManagerConsts.disablePath, parameters: [:]) { (response, error) in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            completion(nil)
        }
    }
    
    func scan(_ completion: @escaping (_ networks: [WlanNetwork]?, _ response: [String: AnyObject]?, _ error: NSError?) -> Void) {
        
        post(path: OnboardingApiManagerConsts.scanPath, parameters: [:], completion: { response, error in
            
            self.finishScan(response, error: error, completion: completion)
        })
    }
    
    func finishScan(_ response: AnyObject?, error: NSError?, completion: (_ networks: [WlanNetwork]?, _ response: [String: AnyObject]?, _ error: NSError?) -> Void) {
        
        guard let responseDictionary: [String: AnyObject] = response as? [String: AnyObject],
            let networksDictionaryArray = responseDictionary["APList"] else {
                return completion(nil, nil, error ?? NSError(domain: OnboardingRouter.Consts.domainError, code: OnboardingRouter.Consts.defaultError, userInfo: nil))
        }
        
        let networks = Mapper<WlanNetwork>().mapArray(JSONArray: networksDictionaryArray as! [[String : Any]])
        var uniqueNetworks: [WlanNetwork]?
        
        if networks != nil {
            
            uniqueNetworks = [WlanNetwork]()
            var foundNetworkNames = [String]()
            
            for network in networks! {
                
                if !foundNetworkNames.contains(network.ssid) {
                    
                    uniqueNetworks!.append(network)
                    foundNetworkNames.append(network.ssid)
                }
            }
            
            uniqueNetworks?.sort { $0.ssid < $1.ssid }
        }
        
        completion(uniqueNetworks, responseDictionary, nil)
    }
    
    func info(_ completion: @escaping (_ info: WlanInfo?, _ error: NSError?) -> ()) {
        
        get(path: OnboardingApiManagerConsts.infoPath) { (response, error) in
            
            guard let responseDictionary: [String: AnyObject] = response as? [String: AnyObject] else {
                return completion(nil, error ?? NSError(domain: OnboardingRouter.Consts.domainError, code: OnboardingRouter.Consts.defaultError, userInfo: nil))
            }
            
            let info = Mapper<WlanInfo>().map(JSON: responseDictionary)
            completion(info, nil)
        }
    }
    
    func join(_ network: WlanNetwork, password: String?, completion: @escaping (_ error: NSError?) -> ()) {
        
        var parameters = [OnboardingApiManagerConsts.ssidKey: network.ssid]
        
        if let key = password {
            parameters[OnboardingApiManagerConsts.🔑Key] = key
        }
        
        manager.request(OnboardingRouter.post(path: OnboardingApiManagerConsts.joinPath, parameters: parameters as [String : AnyObject])).response { (response) in
        
            guard response.response?.statusCode == 200 else {
                return completion(NSError(domain: OnboardingRouter.Consts.domainError, code: OnboardingRouter.Consts.defaultError, userInfo: nil))
            }
            
            completion(response.error as? NSError)
        }
    }
}
