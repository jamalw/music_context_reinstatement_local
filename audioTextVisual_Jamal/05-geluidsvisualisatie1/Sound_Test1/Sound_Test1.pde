import geomerative.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import processing.video.*;
PImage fade;
FFT fft;
//AudioPlayer player;
AudioPlayer[] player = new AudioPlayer[2];
Minim mySound; //CREATE A NEW SOUND OBJECT
AudioInput in;
RFont font;
int song_idx;

//String[] myText = {"Music", "Sound", "Motion", "Grapes", "Process", "Test", "Block", "Color", "Octopus", "Matrix", "Farmer", "Astro"};
String[] myText = {"Music", "Sound", "Motion", "Grapes", "Process", "Test"};

float rWidth, rHeight;
int hVal;
int time = millis();
int counter = 0;
int frameCounter = 0;
String text;
int rate = 30;

  //COULD USE A NOISE FUNCTION HERE FOR WIGGLE.
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
  //player[0] = mySound.loadFile("u.wav");
  player[0] = mySound.loadFile("Kamasi Washington - Change of the Guard-2 3.mp3",2048);
  player[1] = mySound.loadFile("Stelvio Cipriani - Mary's Theme [1969].wav",2048);
  player[0].play();
  //fft = new FFT(player.bufferSize(),player.sampleRate());
  //fft.logAverages(60,7);
  frameRate(rate);
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
  float soundLevel = player[0].mix.level(); //GET OUR AUDIO IN LEVEL
 
  //fft.forward(player.mix);
  
  RCommand.setSegmentLength(soundLevel*270);
  //RCommand.setSegmentLength(fft.getAvg(1)*2000);
  RCommand.setSegmentator(RCommand.UNIFORMLENGTH);
  
  text = myText[counter];
  RGroup myGoup = font.toGroup(text);
  frameCounter = frameCounter + (frameCount/frameCount);
  
  if (frameCounter == rate*6)
  {    
    counter = counter + 1;
    frameCounter = 0;
  }  
  
  if
  
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

//////////////////////////////////////////////
