import java.util.ArrayList;
import java.util.LinkedList;
import java.util.ListIterator;
import java.util.Arrays;
import java.util.Properties;
import java.io.InputStream;
import java.io.IOException;
import java.net.URL;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.geom.Line2D;

int get_int_prop(Properties props, String key) {
  // get the value of the property key as an integer
  return Integer.parseInt(props.getProperty(key));
}
  
double get_double_prop(Properties props, String key) {
  // get the value of the property key as a double
  return Double.parseDouble(props.getProperty(key));
}

class LightningStrike {
  // class for a single lightning strike
  
  // various properties for generating and displaying lightning strikes
  final int screen_width = get_int_prop(props, "screen_width");
  final int screen_height = get_int_prop(props, "screen_height");
  final double max_beginning_bias = get_double_prop(props, "max_beginning_bias");
  final double spread = get_double_prop(props, "spread");
  final double split_chance_delta = get_double_prop(props, "split_chance_delta");
  final double bias_change_max = get_double_prop(props, "bias_change_max");
  final double bias_mult_factor = get_double_prop(props, "bias_mult_factor");
  final double lightning_duration = get_double_prop(props, "lightning_duration");
  
  private ArrayList<Line2D.Double> lines;
  private double age; // time since creation, in seconds

  public LightningStrike(double start_x, double start_y) {
    // start_x and start_y are the origin of the strike
    get_lines(start_x, start_y);
    age = 0;
  }
  
  private void get_lines(double start_x, double start_y) {
    lines = new ArrayList<Line2D.Double>();
    
    // split_chance is the chance that the lightning bolt will split at the next y level
    double split_chance = 0;
    // current horizontal locations of the lightning "legs"
    ArrayList<Double> locations = new ArrayList<Double>(
      Arrays.asList(0d)
    );
    // biases of each of the lightning legs (essentially slopes)
    ArrayList<Double> biases = new ArrayList<Double>(
      Arrays.asList(Math.random() * (2 * max_beginning_bias) - max_beginning_bias)
    );
    // the multiplier for the change of bias at the next leg split
    ArrayList<Double> bias_change_factors = new ArrayList<Double>(
      Arrays.asList(1.0d)
    );
    for (int i = 0; i < screen_height; ++i) {
      // loop through screen one y-level at the time
      // i is the y-level
      for (int k = 0; k < locations.size(); ++k) {
        // loop through each lightning leg
        double location = locations.get(k).doubleValue();
        double bias = biases.get(k).doubleValue();
  
        // delta is how far the leg will move left or right
        double delta = Math.random() * (2 * spread) - spread + bias;
        double new_location = location + delta;
        locations.set(
          k,
          new_location
        );
  
        // add a new line to the set
        lines.add(new Line2D.Double(
          start_x + location,
          start_y + i,
          start_x + new_location,
          start_y + i + 1
        ));
  
        // check if the leg should split
        if (Math.random() < split_chance) {
          // offset the current leg bias by the bias change,
          // use that as the bias for the new leg
          double bias_change_factor = bias_change_factors.get(k).doubleValue();
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
      (float)(age / lightning_duration)
    );
  }

  public void display() {
    // display this lightning bolt
    color current_color = get_current_color();
    // set stroke color
    stroke(current_color);
    strokeWeight(0.5);
    // draw each line
    for (Line2D.Double line : lines) {
      line(
        (float)line.getX1(),
        (float)line.getY1(),
        (float)line.getX2(),
        (float)line.getY2()
      );
    }
  }
  
  public void add_age(double diff) {
    // add diff seconds to the age
    age += diff;
  }
  
  public boolean is_finished() {
    // is the lightning bolt finished displaying?
    return age >= lightning_duration;
  }
}

static Properties props; // stores properties for the program
static Dimension screen_dimens;
static double frame_rate;

void get_props() {
  // fills out the program properties
  props = new Properties();

  props.setProperty("screen_width", "80");
  props.setProperty("screen_height", "30");
  props.setProperty("max_beginning_bias", "0");
  props.setProperty("spread", "1.5");
  props.setProperty("split_chance_delta", "0.02");
  props.setProperty("bias_change_max", "5");
  props.setProperty("bias_mult_factor", "0.1");
  props.setProperty("lightning_duration", "0.5");
  props.setProperty("frame_rate", "30");
}

void get_screen_dimens() {
  // get screen_dimens from the properties
  screen_dimens = new Dimension(
    get_int_prop(props, "screen_width"),
    get_int_prop(props, "screen_height")
  );
}

void get_frame_rate() {
  // get frame_rate from the properties
  frame_rate = get_double_prop(props, "frame_rate");
}

static LinkedList<LightningStrike> lightning_strikes; // currently displayed lightning strikes
static int frames_until_lightning_strike; // frames until a new lightning strike is created

void setup() {
  surface.setTitle("Lightning");
  size(800, 300);
  surface.setResizable(true);
  
  get_props();
  get_screen_dimens();
  get_frame_rate();
  
  // set frame rate of screen
  frameRate((float)frame_rate);
  
  lightning_strikes = new LinkedList<LightningStrike>();
  frames_until_lightning_strike = 0;
}

void draw() {
  // scale so that whole drawing screen is visible
  // (shrink-to-fit)
  scale(Math.min(
    (float)width / screen_dimens.width,
    (float)height / screen_dimens.height
  ));

  // background is black
  background(color(0x00, 0x00, 0x40));

  // display each strike
  for (LightningStrike strike : lightning_strikes) {
    strike.display();
  }
  
  // age each strike and remove the ones that are finished
  ListIterator<LightningStrike> it = lightning_strikes.listIterator();
  while (it.hasNext()) {
    LightningStrike strike = it.next();
    strike.add_age(1.0 / frame_rate); // time passed since last draw call in seconds (approximately)
    if (strike.is_finished()) {
      it.remove();
    }
  }
  
  if (frames_until_lightning_strike == 0) {
    // if a new lightning strike is due
    double start_x = 0.5 * screen_dimens.width; // halfway across the screen horizontally
    double start_y = 0; // top of the screen
    lightning_strikes.add(new LightningStrike(start_x, start_y));
    frames_until_lightning_strike = (int)(frame_rate * 1); // new lightning strike in 1 second
  }
  else {
    --frames_until_lightning_strike;
  }
}
