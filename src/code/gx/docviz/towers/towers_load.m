function hGuidata = towers_load(hFigureMain, url)
% TOWERS_LOAD Visualize the spatial structure of documents (bounding boxes)
% 
% -------------
% INPUT
% -------------
% hFigureMain - handle to the main GUI figure
% url - directory path of document geometry data (json file)
%       NOTE: see towers_show for the format specifications
% 
% -------------
% OUTPUT
% -------------
% [name].fig - visualization of frames as Matlab figure
% [name].eps - idem in Encapsulated Post Script;
%     useful to insert in print documents
% [name].png - idem in PNG; useful for web display
% [name] - w pages.[fig,eps,png] - shows frames and page boundaries
% 
% -------------
% REQUIREMENTS
% -------------
% - multiWaitbar
% http://www.mathworks.com/matlabcentral/fileexchange/26589-multi-progress-bar/content/multiWaitbar.m
% 
% -------------
% LOG
% -------------
% 2018.10.01 - [new] added support for information on object labels
% 2014.12.09  - creation
% 
% -------------
% CREDITS
% -------------
% Vlad Atanasiu, atanasiu@alum.mit.edu, http://alum.mit.edu/www/atanasiu/


% -------------------
% INITIALISATION
% -------------------
if nargin < 2 || isempty(url)
    % select directory interactively if none supplied
    url = uigetdir('','Select directory of geometry data files');
    if sum(double(url)) == 0
        return
    elseif size(dir(fullfile(url,'*.json')),1) == 0
        msgbox('No geometry files in this directory', 'Error','error');
        return
    end
end
% clear variable url for later reuse of same name
c = url; clear url; url.path = c;
% well formed path
if ~strcmp(url.path(end),filesep)
    url.path = [url.path,filesep];
end
% by cd-ing to the selected directory we don't need to select it the next
% time we want to use it; also this allows to put the PDF of a document to
% visualize in the same directory as its geometry
cd(url.path)
% directory name
k = strfind(url.path,filesep);
if k == 1
    idx = 1;
else
    idx = k(end-1);
end
urlGuiData.dir = ['...',url.path(idx:end)];
urlGuiData.path = url.path;
% file names
url.files = dir(fullfile(url.path,'*.json'));
nFiles = length(url.files);
% there are no files in the selected directory
if nFiles == 0
    hGuidata = [];
    return
end
urlGuiData.file = url.files(1).name;
setappdata(hFigureMain,'url',urlGuiData)

% object classes to be displayed
objectClasses = getappdata(hFigureMain,'objectClasses');
objectClassesShow(1) = {'Documents'};
objectClassesShow(2:numel(objectClasses)+1) = objectClasses;
statisticsClasses = getappdata(hFigureMain,'statisticsClasses');

% reset statistics
statistics = getappdata(hFigureMain,'statistics');
statistics.Documents = 0;
n = length(objectClasses);
for k = 1:n
    statistics.(objectClasses{k}) = 0;
end
statistics.FontsSelected = 0;
n = length(statisticsClasses);
for k = 1:n
    statistics.(statisticsClasses{k}) = {};
end

% varia
geometry = struct;
docRank = [];
docRank.n = nFiles;
figObjLabels.list = [];
figObjLabels.selection = [];
setappdata(hFigureMain,'labels',figObjLabels)
fontsGeometry = struct;
setappdata(hFigureMain,'fontsGeometry',fontsGeometry)
fontsSingletons = struct;
fontsSingletons.name = {};
fontsSingletons.size = [];
fontsSingletons.color = [];
fontsSingletons.transparency = [];
setappdata(hFigureMain,'fontsSingletons',fontsSingletons)
docsPerFig = 'single';
if nFiles > 1
    docsPerFig = 'multiple';
end
setappdata(hFigureMain,'docsPerFig',docsPerFig);
preferences = getappdata(hFigureMain,'preferences');
textFaceAlpha = preferences.textFaceAlpha;
addVizMode = preferences.addVizMode;

% show coordinates origin
hCoordinatesAxes = hggroup;
hCoordinatesAxes.Visible = 'off';
text(0,0,0,'0','BackgroundColor','yellow','Parent',hCoordinatesAxes)
text(1000,0,0,'X','BackgroundColor','red','Parent',hCoordinatesAxes)
text(0,1000,0,'Y','BackgroundColor','green','Parent',hCoordinatesAxes)
text(0,0,1000,'Z','BackgroundColor','blue','Parent',hCoordinatesAxes)
line([0,1000],[0,0],[0,0],'Color','red','Parent',hCoordinatesAxes)
line([0,0],[0,1000],[0,0],'Color','green','Parent',hCoordinatesAxes)
line([0,0],[0,0],[0,1000],'Color','blue','Parent',hCoordinatesAxes)
setappdata(hFigureMain,'hCoordinatesAxes',hCoordinatesAxes)

