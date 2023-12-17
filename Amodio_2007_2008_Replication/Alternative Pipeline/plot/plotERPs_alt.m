%% for creating averaged plots of ERN and N2 waves
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

%% change the timings to whatever is appropriate
cd(data_path)
SME = load("SME.mat");

addpath '/home/pavgreen/Documents/LRGS/EEG/eeglab2023.0';
eeglab;

%type = input('P3, ERN or N2?' ,'s');
type = 'P3';

%% remove participants that do not have enough events after removing epochs %%
for m = 1:length(files)

    subnum = files(m).name; %get names of each subject's folder
    
    EEG = pop_loadset([data_path num2str(subnum) '/' num2str(subnum) 'comprem' type '.set']);
    
    %1- incorrect Go stim
    %2 - Correct no-go stim (need at least 20 for N2)
    %3 - Correct go response
    %4 - Incorrect no-go response (need at least 6 for ERN)

    for i = 1:numel(EEG.event)
        if isnumeric(EEG.event(i).type)
            EEG.event(i).type = num2str(EEG.event(i).type);
        end
    end
    
    [C,ia,ic] = unique({EEG.event.type}');
    trials = accumarray(ic,1);
    epoch_counts = table(C, trials);

    if strcmp(type, "P3") || strcmp(type, "N2")
            %take only those with correct no-go responses of 20 or more
        if (epoch_counts.trials(find(strcmp(epoch_counts.C, '2')),:) >=20)  
            filename_idx(m) = 1;
        else 
            filename_idx(m) = 0;
            warning("Not enough P3 or N2")
            disp(subnum)
            epoch_counts.trials(find(strcmp(epoch_counts.C, '2')),:)
        end
    
    elseif strcmp(type, "ERN")
            %take only those with incorrect no-go responses of 6 or more
        if epoch_counts.trials(find(strcmp(epoch_counts.C, 'B4(4)')),:) >=6
            filename_idx(m) = 1;
        else 
            filename_idx(m) = 0;
            error("Not enough ERN")
        end
    
    end

end

% index participant folders with enough trials
files = files(logical(filename_idx));


%create directory where ERP sets will go
mkdir ([data_path 'forPlotting' type]);

%% loop over each participant and create separate .erp files

ID = [];
Int1 = [];
CompRem = [];
Int2 = [];

GP3 = [];
nGP3 = [];
dP3 = [];
GP3SME = [];
nGP3SME = [];

GN2 = [];
nGN2 = [];
dN2 = [];
GN2SME = [];
nGN2SME = [];

for i = 1:length(files)

    subnum = files(i).name; %get names of each subject's folder
    
    %read in either ERN or N2 files
    EEG = pop_loadset([data_path num2str(subnum) '/' num2str(subnum) 'comprem' type '.set']);

    ID = [ID; string(subnum)];

    %Int1 = [Int1; {EEG.interpChannelsBeforeICA}];

    %CompRem = [CompRem; {EEG.CompRemoved}];

    %Int2 = [Int2; {EEG.interpChannelsAfterICA}];

    %IAICA = EEG.interpChannelsAfterICA;

    ERP = pop_averager(EEG , 'Criterion', 'good', 'DQ_flag', 1, 'SEM', 'on', 'DQ_spec', SME.spec);

    %% change the timings here 
    GP3times = find(ERP.times == 400):find(ERP.times == 500);
    nGP3times = find(ERP.times == 400):find(ERP.times == 500);
    GN2times = find(ERP.times == 250):find(ERP.times == 350);
    nGN2times = find(ERP.times == 250):find(ERP.times == 350);

    % uncomment and change timings
    %GERNtimes = find(ERP.times == -50):find(ERP.times == 150);
    %nGERNtimes = find(ERP.times == -50):find(ERP.times == 150);

    ERP.GP3 = mean(ERP.bindata(12, GP3times, 3));
    GP3 = [GP3; ERP.GP3];
    GP3SME = [GP3SME; ERP.dataquality(3).data(12, 1, 3)];

    ERP.nGP3 = mean(ERP.bindata(12, nGP3times, 2));
    nGP3 = [nGP3; ERP.nGP3];
    nGP3SME = [nGP3SME; ERP.dataquality(3).data(12, 2, 2)];

    ERP.dP3 = ERP.nGP3 - ERP.GP3;
    dP3 = [dP3; ERP.dP3];

    ERP.GN2 = mean(ERP.bindata(12, GN2times, 3));
    GN2 = [GN2; ERP.GN2];
    GN2SME = [GN2SME; ERP.dataquality(3).data(12, 3, 3)];

    ERP.nGN2 = mean(ERP.bindata(12, nGN2times, 2));
    nGN2 = [nGN2; ERP.nGN2];
    nGN2SME = [nGN2SME; ERP.dataquality(3).data(12, 3, 2)];

    ERP.dN2 = ERP.nGN2 - ERP.GN2;
    dN2 = [dN2; ERP.dN2];

    %ERP.GERN = mean(ERP.bindata(12, GERNtimes, 3));
    %GERN = [GERN; ERP.GERN];
    %GERNSME = [GERNSME; ERP.dataquality(3).data(12, 4, 3)];

    %ERP.nGERN = mean(ERP.bindata(12, nGERNtimes, 4));
    %nGERN = [nGERN; ERP.nGERN];
    %nGERNSME = [nGERNSME; ERP.dataquality(3).data(12, 4, 4)];

    %ERP.dERN = ERP.nGERN - ERP.GERN;
    %dERN = [dERN; ERP.dERN];

    ERP = pop_savemyerp(ERP, 'erpname', [num2str(subnum)], 'filename', [num2str(subnum) '.erp'], 'filepath', [data_path '/forPlotting' type],...
     'Warning', 'on');

    %% uncomment this if you want plot for each participant
    %pop_ploterps( ERP, [2, 3],  [12] , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'Blc', 'pre', 'Box', [ 6 5], 'ChLabel', 'on', 'FontSizeChan',...
    %   10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-' }, 'LineWidth',  1, 'Maximize', 'on',...
    %  'Position', [ 103.714 22.4615 106.857 31.9231], 'Style', 'Classic', 'Tag', 'ERP_figure', 'Transparency',  0, 'xscale', [ -250.0 600.0   -250:100:600 ],...
    %  'YDir', 'normal' );
    
    filenames{i,1} = [data_path 'forPlotting' type '/' num2str(subnum) '.erp'];

end

head = {'ID', 'nGP3', 'nGP3SME', 'GP3', 'GP3SME', 'dP3', 'nGN2', 'nGN2SME', 'GN2', 'GN2SME', 'dN2'};
fin = horzcat(ID, nGP3, nGP3SME, GP3, GP3SME, dP3, nGN2, nGN2SME, GN2, GN2SME, dN2);
fin = vertcat(head, fin);

filename = [data_path '/erp.csv'];
writematrix(fin ,filename,'Delimiter',','); 

%% combine each participant's ERP files and plot them  

%create .txt file with all participant file names

filenames = filenames(cellfun(@ischar,filenames)); %remove missing rows

writecell(filenames ,[data_path 'forPlotting' type '/filenames.txt']);

ERP = pop_gaverager( [data_path 'forPlotting' type '/filenames.txt'] , 'DQ_flag', 1 );
ERP = pop_savemyerp(ERP,...
 'erpname', 'all', 'filename', 'all.erp', 'filepath', [data_path 'forPlotting' type], 'Warning', 'on');

if strcmp(type, 'P3') 
    %for P3
     ERP = pop_ploterps( ERP, [2, 3],  [12] , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'Blc', 'pre', 'Box', [ 6 5], 'ChLabel', 'on', 'FontSizeChan',...
       10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-' }, 'LineWidth',  1, 'Maximize', 'on',...
      'Position', [ 103.714 22.4615 106.857 31.9231], 'Style', 'Classic', 'Tag', 'ERP_figure', 'Transparency',  0, 'xscale', [ -250.0 600.0   -250:100:600 ],...
      'YDir', 'normal' );

elseif strcmp(type, 'ERN')
    %for ERN
    ERP = pop_ploterps( ERP, [2 4],  [12] , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'Blc', 'pre', 'Box', [ 6 5], 'ChLabel', 'on', 'FontSizeChan',...
      10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-' }, 'LineWidth',  1, 'Maximize', 'on',...
     'Position', [ 103.714 22.4615 106.857 31.9231], 'Style', 'Classic', 'Tag', 'ERP_figure', 'Transparency',  0, 'xscale', [ -400.0 400   -400:200:400 ],...
     'YDir', 'normal' );
    
elseif strcmp(type, 'N2')
    %for N2
     ERP = pop_ploterps( ERP, [2 3],  [12] , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'Blc', 'pre', 'Box', [ 6 5], 'ChLabel', 'on', 'FontSizeChan',...
       10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-' }, 'LineWidth',  1, 'Maximize', 'on',...
      'Position', [ 103.714 22.4615 106.857 31.9231], 'Style', ['Clas' ...
      'sic'], 'Tag', 'ERP_figure', 'Transparency',  0, 'xscale', [ -200.0 800.0   -200:200:800 ],...
      'YDir', 'normal' );

end