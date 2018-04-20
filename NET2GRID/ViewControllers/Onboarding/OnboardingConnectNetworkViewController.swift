//
//  OnboardingConnectNetworkViewController.swift
//  Ynni
//
//  Created by Bart Blok on 01-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import UIKit

class OnboardingConnectNetworkViewController: UIViewController
{
    static let storyboardIdentifier = "OnboardingConnectNetworkViewController"
    
    fileprivate var checkTimer: Timer?
    fileprivate var infoCheckAttemptsCounter = 0
    fileprivate var infoResult: WlanInfo?
    
    @IBOutlet weak var infoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var wifiSettingsButtonLabel: UILabel!
    
    var reconnectMode: Bool = false
    
    override func viewDidLoad() {
        
        titleLabel.text = "onboarding-connect-network-title".localized
        wifiSettingsButtonLabel.text = "onboarding-connect-network-wifi-settings".localized
        
        infoImageView.image = UIImage(named: "image-onboarding-qr".localized)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3.0
        paragraphStyle.paragraphSpacing = 6.0
        paragraphStyle.alignment = .center
        
        let defaultAttributes = [NSParagraphStyleAttributeName: paragraphStyle,
                                 NSFontAttributeName: UIFont(name: Fonts.helveticaLight, size: 17.0)]
        
        let italicAttributes = [NSParagraphStyleAttributeName: paragraphStyle,
                                NSFontAttributeName: UIFont(name: Fonts.helveticaLightOblique, size: 17.0)]
        
        let boldAttributes = [NSParagraphStyleAttributeName: paragraphStyle,
                                NSFontAttributeName: UIFont(name: Fonts.helveticaBold, size: 17.0)]
        
        let descriptionString = NSMutableAttributedString(string: "", attributes: defaultAttributes)
        descriptionString.append(NSAttributedString(string: "onboarding-connect-network-description-1".localized, attributes: defaultAttributes))
        descriptionString.append(NSAttributedString(string: "onboarding-connect-network-description-2".localized, attributes: defaultAttributes))
        
        let statement3 = NSMutableAttributedString(string: "onboarding-connect-network-description-3".localized, attributes: defaultAttributes)
        statement3.addAttributes(boldAttributes, range: (statement3.string as NSString).range(of: "sbwf-"))
        descriptionString.append(statement3)
        
        descriptionString.append(NSAttributedString(string: "onboarding-connect-network-description-3-uppercase".localized, attributes: italicAttributes))
        
        let statement4 = NSMutableAttributedString(string: "onboarding-connect-network-description-4".localized, attributes: defaultAttributes)
        statement4.addAttributes(boldAttributes, range: (statement4.string as NSString).range(of: "sbwf-"))
        descriptionString.append(statement4)
        
        descriptionString.append(NSAttributedString(string: "onboarding-connect-network-description-4-uppercase".localized, attributes: italicAttributes))
        descriptionString.append(NSAttributedString(string: "onboarding-connect-network-description-5".localized, attributes: defaultAttributes))
        
        descriptionLabel.adjustsFontSizeToFitWidth = true
        descriptionLabel.attributedText = descriptionString
        descriptionLabel.lineBreakMode = .byTruncatingTail
        
        let closeImage = reconnectMode ? UIImage(named: "icon_cross_nav_white") : UIImage(named: "icon_back_white")
        closeButton.setImage(closeImage, for: .normal)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        startChecking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        checkTimer?.invalidate()
        checkTimer = nil;
    }
    
    fileprivate func startChecking() {
        
        if let timer = checkTimer, timer.isValid {
            timer.invalidate()
        }
        
        checkTimer = Timer.scheduledTimer(timeInterval: OnboardingConstants.checkInfoInterval, target: self, selector: #selector(checkInfo), userInfo: nil, repeats: true)
        checkTimer?.fire()
    }
    
    fileprivate func reportConnectionAvailable(_ available: Bool){
        
        if let timer = self.checkTimer, timer.isValid {
            timer.invalidate()
        }
        
        var viewController: UIViewController?
        
        if available {
            
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            viewController = mainStoryboard.instantiateViewController(withIdentifier: LiveUsageViewController.storyboardIdentifier)
            
            navigationController?.pushViewController(viewController!, animated: true)
        }
        else {
            
            self.performSegue(withIdentifier: "ConnectNetworkPingSegue", sender: self)
        }
    }
    
    @IBAction func closeTap() {
        
        if(reconnectMode){
            dismiss(animated: true, completion: nil)
        }
        else{
            navigationController?.popViewController(animated: true)
        }
    }
    
    @objc fileprivate func checkInfo() {
        
        infoCheckAttemptsCounter += 1
        log.info("Info Check attempt number: \(infoCheckAttemptsCounter)")
        
        let apiManager = OnboardingApiManager.sharedManger
        apiManager.info { info, error in
            
            if let error = error {
                log.error("Received info error: " + error.description)
            } else {
                log.info("Received info response")
            }
            
            guard let info = info else {
                return
            }
            
            self.infoResult = info
            log.info("Info Check success after number of attempts: \(self.infoCheckAttemptsCounter)")
            
            if info.mode == WlanInfo.Mode.client {
                
                // Client mode, connection available
                PersistentHelper.storeSsid(info.clientSsid)
                self.reportConnectionAvailable(true)
            }
            else {
                self.reportConnectionAvailable(false)
            }
        }
    }

    
    @IBAction func gotoWiFiButtonTapped() {
        
        if let url = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.openURL(url)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "ConnectNetworkPingSegue", let destination = segue.destination as? OnboardingPingViewController {
            
            destination.reconnectMode = reconnectMode
            destination.infoResult = infoResult
        }
    }
}