% document location in collection grid
grid = struct;
grid.x = 0;
grid.y = 0;
grid.ykmax = ceil( sqrt( nFiles ) ); % documents per row of a square grid
grid.yk = 1; % current document index
grid.xk1 = 0; % current document x axis displacement
grid.xk2 = 0; % next document x axis displacement
setappdata(hFigureMain,'grid',grid)


% -------------------
% PROCESSING
% -------------------

multiWaitbar('Importing geometry files',0);

for kFiles = nFiles:-1:1 % files
    
    multiWaitbar('Importing geometry files','Increment',1/nFiles);

    % read json file
    docRank.k = kFiles;
    url.file = url.files(kFiles).name;
    try
        json = loadjsonp([url.path, url.file]);
    catch
        msgbox([{'Could not read file ' url.file},...
            {'Please check it for errors.'}],...
            'Error','error');
        return
    end
    url.documentFileName = json.metadata.filename;

    % remove the dummy empty string (we want each spread to be a cell, but
    % if we make the spreads arrays of arrays and there is no string in
    % in them (i.e. no font information), then loadjson will read them
    % as a single matrix; now, by introducing one empty string, we force
    % loadjson to read the data as cells)
    json.geometry(1) = [];
    
    % set tags structure to empty if no tag information in file
    if isfield(json,'tags') == 0
        json.tags = [];
    end
    
    % get object classes
    class = [];
    n = length(objectClasses);
    for k = n:-1:1
        c = objectClasses{k};
        class{k}.name = c;
        class{k}.idx = 0;
    end
    
    % add object labels in current file to those allready stored in figure
    if isfield(json.metadata,'labels') == 1
%         fileObjLabels = rot90(json.metadata.labels(:,2)); % old
%        fileObjLabels = rot90(json.metadata.labels{:}(:,2)); % ok if 1 label
        n = length(json.metadata.labels);
        if n == 1 % in case there is only one label
            n = 2; % now we can reshape
        end
        fileObjLabels = reshape([json.metadata.labels{:}],n,[]);
        fileObjLabels = rot90(fileObjLabels(2,:));

        handles = guihandles(gcf);
        hFigureMain = handles.figureMain;
        figObjLabels = getappdata(hFigureMain,'labels');
        figObjLabels.list = unique([figObjLabels.list,fileObjLabels]);
        setappdata(hFigureMain,'labels',figObjLabels)
    end
    
    % transform from json format to matlab structure
    multiWaitbar('Reading geometries',0);
    n1 = length(json.geometry);
    for k1 = n1:-1:1 % spreads

        % in converting to structure, a string in a array makes the array 
        % to a cell, so we handle these cases separately
        if ~iscell(json.geometry{k1}) % arrays: spreads without fonts

            n2 = size(json.geometry{k1},1);
            for k2 = n2:-1:1 % objects

                % get object format class index
                c = json.geometry{k1}(k2,1);
                c = c + 1;
                class{c}.idx = class{c}.idx + 1;

                % get object geometry
                geo = json.geometry{k1}(k2,3:end);
                n3 = length(geo)/2;
                for k3 = n3:-1:1 % coordinates

                    y = geo(k3*2 - 1);
                    x = geo(k3*2);

                    % non-font objects geometry
                    geometry(kFiles).spreads(k1).(class{c}.name)(class{c}.idx).coordinates(k3).y = y;
                    geometry(kFiles).spreads(k1).(class{c}.name)(class{c}.idx).coordinates(k3).x = x;
                end
                
                % get object label
                if isfield(json.metadata,'labels') == 0
                    objLabel = 'Unlabeled';
                else
                    % label keys in geometry files start at zero, but the
                    % indices of Matlab structures start at one, so we
                    % increase the objLabelKey by one
                    objLabelKey = json.geometry{k1}(k2,2) + 1;
                    objLabel = json.metadata.labels{objLabelKey}(2);
%                     objLabel = json.metadata.labels{:}(objLabelKey,2);
%                     objLabel = json.metadata.labels(objLabelKey,2); % old
                end
                geometry(kFiles).spreads(k1).(class{c}.name)(class{c}.idx).label = ...
                    objLabel;
                
            end
        else % cells: spreads with fonts
            n2 = size(json.geometry{k1},1);
            for k2 = n2:-1:1 % objects

                % get object format class index
                c = json.geometry{k1}{k2}(1);
                if isstring(c)
                    % loadjson puts data in cells if there is a string
                    % in an array, so we have to convert back to numerical
                    c = str2double(char(c));
                end
