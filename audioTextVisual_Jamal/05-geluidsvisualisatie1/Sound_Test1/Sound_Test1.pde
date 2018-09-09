import geomerative.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import processing.video.*;
import java.util.Collections;
import java.util.Arrays;
import java.nio.file.*;
import java.io.File;

PImage fade;
FFT fft;
AudioPlayer[] player = new AudioPlayer[21];
Minim mySound; //CREATE A NEW SOUND OBJECT

// for recording
Minim myRec;
AudioInput in;
AudioRecorder[] recorder = new AudioRecorder[12];
boolean recorded;

RFont font;
Table word_table;
Table song_table;
int[] conditions = {0,1,2,3,0,1,2,3,0,1,2,3};
String[] subj_id = {"test_subj"};
String[] datadir = {"/Users/jamalw/Desktop/PNI/music_context_reinstatement/"};
boolean displayinstructioncommand = true;
boolean display_end_of_list = false;
float rWidth, rHeight;
int hVal;
int counter = 0;
int frameCounter = 0;
int allwords_counter = 0;
int conds_counter = 0;
String text;
int rate = 30;
int song_idx = 0;
String[] instructions;
int index = 0;
String[] words;
String[] songs;
int run = 1;
int list_num = 0;
PrintWriter log;

//COULD USE A NOISE FUNCTION HERE FOR WIGGLE.
boolean stopAnime = false;

//----------------SETUP---------------------------------
void setup() {
  //Setup new subject if it has not been done already
  create_word_lists(datadir[0], subj_id[0]);
  create_song_list(datadir[0], subj_id[0]);
  create_data_directory(datadir[0], subj_id[0]);
  String[] instructions_split = loadStrings("FR_INSTRUCTIONS.txt");
  String instructions_join = join(instructions_split,"\n");  
  instructions = split(instructions_join,"\n");
  words = loadStrings(datadir[0] + "data/" + subj_id[0] + "/stimuli/word_lists/" + str(run) + "_" + str(list_num) +".csv");
  songs = loadStrings(datadir[0] + "data/" + subj_id[0] + "/stimuli/songs/song_list.csv");
  String subj_logfile = datadir[0] + "data/" + subj_id[0] + "/data/" + subj_id[0] + "_mcr.log";
  //size(900, 400);
  fullScreen();
  background(255);
  smooth();
  RG.init(this); 
  font = new RFont("FreeSans.ttf", 200, CENTER);
  mySound = new Minim(this);
  in = mySound.getLineIn(Minim.STEREO,2048);
  fade = get(0, 0,width, height);
  rWidth = width * 0.99;
  rHeight = height * 0.99;
  hVal = 0;
  for (int i = 0; i < songs.length; i++) {
    player[i] = mySound.loadFile(songs[i],2048);
  }  
  //fft = new FFT(player.bufferSize(),player.sampleRate());
  //fft.logAverages(60,7);
  frameRate(rate);  
  for (int i = 0; i < 12; i++){
    recorder[i] = mySound.createRecorder(in, datadir[0] + "data/" + subj_id[0] + "/data/myrecording_run_" + str(i) + ".wav");
  }
  log = createWriter(subj_logfile);
  
  
}

