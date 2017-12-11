//
//  OnboardingChooseWiFiViewController.swift
//  Ynni
//
//  Created by Bart Blok on 01-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import UIKit

class OnboardingChooseWiFiViewController: UIViewController
{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    
    fileprivate var networkRefreshTimer: Timer?
    public var networks: [WlanNetwork]?
    
    fileprivate var selectedNetwork: WlanNetwork?
    fileprivate var selectedPassword: String?
    
    override func viewDidLoad() {
        
        titleLabel.text = "onboarding-choose-wifi-title".localized
        
        tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 20.0, right: 0.0)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        if let timer = networkRefreshTimer, timer.isValid {
            timer.invalidate()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        startRefreshing()
    }
    
    func selectNetwork(network: WlanNetwork, password: String?){
        
        selectedNetwork = network
        selectedPassword = password
        
        performSegue(withIdentifier: "ChooseWiFiJoinNetworkSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "ChooseWiFiJoinNetworkSegue", let destination = segue.destination as? OnboardingJoinNetworkViewController, let network = selectedNetwork {
            
            destination.setNetwork(network, password: selectedPassword)
        }
    }
}

// MARK: Networks refreshing
extension OnboardingChooseWiFiViewController {
    
    fileprivate func startRefreshing() {
        
        networkRefreshTimer = Timer.scheduledTimer(timeInterval: OnboardingConstants.networksRefreshInterval, target: self, selector: #selector(refreshNetworks), userInfo: nil, repeats: true)
        networkRefreshTimer?.fire()
    }
    
    @objc fileprivate func refreshNetworks() {
        
        log.info("Refreshing networks..")
        
        OnboardingApiManager.sharedManger.scan { (networks, response, error) in
            
            guard let networks = networks, error == nil else {
                
                log.error("Error loading networks: " + (error?.description ?? ""))
                return
            }
            
            log.info("Networks loaded")
            
            self.networks = networks
            self.tableView.reloadData()
        }
    }
}

// MARK: UITableViewDataSource
extension OnboardingChooseWiFiViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let networks = networks else {
            return 0
        }
        
        return networks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: OnboardingSSIDCell.identifier, for: indexPath) as! OnboardingSSIDCell
        guard let networks = networks else {
            return cell
        }
        
        let network = networks[indexPath.row]
        cell.ssidLabel.text = network.ssid
        
        return cell
    }
}

// MARK: UITableViewDelegate
extension OnboardingChooseWiFiViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let networks = networks else {
            return
        }
        
        let network = networks[indexPath.row]
        
        if network.encryption {
            
            let alertController = UIAlertController(title: network.ssid, message: "onboarding-choose-wifi-password-title".localized, preferredStyle: .alert)
            alertController.addTextField(configurationHandler: { (textField) in
                
                textField.placeholder = "onboarding-choose-wifi-password-placeholder".localized
                textField.isSecureTextEntry = true
            })
            
            alertController.addAction(UIAlertAction(title: "general-cancel".localized, style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "general-ok".localized, style: .default, handler: { (action) in
                
                let textField = alertController.textFields?.first!
                let password = textField?.text
                
                if let password = password, !password.isEmpty {
                
                    self.selectNetwork(network: network, password: textField?.text)
                }
                else {
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }))
            
            present(alertController, animated: true, completion: nil)
        }
        else {
            
            selectNetwork(network: network, password: nil)
        }
    }
}
