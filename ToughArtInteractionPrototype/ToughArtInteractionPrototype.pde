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
 
 v. 0.71 slideSwitches branch Aug 9, 2017
 IN PROGRESS interpreting 5 data points coming from the Arduino
 changed position containers to PVectors (thanks Madeline Gannon)
 fixed proximity scan function of each ball so it doesn't do too many scans unnecessarily (thanks again Madeline)
 using a 2d array to hold the ball objects, can be resized live
 ball array can be resized in space but mouseover isn't working quite right
 
 v. 0.8 slideSwitches branch Aug 9, 2017
 ball array can be live resized with correct mouseover coloring
 TO DO: test with live Arduino input
 
 v. 0.81 slideSwitches branch Aug 9, 2017
 brought back previous keyboard commands that had been commented out
 removed old code no longer used
 added gridSkew (to slide between grid and honeycomb)
 can select polygon side counts
 GOOD SUGGESTION FROM BJORN: colors fade over time
 
 v. 0.82 slideSwitches branch Aug 9, 2017
 removed more cruft
 sketch receives serial data from Arduino
 was getting an out of bounds exception when making ballRad small, but now I can't reproduce the behavior
 
 moving v. 0.82 to master Aug 9, 2017
 
 v. 0.83 Aug 20, 2017
 corrected tiny typo in version history
 slightly modified debug console feedback
 
 v. 0.84x colorFade branch Aug 22, 2017
 trying to add a parameter "fadeRate" that changes rate at which a color fades out and it's not working as expected
 
 v. 0.85 colorFade branch Aug 23, 2017
 fading can be set by "fadeRate": 1 is no fading and 0.95 is fairly fast fading
 
 
 */

import controlP5.*;
import java.util.*;
import processing.serial.*;

Serial myPort;

Shape[][] ballgrid;

boolean serial = true;
boolean debugDisplay = true;
boolean debugConsole = true;
int wheelX, wheelY;

int ballRad = 15;
int spacing = 0;
int cursorRad = 8;
int polypoints = 3;
int gridSkewInput = 0;
float fadeRate = 1.0;
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
    .setRange(15, 200)
    ;
  cp5.addSlider("spacing")
    .setPosition(10, 20)
    .setRange(-20, 50)
    ;
  cp5.addSlider("cursorRad")
    .setPosition(10, 30)
    .setRange(1, 30)
    ;
  cp5.addSlider("gridSkewInput")
    .setPosition(10, 50)
    .setRange(0, 100)
    ;
  cp5.addSlider("fadeRate")
    .setPosition(10, 60)
    .setRange(0.95, 1.0)
    ;
  cp5.addToggle("serial")
    .setPosition(200, 10)
    .setSize(10, 10)
    ;
  //List g = Arrays.asList("none", "horizontal", "vertical");
  //cp5.addScrollableList("gradient")
  //  .setPosition(200, 50)
  //  .addItems(g)
  //  ;
  cp5.addSlider("polypoints")
    .setPosition(10, 100)
    .setRange(3, 7)
    ;
  cp5.addColorWheel("selected", 400, 10, 200)
    .setRGB(color(249, 252, 88))
    ;
  //cp5.addColorWheel("gradientColor", 600, 10, 200)
  //  .setRGB(color(249, 252, 88))
  //  ;

  if (serial) {
    //diagnostic to list all ports
    for (int i = 0; i < Serial.list().length; i++) {
      println("Serial.list()[", i, "] = ", Serial.list()[i]);
    }
    String portName = Serial.list()[6]; // may have to change this number later
    myPort = new Serial(this, portName, 9600);
  }

  int cols = width/(ballRad+spacing);
  int rows= height/(ballRad+spacing);
  ballgrid = new Shape[cols][rows];

  for (int i = 1; i*(ballRad+spacing) < Rmargin; i++) {
    for (int j = 1; j*(ballRad+spacing) < Bmargin; j++) {
      // Initialize each object
      ballgrid[i][j] = new Shape(i*(ballRad+spacing), j*(ballRad+spacing), ballRad);
    }
  }

  if (debugConsole) println("cols: " + cols + " rows: " + rows);

  cp5.hide(); // hide all GUI menus by default
  debugDisplay = false;
}




