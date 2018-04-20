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
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController: EntryViewController? = storyboard.instantiateViewController(withIdentifier: EntryViewController.storyboardIdentifier) as? EntryViewController
        viewController?.reconnectMode = true
        
        let navigationController = UINavigationController(rootViewController: viewController!)
        navigationController.isNavigationBarHidden = true
        
        present(navigationController, animated: true, completion: nil)
    }
}
