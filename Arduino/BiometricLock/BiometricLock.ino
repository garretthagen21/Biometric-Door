/*************************************************** 
  @author: Garrett Hagen
  @created: 12-15-2018
  @description: Program to handle solenoid lock, fingerprint sensor, button lock, and communicate with Biometric Door iOS app
  @connections:
    
        ARDUINO ---> MODULE
        
        TX ------> HM-10 RX
        RX ------> HM-10 TX
        D2 ------> Fingerprint TX (Green) 
        D3 ------> Fingerprint RX (White)
        D4 ------> Button NC (Blue)
        D5 ------> Button LED (Yellow)
        D6 ------> Lock+ (Red)
        5V ------> HM-10 VCC
        3v3 -----> FP VCC
        
  @contributions: 
  
      This is an example sketch for our optical Fingerprint sensor
    
      Designed specifically to work with the Adafruit BMP085 Breakout 
      ----> http://www.adafruit.com/products/751
    
      These displays use TTL Serial to communicate, 2 pins are required to 
      interface
      Adafruit invests time and resources providing this open source code, 
      please support Adafruit and open-source hardware by purchasing 
      products from Adafruit!
    
      Fingerprint Library and skeleton code fritten by Limor Fried/Ladyada for Adafruit Industries.  
      BSD license, all text above must be included in any redistribution

    
 ****************************************************/

#include <Adafruit_Fingerprint.h>
#include <String.h>
#include <SoftwareSerial.h>

/** Set to true if using the BiometricLock iOS (or other) mobile device. If set to false, the program will just use the fingerprint scanner and button for input.**/
boolean useMobileApp = true;

/** Change this to true to print bluetooth output to serial monitor. Must be set to false otherwise to avoid interference w/ Bluetooth**/
boolean serial_debug = false;

// Fingerprint Sensor
SoftwareSerial fingerSerial(2, 3);
Adafruit_Fingerprint finger = Adafruit_Fingerprint(&fingerSerial);
int overrideCount = 0;  // Once this reaches 3, the door will lock/unlock without waiting for a callback from the BiometricLock App, then it will reset. 
                        // It is intended to serve as a backup mechanism for emergencies or an unexpected app crash

// BLE Communication
int incoming_command;
int current_command = 'X';
long loop_timer;

//Lock Button
int lockButton = 4;
int buttonLED = 5;
int prevButtonStatus = LOW;

// Solenoid Lock
int lockPin = 6;
boolean isLocked = true;    //This should always match lockStatus. Quicker to use boolean than compare string every time
boolean updateConfirmed = false;


void setup()  
{
  
  //Serial and Bluetooth Communication Initialization
  Serial.begin(9600);
  //delay(1000);
  //Serial.print("AT+NAMEDoorLock");
  //delay(1000);

  
  //Fingerprint scanner initialization
  finger.begin(57600); 
  if (finger.verifyPassword() && serial_debug) { 
    if(serial_debug){
    Serial.print("Sensor contains "); 
    finger.getTemplateCount();
    Serial.print(finger.templateCount); 
    Serial.println(" templates");
    }
  }
  else { 
      if(serial_debug){ Serial.println("Did not find fingerprint sensor."); }    //This should never execute 
    }

  //Lock & Button initialization
  pinMode(lockPin,OUTPUT);
  pinMode(buttonLED,OUTPUT);
  pinMode(lockButton,INPUT_PULLUP);
  doLock();
  
}//End setup

void loop()                     // run over and over again
{
   
   //--------READ INCOMING COMMAND TO SEE IF WE SHOULD UNLOCK VIA PASSCODE--------//
    if (Serial.available()){
     incoming_command = Serial.read();
     if(serial_debug){ Serial.println("Bluetooth is ready"); }
        if(isWhitespace(incoming_command) == false){
            current_command = incoming_command;
        if(serial_debug) { Serial.println(current_command); }
     }
    }
    


  //--------CHECK FINGERPRINT SENSOR--------//
  int id = getFingerprintIDez(); 
  int buttonStatus = digitalRead(lockButton);
    
  
   //--------MAKE DECISION--------//
   
   // If useMobileApp == true, Tell the phone we are unlocking/locking, 
   // and the phone will then send 'U'/'L' respectively back to the Arduino, 
   // which will unlock/lock the door. This way the app and arduino will always stay in sync 
   // If useMobileApp == false, simply unlock/lock the door
  if(id != -1 || (buttonStatus == HIGH && prevButtonStatus == LOW)){ 
     overrideCount++;
     if(isLocked) { 
        Serial.print("UNLOCK");
        if(!useMobileApp || overrideCount >= 3){ doUnlock(); }
     }
     else {   
        Serial.print("LOCK");
        if(!useMobileApp || overrideCount >= 3){ doLock(); }
     }
     
  }

  // These commands are sent via Bluetooth from the BiometricLock app, but can also be triggered from the SerialMonitor
  else if(current_command == 'U'){
     doUnlock();
     current_command = 'X';      // Acknowledge we have recieved and executed the command by setting it back to 'X' and waiting for a new command to arrive  
  }
  else if(current_command == 'L'){
     doLock();
     current_command = 'X';   
  }
  else if(current_command == 'A'){
    if(addFingerPrint() == -1){ Serial.print("ADD:fail"); }
    else{ Serial.print("ADD:succ"); }
    current_command = 'X';
  }
  else if(current_command == 'D'){
    if (deleteFingerPrint() == -1){ Serial.print("DEL:fail"); }
    else{ Serial.print("DEL:succ"); }
    current_command = 'X';
  }
  else if(current_command == 'C'){
    finger.emptyDatabase();
    Serial.print("CLEAR:1");
    //delay(1000);
    Serial.print("CLEAR:succ");
    current_command = 'X';
  }
     
  //prevButtonStatus = buttonStatus;  // This allows us to ensure the button was actually clicked and won't trigger an override from being held down for a split second too long

} // End loop