//----------------DRAW---------------------------------
void draw() {
  background(0);
  colorMode(HSB);
  stroke(hVal, 200, 200);
  colorMode(RGB);
  noFill();
  translate(width/2, height/1.75);
  
  if (displayinstructioncommand) {
    for (int i = 0; i < instructions.length; i++){
      fill(255);
      textAlign(CENTER,CENTER);
      text(instructions[i],-50,-250+i*20);
    }    
  } else if (display_end_of_list) {
    player[song_idx].pause();
    frameCounter = frameCounter + (frameCount/frameCount);
    if (frameCounter <= rate*3){
      textAlign(CENTER,CENTER);
      textSize(40);    
      text("End of List",0,-100);
      // rewind song for playback during recall
      rewind_song(conditions[conds_counter]);
    }
    if (frameCounter > rate*3 && frameCounter <= rate*6){
      textAlign(CENTER,CENTER);
      textSize(40);    
      text("Recall List",0,-100);           
    }
    if (frameCounter > rate*6 && frameCounter <= rate*10){
      textAlign(CENTER,CENTER);
      textSize(40);    
      text("...",0,-100);
      recorder[conds_counter].beginRecord();       
      if (frameCounter == rate*7){
        log.println(second() + "     event: Start Recording");
      }
      play_song(conditions[conds_counter]);
    }
    if (frameCounter == rate*10) {      
      recorder[conds_counter].endRecord();
      log.println(second() + "     event: End Recording");
      pause_song(conditions[conds_counter]);
      recorder[conds_counter].save();      
      log.println(second() + "     event: Save Recording");
    }
    if (frameCounter > rate*10 && frameCounter <= rate*13){
      textAlign(CENTER,CENTER);
      textSize(40);    
      text("Starting next run",0,-100);             
    }
    if (frameCounter == rate*13){
      display_end_of_list = false;
      counter = 0;
      allwords_counter = 0;
      frameCounter = 0;
      run = run + 1;
      log.println(second() + "     starting_run: " + run);
      list_num = 0;     
      words = loadStrings(datadir[0] + "data/" + subj_id[0] + "/stimuli/word_lists/" + str(run) + "_" + str(list_num) +".csv");
      
      if (conditions[conds_counter] == 2){
        song_idx = song_idx + 2;
      }else{
        song_idx = song_idx + 1;
      }
      
      conds_counter = conds_counter + 1;
      log.println(second() + "     playing_song: "+ song_idx + " - " + songs[song_idx]);
      log.println(second() + "     starting_list: 1");
      player[song_idx].play();
      log.flush();
      
    }
  } else {
    float soundLevel = player[song_idx].mix.level(); //GET OUR AUDIO IN LEVEL
    
    //fft.forward(player.mix);
    
    RCommand.setSegmentLength(soundLevel*300);
    //RCommand.setSegmentLength(fft.getAvg(1)*2000);
    RCommand.setSegmentator(RCommand.UNIFORMLENGTH);
    
    text = words[counter];    
    
    
    RGroup myGoup = font.toGroup(text);
    frameCounter = frameCounter + (frameCount/frameCount);
    
    // if x seconds (framerate * x) has passed then progress to the next word
    if (frameCounter == rate*1)
    {       
      log.println(second() + "     present_word: " + text);      
      counter = counter + 1;      
      println(counter);
      allwords_counter = allwords_counter + 1;
      frameCounter = 0;
      
    }
    
    // switch to list 2 and change to song 2
    setup_list2(conditions[conds_counter]);
    
    if (allwords_counter == 24) {
      display_end_of_list = true;
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
}

//--------------PREPARE SUBJECT'S DIRECTORY, WORD LISTS, AND SONGS------------------


void create_word_lists (String datadir, String subj_id) {
  //Prepare variables for subject word lists creation
  int run = 1;
  int list_num = 0;
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

void create_data_directory(String datadir, String subj_id) {
  File f = new File(datadir + "data/" + subj_id + "/data/");
  f.mkdir();  
  
}

//--------------FUNCTIONS FOR EXPERIMENT FLOW------------------

// This function rewinds a given song to playback during recall
void rewind_song (int cond_num) {
  if (cond_num == 0){        
    player[song_idx - 1].rewind();
  } else if (cond_num == 1 || cond_num == 3){        
    player[song_idx].rewind();        
  } else if (cond_num == 2) { 
    player[song_idx + 1].rewind();
  }  
}

// This function plays a given song during recall
void play_song (int cond_num) {
  int log_playtime = rate * 7;
  
  if (cond_num == 0){        
    player[song_idx - 1].play();
    if (frameCounter == log_playtime){
      log.println(second() + "     playing_song: "+ song_idx + " - " + songs[song_idx - 1]);
    }
  } else if (cond_num == 1 || cond_num == 3){        
    player[song_idx].play();        
    if (frameCounter == log_playtime){
      log.println(second() + "     playing_song: "+ song_idx + " - " + songs[song_idx]);
    }
  } else if (cond_num == 2) { 
    player[song_idx + 1].play();
    if (frameCounter == log_playtime){
      log.println(second() + "     playing_song: "+ song_idx + " - " + songs[song_idx + 1]);
    }
  }      
}

// This function pauses a given song after recall
void pause_song (int cond_num) {
  if (cond_num == 0){
    player[song_idx - 1].pause();
  } else if (cond_num == 1 || cond_num == 3){
    player[song_idx].pause();        
  } else if (cond_num == 2) {
    player[song_idx + 1].pause();
  }
}

// This function switches to list 2 and changes to song 2
void setup_list2(int cond_num){
  if (counter == words.length & list_num == 0) {      
    list_num = 1;
    words = loadStrings(datadir[0] + "data/" + subj_id[0] + "/stimuli/word_lists/" + str(run) + "_" + str(list_num) +".csv");
    counter = 0;
    frameCounter = 0;
    player[song_idx].pause();      
    if (cond_num == 0 || cond_num == 3){
      song_idx = song_idx + 1;
      player[song_idx].play();
    } else if (cond_num == 1 || cond_num == 2){
      player[song_idx].rewind();
      player[song_idx].play();
    }
    log.println(second() + "     playing_song: "+ song_idx + " - " + songs[song_idx]);
    log.println(second() + "     starting_list: 2");
    
  }  
}


//----------------KEYS---------------------------------
void keyReleased() {
  if (displayinstructioncommand) {
    displayinstructioncommand=false;
    log.println(second() + "     begin_exp   : " + subj_id[0]);
    log.println(second() + "     starting_run: " + run);
    log.println(second() + "     playing_song: 0 - " + songs[0]);
    player[0].play();     
    log.println(second() + "     starting_list: 1");    
    }
    else {
    if (key == 'f') 
      stopAnime = !stopAnime;
    if (stopAnime == true) 
      noLoop(); 
    else loop();
    }
}

void keyPressed() {
  if (key == ESC){
    log.flush();
    log.close();
  }
}

//////////////////////////////////////////////
