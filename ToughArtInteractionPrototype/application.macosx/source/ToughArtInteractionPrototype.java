import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import controlP5.*; 
import java.util.*; 
import processing.serial.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class ToughArtInteractionPrototype extends PApplet {

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
 
 v. 0.85 merging into master Aug 23, 2017
 
 v. 0.86 Aug 23, 2017
 using a map command to keep ballRad in range 60-200
 
 v. 0.87 quiettimer branch Aug 24, 2017
 'inactivity' sequence triggers after shortWait seconds of inactivity (not fully implemented)
 changed minimum and default ballRad to 60
 using createFont() rather than loadFont() in order to render properly at multiple sizes
 got rid of settings() function at top since it wasn't really needed
 pushed on-screen sliders around a bit
 
 v. 0.88 quiettimer branch Aug 24, 2017
 shortwait and longwait implemented.
 
 v. 0.89x quiettimer branch Aug 30, 2017
 broke longwaitSequence into its own function
 put Shape class definition on its own tab
 size, shape, and color change after longwait triggers
 HOWEVER inconsistent coloring behavior after longwait; needs fixing
 
 v. 0.90 quiettimer branch Sep 9, 2017
 only getting data from two encoders via serial
 
 v. 0.91 quiettimer branch Sep 9, 2017
 changed casting string to int so it would compile
 serial on by default
 resolution matches projector native
 
 v. 0.92 quiettimer branch Sep 10, 2017
 ballrad goes down to 30
 resolution tweaked because the projector is 1280x800, not 1200x800
 
 v. 0.93 quiettimer branch Sep 10, 2017
 fixed margins
 
 v. 0.94 quiettimer branch Sep 10, 2017
 dots fade individually (no more shortWait), using code from master branch v. 0.85
 fixed dots having memory left over from before reset sequence
 
 v. 0.95 quiettimer branch Sep 10, 2017
 uses a random letter from a sequence instead of always T as the prompting text
 many tweaks and deletion of spurious code
 
 v. 1.0 master branch Sep 10, 2017
 merged quiettimer 0.95 into master
 show no debug displays by default, serial on by default (to run facing the public)
 
 v. 1.01 Sep 10, 2017
 longWait defaults to 20 seconds
 
 v. 1.02 slowwheel branch Sep 10 2017 
 small changes in default background color and unselected color
  
 */





Serial myPort;

Shape[][] ballgrid;

boolean serial = true;
boolean debugDisplay = false;
boolean debugConsole = false;
int wheelX, wheelY;

int ballRad = 30;
int spacing = 0;
int cursorRad = 8;
int polypoints = 3;
int gridSkewInput = 0;
float fadeRate = 0.997f;
ControlP5 cp5;

long timerval;
long longWait = 20 * 1000;

int back = 0; // background
int unselected = 20;
int selected = color(249, 252, 88); // to be modified by cp5 colorWheel below

int margin = 25;
int Bmargin, Rmargin, cols, rows; //will be set below

PFont font;

public void setup() {
  
  Bmargin = height-margin;
  Rmargin = width-margin;

  background(back);

  cp5 = new ControlP5(this);
  cp5.addToggle("serial")
    .setPosition(10, 0)
    .setSize(50, 10)
    ;
  cp5.addSlider("ballRad")
    .setPosition(10, 30)
    .setRange(30, 200)
    ;
  cp5.addSlider("longWait")
    .setPosition(200, 45)
    .setRange(5000l, 15000l)
    ;
  //cp5.addSlider("spacing")
  //  .setPosition(10, 20)
  //  .setRange(-20, 50)
  //  ;
  cp5.addSlider("cursorRad")
    .setPosition(10, 45)
    .setRange(1, 30)
    ;
  cp5.addSlider("polypoints")
    .setPosition(10, 60)
    .setRange(3, 7)
    ;
  cp5.addSlider("gridSkewInput")
    .setPosition(10, 75)
    .setRange(0, 100)
    ;
  cp5.addSlider("fadeRate")
    .setPosition(10, 90)
    .setRange(0.95f, 1.0f)
    ;
  cp5.addColorWheel("selected", 10, 105, 100)
    .setRGB(color(249, 252, 88))
    ;

  if (serial) {
    //diagnostic to list all ports
    for (int i = 0; i < Serial.list().length; i++) {
      println("Serial.list()[", i, "] = ", Serial.list()[i]);
    }
    String portName = Serial.list()[4]; // may have to change this number later
    myPort = new Serial(this, portName, 9600);
  }

  cols = (width-(margin*2))/(ballRad+spacing);
  rows= (height-(margin*2))/(ballRad+spacing);
  ballgrid = new Shape[cols][rows];

  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      // Initialize each object
      ballgrid[i][j] = new Shape(i*(ballRad+spacing), j*(ballRad+spacing), ballRad);
    }
  }

  if (debugConsole) println("cols: " + cols + " rows: " + rows);

  cp5.hide(); // hide all GUI menus by default

  font = createFont("SansSerif", 48);
}

