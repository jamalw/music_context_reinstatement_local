function[] = run_audio_context_4_conds(subj,FORCE_NEW)
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
% [Author]: Jamal Williams (jamalw@princeton.edu)       %
% [Date]:   February 3, 2015                                  %
% [File]:   Main experiment code                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%change log
%jrm 3-16-13 wrote it (based on run_classFR)
%jrm 4-2-13  fleshing out structure of program, debugging
%jrm 4-17-13  correct order of instructions and waiting for pulses

%#ok<*MCKBD,*TLEV>

%seed the random number generator using the clock
s = RandStream.create('mt19937ar','seed',sum(100*clock));
RandStream.setDefaultStream(s);
GetSecs; %load GetSecs mex file into memory for highest-possible timing precision
clear Screen; %close any previously opened PsychToolbox screens
%PsychDebugWindowConfiguration;

%checkpoints to keep track of
global START_CLEAN; START_CLEAN = 0;
global PRESENT_LISTS; PRESENT_LISTS = 1;
global LOCALIZER; LOCALIZER = 2;
global END_SCAN; END_SCAN = 3;
global FINISHED; FINISHED = 4;

%data directory
global DATA_DIR; DATA_DIR = fullfile(fileparts(which(mfilename)),'data');
global SUBJ_DIR; SUBJ_DIR = fullfile(DATA_DIR,subj);

%i/o devices
global KEY_DEVICE; 
global KEY_DEVICE_ID; [KEY_DEVICE,KEY_DEVICE_ID] = get_keyboard;
global BUTTON_DEVICE; 
global BUTTON_BOX_ID;

%if it's a new subject, create it; otherwise restore the
%subject's state (this tells us which part of which session
%was most recently completed).  need to do this before anything else, so
%that the window properties can be set to debug mode if needed.
FORCE_NEW = exist('FORCE_NEW','var') && FORCE_NEW;
state = load_state(subj,FORCE_NEW); %state.subj, state.config, state.block, state.listnum, state.sesnum, state.logfile

%simulate BUTTON_BOX via keyboard if we're in debug mode or if the button
%box won't be used.
if state.config.DEBUG_MODE || ~state.config.BUTTON_BOX
    [BUTTON_DEVICE,BUTTON_BOX_ID] = get_keyboard;
    disp('   *** SIMULATING BUTTON BOX VIA KEYBOARD DEVICE ***');
else
    [BUTTON_DEVICE,BUTTON_BOX_ID] = get_button_box(state);
end

ListenChar(2);
KbName('UnifyKeyNames');

if state.config.DEBUG_MODE    
    InitializePsychSound(0);
    PsychDebugWindowConfiguration;
    Screen('Preference', 'SkipSyncTests', 0);
else
    HideCursor;
    InitializePsychSound(1);
    Screen('Preference', 'SkipSyncTests', 2);
end

try
    %set up the screen;
    global WINDOW; WINDOW = get_window(state); 
    global WHITE; WHITE = WhiteIndex(WINDOW);
    global BLACK; BLACK = BlackIndex(WINDOW);
    global GRAY; GRAY = (WHITE + BLACK)/2;
    global DISCARD_PULSES; DISCARD_PULSES = 3;
    
    %set up the button box
    n_button_box_tests = 0;
    while ~test_button_box(state)
        n_button_box_tests = n_button_box_tests + 1;
        
        if n_button_box_tests < 3
            display_message(state.config.debugButtonBoxText);
        else
            debug_button_box(state);
        end           
    end
    
    %set up the microphone
    n_mic_tests = 0;
    while ~test_microphone(state)
        n_mic_tests = n_mic_tests + 1;
        
        if n_mic_tests < 3
            display_message(state.config.debugMicText);
        else
            ListenChar(0);
            ShowCursor;
            fprintf('   *** ENTERING MICROPHONE DEBUG MODE ***\n   **************************************\n');           
            keyboard; 
            ListenChar(2);
            if ~state.config.DEBUG_MODE
                HideCursor;
            end
        end
    end
            
    %if starting fresh, generate lists
    if state.block == START_CLEAN
        state = prepare_stimuli(state);
        state = set_block(state,PRESENT_LISTS);
        state = set_listblock(state, 1);
        state = set_listnum(state, 0);
    end
        
    %present each pair of lists, one block at a time
    if state.block == PRESENT_LISTS         
        while state.listblock <= state.config.nBlocks
            first = true;
            if state.listnum == 0
                global song_name
                state.config.cond_idx
                [song_name] = present_list(state,false,first,song_name);                
%                 present_word(state.config.end_L1, state.config.cueDur);                
                state = set_listnum(state,1);    
                first = false;                    
            end
            if state.listnum == 1 
                clear_screen;                
                if state.config.cond_idx(state.listblock) == 0 
                    state.config.counter = state.config.counter + 1;
                elseif state.config.cond_idx(state.listblock) == 1
                    state.config.counter = state.config.counter + 1;
                elseif state.config.cond_idx(state.listblock) == 3
                    state.config.counter = state.config.counter + 1;
                end
                present_list(state,false,first,song_name);
                state = set_listnum(state,0);
                state.config.counter = state.config.counter + 1;
                state.config.recog_counter = state.config.counter + 1;
            end
            if state.config.fMRI || (state.listblock < state.config.nBlocks)
                display_message(state.config.breakText);
            end
            state = set_listblock(state, state.listblock + 1);
        end
        
        if state.config.fMRI
            state = set_block(state, LOCALIZER);
        else
            state = set_block(state, FINISHED);
        end
    end
    
    
    %do localizer
    if state.block == LOCALIZER
        run_localizer(state);
        state = set_block(state,END_SCAN);        
    end
    
    %end with a structural scan
    if state.block == END_SCAN
        display_message(state.config.structuralScanText,true,true);            
        wait_for_experimenter(state);            
        display_countdown_timer(state.config.structuralDur);
        state = set_block(state, FINISHED);
    end
    
    %display "you are done" message
    display_message(state.config.endText);
    
    kill_experiment(state);
catch %#ok<CTCH>
   Screen('CloseAll');
   ShowCursor;
   ListenChar(1);
   fclose('all');
   psychrethrow(psychlasterror);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RUN EXPERIMENT %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[song_name] = present_list(state,show_scenes,wait,song_name)
global PRESENT_LISTS;
global LOCALIZER;
global pahandle;
global example_words;
global example_words_2;


