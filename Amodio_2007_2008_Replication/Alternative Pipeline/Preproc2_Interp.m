clc;
clear;

%This script enables you to interpolate 'bad' channels before or after doing ICA

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

%% associated channels and numbers

% 1 = AF7
% 2 = Fpz
% 3 = F7
% 4 = Fz
% 5 = T7
% 6 = FC6
% 7 = Fp1
% 8 = F4
% 9 = C4
% 10 = Oz
% 11 = CP6
% 12 = Cz
% 13 = PO8
% 14 = CP5
% 15 = O2
% 16 = O1
% 17 = P3
% 18 = P4
% 19 = P7
% 20 = P8
% 21 = Pz
% 22 = PO7
% 23 = T8
% 24 = C3
% 25 = Fp2
% 26 = F3
% 27 = F8
% 28 = FC5
% 29 = AF8


%% Loops through each folder and plots the data to allow for checking channels. 
% The computer will then ask you for input for interpolation
%If the data looks okay without interpolation, just press enter without
%entering any input

%change the first number to start from the desired participant file if you have taken a break from interpolation and are coming back to it
for m = [25]%1:length(files)
    
    %get names of each subject's folder
    subnum = files(m).name; 

    interp_channels_before_ICA = {};

    %read in epoched file
    %change this from epoch file to comprem file if you want to do interpolation after ICA
    EEG = pop_loadset([data_path num2str(subnum) '/' num2str(subnum) ['_new_epoched_' type '.set'] ]);


    % while loop
    while true

        %plot data
        pop_eegplot( EEG, 1, 1, 1);

        %prompt for saving data
        answers2 = input('Save data? Press 1 for Yes or 2 for No:');

        if answers2 == 1

            %save which channels were interpolated as part of EEG struct
            EEG.interpChannelsBeforeICA = interp_channels_before_ICA;

            % Close all GUI
            h = findobj('Type', 'figure');        
            close(h);

            %save file
            EEG = pop_saveset( EEG, 'filename',[num2str(subnum) '_new_interp_' type '.set'], 'filepath',[data_path num2str(subnum)]);

            disp(['Saved participant' num2str(subnum)]);
            break;

        else 

            %plot spectra map, see if any channels deviate from the masses
            %click on line to determine which channel it is
            figure; pop_spectopo(EEG, 1, [-500  800], 'EEG' , 'freq', [6 10 22], 'freqrange',[2 25],'electrodes','off');
            pop_prop( EEG, 1, [4, 8, 26, 9, 12, 24, 17, 18, 21], NaN, {'freqrange',[2 50] })

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

            % add
            ind = length(interp_channels_before_ICA) + 1;
            interp_channels_before_ICA{ind} = chosen_channels;

        end

    end 

end