// Unlock door and turn red LED off
void doUnlock(){
   isLocked = false;
   digitalWrite(lockPin,HIGH);
   digitalWrite(buttonLED,LOW);
   overrideCount = 0;
}



//Lock Door and turn red LED on
void doLock(){ 
   isLocked = true;
   digitalWrite(lockPin,LOW);
   digitalWrite(buttonLED,HIGH);
   overrideCount = 0;
}


// Verify/Deny fingerprint using simplified Adafruit example function
int getFingerprintIDez() {
  uint8_t p = finger.getImage();
  if (p != FINGERPRINT_OK)  return -1;

  p = finger.image2Tz();
  if (p != FINGERPRINT_OK)  return -1;

  p = finger.fingerFastSearch();
  if (p != FINGERPRINT_OK)  return -1;
  
  return finger.fingerID; 
}

// Get the ID number from the BiometricLock App
int waitForIDNumber(){
   long start_time = millis(); //Start time
   int id = -1;
    while(id < 1){
      id = Serial.parseInt();
   
      if(millis() - start_time >= 5000){ //Allow 3 seconds maximum to set the offset values before giving up
        break;
      }
     
    }
    if (serial_debug) { Serial.print("ID found: "); Serial.print(id); Serial.println(); }
    return id;
}


//Enroll/overwrite finger print using simplified Adafruit example function
uint8_t addFingerPrint() {
  int p = -1;
  int id = waitForIDNumber();
  if (id < 1) { return p; }
   
  Serial.print("ADD:place"); 
  while (p != FINGERPRINT_OK) {
    p = finger.getImage();
    switch (p) {
    case FINGERPRINT_OK:
    delay(1000);
      Serial.print("ADD:1");
      break;
    default:
      break;
    }
  }

  // OK success!
  p = finger.image2Tz(1);
  switch (p) {
    case FINGERPRINT_OK:
      delay(1000);
      Serial.print("ADD:2");
      break;
    default:
     break;
  }
  delay(1000);
  Serial.print("ADD:remove");
  
  
  p = 0;
  while (p != FINGERPRINT_NOFINGER) {
    p = finger.getImage();
  }
  p = -1;
  delay(1000);
  Serial.print("ADD:place");
  while (p != FINGERPRINT_OK) {
    p = finger.getImage();
    switch (p) {
    case FINGERPRINT_OK:
      delay(1000);
      Serial.print("ADD:3");
      break;
 
    default:
      break;
    }
  }

  // OK success!
  p = finger.image2Tz(2);
   switch (p) {
    case FINGERPRINT_OK:
      delay(1000);
      Serial.print("ADD:4");
      break;
 
    default:
        break;
    }
  
  p = finger.createModel();
  if (p == FINGERPRINT_OK) {
    delay(1000);
    Serial.print("ADD:5");
  } 
  else {
    return -1;
  }
  
  
  p = finger.storeModel(id);
  if (p == FINGERPRINT_OK) {
    delay(1000);
    Serial.println("ADD:6");
  } 
  else {
    return -1;
  }   
  delay(1000);
  return 1; // ODO: Return p for specific fingerprint. As of now we only care about success or failure
}



// Delete a fingerprint from the sensor using simplified Adafruit example function
uint8_t deleteFingerPrint() {
  int p = -1;
  int id = waitForIDNumber();
  if (id < 1) { return p; }
  
  p = finger.deleteModel(id);

  if (p == FINGERPRINT_OK) {
    delay(1000);
    Serial.print("DEL:1");
  } else {
    return p;
  }  
  delay(1000);
  return 1; 
}
