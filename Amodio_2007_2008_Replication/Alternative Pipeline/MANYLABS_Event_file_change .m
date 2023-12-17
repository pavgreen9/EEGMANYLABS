% read in each EEG file, export event per participant
% need to read in behavioural files too 
% change event file such that new trigger labels are assigned for correct
% and incorrect trials 
% stimulus (go and no-go) are labelled
% reimport event file per subject

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

addpath '/home/pavgreen/Documents/LRGS/EEG/eeglab2022.1';
eeglab;

for i = 1:length(files)   
    subnum = files(i).name; %get names of each subject's folder
    
    %load in data
    EEG = pop_loadbv([data_path num2str(subnum)], [ num2str(subnum) '.vhdr'], [], [1:29]);
    %export events
    pop_expevents(EEG, [data_path num2str(subnum) '/event.txt'], 'samples');
    
    %% cleaning behavioural
    %import gng behavioural file 
    behav_file = dir([data_path num2str(subnum) '/' num2str(subnum) '.csv']);
    behav_data = readtable ([data_path num2str(subnum) '/' behav_file.name]);
    behav_data(isnan(behav_data.triggers), :) = [];
    
    %index out trials that are too fast (<150ms), make them 0
    trialsToKeep = behav_data.key_resp_rt >= 0.150 | isnan(behav_data.key_resp_rt);
    trialsToThrow = find(trialsToKeep == 0);
    trialsfast = trialsToThrow;
    triggersfast = behav_data.triggers(trialsfast);

    trialsfast = horzcat(trialsfast, triggersfast);
    trialsfast = table(trialsfast);

    %record the trials too fast
    writetable(trialsfast, [data_path num2str(subnum) '/throw.csv'])

    %% cleaning triggers
    %import events
    trig_file= readtable ([data_path num2str(subnum) '/event.txt']);
    
    %remove unecessary triggers
    trig_file= trig_file(ismember(trig_file.type,[1, 2, 3, 4]),:);

    % select relevant columns
    trig_file_raw = trig_file(:,[2,3,8]);
    trig_file_rem = trig_file(:, [2, 3, 8]);
    trig_file = trig_file(:,[2,3,8]);

    % Remove triggers that are duplicates which are too close 
    trig_rem = [];

    for ind = 1:height(trig_file)-1
        if (trig_file.type(ind+1) == trig_file.type(ind)) && (trig_file.latency(ind+1) - trig_file.latency(ind) < 99)
            trig_rem = vertcat([trig_rem ind+1]);
        end
    end

    trig_file(trig_rem, :) = [];
    trig_file_rem(trig_rem, :) =  [];

    % Identify standalone response triggers
    trig_stand = [];

    %% change trig numbers to reflect incorrect go and correct no-go stim
    
    %original triggers 
    %1 - Go-stimulus
    %2 - No-go stimulus
    %3 - Correct go response
    %4 - Incorrect no-go response
    
    %what I want
    %1 - Incorrect Go Stimulus
    %2 - Correct No-Go Stimulus
    %3 - Correct Go Response
    %4 - Incorrect No-Go Response
    %everything else = 0 

    comp = cell2table(cell(0,1));
    comp.Properties.VariableNames{'Var1'}='type';
    note = [];
    half = [];
    
    %% parallel run
    for m = 1:height(behav_data)
    
        k = height(comp);

        note = vertcat([note, [m; k+1]]);

        % if there is a trial with a response too fast, both event and
        % response triggers will be removed
        if ismember(m, trialsToThrow) 
            comp.type(k+1) = 0;
            comp.type(k+2) = 0;

            trig_file.type(k+1) = 0;
            trig_file.type(k+2) = 0;

        % resp triggers that do not have the appropiate event triggers
        elseif trig_file.type(k+1) == 3 || trig_file.type(k+1) == 4
            comp.type(k+1) = 0;
            trig_file.type(k+1) = 0;

            trig_stand = [trig_stand k+1];

        % if the both behv and eeg reflect event trigger for Go
        elseif trig_file.type(k+1) == 1 && behav_data.triggers(m) == 1
                
            % if resp is timely, mark as appropriate 3
            if behav_data.key_resp_corr(m) == 1 && trig_file.type(k+2) == 3
                comp.type(k+1) = 0;             % change this to 0 for response lock
                trig_file.type(k+1) = 0; % change this to 0 for response lock
                
                comp.type(k+2) = 3; % change this to 3 for response lock
                trig_file.type(k+2) = 3; % change this to 3 for response lock
                
            % if resp is untimely, mark as late 5 - change for MANYLABS
            elseif behav_data.key_resp_after500_corr(m) == 1 && trig_file.type(k+2) == 3
                comp.type(k+1) = 0;
                trig_file.type(k+1) = 0;
                
                comp.type(k+2) = 3; %5
                trig_file.type(k+2) = 3; %5

            % if no resp
            elseif behav_data.key_resp_corr(m) == 0 && behav_data.key_resp_after500_corr(m) == 0
                comp.type(k+1) = 1;
                %eeg trig should already note a 1 only

            % theres a 1 and there should be a resp but trigger doesnt show
            else
                comp.type(k+1) = 0;
                trig_file.type(k+1) = 0;

                trig_stand = [trig_stand k+1];

            end


        % if the both behv and eeg reflect event trigger for noGo
        elseif trig_file.type(k+1) == 2 && behav_data.triggers(m) == 2
                
            % if no resp is made, mark only stimuli 2
            if behav_data.key_resp_corr(m) == 1 && behav_data.key_resp_after500_corr(m) == 1
                comp.type(k+1) = 2;
                %eeg trig should already reflect 2 only

            % if resp is made, mark wrong 4
            elseif (behav_data.key_resp_corr(m) == 0 || behav_data.key_resp_after500_corr(m) == 0) && (trig_file.type(k+2) == 4)
                comp.type(k+1) = 0; % change to 0 for response lock
                trig_file.type(k+1) = 0; % change to 0 for response lock

                comp.type(k+2) = 4; % change to 4 for response lock
                trig_file.type(k+2) = 4; % change to 4 for response lock

            % if trigger 2 but answer was wrong
            else 
                comp.type(k+1) = 0;
                trig_file.type(k+1) = 0;

                trig_stand = [trig_stand k+1];

            end

        else
            error("trigger did not catch trial")

        end

        % mark midpoint - not necessary but just something
        if m == 251
           trig_file.half(k+1) = 9;
           trig_file.half(k+2) = 9;
        end

    end

    % rename
    final_trig = trig_file;

    %remove 0s (Go with correct response) and 5s (Go with late response)
    final_trig= final_trig(ismember(final_trig.type,[1, 2, 3, 4, 5]),:);

    %% reorder
    final_trig = sortrows(final_trig,1); 
    
    %get length of final_trig and participant number to check
    subnum
    height(final_trig)
    
    %save new event file
    filename = [data_path num2str(subnum) '/eventnew.txt'];
    filename2 = [data_path num2str(subnum) '/eventnew.csv'];

    writetable(final_trig ,filename,'Delimiter','\t');
    writetable(final_trig ,filename2,'Delimiter',',');    

    % Check if the EEG trigger version is the same as the behavioural version
    % Check for differences if greather than 500 or less than 500
    if ~isequal(comp.type, trig_file.type)
        for x = 1:height(trig_file)
            if trig_file.type(x) ~= comp.type(x)
                error(["Check" subnum])

            end
        end
    end

end

%% comparison to check 
%{
data_alt = '/home/pavgreen/Documents/LRGS/EEG/alt/study/';
for i = 1:length(files)

     subnum = files(i).name

    t = pop_importevent( EEG, 'append','no','event',[data_path num2str(subnum) '/eventnew.txt'], ...
         'fields',{'latency','duration','type'},'skipline',1,'timeunit',NaN);

    tr = pop_importevent( EEG, 'append','no','event',[data_alt num2str(subnum) '/eventnew.txt'], ...
         'fields',{'latency','duration','type'},'skipline',1,'timeunit',NaN);

    if ~isequal(t, tr)
        error(["Check" ' ' subnum])
    end
end
%}
