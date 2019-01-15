

import UIKit
import Foundation
import CoreBluetooth
import QuartzCore



final class KeypadViewController: UIViewController, UITextFieldDelegate, BluetoothSerialDelegate {
    
    
    @IBOutlet var changePasswordLabel: UILabel!
    
    @IBOutlet weak var lockStatusImage: UIImageView!
    @IBOutlet var bubbleEntries: [UIImageView]!
    @IBOutlet weak var keypadNumbers: UIButton!
    @IBOutlet weak var bluetoothImage: UIImageView!
    @IBOutlet weak var bluetoothLabel: UILabel!
    @IBOutlet var blurViews: [UIVisualEffectView]!
    @IBOutlet weak var backgroundBlur: UIVisualEffectView!
    @IBOutlet weak var backgroundImage: UIImageView!
    var unlockMenu:UIAlertController?
    var currentEntry:[Int] = []
    var targetPeripheral:CBPeripheral?
    var currentSettings:Settings?
    var changePasswordMode = false
    var passConfirmCount = 0
    var newPassword = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        serial = BluetoothSerial(delegate: self)
        currentSettings = Settings()                //Get default settings
         NotificationCenter.default.addObserver(self, selector: #selector(KeypadViewController.reloadView), name: NSNotification.Name(rawValue: "reloadStartViewController"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
 /****** UI FUNCTIONS *****/
    
    override func viewDidAppear(_ animated: Bool) {
        setBackground()         //This method provides a somewhat hacky approach to maintaining the appropriate scene after returning from unlock action sheet
        reloadView()
    }
    func setBackground(){
        backgroundImage.image = currentSettings!.backgroundImage
        
        for blur in blurViews{
            blur.layer.cornerRadius = CGFloat(currentSettings!.cornerRadius)
            blur.isHidden = currentSettings!.hideBlurItems
        }
        
        if currentSettings!.isLocked{
            backgroundBlur.isHidden = currentSettings!.hideBlurBackground
        }
        else{
            backgroundBlur.isHidden = !currentSettings!.hideBlurBackground
            drawBubbles(type: "green")
            displayUnlockActionSheet(_sender: self)
        }
    }
    
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
        
        
        
        if currentSettings!.isLocked {
            lockStatusImage.image = UIImage(named: "icons8-lock-filled-100")
            if currentEntry.count == currentSettings!.masterPassword.count { drawBubbles(type:"red") }
            else { drawBubbles(type:"") }
        }
        else{
            lockStatusImage.image = UIImage(named: "icons8-unlock-filled-100")
            if !changePasswordMode { drawBubbles(type:"green") }
            else{ drawBubbles(type:"") }
        }
        
        if changePasswordMode { changePasswordLabel.isHidden = false }
        else { changePasswordLabel.isHidden = true }
        
        //Draw the bubble entries
       
        
    }
    
    
    
    func drawBubbles(type:String){
        switch(type){
        case "green":
            for i in 0...self.bubbleEntries.count-1{ self.bubbleEntries[i].image = UIImage(named:"icons8-circle-filled-green-100") }
        case "red":
            for i in 0...self.bubbleEntries.count-1{ self.bubbleEntries[i].image = UIImage(named:"icons8-circle-filled-red-100") }
        case "empty":
            for i in 0...self.bubbleEntries.count-1{ self.bubbleEntries[i].image = UIImage(named:"icons8-circle-outline-100") }
        case "filled":
             for i in 0...self.bubbleEntries.count-1{ self.bubbleEntries[i].image = UIImage(named:"icons8-circle-filled-100") }
        default:
            for i in 0...bubbleEntries.count-1{
                if(i <= currentEntry.count-1){
                    bubbleEntries[i].image = UIImage(named:"icons8-circle-filled-100")
                }
                else{
                    bubbleEntries[i].image = UIImage(named:"icons8-circle-outline-100")
                }
            }
        }
    }
    
    func oneOptionAlert(title: String,message: String,option: String){
        let alert = UIAlertController(title: title, message: message , preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: option, style: UIAlertAction.Style.default, handler: { action -> Void in alert.dismiss(animated: true, completion: nil) }))
        present(alert, animated: true, completion: nil)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if (segue.identifier == "TimerSegue") {
            let nextVC = segue.destination as! TimerSettingsViewController
            nextVC.currentSettings = currentSettings
        }
    }
    

    
