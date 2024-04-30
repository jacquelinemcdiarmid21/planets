% Template script for EEG data analysis. This script will draw upon the
% previous work package I sent you: https://cloud.psy.gla.ac.uk/index.php/s/6OFKapluGSq5cJ8
% If you run into issues while I'm gone, try to solve it yourself by
% searching for errors or issues on Google. This is what I do about 50% of
% my time spent coding :)
% For MemPing project; SvB

clear all; close all; clc %this cleans up MATLAB

%% Step 0: Before starting
% Make sure FieldTrip is initialized. In MATLAB, navigate into the folder of
% FieldTrip and type 'ft_defaults'. Then navigate your way back to this
% folder.
ft_defaults

% Select participant to work over
dataset = 'pp01.vhdr';

%% Step 1: Load data
cfg = [];                               
cfg.dataset = dataset;
data_eeg    = ft_preprocessing(cfg);
data_eeg.label % 64 channels: https://pressrelease.brainproducts.com/wp-content/uploads/M1.jpg
size(data_eeg.trial{1}) % The data is 64 x Big Number. The first dimension is the number of trials.
                     % The second dimension are the samples (datapoints).
                     % There are many samples -- the data is "continuous"
                     % by default. We need to slice it up into various
                     % trials.  
                     
%% Step 2: Plotting raw data
channel = 1;
plot(data_eeg.time{1}, data_eeg.trial{1}(channel, :)) 
xlabel('time (s)')
ylabel('channel amplitude (uV)')

% For more information on reading in continuous data, see:
% https://www.fieldtriptoolbox.org/tutorial/continuous/#segmenting-continuous-data-into-trials

%% Step 3: Preprocessing data
% Preprocessing refers to a family of steps to prepare your data for full
% analysis, including cleaning, artefact rejection, and filtering.
% In the previous work package I showed how to slice up the data before
% preprocessing, but I actually think it's better to first preprocess.

% % BASELINE CORRECTION
% % Baseline correction removes general slow drifts in the data that are unlikely
% % to be meaningful: https://i.imgur.com/MR1N074.png. You need to set a window
% % in which this trend is estimated. Usually, we want to correct for general trends
% % just briefly before the moment of interest (stimulus presentation).         
% cfg = [];
% cfg.demean          = 'yes';
% cfg.baselinewindow  = [-0.2 0];  

% FILTERING
% Filtering removes certain frequencies from the data altogether. We are
% not interested in extremely slow or extremely fast oscillations, and
cfg                 = [];
cfg.lpfilter        = 'yes';    
cfg.lpfreq          = [80]; % Removes oscillations lower than 0.2 Hz
                                % and higher than 80 Hz. 
data_filt = ft_preprocessing(cfg, data_eeg);

cfg.bpfreq          = [50 50]; % Let's also remove 50 Hz, which is what
                               % electricity in the UK is sent at (line
                               % noise). This can create noise too
data_filt = ft_preprocessing(cfg, data_filt);

%% Step 4: Check "triggers" (event values) from data
cfg = [];
cfg.dataset             = dataset;
cfg.trialdef.eventtype  = '?';
dummy                   = ft_definetrial(cfg); % this shows all the triggers

