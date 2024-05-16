%% display electrode seeg
% This script displays the electrodes from excel-file

% Dorien van Blooijs, SEIN Zwolle 2024

%% SET PATHS
clear 
close all
clc

% add current path
rootPath = matlab.desktop.editor.getActiveFilename;
RepoPath = fileparts(rootPath);
matlabFolder = strfind(RepoPath,'matlab');
addpath(genpath(RepoPath(1:matlabFolder+6)));

% set other paths
myDataPath = seegAtlas_setLocalDataPath(1);

% housekeeping
clear matlabFolder RepoPath rootPath

%% patient characteristics
cfg.sub_label = ['sub-' input('Patient number (RESPXXXX): ','s')];
cfg.ses_label = input('Session number (ses-X): ','s');

%% load electrodes.tsv

  elecsName = fullfile(myDataPath(2).proj_dirinput,cfg.sub_label,cfg.ses_label,'ieeg',...
      [cfg.sub_label,'_',cfg.ses_label,'_electrodes.tsv']);
        
  % remove electrodes named 'other' (so no grid, depth,strip)
  tb_electrodes = readtable(elecsName,'FileType','text','Delimiter','\t');
  idx_elec_incl = ~strcmp(tb_electrodes.group,'other');
  tb_electrodes = tb_electrodes(idx_elec_incl,:);

  ch = tb_electrodes.name;
        
%% load electrodes positions (xlsx/electrodes.tsv)

folderName = myDataPath.elec_xlsx;
subj = cfg.sub_label(5:end);

if exist(fullfile(folderName,[subj,'_',cfg.ses_label,'_elektroden.xlsx']),'file')
    elec = readcell(fullfile(folderName,[subj,'_',cfg.ses_label,'_elektroden.xlsx']),'Sheet','matlabsjabloon','Range',[1 1 100 100]);
elseif exist(fullfile(folderName,[subj,'_',cfg.ses_label,'_elektroden.xls']),'file')
    elec = readcell(fullfile(folderName,[subj,'_',cfg.ses_label,'_elektroden.xls']),'Sheet','matlabsjabloon','Range',[1 1 100 100]);
else
    error('Elec file %s cannot be loaded',fullfile(folderName,[subj,'_',cfg.ses_label,'_elektroden.xls']))
end

% localize electrodes in grid
x = NaN(size(tb_electrodes,1),1); y = NaN(size(tb_electrodes,1),1);elecmat = NaN(size(elec));topo=struct;
for nRow = 1:size(elec,1)
    for nCol = 1:size(elec,2)
        if ~ismissing(elec{nRow,nCol})
            letter = regexp(elec{nRow,nCol},'[a-z,A-Z]');
            number = regexp(elec{nRow,nCol},'[1-9]');
            test1 = elec{nRow,nCol}([letter,number:end]);
            test2 = [elec{nRow,nCol}(letter),'0',elec{nRow,nCol}(number:end)];
            if sum(strcmp(ch,test1))==1
                elecmat(nRow,nCol) = find(strcmp(ch,test1));
                y(strcmp(ch,test1),1) = nRow;
                x(strcmp(ch,test1),1)= nCol;
            elseif sum(strcmp(ch,test2))==1
                elecmat(nRow,nCol) = find(strcmp(ch,test2));
                y(strcmp(ch,test2),1) = nRow;
                x(strcmp(ch,test2),1)= nCol;
            else
                error('Electrode %s or %s is not found',test1,test2)
            end
        end
    end
end

topo.x =x;
topo.y = y;


%% display electrode grid

figure(1),
% plot all electrodes
plot(topo.x,topo.y,'ok','MarkerSize',15)

% add electrode names
text(topo.x,topo.y,ch)

ax = gca;
xlim([min(topo.x)-2, max(topo.x)+2])
ylim([min(topo.y)-2, max(topo.y)+2])

ax.YDir = 'reverse';
ax.YTick = [];
ax.XTick = [];
ax.XColor = 'none';
ax.YColor = 'none';
ax.Units = 'normalized';
ax.Position = [0.1 0.1 0.8 0.8];

fig1 = gcf;
fig1.Units = 'normalized';
fig1.Position = [0.1 0.4 0.8 0.4];

%%
% TODO: nog aanpassen zodat het werkt
%% load stimulation notes
% voor nu even importeren via slepen in workspace as string array

notes = [stimnotes;stimnotes1];

% vind echte stimnotes
TPstimnotes = contains(notes,'sec');
stimnotes = notes(TPstimnotes);

stims = [];
for i=1:length(stimnotes)
    dash = strfind(stimnotes(i),'-');
    whites = regexp(stimnotes(i),'\s'); % find white space characters
    [minDist, iMin] = min(abs(whites-dash)); %find closest white space to dash
    
    %de stimchannels staan voor dash en na dash, tussen white spaces
    c1(i) = extractBetween(stimnotes(i),whites(iMin)+1,dash-1);
    if length(regexp(c1(i),'\d'))>2 || any(regexp(c1(i),'\d\D'))%remove strange symbols
        remove = max(regexp(c1(i),'\w')); % remove the last character
        c1(i) = extractBetween(c1(i),1,remove-1); 
    end
    c2(i) = extractBetween(stimnotes(i),dash+1,whites(iMin+1)-1);
    if length(regexp(c2(i),'\d'))>2 || any(regexp(c2(i),'\d\D'))%remove strange symbols
        remove = max(regexp(c2(i),'\w')); % remove the last character
        c2(i) = extractBetween(c2(i),1,remove-1); 
    end
    
    mA = strfind(stimnotes(i),'mA');
    c3(i) = extractBetween(stimnotes(i),mA-3,mA-1);
       
    clear dash whites mA remove
