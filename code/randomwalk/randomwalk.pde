// Flood-Fill Art Using Random Walks
// https://sighack.com/post/flood-fill-art-using-random-walks

/*
 * An array of 'color' values, one for each pixel on
 * canvas.
 */
color[] colors;
/*
 * A boolean for each pixel on canvas, specifying whether
 * it has been visited so far or not. Initially, we
 * initialize it to 'false' for all pixels.
 */
boolean[] visited;
/*
 * A list of points that need to be processed. Initially,
 * it is just an empty list and points are added to it as
 * we color them to indicate that we need to now process
 * the point's neighbors.
 */
ArrayList<PVector> points;

final int SEED_COLOR_RANDOM = 0;
final int SEED_COLOR_WHITE  = 1;
final int SEED_COLOR_BLACK  = 2;
final int SEED_COLOR_FIXED  = 3;
final int SEED_COLOR_IMAGE  = 4;

final int SEED_POSITION_RANDOM     = 0;
final int SEED_POSITION_CENTER_ISH = 1;
final int SEED_POSITION_CENTER     = 2;
final int SEED_POSITION_CORNER     = 3;
final int SEED_POSITION_POISSON    = 4;
final int SEED_POSITION_DIAGONAL   = 5;

int colorType = RGB;     // Try HSB
int numSeedPoints = 10;   // Try 1, 10, 100, 1000
float perturbation = 10; // Try 1, 5, 20, 100
float strokeWidth = 2;   // Try 1, 5, 10, 20
int seedColorStrategy = SEED_COLOR_RANDOM;
int seedPositionStrategy = SEED_POSITION_POISSON;
int poissonRadius = 20;
int poissonTries = 20;
float redBias = 0;
float greenBias = 0;
float blueBias = 0;
float whiteBias = 0;
float blackBias = 0;
float hueBias = 0;
float saturationBias = 0;
float brightnessBias = 0;

/* Randomly mutate an RGB color based on a specified perturbation. */
color mutate(color c) {
  color ret;
  if (colorType == RGB) {
    ret = color(
      int(randomGaussian() * perturbation) +  red(c) + redBias + whiteBias - blackBias, 
      int(randomGaussian() * perturbation) +  green(c) + greenBias + whiteBias - blackBias, 
      int(randomGaussian() * perturbation) +  blue(c) + blueBias + whiteBias - blackBias);
  } else {
    float hue = int(randomGaussian() * perturbation) +  hue(c) + hueBias;
    hue = hue % 360;
    ret = color(
      hue, 
      int(randomGaussian() * perturbation) +  saturation(c) + saturationBias - whiteBias + blackBias, 
      int(randomGaussian() * perturbation) +  brightness(c) + brightnessBias + whiteBias - blackBias);
  }
  return ret;
}

/*
 * This function performs a single iteration of the flood-fill logic.
 * We first remove a random point from our 'points' array, which consists
 * or points that have been colored, but whose neighbors may need visiting.
 * We then, for each of its neighbors, color it with a slightly mutated
 * color if it hasn't been visited already.
 *
 * The function returns true if it successfully processed a point, or
 * false if there are no more points left whose neighbors need to be
 * processed.
 */
boolean run() {
  /* If there are no points left in our 'points' array, we're done. */
  if (points.size() == 0)
    return false;

  /* Get a random point to process from the list, and get its color */
  int idx = int(random(points.size()));
  PVector p = points.get(idx);
  points.remove(idx);
  color original = colors[int(p.y * width) + int(p.x)];

  /* Iterate over a 3x3-pixel grid around the original point */
  for (int i = int(p.x); i <= int(p.x) + 1; i++) {
    for (int j = int(p.y); j <= int(p.y) + 1; j++) {
      /* Ignore original point (center of 3x3-pixel grid) */
      if (i == int(p.x) && j == int(p.y))
        continue;
      /* Ignore points that are outside the canvas. */
      if (i < 0 || i >= width || j < 0 || j >= height)
        continue;
      /* Ignore points that have already been visited */
      if (visited[j * width + i])
        continue;

      /* Mutate the color, save it, and mark point as visited */
      color col = mutate(original);
      colors[j * width + i] = col;
      visited[j * width + i] = true;
      points.add(new PVector(i, j));

      /* Now just draw line from original point to neighbor */
      stroke(col);
      strokeWeight(strokeWidth);
      line(p.x, p.y, i, j);
    }
  }
  return true;
}