if state.block == PRESENT_LISTS
    if state.listnum == 0
        if state.listblock == 1            
            display_instructions(state, state.config.fr_instructions);
            response = -999;
            exp_cont = KbName('b');
            
            while ~ismember(response, exp_cont)                
                response = find(display_message('Please notify the experimenter.',true,false,50,true));
            end
            
            for x = 1:2
                if x == 1
                    song_name = 'mike_slott_looped.wav';
                elseif x == 2
                    song_name = 'Flying_Lotus_Melt.wav';
                end
            song_name = num2str(song_name);
            song_dir = strcat('/Users/jamalwilliams/Desktop/Chop_Suey/audio_mix/original_audio/example_song/',song_name);     
            [y, Fs] = wavread(song_dir);               
    
            wavedata = y';  
            nrchannels = size(wavedata,1);
                if nrchannels < 2
                    wavedata = [wavedata ; wavedata];
                    nrchannels = 2;
                end
            pahandle = PsychPortAudio('Open', [], [], 0, [], nrchannels);
            PsychPortAudio('FillBuffer', pahandle, wavedata);
            PsychPortAudio('Start', pahandle, 2, 0, 1);
            WaitSecs(10)
            if x == 1
                for i = 1:length(example_words)
    
                    clear_screen;
                    wait_for_pulse(state);
                    logappend(state,'PRES_WORD',example_words{i});
                    present_word(example_words{i},state.config.wordDur);
                    clear_screen;
    
                    tic;
                    jitter = state.config.wordJitter*rand/1000;
                    while toc*1000 < (state.config.wordISI + jitter)
                        continue;
                    end
                end
            
            PsychPortAudio('Stop', pahandle, 2, 0, 1);
            logappend(state,'END_LIST');
            response = -999;
            exp_cont = KbName('b');
            
            while ~ismember(response, exp_cont)                
                response = find(display_message('Please wait for the experimenter.',true,false,50,true));
            end
            
            end
            
            if x == 2
                for i = 1:length(example_words_2)
    
                    clear_screen;
                    wait_for_pulse(state);
                    logappend(state,'PRES_WORD',example_words_2{i});
                    present_word(example_words_2{i},state.config.wordDur);
                    clear_screen;
    
                    tic;
                    jitter = state.config.wordJitter*rand/1000;
                    while toc*1000 < (state.config.wordISI + jitter)
                        continue;
                    end
                end
            
            PsychPortAudio('Stop', pahandle, 2, 0, 1);
            logappend(state,'END_LIST');
            response = -999;
            exp_cont = KbName('b');
            
            while ~ismember(response, exp_cont)                
                response = find(display_message('Please wait for the experimenter.',true,false,50,true));
            end
            
            end
            end
            
            
        else
            display_instructions(state, state.config.fr_instructions_summary);
        end
    end
    list_file = fullfile(state.config.docs_folder,sprintf('%d_%d.lst',state.listblock,state.listnum));
elseif state.block == LOCALIZER
    if state.listnum == 1
        display_instructions(state, state.config.word_localizer_instructions);
    else
        display_instructions(state, state.config.word_localizer_instructions_summary);
    end
    list_file = fullfile(state.config.docs_folder,sprintf('word_localizer_%d.lst',state.listnum));
end
words = textread(list_file,'%s');
if show_scenes
    img_list = fullfile(state.config.docs_folder,sprintf('%d_%d.scenes',state.listblock,state.listnum));
    images = textread(img_list,'%s');
    images = cellfun(@(x)(fullfile(state.config.images_folder,'scenes',x)),images,'UniformOutput',false);
end

if wait
    wait_for_experimenter(state);
    init_pulses(state);
end

if state.listnum == 0
    wait_for_pulse(state);
    fixation_cross(state);
end

logappend(state,'START_LIST',list_file);

%% create 4 conditions here
% condition 1
if state.listnum == 0 && state.config.cond_idx(state.listblock) == 0
    
    song_name = state.config.single_songs(state.config.counter);
    song_dir = strcat('/Users/jamalwilliams/Desktop/Chop_Suey/audio_mix/original_audio/singles/',song_name);     
    [y, Fs] = wavread(song_dir{:});               
    
    
    wavedata = y';  
    nrchannels = size(wavedata,1);
        if nrchannels < 2
            wavedata = [wavedata ; wavedata];
            nrchannels = 2;
        end
    pahandle = PsychPortAudio('Open', [], [], 0, [], nrchannels);
    PsychPortAudio('FillBuffer', pahandle, wavedata);
    PsychPortAudio('Start', pahandle, 1, 0, 1);
end


if state.listnum == 1 && state.config.cond_idx(state.listblock) == 0
   state.config.counter = state.config.counter; 
   song_name = state.config.single_songs(state.config.counter);
   song_dir = strcat('/Users/jamalwilliams/Desktop/Chop_Suey/audio_mix/original_audio/singles/',song_name); 
   [y, Fs] = wavread(song_dir{:});               
    
    
    wavedata = y';  
    nrchannels = size(wavedata,1);
        if nrchannels < 2
            wavedata = [wavedata ; wavedata];
            nrchannels = 2;
        end
    pahandle = PsychPortAudio('Open', [], [], 0, [], nrchannels);
    PsychPortAudio('FillBuffer', pahandle, wavedata);
    PsychPortAudio('Start', pahandle, 4, 0, 1);
end
    
%%
% condition 2
if state.listnum == 0 && state.config.cond_idx(state.listblock) == 1
    
    song_name = state.config.single_songs(state.config.counter);
    song_dir = strcat('/Users/jamalwilliams/Desktop/Chop_Suey/audio_mix/original_audio/singles/',song_name);     
    [y, Fs] = wavread(song_dir{:});               
    
    
    wavedata = y';  
    nrchannels = size(wavedata,1);
        if nrchannels < 2
            wavedata = [wavedata ; wavedata];
            nrchannels = 2;
        end
    pahandle = PsychPortAudio('Open', [], [], 0, [], nrchannels);
    PsychPortAudio('FillBuffer', pahandle, wavedata);
    PsychPortAudio('Start', pahandle, 3, 0, 1);

end

%%
% condition 3
if state.listnum == 0 && state.config.cond_idx(state.listblock) == 2
    
    song_name = state.config.single_songs(state.config.counter);
    song_dir = strcat('/Users/jamalwilliams/Desktop/Chop_Suey/audio_mix/original_audio/singles/',song_name);     
    [y, Fs] = wavread(song_dir{:});               
    
    
    wavedata = y';  
    nrchannels = size(wavedata,1);
        if nrchannels < 2
            wavedata = [wavedata ; wavedata];
            nrchannels = 2;
        end
    pahandle = PsychPortAudio('Open', [], [], 0, [], nrchannels);
    PsychPortAudio('FillBuffer', pahandle, wavedata);
    PsychPortAudio('Start', pahandle, 4, 0, 1);

end
    
