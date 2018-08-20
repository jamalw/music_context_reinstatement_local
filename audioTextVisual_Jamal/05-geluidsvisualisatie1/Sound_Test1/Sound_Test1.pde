import geomerative.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import processing.video.*;
import java.util.Collections;
import java.util.Arrays;
import java.nio.file.*;
import java.io.File;

PImage fade;
FFT fft;
AudioPlayer[] player = new AudioPlayer[2];
Minim mySound; //CREATE A NEW SOUND OBJECT
AudioInput in;
RFont font;
Table word_table;
Table song_table;

String[] subj_id = {"test_subj"};
String[] datadir = {"/Users/jamalw/Desktop/PNI/music_context_reinstatement/"};

//Prepare variables for subject word lists creation
int run = 1;
int list_num = 0;


String[] myText = {"Music", "Sound", "Motion", "Grapes", "Process", "Test", "Block", "Color", "Octopus", "Matrix", "Farmer", "Astro"};

//String[] myText = {"Music", "Sound", "Motion", "Grapes"};

float rWidth, rHeight;
int hVal;
int counter = 0;
int frameCounter = 0;
String text;
int rate = 30;
int song_idx = 0;


//COULD USE A NOISE FUNCTION HERE FOR WIGGLE.
boolean stopAnime = false;

//----------------SETUP---------------------------------
void setup() {
  //Setup new subject if it has not been done already
  create_word_lists(datadir[0], subj_id[0]);
  create_song_list(datadir[0], subj_id[0]);
  
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
  player[0] = mySound.loadFile("Kamasi Washington - Change of the Guard-2 3.mp3",2048);
  player[1] = mySound.loadFile("11 Davibe.mp3",2048);
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
  float soundLevel = player[song_idx].mix.level(); //GET OUR AUDIO IN LEVEL
 
  //fft.forward(player.mix);
  
  RCommand.setSegmentLength(soundLevel*120);
  //RCommand.setSegmentLength(fft.getAvg(1)*2000);
  RCommand.setSegmentator(RCommand.UNIFORMLENGTH);
  
  text = myText[counter];
  RGroup myGoup = font.toGroup(text);
  frameCounter = frameCounter + (frameCount/frameCount);
  
  if (frameCounter == rate*3)
  {    
    counter = counter + 1;
    frameCounter = 0;
  }  
  
  if (counter > (myText.length * 1/2)-1)
  {
    player[0].pause();
    //player[song_idx = (song_idx + 1) % player.length].play();
    song_idx = 1;
    player[song_idx].play();
  }
  
  
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

//--------------Prepare subject's directory, word lists, and songs------------------


void create_word_lists (String datadir, String subj_id) {
  File f = new File(datadir + "data/" + subj_id + "/stimuli/word_lists/");
  f.mkdir();
  String[] lines = loadStrings(datadir + "stimuli/longpool_audio.csv");
  word_table = new Table();
  // create array of values ranging from 1 length of "lines"  
  Integer[] arr = new Integer[lines.length];
  for (int i = 0; i < arr.length; i++) {
      arr[i] = i;
  }
  
  // shuffle newly created array
  Collections.shuffle(Arrays.asList(arr));
  
  // use shuffled array to index words from "lines" and store indexed words into "newlines"
  String[] newlines = new String[arr.length];
  for(int i=0; i < arr.length; i++)
  {
      newlines[i] = lines[arr[i]];
  }
  
  // save every 12 words to its own csv file until we've looped through all of the words
  for(int i=0;i < newlines.length; i++)
  {
    TableRow newRow = word_table.addRow();
    newRow.setString(0,newlines[i]);
    if (word_table.getRowCount() % 12 == 0)
    { 
      String[] listdir = {datadir + "data/" + subj_id + "/stimuli/word_lists/" + str(run) + "_" + str(list_num) + ".csv"};
      saveTable(word_table, listdir[0]);
      word_table = new Table();
     
      if (list_num == 0){
        list_num = 1;
      } else {
        run = run + 1;
        list_num = 0;
      }
      
    } 
    
    
  }
}

void create_song_list (String datadir, String subj_id) {
  song_table = new Table();
  File f = new File(datadir + "stimuli/songs/");
  ArrayList<String> names = new ArrayList<String>(Arrays.asList(f.list()));
  names.remove(".DS_Store");
  Collections.shuffle(names);
  
  for(int i=0;i < names.size(); i++)
  {
    TableRow newRow = song_table.addRow();
    newRow.setString(0,names.get(i));
  }

saveTable(song_table, datadir + "data/" + subj_id + "/stimuli/songs/song_list.csv");
  
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
