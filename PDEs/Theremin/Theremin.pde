// Theremin on Processing with the camera

// Launches your webcam and when you select an object it will track it.
// X axis is for pitch.
// Y axis is for amplitude.

import processing.video.*;
import boofcv.processing.*;
import boofcv.struct.image.*;
import georegression.struct.point.*;
import georegression.struct.shapes.*;

import processing.sound.*;


Capture cam;
SimpleTrackerObject tracker;

// TODO should be polymorphic.
TriOsc osc;

// storage for where the use selects the target and the current target location
// http://georegression.org/javadoc/georegression/struct/GeoTuple2D_F64.html#x
Quadrilateral_F64 target = new Quadrilateral_F64();
// if true the target has been detected by the tracker
boolean targetVisible = false;
PFont f;
// indicates if the user is selecting a target or if the tracker is tracking it
int mode = 0;

void setup() {
  // Open up the camera so that it has a video feed to process
  // VGA of iSight 640x480
  // Assuming FaceTime HD (720p)
  // 720p format which has a resolution of 1280x720
  //initializeCamera(320, 240);
  initializeCamera(1280, 720);
  size(cam.width, cam.height);

  // Select which tracker you want to use by uncommenting and commenting the lines below
  tracker = Boof.trackerCirculant(null, ImageDataType.F32);
//    tracker = Boof.trackerTld(null,ImageDataType.F32);
//    tracker = Boof.trackerMeanShiftComaniciu(null, ImageType.ms(3,ImageFloat32.class));
//    tracker = Boof.trackerSparseFlow(null, ImageDataType.F32);

  f = createFont("Arial", 32, true);

    // Create and start the triangle wave oscillator.

    osc = new TriOsc(this);
    
    // TODO filter
    
    //Start the Oscillator. There will be no sound in the beginning
    //unless the mouse enters the   
    osc.play();

}

void draw() {
  if (cam.available() == true) {
    cam.read();

    if ( mode == 1 ) {
      targetVisible = true;
    } else if ( mode == 2 ) {
      // user has selected the object to track so initialize the tracker using
      // a rectangle.  More complex objects and be initialized using a Quadrilateral.
      if ( !tracker.initialize(cam, target.a.x, target.a.y, target.c.x, target.c.y) ) {
        mode = 100;
      } else {
        targetVisible = true;
        mode = 3;
      }
    } else if ( mode == 3 ) {
      // Update the track state using the next image in the sequence
      if ( !tracker.process(cam) ) {
        // it failed to detect the target.  Depending on the tracker this could mean
        // the track is lost for ever or it could be recovered in the future when it becomes visible again
        targetVisible = false;
      } else {
        // tracking worked, save the results
        targetVisible = true;
        target.set(tracker.getLocation());
      }
    }
  }
  image(cam, 0, 0);

  // The code below deals with visualizing the results
  textFont(f);
  textAlign(CENTER);
  fill(0, 0xFF, 0);
  if ( mode == 0 ) {
    text("Click and Drag", width/2, height/4);
  } else if ( mode == 1 || mode == 2 || mode == 3) {
    if ( targetVisible ) {
      drawTarget();
    } else {
      text("Can't Detect Target", width/2, height/4);
    }
  } else if ( mode == 100 ) {
    text("Initialization Failed.\nSelect again.", width/2, height/4);
  }
}

void mousePressed() {
  // use is draging a rectangle to select the target
  mode = 1;
  target.a.set(mouseX, mouseY);
  target.b.set(mouseX, mouseY);
  target.c.set(mouseX, mouseY);
  target.d.set(mouseX, mouseY);
}

void mouseDragged() {
  target.b.x = mouseX;
  target.c.set(mouseX, mouseY);
  target.d.y = mouseY;
}

void mouseReleased() {
  // After the mouse is released tell it to initialize tracking
  mode = 2;
}

// Draw the target using different colors for each side so you can see if it is rotating
// Most trackers don't estimate rotation.
void drawTarget() {
  noFill();
  strokeWeight(3);
  stroke(255, 0, 0);
  line(target.a, target.b);
  stroke(0, 255, 0);
  line(target.b, target.c);
  stroke(0, 0, 255);
  line(target.c, target.d);
  stroke(255, 0, 255);
  line(target.d, target.a);
  
  textAlign(LEFT);
  text("x=" + target.a.x, width/4, height - 15);
  text("y=" + target.a.y, width * 11/20, height - 15);

    // Map for amplitude
    float amp = 2/map((float)target.a.y, 0, height, 2.0, 0.0);
    text("amp="+amp, width/4, height - 50);
    osc.amp(amp);

    // Map for frequency
    //tri.freq(map(log2((float)target.a.x), 0, width, 80.0, 4000.0));
    float freq = pow(2,map((float)target.a.x, 0, width, 1/12, 3))*220;
    text("freq="+freq, width/4, height - 80);
    osc.freq(freq);

    // Map from -1.0 to 1.0 for left to right 
    osc.pan(map((float)target.a.x, 0, width, -1.0, 1.0));

}
// Calculates the base-10 logarithm of a number
float log2 (float x) {
  return (log(x) / log(2));
}

void line( Point2D_F64 a, Point2D_F64 b ) {
  line((float)a.x, (float)a.y, (float)b.x, (float)b.y);
}

void initializeCamera( int desiredWidth, int desiredHeight ) {
  String[] cameras = Capture.list();

  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    cam = new Capture(this, desiredWidth, desiredHeight);
    cam.start();
  }
}