%%
% condition 4
if state.listnum == 0 && state.config.cond_idx(state.listblock) == 3
    
    song_name = state.config.single_songs(state.config.counter);
    song_dir = strcat('/Users/jamalwilliams/Desktop/Chop_Suey/audio_mix/original_audio/singles/',song_name);     
    [y, Fs] = wavread(song_dir{:});               
    
    
    wavedata = y';  
    nrchannels = size(wavedata,1);
        if nrchannels < 2
            wavedata = [wavedata ; wavedata];
            nrchannels = 2;
        end
    pahandle = PsychPortAudio('Open', [], [], 0, [], nrchannels);
    PsychPortAudio('FillBuffer', pahandle, wavedata);
    PsychPortAudio('Start', pahandle, 2, 0, 1);
end


if state.listnum == 1 && state.config.cond_idx(state.listblock) == 3    
   song_name = state.config.single_songs(state.config.counter);
   song_dir = strcat('/Users/jamalwilliams/Desktop/Chop_Suey/audio_mix/original_audio/singles/',song_name); 
   [y, Fs] = wavread(song_dir{:});               
    
    
    wavedata = y';  
    nrchannels = size(wavedata,1);
        if nrchannels < 2
            wavedata = [wavedata ; wavedata];
            nrchannels = 2;
        end
    pahandle = PsychPortAudio('Open', [], [], 0, [], nrchannels);
    PsychPortAudio('FillBuffer', pahandle, wavedata);
    PsychPortAudio('Start', pahandle, 1, 0, 1);
end
    
%%
if state.listnum == 0
    WaitSecs(10)
end

for i = 1:length(words)
    
    clear_screen;
    wait_for_pulse(state);
    logappend(state,'PRES_WORD',words{i});
    present_word(words{i},state.config.wordDur);
    clear_screen;
    
    tic;
    if show_scenes && i < length(words)
        for j = ((i-1)*state.config.scenesPerWord + 1):(i*state.config.scenesPerWord)
            logappend(state,'PRES_IMG',images{j});
            present_image(images{j},state.config.sceneDur);
            clear_screen;
            pause(state.config.sceneISI/1000);
            pause(state.config.sceneJitter*rand/1000);
        end
    end
    
    jitter = state.config.wordJitter*rand/1000;
    while toc*1000 < (state.config.wordISI + jitter)
        continue;
    end
end
logappend(state,'END_LIST');

if state.listnum == 0 && state.config.cond_idx(state.listblock) == 0
    PsychPortAudio('Stop', pahandle, 0, 0, 1);
elseif state.listnum == 1 && state.config.cond_idx(state.listblock) == 1
    PsychPortAudio('Stop', pahandle, 0, 0, 1);
elseif state.listnum == 0 && state.config.cond_idx(state.listblock) == 3
    PsychPortAudio('Stop', pahandle, 0, 0, 1);
elseif state.listnum == 1 && state.config.cond_idx(state.listblock) == 3
    PsychPortAudio('Stop', pahandle, 0, 0, 1);
end

    
    if state.listnum == 1 && state.config.cond_idx(state.listblock) == 0
        [r,samplerate,nbits,nchans] = record_responses(state,0,true);
        wait_for_pulse(state);
        if state.block == PRESENT_LISTS        
            present_word(state.config.end_L2, state.config.cueDur);
            logappend(state,'RECALL_CUE', state.recall_list(state.listblock));
            if state.recall_list(state.listblock) == 0        
                present_word(state.config.recall_first, state.config.cueDur);
            else
                present_word(state.config.recall_second, state.config.cueDur);
            end    
        end
        clear_screen;
        wait_for_pulse(state);
        fixation_cross(state);
        startTime = tic;
        while toc(startTime) < state.config.recallDur/1000
            wait_for_pulse(state);
        end
        fixation_cross(state);
        wait_for_pulse(state);
        record_responses(state,0,false,r,samplerate,nbits,nchans);
        PsychPortAudio('Stop', pahandle, 0, 0, 1);
    elseif state.listnum == 1 && state.config.cond_idx(state.listblock) == 1        
        song_name = state.config.single_songs(state.config.counter);
        song_dir = strcat('/Users/jamalwilliams/Desktop/Chop_Suey/audio_mix/original_audio/singles/',song_name); 
        [y, Fs] = wavread(song_dir{:});               
        wavedata = y';  
        nrchannels = size(wavedata,1);
        if nrchannels < 2
            wavedata = [wavedata ; wavedata];
            nrchannels = 2;
        end
%         pahandle = PsychPortAudio('Open', [], [], 0, [], nrchannels);
        PsychPortAudio('FillBuffer', pahandle, wavedata);        
        [r,samplerate,nbits,nchans] = record_responses(state,0,true);
        wait_for_pulse(state);
        if state.block == PRESENT_LISTS        
            present_word(state.config.end_L2, state.config.cueDur);
            logappend(state,'RECALL_CUE', state.recall_list(state.listblock));
            if state.recall_list(state.listblock) == 0        
                present_word(state.config.recall_first, state.config.cueDur);
            else
                present_word(state.config.recall_second, state.config.cueDur);
            end    
        end
        clear_screen;
        wait_for_pulse(state);
        fixation_cross(state);
        startTime = tic;
        PsychPortAudio('Start', pahandle, 1, 0, 1);
        while toc(startTime) < state.config.recallDur/1000
            wait_for_pulse(state);
        end
        fixation_cross(state);
        wait_for_pulse(state);
        record_responses(state,0,false,r,samplerate,nbits,nchans);
        PsychPortAudio('Stop', pahandle, 0, 0, 1);
    elseif state.listnum == 1 && state.config.cond_idx(state.listblock) == 2
        [r,samplerate,nbits,nchans] = record_responses(state,0,true);
        wait_for_pulse(state);
        if state.block == PRESENT_LISTS        
            present_word(state.config.end_L2, state.config.cueDur);
            logappend(state,'RECALL_CUE', state.recall_list(state.listblock));
            if state.recall_list(state.listblock) == 0        
                present_word(state.config.recall_first, state.config.cueDur);
            else
                present_word(state.config.recall_second, state.config.cueDur);
            end    
        end
        clear_screen;
        wait_for_pulse(state);
        fixation_cross(state);
        startTime = tic;
        while toc(startTime) < state.config.recallDur/1000
            wait_for_pulse(state);
        end
        fixation_cross(state);
        wait_for_pulse(state);
        record_responses(state,0,false,r,samplerate,nbits,nchans);
        PsychPortAudio('Stop', pahandle, 0, 0, 1);
    elseif state.listnum == 1 && state.config.cond_idx(state.listblock) == 3                
        song_name = state.config.single_songs(state.config.counter - 1);
        song_dir = strcat('/Users/jamalwilliams/Desktop/Chop_Suey/audio_mix/original_audio/singles/',song_name); 
        [y, Fs] = wavread(song_dir{:});               
        wavedata = y';  
        nrchannels = size(wavedata,1);
        if nrchannels < 2
            wavedata = [wavedata ; wavedata];
            nrchannels = 2;
        end
