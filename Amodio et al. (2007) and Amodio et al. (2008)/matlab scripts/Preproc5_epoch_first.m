%This script applies a bandpass filter to files with components removed and re-references data to A1 and A2
clc;
clear;

data_path = '/home/pavgreen/Documents/LRGS/EEG/EEGMANYLABS2/raw_pilot_data/';

%get foldernames
files1 = dir(data_path);
files1 = files1([files1.isdir]);

%read in only participant files
matches = regexp({files1.name}, {'^\d+|^A\d+'});
bool = cellfun(@(x) any(x), matches);
files = files1(bool);

addpath '/home/pavgreen/Documents/LRGS/EEG/eeglab2022.1';
eeglab;

%% cleaning
for i = 1:length(files)
   
    subnum = files(i).name; %get names of each subject's folder
    
    EEG = pop_loadset([data_path num2str(subnum) '/A' num2str(subnum) '_comprem.set']);

    %re-reference data to average reference and add back A1 to be included in the average of all channels
    EEG = pop_reref( EEG, [],'refloc', ...
        struct('labels',{'A1'},'type',{''}, ...
        'theta',{-106.2516},'radius',{0.70712}, ...
        'X',{-25.0093},'Y',{85.7939},'Z',{-68.031}, ...
        'sph_theta',{106.2516},'sph_phi',{-37.2811},'sph_radius',{112.3133}, ...
        'urchan',{[]},'ref',{''},'datachan',{0}));
    
    %re-reference to A1 and A2 (earlobes)
    EEG = pop_reref( EEG, [30 31] );
    
    %% clean ERN and N2 files separately
    clear forERP %clears memory for next participant
    
    forERP (1) = EEG; %EEG_ERN
    %forERP (2) = EEG_N2;
    
    % Originally {'ERN','N2'} 
    ERP_name = {'ERN'};
    ERP_name = string(ERP_name);

    for m = 1:length(forERP)
    
        %% cleaned of bad segments (epochs deviating more than 3.29 SD) (Ref Tabachnik 2007)
        % from trimmed normalized means with respect to joint probability, kurtosis or the spectrum)
        % code adapted from  Paul et al. (2021): https://osf.io/2w9gy/?view_only=d79c0538c9e04f1298848dcfd7266d5d
        Clean_Epochs_Mask = ones(1,forERP(m).trials);
        threshold_DB = 90;
        threshold_SD = 3.29;
        
        % Check Frequency Spectrum
        [~, bad_Spectrum] = pop_rejspec(forERP(m), 1, 'elecrange', [1:forERP(m).nbchan], 'threshold', [-threshold_DB threshold_DB], 'freqlimits', [1 30]);
        Clean_Epochs_Mask(bad_Spectrum) = 0;
        
        % Check Kurtosis
        bad_Kurtosis = pop_rejkurt(forERP(m), 1, [1:forERP(m).nbchan],  threshold_SD,threshold_SD,0,0,0);
        bad_Kurtosis = find(bad_Kurtosis.reject.rejkurt);
        Clean_Epochs_Mask(bad_Kurtosis) = 0;
        
        % Check Probability 
        bad_Probability = pop_jointprob(forERP(m), 1, [1:forERP(m).nbchan],  threshold_SD, threshold_SD,0,0,0);
        bad_Probability = find(bad_Probability.reject.rejjp);
        Clean_Epochs_Mask(bad_Probability) = 0;
        
        % Remove bad Epochs
        forERP(m) = pop_select( forERP(m), 'trial',find(Clean_Epochs_Mask));
        
        %% Add Info on Cleaning (bad segments, channels, ICAs, epochs) and Save File 
        forERP(m).AC = struct(...
            'Clean_Epochs_Mask', Clean_Epochs_Mask);
        
        %save data, this is the data we'll be doing ERP analysis on
        forERP(m) = pop_saveset(forERP(m), 'filename',['A' num2str(subnum) '_' char(ERP_name(m)) '_clean.set'], ...
            'filepath',[data_path num2str(subnum)]);

    end 

end
