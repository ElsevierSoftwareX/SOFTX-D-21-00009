function xml = idmlgeo_units(url, DOM)
%IDMLGEO_UNITS Gets data on units from InDesign IDML files
% 
% -------------
% INPUT
% -------------
% url - URL of IDML unzipped directory
% DOM - IDML DOMs of Styles.xml, Graphic.xml, Preferences.xml
% 
% -------------
% OUTPUT
% -------------
% xml - dat on units used in the IDML document
% 
% -------------
% LIMITATIONS
% -------------
% - See also limitations in idmlgeo.m.
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
% 2013.10.03 - creation
% 
% -------------
% CREDITS
% -------------
% Vlad Atanasiu, atanasiu@alum.mit.edu, http://alum.mit.edu/www/atanasiu/


if nargin < 1 || isempty(url)
    % select directrory interactively if none supplied
    url = uigetdir('','Select directory of unzipped IDML files');
    if url == 0
        return
    end
end
% get directory path & name
if isfield(url, 'dir') == 0
    t = url; clear url; url.dir = t;
    url = url_chop(url);
end

if nargin < 2 || isempty(DOM)
    DOM.Preferences = xml_read(...
        [url.dir filesep 'Resources' filesep 'Preferences.xml']);
end

units.space.unit = 'point';
units.space.resolution = DOM.Preferences.ViewPreference.ATTRIBUTE.PointsPerInch;
units.text = DOM.Preferences.ViewPreference.ATTRIBUTE.TextSizeMeasurementUnits;

xml = [...
    '\t<units>\n',...
    '\t\t<space>\n',...
    '\t\t\t<unit>' units.space.unit '</unit>\n',...
    '\t\t\t<pointsPerInch>' num2str(units.space.resolution) '</resolution>\n',...
    '\t\t</space>\n'...
    '\t\t<text>' units.text '</text>\n',...
    '\t</units>\n'...
    ];
