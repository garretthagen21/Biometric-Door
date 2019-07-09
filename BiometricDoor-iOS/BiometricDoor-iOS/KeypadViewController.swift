

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
    var newPassword:[Int] = []
    var countDownTimer:Timer?
    var elapsedTime:Double = 0.0
    
    /*enum UIState
    {
        case locked
        case unlocked
        case changePassword
        
    }
    
    func drawUIState(state: UIState)
    {
        switch(state)
        {
            .locked:
                for number in keypadNumbers { number.isHidden = false }
                backgroundBlur.isHidden = currentSettings!.hideBlurBackground
                unlockMenu?.dismiss(animated: true, completion: nil)
                lockStatusImage.image = UIImage(named: "icons8-lock-filled-100")
                if currentEntry.count == currentSettings!.masterPassword.count { drawBubbles(type:"red") }
                else { drawBubbles(type:"") }
            
            .unlocked:
            .cleared:
            .passwordChange(message:String):
            
            
            
            
        default:
            
            
        }
        
    }*/
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        
        
        //Blurs should be opposite
        var keypadEffect = UIBlurEffect(style: .dark)
        var backgroundEffect = UIBlurEffect(style: .light)
        
        if currentSettings!.darkMode{
            backgroundEffect = UIBlurEffect(style: .dark)
            keypadEffect = UIBlurEffect(style: .light)
        }
        
        // Bluetooth & Keypad
        for blur in blurViews{
            blur.layer.cornerRadius = CGFloat(currentSettings!.cornerRadius)
            blur.effect = keypadEffect
            blur.isHidden = currentSettings!.hideBlurItems
        }
        
        backgroundBlur.effect = backgroundEffect
        
        if !currentSettings!.isLocked{
            displayUnlockActionSheet(_sender: self)
            startTimer()
        }
        
        reloadView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        endTimer()
    }

    
    @objc func reloadView() {
        
        serial.delegate = self
        
        // Check bluetooth status
        if serial.isReady {
            bluetoothImage.image = UIImage(named: "bluetoothgreen")
            bluetoothLabel.text="Connected"
            bluetoothLabel.textColor=UIColor.green
        }
        else{
            currentSettings?.isLocked = true
            bluetoothImage.image = UIImage(named: "bluetoothred")
            bluetoothLabel.text="Disconnected"
            bluetoothLabel.textColor=UIColor.red
            serial.startScan()
            Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(KeypadViewController.scanTimeOut), userInfo: nil, repeats: false)
        }
        
        
        //UI Stuff
        if currentSettings!.isLocked {
            lockStatusImage.isHidden = false
            changePasswordLabel.isHidden = true
            backgroundBlur.isHidden = currentSettings!.hideBlurBackground
            lockStatusImage.image = UIImage(named: "icons8-lock-filled-100")
            backgroundImage.image = currentSettings!.backgroundImage
            
            // Set change password mode to disabled and end any active timer
            changePasswordMode = false
            endTimer()
            
            for number in keypadNumbers { number.isHidden = false }
           
            unlockMenu?.dismiss(animated: true, completion: nil)
         
            if currentEntry.count == currentSettings!.masterPassword.count { drawBubbles(type:"red") }
            else { drawBubbles(type:"") }
        }
        else{
            if !changePasswordMode{
                lockStatusImage.isHidden = false
                changePasswordLabel.isHidden = true
                backgroundBlur.isHidden = !currentSettings!.hideBlurBackground
                backgroundImage.image = currentSettings!.backgroundImage
                lockStatusImage.image = UIImage(named: "icons8-unlock-filled-100")

                drawBubbles(type:"green")
                for number in keypadNumbers { number.isHidden = true }
    
            }
            else
            {
                endTimer()  // Pause any active timers
                lockStatusImage.isHidden = true
                changePasswordLabel.isHidden = false
                backgroundBlur.isHidden = !currentSettings!.hideBlurBackground
                backgroundImage.image = UIImage(named:"blackbackground")
                lockStatusImage.image = UIImage(named: "icons8-unlock-filled-100")
                
                drawBubbles(type: "")
                for number in keypadNumbers { number.isHidden = false }
                
            }
           
            
        }
        
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
    
