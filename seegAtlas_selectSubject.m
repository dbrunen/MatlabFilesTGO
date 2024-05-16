% this function selects subject and optionally which EEG files

% INPUT: 
% myDataPath.proj_dirinput  - directory folder where the subject folders are located
% varargin{1}               - 'EEG'/'Subject' --> selects 1 EEG or all EEGs
%                             from a specific subject

% OUTPUT:
% cfg   - cfg.sub_label = subject label (string)
%       - cfg.eeg_label = eeg label (string in cell)

% Copyright (C) 2022 Dorien van Blooijs, SEIN Zwolle, the Netherlands


function cfg = seegAtlas_selectSubject(myDataPath,varargin)

cfg = [];

% SELECT SUBJECT
cfg.sub_label = input('Subject number in Micromed folder [PAT_X]: ','s');

if ~exist(fullfile(myDataPath(1).proj_dirinput,cfg.sub_label),'dir')
    error('Folder %s does not exist.',...
        fullfile(myDataPath(1).proj_dirinput,cfg.sub_label))
end

% SELECT EEG-FILE(S)
patfiles = dir(fullfile(myDataPath(1).proj_dirinput,cfg.sub_label));
idx_eegfiles = contains({patfiles(:).name},'trc','IgnoreCase',	true);
eegfiles = {patfiles(idx_eegfiles).name};

if strcmp(varargin{1},'EEG')
    eegstring = [repmat('%s, ',1,size(eegfiles,2)-1),'%s'];

    eeg_label = input(sprintf(['EEG file, choose from ',eegstring, ': \n'],...
        eegfiles{:}),'s');

    cfg.eeg_label = {eeg_label};

elseif strcmp(varargin{1},'Subject')
    cfg.eeg_label = eegfiles;
end

end