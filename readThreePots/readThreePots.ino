/*
 * read the values of three pots and report them via serial if they change by more than a specified amount
 * 
 * v 0.1 8-2-17
 *  first version
 * 
 * Robert Zacharias
 * rz@rzach.me
 * 
 * released to the public domain by the author
 */

int val[3], oldval[3];
bool change = true;
int slop = 1; // minimum change to detect

void setup() {
  Serial.begin(9600);
  for (int i = 14; i<17; i++){ // A0 is pin 14, A1 is 15, A2 is 16
    pinMode(i, INPUT);
  }
  for (int i = 0; i<3; i++) oldval[i] = analogRead(i+14); // load initial values
}

void loop() {
  check();
  if (change) {
    for (int i = 0; i < 3; i++) {
      Serial.print(val[i]);
      if (i < 2) Serial.print(',');
    }
    Serial.println();
  }
}

void check(){
  
  // read three pots
  for (int i = 0; i < 3; i++) {
    val[i] = analogRead(i + 14);
    delay(1);
  }

  // compare to old values
  for (int i = 0; i<3; i++){
    if (abs(val[i] - oldval[i]) > slop){
      change = true;
      break;
    }
    else change = false;
  }

  // record new values as old
  for (int i = 0; i<3; i++) oldval[i] = val[i];
}

