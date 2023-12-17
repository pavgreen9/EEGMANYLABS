%calculate mean and peak ERN/N2 per participant and save to respective .txt
%file
clc;
clear;

%ask user whether they want to interpolate ERN or N2 files
%type = input('P3, ERN or N2?' ,'s');
type = 'P3';

data_path = ['/home/pavgreen/Documents/LRGS/EEG/alt/study/forPlotting' type '/'];
cd(data_path);

addpath '/home/pavgreen/Documents/LRGS/EEG/eeglab2023.0';
eeglab;

%get foldernames
files1 = dir([data_path '*.erp']);
matches = regexp({files1.name}, {'^\d+'});
bool = cellfun(@(x) any(x), matches);
files = files1(bool);

for i = 1:length(files) 
 
    ERP = pop_loaderp('filename', [files(i).name], 'filepath', [data_path]);
 
    if strcmp(type, 'ERN')
        % for peak ERN
        ERP = pop_geterpvalues( ERP, [-50 150], 4,12 , 'Baseline', [-400 -50], 'FileFormat', 'wide',...
            'Filename', 'ERN_peak.txt', 'Append', 'on', 'Fracreplace', 'NaN', 'InterpFactor',1, 'Measure', 'peakampbl',...
            'Neighborhood',5, 'PeakOnset',1, 'Peakpolarity', 'negative', 'Peakreplace', 'absolute',...
            'Resolution',3, 'SendtoWorkspace', 'on' );   
        
        % for mean ERN
        ERP = pop_geterpvalues( ERP, [-50 150], 4,12 , 'Baseline', [-400 -50], 'FileFormat', 'wide',...
            'Filename', 'ERN_mean.txt', 'Append', 'on', 'Fracreplace', 'NaN', 'InterpFactor',1, 'Measure', 'meanbl',...
            'Neighborhood',5, 'Resolution',3, 'SendtoWorkspace', 'on' );   
        
        % for delta ERN
        
        %get difference waveform between Correct trials and Incorrect trials
        ERP = pop_binoperator( ERP, {  'b5 = b3 - b1 label Correct Go - Incorrect NoGo'});
        
        %for mean delta ERN
        ERP = pop_geterpvalues( ERP, [-50 150], 5,12 , 'Baseline', [-400 -50], 'FileFormat', 'wide',...
            'Filename', 'ERN_delta_mean.txt', 'Append', 'on', 'Fracreplace', 'NaN', 'InterpFactor',1, 'Measure', 'meanbl',...
            'Neighborhood',5, 'Resolution',3, 'SendtoWorkspace', 'on' );   
        
        %for peak delta ERN
        ERP = pop_geterpvalues( ERP, [-50 150], 5,12 , 'Baseline', [-400 -50], 'FileFormat', 'wide',...
            'Filename', 'ERN_peak.txt', 'Append', 'on', 'Fracreplace', 'NaN', 'InterpFactor',1, 'Measure', 'peakampbl',...
            'Neighborhood',5, 'PeakOnset',1, 'Peakpolarity', 'negative', 'Peakreplace', 'absolute',...
            'Resolution',3, 'SendtoWorkspace', 'on' ); 
            
    
    elseif strcmp(type, 'N2')
        % for peak N2
        ERP = pop_geterpvalues( ERP, [200 400], 2,12 , 'Baseline', [100 200], 'FileFormat', 'wide',...
            'Filename', 'N2_peak.txt', 'Append', 'on', 'Fracreplace', 'NaN', 'InterpFactor',1, 'Measure', 'peakampbl',...
            'Neighborhood',5, 'PeakOnset',1, 'Peakpolarity', 'negative', 'Peakreplace', 'absolute',...
            'Resolution',3, 'SendtoWorkspace', 'on' );  
        
        % for mean N2
        ERP = pop_geterpvalues( ERP, [200 400], 2,12 , 'Baseline', [100 200], 'FileFormat', 'wide',...
            'Filename', 'N2_mean.txt', 'Append', 'on', 'Fracreplace', 'NaN', 'InterpFactor',1, 'Measure', 'meanbl',...
            'Neighborhood',5, 'Resolution',3, 'SendtoWorkspace', 'on' );   

    end
end 