%         pahandle = PsychPortAudio('Open', [], [], 0, [], nrchannels);
        PsychPortAudio('FillBuffer', pahandle, wavedata);        
        [r,samplerate,nbits,nchans] = record_responses(state,0,true);
        wait_for_pulse(state);
        if state.block == PRESENT_LISTS        
            present_word(state.config.end_L2, state.config.cueDur);
            logappend(state,'RECALL_CUE', state.recall_list(state.listblock));
            if state.recall_list(state.listblock) == 0        
                present_word(state.config.recall_first, state.config.cueDur);
            else
                present_word(state.config.recall_second, state.config.cueDur);
            end    
        end
        clear_screen;
        wait_for_pulse(state);
        fixation_cross(state);
        startTime = tic;
        PsychPortAudio('Start', pahandle, 2, 0, 1);
        while toc(startTime) < state.config.recallDur/1000
            wait_for_pulse(state);
        end
        fixation_cross(state);
        wait_for_pulse(state);
        record_responses(state,0,false,r,samplerate,nbits,nchans);
        PsychPortAudio('Stop', pahandle, 0, 0, 1);
    end
    
    
    
     if state.listnum == 1         
          present_word(state.config.pre_rec, state.config.fixDur);
          single_song_name = state.config.single_recog_songs(state.config.recog_counter);               
          song_dir = strcat('/Users/jamalwilliams/Desktop/Chop_Suey/audio_mix/original_audio/recog_singles/',single_song_name);     
          song_dir_og = strcat('/Users/jamalwilliams/Desktop/Chop_Suey/audio_mix/original_audio/singles/',song_name);     
          
          rand_song_selector = randi(2);
          
          if rand_song_selector == 1
            [y, Fs] = wavread(song_dir{:});
            song_source_code = 1;
          elseif rand_song_selector == 2
            [y, Fs] = wavread(song_dir_og{:});
            song_source_code = 2;
          end
      
      
      wavedata = y';  
      nrchannels = size(wavedata,1);
          if nrchannels < 2
              wavedata = [wavedata ; wavedata];
              nrchannels = 2;
          end
      pahandle = PsychPortAudio('Open', [], [], 0, [], nrchannels);
      PsychPortAudio('FillBuffer', pahandle, wavedata);     
      PsychPortAudio('Start', pahandle, 1, 8, 0, GetSecs + 3);
      WaitSecs(4);
            
      
      if song_source_code == 1
          song_match = 0;
      elseif song_source_code == 2
          song_match = 1;
      end
      
      % Collect subject's response for recognition task
      state.response = -999;
      yes = KbName('y');
      no = KbName('n');
      
      % n = 17 and y = 28
      while ~ismember(state.response,[yes no])    
          state.response = find(display_message('Does the clip match a song \n from the previous list? \n Press (y)es or (n)o',true,false,50,true));
          logappend(state,'RECOGNITION INSTRUCTIONS')
          if song_match == 1 & state.response == 28
              state.feedback = display_message('Correct \n\n Press any key to continue',true,false,50,true);
              logappend(state,'RESPONSE',state.response)
              logappend(state,'CORRECT',state.feedback)
          elseif song_match == 1 & state.response == 17
              state.feedback = display_message('Incorrect \n\n Press any key to continue',true,false,50,true);
              logappend(state,'RESPONSE',state.response)
              logappend(state,'INCORRECT',state.feedback)
          elseif song_match == 0 & state.response == 17
              state.feedback = display_message('Correct \n\n Press any key to continue',true,false,50,true);
              logappend(state,'RESPONSE',state.response)
              logappend(state,'CORRECT',state.feedback)
          elseif song_match == 0 & state.response == 28
              state.feedback = display_message('Incorrect \n\n Press any key to continue',true,false,50,true);
              logappend(state,'RESPONSE',state.response)
              logappend(state,'INCORRECT',state.feedback)
          end
      end     
      
      clear song_name
     end
   



function[] = run_localizer(state)
global KEY_DEVICE_ID;

if state.config.RUN_WORD_LOCALIZER
    %run word localizer
    state = set_listnum(state,1);
    for i = state.listnum:state.config.nLocalizerLists
          present_list(state,false,true,song_name);
        state = set_listnum(state, state.listnum+1);
    end
end

%run images localizer
display_instructions(state, state.config.oneback_instructions);
wait_for_experimenter(state);
init_pulses(state);

n_blocks = min(state.config.nMiniBlocks*length(state.config.localizerImages), length(state.localizer_order));
for i = 1:n_blocks
    stimtype = state.config.localizerImages{state.localizer_order(i)};
    list = fullfile(state.config.docs_folder,sprintf('image_localizer_%d.lst',i));
    images = textread(list,'%s');    
    images = cellfun(@(x)(fullfile(state.config.images_folder,stimtype,x)),images,'UniformOutput',false);
    
    for j = 1:length(images)
        wait_for_pulse(state);
        logappend(state,'PRES_IMG',images{j});
        tic;
        present_image(images{j},0);
        get_keypress(state, KEY_DEVICE_ID, state.config.localizerDur/1000);
        pause_time = state.config.localizerDur/1000 - toc;
        if pause_time > 0
            pause(pause_time);
        end
        clear_screen;
        pause_time = (state.config.localizerDur + state.config.localizerISI)/1000 - toc;
        if pause_time > 0
            pause(pause_time);
        end
    end
    
    if i < n_blocks
        pause(state.config.localizerIBI/1000);
    end
end



%%%%%%%%%%%%%%%%%%%%%
% LOAD/MODIFY STATE %
%%%%%%%%%%%%%%%%%%%%%
function[state] = load_state(subj,FORCE_NEW)
global SUBJ_DIR;
global START_CLEAN;

if ~FORCE_NEW && exist(fullfile(SUBJ_DIR,'state.mat'),'file')
    load(fullfile(SUBJ_DIR,'state.mat'));
    logappend(state,'BEGIN_EXP','EXISTING_SUBJ',state.block,state.listblock,state.listnum); %#ok<NODEF>
