%% for creating averaged plots of ERN and N2 waves
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

%ask user whether they want to read in ERN or N2 files
type = input('ERN or N2?', 's');
type = num2str(type);


%% remove participants that do not have enough events after removing epochs %%
for m = 1:length(files)

subnum = files(m).name; %get names of each subject's folder

EEG = pop_loadset([data_path num2str(subnum) '/A' num2str(subnum) '_' type '_clean.set' ]);

%256 - incorrect Go stim
%512 - Correct no-go stim (need at least 20 for N2)
%768 - Correct go response
%1024 - Incorrect no-go response (need at least 6 for ERN)

[C,ia,ic] = unique({EEG.event.type}');
trials = accumarray(ic,1);
epoch_counts = table(C, trials);

if strcmp(type, "ERN")
    %take only those with incorrect no-go responses of 6 or more
if epoch_counts.trials(2,:) >= 6
    filename_idx(m) = 1;
else 
    filename_idx(m) = 0;
end

elseif strcmp(type, "N2")
    %take only those with correct no-go responses of 20 or more
if epoch_counts.trials(2,:) >= 20
    filename_idx(m) = 1;
else 
    filename_idx(m) = 0;
end
end

end

%% index participant folders with enough trials
files = files(filename_idx');
%% loop over each participant and create separate .erp files

for i = 1:length(files)

subnum = files(i).name; %get names of each subject's folder

%read in either ERN or N2 files
EEG = pop_loadset([data_path num2str(subnum) '/A' num2str(subnum) '_' type '_clean.set' ]);

ERP = pop_averager( EEG , 'Criterion', 'good', 'DQ_custom_wins', 0, 'DQ_flag', 1, 'DQ_preavg_txt', 0, 'ExcludeBoundary', 'on', 'SEM',...
 'on' );
ERP = pop_savemyerp(ERP, 'erpname', ['A' num2str(subnum)], 'filename', ['A' num2str(subnum) '.erp'], 'filepath', [data_path '/forPlotting' type],...
 'Warning', 'on');

filenames{i,1} = [data_path 'forPlotting' type '/A' num2str(subnum) '.erp'];

end

%% combine each participant's ERP files and plot them  

%create .txt file with all participant file names

filenames = filenames(cellfun(@ischar,filenames)); %remove missing rows

writecell(filenames ,[data_path 'forPlotting' type '/filenames.txt']);


ERP = pop_gaverager( [data_path 'forPlotting' type '/filenames.txt'] , 'DQ_flag', 1 );
ERP = pop_savemyerp(ERP,...
 'erpname', 'all', 'filename', 'all.erp', 'filepath', [data_path 'forPlotting' type], 'Warning', 'on');

if strcmp(type, 'ERN')
%for ERN
ERP = pop_ploterps( ERP, [2 4],  [4] , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'Blc', 'pre', 'Box', [ 6 5], 'ChLabel', 'on', 'FontSizeChan',...
  10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-' }, 'LineWidth',  1, 'Maximize', 'on',...
 'Position', [ 103.714 22.4615 106.857 31.9231], 'Style', 'Classic', 'Tag', 'ERP_figure', 'Transparency',  0, 'xscale', [ -400.0 800   -400:200:400 ],...
 'YDir', 'normal' );

elseif strcmp(type, 'N2')
%for N2
 ERP = pop_ploterps( ERP, [2 3],  [12] , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'Blc', 'pre', 'Box', [ 6 5], 'ChLabel', 'on', 'FontSizeChan',...
   10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-' }, 'LineWidth',  1, 'Maximize', 'on',...
  'Position', [ 103.714 22.4615 106.857 31.9231], 'Style', 'Classic', 'Tag', 'ERP_figure', 'Transparency',  0, 'xscale', [ -200.0 800.0   -200:200:800 ],...
  'YDir', 'normal' );

end
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

% %for ERN
%ERP = pop_ploterps('C:\Users\aleya\Documents\EEGdataLRGS_folders\DataforERN\forPlotting\all_filt.erp', [ 2 4],  [4 12] , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'Blc', 'pre', 'Box', [ 6 5], 'ChLabel', 'on', 'FontSizeChan',...
 % 10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-' }, 'LineWidth',  1, 'Maximize', 'on',...
 %'Position', [ 103.714 22.4615 106.857 31.9231], 'Style', 'Classic', 'Tag', 'ERP_figure', 'Transparency',  0, 'xscale', [ -200.0 800   -200:200:800 ],...
 %'YDir', 'normal' );

% %for N2
% ERP = pop_ploterps('C:\Users\aleya\Documents\EEGdataLRGS_folders\forPlotting\all.erp',[ 2 3],  [2 4 12] , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'Blc', 'pre', 'Box', [ 6 5], 'ChLabel', 'on', 'FontSizeChan',...
%   10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-' }, 'LineWidth',  1, 'Maximize', 'on',...
%  'Position', [ 103.714 22.4615 106.857 31.9231], 'Style', 'Classic', 'Tag', 'ERP_figure', 'Transparency',  0, 'xscale', [ -200.0 1000.0   -200:200:1000 ],...
%  'YDir', 'normal' );