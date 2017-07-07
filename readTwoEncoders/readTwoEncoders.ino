/* Encoder Library - Basic Example
 * http://www.pjrc.com/teensy/td_libs_Encoder.html
 * 
 * modified to read two encoders, one of which is on Nano pins 2 and 4, the other on pins 3 and 5
 * (pins 2 and 3 have interrupts and this library works best if each encoder is attached to 
 * at least one interrupt pin)
 * 
 * Robert Zacharias, rz@rzach.me
 *
 * The original example code is in the public domain as is this modification of it.
 * 
 * v 0.1, 7 Jul. 2017
 *  * modified code to accommodate two encoders
 *  * works well with Serial Plotter
 *  * to do: bound ranges to prepare signal to be transmitted to Processing
 */

#include <Encoder.h>

Encoder left(2,4);
Encoder right(3,5);

void setup() {
  Serial.begin(9600);
}

void loop() {
  static long leftOldPos, rightOldPos;
  
  long leftPos = left.read();
  long rightPos = right.read();
  
  if (leftPos != leftOldPos || rightPos != rightOldPos) {
    leftOldPos = leftPos;
    rightOldPos = rightPos;
    Serial.print(leftPos);
    Serial.print(',');
    Serial.println(rightPos);
  }
}