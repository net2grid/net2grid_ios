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
    
    var bluetoothManager: BluetoothOnboardingManager?
    var bluetoothDevice: BluetoothDevice?
    var bluetoothMode = false
    
    fileprivate var joinAttemptCount = 0
    fileprivate var infoAttemptCount = 0
    
    fileprivate var infoTimeoutExpired = false
    fileprivate var connected = false
    
    fileprivate var infoExpireTimer: Timer?
    fileprivate var infoRetryTimer: Timer?
    
    var reconnectMode: Bool = false
    
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
    
    fileprivate func reportJoinError(){
        
        ToastHelper.error("onboarding-join-error".localized, inView: navigationController!.view)
        self.navigationController?.popViewController(animated: true)
    }
    
    fileprivate func confirmCheckSmartBridge(){
        
        let alertController = UIAlertController(title: "onboarding-join-check-smartbridge-online".localized, message: nil, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "general-yes-capital".localized, style: .default, handler: { (action) in
            
            self.startInfoCalls()
        }))
        
        alertController.addAction(UIAlertAction(title: "general-no-capital".localized, style: .default, handler: { (action) in
            
            self.reportConnectionLost();
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func joinNetwork() {
        
        guard joinAttemptCount < OnboardingConstants.joinRetryCount else {

            self.reportConnectionLost()
            return
        }
        
        joinAttemptCount += 1
        log.info("Joining network \(network!.ssid) attempt \(joinAttemptCount)")
        
        
        if bluetoothMode, let manager = bluetoothManager {
            
            manager.executeJoin(ssid: network!.ssid, password: password) { error in
                
                guard error == nil else {
                    
                    if let joinError = error as? BluetoothOnboardingManager.JoinError, case .errorResponse = joinError  {
                        
                        log.error("Join responded with error")
                        self.reportJoinError()
                    }
                    else {
                        
                        log.error("Error joining network: " + (error?.localizedDescription ?? ""))
                        self.joinNetwork()
                    }
                    
                    return
                }
                
                log.info("Successfully joined network via BlueTooth, resuming")
                
                PersistentHelper.storeSsid(self.network!.ssid)
                
                self.connected = true
                self.showConnected()
            }
        }
        else {
            
            OnboardingApiManager.sharedManger.join(network!, password: password) { error in
                
                guard error == nil else {
                    
                    log.error("Error joining network: " + (error?.description ?? ""))
                    self.joinNetwork()
                    
                    return
                }
                
                log.info("Successfully joined network via WiFi, getting info...")
                
                self.startInfoCalls()
            }
        }
    }
    
    fileprivate func startInfoCalls(){
        
        infoAttemptCount = 0;
        infoTimeoutExpired = false
        
        infoExpireTimer = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(infoExpired), userInfo: nil, repeats: false)
        
        checkInfo()
    }
    
    @objc fileprivate func infoExpired(){
        
        if let retryTimer = infoExpireTimer {
            retryTimer.invalidate()
            infoExpireTimer = nil
        }
        
        infoTimeoutExpired = true
        
        // Failed
        confirmCheckSmartBridge()
    }
    
    @objc fileprivate func checkInfo() {
        
        infoAttemptCount += 1
        log.info("Info Check attempt number: \(infoAttemptCount)")
        
        let apiManager = OnboardingApiManager.sharedManger
        apiManager.info { info, error in
            
            if self.infoTimeoutExpired || self.connected {
                return
            }
            
            if info == nil || error != nil {
                
                log.warning("Received info error: " + (error?.description ?? ""))
                log.info("Info Check success after number of attempts: \(self.infoAttemptCount)")
                
                if let expireTimer = self.infoExpireTimer {
                    expireTimer.invalidate()
                    self.infoExpireTimer = nil;
                }
                
                PersistentHelper.storeSsid(self.network!.ssid)
                
                self.connected = true
                self.showConnected()
            }
            else {
                
                log.info("Info call still available, retrying in 10 sec...")
                
                self.infoRetryTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.checkInfo), userInfo: nil, repeats: false)
            }
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
        
        if reconnectMode {
            
            dismiss(animated: true, completion: nil)
        }
        else {
            
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let viewController = mainStoryboard.instantiateViewController(withIdentifier: LiveUsageViewController.storyboardIdentifier)
            
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
