/*
   read the values of three pots and two encoders,
   and report them via serial if any change by more than a specified amount

   serial output should be:
   leftwheel,rightwheel,ballRad,polypoints,gridSkew

   leftwheel and rightwheel have ranges 0–10000
   ballRad has range 15–200
   polyPoints has range 3–7
   gridSkew has range 0–100

   ballRad pot on A0, polyPoints pot on A1, gridSkew on A2

   v 0.1 8-2-17
    first version

   v 0.2 8-9-17
    merging with readTwoEncoders
    adding appropriate ranges for output values
    this needs revision but was done in a hurry

   v 0.21 8-9-17
    minor restructuring; added reset button on pin 7 which I'd forgotten about
    tested and is outputting correct serial data

   v 0.22 8-9-17
    corrected ballRad range to 15–200

   v 0.23 8-10-17
    adding wraparound to the encoder wheels as per Arvid's suggestion

   Robert Zacharias
   rz@rzach.me

   released to the public domain by the author
*/

#include <Encoder.h>

Encoder left(2, 4);
Encoder right(3, 5);

bool wraparound = true;

int resetButton = 7;

int val[3], oldval[3];
bool change = true;
int slop = 1; // minimum change to detect

void setup() {
  Serial.begin(9600);
  for (int i = 14; i < 17; i++) { // A0 is pin 14, A1 is 15, A2 is 16
    pinMode(i, INPUT);
  }
  for (int i = 0; i < 3; i++) oldval[i] = analogRead(i + 14); // load initial values
  pinMode(resetButton, INPUT_PULLUP);
}

void loop() {

  // read three pots
  for (int i = 0; i < 3; i++) {
    val[i] = analogRead(i + 14);
    delay(1);
  }

  // compare to old values
  for (int i = 0; i < 3; i++) {
    if (abs(val[i] - oldval[i]) > slop) {
      change = true;
      break;
    }
    else change = false;
  }

  static long leftOldPos, rightOldPos;

  long leftPos = left.read();
  long rightPos = right.read();

  if (wraparound) {
    if (leftPos < 0) left.write(9999);
    else if (leftPos > 10000) left.write(0);
    if (rightPos < 0) right.write(9999);
    else if (rightPos > 10000) right.write(0);
  }

  else {
    if (leftPos < 0) left.write(0);
    else if (leftPos > 10000) left.write(10000);
    if (rightPos < 0) right.write(0);
    else if (rightPos > 10000) right.write(10000);
  }
  
  if (leftPos != leftOldPos || rightPos != rightOldPos) {
    leftOldPos = leftPos;
    rightOldPos = rightPos;
    change = true;
  }

  // record new values as old
  for (int i = 0; i < 3; i++) oldval[i] = val[i];


  if (change) {
    int ballRad = map(val[0], 0, 1023, 15, 200);
    int polyPoints = map(val[1], 0, 1000, 3, 7);
    int gridSkew = map(val[2], 0, 1023, 0, 100);

    Serial.print(leftPos);
    Serial.print(',');
    Serial.print(rightPos);
    Serial.print(',');
    Serial.print(ballRad);
    Serial.print(',');
    Serial.print(polyPoints);
    Serial.print(',');
    Serial.println(gridSkew);

    change = false;
  }

  if (digitalRead(resetButton) == LOW) Serial.println('r');

}

