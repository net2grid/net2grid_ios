//
//  MenuViewController.swift
//  Ynni
//
//  Created by Bart Blok on 21-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {

    @IBOutlet weak var onboardingButton: UIButton!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        onboardingButton.setTitle("menu-onboarding".localized, for: .normal)
    }

    
    @IBAction func onboardingTap() {
        
        let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
        let viewController: OnboardingConnectNetworkViewController? = storyboard.instantiateInitialViewController() as? OnboardingConnectNetworkViewController
        viewController?.reconnectMode = true
        
        let navigationController = UINavigationController(rootViewController: viewController!)
        navigationController.isNavigationBarHidden = true
        
        present(navigationController, animated: true, completion: nil)
    }
}
