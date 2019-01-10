

import UIKit
import Foundation
import CoreBluetooth
import QuartzCore



final class KeypadViewController: UIViewController, UITextFieldDelegate, BluetoothSerialDelegate {
    
    @IBOutlet weak var lockStatusImage: UIImageView!
    @IBOutlet var bubbleEntries: [UIImageView]!
    @IBOutlet weak var keypadNumbers: UIButton!
    @IBOutlet weak var bluetoothImage: UIImageView!
    @IBOutlet weak var bluetoothLabel: UILabel!
    @IBOutlet var blurViews: [UIVisualEffectView]!
    @IBOutlet weak var backgroundBlur: UIVisualEffectView!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    var currentEntry:[Int] = []
    var targetPeripheral:CBPeripheral?
    var currentSettings:Settings?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        serial = BluetoothSerial(delegate: self)
        currentSettings = Settings()                //Get default settings
         NotificationCenter.default.addObserver(self, selector: #selector(KeypadViewController.reloadView), name: NSNotification.Name(rawValue: "reloadStartViewController"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        backgroundImage.image = currentSettings!.backgroundImage
        backgroundBlur.isHidden = currentSettings!.hideBlurBackground
        
        for blur in blurViews{
            blur.layer.cornerRadius = CGFloat(currentSettings!.cornerRadius)
            blur.isHidden = currentSettings!.hideBlurItems
        }
        reloadView()
    }
    
    func displayUnlockActionSheet(_sender: Any){
     
        let unlockMenu = UIAlertController(title: nil, message:"Door Unlocked", preferredStyle: .actionSheet)
        
        unlockMenu.addAction(UIAlertAction(title: "🗝   Change Password", style: .default, handler:{ (UIAlertAction) in

            self.displayUnlockActionSheet(_sender: self)
        }))
        unlockMenu.addAction(UIAlertAction(title: "✋🏻   Manage Fingerprints", style: .default, handler:{ (UIAlertAction) in
     
           self.displayUnlockActionSheet(_sender: self)
        }))
       
        unlockMenu.addAction(UIAlertAction(title: "⏰   Timer Settings", style: .default, handler:{ (UIAlertAction) in
            self.displayUnlockActionSheet(_sender: self)
        }))
        unlockMenu.addAction(UIAlertAction(title: "🌇   Customize Theme", style: .default, handler:{ (UIAlertAction) in
           self.displayUnlockActionSheet(_sender: self)
        }))
      
        unlockMenu.addAction(UIAlertAction(title: "🔒   Lock Door", style: .destructive, handler:{ (UIAlertAction) in
            self.doLock()
             self.reloadView()
            //self.dismiss(animated:true,completion:nil)
        }))
        
        // 5
        self.present(unlockMenu, animated: true, completion: nil)
       
        
        
    }
    
    @IBAction func keypadButtonPressed(_ sender: UIButton) {
        
        if(sender.tag == 10){  //10 is tag for backspace
            if(!currentEntry.isEmpty){ currentEntry.remove(at: currentEntry.count-1) }
        }
        else{
            currentEntry.append(sender.tag)
            if(currentEntry.count == currentSettings!.masterPassword.count){
                checkPassword()
                currentEntry = []
                return
            }
        }
        reloadView()
    }
    
    func checkPassword(){
        var entryString:String = ""
        
        for entry in currentEntry{ entryString += String(entry) }
        if entryString == currentSettings!.masterPassword{ doUnlock() }
        else{ doLock() }
    }
    
    func doUnlock(){
        serial.sendMessageToDevice("U")
        lockStatusImage.image = UIImage(named: "icons8-unlock-filled-100")
        for i in 0...self.bubbleEntries.count-1{ self.bubbleEntries[i].image = UIImage(named:"icons8-circle-filled-green-100") }
        backgroundBlur.isHidden = !currentSettings!.hideBlurBackground
        currentSettings!.isLocked = false
        //self.performSegue(withIdentifier: "UnlockedSegue", sender: nil)/
        displayUnlockActionSheet(_sender: self)
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if (segue.identifier == "UnlockedSegue") {
            let nextVC = segue.destination as! UnlockedViewController
            nextVC.currentSettings = currentSettings
            
        }
    }
    
    func doLock(){
        serial.sendMessageToDevice("L")
        lockStatusImage.image = UIImage(named: "icons8-lock-filled-100")
        for i in 0...self.bubbleEntries.count-1{ self.bubbleEntries[i].image = UIImage(named:"icons8-circle-filled-red-100") }
        backgroundBlur.isHidden = currentSettings!.hideBlurBackground
        currentSettings!.isLocked = true
    }
    
    // Should be called 10s after we've begun scanning
   
    @objc func reloadView() {
       
        serial.delegate = self
       
        //Check bluetooth status
        if serial.isReady {
            bluetoothImage.image = UIImage(named: "bluetoothgreen")
            bluetoothLabel.text="Connected"
            bluetoothLabel.textColor=UIColor.green
        }
        else{
            bluetoothImage.image = UIImage(named: "bluetoothred")
            bluetoothLabel.text="Disconnected"
            bluetoothLabel.textColor=UIColor.red
            if serial.centralManager.state != .poweredOn {
                title = "Bluetooth Off"
                return
            }
            serial.startScan()
            Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(KeypadViewController.scanTimeOut), userInfo: nil, repeats: false)
        }
        
        
        //Show lock status
        if(currentSettings!.isLocked){ lockStatusImage.image = UIImage(named: "icons8-lock-filled-100") }
        else{ lockStatusImage.image = UIImage(named: "icons8-unlock-filled-100") }
        
        //Draw the bubble entries
        for i in 0...bubbleEntries.count-1{
            if(i <= currentEntry.count-1){
                bubbleEntries[i].image = UIImage(named:"icons8-circle-filled-100")
            }
            else{
                bubbleEntries[i].image = UIImage(named:"icons8-circle-outline-100")
            }
        }
    
    }

   
    
    func serialDidReceiveString(_ message: String) {
        switch(message){
        
        case "UNLOCK":
            doUnlock()
        case "LOCK":
            doLock()
        default:
            print("\nInvalid messsage: \(message)")
        }
    }
    
    @objc func scanTimeOut(){
        serial.stopScan()
    }
    
    // Should be called 10s after we've begun connecting
    @objc func connectTimeOut() {
        if let _ = serial.connectedPeripheral {
            return
        }
    }
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        targetPeripheral = nil
        reloadView()
    }
    func serialDidConnect(_peripheral: CBPeripheral){
        reloadView()
    }
    func serialIsReady(_ peripheral: CBPeripheral) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadStartViewController"), object: self)
        dismiss(animated: true, completion: nil)
        reloadView()
    }
    
    func serialDidChangeState() {
        if serial.centralManager.state != .poweredOn {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadStartViewController"), object: self)
            dismiss(animated: true, completion: nil)
        }
        reloadView()
    }
    
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?) {
        
        //print(peripheral.name)
        if targetPeripheral != nil{ return }
        
        if (peripheral.name == "DoorLock" || peripheral.name == "DSD TECH"){
            targetPeripheral = peripheral
            serial.stopScan()
            serial.connectToPeripheral(targetPeripheral!)
            bluetoothLabel.text = "Connecting..."
            Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(KeypadViewController.connectTimeOut), userInfo: nil, repeats: false)
        }
        reloadView()
    }

}

