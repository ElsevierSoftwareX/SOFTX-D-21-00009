function output = idmlgeo_colors(DOM, name)
%IDMLGEO_COLORS Gets color data from InDesign IDML files
% 
% -------------
% INPUT
% -------------
% DOM - Either of the two:
%     1. IDML DOMs of Graphic.xml
%     2. URL of IDML unzipped directory
% name - color name
% 
% -------------
% OUTPUT
% -------------
% output (structure) - data on an IDML color
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


% load DOM
if ~isstruct(DOM)
    if nargin < 1 || isempty(url)
        % select directrory interactively if none supplied
        url = uigetdir('','Select directory of unzipped IDML files');
        if url == 0;
            return
        end
    end
    % get directory path & name
    if isfield(url, 'dir') == 0
        t = url; clear url; url.dir = t;
        url = url_chop(url);
    end
    % read IDML file
    DOM.Graphic = xml_read(...
        [url.dir filesep 'Resources' filesep 'Graphic.xml']);
end

% initialization
output = [];
if isempty(name)
    return
end

% loop colors
multiWaitbar('Looking for color',0);
n = numel(DOM.Graphic.Color);
for k = 1:n
    multiWaitbar('Looking for color','Increment',1/n);
    
    if strcmp(DOM.Graphic.Color(k).ATTRIBUTE.Self, name) == 1
        
        output.Name = DOM.Graphic.Color(k).ATTRIBUTE.Name;
        output.Model = DOM.Graphic.Color(k).ATTRIBUTE.Model;
        output.Space = DOM.Graphic.Color(k).ATTRIBUTE.Space;
        output.ColorValue = DOM.Graphic.Color(k).ATTRIBUTE.ColorValue;
        
        break
    end
end
multiWaitbar('Looking for color','Close');


