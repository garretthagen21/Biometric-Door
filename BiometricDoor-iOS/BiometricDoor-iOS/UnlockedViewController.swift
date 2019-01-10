//
//  UnlockedViewController.swift
//  BiometricDoor-iOS
//
//  Created by Garrett Hagen on 1/9/19.
//  Copyright © 2019 Garrett Hagen. All rights reserved.
//

import Foundation
import UIKit

class UnlockedViewController:UITableViewController{
    
  
    @IBOutlet var tableCells: [UITableViewCell]!
    @IBOutlet weak var lockButton: UIButton!
    
    
    
    var currentSettings:Settings?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func lockPressed(_ sender: Any) {
    
    
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        for cell in tableCells{
            cell.layer.cornerRadius = CGFloat(currentSettings!.cornerRadius)
            
        }
        lockButton.layer.cornerRadius = CGFloat(currentSettings!.cornerRadius)
  }

}
