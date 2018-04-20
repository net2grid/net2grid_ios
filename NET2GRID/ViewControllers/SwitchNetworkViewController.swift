//
//  SwitchNetworkViewController.swift
//  Ynni
//
//  Created by Bart Blok on 01-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import UIKit

class SwitchNetworkViewController: UIViewController {
    
    static let storyboardIdentifier = "SwitchNetworkViewController"
    
    struct Consts {
        
        static let checkSSIDInterval = 5.0 as TimeInterval
    }
    
    @IBOutlet weak var currentNetworkLabel: UILabel!
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var wifiSettingsButtonLabel: UILabel!
    
    var checkSSIDTimer: Timer?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        stepsLabel.text = "switch-network-steps".localized
        wifiSettingsButtonLabel.text = "switch-network-wifi-settings".localized
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if let network = WiFiHelper.getCurrentSSID(), let ssid = PersistentHelper.ssid() {
            
            let boldAttributes = [NSFontAttributeName: UIFont(name: "HelveticaNeue-Medium", size: 22.0)!]
            
            let attributedText = NSMutableAttributedString()
            attributedText.append(NSAttributedString(string: "switch-network-current-1".localized + " "))
            attributedText.append(NSAttributedString(string: network, attributes: boldAttributes))
            attributedText.append(NSAttributedString(string: " " + "switch-network-current-2".localized + " "))
            attributedText.append(NSAttributedString(string: ssid, attributes: boldAttributes))
            attributedText.append(NSAttributedString(string: "switch-network-current-3".localized))
            
            currentNetworkLabel.attributedText = attributedText
        }
        else {
            
            currentNetworkLabel.text = "switch-network-current-none".localized;
        }
        
        checkSSIDTimer = Timer.scheduledTimer(timeInterval: Consts.checkSSIDInterval, target: self, selector: #selector(checkNetworkSSID), userInfo: nil, repeats: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func gotoWiFiButtonTapped() {
        
        if let url = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.openURL(url)
        }
    }
    
    func checkNetworkSSID(){
        
        let networkAvailable = WiFiHelper.isOnSmartBridgeNetwork()
        log.info("Network SSID valid: \(networkAvailable)")
        
        if networkAvailable {
            
            dismiss(animated: true, completion: nil)
        }
    }
}
