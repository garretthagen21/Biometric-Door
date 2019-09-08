//
//  TimerSettingsViewController.swift
//  BiometricDoor-iOS
//
//  Created by Garrett Hagen on 1/14/19.
//  Copyright © 2019 Garrett Hagen. All rights reserved.
//

import Foundation
import UIKit


class TimerSettingsViewController:UIViewController{
    
    var currentSettings:Settings?
    
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var timerMinutesLabel: UILabel!
    @IBOutlet weak var timerSwitch: UISwitch!
    @IBOutlet weak var stepper: UIStepper!

    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        headerLabel.layer.cornerRadius = CGFloat(Settings.cornerRadius)
        stepper.wraps = true
     
    }
    override func viewWillAppear(_ animated: Bool) {
        timerSwitch.isOn = Settings.timerOn
        stepper.value = Settings.timerMinutes
        timerMinutesLabel.text = "\(stepper.value) minutes"
        backgroundImage.image = Settings.backgroundImage
    }

    
    @IBAction func valueDidChange(_ sender: Any) {
         timerMinutesLabel.text = "\(stepper.value) minutes"
    }
    
  

    @IBAction func doneButtonPressed(_ sender: Any) {
        Settings.timerOn = timerSwitch.isOn
        Settings.timerMinutes = stepper.value
        self.dismiss(animated:true,completion: nil)
    }
    
    
    
    
}