%                 % previous code version:
%                 if iscell(c)
%                     c = c{1};
%                 end
                c = c + 1;
                class{c}.idx = class{c}.idx + 1;

                % get object label
                if isfield(json.metadata,'labels') == 0
                    objLabel = 'Unlabeled';
                else
                    objLabelKey = json.geometry{k1}{k2}(2);
                    if isstring(objLabelKey)
                        objLabelKey = str2double(char(objLabelKey));
                    end
                    objLabelKey = objLabelKey + 1;
                    objLabel = json.metadata.labels{objLabelKey}(2);
                end
                if c ~= 5
                    % non-font objects
                    geometry(kFiles).spreads(k1).(class{c}.name)(class{c}.idx).label = ...
                        objLabel;
                else
                    % font objects
                    fontsGeometry(kFiles).spreads(k1).Fonts(class{c}.idx).label = ...
                        objLabel;
                end
                
                % data beyond coordinates index
                d = 2;
                if c == 5 % font
                    d = 8;
                end

                n3 = (length(json.geometry{k1}{k2}) - d)/2;
                for k3 = n3:-1:1 % coordinates

                    y = json.geometry{k1}{k2}(k3*2 + 1);
                    x = json.geometry{k1}{k2}(k3*2 + 2);

                    if iscell(y)
                        y = y{1};
                        x = x{1};
                    end

                    if c ~= 5
                        % non-font objects geometry
                        geometry(kFiles).spreads(k1).(class{c}.name)(class{c}.idx).coordinates(k3).y = y;
                        geometry(kFiles).spreads(k1).(class{c}.name)(class{c}.idx).coordinates(k3).x = x;
                    else
                        % font geometry
                        fontsGeometry(kFiles).spreads(k1).Fonts(class{c}.idx).coordinates(k3).y = y;
                        fontsGeometry(kFiles).spreads(k1).Fonts(class{c}.idx).coordinates(k3).x = x;
                    end
                end

                % font attributes
                if c == 5
                    
                    % collect font geometries and attributes
                    fontName = json.geometry{k1}{k2}(n3*2 + 3);
                    fontName = fontName{1};
                    fontsGeometry(kFiles).spreads(k1).Fonts(class{c}.idx).name = ...
                        fontName;
                    fontSize = json.geometry{k1}{k2}(n3*2 + 4);
%                     fontSize = fontSize{1};
                    fontSize = str2double(fontSize);
                    fontsGeometry(kFiles).spreads(k1).Fonts(class{c}.idx).size = ...
                        fontSize;
                    r = json.geometry{k1}{k2}(n3*2 + 5);
%                     r = r{1};
                    r = str2double(r);
                    g = json.geometry{k1}{k2}(n3*2 + 6);
%                     g = g{1};
                    g = str2double(g);
                    b = json.geometry{k1}{k2}(n3*2 + 7);
%                     b = b{1};
                    b = str2double(b);
                    fontsGeometry(kFiles).spreads(k1).Fonts(class{c}.idx).color = ...
                        [r g b];
                    a = json.geometry{k1}{k2}(n3*2 + 8);
%                     a = a{1};
                    a = str2double(a);
                    fontsGeometry(kFiles).spreads(k1).Fonts(class{c}.idx).transparency = ...
                        a;
                    
                    % list of unique font attributes
                    n = length(fontsSingletons.name);
                    fontsSingletons.name{n+1} = fontName;
                    fontsSingletons.name = unique(fontsSingletons.name);
                    
                    fontsSingletons.size = ...
                        [fontsSingletons.size; fontSize];
                    fontsSingletons.size = ...
                        unique(fontsSingletons.size,'rows');
                    
                    fontsSingletons.color = ...
                        [fontsSingletons.color; r g b];
                    fontsSingletons.color = ...
                        unique(fontsSingletons.color,'rows');
                    
                    fontsSingletons.transparency = ...
                        [fontsSingletons.transparency; a];
                    fontsSingletons.transparency = ...
                        unique(fontsSingletons.transparency,'rows');
                end
            end
        end
        
        % reset object class index
        n = length(objectClasses);
        for c = 1:n
            class{c}.idx = 0;
        end
        
        multiWaitbar('Reading geometries','Increment',1/n1);
    end
    multiWaitbar('Reading geometries','Close');

    % increment statistics
    statistics.Documents = statistics.Documents + 1;
    n = length(objectClasses);
    for k = 1:n
         statistics.(objectClasses{k}) = statistics.(objectClasses{k}) + ...
            json.metadata.counts(k);
    end

    % show document geometry
    towers_show(...
        geometry(kFiles).spreads, json.metadata, url, ...
        docsPerFig, hFigureMain, docRank, ...
        textFaceAlpha, objectClassesShow, json.tags, addVizMode);

    % save metadata to figure
    metadata(kFiles) = json.metadata;
    setappdata(hFigureMain,'metadata',metadata)

end
multiWaitbar('Importing geometry files','Close');

% save data to figure
setappdata(hFigureMain,'geometry',geometry)
setappdata(hFigureMain,'fontsGeometry',fontsGeometry)
setappdata(hFigureMain,'fontsSingletons',fontsSingletons)
setappdata(hFigureMain,'statistics',statistics)
