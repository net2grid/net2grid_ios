//
//  OnboardingJoinNetworkViewController.swift
//  Ynni
//
//  Created by Bart Blok on 07-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class OnboardingJoinNetworkViewController: UIViewController
{
    @IBOutlet weak var waitingView: UIView!
    @IBOutlet weak var activityIndicatorView: NVActivityIndicatorView!
    
    @IBOutlet weak var connectedView: UIView!
    
    @IBOutlet weak var connectedLabel: UILabel!
    @IBOutlet weak var waitingLabel: UILabel!
    
    fileprivate var network: WlanNetwork?
    fileprivate var password: String?
    
    fileprivate var joinAttemptCount = 0
    fileprivate var infoAttemptCount = 0
    
    override func viewDidLoad() {
        
        waitingLabel.text = "onboarding-join-title".localized
        connectedLabel.text = "onboarding-join-connected".localized
        
        activityIndicatorView.startAnimating()
        
        connectedView.isHidden = true;
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        joinNetwork()
    }
    
    func setNetwork(_ network: WlanNetwork, password: String?){
        
        self.network = network
        self.password = password
    }
    
    fileprivate func reportConnectionLost(){
        
        ToastHelper.error("general-error-connection-lost".localized, inView: view)
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    fileprivate func joinNetwork() {
        
        guard joinAttemptCount < OnboardingConstants.joinRetryCount else {

            self.reportConnectionLost()
            return
        }
        
        joinAttemptCount += 1
        log.info("Joining network \(network!.ssid) attempt \(joinAttemptCount)")
        
        OnboardingApiManager.sharedManger.join(network!, password: password) { error in
            
            guard error == nil else {
                
                log.error("Error joining network: " + (error?.description ?? ""))
                self.joinNetwork()
                
                return
            }
            
            log.info("Successfully joined network, getting info...")
            
            self.checkInfo()
        }
    }
    
    @objc fileprivate func checkInfo() {
        
        infoAttemptCount += 1
        log.info("Info Check attempt number: \(infoAttemptCount)")
        
        let apiManager = OnboardingApiManager.sharedManger
        apiManager.info { info, error in
            
            if info == nil || error != nil {
                
                log.error("Received info error: " + (error?.description ?? ""))
                
                if self.infoAttemptCount >= OnboardingConstants.joinRetryCount {
                    self.reportConnectionLost()
                }
                else {
                    self.checkInfo()
                }
                
                return
            }
            
            log.info("Info Check success after number of attempts: \(self.infoAttemptCount)")
            
            PersistentHelper.storeWlanInfo(info!)
            self.showConnected()
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
}
