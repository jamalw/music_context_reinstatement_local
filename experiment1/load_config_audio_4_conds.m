function[config] = load_config_audio_4_conds()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Directed Forgetting Free Recall, fMRI/EEG version ("dfFr") %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [Experiment Description]: Participants view a total of 24  %
% lists, divided into 12 blocks.  The items on the first     %
% list in each block are separated by presentations of       %
% scene images.  The items on the second list in each block  %
% are separated by black screen.  After the first list in    %
% a block the participant receives either a forget cue (X)   %
% or a remember cue (+), instructing them to either forget   %
% or remember the items from the first list in the block.    %
% After the list item in the second list, participants are   %
% asked to remember either the second list items (if the cue %
% was a forget cue) or *either* the first or second list     %
% items (if the cue was a remember cue).  A critical         %
% manipulation is that for the last block participants are   %
% tricked: they are given a forget cue but are asked to      %
% the first list's items.  The experiment also includes a    %
% localizer task at the end.                                 %
%                                                            %
% [Author]: Jeremy R. Manning (manning3@princeton.edu)       %
% [Date]:   March 16, 2013                                   %
% [File]:   configuration file (adjust experiment timing     %
%           and params)                                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%change log
%jrm 3-16-13 wrote it (based on load_config_classFR)

%#ok<*UNRCH>
config.DEBUG_MODE = true;
config.fMRI = false;
config.EEG = false;
config.BUTTON_BOX = false;
config.DUAL_SCREEN = true;
config.RUN_WORD_LOCALIZER = true;

%Timing parameters --> note that for fMRI experiments stimulus
%presentations (of words) will be locked to TR pulses.  The stimuli will be
%presented when the first pulse is received after the specified time has
%elapsed.  All presentation times and pulse times will be logged, and any
%analyses of timing information should rely on the log file rather than the
%times specified below.
config.fixDur = 1000;     %ms
config.fixISI = 1000;      %ms
config.fixJitter = 0;   %ms (uniformly chosen in this range-- 0 to fixJitter)
config.wordDur = 3000;    %ms
config.wordISI = 2700;    %ms
config.wordJitter = 0;  %ms (uniformly chosen in this range-- 0 to wordJitter)
config.sceneISI = 50; %ms
config.sceneJitter = 0; %ms
config.cueDur = 3000; %ms
config.beepDur = 300;     %ms
config.recallDur = 60*1000; %ms
config.localizerDur = 500; %ms
config.localizerISI = 1300; %ms
config.localizerIBI = 12000; %ms
config.structuralDur = 15*60;  %s -- NOTE DIFFERENT UNITS THAN OTHER TIMINGS
config.recognition_question_dur = 9000;

%Localizer
config.localizerImages = {'scenes', 'scrambled_scenes', 'objects'};
config.localizerOnebackMatchProb = 0.15;
config.localizerListLen = 20;
config.localizerWordpool = 'localizer_words.csv';


%Display settings
config.stimTextHeight = 0.1;
config.stimTextColor = [1 1 1];

%Hard-coded instructions
config.fixCross = '+';
config.breakText = 'You have finished this block.\nYou may now take a short break.';
config.structuralScanText = 'You are done with the main experiment!\n\nWe need to do one last scan,\nso please remain still...';
config.endText = 'Thank you!\nYou are done!';
config.debugMicText = 'Please check sound input/output\nsettings and try again.';
config.debugButtonBoxText = 'Please check button box cable\nand try again.';
config.waitForScanStartText = '     ****** EXPERIMENTER: PRESS ANY KEY PRIOR TO STARTING SCAN ******';
config.scanReadyText = '     ****** LISTENING FOR PULSES ******';
config.forget = '< FORGET >';
config.remember = '< REMEMBER >';
config.recall_first = '< RECALL LIST >';
config.recall_second = '< RECALL LIST >';
config.end_L1 = '< END OF LIST 1 >';
config.end_L2 = '< END OF LIST >';
config.pre_rec = 'Listen to this clip';
config.recognition = 'Does the clip match a song \n from the previous list? \n Press (y)es or (n)o';
config.correct = 'Correct';
config.incorrect = 'Incorrect';

%Files
config.docs_folder = 'docs';
config.images_folder = 'images';
config.wordpool = 'longpool_audio.csv';
config.example_wordpool = 'example_list.csv';
config.example_wordpool_2 = 'example_list_2.csv';
config.logfile = 'log.txt';

%Experimental structure
config.nBlocks = 12;
config.nLists = 2*config.nBlocks;
config.scenesPerWord = 3;
config.miniBlockSize = 8;
config.nMiniBlocks = 9; %per category

%Other parameters
config.beepFreq = 800; %Hz
config.counter = 1;
config.recog_counter = 1;

%instructions
config.fr_instructions = 'FR_INSTRUCTIONS.txt';
config.fr_instructions_summary = 'FR_SUMMARY.txt';
config.oneback_instructions = 'ONEBACK_INSTRUCTIONS.txt';
config.oneback_instructions_summary = 'ONEBACK_INSTRUCTIONS_SUMMARY.txt';
config.word_localizer_instructions = 'WORD_LOCALIZER.txt';
config.word_localizer_instructions_summary = 'WORD_LOCALIZER_SUMMARY.txt';


%logging
config.logfile = 'log.txt';

%debugging params (makes experiment go much faster)
if config.DEBUG_MODE  
    config.fixDur = 25;       %ms
    config.fixISI = 25;        %ms
    config.fixJitter = 0;      %ms (uniformly chosen in this range-- 0 to fixJitter)
    config.wordDur = 25;      %ms
    config.scenesPerWord = 1;
    config.wordISI = 50;       %ms
    config.wordJitter = 0;     %ms (uniformly chosen in this range-- 0 to wordJitter)
    config.beepDur = 50;      %ms
    config.recallDur = 100;    %ms
    config.sceneDur = 50;  %ms
    config.sceneISI = 25; %ms
    config.sceneJitter = 0; %ms
    config.structuralDur = 5;  %s -- NOTE DIFFERENT UNITS THAN OTHER TIMINGS
    config.localizerDur = 25; %ms
    config.localizerISI = 25; %ms
    config.localizerIBI = 100; %ms
end
