import processing.video.*;

Capture cam;
PImage prevFrame;
float angleX = 0;
float angleY = 0;

void setup() {
  size(800, 600, P3D);
  
  // List all available cameras
  String[] cameras = Capture.list();
  println("\nAvailable cameras:");
  for (int i = 0; i < cameras.length; i++) {
    println(cameras[i]);
  }
  
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    cam = new Capture(this, cameras[0]);
    cam.start();
    prevFrame = createImage(cam.width, cam.height, RGB);
  }
  
  strokeWeight(1.5);
  stroke(255);
}

void draw() {
  if (cam.available()) {
    cam.read();
    prevFrame.copy(cam, 0, 0, cam.width, cam.height, 0, 0, cam.width, cam.height);
    prevFrame.loadPixels();
    
        image(cam, 0, 0);
    background(0);
    translate(width/2, height/2, 0);
    rotateY(angleY);
    rotateX(angleX);
    
    // Sample points from the image
    int spacing = 6; // Decreased spacing for more points
    
    for (int x = spacing; x < prevFrame.width - spacing; x += spacing) {
      for (int y = spacing; y < prevFrame.height - spacing; y += spacing) {
        // Get brightness of current pixel
        color currentColor = prevFrame.get(x, y);
        float currentBrightness = brightness(currentColor);
        
        // Calculate local contrast by comparing with surrounding pixels
        float totalDifference = 0;
        int samples = 0;
        
        // Check surrounding pixels in a 3x3 grid
        for (int dx = -spacing; dx <= spacing; dx += spacing) {
          for (int dy = -spacing; dy <= spacing; dy += spacing) {
            if (dx == 0 && dy == 0) continue;
            
            int nx = x + dx;
            int ny = y + dy;
            
            if (nx >= 0 && nx < prevFrame.width && ny >= 0 && ny < prevFrame.height) {
              color neighborColor = prevFrame.get(nx, ny);
              float neighborBrightness = brightness(neighborColor);
              totalDifference += abs(currentBrightness - neighborBrightness);
              samples++;
            }
          }
        }
        
        // Calculate average contrast
        float contrast = totalDifference / samples;
        
        // Adjust threshold based on the new contrast calculation method
        if (contrast > 15) { // Lowered threshold since we're using average difference
          // Use brightness for z-depth and contrast for point size
          float z = map(currentBrightness, 0, 255, 50, -150);
          
          // Map coordinates to center the point cloud
          float mappedX = map(x, 0, prevFrame.width, -200, 200);
          float mappedY = map(y, 0, prevFrame.height, -150, 150);
          
          // Color points based on the original image and contrast
          color pointColor = currentColor;
          stroke(red(pointColor), green(pointColor), blue(pointColor), map(contrast, 0, 50, 100, 255));
          
          // Adjust point size based on contrast
          strokeWeight(map(contrast, 15, 50, 1, 3));
          
          point(mappedX, mappedY, z);
        }
      }
    }
    
    // Update rotation angles for animation
    angleY += 0.01;
    
    // Reset stroke weight for text
    strokeWeight(1);
    
    // Display info
    camera();
    fill(255);
    noStroke();
    text("Frame rate: " + int(frameRate) + "\nPress mouse to rotate\nPoints vary by contrast", 10, 20);
  }
}

void mouseDragged() {
  angleY += (mouseX - pmouseX) * 0.01;
  angleX += (mouseY - pmouseY) * 0.01;
}