/***** PASSWORD VERIFICATION FUNCTIONS ******/
    
    func changePassword(turnOn:Bool){
        if turnOn{
            changePasswordMode = true
            backgroundBlur.isHidden = true
            backgroundImage.image = UIImage(named:"blackbackground")
            lockStatusImage.isHidden = true
            changePasswordLabel.isHidden = false
            changePasswordLabel.text = "Type Current Password"
            drawBubbles(type:"empty")
            passConfirmCount = 0
        }
        else{
            changePasswordMode = false
            lockStatusImage.isHidden = false
            changePasswordLabel.isHidden = true
            passConfirmCount = 0
            backgroundImage.image = currentSettings!.backgroundImage
            backgroundBlur.isHidden = false
            newPassword = ""
        }
        
    }
    
    func handlePasswordChangeProcedure(entryString:String){
        if(passConfirmCount == 0){
            var bubbleType = "red"
            if entryString == currentSettings!.masterPassword{
                passConfirmCount+=1
                bubbleType = "green"
                changePasswordLabel.text = "Type New Password"
            }
            drawBubbles(type:bubbleType)
            
        }
        else if(passConfirmCount == 1){
            newPassword = entryString
            passConfirmCount+=1
            changePasswordLabel.text = "Confirm New Password"
        }
        else if(passConfirmCount == 2){
            if(entryString == newPassword){
                currentSettings!.masterPassword = entryString
                changePassword(turnOn:false)
                let alert = UIAlertController(title: "Success", message: "Password successfully changed to \(entryString)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { action -> Void in
        
                    alert.dismiss(animated: true, completion: nil)
                    self.displayUnlockActionSheet(_sender: self)
                    self.drawBubbles(type:"green")
                }))
                present(alert, animated: true, completion: nil)
            }
            else{
                changePasswordLabel.text = "Passwords Do Not Match\nType New Password Again"
                passConfirmCount-=1
            }
        }
    }
   
    @IBAction func keypadButtonPressed(_ sender: UIButton) {
        if !serial.isReady {
            oneOptionAlert(title:"Not Connected",message:"Not connected to Door Lock",option: "Dismiss")
            reloadView()
            return
        }
        if(sender.tag == 10){  //10 is tag for backspace
            if(!currentEntry.isEmpty){ currentEntry.remove(at: currentEntry.count-1) }
        }
        else{
            currentEntry.append(sender.tag)
            if(currentEntry.count == currentSettings!.masterPassword.count){
                drawBubbles(type:"")
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
        
        if(!changePasswordMode){
            if entryString == currentSettings!.masterPassword{ doUnlock() }
            else{ doLock() }
        }
        else{
            handlePasswordChangeProcedure(entryString: entryString)
        }
    }
   
    
//***** UNLOCK/LOCK FUNCTIONS *****//
    
    func displayUnlockActionSheet(_sender: Any){
        
        unlockMenu = UIAlertController(title: nil, message:"Door Unlocked", preferredStyle: .actionSheet)
        
        unlockMenu!.addAction(UIAlertAction(title: "🗝   Change Password", style: .default, handler:{ (UIAlertAction) in
            self.changePassword(turnOn:true)
            //self.displayUnlockActionSheet(_sender: self)
        }))
        unlockMenu!.addAction(UIAlertAction(title: "✋🏻   Manage Fingerprints", style: .default, handler:{ (UIAlertAction) in
            
            self.displayUnlockActionSheet(_sender: self)
        }))
        
        unlockMenu!.addAction(UIAlertAction(title: "⏰   Timer Settings", style: .default, handler:{ (UIAlertAction) in
            self.performSegue(withIdentifier: "TimerSegue", sender: self)
            
        }))
        unlockMenu!.addAction(UIAlertAction(title: "🌇   Customize Theme", style: .default, handler:{ (UIAlertAction) in
            self.currentSettings!.hideBlurItems = !self.currentSettings!.hideBlurItems
            self.setBackground()
            self.displayUnlockActionSheet(_sender: self)
        }))
        
        unlockMenu!.addAction(UIAlertAction(title: "🔒   Lock Door", style: .destructive, handler:{ (UIAlertAction) in
            self.doLock()
            self.reloadView()
            //self.dismiss(animated:true,completion:nil)
        }))
        
        // 5
        self.present(unlockMenu!, animated: true, completion: nil)
        
        
        
    }
    
    func doUnlock(){
        serial.sendMessageToDevice("U")
        //lockStatusImage.image = UIImage(named: "icons8-unlock-filled-100")
        //drawBubbles(type:"green")
        if(currentSettings!.isLocked) { displayUnlockActionSheet(_sender: self) }
        backgroundBlur.isHidden = !currentSettings!.hideBlurBackground
        currentSettings!.isLocked = false
        reloadView()
        
    }
  
    
    func doLock(){
        serial.sendMessageToDevice("L")
        //lockStatusImage.image = UIImage(named: "icons8-lock-filled-100")
        //drawBubbles(type:"red")
        if changePasswordMode { changePassword(turnOn:false)}
        if(!currentSettings!.isLocked){ unlockMenu!.dismiss(animated: true, completion: nil) }
        backgroundBlur.isHidden = currentSettings!.hideBlurBackground
        currentSettings!.isLocked = true
        reloadView()
        
    }
    

   
    
    
    
/****** BLUETOOTH FUNCTIONS ******/
    
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

