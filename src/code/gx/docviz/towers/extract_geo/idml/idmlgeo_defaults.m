function output = idmlgeo_defaults(DOM, structure, node, type, property)
%IDMLGEO_DEFAULTS Individual defaults & graphic data in IDML files
% 
% -------------
% INPUT
% -------------
% DOM - IDML DOMs of Styles.xml, Graphic.xml, Preferences.xml
% structure ('Preferences' | 'Graphic') - DOM name; same as
%     the IDML file where to look for data in this code
% node - name of XML tag from where data is to be extracted
% type ('attribute' | 'content') - whether the data is an XML
%     attribute or content
% property - name of the attribute or content node where teh data is
% 
% -------------
% OUTPUT
% -------------
% xml - data on IDML document defaults
% 
% -------------
% LIMITATIONS
% -------------
% There should be only one node with the given name in the structure.
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

output = [];
switch type
    case 'attribute'
        if isfield(DOM.(structure).(node).ATTRIBUTE, property)
            output = DOM.(structure).(node).ATTRIBUTE.(property);
        end
    case 'content'
        if isfield(DOM.(structure).(node).Properties, property)
            output = DOM.(structure).(node).Properties.(property).CONTENT;
        end
end

