% read in each EEG file, export event per participant
% need to read in behavioural files too 
% change event file such that new trigger labels are assigned for correct
% and incorrect trials 
% stimulus (go and no-go) are labelled
% reimport event file per subject


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

for i = 1%:length(files)
   
    subnum = files(i).name; %get names of each subject's folder
    
    %load in data
    %EEG = pop_loadbv([data_path num2str(subnum)], ['A' num2str(subnum) 'gng.vhdr'], [], [1:29]);
    EEG = pop_loadbv([data_path num2str(subnum)], [ num2str(subnum) '.vhdr'], [], [1:29]);
    %export events
    pop_expevents(EEG, [data_path num2str(subnum) '/event.txt'], 'samples');
    
    %import gng behavioural file 
    behav_file = dir([data_path num2str(subnum) '/*.csv']);
    behav_data = readtable ([data_path num2str(subnum) '/' behav_file.name]);
    behav_data(isnan(behav_data.triggers(:,1)), :) = [];
    
    %index out trials that are too fast (<150ms), make them 0
    trialsToKeep = behav_data.key_resp_rt >= 0.150 | isnan(behav_data.key_resp_rt);
    
    %import events
    trig_file= readtable ([data_path num2str(subnum) '/event.txt']);
    
    %remove unecessary triggers
    trig_file= trig_file(ismember(trig_file.type(:,1),[1, 2, 3, 4]),:);
    
    %get only triggers associated with stimuli
    trig_file_stim = trig_file(ismember(trig_file.type(:,1),[1, 2]),:);
    
    %% take out triggers that occur too close in time in stimulus
    %change this such that it only implements if there are more than 500
    %triggers
    %threshold = 800; %need to find example first of instance where there are
    %too many triggers
    %trig_file_stim([false;(diff(trig_file_stim.latency)<=threshold)],:)=[];
    
    %triggers associated with responses
    check_trig = trig_file;
    
    %reset after each participant loop
    idx_first_response  = [];
    
    %for checking triggers that occur one after another (possibly because
    %participants double tap)
    for h = 1:height(check_trig)-1
     if (check_trig.type(h,1) == 3 & check_trig.type(h+1,1) == 3) | (check_trig.type(h,1) == 4 & check_trig.type(h+1,1) == 4)
         idx_first_response (h+1,1) = 1;
     else 
         idx_first_response (h+1,1) = 0;
     end
end

new_trig_file = check_trig(~idx_first_response,:);


%take out stimuli leaving only responses
new_trig_file((new_trig_file.type(:,1) == 1), :) = [];
new_trig_file((new_trig_file.type(:,1) == 2), :) = [];

%% change trig numbers to reflect incorrect go and correct no-go stim

%original triggers 
%1 - Go-stimulus
%2 - No-go stimulus
%3 - Correct go response
%4 - Incorrect no-go response

%what I want
%1 - incorrect Go Stimulus
%2 - Correct No-Go Stimulus
%3 - Correct Go Response
%4 - Incorrect No-Go Response

%everything else = 0 
for m = 1:height(behav_data)

    %if correct GO stim = 0
    if behav_data.triggers(m) == 1 && ...
       (behav_data.key_resp_corr(m) == 1 || behav_data.key_resp_after500_corr(m) == 1)
       trig_file_stim.type(m) =  0;
    end
     
     %if incorrect GO stim = 1
    if behav_data.triggers(m) == 1 && ...
       (behav_data.key_resp_corr(m) == 0 && behav_data.key_resp_after500_corr(m) == 0)
       trig_file_stim.type(m) =  1;
    end

     %if correct NOGO stim = 2
    if behav_data.triggers(m) == 2 && ...
       (behav_data.key_resp_corr(m) == 1 && behav_data.key_resp_after500_corr(m) == 1) 
       trig_file_stim.type(m) =  2;
    end
   
    %if incorrect NOGO stim = 0
    if behav_data.triggers(m) == 2 &&...
       (behav_data.key_resp_corr(m) == 0 || behav_data.key_resp_after500_corr(m) == 0)
       trig_file_stim.type(m) =  0;
    end

end

%% combine stim triggers with response triggers
new_trig = vertcat(new_trig_file, trig_file_stim);


%get only specific columns
final_trig = new_trig(:,[2,3,8]);

%remove 0s
final_trig((final_trig.type(:,1) == 0), :) = [];

%reorder
final_trig = sortrows(final_trig,1); 

%get length of final_trig and participant number to check
subnum
height(final_trig)

%apply filter to remove trials that are too fast, for new pipeline only
%final_trig_filtered = final_trig(trialsToKeep,:);

%save new event file
filename = [data_path num2str(subnum) '/eventnew.txt'];
%writetable(final_trig_filtered ,filename,'Delimiter','\t');
writetable(final_trig ,filename,'Delimiter','\t');

end
