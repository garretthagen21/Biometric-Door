//
//  Settings.swift
//  BiometricDoor-iOS
//
//  Created by Garrett Hagen on 1/9/19.
//  Copyright © 2019 Garrett Hagen. All rights reserved.
//

import Foundation
import UIKit


class Settings {

    var hideBlurItems:Bool
    var hideBlurBackground:Bool
    var cornerRadius:Float
    var masterPassword:String
    var backgroundImage:UIImage
    var timerOn:Bool
    var timerMinutes:Int
    var isLocked:Bool

    //Default settings
    init(){
        self.hideBlurItems = true
        self.hideBlurBackground = true
        self.masterPassword = "521769"
        self.backgroundImage = UIImage(named: "galaxy-iphone-wallpaper-20")!
        self.timerOn = false
        self.timerMinutes = 3
        self.isLocked = true
        self.cornerRadius = 12.5
    }
    
}
