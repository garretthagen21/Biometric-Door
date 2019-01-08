/*************************************************** 
  This is an example sketch for our optical Fingerprint sensor

  Designed specifically to work with the Adafruit BMP085 Breakout 
  ----> http://www.adafruit.com/products/751

  These displays use TTL Serial to communicate, 2 pins are required to 
  interface
  Adafruit invests time and resources providing this open source code, 
  please support Adafruit and open-source hardware by purchasing 
  products from Adafruit!

  Written by Limor Fried/Ladyada for Adafruit Industries.  
  BSD license, all text above must be included in any redistribution
 ****************************************************/


#include <Adafruit_Fingerprint.h>


#include <SoftwareSerial.h>

/** Change this to true to print bluetooth output to serial monitor. Must be set to false otherwise **/
boolean serial_debug = true;

// BLE Communication
SoftwareSerial bluetoothLE(3,4); //RX,TX on Arduino
int incoming_command;
int current_command = 'L';


// Fingerprint Sensor
SoftwareSerial fingerSerial(4, 5);
Adafruit_Fingerprint finger = Adafruit_Fingerprint(&fingerSerial);

// Solenoid Lock
int verifyLED = 6;
String lockStatus = "LOCKED";
boolean isLocked = true;    //This should always match lockStatus. Quicker to use boolean than compare string every time
boolean statusConfirmed = false;

void setup()  
{

  //Serial and Bluetooth Communication Initialization
  bluetoothLE.begin(9600);
  delay(1000);
  bluetoothLE.write("AT+NAMEDoorLock");
  if (serial_debug){ Serial.begin(9600); }
  

  
  //Fingerprint scanner initialization
  finger.begin(57600); 
  if (finger.verifyPassword() && serial_debug) { 
    Serial.print("Sensor contains "); 
    finger.getTemplateCount();
    Serial.print(finger.templateCount); 
    Serial.println(" templates");}   //These should never execute
  else { 
      Serial.println("Did not find fingerprint sensor."); 
    }
  
  //Lock initialization
  pinMode(verifyLED,OUTPUT);

}//End setup

void loop()                     // run over and over again
{
   //--------READ INCOMING COMMAND TO SEE IF WE SHOULD UNLOCK VIA PASSCODE--------//
    if (bluetoothLE.available() > 0){
     incoming_command = bluetoothLE.read();
     if((isWhitespace(incoming_command) == false) && (isAlpha(incoming_command)==true)){
        current_command = incoming_command;
     }
    }

  //--------CHECK FINGERPRINT SENSOR--------//
  int id = getFingerprintIDez();
  if(id != -1){
    doUnlock();
  }
  else if(current_command == 'U'){
    doUnlock();
  }
  else if(current_command == 'C'){
    statusConfirmed = true;
  }
  else{
    doLock();
  }

  
  if(!statusConfirmed){ bluetoothLE.print(lockStatus); }  //Keep sending the lock status until we recieve a callback that we have acknowlegded it
  //delay(50);           

}//End loop

//Unlock door if it is currently locked
void doUnlock(){
  if(isLocked){
    digitalWrite(verifyLED,HIGH);
    delay(250);
    digitalWrite(verifyLED,LOW);
    isLocked = false;
    lockStatus = "UNLOCKED";
    statusConfirmed = false;
  }
}

//Lock door if it is currently unlocked
void doLock(){ 
  if(!isLocked){
    digitalWrite(verifyLED,HIGH);
    delay(50);
    digitalWrite(verifyLED,LOW);
    digitalWrite(verifyLED,HIGH);
    delay(50);
    digitalWrite(verifyLED,LOW);
    digitalWrite(verifyLED,HIGH);
    delay(50);
    digitalWrite(verifyLED,LOW);
    isLocked = true;
    lockStatus = "LOCKED";
    statusConfirmed = false;
  }
}

//Verify/Deny fingerprint
int getFingerprintIDez() {
  uint8_t p = finger.getImage();
  if (p != FINGERPRINT_OK)  return -1;

  p = finger.image2Tz();
  if (p != FINGERPRINT_OK)  return -1;

  p = finger.fingerFastSearch();
  if (p != FINGERPRINT_OK)  return -1;
  
  // found a match!
  Serial.print("Found ID #"); Serial.print(finger.fingerID); 
  Serial.print(" with confidence of "); Serial.println(finger.confidence);
  return finger.fingerID; 
}
