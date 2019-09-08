//
//  ManageFingerprintsViewController.swift
//  BiometricDoor-iOS
//
//  Created by Garrett Hagen on 1/15/19.
//  Copyright © 2019 Garrett Hagen. All rights reserved.
//

import Foundation
import CoreBluetooth
import QuartzCore
import UIKit


class ManageFingerprintsViewController:UIViewController,BluetoothSerialDelegate{
    
    enum UIState
    {
        case idle
        case active
    }
    
    
    var selectedPeripheral:CBPeripheral?
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var fingerPrintIDLabel: UILabel!
    @IBOutlet weak var fingerPrintNameLabel: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var statusUpdateLabel: UILabel!
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var commandSegmentControl: UISegmentedControl!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    var activeFingerDict: [String:String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        headerLabel.layer.cornerRadius = CGFloat(Settings.cornerRadius)
        goButton.layer.cornerRadius = CGFloat(Settings.cornerRadius)
        stepper.wraps = true
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        serial.delegate = self
        activeFingerDict = Settings.fingerPrintIDs
        backgroundImage.image = Settings.backgroundImage
        drawUIState(state: .idle)
        stepperPressed(self)
    }
 

    func drawUIState(state: UIState)
    {
        switch(state)
        {
        case .idle:
            statusUpdateLabel.text = ""
            goButton.isHidden = false
            statusUpdateLabel.isHidden = true
            doneButton.isEnabled = true
            stepper.isEnabled = true
            progressView.isHidden = true
        case .active:
            goButton.isHidden = true
            statusUpdateLabel.isHidden = false
            doneButton.isEnabled = false
            stepper.isEnabled = false
            progressView.isHidden = false
        }
    }
    
    @IBAction func stepperPressed(_ sender: Any) {
       
        let id = "\(Int(stepper.value))"
        let name = Settings.fingerPrintIDs[id]

        if name == nil{
            fingerPrintIDLabel.text = "✅   ID: \(id)"
            fingerPrintNameLabel.text = ""
        }
        else{
            fingerPrintIDLabel.text = "⛔️   ID: \(id)"
            fingerPrintNameLabel.text = "\(name ?? "")"
        }
     
    }
    
    
    @IBAction func goButtonPressed(_ sender: Any) {
        let id = String(Int(stepper.value))
        
      
        switch(commandSegmentControl.selectedSegmentIndex){
            case 0:
                self.promptName(completion:{
                    (name) in
                    
                    if name != "" {
                        self.activeFingerDict[id] = name
                        serial.sendMessageToDevice("A")
                        self.beginProcedure(id: id)
                        
                    }
                    else{
                        self.oneOptionAlert(title: "Oops!", message: "The name entry cannot be empty!", option: "Ok")
                    }
                   
                    
                })
          
            case 1:
                self.activeFingerDict.removeValue(forKey: id)
                serial.sendMessageToDevice("D")
                beginProcedure(id: id)
            case 2:
                self.activeFingerDict = [:]
                serial.sendMessageToDevice("C")
                beginProcedure(id: id)
            default:
                return
        }
        
     
    
    }
    
    func beginProcedure(id:String)
    {
        progressView.setProgress(0.0, animated: false)
        drawUIState(state: .active)
        serial.sendMessageToDevice(id)
    }
    @IBAction func doneButtonPressed(_ sender: Any) {
        self.dismiss(animated: true)
    }
   
    
    func serialDidReceiveString(_ message: String) {
        
        let incomingString = message.components(separatedBy: ":")
        if incomingString.count != 2{
            return
        }
        guard let incomingCommand:String = incomingString[0] else {return}
        guard let incomingData:String = incomingString[1] else { return }
        
        switch(incomingCommand){
            
        case "ADD":
            showAddProgress(data: incomingData)
        case "DEL":
            showDeleteProgress(data: incomingData)
        case "CLEAR":
            showClearProgress(data: incomingData)
        default:
            print("\nInvalid messsage: \(message)")
        }
    }
    
    
    
    func promptName(completion: @escaping (_ nameEntry: String) -> Void)
    {
        let alert = UIAlertController(title: "Who dis be?", message: "Please enter your full name.", preferredStyle: .alert)
        
     
        alert.addTextField { (textField) in
            textField.text = ""
        }
        
        alert.addAction(UIAlertAction(title: "Go", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            completion(textField?.text ?? "")
        }))
        
        self.present(alert, animated: true, completion: nil)
    
    }
    
    func showAddProgress(data:String){
        switch(data){
        case "place":
            statusUpdateLabel.text = "Place Finger on Fingerprint Scanner"
        case "remove":
            statusUpdateLabel.text = "Remove Finger from Fingerprint Scanner"
        case "succ":
            finalizeProcedure(success: true)
            progressView.setProgress(1.0,animated: true)
            oneOptionAlert(title: "Success", message: "Successfully added fingerprint for ID: \(Int(stepper.value))", option: "Dismiss")
            drawUIState(state: .idle)
        case "fail":
            finalizeProcedure(success: false)
            oneOptionAlert(title: "Fail", message: "Failed to add fingerprint for ID: \(Int(stepper.value))", option: "Dismiss")
            drawUIState(state: .idle)
        default:
            let progress = Float32(data) ?? 0.0
            progressView.setProgress(progress/6.0,animated: true)
        }
        
    }
    func finalizeProcedure(success: Bool)
    {
        if success{
            Settings.fingerPrintIDs = self.activeFingerDict
        }
        
        self.activeFingerDict = Settings.fingerPrintIDs
        stepperPressed(self)
        
    }
    func showDeleteProgress(data:String){
        switch(data){
       
        case "succ":
            finalizeProcedure(success: true)
            progressView.setProgress(1.0,animated: true)
            oneOptionAlert(title: "Success", message: "Successfully deleted fingerprint for ID: \(Int(stepper.value))", option: "Dismiss")
            drawUIState(state: .idle)
        case "fail":
            finalizeProcedure(success: false)
            oneOptionAlert(title: "Fail", message: "Failed to delete fingerprint for ID: \(Int(stepper.value))", option: "Dismiss")
            drawUIState(state: .idle)
        default:
            let progress = Float32(data) ?? 0.0
            progressView.setProgress(progress/1.0,animated: true)
        }
        
    }
    func showClearProgress(data:String){
        switch(data){
            
        case "succ":
            finalizeProcedure(success: true)
            progressView.setProgress(1.0,animated: true)
            oneOptionAlert(title: "Success", message: "Successfully cleared all fingerprints from Fingerprint Scanner", option: "Dismiss")
            drawUIState(state: .idle)
        case "fail":
            finalizeProcedure(success: false)
            statusUpdateLabel.text = "Failed to clear all fingerprints from Fingerprint Scanner"
            drawUIState(state: .idle)
        default:
            let progress = Float32(data) ?? 0.0
            progressView.setProgress(progress/1.0,animated: true)
        }
        
    }
    
    func serialDidChangeState() {
        self.dismiss(animated:true)
    }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
         self.dismiss(animated:true)
    }
    
    
    func oneOptionAlert(title: String,message: String,option: String){
        let alert = UIAlertController(title: title, message: message , preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: option, style: UIAlertAction.Style.default, handler: { action -> Void in alert.dismiss(animated: true, completion: nil) }))
        present(alert, animated: true, completion: nil)
    }
    
    
    
    
    
    
}
