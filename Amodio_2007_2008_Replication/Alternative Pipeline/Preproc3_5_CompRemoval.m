%% Authored by Paveen Phon-Amnuaisuk. Shows SASICA, iclabel, and component scroll gui per subject to enable quicker removal of components

% PLEASE READ:
% to use this script you must have bva.io installed as a plugin
%To install: open EEGLAB -> File -> Manage EEGLAB Extensions -> search
%BVA-> Install/Update
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

%ask user whether they want to interpolate P3, ERN or N2 files
%type = input('P3, ERN or N2?' ,'s');
type = 'weight';

%% SASICA and ICLabel
for m = 2

    subnum = files(m).name;

    % pop dataset
    EEG = pop_loadset([data_path num2str(subnum) '/' num2str(subnum) '_new_ica_' type '.set' ]);
    
    % Plot
    pop_eegplot(EEG, 0, 1, 1);

    % IC Label
    EEG = iclabel(EEG, 'default');
    EEG = pop_icflag(EEG, [NaN NaN;0.6 1;0.6 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]);
    pop_viewprops(EEG, 0, [1:height(EEG.icaact)], {'freqrange', [2 80]}, {}, 1, 'ICLabel');

    % SASICA - feels unecessary...
    %EEG.sasica = SASICA(EEG, 'method', {'autocorr', 'focalcomp', 'SNR', 'ADJUST'});
            
    % Remove
    res = input('Components to remove, place in brackets with space or , as separator e.g., [1, 2, 3]: ');
    EEG = pop_subcomp(EEG, [res]);

    % Close figure
    h = findobj('Type', 'figure');        
    close(h);

    % Save components as EEG struct
    EEG.CompRemoved = res;

    % Save dataset 
    EEG = pop_saveset(EEG, 'filename', [num2str(subnum) '_comprem_' type '.set'], 'filepath', [data_path num2str(subnum)]);

    h = findobj('Type', 'figure');        
    close(h);

end

    % SASICA
    % EEG = SASICA(EEG, 'method', {'Autocorrelation', 'Focal components','Signal to noise ratio', 'ADJUST selection'}); seems to work butneeds more testing to confirm
%     SASICA(EEG,'MARA_enable',1,'FASTER_enable',0,'FASTER_blinkchanname','No channel','ADJUST_enable',1, ...
%         'chancorr_enable',0,'chancorr_channames','No channel','chancorr_corthresh','auto 4','EOGcorr_enable',0, ...
%         'EOGcorr_Heogchannames','No channel','EOGcorr_corthreshH','auto 4','EOGcorr_Veogchannames','No channel', ...
%         'EOGcorr_corthreshV','auto 4','resvar_enable',0,'resvar_thresh',15,'SNR_enable',1,'SNR_snrcut',1, ...
%         'SNR_snrBL',[-Inf 0] ,'SNR_snrPOI',[0 Inf] ,'trialfoc_enable',0,'trialfoc_focaltrialout','auto', ...
%         'focalcomp_enable',1,'focalcomp_focalICAout','auto','autocorr_enable',1,'autocorr_autocorrint',20, ...
%         'autocorr_dropautocorr','auto','opts_noplot',0,'opts_nocompute',0,'opts_FontSize',14);
%     
    % Note the SASICA GUI's pre-selected components do not dictate the automatic removal of any componenets, 
    % so if you press enter without typing any number below, 0 components will be removed despite it being shown as red in SASICA's GUI
    % EEG.reject.gcompreject; you can uncomment this line and itll show you the components marked for auto removal, which should be 0 for all