// number of seed points --> 1, 10, 100, 1000
// Perturbation size --> 1, 10, 20, 100
// color mode --> RGB, HSB (monochromatic)
// Line stroke width --> 1, 5, 10
// location of seed point --> fixed, random-ish location, two corners, two sides
// Seed color --> random, white, black, fixed color
// Biasing mutations towards dark/light
// seed color based on underlying image --> use poisson disk sampling for seeds

// Seed shape (diagonal line)

// Point removal --> random vs. index 0

// multiple points with different mutations (e.g., blue channel for one, red channel for the other)
// https://tangent128.deviantart.com/gallery/
// limit propogation direction (e.g., only bottom or left)
// re-seed pixels from time to time (seed() instead of mutate()).

/*
 * Seed a point (x, y) with a color 'c', and add it to the list
 * of points whose neighbors need to be processed.
 */
void seed(int x, int y, color c) {
  colors[y * width + x] = c;
  visited[y * width + x] = true;
  points.add(new PVector(x, y));
}

boolean isValidPoint(PVector[][] grid, float cellsize, 
  int gwidth, int gheight, 
  PVector p, float radius) {
  /* Make sure the point is on the screen */
  if (p.x < 0 || p.x >= width || p.y < 0 || p.y >= height)
    return false;

  /* Check neighboring eight cells */
  int xindex = floor(p.x / cellsize);
  int yindex = floor(p.y / cellsize);
  int i0 = max(xindex - 1, 0);
  int i1 = min(xindex + 1, gwidth - 1);
  int j0 = max(yindex - 1, 0);
  int j1 = min(yindex + 1, gheight - 1);

  for (int i = i0; i <= i1; i++)
    for (int j = j0; j <= j1; j++)
      if (grid[i][j] != null)
        if (dist(grid[i][j].x, grid[i][j].y, p.x, p.y) < radius)
          return false;

  /* If we get here, return true */
  return true;
}

void insertPoint(PVector[][] grid, float cellsize, PVector point) {
  int xindex = floor(point.x / cellsize);
  int yindex = floor(point.y / cellsize);
  grid[xindex][yindex] = point;
}

ArrayList<PVector> poissonDiskSampling(float radius, int k) {
  int N = 2;
  /* The final set of points to return */
  ArrayList<PVector> points = new ArrayList<PVector>();
  /* The currently "active" set of points */
  ArrayList<PVector> active = new ArrayList<PVector>();
  /* Initial point p0 */
  PVector p0 = new PVector(random(width), random(height));
  PVector[][] grid;
  float cellsize = floor(radius/sqrt(N));

  /* Figure out no. of cells in the grid for our canvas */
  int ncells_width = ceil(width/cellsize) + 1;
  int ncells_height = ceil(width/cellsize) + 1;

  /* Allocate the grid an initialize all elements to null */
  grid = new PVector[ncells_width][ncells_height];
  for (int i = 0; i < ncells_width; i++)
    for (int j = 0; j < ncells_height; j++)
      grid[i][j] = null;

  insertPoint(grid, cellsize, p0);
  points.add(p0);
  active.add(p0);

  while (active.size() > 0) {
    int random_index = int(random(active.size()));
    PVector p = active.get(random_index);

    boolean found = false;
    for (int tries = 0; tries < k; tries++) {
      float theta = random(360);
      float new_radius = random(radius, 2*radius);
      float pnewx = p.x + new_radius * cos(radians(theta));
      float pnewy = p.y + new_radius * sin(radians(theta));
      PVector pnew = new PVector(pnewx, pnewy);

      if (!isValidPoint(grid, cellsize, 
        ncells_width, ncells_height, 
        pnew, radius))
        continue;

      points.add(pnew);
      insertPoint(grid, cellsize, pnew);
      active.add(pnew);
      found = true;
      break;
    }

    /* If no point was found after k tries, remove p */
    if (!found)
      active.remove(random_index);
  }

  return points;
}