/***** PASSWORD VERIFICATION FUNCTIONS ******/
    
   /* func changePassword(turnOn:Bool){
        if turnOn{
            changePasswordMode = true
            for number in keypadNumbers { number.isHidden = false }
            backgroundImage.image = UIImage(named:"blackbackground")
            lockStatusImage.isHidden = true
            changePasswordLabel.isHidden = false
            changePasswordLabel.text = "Enter Current Password"
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
            newPassword = ""
        }
        
    }*/
    
    /* This is only called when the password count is valid */
    func handlePasswordChangeProcedure(){
        if(passConfirmCount == 0){
            if currentSettings?.masterPassword.elementsEqual(currentEntry) ?? false{
                changePasswordLabel.text = "Enter New Password"
                drawBubbles(type: "green")
                passConfirmCount+=1
            }
            else{ drawBubbles(type: "red")}
        }
        else if(passConfirmCount == 1){
            changePasswordLabel.text = "Confirm New Password"
            newPassword = currentEntry
            passConfirmCount+=1
        }
        else if(passConfirmCount == 2){
            if(newPassword.elementsEqual(currentEntry)){
                currentSettings!.masterPassword = newPassword
                changePasswordMode = false
                let alert = UIAlertController(title: "Success", message: "Password successfully changed to \(newPassword)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default, handler: { action -> Void
                    in
                    self.displayUnlockActionSheet(_sender: self)
                    self.startTimer()
                    self.reloadView()
                    alert.dismiss(animated: true, completion: nil)
                }))
                present(alert, animated: true, completion: nil)
            }
            else{
                passConfirmCount-=1
                changePasswordLabel.text = "Passwords do not match!\nPlease try again."
                drawBubbles(type: "red")
            }
        }
    }
   
    @IBAction func keypadButtonPressed(_ sender: UIButton) {
        if !serial.isReady {
            oneOptionAlert(title:"Not Connected",message:"Not connected to Door Lock.",option: "Dismiss")
            reloadView()
            return
        }
        
        
        if(sender.tag == 10){  //10 is tag for backspace
            if(!currentEntry.isEmpty){ currentEntry.remove(at: currentEntry.count-1) }
        }
        else{
            currentEntry.append(sender.tag)
            if(currentEntry.count == currentSettings!.masterPassword.count){
                drawBubbles(type: "")
                handlePassword()
                currentEntry = []
                return // Let the functions called from handlePassword handle reloading the view
            }
        }
        reloadView()
    }
    
    
    func handlePassword(){
       
        if(!changePasswordMode){
            if currentSettings!.masterPassword.elementsEqual(currentEntry){ doUnlock() }
            else{ doLock() }
        }
        else{
            handlePasswordChangeProcedure()
        }
    }
   
    
//***** UNLOCK/LOCK FUNCTIONS *****//
    
    func displayUnlockActionSheet(_sender: Any){
       
        
        unlockMenu = UIAlertController(title: nil, message:"Door Unlocked", preferredStyle: .actionSheet)
        
        unlockMenu!.addAction(UIAlertAction(title: "🗝   Change Password", style: .default, handler:{ (UIAlertAction) in
            // Reset the procedure
            self.changePasswordMode = true
            self.passConfirmCount = 0
            self.newPassword = []
            self.changePasswordLabel.text = "Enter Current Password"
            self.reloadView()
            
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
        startTimer()
        
        if(currentSettings!.isLocked) { // Double check to avoid stacking action sheets on top of eachother
            displayUnlockActionSheet(_sender: self)
        }
        currentSettings!.isLocked = false
        reloadView()
    }
  
    
    func doLock(){
        serial.sendMessageToDevice("L")
        endTimer()
        changePasswordMode = false
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
    
    func startTimer()
    {
        if(currentSettings!.timerOn && countDownTimer == nil) {
            countDownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(KeypadViewController.updateTimer), userInfo: nil, repeats: true)
        }
    }
    
    func endTimer(){
        if countDownTimer != nil{
            elapsedTime = 0
            timerProgress.setProgress(0.0,animated:true)
            countDownTimer!.invalidate()
            countDownTimer = nil
        }
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
        //if targetPeripheral != nil{ return }
        
        if (peripheral.name == "DoorLock" || peripheral.name == "DSD TECH"){
            targetPeripheral = peripheral
            serial.stopScan()
            serial.connectToPeripheral(targetPeripheral!)
            bluetoothLabel.text = "Connecting..."
            Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(KeypadViewController.connectTimeOut), userInfo: nil, repeats: false)
        }
        reloadView()
    }
    
    /****** ALERT FUNCTIONS ******/
    
    func oneOptionAlert(title: String,message: String,option: String){
        let alert = UIAlertController(title: title, message: message , preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: option, style: UIAlertAction.Style.default, handler: { action -> Void in alert.dismiss(animated: true, completion: nil) }))
        present(alert, animated: true, completion: nil)
    }

}

