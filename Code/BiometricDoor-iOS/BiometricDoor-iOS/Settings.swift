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
    var darkMode:Bool
    var cornerRadius:Float
    var masterPassword:[Int]
    var backgroundImage:UIImage
    var timerOn:Bool
    var timerMinutes:Double
    var isLocked:Bool
    let encryptionKey:[UInt8] = [7, 198, 228, 92, 25, 238, 64, 88, 248, 172, 139, 32, 50, 14, 3, 227, 200, 217, 94, 191, 74, 175, 54, 156, 243, 73, 171, 179, 86, 113, 19, 254, 195, 105, 117, 244, 13, 83, 40, 99, 241, 108, 89, 216, 159, 119, 29, 106, 49, 141, 174, 38, 101, 116, 251, 47, 250, 242, 48, 127, 124, 114, 78, 125, 10, 219, 240, 178, 67, 196, 226, 16, 230, 5, 176, 134, 24, 142, 20, 181, 118, 34, 59, 56, 21, 81, 97, 223, 132, 208, 168, 205, 150, 166, 235, 123, 211, 109, 201, 151, 220, 212, 111, 26, 90, 37, 136, 79, 154, 222, 197, 252, 33, 161, 165, 206, 55, 234, 214, 96, 82, 53, 193, 239, 204, 157, 115, 190, 98, 46, 177, 66, 188, 255, 58, 173, 135, 247, 221, 210, 41, 229, 231, 43, 194, 131, 112, 253, 103, 233, 68, 100, 93, 126, 232, 35, 144, 62, 147, 57, 169, 224, 180, 36, 153, 15, 187, 71, 160, 70, 143, 146, 69, 60, 11, 27, 44, 140, 199, 225, 128, 104, 61, 76, 63, 130, 152, 95, 203, 17, 249, 1, 162, 75, 218, 65, 192, 246, 237, 2, 186, 22, 213, 51, 87, 163, 182, 183, 102, 167, 18, 149, 85, 138, 164, 245, 45, 42, 72, 4, 215, 129, 202, 39, 80, 158, 145, 6, 30, 77, 120, 52, 209, 122, 133, 8, 184, 236, 12, 91, 189, 170, 84, 23, 9, 28, 155, 185, 148, 110, 207, 107, 31, 137, 0, 121]

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
    
    // TODO: Get this working
   /* func encryptMessage(messageString:String) -> [UInt8]
    {

        for char in messageString.utf8
        {
           let charIndex = UInt8(encryptionKey.firstIndex(of: char))
            encryptedBytes.append(charIndex)
        }
        
        
    }
    
    func decryptMessage(messageBytes:[UInt8]) -> String
    {
        
        
        
    }*/
    
}
