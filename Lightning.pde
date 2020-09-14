// partial implementation of standard Java library class

class Line2D {
  private double x1;
  private double y1;
  private double x2;
  private double y2;
  
  public Line2D(double ix1, double iy1, double ix2, double iy2) {
    x1 = ix1;
    y1 = iy1;
    x2 = ix2;
    y2 = iy2;
  }
    
  public double getX1() {
    return x1;
  }
   
  public double getY1() {
    return y1;
  }
  
  public double getX2() {
    return x2;
  }
  
  public double getY2() {
    return y2;
  }
}

// represents objects that can be drawn on screen
abstract class Drawable {
  private double age;

  public Drawable() {
    age = 0;
  }
  
  public double get_age() {
    return age;
  }
  
  public void add_age(double diff) {
    age += diff;
  }
  
  public abstract void display();
  public abstract boolean is_finished();
}

class LightningStrike extends Drawable {
  // class for a single lightning strike
  
  // various properties for generating and displaying lightning strikes
  final double max_beginning_bias = 0;
  final double spread = 1.5;
  final double split_chance_delta = 0.02;
  final double bias_change_max = 5;
  final double bias_mult_factor = 0.1;
  final double lightning_duration = 0.25;
  
  private ArrayList<Line2D> lines;

  public LightningStrike(double start_x, double start_y) {
    super();
    // start_x and start_y are the origin of the strike
    get_lines(start_x, start_y);
  }
  
  private void get_lines(double start_x, double start_y) {
    lines = new ArrayList<Line2D>();
    
    // split_chance is the chance that the lightning bolt will split at the next y level
    double split_chance = 0;
    // current horizontal locations of the lightning "legs"
    ArrayList<Double> locations = new ArrayList<Double>();
    locations.add((double)0);
    // biases of each of the lightning legs (essentially slopes)
    ArrayList<Double> biases = new ArrayList<Double>();
    biases.add(Math.random() * (2 * max_beginning_bias) - max_beginning_bias);
    // the multiplier for the change of bias at the next leg split
    ArrayList<Double> bias_change_factors = new ArrayList<Double>();
    bias_change_factors.add((double)1);

    for (int i = 0; i < screen_height; ++i) {
      // loop through screen one y-level at the time
      // i is the y-level
      for (int k = 0; k < locations.size(); ++k) {
        // loop through each lightning leg
        double location = locations.get(k);
        double bias = biases.get(k);
  
        // delta is how far the leg will move left or right
        double delta = Math.random() * (2 * spread) - spread + bias;
        double new_location = location + delta;
        locations.set(
          k,
          new_location
        );
  
        // add a new line to the set
        lines.add(new Line2D(
          start_x + location,
          start_y + i,
          start_x + new_location,
          start_y + i + 1
        ));
  
        // check if the leg should split
        if (Math.random() < split_chance) {
          // offset the current leg bias by the bias change,
          // use that as the bias for the new leg
          double bias_change_factor = bias_change_factors.get(k);
          double bias_change = (Math.random() * (2 * bias_change_max) - bias_change_max) * bias_change_factor;
          locations.add(location);
          biases.add(bias + bias_change);
          bias_change_factors.add(bias_change_factor * bias_mult_factor);
          // reset split_chance
          split_chance = 0;
        }
      }
      // split_chance increases with each y-level unless reset
      split_chance += split_chance_delta;
    }
  }

  public color get_current_color() {
    // current lightning bolt color
    // linearly interpolate between start color and end color depending on current age
    return lerpColor(
      color(0xff, 0xff, 0x00), // color yellow
      color(0xff, 0xff, 0xff), // color white
      (float)(get_age() / lightning_duration)
    );
  }

  public void display() {
    // display this lightning bolt
    color current_color = get_current_color();
    // set stroke color
    stroke(current_color);
    strokeWeight(0.5);
    // draw each line
    for (Line2D l : lines) {
      line(
        (float)l.getX1(),
        (float)l.getY1(),
        (float)l.getX2(),
        (float)l.getY2()
      );
    }
  }
    
  public boolean is_finished() {
    // is the lightning bolt finished displaying?
    return get_age() >= lightning_duration;
  }
}