else
    if FORCE_NEW && exist(fullfile(SUBJ_DIR,'state.mat'),'file')
        backup_dir = get_backup_dirname(SUBJ_DIR);
        fprintf('FORCING SUBJECT OVERWRITE (BACKUP: %s)\n',backup_dir);
        move_dir_contents(SUBJ_DIR,backup_dir);
    end
    
    state.subj = subj;
    state.config = load_config_audio_4_conds;
    state.logfile = fullfile(SUBJ_DIR,state.config.logfile);
    state.docs = fullfile(SUBJ_DIR,'docs/');
    
    if ~exist(SUBJ_DIR,'dir') 
        mkdir(SUBJ_DIR);
    end
    
    logappend(state,'BEGIN_EXP','NEW_SUBJ',subj);
    
    copydir(fullfile(fileparts(which(mfilename)),state.config.docs_folder),...
       SUBJ_DIR);
    state.config.docs_folder = fullfile(SUBJ_DIR,state.config.docs_folder);
    state.config.images_folder = fullfile(fileparts(which(mfilename)),state.config.images_folder);
    
    %compute config.sceneDur
    state.config.sceneDur = (state.config.wordISI/state.config.scenesPerWord) - state.config.sceneISI;
    
    state = set_block(state,START_CLEAN);
    state = set_listblock(state,0);
    state = set_listnum(state,0);
end

function[state] = set_block(state,block)
state.block = block;
logappend(state,'SET_BLOCK',state.block);
save_state(state);


function[state] = set_listblock(state,listblock)
state.listblock = listblock;
logappend(state,'SET_LISTBLOCK',state.listblock);
save_state(state);

function[state] = set_listnum(state,listnum)
state.listnum = listnum;
logappend(state,'SET_LIST',state.listnum);
save_state(state);

%%%%%%%%%%%%%%%%%%%%%
% CREATE WORD LISTS %
%%%%%%%%%%%%%%%%%%%%%

function[state] = prepare_stimuli(state)
logappend(state,'PREP_STIMULI');
global example_words
global example_words_2

%generate sequence of lists, forget & remember cues, and recall cues
lists = Shuffle(1:state.config.nLists);
state.blocks = reshape(repmat(1:state.config.nBlocks,2,1),1,state.config.nLists);
state.listnums = repmat([0 1],1,state.config.nBlocks);

state.forget = zeros(1,state.config.nBlocks);
for i = 1:ceil(state.config.nBlocks/2)
    start = (i-1)*2 + 1;
    if (rand > 0.5) || (i == ceil(state.config.nBlocks/2))
        state.forget(start:(start+1)) = [0 1];
    else
        state.forget(start:(start+1)) = [1 0];
    end
end
state.forget = state.forget(1:state.config.nBlocks);

%create matrix that holds condition cue and recall cue
assign = [0 0 0 1 1 1 2 2 2 3 3 3;0 0 0 1 1 1 0 0 0 1 1 1];
rand_assign = assign(:,randperm(12));

state.recall_list = rand_assign(2,:); %default: recall second list

%generate the lists & image sequences
[words,list_inds] = csvimport(state.config.wordpool,'columns',[1 2],'noHeader',true);
[example_words,list_inds_ex] = csvimport(state.config.example_wordpool,'columns',[1 2],'noHeader',true);
[example_words_2,list_inds_ex] = csvimport(state.config.example_wordpool_2,'columns',[1 2],'noHeader',true);
list_inds = [list_inds; 24];
words = importdata([state.docs 'longpool_audio.csv']);
words = words.textdata;
example_words = importdata([state.docs 'example_list.csv']);
example_words = example_words.textdata;
example_words_2 = importdata([state.docs 'example_list_2.csv']);
example_words_2 = example_words_2.textdata;
files = dir(fullfile(state.config.images_folder,'scenes'));
scenes = {files.name};
scenes = scenes(~ismember(scenes,{'.', '..','.DS_Store'}));
scene_inds = true(size(scenes));
for i = 1:length(lists)
    next_fname = fullfile(state.config.docs_folder,sprintf('%d_%d.lst',state.blocks(i),state.listnums(i)));
    next_words = Shuffle(words(list_inds == lists(i)));
    write_list(next_fname,upper(next_words));        
end
for i = 1:state.config.nBlocks
    next_fname = fullfile(state.config.docs_folder,sprintf('%d_0.scenes',i));    
    shuffled_inds = Shuffle(find(scene_inds));
    next_inds = shuffled_inds(1:state.config.scenesPerWord*(length(next_words)-1));
    next_scenes = scenes(next_inds);
    write_list(next_fname,next_scenes);
    scene_inds(next_inds) = false;
end

% generate song sequence

% grab gradual songs
% gradual_song_dir = dir('/Users/jamalwilliams/Desktop/Chop_Suey/audio_mix/play_gradual/*.wav');
% rand_grad_song_size = length(gradual_song_dir);
% rand_gs_vec = Shuffle(1:rand_grad_song_size);
% 
% gradual_songs = cell(1,rand_grad_song_size);

% for x = 1:rand_grad_song_size
%     state.config.gradual_songs{x} = num2str(gradual_song_dir(rand_gs_vec(x)).name);
% end
% 
% % grab abrupt songs
% abrupt_song_dir = dir('/Users/jamalwilliams/Desktop/Chop_Suey/audio_mix/play_abrupt/*.wav');
% rand_abrp_song_size = length(abrupt_song_dir);
% rand_as_vec = Shuffle(1:rand_abrp_song_size);
% 
% abrupt_songs = cell(1,rand_abrp_song_size);
% 
% for x = 1:rand_abrp_song_size
%     state.config.abrupt_songs{x} = num2str(abrupt_song_dir(rand_as_vec(x)).name);
% end

% grab single songs
single_song_dir = dir('/Users/jamalwilliams/Desktop/Chop_Suey/audio_mix/original_audio/singles/*.wav');
single_song_dir_recog = dir('/Users/jamalwilliams/Desktop/Chop_Suey/audio_mix/original_audio/recog_singles/*.wav');

rand_single_song_size = length(single_song_dir);
rand_single_vec = Shuffle(1:rand_single_song_size);

rand_single_recog_song_size = length(single_song_dir_recog);
rand_single_vec_recog = Shuffle(1:rand_single_recog_song_size);

single_songs = cell(1,rand_single_song_size);
single_recog_songs = cell(1,rand_single_recog_song_size);

for x = 1:rand_single_song_size
    state.config.single_songs{x} = num2str(single_song_dir(rand_single_vec(x)).name);
end

for x = 1:rand_single_recog_song_size
    state.config.single_recog_songs{x} = num2str(single_song_dir_recog(rand_single_vec_recog(x)).name);
end

% create vector of 0's (gradual) and 1's (abrupt) for indexing song
% condition

state.config.cond_idx = rand_assign(1,:);


