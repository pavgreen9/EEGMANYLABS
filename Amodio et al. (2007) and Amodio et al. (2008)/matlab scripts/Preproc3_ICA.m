clc;
clear;

data_path = '/home/pavgreen/Documents/LRGS/EEG/EEGMANYLABS2/raw_pilot_datac/';

%get foldernames
files1 = dir(data_path);
files1 = files1([files1.isdir]);

%read in only participant files
matches = regexp({files1.name}, {'^\d+|^A\d+'});
bool = cellfun(@(x) any(x), matches);
files = files1(bool);

addpath '/home/pavgreen/Documents/LRGS/EEG/eeglab2022.1';
eeglab;

%% batch process 

for i = 1:length(files)
   
    %get names of each subject's folder
    subnum = files(i).name;
    
    %load interpolated data
    EEG = pop_loadset([data_path num2str(subnum) '/A' num2str(subnum) '_interp.set' ]);
    
    
    %run ICA
    EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','on');
    
    
    %save data
    EEG = pop_saveset( EEG, 'filename',['A' num2str(subnum) '_new_ica_.set'], ...
        'filepath',[data_path num2str(subnum)]);


end

%% after this, look at data in GUI and do the following:

% 1. Load existing dataset (the ICA file for each participant)
% 2. Go to Tools - SASICA (make sure you have installed Signal processing
% toolbox and the Statistics & Machine Learning Toolbox)
% 3. Tick Autocorrelation, Focal Components, Signal to noise Ratio, ADJUST
% Selection. Press Compute
% 4. Verify whether components to be rejected are sensible. See if any
% other components need to be removed, can cross reference with IClabel 
% 5. Go to Tools -> Remove components from data 
% 6. check ERPs and plot data
% 7. reject components, save data as <subID>_comprem.set
% note down which components were removed