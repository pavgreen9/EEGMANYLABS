%% for conducting ICA
clc;
clear;

data_path = '/home/pavgreen/Documents/LRGS/EEG/alt/study/';
%data_path = '/home/pavgreen/Documents/LRGS/EEG/alt/pilot/';

%get foldernames
files1 = dir(data_path);
files1 = files1([files1.isdir]);

%read in only participant files
matches = regexp({files1.name}, {'^\d+'});
bool = cellfun(@(x) any(x), matches);
files = files1(bool);

addpath '/home/pavgreen/Documents/LRGS/EEG/eeglab2023.0';
eeglab;

type = 'weight';

%% batch process 
for m = [23, 25]%1:length(files)
   
    subnum = files(m).name; %get names of each subject's folder
    
    %load interpolated data
    EEG = pop_loadset([data_path num2str(subnum) '/' num2str(subnum) '_new_epoched_clean_' type '.set' ]);
    
    %check ICA datapoint 
    if length(EEG.epoch) < 60
        disp('Not enough datapoints for ICA')

    else
        % get rank - 
        EEG.pcakeep = rank(EEG.data(:, :));
    
        % AMICA
        EEG = pop_runamica(EEG);
    
        %save data
        EEG = pop_saveset( EEG, 'filename',[num2str(subnum) '_new_ica_' type '.set'], ...
            'filepath',[data_path num2str(subnum)]);

    end

end

