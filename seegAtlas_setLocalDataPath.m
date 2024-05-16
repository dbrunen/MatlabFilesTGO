function myDataPath = seegAtlas_setLocalDataPath(varargin)
% function LocalDataPath = setLocalDataPath(varargin)
% Return the path to the root directory and add paths in this repo
%
% input:
%   personalDataPath: optional, set to 1 if adding personalDataPath
%
% when adding personalDataPath, the following function should be in the
% root of this repo:
%
% function localDataPath = personalDataPath()
%     'localDataPath = [/my/path/to/data];
%
% dvanblooijs, 2020, University Medical Center Utrecht, the Netherlands &
%                    SEIN Zwolle, the Netherlands

if isempty(varargin)
    rootPath = which('setLocalDataPath');
    RepoPath = fileparts(rootPath);
    
    % add path to functions
    addpath(genpath(RepoPath));
    
    % add localDataPath default
    myDataPath = fullfile(RepoPath,'data');
    
elseif ~isempty(varargin)
   
    % add path to data

    if varargin{1}==1 && exist('seegAtlas_personalDataPath','file')

        myDataPath = seegAtlas_personalDataPath(varargin{1});

    elseif varargin{1}==1 && ~exist('seegAtlas_personalDataPath','file')

        sprintf(['add seegAtlas_personalDataPath function to add your localDataPath:\n'...
            '\n'...
            'function localDataPath = seegAtlas_personalDataPath()\n'...
            'myDataPath(1).proj_dirinput = [/my/path/to/data];\n'...
            'myDataPath(1).proj_diroutput = [/my/path/to/output];\n'...
            '\n'...
            'this function is ignored in .gitignore'])
        return
    end
    
end

return

