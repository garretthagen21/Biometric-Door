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

/*  ARDUINO ---> MODULE
 *  
 *  TX ------> HM-10 RX
 *  RX ------> HM-10 TX
 *  D2 ------> FP TX (Green) 
 *  D3 ------> FP RX (Yellow)
 *  D4 ------> Button NC (Blue)
 *  D5 ------> Button LED (Green)
 *  D6 ------> Lock+ (Red)
 *  5V ------> HM-10 VCC
 *  3v3 -----> FP VCC
 */
#include <Adafruit_Fingerprint.h>
#include <String.h>
#include <SoftwareSerial.h>


/** Change this to true to print bluetooth output to serial monitor. Must be set to false otherwise to avoid interference w/ Bluetooth**/
boolean serial_debug = false;


// Fingerprint Sensor
SoftwareSerial fingerSerial(2, 3);
Adafruit_Fingerprint finger = Adafruit_Fingerprint(&fingerSerial);

// BLE Communication
int incoming_command;
int current_command = 'X';
long loop_timer;

//Lock Button
int lockButton = 4;
int buttonLED = 5;

// Solenoid Lock
int verifyLED = 6;
boolean isLocked = true;    //This should always match lockStatus. Quicker to use boolean than compare string every time
boolean updateConfirmed = false;


void setup()  
{
  
   //Serial and Bluetooth Communication Initialization
  Serial.begin(9600);
  delay(1000);
  Serial.print("AT+NAMEDoorLock");
  delay(1000);

  
  //Fingerprint scanner initialization
  finger.begin(57600); 
  if (finger.verifyPassword() && serial_debug) { 
    if(serial_debug){
    Serial.print("Sensor contains "); 
    finger.getTemplateCount();
    Serial.print(finger.templateCount); 
    Serial.println(" templates");
    }   //These should never execute
  }
  else { 
      if(serial_debug){ Serial.println("Did not find fingerprint sensor."); }
    }

  //Lock & Button initialization
  pinMode(verifyLED,OUTPUT);
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
  
  if(id != -1 || buttonStatus == HIGH){ //Tell the phone we are unlocking, the phone will then send 'U' back to the Arduino to unlock it. Phone = master. Arduino = slave
     if(isLocked) { Serial.print("UNLOCK"); }
     else {  Serial.print("LOCK"); }
  }
  else if(current_command == 'U'){
     doUnlock();   
  }
  else if(current_command == 'L'){
     doLock();   
  }

  //delay(50);             

}//End loop


//Unlock door if it is currently locked -> returns true if the door executes unlocking
void doUnlock(){
   isLocked = false;
   digitalWrite(verifyLED,LOW);
   digitalWrite(buttonLED,LOW);
}

//Lock door if it is currently unlocked -> returns true if the door executes locking
void doLock(){ 
   isLocked = true;
   digitalWrite(verifyLED,HIGH);
   digitalWrite(buttonLED,HIGH);
}

// Verify/Deny fingerprint
int getFingerprintIDez() {
  uint8_t p = finger.getImage();
  if (p != FINGERPRINT_OK)  return -1;

  p = finger.image2Tz();
  if (p != FINGERPRINT_OK)  return -1;

  p = finger.fingerFastSearch();
  if (p != FINGERPRINT_OK)  return -1;
  
  return finger.fingerID; 
}
