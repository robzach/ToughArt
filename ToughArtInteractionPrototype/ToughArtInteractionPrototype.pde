/*

 interaction prototype for Tough Art project at Children's Museum of Pittsburgh
 
 displays varying shapes at varying sizes and changes their color if the cursor passes beneath them
 
 Robert Zacharias, rz@rzach.me
 released to the public domain by the author
 
 v. 0.1, Jul. 6, 2017
 click to add a new ball anywhere; 
 mouse over it to change its color; 
 type space to reset colors;
 type 'h' to hide size, spacing, and drawing mode selectors and 's' to show them.
 To do: 
 * add polygon support (define the number of sides and it does the rest)
 * fix selector so it only touches the single underlying ball, not everything nearby
 * add serial data support for Arduino position information
 
 v. 0.2, Jul. 7, 2017
 added support for incoming serial position data from Arduino
 
 v. 0.3, Jul 10, 2017
 added grid fill
 added object deleter (type 'c' to clear all objects so the canvas is blank again) 
 added start of polygon builder (not yet complete)
 
 v. crazytown Jul 12, 2017 (now ahead of some of the changes on the multimaster branch and will probably need to manually merge later)
 modified proximity test with stupid divisor
 added color selector, too
 removed Shape.display() but preserved Shape.display(int x, int y), because the first was redundant
 made some progress on option for gradients as colors, but not done
 
 v. 0.5 Jul 13, 2017
 I didn't make any contemporaneous notes on this update so I don't know what changed.
 
 v. 0.6 Jul 19, 2017
 added slider for cursor size (cursorRad) since it was too small to see sometimes
 added serial reset command; if character 'r' is transmitted, will perform reset
 
 v. 0.65 Jul 19, 2017
 IN PROGRESS add hexagon grid (honeycomb) pattern
 (committing to master so I can make a development branch without disturbing the code that's presently running)
 
 v. 0.66 Jul 27, 2017
 added ability to save out settings (press 's') and load them in (press 'l')
 
 */

import controlP5.*;
import java.util.*;
import processing.serial.*;

Serial myPort;

final static ArrayList<Shape> ball = new ArrayList();

boolean serial = true;
boolean debugDisplay = true;
int wheelX, wheelY;

int ballRad = 30;
int spacing = 3;
int cursorRad = 8;
int polypoints = 3;
ControlP5 cp5;
Slider rad;

color back = 10; // background
color unselected = 40;
color selected = color(249, 252, 88); // these two colors to be modified by cp5 colorWheel below
color gradientColor = color(249, 252, 88);

int w = 1200;
int h = 800;
int margin = 25;
int Bmargin = h - margin;
int Rmargin = w - margin;

int rows, cols; // globals to store number of rows and cols of grid, which are generated inside mouseClicked()

// state variable for different modes
int shapeSelect = 3; // default to grid
int gradient = 0;

// needed to use variables to set width and height
void settings() {
  size(w, h);
}

void setup() {
  background(back);
  cp5 = new ControlP5(this);
  cp5.addSlider("ballRad")
    .setPosition(10, 10)
    .setRange(5, 200)
    ;
  cp5.addSlider("spacing")
    .setPosition(10, 20)
    .setRange(0, 50)
    ;
  List l = Arrays.asList("single", "row", "polygon", "grid", "honeycomb");
  cp5.addScrollableList("shapeSelect")
    .setPosition(10, 40)
    .addItems(l)
    ;
  cp5.addSlider("cursorRad")
    .setPosition(10, 30)
    .setRange(1, 30)
    ;
  cp5.addToggle("serial")
    .setPosition(200, 10)
    .setSize(10, 10)
    ;
  List g = Arrays.asList("none", "horizontal", "vertical");
  cp5.addScrollableList("gradient")
    .setPosition(200, 50)
    .addItems(g)
    ;
  //cp5.addSlider("polysides")
  //  .setPosition(200,20)
  //  .setRange(3,10)
  //  ;
  cp5.addColorWheel("selected", 400, 10, 200)
    .setRGB(color(249, 252, 88))
    ;
  cp5.addColorWheel("gradientColor", 600, 10, 200)
    .setRGB(color(249, 252, 88))
    ;

  if (serial) {
    //diagnostic to list all ports
    for (int i = 0; i < Serial.list().length; i++) {
      println("Serial.list()[", i, "] = ", Serial.list()[i]);
    }
    String portName = Serial.list()[6]; // may have to change this number later
    myPort = new Serial(this, portName, 9600);
  }
}

void draw() {
  background(back);

  if (!serial) for (Shape b : ball) b.display(mouseX, mouseY);
  else {
    for (Shape b : ball) b.display(wheelX, wheelY);
    fill(0, 255, 255); // cursor marker color
    ellipse(wheelX, wheelY, cursorRad, cursorRad); // cursor marker
  }

  if (shapeSelect == 3 && debugDisplay) {
    String msg = "rows:" + rows + ", cols:" + cols;
    fill(255);
    text(msg, 10, height-10);
  }
}

