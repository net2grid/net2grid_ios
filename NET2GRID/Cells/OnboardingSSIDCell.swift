//
//  OnboardingSSIDCell.swift
//  Ynni
//
//  Created by Bart Blok on 01-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import UIKit

class OnboardingSSIDCell: UITableViewCell
{
    static let identifier = "OnboardingSSIDCell"
    
    @IBOutlet weak var ssidLabel: UILabel!
    
    override func awakeFromNib() {
        
        let selectionView = UIView()
        selectionView.backgroundColor = UIColor(hex: 0x1d3342)
        
        selectedBackgroundView = selectionView
    }
}
