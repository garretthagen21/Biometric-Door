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
    
    var selectedPeripheral:CBPeripheral?
    var currentSettings:Settings?
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var fingerPrintIDLabel: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var statusUpdateLabel: UILabel!
    
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var commandSegmentControl: UISegmentedControl!

    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewDidAppear(_ animated: Bool) {
        headerLabel.layer.cornerRadius = CGFloat(currentSettings!.cornerRadius)
        goButton.layer.cornerRadius = CGFloat(currentSettings!.cornerRadius)
        stepper.wraps = true
        fingerPrintIDLabel.text = "Finger ID:  \(Int(stepper.value))"
        backgroundImage.image = currentSettings!.backgroundImage
        drawNonExecuting()
        serial.delegate = self
    }
    
    @IBAction func stepperPressed(_ sender: Any) {
       fingerPrintIDLabel.text = "Finger ID:  \(Int(stepper.value))"
    }
    
    
    @IBAction func goButtonPressed(_ sender: Any) {
       let id = String(Int(stepper.value))
        drawExecuting()
        
        
        switch(commandSegmentControl.selectedSegmentIndex){
            case 0:
                serial.sendMessageToDevice("ADD")
            case 1:
                serial.sendMessageToDevice("DEL")
            case 2:
                serial.sendMessageToDevice("CLEAR")
            default:
            return
        }
        
        serial.sendMessageToDevice(id)
    
    }
    @IBAction func doneButtonPressed(_ sender: Any) {
        self.dismiss(animated: true)
    }
    func drawExecuting(){
        goButton.isHidden = true
        statusUpdateLabel.isHidden = false
        doneButton.isEnabled = false
        stepper.isEnabled = false
        progressView.isHidden = false
    }
    
    func drawNonExecuting(){
        statusUpdateLabel.text = ""
        goButton.isHidden = false
        statusUpdateLabel.isHidden = true
        doneButton.isEnabled = true
        stepper.isEnabled = true
        progressView.setProgress(0.0, animated: true)
        progressView.isHidden = true
    }
    
    func serialDidReceiveString(_ message: String) {
        
        let incomingString = message.components(separatedBy: ":")
        if incomingString.count != 2{
            print("Invalid data string: ")
            print(message)
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
    
    func showAddProgress(data:String){
        switch(data){
        case "place":
                statusUpdateLabel.text = "Place Finger on Fingerprint Scanner"
        case "remove":
                statusUpdateLabel.text = "Remove Finger from Fingerprint Scanner"
        case "succ":
             oneOptionAlert(title: "Success", message: "Successfully added fingerprint for ID: \(Int(stepper.value))", option: "Dismiss")
            drawNonExecuting()
        case "fail":
            statusUpdateLabel.text = "Failed to add fingerprint for ID: \(stepper.value)"
            drawNonExecuting()
        default:
            let progress = Float32(data) ?? 0.0
            progressView.setProgress(progress/6.0,animated: true)
        }
        
    }
    
    func showDeleteProgress(data:String){
        switch(data){
       
        case "succ":
            oneOptionAlert(title: "Success", message: "Successfully deleted fingerprint for ID: \(Int(stepper.value))", option: "Dismiss")
            drawNonExecuting()
        case "fail":
            statusUpdateLabel.text = "Failed to delete fingerprint for ID: \(Int(stepper.value))"
            drawNonExecuting()
        default:
            let progress = Float32(data) ?? 0.0
            progressView.setProgress(progress/1.0,animated: true)
        }
        
    }
    func showClearProgress(data:String){
        switch(data){
            
        case "succ":
            oneOptionAlert(title: "Success", message: "Successfully cleared all fingerprints from Fingerprint Scanner", option: "Dismiss")
            drawNonExecuting()
        case "fail":
            statusUpdateLabel.text = "Failed to clear all fingerprints from Fingerprint Scanner"
            drawNonExecuting()
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