% What do all these triggers ("event values") mean?
% Each trigger happens at a specific point in time in the data, and
% signifies when an event happens, allowing you to organize your data
% for subsequent analyses. Here is the meaning of each trigger:
% 10 = start of encoding block (https://i.imgur.com/W5Wjqni.png)
% 11 = start of working memory test (https://i.imgur.com/IJsfY0N.png)
% 12 MISSING?? supposed to be start retrieval
% 13 = start of retrieval test (https://i.imgur.com/zvJKkZa.png)
% 14 = start of new block
% 20 = a stimulus (word of a word-image pair) during retrieval that will soon be pinged
% 21 = a stimulus (word of a word-image pair) during retrieval that will not be pinged
% 22 = the actual ping itself
% Some more that are not relevant just yet

%% Step 5: Retrieve stimulus triggers
% OK so there is another file: "trig_code_ppxx.mat" which tells you which
% association is tested when during retrieval.
load trig_code_pp01.mat

% Check out set_ret
disp(set_ret); % This is a 8x40 matrix where rows (8) represents each block
               % and the 40 numbers represent four retrievals of each
               % word-image pair (remember there were 10 pairs).
               
% What does each number in this matrix mean? To know that, check out the
% stimulus file ("stimlist.xlsx") in Excel. Ignore the first column.
% The second column has stimulus names. The third column has their category. The fourth
% column has their category in number format. You can now backtrack which stimulus was presented when.
% For example:
disp(set_ret(2,6)) % In the 2nd block, 6th retrieval trial, stimulus 181 was presented.
% What was that? Go to row 181 in the Excel file, it was: so_street1.jpg
% This is a an outdoor scene, as you can tell from the other columns.

%% Step 5: Extract data structure of interest based on triggers
cfg = [];  
cfg.dataset             = dataset;
cfg.trialdef.eventtype  = 'Stimulus';
cfg.trialdef.eventvalue = {'S 20', 'S 21'}; % You enter triggers here of triggers (events)
                                            % you wish to analyze around.
                                            % For example here, we extract
                                            % retrieved word-image pairs
                                            % that will be pinged (S20) or
                                            % not (S21). Think about the
                                            % other event values and what
                                            % kinds of analyses you may
                                            % want to do for those!
cfg.trialdef.prestim    = 1;     % Cut out some time before [s]
cfg.trialdef.poststim   = 3;     % and some time after [s]
epoch_cfg               = ft_definetrial(cfg);  % Establish trial definition (how are we gonna cut the data)
epoched_data            = ft_redefinetrial(epoch_cfg,data_filt); % Execute it

% The data is now "epoched", we have pseudo trials cut around the events of interest.
disp(epoched_data)

% How many trials do we have? 40 retrieved pairs, 8 blocks = 320 trials.
% You can see under 
epoched_data.trialinfo % which trials were pinged (20) or not (21).

% Now let's get our info about which stimulus pair was presented when into
% the same format:
trig_info = set_ret(:); %now this one is also 1x320 (we have just flattened the previous matrix);

% summary:
% TRIG_INFO tells you which image was to be retrieved during any retrieval
% trial
% STIMLIST.XLSX tells you what those images were, and which category they
% were in.
% EPOCHED_DATA.TRIALINFO tells you whether a retrieval trial was pinged (20) or
% not (21)
% EPOCHED_DATA.TRIAL gives you the actual EEG data, with 320 trials that
% you can now link up to anything you want: which ones were pinged, which
% ones were objects or scenes, whatever. Each trial is 64x4000 (64 channels
% x 4000 datapoints [we cut out 4 seconds]).

%% Step 6: Continue based on what you learned from the other work package
% Can you think about how we should proceed from here? In principle, from
% here on the kinds of analyses one can do is very open-ended. I want to
% give you some room to try and play around for yourself here.

% HINT 1: you probably want to use the excel file to filter EEG data trials
% that are of one category versus another to perform contrasts. You can
% filter data by trials like so:
cfg = [];
cfg.trials = 100:200; %enter range here
cut_data = ft_selectdata(cfg,epoched_data); %now you have "cut_data" with only those trials

% HINT 2: Use what you have learned from my previous Work Package to carry
% out analyses you are interested in. https://cloud.psy.gla.ac.uk/index.php/s/6OFKapluGSq5cJ8
% Here are some things that should be done still:
% - Perform baseline correction in the data (step 5 in tutorial 1). You
% don't need to filter anymore; we already did that.
% - Temporarily combine the two datasets (step 5 in tutorial 1)
% - Remove artefacts (step 6 in tutorial 1)
% NOTE: do not load dccn_customized_acticap64.mat. Instead, load
% easycapm20.mat (this is the relevant EEG cap file)
% - Look at the data again (step 7 in tutorial 1)
% - Perform EEG analyses from step 8 (in tutorial 1) onwards but adapt
% based on what you want to test. Timelocked ERP analysis should be
% possible.

% HINT 3: why not go back and try extracting the data in a different way?
% Right now we're extracting based on when word-image pairs are retrieved,
% but we can also perform an ERP analysis on the ping itself to see if
% there is a strong bump in the signal right after. To do that you just
% need to change cfg.trialdef.eventvalue to 22 (the actual ping, see the
% event code list above).
