// we need to import the TUIO library and declare a TuioProcessing client variable
import TUIO.*;
import java.util.*;

TuioProcessing tuioClient;
int port = 3333;
TuioCursor tuioCursor1 = null;
TuioCursor tuioCursor2 = null;
TuioCursor tuioCursor3 = null;
Vector cursorPath;

float desiredImageWidth = sketchWidth/8;
float startDistance, currDistance;
float prevZoomFactor, zoomFactor;

float prevTapTimeStamp;
float tapTimeStamp = 0;

boolean staticCursor = false;

// distance between finger and selected picture's center
int dx, dy;

void initTUIO() {
  // we create an instance of the TuioProcessing client
  // since we add "this" class as an argument the TuioProcessing class expects
  // an implementation of the TUIO callback methods (see below)
  if(MPE_ON){
    if(tileConfig.isLeader()) tuioClient  = new TuioProcessing(this, 3333);
    else tuioClient  = new TuioProcessing(this, 3334);
    println("\n" + "Leader process listening for TUIO on port 3333 .....");
    println("\n" + "Client processes listening for TUIO on port 3334 .....");
  } else {
    tuioClient  = new TuioProcessing(this, port);
    println("\n" + "TUIO client listening on port " + port + " .....");
  }
}

float getDistance(TuioCursor tuioCursor1, TuioCursor tuioCursor2) {
  return dist(tuioCursor1.getScreenX(sketchWidth), tuioCursor1.getScreenY(sketchHeight), 
              tuioCursor2.getScreenX(sketchWidth), tuioCursor2.getScreenY(sketchHeight));
}

boolean doubleTapped(TuioCursor finger) {
  if(tapTimeStamp == 0) {
    tapTimeStamp = finger.getTuioTime().getTotalMilliseconds()*0.001;
    return false;
  } else {
    prevTapTimeStamp = tapTimeStamp;
    tapTimeStamp = finger.getTuioTime().getTotalMilliseconds()*0.001;
    if((tapTimeStamp-prevTapTimeStamp) < 0.5) {
      tapTimeStamp = 0; // reset for next time
      return true;
    } else return false;
  }
}

// these callback methods are called whenever a TUIO event occurs
// called when a cursor is added to the scene
void addTuioCursor(TuioCursor tcur) { 
  if (tuioCursor1 == null) {
    tuioCursor1 = tcur;    
    for(int i=0; i<pictures.length; i++) {
      if(pictures[i].isPicked()) {
        // update offsets cursor #1 is added
        pictures[i].setxOffset(tuioCursor1.getScreenX(sketchWidth) - pictures[i].getX());
        pictures[i].setyOffset(tuioCursor1.getScreenY(sketchHeight) - pictures[i].getY());
        
        if(doubleTapped(tuioCursor1)) pictures[i].flip();
      } 
    }
  } 
  else if (tuioCursor2 == null) {
    // zooming & rotating
    tuioCursor2 = tcur; 
    startDistance = getDistance(tuioCursor1, tuioCursor2);
    prevZoomFactor = zoomFactor;
  }
  else if (tuioCursor3 == null) {
    tuioCursor3 = tcur;
    // deselect picture with 3 finger touch. 
    for (int i=0; i<pictures.length; i++){   
      pictures[i].unPick();
    }     
  }
}

// called when a cursor is moved
void updateTuioCursor (TuioCursor tcur) { 
  if (tuioCursor1 != null && tuioCursor2 != null) {    
    for (int i=0; i<pictures.length; i++) {
      if(pictures[i].isPicked()) {
        // zoom
        currDistance = getDistance(tuioCursor1, tuioCursor2);
        zoomFactor = prevZoomFactor*(currDistance/startDistance);
        pictures[i].setZoom(zoomFactor); // get picture's scale value in case user zooms
      }
    }
  } 
  
  else if (tuioCursor1 != null) {        
    cursorPath = tuioCursor1.getPath();
   
    // check if cursor is moving or not
    if(cursorPath.size() > 0) {
      TuioPoint previous = (TuioPoint)cursorPath.elementAt(cursorPath.size()-2);
      if (previous.getScreenX(width) == tuioCursor1.getScreenX(width) && previous.getScreenY(height) == tuioCursor1.getScreenY(height)) staticCursor = true;
      else staticCursor = false;
    }

    // move selected picture to current cursor position
    for (int i=0; i<pictures.length; i++) {
      if(pictures[i].isPicked()) {
        zoomFactor = pictures[i].getZoom();
        pictures[i].setXY(tuioCursor1.getScreenX(sketchWidth)-pictures[i].getxOffset(), tuioCursor1.getScreenY(sketchHeight)-pictures[i].getyOffset());
      }
    }
  } 
}

// called when a cursor is removed from the scene
void removeTuioCursor(TuioCursor tcur) {
  if (tuioCursor3 != null && tuioCursor3.getCursorID() == tcur.getCursorID()) {
    // remove 3rd cursor
    tuioCursor3 = null;
  }
  
  if (tuioCursor2 != null && tuioCursor2.getCursorID() == tcur.getCursorID()) {
    // remove 2nd cursor
    tuioCursor2 = null;
    // If 3rd cursor still exists, make it the 2nd cursor
    if (tuioCursor3 != null) {
      tuioCursor2 = tuioCursor3;
      tuioCursor3 = null; 
    }
  }
  
  if (tuioCursor1 != null && tuioCursor1.getCursorID() == tcur.getCursorID()) {
    // remove 1st cursor
    tuioCursor1 = null;
    // If 2nd cursor still exists, make it the 1st cursor
    if (tuioCursor2 != null) {
      tuioCursor1 = tuioCursor2;
      tuioCursor2 = null; 
      
      // update offsets due to cursor exchange
      for(int i=0; i<pictures.length; i++) {
        if(pictures[i].isPicked()) {
          pictures[i].setxOffset(tuioCursor1.getScreenX(sketchWidth) - pictures[i].getX());
          pictures[i].setyOffset(tuioCursor1.getScreenY(sketchHeight) - pictures[i].getY());
        } 
      }
    }    
    // If 3rd cursor still exists, make it the 2nd cursor
    if (tuioCursor3 != null) {
      tuioCursor2 = tuioCursor3;
      tuioCursor3 = null; 
    }
  }
  
}

// called after each message bundle representing the end of an image frame
void refresh(TuioTime bundleTime) { 
  redraw();
} 

// NOT NEEDED
public void addTuioObject(TuioObject tobj) {}
public void updateTuioObject(TuioObject tobj) {}  
public void removeTuioObject(TuioObject tobj) {}

