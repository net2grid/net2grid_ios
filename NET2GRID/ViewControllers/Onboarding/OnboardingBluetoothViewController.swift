//
//  OnboardingBluetoothViewController.swift
//  Ynni
//
//  Created by Bart Blok on 08-03-18.
//  Copyright © 2018 Wittig. All rights reserved.
//

import UIKit
import SwiftyGif

class OnboardingBluetoothViewController: UIViewController {
    
    static let storyboardIdentifier = "OnboardingBluetoothViewController"
    
    private static let wifiSgue = "BluetoothChooseWiFiSegue";
    private static let connectNetworkSegue = "BluetoothConnectNetworkSegue"
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var noButton: UIButton!
    
    var bluetoothManager: BluetoothOnboardingManager!
    var bluetoothDevice: BluetoothDevice!
    
    var reconnectMode = false

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let gif = UIImage(gifName: "bluetooth_animation.gif")
        iconImageView.setGifImage(gif)
        
        titleLabel.text = "onboarding-bluetooth-title".localized

        yesButton.setTitle("general-yes-capital".localized, for: .normal)
        noButton.setTitle("general-no-capital".localized, for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        closeButton.isHidden = !reconnectMode
        
        deviceNameLabel.text = bluetoothDevice.name
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == OnboardingBluetoothViewController.wifiSgue, let destination = segue.destination as? OnboardingChooseWiFiViewController {
            
            destination.reconnectMode = reconnectMode
            destination.bluetoothManager = bluetoothManager
            destination.bluetoothDevice = bluetoothDevice
            destination.bluetoothMode = true
        }
        else if segue.identifier == OnboardingBluetoothViewController.connectNetworkSegue, let destination = segue.destination as? OnboardingConnectNetworkViewController {
            
            destination.reconnectMode = reconnectMode
            
            bluetoothManager.disconnectSmartBridge()
        }
    }
    
    @IBAction func closeTap() {
        
        if let manager = bluetoothManager {
            manager.disconnectSmartBridge()
        }
        
        dismiss(animated: true, completion: nil)
    }
}
