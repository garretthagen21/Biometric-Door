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

    
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var backgroundBlurSwitch: UISwitch!
    @IBOutlet weak var keypadBlurSwitch: UISwitch!
    @IBOutlet weak var darkModeSwitch: UISwitch!
    @IBOutlet weak var editImageButton: UIButton!
    @IBOutlet weak var headerLabel: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        editImageButton.layer.cornerRadius = CGFloat(Settings.cornerRadius)
        headerLabel.layer.cornerRadius = CGFloat(Settings.cornerRadius)
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        backgroundBlurSwitch.isOn = !Settings.hideBlurBackground
        keypadBlurSwitch.isOn = !Settings.hideBlurItems
        editImageButton.setBackgroundImage(Settings.backgroundImage, for: UIControl.State.normal)
        backgroundImage.image = Settings.backgroundImage
        darkModeSwitch.isOn = Settings.darkMode
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
        
        imageChoice.allowsEditing = true
        present(imageChoice,animated:true)
    }
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        // let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
                editImageButton.setBackgroundImage(image, for: UIControl.State.normal)
                Settings.backgroundImage = image
                print("Edited Image Set!")
        }
        else if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
               editImageButton.setBackgroundImage(image, for: UIControl.State.normal)
                Settings.backgroundImage = image
               print("Original Image Set!")
        } else{
               print("Something went wrong with the image")
        }
        dismiss(animated:true,completion:nil)
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        Settings.hideBlurBackground = !backgroundBlurSwitch.isOn
        Settings.hideBlurItems = !keypadBlurSwitch.isOn
        Settings.darkMode = darkModeSwitch.isOn
        // Settings.backgroundImage = editImageButton!.currentBackgroundImage ?? Settings.backgroundImage
        self.dismiss(animated:true)
    }
    
}
// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}
