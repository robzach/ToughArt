/* Encoder Library - Basic Example
 * http://www.pjrc.com/teensy/td_libs_Encoder.html
 * 
 * modified to read two encoders, one of which is on Uno pins 2 and 4, the other on pins 3 and 5
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
 *  
 * v 0.11 7 Jul. 2017
 *  * bounded output range between 0 and 10000
 *  
 * v 0.12 19 Jul. 2017
 *  * added sending reset command via serial when a button is pushed
 *  
 * v 0.2 9 Sep. 2017
 *  * encoders roll over (less than 0 becomes 9999, more than 9999 becomes 0)
 *  * removed reset button
 *  
 * v 0.21 slowwheel branch 12 Sep. 2017
 *  * encoders scale down by a factor of 2, but still send values [0,10000]
 *  * digital pins for noninterrupt pins moved for greater ease of wiring
 *  
 * v 0.22 slowwheel branch 12 Sep. 2017
 *  * horizontal encoder (left) slows down by factor of 3 (screen is about 3:2 so this
 *      roughly equalizes the speeds of both encoders)
 *      
 * v 0.23 slowwheel branch 
 *  * fixed dumb typo
 * 
 */

#include <Encoder.h>

Encoder left(2,6);
Encoder right(3,7);

void setup() {
  Serial.begin(9600);
}

void loop() {
  static long leftOldPos, rightOldPos;
  
  long leftPos = left.read();
  long rightPos = right.read();

  if(leftPos < 0) left.write(29999);
  else if(leftPos > 29999) left.write(0);
  if(rightPos < 0) right.write(19999);
  else if(rightPos > 19999) right.write(0);
  
  
  if (leftPos != leftOldPos || rightPos != rightOldPos) {
    leftOldPos = leftPos;
    rightOldPos = rightPos;
    int leftSend = leftPos/3;
    int rightSend = rightPos/2;
    Serial.print(leftSend);
    Serial.print(',');
    Serial.println(rightSend);
  }
}
