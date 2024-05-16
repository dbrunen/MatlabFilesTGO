%% DESCRIPTION OF THIS CODE
% This script automatically defines run and session for each EEG-file and 
% writes this back into the trc-file. --> TRC file is een trace file
% afkomstig uit een database

% Dorien van Blooijs, SEIN Zwolle 2023

%% SET PATHS
clear 
close all
clc %Clear command window

% add current path
rootPath = matlab.desktop.editor.getActiveFilename; % --> Deze regel haalt het volledige pad op naar het bestand dat actief is in de matlab editor. Dit pad wordt opgeslagen onder de variabele "rootpath"
RepoPath = fileparts(rootPath); % -->De "fileparts" functie splitst het pad naar het bestand op in drie delen: Het pad naar de map, de bestandsnaam zonder extensie en met extensie. Het pad naar de map wordt opgeslagen in de variabele "repopath"
matlabFolder = strfind(RepoPath,'matlab'); % --> Deze regel zoekt naar het woord 'matlab' in het pad
addpath(genpath(RepoPath(1:matlabFolder+6))); % Deze regel voegt het pad naar de map waarin 'matlab' is gevonden toe aan de MATLAB zoekpaden. genpath wordt gebruikt om alle submappen toe te voegen.

% set other paths
myDataPath = seegAtlas_setLocalDataPath(1); % -> Function, zie seeg_setLocalDataPath.m

% housekeeping
clear matlabFolder RepoPath rootPath % -> Na het uitvoeren van dit commando zullen de variabelen niet meer beschikbaar zijn in de Matlabsessie en wordt het geheugen opgeruimd, vandaar housekeeping.

%% SELECT PATIENT AND EEG-FILE

% modus = 'EEG'/'Subject' --> selects 1 EEG or all EEGs from a specific subject
modus = 'EEG'; % select one EEG of a specific subject

cfg = seegAtlas_selectSubject(myDataPath,modus); % --> aanroepen functie met argumenten myDataPath en modus. Volgens mij is modus de EEG

%% EXTRACT NOTES AND COMBINE ALL ANNOTATIONS FOR EACH TRC-FILE

for nEEG = 1:size(cfg.eeg_label,2) % Grootte 2e dimensie

    fileName = fullfile(myDataPath(1).proj_dirinput,cfg.sub_label,cfg.eeg_label{nEEG}); % --> deze reegel creeert een invoermap

    % obtain information from the header of the trc-file
    [header,data,data_time,trigger] = read_TRC_HDR_DATA_TRIGS_ANNOTS(fileName);

    fs = header.Rate_Min;

    %% EXTRACT NOTES

    [annotationsTRC, note_offset] = extractNotesTRC(fileName);

    %% CONVERT NOTES TO STRUCT

    nCount = 1;
    tb = struct();

    for nNote = 1:size(annotationsTRC,1)
            
            time = annotationsTRC{nNote,1}/fs;
            recDate = datetime([header.recyear header.recmonth header.recday header.hour header.min header.sec],'Format','dd-MMM-uuuu HH:mm:ss.SSS');
            noteDate = recDate + seconds(time);

            tb(nCount).recDate = recDate;
            tb(nCount).sample = annotationsTRC{nNote,1};
            tb(nCount).origAnnotation = annotationsTRC{nNote,2};
            tb(nCount).date = datestr(noteDate,'dd-mmm-yyyy HH:MM:SS.FFF');
            tb(nCount).timeEEG = time;

            nCount = nCount + 1;
    end

    disp(struct2table(tb))

    %% WRITE TABLE TO EXCEL

    subLabel = header.name;
    eegDate = datestr(recDate,'yyyy_mm_dd_HH_MM_SS');
    outputFileName = fullfile(myDataPath.proj_diroutput,...
        [subLabel,'_',eegDate,'.xlsx']);
   
    saveTB = input(sprintf('Wil je de annotaties opslaan in \n%s? [y/n] : ',replace(outputFileName,'\','/')),'s');

    if strcmpi(saveTB,'y')

        writetable(struct2table(tb),outputFileName,"WriteRowNames",true)

        fprintf('Annotations are saved in %s.\n',outputFileName)
    else
        warning('Annotations are not saved!')
    end

end