end

TB = table(c1', c2', c3');
stims = [c1',c2',c3'];

%% match stims with channel names

%remove doubles
[~,idx]=unique(TB,'rows');
Ustims =  stims(idx,:);
UTB = TB(idx,1:2);

%find used stim currents
c = unique(stims(:,3));

%collaps stim currents
[sc,ia,ic] = unique(UTB,'rows');
UAstims = Ustims(ia,1:2);

%match stims with channel names
stimchan = [];
for i=1:length(UAstims)
    tf1 = strncmp(chn,UAstims{i,1},strlength(UAstims{i,1}));
    chann1 = find(tf1==1);
    tf2 = strncmp(chn,UAstims{i,2},strlength(UAstims{i,2}));
    chann2 = find(tf2==1);

    if length(chann1)>1 || length(chann2)>1 % als label meer dan 1 keer herkend wordt, bijv C1 en C10
    display(['Error in channel recognition, check stimpair ' num2str(i) UAstims{i,1} UAstims{i,2}]);
    if length(chann1)>1 %vind de value van chann1 die het dichtst bij chann2 ligt
        [minCD, iMinD] = min(abs(chann1-chann2)); %find index closest to chann1
        chann1 = chann1(iMinD);
    elseif length(chann2)>1
        [minCD, iMinD] = min(abs(chann2-chann1)); %find index closest to chann2
        chann2 = chann2(iMinD);
%         [~,ch] = min([abs(chann2(1)-chann1),abs(chann2(2)-chann1)]);
%         chann2 = chann2(ch);
    end
    end
    
    stimchan(i,1:2) = [chann1 chann2];
    
    %number of stims per stimchan
    stimchan(i,3) = sum(ic == i);
end

%% draw lines

for st=1:length(stimchan)
    
    if stimchan(st,3)==1
        plot(topo.x(stimchan(st,1:2)),topo.y(stimchan(st,1:2)),'k');
    elseif stimchan(st,3)==2
        if topo.y(stimchan(st,1)) == topo.y(stimchan(st,2))%horizontal
            yspread = [(topo.y(stimchan(st,1))-0.15) (topo.y(stimchan(st,1))+0.15)];
            plot(topo.x(stimchan(st,1:2)),[yspread(1) yspread(1)],'k');
            plot(topo.x(stimchan(st,1:2)),[yspread(2) yspread(2)],'k');
        else %vertical
            xspread = [(topo.x(stimchan(st,1))-0.15) (topo.x(stimchan(st,1))+0.15)];
            plot([xspread(1) xspread(1)],topo.y(stimchan(st,1:2)),'k');
            plot([xspread(2) xspread(2)],topo.y(stimchan(st,1:2)),'k');
        end
    elseif stimchan(st,3)==3
        if topo.y(stimchan(st,1)) == topo.y(stimchan(st,2))%horizontal
            yspread = [(topo.y(stimchan(st,1))-0.15) topo.y(stimchan(st,1)) (topo.y(stimchan(st,1))+0.15)];
            plot(topo.x(stimchan(st,1:2)),[yspread(1) yspread(1)],'k');
            plot(topo.x(stimchan(st,1:2)),[yspread(2) yspread(2)],'k');
            plot(topo.x(stimchan(st,1:2)),[yspread(3) yspread(3)],'k');
        else %vertical
            xspread = [(topo.x(stimchan(st,1))-0.15) topo.x(stimchan(st,1)) (topo.x(stimchan(st,1))+0.15)];
            plot([xspread(1) xspread(1)],topo.y(stimchan(st,1:2)),'k');
            plot([xspread(2) xspread(2)],topo.y(stimchan(st,1:2)),'k');
            plot([xspread(3) xspread(3)],topo.y(stimchan(st,1:2)),'k');
        end
     elseif stimchan(st,3)>3
        if topo.y(stimchan(st,1)) == topo.y(stimchan(st,2))%horizontal
            yspread = [(topo.y(stimchan(st,1))-0.2) (topo.y(stimchan(st,1))-0.05) (topo.y(stimchan(st,1))+0.05) (topo.y(stimchan(st,1))+0.2)];
            plot(topo.x(stimchan(st,1:2)),[yspread(1) yspread(1)],'k');
            plot(topo.x(stimchan(st,1:2)),[yspread(2) yspread(2)],'k');
            plot(topo.x(stimchan(st,1:2)),[yspread(3) yspread(3)],'k');
            plot(topo.x(stimchan(st,1:2)),[yspread(4) yspread(4)],'k');
        else %vertical
            xspread = [(topo.x(stimchan(st,1))-0.2) (topo.x(stimchan(st,1))-0.05) (topo.x(stimchan(st,1))+0.05) (topo.x(stimchan(st,1))+0.2)];
            plot([xspread(1) xspread(1)],topo.y(stimchan(st,1:2)),'k');
            plot([xspread(2) xspread(2)],topo.y(stimchan(st,1:2)),'k');
            plot([xspread(3) xspread(3)],topo.y(stimchan(st,1:2)),'k');
            plot([xspread(4) xspread(4)],topo.y(stimchan(st,1:2)),'k');
        end
    end
end
