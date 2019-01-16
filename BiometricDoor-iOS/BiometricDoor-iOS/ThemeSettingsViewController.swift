//
//  ThemeSettingsViewController.swift
//  BiometricDoor-iOS
//
//  Created by Garrett Hagen on 1/15/19.
//  Copyright © 2019 Garrett Hagen. All rights reserved.
//

import Foundation
import UIKit

class ThemeSettingsViewController:UIViewController,UINavigationControllerDelegate,UIImagePickerControllerDelegate{

var currentSettings:Settings?
    
    
@IBOutlet weak var backgroundImage: UIImageView!
@IBOutlet weak var backgroundBlurSwitch: UISwitch!
@IBOutlet weak var keypadBlurSwitch: UISwitch!
@IBOutlet weak var darkModeSwitch: UISwitch!
@IBOutlet weak var editImageButton: UIButton!
@IBOutlet weak var headerLabel: UILabel!
    
override func viewDidLoad() {
    super.viewDidLoad()
}
override func viewDidAppear(_ animated: Bool) {
    editImageButton.layer.cornerRadius = CGFloat(currentSettings!.cornerRadius)
    headerLabel.layer.cornerRadius = CGFloat(currentSettings!.cornerRadius)
    backgroundBlurSwitch.isOn = !currentSettings!.hideBlurBackground
    keypadBlurSwitch.isOn = !currentSettings!.hideBlurItems
    editImageButton.setBackgroundImage(currentSettings!.backgroundImage, for: UIControl.State.normal)
    backgroundImage.image = currentSettings!.backgroundImage
    darkModeSwitch.isOn = currentSettings!.darkMode
}
    
    
    @IBAction func editImageButtonPressed(_ sender: Any) {
        let photoChoiceMenu = UIAlertController(title: nil, message:"Choose Photo Source", preferredStyle: .actionSheet)
        
        photoChoiceMenu.addAction(UIAlertAction(title: "Camera", style: .default, handler:{ (UIAlertAction) in
            self.doImagePicking(sourceChoice:"Camera")
            
        }))
        photoChoiceMenu.addAction(UIAlertAction(title: "Photo Library", style: .default, handler:{ (UIAlertAction) in
            self.doImagePicking(sourceChoice:"PhotoLib")
        }))
        photoChoiceMenu.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (UIAlertAction) in
            self.dismiss(animated:true)
        }))
        
        self.present(photoChoiceMenu,animated:true)
        
    }
   
    
    func doImagePicking(sourceChoice:String){
        let imageChoice = UIImagePickerController()
        imageChoice.delegate = self
        if sourceChoice == "Camera" { imageChoice.sourceType = UIImagePickerController.SourceType.camera }
        else { imageChoice.sourceType = UIImagePickerController.SourceType.photoLibrary }
        
        imageChoice.allowsEditing = false
        self.present(imageChoice,animated:true)
    }

    private func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
            editImageButton.setBackgroundImage(image, for: UIControl.State.normal)
        }

    }
    @IBAction func doneButtonPressed(_ sender: Any) {
    currentSettings!.hideBlurBackground = !backgroundBlurSwitch.isOn
    currentSettings!.hideBlurItems = !keypadBlurSwitch.isOn
    currentSettings!.darkMode = darkModeSwitch.isOn
    currentSettings!.backgroundImage = editImageButton!.currentBackgroundImage ?? currentSettings!.backgroundImage
    self.dismiss(animated:true)
}
    
    
}
