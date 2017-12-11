//
//  ToastHelper.swift
//  Ynni
//
//  Created by Bart Blok on 21-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import Foundation
import APESuperHUD

class ToastHelper {
    
    class func error(_ message: String, inView: UIView) {
        
        APESuperHUD.showOrUpdateHUD(icon: UIImage(named: "icon_cross_white")!, message: message, duration: 3.0, presentingView: inView, completion: nil)
    }
    
    class func setup(){
        
        APESuperHUD.appearance.backgroundBlurEffect = .dark
        APESuperHUD.appearance.foregroundColor = UIColor.clear
        APESuperHUD.appearance.iconColor = UIColor.white
        APESuperHUD.appearance.textColor = UIColor.white
        
        APESuperHUD.appearance.iconWidth = 68.0
        APESuperHUD.appearance.iconHeight = 68.0
        
        APESuperHUD.appearance.titleFontName = Fonts.helveticaLightOblique
        APESuperHUD.appearance.titleFontSize = 15.0
        
        APESuperHUD.appearance.messageFontName = Fonts.helveticaLightOblique
        APESuperHUD.appearance.messageFontSize = 15.0
    }
}