%localizer-- words
[loc_words,list_inds] = csvimport(state.config.localizerWordpool,'columns',[1 2],'noHeader',true);
lists = unique(list_inds);
state.config.nLocalizerLists = length(lists);
for i = 1:length(lists)
    next_fname = fullfile(state.config.docs_folder,sprintf('word_localizer_%d.lst',i));
    next_words = Shuffle(loc_words(list_inds == lists(i)));
    write_list(next_fname,upper(next_words));
end
write_list(fullfile(state.config.docs_folder,'wordpool.txt'), sort(union(upper(words), upper(loc_words))));

%localizer-- images
%get set of stimuli we can use
stims = cell(1,length(state.config.localizerImages));
for i = 1:length(state.config.localizerImages)
    next_stimtype = state.config.localizerImages{i};
    files = dir(fullfile(state.config.images_folder,next_stimtype));
    stims{i} = {files.name};
    stims{i} = stims{i}(~ismember(stims{i},{'.', '..', '.DS_Store'}));
    
    if strcmp(next_stimtype,'scenes')
        stims{i} = stims{i}(scene_inds);
    end
end

%create miniblocks-- each set of length(localizerImages) blocks should
%follow a debruijn sequence (sequence length: 2)
loc = []; %debruijn_generator(length(state.config.localizerImages),2)';
while sum(loc == 1) < state.config.nMiniBlocks
    loc = [loc Shuffle([1:length(state.config.localizerImages)])]; %[loc debruijn_generator(length(state.config.localizerImages),2)']; %#ok<AGROW>
end
state.localizer_order = loc;

stim_inds = cellfun(@(x)(true(size(x))),stims,'UniformOutput',false);
for i = 1:length(state.localizer_order)
    next_inds = Shuffle(find(stim_inds{state.localizer_order(i)}));
    next_inds = add_oneback_reps(next_inds(1:state.config.miniBlockSize), state.config.localizerOnebackMatchProb);        
    next_fname = fullfile(state.config.docs_folder,sprintf('image_localizer_%d.lst',i));
    
    next_stims = stims{state.localizer_order(i)}(next_inds);    
    write_list(next_fname,next_stims);
    stim_inds{state.localizer_order(i)}(next_inds) = false;
end

save_state(state);

function[rep_inds] = add_oneback_reps(inds, prob)
rep_inds = inds;
for i = 2:length(inds)
    if rand <= prob
        rep_inds(i) = inds(i-1);
    end
end

function[] = write_list(fname,list)
fid = fopen(fname,'w+');
for i = 1:length(list)
    fprintf(fid,'%s\n',list{i});
end
fclose(fid);

function[] = save_state(state) %#ok<INUSD>
global SUBJ_DIR
save(fullfile(SUBJ_DIR,'state.mat'),'state');


%%%%%%%
% I/O %
%%%%%%%
function[w] = get_window(state)
if state.config.DEBUG_MODE
    Screen('Preference', 'SkipSyncTests', 1);
end

s = Screen('Screens');
if state.config.DUAL_SCREEN    
    w = Screen(max(s), 'OpenWindow');
else
    w = Screen(min(s), 'OpenWindow'); 
end

function[mic_ok] = test_microphone(state)
display_message('Microphone test.');
clear_screen;
display_message('Say something!',true,true);
r = record_responses({state},3,false);
clear_screen;
display_message('Playback...',true,true);
pause(0.5);
play(r); %%%%%%NEED TO USE PSYCH SOUND...
pause(2.5);
response = -999;
yes = KbName('y');
no = KbName('n');
skip = KbName('s');
while ~ismember(response,[yes no skip])
    %display_message(message,noappend,nowait,override_text_size,local_only)
    response = find(display_message('Did you hear the recording? [(y)es/(n)o/(s)kip]',true,false,50,true));
end
mic_ok = (response == yes) || (response == skip);
logappend(state,'MIC_TEST',int8(mic_ok),int8(response == skip));
if response == skip
    fprintf('   *** SKIPPING MICROPHONE TEST ***\n');
end

function[heard_button_presses] = test_button_box(state)
global BUTTON_BOX_ID;
global KEY_DEVICE_ID;

if ~state.config.BUTTON_BOX
    heard_button_presses = true;
    return;
end

listen_devices = unique([BUTTON_BOX_ID KEY_DEVICE_ID]);
space_key = KbName('SPACE');
esc_key = KbName('ESCAPE');
heard_button_presses = false;
if state.config.BUTTON_BOX    
    display_message('Press buttons!\n\n(Tester: press\nspace bar to continue\nor escape to skip)',true,true);
    if state.config.DUAL_SCREEN
        fprintf('\nLISTENING FOR BUTTON PRESSES:');
    end
    while(1)
        [~,key_code] = get_keypress(state, listen_devices);        
        if key_code(space_key) || key_code(esc_key)
            break;
        else
            heard_button_presses = true;
        end
        
        if state.config.DUAL_SCREEN
            fprintf(' %s', KbName(key_code));            
        end
    end
    if state.config.DUAL_SCREEN
        fprintf('\n');
    end
end

if key_code(esc_key)
    fprintf('   *** SKIPPING BUTTON BOX TEST ***\n');
    heard_button_presses = true;
end
logappend(state,'BUTTON_BOX_TEST',int8(heard_button_presses),int8(key_code(esc_key)));




function[] = display_instructions(state,fname)
logappend(state,'INSTRUCTIONS',fname);
fid = fopen(fullfile(state.config.docs_folder,fname));
instructions = [];
next_line = 0;
while next_line ~= -1    
    next_line = fgets(fid);
    if next_line ~= -1
        instructions = [instructions next_line]; %#ok<AGROW>
    end
end
fclose(fid);

display_message(instructions, false, false, 45, false, true);


function[keyCode] = display_message(message,noappend,nowait,override_text_size,local_only,force_left_justify)
global WINDOW;
global WHITE;
global KEY_DEVICE_ID;
global BUTTON_BOX_ID;

if ~exist('noappend','var')
    noappend = false;
end
if ~exist('nowait','var')
    nowait = false;
end

if ~noappend
    message = [message,'\n\nPress any button to continue...'];    
end

if ~exist('override_text_size','var')
    Screen('TextSize', WINDOW, 50);
else
    Screen('TextSize', WINDOW, override_text_size);
end

if ~exist('local_only','var')
    local_only = false;
end

if ~exist('force_left_justify','var')
    force_left_justify = false;
end

if local_only
    listen_devices = KEY_DEVICE_ID;
else
    listen_devices = unique([KEY_DEVICE_ID BUTTON_BOX_ID]);
end

Screen('TextFont', WINDOW, 'Myriad Pro');

winHeight = RectHeight(Screen('Rect', WINDOW));
[~, ~, bbox] = DrawFormattedText(WINDOW, message, 0, 0, WHITE);
textHeight = RectHeight(bbox);

clear_screen;
if textHeight <= winHeight - 50
    if force_left_justify
        DrawFormattedText(WINDOW, message, 50, 'center', WHITE);    
    else
        DrawFormattedText(WINDOW, message, 'center', 'center', WHITE);    
    end
    Screen('Flip', WINDOW);        
else %teleprompter mode...    
    DrawFormattedText(WINDOW, message, 50, 50, WHITE);
    Screen('Flip', WINDOW);        
    KbPressWait(listen_devices);
    
    for i = 50:-1:(winHeight - textHeight - 50)
        % Draw text again, this time with unlimited line length:
        DrawFormattedText(WINDOW, message, 50, i, WHITE);
        Screen('FrameRect', WINDOW, 0, bbox);
        Screen('Flip', WINDOW);        
    end
end
if ~nowait
    [~,keyCode] = KbPressWait(listen_devices);
    clear_screen;
end


function[secs, keyCode, deltaSecs] = get_keypress(state, varargin)
[secs, keyCode, deltaSecs] = KbPressWait(varargin{:});
logappend(state, 'KEY_PRESS', secs, keyCode, deltaSecs);
FlushEvents;



function[xpos,ypos] = present_word(stim,dur_ms,beep_dur,beep_freq,xpos,ypos,color)
global WINDOW;
global WHITE;

if ~exist('beep_dur','var') || isempty(beep_dur)
    play_beep = false;
else
    play_beep = true;
end
if ~exist('beep_freq','var') || isempty(beep_freq)
    beep_freq = 800; %kHz
end
if ~exist('xpos','var') || isempty(xpos)
    xpos = 'center';
end
if ~exist('ypos','var') || isempty(ypos)
    ypos = 'center';
end
if ~exist('color','var')
    color = WHITE;
end

Screen('TextSize', WINDOW, 100);
Screen('TextFont', WINDOW, 'Myriad Pro');
[xpos,ypos] = DrawFormattedText(WINDOW, stim, xpos, ypos, color);

if play_beep
    Beeper(beep_freq,0.4,beep_dur/1000);
end
Screen('Flip',WINDOW);
pause(dur_ms/1000);



function[] = present_image(fname,dur_ms)
global WINDOW;

img = imread(fname,'jpg');
Screen('PutImage',WINDOW,img);
Screen('Flip',WINDOW);
pause(dur_ms/1000);

function[] = clear_screen()
global WINDOW;
global BLACK;
Screen(WINDOW, 'FillRect', BLACK);
Screen('Flip',WINDOW);





function[] = fixation_cross(state)
logappend(state,'FIXATE');
clear_screen;
present_word(state.config.fixCross,state.config.fixDur,...
    state.config.beepDur,state.config.beepFreq);
clear_screen;
pause(state.config.fixISI/1000);
pause(state.config.fixJitter*rand/1000);







function[] = display_countdown_timer(dur)
global KEY_DEVICE_ID;

pause_key = KbName('SPACE');
reset_key = KbName('R');
up_key = KbName('UPARROW');
down_key = KbName('DOWNARROW');
done_key = KbName('ESCAPE');

delta = 10; %seconds

display_time_remaining(dur);
last_update = tic;
paused = false;
time_left = dur;
while time_left > 0
    loop_start = tic;    
    [key_pressed,~,key_code] = KbCheck(KEY_DEVICE_ID);    
    if key_pressed
        while KbCheck(KEY_DEVICE_ID); end
    end
    
    if key_code(pause_key)
        paused = ~paused;
    end    
    if key_code(reset_key)
        time_left = dur;        
    end
    if key_code(up_key)
        time_left = time_left + delta;
    end
    if key_code(down_key)
        time_left = time_left - delta;
    end
    if key_code(done_key)
        time_left = 0;
    end
        
    if toc(last_update) > 1
        display_time_remaining(time_left)
        last_update = tic;
    end
    
    if ~paused        
        time_left = time_left - toc(loop_start);
    end       
end
display_time_remaining(0);


function[] = display_time_remaining(t)
mins = floor(t/60);
secs = floor(t-60*mins);
display_message(sprintf('%d:%02d',mins,secs),true,true,200);



function[r,samplerate,nbits,nchans] = record_responses(state,dur,leave_open,r,samplerate,nbits,nchans)
global LOCALIZER;

if ~exist('leave_open','var')
    leave_open = false;
end

tic;
if ~exist('r','var')
    samplerate = 44100; %22050; %Hz
    nbits = 16;
    nchans = 1;
    r = audiorecorder(samplerate, nbits, nchans);
    record(r); %start recording
    new_record = true;
else
    new_record = false;
end

if ~iscell(state)
    if new_record
        logappend(state,'START_RECORD',samplerate,nbits,nchans);
    end
    if state.block == LOCALIZER
        wav_file = sprintf('localizer_%d.wav',state.listnum);
    else
        wav_file = sprintf('%d_%d.wav',state.listblock,state.recall_list(state.listblock));    
    end
else
    state = state{1}; %don't record to log file (e.g. for debugging microphone)
    wav_file = '';
end

if dur > 0
    while toc < dur
        continue;
    end
end
if ~leave_open
    stop(r);
    if ~isempty(wav_file)
        logappend(state,'STOP_RECORD',wav_file);
        data = getaudiodata(r,'int16');
        wavwrite(data,samplerate,nbits,fullfile(state.config.docs_folder,wav_file));
    end
end

function[heard_pulse] = wait_for_pulse(state,catch_up_delay)
if ~exist('catch_up_delay','var'), catch_up_delay = 0; end

if state.config.DEBUG_MODE && state.config.fMRI
    [pulse_time,heard_pulse] = WaitTRPulsePTB3_skyra_debug(1,GetSecs + 0.6 - catch_up_delay/1000);
elseif state.config.fMRI
    [pulse_time,heard_pulse] = WaitTRPulsePTB3_skyra(1,GetSecs + 2.1 - catch_up_delay/1000);
elseif state.config.DEBUG_MODE
    pause(0.25 + 0.25*rand);
    pulse_time = GetSecs;
    heard_pulse = rand > 0.05;
end
if state.config.DEBUG_MODE || state.config.fMRI
    if heard_pulse
        logappend(state,'PULSE_RECEIVED',sprintf('%0.37f',pulse_time));
    else
        logappend(state,'PULSE_INFERRED',sprintf('%0.37f',pulse_time));
    end
end
if ~state.config.fMRI
    heard_pulse = true;
end

function[] = init_pulses(state)
global DISCARD_PULSES;
count = 0;
while count < DISCARD_PULSES
    count = count + wait_for_pulse(state);
end

function[] = wait_for_experimenter(state)
global KEY_DEVICE;
global KEY_DEVICE_ID;
if state.config.fMRI% || state.config.DEBUG_MODE
    logappend(state,'WAIT_FOR_INPUT',KEY_DEVICE,KEY_DEVICE_ID);
    disp(state.config.waitForScanStartText);
    Beeper(200,0.5,0.5);
    get_keypress(state, KEY_DEVICE_ID);
    disp(state.config.scanReadyText);
    logappend(state,'FUNCTIONAL_SCAN_START');
end
    

%%%%%%%%%%%%%%%%%%%
% HELPER FUNCTION %
%%%%%%%%%%%%%%%%%%%

function[] = kill_experiment(state)
if exist('state','var')
    logappend(state,'END_EXP');
end
Screen('CloseAll');
ShowCursor;
ListenChar(1);

function[] = logappend(state,event_type,varargin)
if ~isempty(varargin)
    varargin = cellfun(@string_it,varargin,'UniformOutput',false);
end
message = join('\t',{sprintf('%0.37f',GetSecs) event_type varargin{:}}); %#ok<CCAT>
fid = fopen(state.logfile,'a+');
fprintf(fid,[message,'\n']);
fclose(fid);
if state.config.DUAL_SCREEN
    fprintf([message,'\n']);
end

function[kb_name,dev_id] = get_keyboard()
[d,i] = GetKeyboardIndices;

%try internal keyboard
internal_keyboards = ~cellfun(@isempty,cellfun(@(x)(strfind(lower(x),'internal keyboard')),i,'UniformOutput',false));
if sum(internal_keyboards) == 0
    keyboards = ~cellfun(@isempty,cellfun(@(x)(strfind(lower(x),'keyboard')),i,'UniformOutput',false));
    if sum(keyboards) == 0
        disp('   *** Keyboard not found! ***');
        ShowCursor;
        ListenChar(1);
        keyboard;
    end
else
    keyboards = internal_keyboards;
end
kb_name = i{find(keyboards,1,'first')};
dev_id = d(find(keyboards,1,'first'));

function[bb_name,dev_id] = get_button_box(state)
[d,i] = GetKeyboardIndices;
button_box = ~cellfun(@isempty,cellfun(@(x)(strfind(lower(x),'xkeys')),i,'UniformOutput',false));
if sum(button_box) == 0 %try XKeys instead...
    button_box = ~cellfun(@isempty,cellfun(@(x)(strfind(lower(x),'932')),i,'UniformOutput',false));
end
if sum(button_box) == 0    
    disp('   *** Button box not found! ***');
    debug_button_box(state);
    [d,i] = GetKeyboardIndices;
    button_box = ~cellfun(@isempty,cellfun(@(x)(strfind(lower(x),'932')),i,'UniformOutput',false));
end
try
    bb_name = i{find(button_box,1,'first')};
    dev_id = d(find(button_box,1,'first'));
catch %#ok<CTCH>
    ShowCursor;
    ListenChar(1);
    error('   *** Debugging button box failed.  Killing experiment. ***');
end

function[] = debug_button_box(state)
global KEY_DEVICE;
global KEY_DEVICE_ID;
global BUTTON_DEVICE;
global BUTTON_BOX_ID;

ListenChar(0);
ShowCursor;
fprintf('   *** ENTERING BUTTON BOX DEBUG MODE ***\n   DEVICES PRESENT:\n');
[ids,names] = GetKeyboardIndices;
for i = 1:length(ids)
    fprintf('\t\t%d.) %s (ID: %d)\n',i,names{i},ids(i));
end
fprintf('   **************************************\n');
fprintf('\tKEY_DEVICE: %s (ID: %d)\n',KEY_DEVICE,KEY_DEVICE_ID);
fprintf('\tBUTTON_BOX: %s (ID: %d)\n',BUTTON_DEVICE,BUTTON_BOX_ID);
fprintf('   **************************************\n');
keyboard;
ListenChar(2);
if ~state.config.DEBUG_MODE
    HideCursor;
end

function[s] = string_it(x) %limited string conversion
if ischar(x)
    s = x;
elseif isnumeric(x)
    s = num2str(x);
end

function[s] = join(d,varargin)
%S=JOIN(D,L) joins a cell array of strings L by inserting string D in
%            between each element of L.  Meant to work roughly like the
%            PERL join function (but without any fancy regular expression
%            support).  L may be any recursive combination of a list 
%            of strings and a cell array of lists.
%
%For any of the following examples,
%    >> join('_', {'this', 'is', 'a', 'string'} )
%    >> join('_', 'this', 'is', 'a', 'string' )
%    >> join('_', {'this', 'is'}, 'a', 'string' )
%    >> join('_', {{'this', 'is'}, 'a'}, 'string' )
%    >> join('_', 'this', {'is', 'a', 'string'} )
%the result is:
%    ans = 
%        'this_is_a_string'
%
%Written by Gerald Dalley (dalleyg@mit.edu), 2004

if isempty(varargin) 
    s = '';
else
    if (iscell(varargin{1}))
        s = join(d, varargin{1}{:});
    else
        s = varargin{1};
    end
    
    for ss = 2:length(varargin)
        s = [s d join(d, varargin{ss})]; %#ok<AGROW>
    end
end

function[dname] = get_backup_dirname(basedir)
if ~exist(fullfile(basedir,'backup'),'dir')
    dname = fullfile(basedir,'backup');
else
    i = 1;
    dname = fullfile(basedir,sprintf('backup_%d',i));
    while exist(dname,'dir')
        i = i+1;
        dname = fullfile(basedir,sprintf('backup_%d',i));
    end
end

function[] = move_dir_contents(source,dest)
c = dir(fullfile(source,'*'));
mkdir(dest);
err_flag = false;
for i = 1:length(c)
    if ismember(c(i).name,{'.' '..'});
       continue;
    end
    fprintf('\tMOVING %s...',c(i).name);
    success = movefile(fullfile(source,c(i).name),fullfile(dest,c(i).name));
    if success
        fprintf('DONE\n');
    else
        fprintf('FAILED\n');
        err_flag = true;
    end
end
if err_flag
    keyboard;
end

function[] = copydir(source, dest)
cmd = sprintf('cp -R ''%s'' ''%s''',source,dest);
if ~strcmp(cmd(end-1),filesep)
    cmd = [cmd(1:end-1), filesep, cmd(end)];
end
system(cmd);