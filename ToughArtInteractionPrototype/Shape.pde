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

  void display(int dotxpos, int dotypos, int xin, int yin) {
    PVector cursorPos = new PVector(xin, yin);
    PVector dotPos = new PVector(dotxpos, dotypos);

    float d = PVector.dist(dotPos, cursorPos);
    if ((int)d < ballRad/2) moused = true;

    // draw background shape, which will be drawn on top of by selected color
    fill(unselected);
    if (polypoints < 7) polygon((int)dotPos.x, (int)dotPos.y, polypoints);
    else ellipse(dotPos.x, dotPos.y, ballRad, ballRad);

    //// trigger once when moused over
    //if (moused) {
    //  alpha = 255 * fadeRate;
    //  fill(selected, alpha);
    //  if (alpha != 255) moused = false;
    //}

    if (moused) {
      fill(selected);
      if (autofade) {
        alpha *= fadeRate;
        fill(selected, alpha);
      }
    }

    // trigger when already in fade, to continue fade


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