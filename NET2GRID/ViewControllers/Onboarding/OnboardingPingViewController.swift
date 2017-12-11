//
//  OnboardingWaitViewController.swift
//  Ynni
//
//  Created by Bart Blok on 01-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class OnboardingPingViewController: UIViewController
{
    @IBOutlet weak var waitingView: UIView!
    @IBOutlet weak var activityIndicatorView: NVActivityIndicatorView!
    
    @IBOutlet weak var connectedView: UIView!
    
    @IBOutlet weak var connectedLabel: UILabel!
    @IBOutlet weak var waitingLabel: UILabel!
    
    var infoResult: WlanInfo?
    
    fileprivate var pingAttemptCount = 0
    fileprivate var networks: [WlanNetwork]?
    
    override func viewDidLoad() {
        
        waitingLabel.text = "onboarding-ping-title".localized
        connectedLabel.text = "onboarding-ping-connected".localized
        
        activityIndicatorView.startAnimating()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        performPing()
    }
    
    fileprivate func performPing() {
        
        pingAttemptCount += 1
        log.info("Starting ping attempt \(pingAttemptCount)...")
        
        OnboardingApiManager.sharedManger.ping { (connected, error) in
            
            guard error == nil else {
                
                log.error("Error during ping: " + (error?.description ?? ""))
                self.handleError()
  
                return;
            }
            
            if let connected = connected, connected {
                
                log.info("Ping result: connected via Ethernet")
                
                if let info = self.infoResult {
                    PersistentHelper.storeWlanInfo(info)
                }
                
                self.showConnected()
            }
            else {
                
                log.info("Ping result: not connected via Ethernet")
                self.scanNetworksAndProceed()
            }
        }
    }
    
    fileprivate func scanNetworksAndProceed(){
        
        log.info("Scanning networks")
        
        OnboardingApiManager.sharedManger.scan { (networks, response, error) in
            
            guard let networks = networks else {
                
                log.error("Error scanning networks: " + (error?.description ?? ""))
                self.handleError()
                
                return
            }
            
            log.info("Networks loaded")
            
            self.networks = networks
            self.performSegue(withIdentifier: "PingChooseWiFiSegue", sender: self)
        }
    }
    
    fileprivate func handleError(){
        
        if self.pingAttemptCount >= OnboardingConstants.pingRetryCount {
            
            ToastHelper.error("general-error-connection-lost".localized, inView: view)
            self.navigationController?.popToRootViewController(animated: true)
        }
        else {
            
            self.performPing()
        }
    }
    
    fileprivate func showConnected(){
        
        UIView.animate(withDuration: 0.2, animations: {
            
            self.waitingView.alpha = 0.0;
            
        }) { (completed) in
            
            self.connectedView.alpha = 0.0;
            self.connectedView.isHidden = false;
            
            Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(self.proceedToLive), userInfo: nil, repeats: false)
            
            UIView.animate(withDuration: 0.2, animations: {
                
                self.connectedView.alpha = 1.0;
            })
        }
    }
    
    func proceedToLive(){
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = mainStoryboard.instantiateViewController(withIdentifier: LiveUsageViewController.storyboardIdentifier)
        
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "PingChooseWiFiSegue" {
            
            if let destination = segue.destination as? OnboardingChooseWiFiViewController {
                
                destination.networks = networks
            }
        }
    }
}
