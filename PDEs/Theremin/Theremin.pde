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

// TODO should be really polymorphic.
TriOsc osc;
LowPass filter;

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
//    tracker = Boof.trackerTld(null, ImageDataType.F32);
//    tracker = Boof.trackerMeanShiftComaniciu(null, ImageType.ms(3,ImageFloat32.class));
//    tracker = Boof.trackerSparseFlow(null, ImageDataType.F32);

    f = createFont("Arial", 32, true);

    // Create and start the triangle wave oscillator.
    osc = new TriOsc(this);
    // filter
    filter = new LowPass(this);
    
    //Start the Oscillator. There will be no sound in the beginning
    //unless the mouse enters the   
    osc.play();

    // Filter process has to be after play().
    filter.process(osc, 800);
    filter.freq(1000);

}

void draw() {
  
    if (cam.available() == true) {
        cam.read();

        if ( mode == 1 ) {
            targetVisible = true;
        } else if ( mode == 2 ) {
            // user has selected the object to track so initialize the tracker using
            // a rectangle.  More complex objects and be initialized using a Quadrilateral.
            if (!tracker.initialize(cam, target.a.x, target.a.y, target.c.x, target.c.y) ) {
                mode = 100;
            } else {
                targetVisible = true;
                mode = 3;
            }
        } else if (mode == 3) {
            // Update the track state using the next image in the sequence
            if (!tracker.process(cam)) {
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

    // x mirroring to display
    pushMatrix();
    scale(-1, 1);
    image(cam, -width, 0);
    popMatrix();


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
  float x = width - mouseX;
  target.a.set(x, mouseY);
  target.b.set(x, mouseY);
  target.c.set(x, mouseY);
  target.d.set(x, mouseY);
}

void mouseDragged() {
  float x = width - mouseX;
  target.b.x = x;
  target.c.set(x, mouseY);
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
  // x mirroring
  double ax = width - target.a.x;
  double bx = width - target.b.x;
  double cx = width - target.c.x;
  double dx = width - target.d.x;
  line((float)ax, (float)target.a.y, (float)bx, (float)target.b.y);
  stroke(0, 255, 0);
  line((float)bx, (float)target.b.y, (float)cx, (float)target.c.y);
  stroke(0, 0, 255);
  line((float)cx, (float)target.c.y, (float)dx, (float)target.d.y);
  stroke(255, 0, 255);
  line((float)dx, (float)target.d.y, (float)ax, (float)target.a.y);
  
  textAlign(LEFT);
  // Reluctant down casting...
  float x = (float) ax;
  float y = (float) target.a.y;
  text("x=" + x, width/4, height - 15);
  text("y=" + y, width * 11/20, height - 15);

    // Map for amplitude
    float amp = map(y, 0, height, 2.0, 0.0);
    text("amp="+amp, width/4, height - 50);
    osc.amp(amp);

    // Map for frequency
    float freq = pow(2,map(x, 0, width, 1/12, 3))*220;
    text("freq="+freq, width/4, height - 80);
    osc.freq(freq);

    // Map from -1.0 to 1.0 for left to right 
    osc.pan(map(x, 0, width, -1.0, 1.0));

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
