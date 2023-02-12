clc;
clear;

data_path = '/home/pavgreen/Documents/LRGS/EEG/EEGMANYLABS/';

%get foldernames
files1 = dir(data_path);
files1 = files1([files1.isdir]);

%read in only participant files
matches = regexp({files1.name}, {'^\d+|^A\d+'});
bool = cellfun(@(x) any(x), matches);
files = files1(bool);

addpath '/home/pavgreen/Documents/LRGS/EEG/eeglab2022.1';
eeglab;

%% SASICA
for i = 1:length(files)

    subnum = files(i).name;

    % pop dataset
    EEG = pop_loadset([data_path num2str(subnum) '/A' num2str(subnum) '_new_ica_.set' ]);

    % IC Label
    EEG = iclabel(EEG);
    pop_viewprops( EEG, 0, [1:29], {'freqrange', [2 80]}, {}, 1, 'ICLabel' );

    % Plot
    pop_eegplot( EEG, 0, 1, 1); %plot data

    % SASICA
    % EEG = SASICA(EEG, 'method', {'Autocorrelation', 'Focal components','Signal to noise ratio', 'ADJUST selection'}); seems to work butneeds more testing to confirm
    SASICA(EEG,'MARA_enable',1,'FASTER_enable',0,'FASTER_blinkchanname','No channel','ADJUST_enable',1, ...
        'chancorr_enable',0,'chancorr_channames','No channel','chancorr_corthresh','auto 4','EOGcorr_enable',0, ...
        'EOGcorr_Heogchannames','No channel','EOGcorr_corthreshH','auto 4','EOGcorr_Veogchannames','No channel', ...
        'EOGcorr_corthreshV','auto 4','resvar_enable',0,'resvar_thresh',15,'SNR_enable',1,'SNR_snrcut',1, ...
        'SNR_snrBL',[-Inf 0] ,'SNR_snrPOI',[0 Inf] ,'trialfoc_enable',0,'trialfoc_focaltrialout','auto', ...
        'focalcomp_enable',1,'focalcomp_focalICAout','auto','autocorr_enable',1,'autocorr_autocorrint',20, ...
        'autocorr_dropautocorr','auto','opts_noplot',0,'opts_nocompute',0,'opts_FontSize',14);
    
    % Note the SASICA GUI's pre-selected components do not dictate the automatic removal of any componenets, 
    % so if you press enter without typing any number below, 0 components will be removed despite it being shown as red in SASICA's GUI
    % EEG.reject.gcompreject; %you can uncomment this line and itll show you the components marked for auto removal, which should be 0 for all

    % Remove
    res = input('Components to remove, place in brackets with space or , as separator e.g., [1, 2, 3]: ');
    EEG = pop_subcomp( EEG, res );

    % Save
    contLoop = true;

    while contLoop

        answ = input(['Press 0 to close all GUI and proceed, pressing any other number will refresh the while loop, ' ...
            'any other character will result in an error but functional):']);

        if answ == 0

            EEG = pop_saveset( EEG, 'filename', ['A' num2str(subnum) '_comprem.set'], 'filepath', [data_path num2str(subnum)]);
            h = findobj('Type', 'figure');        
            close(h);
            break;

        end

    end
end