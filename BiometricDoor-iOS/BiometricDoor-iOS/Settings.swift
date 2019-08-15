//
//  Settings.swift
//  BiometricDoor-iOS
//
//  Created by Garrett Hagen on 1/9/19.
//  Copyright © 2019 Garrett Hagen. All rights reserved.
//

import Foundation
import UIKit

// Note: These are only saved in memory so they will be set back to default when the app terminates. This should not be a problem, however, because the app should always be running
class Settings {
    
    var hideBlurItems:Bool
    var hideBlurBackground:Bool
    var darkMode:Bool
    var cornerRadius:Float
    var masterPassword:[Int]
    var backgroundImage:UIImage
    var timerOn:Bool
    var timerMinutes:Double
    var isLocked:Bool


    //Default settings
    init(){
        self.hideBlurItems = true
        self.hideBlurBackground = true
        self.darkMode = false
        self.masterPassword = [1,2,3,4,5,6]
        self.backgroundImage = UIImage(named: "galaxy-iphone-wallpaper-20")!
        self.timerOn = false
        self.timerMinutes = 3
        self.isLocked = true
        self.cornerRadius = 12.5
       
    }
    

    
}
