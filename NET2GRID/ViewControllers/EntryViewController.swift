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
    private static let maxInfoAttempts = 1
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var activityIndicatorView: NVActivityIndicatorView!
    
    fileprivate var bluetoothManager: BluetoothOnboardingManager!
    
    fileprivate var infoCheckAttemptsCounter = 0
    fileprivate var foundBluetoothDevice: BluetoothDevice?
    fileprivate var wlanInfo: WlanInfo?
    
    fileprivate var wlanInfoSucceeded: Bool?
    fileprivate var bluetoothDeviceFound: Bool?
    
    var reconnectMode = false
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        messageLabel.text = "entry-message".localized

        activityIndicatorView.startAnimating()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        infoCheckAttemptsCounter = 0
        bluetoothDeviceFound = nil
        wlanInfoSucceeded = nil
        foundBluetoothDevice = nil
        
        bluetoothManager = BluetoothOnboardingManager()
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        if !reconnectMode {
            checkInfo()
        }
        else {
            wlanInfoSucceeded = false
        }
        
        checkBluetooth()
    }
    
    fileprivate func determineNextStep(){
        
        var viewController: UIViewController?
        
        if let wifiSuccess = wlanInfoSucceeded, wifiSuccess {
            
            viewController = storyboard?.instantiateViewController(withIdentifier: LiveUsageViewController.storyboardIdentifier)
        }
        else if let wifiSuccess = wlanInfoSucceeded, let bluetoothSuccess = bluetoothDeviceFound {
            
            let onboardingStoryboard = UIStoryboard(name: "Onboarding", bundle: nil)
            
            if !wifiSuccess && !bluetoothSuccess {
                
                if let connectNetworkViewController = onboardingStoryboard.instantiateViewController(withIdentifier: OnboardingConnectNetworkViewController.storyboardIdentifier) as? OnboardingConnectNetworkViewController {
                    
                    connectNetworkViewController.reconnectMode = reconnectMode
                    
                    viewController = connectNetworkViewController
                }
            }
            else if bluetoothSuccess {
                
                if let bluetoothViewController = onboardingStoryboard.instantiateViewController(withIdentifier: OnboardingBluetoothViewController.storyboardIdentifier) as? OnboardingBluetoothViewController {
                    
                    bluetoothViewController.bluetoothManager = bluetoothManager
                    bluetoothViewController.bluetoothDevice = foundBluetoothDevice
                    bluetoothViewController.reconnectMode = reconnectMode
                    
                    viewController = bluetoothViewController
                }
            }
        }
        
        if let viewController = viewController {
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    @objc fileprivate func checkInfo() {
        
        infoCheckAttemptsCounter += 1
        
        log.info("Info Check attempt number: \(infoCheckAttemptsCounter)")
        
        LANApiManager.sharedManger.info { info, error in
            
            if info == nil || error != nil {
                
                log.error("Received info error: " + (error?.description ?? ""))
                
                if self.infoCheckAttemptsCounter >= EntryViewController.maxInfoAttempts {
                    
                    self.wlanInfoSucceeded = false
                    self.determineNextStep()
                }
                else {
                    self.checkInfo()
                }
            
                return
            }
            
            log.info("Info Check success after number of attempts: \(self.infoCheckAttemptsCounter)")
            
            
            self.wlanInfo = info
            self.wlanInfoSucceeded = true
            
            PersistentHelper.storeSsid(info!.clientSsid)
            self.determineNextStep()
        }
    }
    
    fileprivate func checkBluetooth() {
        
        bluetoothManager.discoverSmartBridge { (device: BluetoothDevice?, error: Error?) in
            
            var success = true
            
            if let error = error {
                
                log.error("Error discovering Bluetooth device " + error.localizedDescription);
                success = false
            }
            else if device == nil {
                
                log.error("No Bluetooth device received");
                success = false
            }
            
            if success {
                log.info("Found bluetooth device")
            }
            
            self.foundBluetoothDevice = device
            self.bluetoothDeviceFound = success
            
            self.determineNextStep()
        }
    }
}