public void draw() {
  background(back);
  int gridSkew = (int)map(gridSkewInput, 0, 100, 0, ballRad/2);

  if (serial) {
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        if (j%2 == 0) ballgrid[i][j].display(i*(ballRad+spacing)+gridSkew+margin, j*(ballRad+spacing)+margin, wheelX, wheelY);
        else          ballgrid[i][j].display(i*(ballRad+spacing)+margin, j*(ballRad+spacing)+margin, wheelX, wheelY);
      }
    }
    fill(0, 255, 255); // cursor marker color
    ellipse(wheelX, wheelY, cursorRad, cursorRad); // cursor marker
  } else {
    for (int i = 1; i*(ballRad+spacing) < Rmargin; i++) {
      for (int j = 1; j*(ballRad+spacing) < Bmargin; j++) {
        if (j%2 == 0) ballgrid[i][j].display(i*(ballRad+spacing)+gridSkew+margin, j*(ballRad+spacing)+margin, mouseX, mouseY);
        else          ballgrid[i][j].display(i*(ballRad+spacing)+margin, j*(ballRad+spacing)+margin, mouseX, mouseY);
      }
    }
  }

  if (debugDisplay) {
    textSize(12);
    fill(255);
    long currentTimer = millis() - timerval;
    text(rows + " rows\n" + cols + " cols\n" + currentTimer + " currentTimer", 350, 10);
  }

  if (millis() - timerval > longWait) longwaitSequence(); 
  else longwaitFirstRun = true;
}

public void keyPressed() {
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

boolean longwaitFirstRun = true;
int letterRand = 0;

public void longwaitSequence() {
  char[] letters = { 'T', 'X', 'Q', 'R', 'L', 'A' };

  if (longwaitFirstRun) {
    ballRad = (int)random(30, 100);
    polypoints = (int)random(3, 8);
    gridSkewInput = (int)random(0, 100);
    letterRand = PApplet.parseInt(random(letters.length));
    longwaitFirstRun = false;
  }

  resetMarked();
  fill(255, 128);
  textAlign(CENTER, TOP);
  textFont(font, 50);
  String tryDrawing = "Try drawing the letter";
  text(tryDrawing, width/2, 20);
  textFont(font, 800);
  text(letters[letterRand], width/2, -50);
}


// from http://www.interactiondesign.se/wiki/courses:intro.prototyping.spring.2015.jan19_20_21
// though I had to change the second line to use readStringUntil() to make it actually work
public void serialEvent(Serial myPort) {
  timerval = millis(); // reset activity timer
  String inString = myPort.readStringUntil(10);
  if (debugConsole) print(inString);
  if (inString != null) {
    inString = trim(inString);
    String values [] = split(inString, ',');
    if (values.length>1) {
      wheelX = (int)map(PApplet.parseInt(values[0]), 0, 10000, margin, Rmargin);
      wheelY = (int)map(PApplet.parseInt(values[1]), 0, 10000, margin, Bmargin);
    }
  }
}

public void mouseMoved() {
  timerval = millis(); // reset activity timer
}

// shamelessly stolen from the internet and modified a bit
public void polygon(int x, int y, int npoints) {
  float angle = TWO_PI / npoints;
  beginShape();
  for (float a = 0; a < TWO_PI; a += angle) {
    float sx = x + cos(a) * ballRad/2;
    float sy = y + sin(a) * ballRad/2;
    vertex(sx, sy);
  }
  endShape(CLOSE);
}

public void resetMarked() {
  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      ballgrid[i][j].resetColor();
    }
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

  public void display(int dotxpos, int dotypos, int xin, int yin) {
    PVector cursorPos = new PVector(xin, yin);
    PVector dotPos = new PVector(dotxpos, dotypos);

    float d = PVector.dist(dotPos, cursorPos);
    if ((int)d < ballRad/2) moused = true;

    // draw background shape, which will be drawn on top of by selected color
    fill(unselected);
    if (polypoints < 7) polygon((int)dotPos.x, (int)dotPos.y, polypoints);
    else ellipse(dotPos.x, dotPos.y, ballRad, ballRad);

    // trigger once when moused over
    if (moused) {
      alpha = 255 * fadeRate;
      fill(selected, alpha);
      if (alpha != 255) moused = false;
    }

    // trigger when already in fade, to continue fade
    if (alpha < 255) {
      alpha *= fadeRate;
      fill(selected, alpha);
    }

    if (polypoints < 7) polygon((int)dotPos.x, (int)dotPos.y, polypoints);
    else ellipse(dotPos.x, dotPos.y, ballRad, ballRad);
  }
  
  public void resetColor() {
    moused = false;
    alpha = 255; // to properly reset values after longWaitSequence
  }

  public void showColor() {
    moused = true;
  }
}
  public void settings() {  size(1280, 800); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "ToughArtInteractionPrototype" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
