function xml = idmlgeo_wrapper(url, showViz, saveViz, saveFile, getPolygons, onlyGeoJson)
%IDMLGEO_WRAPPER Reads various data from InDesign IDML files
% 
% -------------
% INPUT
% -------------
% url - URL of IDML unzipped directory
% showViz {'show'} | 'noshow' - visualize some of the results
% saveViz {'save'} | 'nosave' - save the visualizations
% saveFile {'save'} | 'nosave' - save the results to XML & JSON files
% getPolygons {false} | true - reduce frames to bounding boxes 
% onlyGeoJson {true} | false - extract only geometry and save only to JSON
%       i.e. no colors, folios, preferences, and XML, MAT saves
% 
% -------------
% OUTPUT
% -------------
% [name].xml - xml file, described in the following functions:
%     idmlgeo_units - units used in the IDML document
%     idmlgeo_folios - data on the page numbers
%     idmlgeo_frames - data on frames
%     idmlgeo_styles - style description
% [name]_frames.mat - frames coordinates of each spread;
%     saved in matlab format, useful for example for visualizing
%     individual documents or collections; saved within the 
%     folder containing the IDML file that is processed
% 
% -------------
% LIMITATIONS
% -------------
% - The software works with InDesign version CS6.
% - The idml file has to be unzipped to a directory of the same name as 
%   the file, without its extension.
%     Ex: FILE: filename.idml > DIRECTORY: filename    
%     NOTE: An IDML file is a zipped collection of files;
%     you need to change the extension to .zip and unzip
%     the file, in order to access its content.
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
% NOTE ON COORDINATES
% -------------
% The origin of the coordinate system used in the output is the center 
% of the double page (it is assumed there are only two pages per spread 
% of equal size). If there is only one page in the document the origin 
% is half way of its height, on the left hand edge.
% 
% References: Adobe Systems (2012) - IDML File Format Specification. 
% Version 8.0; 10.3.3 Geometry in IDML, San Jose (CA), 99-109. 
% Also: InDesign SDK Programming Guide: ?Layout Fundamentals?; 
% PostScript Language Reference Manual.
% 
% -------------
% NOTE ON STYLE INHERITANCE
% -------------
% Following style inheritance rules are applied: 
% 1. Story_[*].xml (overrides)
% 2. Styles.xml (if applied style is not [No character|paragraph style])
% 3. Preferences.xml: TextDefault (can be based on styles defined in Styles.xml)
% 
% -------------
% LOG
% -------------
% 2013.10.04 - [new] addded functions
%            - [new] made code modular
% 2013.09.12 - creation
% 
% -------------
% CREDITS
% -------------
% Vlad Atanasiu, atanasiu@alum.mit.edu, http://alum.mit.edu/www/atanasiu/


% -------------
% initialisations
% -------------
if nargin < 2 || isempty(showViz)
    showViz = 'show';
end
if nargin < 3 || isempty(saveViz)
    saveViz = 'save';
end
if nargin < 4 || isempty(saveFile)
    saveFile = 'save';
end
if nargin < 5 || isempty(getPolygons)
    getPolygons = false; % write all frames as bounding boxes
end
if nargin < 6 || isempty(onlyGeoJson)
    onlyGeoJson = true; % extract just the geometry and save as JSON only
end

t = url; clear url; url.dir = t;
url = url_chop(url);

if onlyGeoJson == false
    % progress bars
    multiWaitbar('Steps',0);


% -------------
% read IDML files content
% -------------
    multiWaitbar('Steps','Increment',1/3);
    multiWaitbar('Importing IDML files',0);

    DOM = [];
    multiWaitbar('Importing IDML files','Increment',1/3);
    DOM.Styles = xml_read(...
        [url.dir filesep 'Resources' filesep 'Styles.xml']);

    multiWaitbar('Importing IDML files','Increment',1/3);
    DOM.Preferences = xml_read(...
        [url.dir filesep 'Resources' filesep 'Preferences.xml']);

    multiWaitbar('Importing IDML files','Increment',1/3);
    DOM.Graphic = xml_read(...
        [url.dir filesep 'Resources' filesep 'Graphic.xml']);

    multiWaitbar('Importing IDML files','Close');

% -------------
% extract InDesign info
% -------------
    multiWaitbar('Steps','Increment',1/3);
    multiWaitbar('Filtering IDML data',0);

    multiWaitbar('Filtering IDML data','Increment',1/4);
    units = idmlgeo_units(url, DOM);

    multiWaitbar('Filtering IDML data','Increment',1/4);
    folios = idmlgeo_folios(url, DOM, showViz);

    multiWaitbar('Filtering IDML data','Increment',1/4);
end

frames = idmlgeo_frames(url, showViz, saveViz, saveFile, getPolygons, onlyGeoJson);

if onlyGeoJson == false

    multiWaitbar('Filtering IDML data','Increment',1/4);
    styles = idmlgeo_styles(url, DOM);

    multiWaitbar('Filtering IDML data','Close');

% -------------
% generate xml
% -------------
    multiWaitbar('Steps','Increment',1/3);
    multiWaitbar('Writing XML file',0);
    multiWaitbar('Writing XML file','Increment',1);

    xml = [...
        '<?xml version="1.0" encoding="UTF-8"?>\n'...
        '<!-- Coordinates origin: center of the doublepage. -->\n'...
        '<InDesignInfo '...
        'xmlns="." '...
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '...
        'xsi:schemaLocation=". indesign_info.xsd">\n'...
        '\t<fileName>' url.name '</fileName>\n'];
    xml = [xml, units, folios, frames, styles];
    xml = [xml,'</InDesignInfo>'];

% -------------
% write to file
% -------------
    fid = fopen([url.path, url.name,'_indesign_info.xml'],'w');
    fprintf(fid,xml,'%s');
    fclose(fid);

    multiWaitbar('Writing XML file','Close');
end
multiWaitbar('Steps','Close');