void draw() {
  background(back);
  int gridSkew = (int)map(gridSkewInput, 0, 100, 0, ballRad/2);

  if (serial) {
    for (int i = 1; i*(ballRad+spacing) < Rmargin; i++) {
      for (int j = 1; j*(ballRad+spacing) < Bmargin; j++) {
        if (j%2 == 0) ballgrid[i][j].display(i*(ballRad+spacing)+gridSkew, j*(ballRad+spacing), wheelX, wheelY);
        else          ballgrid[i][j].display(i*(ballRad+spacing), j*(ballRad+spacing), wheelX, wheelY);
      }
    }
    fill(0, 255, 255); // cursor marker color
    ellipse(wheelX, wheelY, cursorRad, cursorRad); // cursor marker
  } else {
    for (int i = 1; i*(ballRad+spacing) < Rmargin; i++) {
      for (int j = 1; j*(ballRad+spacing) < Bmargin; j++) {
        if (j%2 == 0) ballgrid[i][j].display(i*(ballRad+spacing)+gridSkew, j*(ballRad+spacing), mouseX, mouseY);
        else          ballgrid[i][j].display(i*(ballRad+spacing), j*(ballRad+spacing), mouseX, mouseY);
      }
    }
  }
  if (debugDisplay) {
    int cols = Rmargin / (ballRad+spacing);
    int rows = Bmargin / (ballRad+spacing);
    text(rows + " rows\n" + cols + " cols", 10, height-20);
  }
}



void keyPressed() {
  if (key == ' ') resetMarked();
  if (key == 'h') {
    cp5.hide(); // hide all GUI menus
    debugDisplay = false;
  }
  if (key == 's') {
    cp5.show(); // show all GUI menus
    debugDisplay = true;
  }
}


class Shape
{
  int x, y, rad, inside;
  boolean moused = false;
  boolean rot = false;
  PVector pos;
  float alpha;

  Shape(int inx, int iny, int inrad) {
    pos = new PVector(inx, iny);
    //pos.x = inx;
    //pos.y = iny;
    rad = inrad;
    alpha = 255;
  }

  Shape(int inx, int iny, int inrad, int inside, boolean inrot) {
    x = inx;
    y = iny;
    rad = inrad;
    polypoints = inside;
    rot = inrot;
  }

  void display(int dotxpos, int dotypos, int xin, int yin) {
    PVector cursorPos = new PVector(xin, yin);
    PVector dotPos = new PVector(dotxpos, dotypos);

    float d = PVector.dist(dotPos, cursorPos);
    if ((int)d < ballRad/2) moused = true;

    // draw background shape, which will be drawn on top of by selected color
    fill(unselected);
    if (polypoints < 7) polygon((int)dotPos.x, (int)dotPos.y, polypoints);
    else ellipse(dotPos.x, dotPos.y, ballRad, ballRad);

    // trigger once when moused over
    if (moused){
      alpha = 255 * fadeRate;
      fill(selected, alpha);
      if(alpha != 255) moused = false;
    }
    
    // trigger when already in fade, to continue fade
    if (alpha < 255){
      alpha *= fadeRate;
      fill(selected, alpha);
    }
        
    if (polypoints < 7) polygon((int)dotPos.x, (int)dotPos.y, polypoints);
    else ellipse(dotPos.x, dotPos.y, ballRad, ballRad);
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
  if (debugConsole) print(inString);
  if (inString != null) {
    inString = trim(inString);
    for (int i = 0; i < inString.length(); i++) { // look for 'r' in string (reset flag)
      char c = inString.charAt(i);
      if (c == 'r') {
        resetMarked();
        return;
      }
    }
    String values [] = split(inString, ',');
    if (values.length>1) {
      wheelX = int(values[0]); // range 0–10000
      wheelY = int(values[1]); // range 0–10000
      ballRad = int(values[2]); // range 5–200
      polypoints = int(values[3]); // range 3–7
      gridSkewInput = int(values[4]); // range 0–100

      wheelX = (int)map(wheelX, 0, 10000, margin, Rmargin);
      wheelY = (int)map(wheelY, 0, 10000, margin, Bmargin);
    }
  }
}



// shamelessly stolen from the internet and modified a bit
void polygon(int x, int y, int npoints) {
  float angle = TWO_PI / npoints;
  beginShape();
  for (float a = 0; a < TWO_PI; a += angle) {
    float sx = x + cos(a) * ballRad/2;
    float sy = y + sin(a) * ballRad/2;
    vertex(sx, sy);
  }
  endShape(CLOSE);
}

void resetMarked() {
  for (int i = 1; i*(ballRad+spacing) < Rmargin; i++) {
    for (int j = 1; j*(ballRad+spacing) < Bmargin; j++) {
      ballgrid[i][j].resetColor();
    }
  }
}