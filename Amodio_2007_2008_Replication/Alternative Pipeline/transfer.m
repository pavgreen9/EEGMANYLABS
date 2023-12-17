%% transfer weight
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

%type = input('P3, ERN or N2?' ,'s');
type = 'P3';

for m = [23, 25]%1:length(files)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Preproc1 
    subnum = files(m).name; %get names of each subject's folder

    %reads in EEG data for current subject
    EEG = pop_loadbv([data_path num2str(subnum)], [num2str(subnum) '.vhdr'], [], [1:30]);

    % load weight
    EEG2 = pop_loadset([data_path num2str(subnum) '/' num2str(subnum) '_new_ica_weight.set' ]);

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

    % Filter the data
    % bandpass 
    EEG= pop_basicfilter(EEG, 1:EEG.nbchan , 'Boundary', 'boundary', 'Cutoff', [0.1 30], 'Design', 'butter', 'Filter', 'bandpass', 'Order',2, 'RemoveDC', 'on');% Script: 30-Jun-2022 14:44:19

    % Cleanlinenoise
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

    % Cut off 1.5 seconds from both edges to remove filter artifacts - Anna's
    EEG = pop_select( EEG,'notime',[0 1.5; EEG.xmax-1.5 EEG.xmax]);

    % reref to half of linked ear
    ref = EEG.data(30, :)/2;
    EEG.data(30, :) = ref;
    EEG = pop_reref(EEG, 30);

    % epoch data into correct no-Go trials for P3 (please check if this is correct)
    EEG = pop_epoch(EEG , {2, 3, 4}, [-0.5 0.8], 'epochinfo', 'yes');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% preproc 2

    for i = 1:length(EEG2.interpChannelsBeforeICA)
        chosen_channels = EEG2.interpChannelsBeforeICA{i};
        EEG = pop_interp(EEG, [chosen_channels], 'spherical');
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% preproc 3

    % mv
    EEG = pop_select(EEG, 'trial',find(EEG2.mv));

    % mask
    EEG = pop_select( EEG, 'trial',find(EEG2.AC.Clean_Epochs_Mask));

    % manual
    for i = height(EEG2.filt):-1:1
        eval(EEG2.filt(i, :))
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% apply weight

    EEG = pop_editset(EEG, 'icaweights', EEG2.icaweights, 'icasphere', EEG2.icasphere, 'icachansind', EEG2.icachansind);

    % iclabel on 1hz
    EEG2 = iclabel(EEG2, 'default');
    EEG2 = pop_icflag(EEG2, [NaN NaN;0.7 1;0.7 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]);
    pop_viewprops(EEG2, 0, [1:height(EEG2.icaact)], {'freqrange', [2 80]}, {}, 1, 'ICLabel');

    res = find(EEG2.reject.gcompreject);
    res = reshape(res, 1, height(res));

    %res = input('Components to remove, place in brackets with space or , as separator e.g., [1, 2, 3]: ');

    % component from 1hz to 0.1hz
    EEG = pop_subcomp(EEG, [res]); 

    EEG = pop_saveset( EEG, 'filename',[num2str(subnum) 'comprem' type '.set'], ...
            'filepath',[data_path num2str(subnum)]);

end

%% clean
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for m = [23, 25]%1:length(files)

    %% Preproc1 
    subnum = files(m).name; %get names of each subject's folder

    EEG = pop_loadset([data_path num2str(subnum) '/' num2str(subnum) 'comprem' type '.set']);
    
    % while loop
    interp_channels_after_ICA = [];

    while true

        %plot data
        pop_eegplot( EEG, 1, 1, 1);

        %prompt for saving data
        answers2 = input('Save data? Press 1 for Yes or 2 for No:');

        if answers2 == 1

            %save which channels were interpolated as part of EEG struct
            EEG.interpChannelsAfterICA = interp_channels_after_ICA;

            EEG = pop_rmbase(EEG, [-200 0]); 

            % Close all GUI
            h = findobj('Type', 'figure');        
            close(h);

            disp(['Saved participant' num2str(subnum)]);
            break;

        else 

            %plot spectra map, see if any channels deviate from the masses
            %click on line to determine which channel it is

            figure; pop_spectopo(EEG, 1, [-500  800], 'EEG' , 'freq', [6 10 22], 'freqrange',[2 25],'electrodes','off');
            %pop_prop( EEG, 1, [4, 8, 26, 9, 12, 24, 17, 18, 21], NaN, {'freqrange',[2 50] })

            %display which file is being interpolated
            disp(['Currently checking participant' num2str(subnum)]);

            %Matlab will ask you which channel numbers you would like to interpolate
            answers = input('Which channels would you like to interpolate? Enter the numbers, separated by a comma : ','s');
            answers = regexprep(answers,',',' ');
            chosen_channels = str2num(answers);

            %interpolates channels
            EEG = pop_interp(EEG, [chosen_channels], 'spherical');

            % Close all GUI
            h = findobj('Type', 'figure');        
            close(h);

            %save channels that were interpolated 
            interp_channels_after_ICA = [interp_channels_after_ICA chosen_channels]

        end
    end      
    %}
    EEG = pop_eegthresh(EEG, 1, [1:EEG.nbchan], -100, 100, -0.5, 0.8, 0, 0);
    keep = ~EEG.reject.rejthresh;
    EEG = pop_select(EEG, 'trial',find(keep));
    %{
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

    pop_eegplot( EEG, 1, 1, 1);
    %}
    
    EEG = pop_saveset( EEG, 'filename',[num2str(subnum) 'comprem' type '.set'], ...
            'filepath',[data_path num2str(subnum)]);
end