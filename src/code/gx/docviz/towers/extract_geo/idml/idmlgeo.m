function idmlgeo(showViz, url, saveViz, saveFile)
%IDMLGEO Reads various data from InDesign IDML files
% 
% This is a batch wrapper for idmlgeo_wrapper.m. Check it out details.
% 
% -------------
% INPUT
% -------------
% showViz {'show'} | 'noshow' - show the visualizations
% url - URL of directory containing IDML files
%     1. single file mode: directory contains a single IDML
%     2. batch mode: directory contains multiple IDMLs
%
%     NB: If the selected folder contains a folder called 'MasterSpreads'
%     then it is assumed that the selected folder is that of a single
%     IDML file (option 1.); otherwise it is a collection of files
%
% saveViz {'save'} | 'nosave' - save the visualizations
% saveFile {'save'} | 'nosave' - save the results to XML & JSON files
% 
% -------------
% OUTPUT
% -------------
% See details in idmlgeo_wrapper.m.
% 
% -------------
% REQUIREMENTS
% -------------
% - xml_io_tools on an active Matlab path
% http://www.mathworks.com/matlabcentral/fileexchange/12907-xmliotools
% - multiWaitbar
% http://www.mathworks.com/matlabcentral/fileexchange/26589-multi-progress-bar/content/multiWaitbar.m
% 
% -------------
% LOG
% -------------
% 2013.10.05 - creation
% 
% -------------
% CREDITS
% -------------
% Vlad Atanasiu, atanasiu@alum.mit.edu, http://alum.mit.edu/www/atanasiu/


% -------------------
% INITIALISATION
% -------------------
if nargin < 1 || isempty(showViz)
    showViz = 'noshow';
end

if nargin < 2 || isempty(url)
    % select directrory interactively if none supplied
    url = uigetdir('','Select directory with IDML files');
    if url == 0
        return
    end
end

if nargin < 3 || isempty(saveViz)
    saveViz = 'save';
end

if nargin < 4 || isempty(saveFile)
    saveFile = 'save';
end


% -------------------
% PROCESS FILES
% -------------------

% list of IDML files
dircontents = dir([url filesep '*.idml']);

% process file loop
multiWaitbar('Batch',0);
n = numel(dircontents);
for k = 1:n
    multiWaitbar('Batch','Increment',1/n);

    % file
    fn = [url filesep dircontents(k).name];
    dn = fn(1:end-5);

    % unzip IDML file
    unzip(fn,dn)

    % extract data
    idmlgeo_wrapper(dn, showViz, saveViz, saveFile);

    % delete unzipped files
    rmdir(dn,'s')
end
multiWaitbar('Batch','Close');

beep, beep, beep