void mouseClicked() {
  // modified by cp5 GUI menu
  switch (shapeSelect) {
  case 1:// draw circles in complete rows
    {
      int i = 0;
      while (i*(ballRad+spacing) < Rmargin) {
        if (i*(ballRad+spacing) > margin) ball.add(new Shape(i*(ballRad+spacing), mouseY, ballRad));
        i++;
      }
    }
    break;
  case 2: // polygon
    ball.add(new Shape(mouseX, mouseY, ballRad, polypoints, false));
    break;
  case 3: // grid
    for (int i = 1; i*(ballRad+spacing) < Rmargin; i++) {
      for (int j = 1; j*(ballRad+spacing) < Bmargin; j++) {
        ball.add(new Shape(i*(ballRad+spacing), j*(ballRad+spacing), ballRad));
        rows = i;
        cols = j;
      }
    }
    break;
  case 4: // honeycomb
    // draw odd rows first
    for (int i = 1; i*(ballRad+spacing) < Rmargin; i++) {
      for (int j = 1; j*(ballRad+spacing) < Bmargin; j++) {
        if (j % 2 == 1) ball.add(new Shape(i*(ballRad+spacing), j*(ballRad+spacing), ballRad, 6, false));
        ////// worry about counting totals later
        //rows = i;
        //cols = j;
      }
    }
    // draw even rows so they nest properly, indented by half of ballRad
    for (int i = 1; i*(ballRad+spacing) < Rmargin; i++) {
      for (int j = 1; j*(ballRad+spacing) < Bmargin; j++) {
        if (j % 2 == 0) ball.add(new Shape(i*(ballRad+spacing)+(int(ballRad/2)), j*(ballRad+spacing), ballRad, 6, false)); // SWITCH TO TRUE TO ROTATE
      }
    }
    break;
  case 0:
  default: // add single ball
    ball.add(new Shape(mouseX, mouseY, ballRad));
    break;
  }
}

void keyPressed() {
  if (key == ' ') for (Shape b : ball) b.resetColor(); // mark every object as unselected
  if (key == 'h') {
    cp5.hide(); // hide all GUI menus
    debugDisplay = false;
  }
  if (key == 's') {
    cp5.show(); // show all GUI menus
    debugDisplay = true;
  }
  if (key == 'c') { // clear board
    int i = 0;
    while (i < ball.size()) ball.remove(i);
  }
  if (key == 'a') for (Shape b : ball) b.showColor(); // mark every object as selected
  if (key == 's') cp5.saveProperties(); // save out controlP5 settings to JSON
  if (key == 'l') cp5.loadProperties(); // load saved properties
}

class Shape
{
  int x, y, rad, inside;
  boolean moused = false;
  boolean rot = false;

  Shape(int inx, int iny, int inrad) {
    x = inx;
    y = iny;
    rad = inrad;
  }

  Shape(int inx, int iny, int inrad, int inside, boolean inrot) {
    x = inx;
    y = iny;
    rad = inrad;
    polypoints = inside;
    rot = inrot;    
  }

  color gradientizer(int xin, int yin) {
    float horizProportion = (float)x / (Rmargin - margin);
    float vertProportion = (float)y / (Bmargin - margin);
    float rdiff = red(selected) - red(gradientColor);
    float gdiff = green(selected) - green(gradientColor);
    float bdiff = blue(selected) - blue(gradientColor);
    color hout = color(int(rdiff*horizProportion+red(selected)), int(gdiff*horizProportion+green(selected)), int(bdiff*horizProportion+blue(selected)));
    color vout = color(int(rdiff*vertProportion+red(selected)), int(gdiff*vertProportion+green(selected)), int(bdiff*vertProportion+blue(selected)));
    //println(hex(out));
    if (gradient == 1) return hout;
    else if (gradient == 2) return vout;
    else return 0;
  }

  void display(int xin, int yin) {
    //if (abs(wheelXin - x) < rad && abs(wheelYin - y) < rad) moused = true;
    if ( sq(xin - x) + sq(yin - y) < sq(rad)/3 ) moused = true; // the 3 divisor is totally made up
    if (moused) {
      if (gradient==0) fill(selected);
      else fill(gradientizer(x, y));
    } else fill(unselected);

    if (shapeSelect == 2 || shapeSelect == 4) polygon(x, y, ballRad, polypoints, rot);
    else ellipse(x, y, rad, rad);
  }

  void resetColor() {
    moused = false;
  }

  void showColor() {
    moused = true;
  }
}

// from http://www.interactiondesign.se/wiki/courses:intro.prototyping.spring.2015.jan19_20_21
// though I had to change the second line to use readStringUntil() to make it actually work
void serialEvent(Serial myPort) {
  String inString = myPort.readStringUntil(10);
  if (inString != null) {
    inString = trim(inString);
    for (int i = 0; i < inString.length(); i++) { // look for 'r' in string (reset flag)
      char c = inString.charAt(i);
      if (c == 'r') {
        for (Shape b : ball) b.resetColor();
        return;
      }
    }
    String values [] = split(inString, ',');
    if (values.length>1) {
      wheelX = int(values[0]);
      wheelY = int(values[1]);
      wheelX = (int)map(wheelX, 0, 10000, margin, Rmargin);
      wheelY = (int)map(wheelY, 0, 10000, margin, Bmargin);
    }
  }
}



// shamelessly stolen from the internet and modified a bit
void polygon(int x, int y, int radius, int npoints, boolean rotate) {
  float angle = TWO_PI / npoints;
  if (rotate) {
    pushMatrix();
    rotate(angle/2);
  }
  beginShape();
  for (float a = 0; a < TWO_PI; a += angle) {
    float sx = x + cos(a) * radius;
    float sy = y + sin(a) * radius;
    vertex(sx, sy);
  }
  endShape(CLOSE);
  if (rotate) popMatrix();
}