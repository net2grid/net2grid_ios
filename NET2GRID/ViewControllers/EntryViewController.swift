//
//  EntryViewController.swift
//  Ynni
//
//  Created by Bart Blok on 21-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class EntryViewController: UIViewController {

    static let storyboardIdentifier = "EntryViewController"
    
    @IBOutlet weak var messageLabel: UILabel!
    
    private static let maxInfoAttempts = 1
    
    @IBOutlet weak var activityIndicatorView: NVActivityIndicatorView!
    
    fileprivate var infoCheckAttemptsCounter = 0
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        messageLabel.text = "entry-message".localized

        activityIndicatorView.startAnimating()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        infoCheckAttemptsCounter = 0
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        checkInfo()
    }
    
    fileprivate func reportConnectionAvailable(_ available: Bool){
        
        var viewController: UIViewController?
        
        if available {
            
            viewController = storyboard?.instantiateViewController(withIdentifier: LiveUsageViewController.storyboardIdentifier)
        }
        else {
            
            let liveStoryboard = UIStoryboard(name: "Onboarding", bundle: nil)
            viewController = liveStoryboard.instantiateInitialViewController()
        }
        
        navigationController?.pushViewController(viewController!, animated: true)
    }
    
    @objc fileprivate func checkInfo() {
        
        infoCheckAttemptsCounter += 1
        
        log.info("Info Check attempt number: \(infoCheckAttemptsCounter)")
        
        LANApiManager.sharedManger.info { info, error in
            
            if info == nil || error != nil {
                
                log.error("Received info error: " + (error?.description ?? ""))
                
                if self.infoCheckAttemptsCounter >= EntryViewController.maxInfoAttempts {
                    self.reportConnectionAvailable(false)
                }
                else {
                    self.checkInfo()
                }
            
                return
            }
            
            log.info("Info Check success after number of attempts: \(self.infoCheckAttemptsCounter)")
            
            PersistentHelper.storeWlanInfo(info!)
            
            self.reportConnectionAvailable(true)
        }
    }
}
