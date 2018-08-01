import geomerative.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import processing.video.*;
PImage fade;
FFT fft;
AudioPlayer player;
Minim mySound; //CREATE A NEW SOUND OBJECT
AudioInput in;
RFont font;

//String myText = "GELUID";
String[] myText = {"Apple", "Banana", "Orange", "Grapes"};

float rWidth, rHeight;
int hVal;

  //COULD USE A NOISE FUNCTION HERE FOR WIGGLE.
//float wiggle = 3.7;
boolean stopAnime = false;

//----------------SETUP---------------------------------
void setup() {
  size(900, 400);
  background(255);
  smooth();
  RG.init(this); 
  font = new RFont("FreeSans.ttf", 200, CENTER);
  mySound = new Minim(this);
  in = mySound.getLineIn(Minim.STEREO,512);
  fade = get(0, 0,width, height);
  rWidth = width * 0.99;
  rHeight = height * 0.99;
  hVal = 0;
  player = mySound.loadFile("Kamasi Washington - Change of the Guard-2 3.mp3",2048);
  player.play();
  fft = new FFT(player.bufferSize(),player.sampleRate());
  fft.logAverages(60,7);
}

//----------------DRAW---------------------------------
void draw() {
  background(255);
  image(fade, (width - rWidth) / 2, (height - rHeight) / 2, rWidth, rHeight);
  colorMode(HSB);
  stroke(hVal, 200, 200);
  colorMode(RGB);
  noFill();
  translate(width/2, height/1.5);
  float soundLevel = player.mix.level(); //GET OUR AUDIO IN LEVEL
 
  fft.forward(player.mix);
  
  RCommand.setSegmentLength(soundLevel*270);
  //RCommand.setSegmentLength(fft.getAvg(1)*2000);
  RCommand.setSegmentator(RCommand.UNIFORMLENGTH);

  RGroup myGoup = font.toGroup(myText[0]); 
  RPoint[] myPoints = myGoup.getPoints();

  beginShape(TRIANGLE_STRIP);
  
  
  for (int i=0; i<myPoints.length; i++)
  //for(int i=0; i<fft.avgSize();i++)
  {
    vertex(myPoints[i].x, myPoints[i].y);
  }
  //fade = get(0, 0, width, height);    
  
  hVal += 2;
  if ( hVal > 255)
  {
    hVal = 0;
  }
    
 
  endShape();
}

//----------------KEYS---------------------------------
void keyReleased() {
  if (key == 'f') 
    stopAnime = !stopAnime;
  if (stopAnime == true) 
    noLoop(); 
  else loop();
}

//void keyPressed() {
//  if (key == '1')
//    myText = "GELUID";
//  if (key == '2')
//    myText = "SOUND";
//  if (key == '3')
//    myText = "MOTION";
//}
//////////////////////////////////////////////
