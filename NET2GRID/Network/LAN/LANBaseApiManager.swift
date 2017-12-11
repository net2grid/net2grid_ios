//
//  LANBaseApiManager.swift
//  Ynni
//
//  Created by Bart Blok on 16-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import Foundation
import Alamofire

class LANBaseApiManager {
    
    var request: Alamofire.Request?
    
    let manager: Alamofire.SessionManager = {
        
        let serverTrustPolicies: [String: ServerTrustPolicy] = [
            LANRouter.Consts.baseHost: .disableEvaluation
        ]
        
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = 10
        
        let manager = Alamofire.SessionManager(configuration: configuration,
                                               serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies))
        
        return manager
    }()
    
    func post(path: String, parameters: [String: AnyObject], completion: @escaping (_ response: AnyObject?, _ error: NSError?) -> ()) {
        
        request = manager.request(LANRouter.post(path: path, parameters: parameters)).responseJSON { response in
            
            completion(response.result.value as AnyObject?, response.result.error as NSError?)
        }
    }
    
    func get(path: String, completion: @escaping (_ response: AnyObject?, _ error: NSError?) -> ()) {
        
        log.debug("Requesting " + (LANRouter.get(path: path).asURLRequest().url?.absoluteString ?? ""))
        
        request = manager.request(LANRouter.get(path: path)).responseJSON { (response) in
            
            log.debug("Request DONE " + (LANRouter.get(path: path).asURLRequest().url?.absoluteString ?? "") + " error: " + (response.result.error?.localizedDescription ?? "none"))
            
            completion(response.result.value as AnyObject?, response.result.error as NSError?)
        }
    }
}
