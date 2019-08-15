int lockPin = 6;


void setup() {
  pinMode(OUTPUT,lockPin);
  Serial.begin(9600);
}

void loop() {
  
  // Toggle the lock 20 times
  digitalWrite(lockPin,HIGH);
  Serial.println("Status: LOCKED");
  delay(1000);
  digitalWrite(lockPin,LOW);
  Serial.println("Status: UNLOCKED"); 
  delay(1000);
 

}