ArrayList<PVector> seedLocations() {
  ArrayList<PVector> seeds = new ArrayList<PVector>();
  int x = 0, y = 0;
  switch (seedPositionStrategy) {
  case SEED_POSITION_RANDOM:
    for (int i = 0; i < numSeedPoints; i++) {
      x = int(random(width));
      y = int(random(height));
      seeds.add(new PVector(x, y));
    }
    break;
  case SEED_POSITION_CENTER_ISH:
    for (int i = 0; i < numSeedPoints; i++) {
      x = width/2 + int(random(-width/10, width/10));
      y = height/2 + int(random(-height/10, height/10));
      seeds.add(new PVector(x, y));
    }
    break;
  case SEED_POSITION_CENTER:
    for (int i = 0; i < numSeedPoints; i++) {
      x = width/2;
      y = height/2;
      seeds.add(new PVector(x, y));
    }
    break;
  case SEED_POSITION_CORNER:
    for (int i = 0; i < numSeedPoints; i++) {
      x = 0;
      y = 0;
      seeds.add(new PVector(x, y));
    }
    break;
  case SEED_POSITION_POISSON:
    seeds = poissonDiskSampling(poissonRadius, poissonTries);
    seeds.add(new PVector(0, 0));
    break;
  case SEED_POSITION_DIAGONAL:
    for (int i = 0; i < width; i+= width/numSeedPoints) {
      x = i;
      y = int(map(i, 0, width - 1, height - 1, 0));
      seeds.add(new PVector(x, y));
    }
    break;
  }
  return seeds;
}

color seedColor(int x, int y) {
  color c = color(0);
  switch (seedColorStrategy) {
  case SEED_COLOR_RANDOM:
    if (colorType == RGB)
      c = color(random(255), random(255), random(255));
    else
      c = color(random(360), random(100), random(100));
    break;
  case SEED_COLOR_WHITE:
    if (colorType == RGB)
      c = color(255);
    else
      c = color(0, 0, 100);
    break;
  case SEED_COLOR_BLACK:
    if (colorType == RGB)
      c = color(0);
    else
      c = color(0, 100, 0);
    break;
  case SEED_COLOR_FIXED:
    if (colorType == RGB)
      c = color(255, 0, 0);
    else
      c = color(100, 100, 100);
    break;
  case SEED_COLOR_IMAGE:
    c = img.get(x, y);
  }
  return c;
}

PImage img;

void render() {
  img = loadImage("portrait8.jpg");

  if (colorType == RGB) {
    colorMode(RGB, 255, 255, 255);
  } else if (colorType == HSB) {
    colorMode(HSB, 360, 100, 100);
  }

  background(255);

  /* Initialize empty points array and colors/visited arrays */
  points = new ArrayList<PVector>();
  visited = new boolean[width * height];
  colors = new color[width * height];
  for (int i = 0; i < width * height; i++) {
    colors[i] = color(255);
    visited[i] = false;
  }

  /* Generate X,Y coordinates for seed points */
  ArrayList<PVector> seeds = seedLocations();
  for (int i = 0; i < seeds.size(); i++) {
    /* Generate color for seed point */
    color c = seedColor(int(seeds.get(i).x), int(seeds.get(i).y));
    /* Seed it! */
    seed(int(seeds.get(i).x), int(seeds.get(i).y), c);
  }

  /* Run iterations until there are no more points left to process */
  while (run());
}
