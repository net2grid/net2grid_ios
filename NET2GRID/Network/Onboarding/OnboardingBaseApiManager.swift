//
//  OnboardingBaseApiManager.swift
//  Ynni
//
//  Created by Bart Blok on 07-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import Foundation
import Alamofire

class OnboardingBaseApiManager {
    
    var request: Alamofire.Request?
    
    let manager: Alamofire.SessionManager = {
        
        let serverTrustPolicies: [String: ServerTrustPolicy] = [
            OnboardingRouter.Consts.baseHost: .disableEvaluation
        ]
        
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = 10
        
        let manager = Alamofire.SessionManager(configuration: configuration,
                                               serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies))
        
        return manager
    }()
    
    func post(path: String, parameters: [String: AnyObject], completion: @escaping (_ response: AnyObject?, _ error: NSError?) -> ()) {
        
        cancelRequest()
        
        request = manager.request(OnboardingRouter.post(path: path, parameters: parameters)).responseJSON { response in
            
            completion(response.result.value as AnyObject?, response.result.error as NSError?)
        }
    }
    
    func get(path: String, completion: @escaping (_ response: AnyObject?, _ error: NSError?) -> ()) {
        
        cancelRequest()
        
        request = manager.request(OnboardingRouter.get(path: path)).responseJSON { (response) in
            
            completion(response.result.value as AnyObject?, response.result.error as NSError?)
        }
    }
    
    func cancelRequest() {
        
        if let request = request {
            
            request.cancel()
            self.request = nil
        }
    }
}
