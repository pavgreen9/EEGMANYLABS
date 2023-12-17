% For epoching, notch filtering, and adding back the A1 electrode. 
clc;
clear;

data_path = '/home/pavgreen/Documents/LRGS/EEG/alt/study/';

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

%% batch process up to epoching the data

for m = [16, 23, 25, 31, 45]%1:length(files)
   
    subnum = files(m).name; %get names of each subject's folder

    %reads in EEG data for current subject
    EEG = pop_loadbv([data_path num2str(subnum)], [num2str(subnum) '.vhdr'], [], [1:30]);

    %add coordinates and reorient
    EEG=pop_chanedit(EEG, 'lookup','/home/pavgreen/Documents/LRGS/EEG/eeglab2023.0/plugins/dipfit/standard_BEM/elec/standard_1005.elc',...
        'eval','chans = pop_chancenter( chans, [],[]);');

    %import new event list
    EEG = pop_importevent( EEG, 'append','no','event',[data_path num2str(subnum) '/eventnew.txt'], ...
         'fields',{'latency','duration','type'},'skipline',1,'timeunit',NaN);
    
    %create event list
    EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', ...
       'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' } ); 
    EEG.setname=[subnum '_elist'];
    
    %read in bin descriptor file
    EEG  = pop_binlister( EEG , 'BDF', [data_path 'bindescriptor.txt'], ...
        'IndexEL',  1, 'SendEL2', 'EEG', 'UpdateEEG', 'on', 'Voutput', 'EEG' ); 

    %% Filter the data
    % bandpass 
    EEG= pop_basicfilter(EEG, 1:EEG.nbchan , 'Boundary', 'boundary', 'Cutoff', [1 30], 'Design', 'butter', 'Filter', 'bandpass', 'Order',2, 'RemoveDC', 'on');% Script: 30-Jun-2022 14:44:19

    %% Cleanlinenoise
    signal = struct('data', EEG.data, 'srate', EEG.srate);

    lineNoiseIn = struct('lineNoiseMethod', 'clean', ...
                         'lineNoiseChannels', 1:EEG.nbchan,...
                         'Fs', EEG.srate, ...
                         'lineFrequencies', [50 100 150 200],...
                         'p', 0.01, ...
                         'fScanBandWidth', 2, ...
                         'taperBandWidth', 2, ...
                         'taperWindowSize', 4, ...
                         'taperWindowStep', 1, ...
                         'tau', 100, ...
                         'pad', 2, ...
                         'fPassBand', [0 EEG.srate/2], ...
                         'maximumIterations', 10);

    [signalOut, lineNoiseOut] = cleanLineNoise(signal, lineNoiseIn);
    EEG.data = signalOut.data;

    %% Cut off 1.5 seconds from both edges to remove filter artifacts - Anna's
    EEG = pop_select( EEG,'notime',[0 1.5; EEG.xmax-1.5 EEG.xmax]);

    %% reref to half of linked ear
    ref = EEG.data(30, :)/2;
    EEG.data(30, :) = ref;
    EEG = pop_reref(EEG, 30);

    %% epoch data according to type
    if type == "weight"
        %% epoch data into correct no-Go trials for P300
        EEG = pop_epoch(EEG , {2, 3, 4}, [-0.5 0.8], 'epochinfo', 'yes');

        %% uncomment this for ERN based on Amodio et al 2007
        %EEG = pop_epoch(EEG , {2, 3, 4}, [-0.4 0.4], 'epochinfo', 'yes');
        % uncomment this to remove base
        %EEG = pop_rmbase(EEG, [-400 -50]); 

        %% uncomment this for N2 based on Amodio et al 2007
        %EEG = pop_epoch(EEG , {2, 3, 4}, [-0.2 0.8], 'epochinfo', 'yes');
        % uncomment this to remove base
        %EEG = pop_rmbase(EEG, [100 200]);

        %save data
        EEG = pop_saveset(EEG, 'filename',[subnum '_new_epoched_' type '.set'], ...
        'filepath',[data_path num2str(subnum)]);
    
    end
end