class Cloud extends Drawable {
  private double cloud_width;
  private double cloud_height;
  private double start_x;
  private double start_y;
  private double speed;
  private color cloud_color;
  
  Cloud(double i_cloud_width, double i_cloud_height, double i_start_x, double i_start_y, double i_speed, color i_cloud_color) {
    super();
    cloud_width = i_cloud_width;
    cloud_height = i_cloud_height;
    start_x = i_start_x;
    start_y = i_start_y;
    speed = i_speed;
    cloud_color = i_cloud_color;
  }
  
  public double get_center_x() {
    return start_x + speed * get_age();
  }
  
  public double get_center_y() {
    return start_y;
  }
  
  public void display() {
    fill(cloud_color);
    stroke(color(0x00, 0x00, 0x00));
    strokeWeight(0.1);
    ellipse(
      (float)get_center_x(),
      (float)get_center_y(),
      (float)cloud_width,
      (float)cloud_height
    );
  }
  
  public boolean is_finished() {
    return get_center_x() - cloud_width / 2 > screen_width;
  }
}

// shapes are drawn according to the screen size written below
// they are scaled up or down to the actual screen size in the draw function
final int screen_width = 80;
final int screen_height = 30;
final double frame_rate = 30;
static ArrayList<Drawable> drawables; // currently displayed drawables
static ArrayList<Cloud> clouds;
static int frames_until_cloud; // frames until a new cloud is created

void setup() {
  size(800, 300);
  
  // set frame rate of screen
  frameRate((float)frame_rate);
  
  drawables = new ArrayList<Drawable>();
  clouds = new ArrayList<Cloud>();
  frames_until_cloud = 0;
}

void draw() {
  // scale so that whole drawing screen is visible
  // (shrink-to-fit)
  scale(Math.min(
    (float)width / screen_width,
    (float)height / screen_height
  ));

  // background is black
  background(color(0x00, 0x00, 0x40));

  // display each drawable
  for (Drawable drawable : drawables) {
    drawable.display();
  }
  
  // age each drawable and remove the ones that are finished
  ArrayList<Integer> removal_indices = new ArrayList<Integer>();
  for (int i = 0; i < drawables.size(); ++i) {
    Drawable drawable = drawables.get(i);
    drawable.add_age(1.0 / frame_rate); // time passed since last draw call in seconds (approximately)
    if (drawable.is_finished()) {
      removal_indices.add(i);
    }
  }
  for (Integer i_obj : removal_indices) {
    drawables.remove(i_obj);
  }
  
  // remove the clouds that are finished
  ArrayList<Integer> removal_indices2 = new ArrayList<Integer>();
  for (int i = 0; i < clouds.size(); ++i) {
    Cloud cloud = clouds.get(i);
    if (cloud.is_finished()) {
      removal_indices2.add(i);
    }
  }
  for (Integer i_obj : removal_indices2) {
    clouds.remove(i_obj);
  }
  
  if (frames_until_cloud == 0) {
    // if a new cloud is due
    double cloud_width = 20 + Math.random() * 30;
    double cloud_height = cloud_width / 4;
    double center_x = -cloud_width / 2;
    double center_y = Math.random() * (screen_height / 4);
    double speed = 2 + Math.random() * 3;
    color cloud_color = lerpColor(color(0x60, 0x60, 0x60), color(0xa0, 0xa0, 0xa0), (float)Math.random());
    // create new cloud
    Cloud new_cloud = new Cloud(cloud_width, cloud_height, center_x, center_y, speed, cloud_color);
    drawables.add(new_cloud);
    clouds.add(new_cloud);
    frames_until_cloud = (int)(frame_rate * 5); // new cloud in 5 seconds
  }
  else {
    --frames_until_cloud;
  }
}

void mousePressed() {
  println(clouds.size());
  println(drawables.size());
  // generates a lightning strike from a random cloud
  int i = (int)(Math.random() * clouds.size());
  Cloud cloud = clouds.get(i);
  double start_x = cloud.get_center_x();
  double start_y = cloud.get_center_y();
  LightningStrike new_lightning_strike = new LightningStrike(start_x, start_y);
  drawables.add(new_lightning_strike);
}
