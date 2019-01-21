

import UIKit
import Foundation
import CoreBluetooth
import QuartzCore



final class KeypadViewController: UIViewController, UITextFieldDelegate, BluetoothSerialDelegate {
    
   
    
    @IBOutlet weak var timerProgress: UIProgressView!
    @IBOutlet var changePasswordLabel: UILabel!
    @IBOutlet weak var lockStatusImage: UIImageView!
    @IBOutlet var bubbleEntries: [UIImageView]!
  
    @IBOutlet var keypadNumbers: [UIButton]!
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
    var countDownTimer:Timer?
    var elapsedTime:Double = 0.0
    
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
        applyCurrentSettings()         //This method provides a somewhat hacky approach to maintaining the appropriate scene after returning from unlock action
    }
    func applyCurrentSettings(){
       
        
        backgroundImage.image = currentSettings!.backgroundImage
        
        //Blurs should be opposite
        var keypadEffect = UIBlurEffect(style: .dark)
        var backgroundEffect = UIBlurEffect(style: .light)
        
        if currentSettings!.darkMode{
            backgroundEffect = UIBlurEffect(style: .dark)
            keypadEffect = UIBlurEffect(style: .light)
        }
        
        //Bluetooth & Keypad
        for blur in blurViews{
            blur.layer.cornerRadius = CGFloat(currentSettings!.cornerRadius)
            blur.effect = keypadEffect
            blur.isHidden = currentSettings!.hideBlurItems
        }
        
        
        //Background
        backgroundBlur.effect = backgroundEffect
        if currentSettings!.isLocked{
            backgroundBlur.isHidden = currentSettings!.hideBlurBackground
        }
        else{
            backgroundBlur.isHidden = !currentSettings!.hideBlurBackground
            displayUnlockActionSheet(_sender: self)
        }
        
        reloadView()
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
        
        
        //UI Stuff
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
    
    
    
    
   
    
/***** PASSWORD VERIFICATION FUNCTIONS ******/
    
    func changePassword(turnOn:Bool){
        if turnOn{
            changePasswordMode = true
            for number in keypadNumbers { number.isHidden = false }
            //backgroundBlur.isHidden = currentSettings!.hideBlurBackground
            backgroundImage.image = UIImage(named:"blackbackground")
            lockStatusImage.isHidden = true
            changePasswordLabel.isHidden = false
            changePasswordLabel.text = "Type Current Password"
            drawBubbles(type:"empty")
            passConfirmCount = 0
        }
        else{
            changePasswordMode = false
            for number in keypadNumbers { number.isHidden = true }
            lockStatusImage.isHidden = false
            changePasswordLabel.isHidden = true
            passConfirmCount = 0
            backgroundImage.image = currentSettings!.backgroundImage
            //backgroundBlur.isHidden = !currentSettings!.hideBlurBackground
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
            self.performSegue(withIdentifier: "FingerprintSegue", sender: self)
           
        }))
        
        unlockMenu!.addAction(UIAlertAction(title: "⏰   Timer Settings", style: .default, handler:{ (UIAlertAction) in
            self.performSegue(withIdentifier: "TimerSegue", sender: self)
            
        }))
        unlockMenu!.addAction(UIAlertAction(title: "🌇   Customize Theme", style: .default, handler:{ (UIAlertAction) in
                self.performSegue(withIdentifier: "ThemeSegue", sender: self)
        }))
        
        unlockMenu!.addAction(UIAlertAction(title: "🔒   Lock Door", style: .destructive, handler:{ (UIAlertAction) in
            self.doLock()
            self.reloadView()
            //self.dismiss(animated:true,completion:nil)
        }))
        
      
        self.present(unlockMenu!, animated: true, completion: nil)
        
     
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if (segue.identifier == "TimerSegue") {
            let nextVC = segue.destination as! TimerSettingsViewController
            nextVC.currentSettings = currentSettings
        }
        else if (segue.identifier == "ThemeSegue") {
            let nextVC = segue.destination as! ThemeSettingsViewController
            nextVC.currentSettings = currentSettings
        }
        else if (segue.identifier == "FingerprintSegue") {
            let nextVC = segue.destination as! ManageFingerprintsViewController
            nextVC.currentSettings = currentSettings
            nextVC.selectedPeripheral = targetPeripheral
        }
    }
    
    func doUnlock(){
        serial.sendMessageToDevice("U")

       
        if(currentSettings!.timerOn && countDownTimer == nil) {
        countDownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(KeypadViewController.updateTimer), userInfo: nil, repeats: true)
        }
        if(currentSettings!.isLocked) {
            displayUnlockActionSheet(_sender: self)
            for number in keypadNumbers { number.isHidden = true }
        }
        backgroundBlur.isHidden = !currentSettings!.hideBlurBackground
        currentSettings!.isLocked = false
        reloadView()
    }
  
    
    func doLock(){
        serial.sendMessageToDevice("L")
   
        if countDownTimer != nil { endTimer() }
        if changePasswordMode { changePassword(turnOn:false)}
        if(!currentSettings!.isLocked){
            unlockMenu!.dismiss(animated: true, completion: nil)
            for number in keypadNumbers { number.isHidden = false }
        }
        backgroundBlur.isHidden = currentSettings!.hideBlurBackground
        currentSettings!.isLocked = true
        reloadView()
        
    }
    

    @objc func updateTimer(){
        elapsedTime += 1
        let timeRemaining = currentSettings!.timerMinutes*60 - elapsedTime
        
        print("\nLocking in \(timeRemaining)")
        timerProgress.setProgress(Float(elapsedTime/(currentSettings!.timerMinutes * 60)), animated: true)
        
        if(timeRemaining <= 0 && !currentSettings!.isLocked){
           doLock()
        }
    }
    
    func endTimer(){
        elapsedTime = 0
        timerProgress.setProgress(0.0,animated:true)
        countDownTimer!.invalidate()
        countDownTimer = nil
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

