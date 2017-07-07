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
 
 */

import controlP5.*;
import java.util.*;

final static ArrayList<Shape> ball = new ArrayList();
boolean poly_bool = false;

int ballRad = 15;
int spacing = 3;
ControlP5 cp5;
Slider rad;

color back = 10; // background
color unselected = 40;
color selected = color(249, 252, 88);

int w = 800;
int h = 500;
int margin = 25;
int Bmargin = h - margin;
int Rmargin = w - margin;

int shapeSelect = 0;

void settings() {
  size(w, h);
}

void setup() {
  background(back);
  cp5 = new ControlP5(this);
  cp5.addSlider("ballRad")
    .setPosition(10, 10)
    .setRange(5, 50)
    ;
  cp5.addSlider("spacing")
    .setPosition(10,20)
    .setRange(0,20)
    ;
  List l = Arrays.asList("default", "row", "polygon");
  cp5.addScrollableList("shapeSelect")
    .setPosition(10, 30)
    .addItems(l)
    ;
}

void draw() {
  background(back);
  for (Shape b : ball) b.display();
}

void mouseClicked() {
  switch (shapeSelect) {
  case 1:// create circles in complete rows
    {
      int i = 0;
      while (i*(ballRad+spacing) < Rmargin) {
        if (i*(ballRad+spacing) > margin) ball.add(new Shape(i*(ballRad+spacing), mouseY, ballRad));
        i++;
      }
    }
    break;
  case 2: // polygon
    break;
  case 0:
  default:
    ball.add(new Shape(mouseX, mouseY, ballRad));
    break;
  }
}

void keyPressed() {
  if (key==' ') {
    for (Shape b : ball) b.resetColor();
  }
  if (key == 'h') cp5.hide();
  if (key == 's') cp5.show();
}

class Shape
{
  int x, y, rad;
  boolean moused = false;

  Shape(int inx, int iny, int inrad) {
    x = inx;
    y = iny;
    rad = inrad;
  }

  void display() {
    if (abs(mouseX - x) < rad && abs(mouseY - y) < rad) moused = true;
    if (moused)fill(selected);
    else fill(unselected);
    ellipse(x, y, rad, rad);
  }

  void resetColor() {
    moused = false;
  }
}



// shamelessly stolen from the internet; not yet implemented
void polygon(float x, float y, float radius, int npoints) {
  float angle = TWO_PI / npoints;
  beginShape();
  for (float a = 0; a < TWO_PI; a += angle) {
    float sx = x + cos(a) * radius;
    float sy = y + sin(a) * radius;
    vertex(sx, sy);
  }
  endShape(CLOSE);
}