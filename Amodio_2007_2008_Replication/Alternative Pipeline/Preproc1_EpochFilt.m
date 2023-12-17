% For epoching, notch filtering, and adding back the A1 electrode. 


clc;
clear;

data_path = '/home/pavgreen/Documents/LRGS/EEG/alt/pilot/';

%get foldernames
files1 = dir(data_path);

%read in only participant files
matches = regexp({files1([files1.isdir]).name}, {'^\d+|^A\d+'});
bool = cellfun(@(x) any(x), matches);
files = files1(bool);


addpath '/home/pavgreen/Documents/LRGS/EEG/eeglab2022.1';
eeglab;


%% batch process up to epoching the data

for i = 1:length(files)
   
    subnum = files(i).name; %get names of each subject's folder
    
    %reads in EEG data for current subject
    EEG = pop_loadbv([data_path num2str(subnum)], [num2str(subnum) '.vhdr'], [], [1:30]);
    
    %add back online reference (A1)
    EEG = pop_chanedit(EEG, ...
        'lookup','/home/pavgreen/Documents/LRGS/EEG/eeglab2022.1/plugins/dipfit/standard_BEM/elec/standard_1005.elc', ...
        'insert',29,'changefield',{29,'labels','A1'}, ...
        'changefield',{29,'X','-85.7939'}, 'changefield',{29,'Y','-25.0093'},'changefield',{29,'Z','-68.031'}, ...
        'convert',{'cart2all'},'changefield',{29,'datachan',1},'changefield',{29,'datachan',0});
    
    %import new event list
     EEG = pop_importevent( EEG, 'append','no','event',[data_path num2str(subnum) '/eventnew.txt'], ...
         'fields',{'latency','duration','type'},'skipline',1,'timeunit',NaN);
    
    %create event list
    EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', ...
       'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' } ); 
    EEG.setname=['A' subnum '_elist'];
    
    %read in bin descriptor file
    EEG  = pop_binlister( EEG , ...
        'BDF', [data_path 'bindescriptor.txt'], ...
        'IndexEL',  1, 'SendEL2', 'EEG', 'UpdateEEG', 'on', 'Voutput', 'EEG' ); 
    
    %apply notch filter
    EEG  = pop_basicfilter( EEG,  1:29 , ...
        'Boundary', 'boundary', 'Cutoff',  50, 'Design', 'notch', 'Filter', 'PMnotch', ...
        'Order',  180, 'RemoveDC', 'on' ); 
    
    
    %apply bandpass filter (0.1-30Hz)
    EEG= pop_basicfilter(EEG, 1:29 , 'Boundary', 'boundary', 'Cutoff', [0.1 30], 'Design', 'butter', 'Filter', 'bandpass', 'Order',2 );% Script: 30-Jun-2022 14:44:19
    
    %% epoch data into correct and incorrect trials for ERN (please check if this is correct)
    %baseline correction based on Amodio et al 2007
     EEG_ERN = pop_epochbin( EEG , [-400  400], [-400 -50] ); %baseline correction -400 to -50 before stimulus onset
    
    %% OR epoch data into correct Go and No/Go for N2 (please check if this is correct)
    %baseline correction based on Amodio et al 2007
     EEG_N2 = pop_epochbin( EEG , [-200  800], [100 200] ); %baseline correction 100 to 200ms after stimulus onset
    
    
    %save data
    EEG_ERN = pop_saveset(EEG_ERN, 'filename',[subnum '_new_epochedERN.set'], ...
        'filepath',[data_path num2str(subnum)]);
    
    EEG_N2 = pop_saveset(EEG_N2, 'filename',[subnum '_new_epochedN2.set'], ...
        'filepath',[data_path num2str(subnum)]);


end
