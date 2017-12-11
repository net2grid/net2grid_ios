//
//  OnboardingRouter.swift
//  Ynni
//
//  Created by Bart Blok on 07-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import Foundation
import Alamofire

enum OnboardingRouter: URLRequestConvertible {
    
    struct Consts {
        
        static let baseHost = "10.5.6.1"
        static let baseUrlString = "http://" + baseHost
        
        static let domainError = "RouterDomainError"
        static let defaultError = 1
        
        static let jsonCodingValue = "application/json"
        static let jsonContentTypeKey = "Content-Type"
        static let jsonAcceptKey = "Accept"
    }
    
    case get(path: String)
    case post(path: String, parameters: [String: AnyObject])
    
    func asURLRequest() -> URLRequest {
        
        var tempUrl: Foundation.URL?
        let path: String = {
            switch self {
            case .get(let path):
                tempUrl = Foundation.URL(string: OnboardingRouter.Consts.baseUrlString)
                return path
            case .post(let path, _):
                tempUrl = Foundation.URL(string: OnboardingRouter.Consts.baseUrlString)
                return path
            }
        }()
        
        let URL = tempUrl!
        var urlRequest = URLRequest(url: URL.appendingPathComponent(path))
        
        // set header fields
        urlRequest.setValue(OnboardingRouter.Consts.jsonCodingValue,
                            forHTTPHeaderField: OnboardingRouter.Consts.jsonContentTypeKey)
        urlRequest.setValue(OnboardingRouter.Consts.jsonCodingValue,
                            forHTTPHeaderField: OnboardingRouter.Consts.jsonAcceptKey)
        
        switch self {
        case .get(_):
            urlRequest.httpMethod = "GET"
            break
            
        case .post(_, let parameters):
            urlRequest.httpMethod = "POST"
            do {
                urlRequest.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: JSONSerialization.WritingOptions())
            } catch {
                // No-op
            }
            break
        }
        
        return urlRequest
    }
}
