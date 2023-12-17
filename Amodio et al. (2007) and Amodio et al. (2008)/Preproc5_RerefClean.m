%This script applies a bandpass filter to files with components removed and
%re-references data to A1 and A2

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

for m = [25]%1:length(files)

    subnum = files(m).name; %get names of each subject's folder
    
    EEG = pop_loadset([data_path num2str(subnum) '/' num2str(subnum) '_new_interp_' type '.set']);

    %% reject artifacts
    EEG = pop_eegthresh(EEG, 1, [1:EEG.nbchan], -500, 500, -0.5, 0.8, 0, 0);
    keep = ~EEG.reject.rejthresh;
    EEG.mv = keep;
    EEG = pop_select(EEG, 'trial',find(keep));

    %% cleaned of bad segments (epochs deviating more than 3.29 SD (Ref Tabachnik 2007)
    % from trimmed normalized means with respect to joint probability, kurtosis or the spectrum)
    % code adapted from  Paul et al. (2021): https://osf.io/2w9gy/?view_only=d79c0538c9e04f1298848dcfd7266d5d
    Clean_Epochs_Mask = ones(1,EEG.trials);
    threshold_DB = 90;
    threshold_SD = 3.29;
    
    % Check Frequency Spectrum
    [~, bad_Spectrum] = pop_rejspec(EEG, 1, 'elecrange', [1:EEG.nbchan], 'threshold', [-threshold_DB threshold_DB], 'freqlimits', [1 30]);
    Clean_Epochs_Mask(bad_Spectrum) = 0;
    
    % Check Kurtosis
    bad_Kurtosis = pop_rejkurt(EEG, 1, [1:EEG.nbchan],  threshold_SD,threshold_SD,0,0,0);
    bad_Kurtosis = find(bad_Kurtosis.reject.rejkurt);
    Clean_Epochs_Mask(bad_Kurtosis) = 0;
    
    % Check Probability 
    bad_Probability = pop_jointprob(EEG, 1, [1:EEG.nbchan],  threshold_SD, threshold_SD,0,0,0);
    bad_Probability = find(bad_Probability.reject.rejjp);
    Clean_Epochs_Mask(bad_Probability) = 0;
    
    % Remove bad Epochs
    EEG = pop_select( EEG, 'trial',find(Clean_Epochs_Mask));

    % Add Info on Cleaning (bad segments, channels, ICAs, epochs) and Save File 
    EEG.AC = struct('Clean_Epochs_Mask', Clean_Epochs_Mask);

    %% manual check
    % while loop
    while true

        %plot data
        pop_eegplot( EEG, 1, 1, 1);

        %clean epoch mask
        chosen_trials = ones(1,EEG.trials);

        figure; pop_spectopo(EEG, 1, [-500  800], 'EEG' , 'freq', [6 10 22], 'freqrange',[2 25],'electrodes','off');

        %prompt for saving data
        answers2 = input('Save data? Press 1 for Yes or 2 for No:');

        if answers2 == 1

            % store command
            hist = eegh;
            rowsWithPopRejepoch = contains(cellstr(hist), 'pop_rejepoch');
            EEG.filt = hist(rowsWithPopRejepoch, :);

            %save file
            EEG = pop_saveset( EEG, 'filename',[num2str(subnum) '_new_epoched_clean_' type '.set'], ...
                'filepath',[data_path num2str(subnum)]);

            % Close all GUI
            h = findobj('Type', 'figure');        
            close(h);

            disp(['Saved participant ' num2str(subnum)]);
            eeglab
            break;

        else 
            
            %display which file is being interpolated
            disp(['Select trials to remove via the plot GUI']);
    
            % Close all GUI
            h = findobj('Type', 'figure');        
            close(h);

        end

    end 

end 
