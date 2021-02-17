function [geoSpread, counts, footprint, objLabelsPg] = altogeo_pg(url)
%ALTOGEO_PG Reads page object coordinates from Alto files
% 
% -------------
% INPUT
% -------------
% url - URL of page description file.
%
% -------------
% OUTPUT
% -------------
% geoSpread - Coordinates of various page objects in this spread.
% counts - Quantity of various page objects.
% footprint - Document footprint.
% objLabels - Object labels in this page.
%
% -------------
% REQUIREMENTS
% -------------
% root = 'http://www.mathworks.com/matlabcentral/fileexchange'
%
% - xml_io_tools on an active Matlab path
% {root}/12907-xmliotools
% - multiWaitbar
% {root}/26589-multi-progress-bar/content/multiWaitbar.m
% 
% -------------
% LOG
% -------------
% 2018.09.12 - creation
% 
% -------------
% CREDITS
% -------------
% Vlad Atanasiu, atanasiu@alum.mit.edu, http://alum.mit.edu/www/atanasiu/


% -------------------
% INITIALIZATION
% -------------------
geoSpread = '\t\t[\n';

counts.Texts = 0;
counts.Images = 0;
counts.Graphics = 0;
counts.Fonts = 0;

footprint.n = 0;
footprint.e = 0;
footprint.s = 0;
footprint.w = 0;


% -------------------
% PROCESS
% -------------------

% read page info
try
    DOM = xml_read(url);
catch
    msgbox([{'Could not read file ' url.file},...
        {'Please check it for errors.'}],...
        'Error','error');
    return
end

% page geometry
if isfield(DOM.Layout, 'Page')
    
    xmlItem = DOM.Layout.Page;
    n = numel(xmlItem);
    for k = 1:n

        % get coordinates
        geoSpread = [geoSpread,...
            '\t\t\t[0,0,', ...
            '0,','0,',...
            num2str(xmlItem(k).ATTRIBUTE.WIDTH),',0,',...
            num2str(xmlItem(k).ATTRIBUTE.WIDTH),',',num2str(xmlItem(k).ATTRIBUTE.HEIGHT),',',...
            '0,',num2str(xmlItem(k).ATTRIBUTE.HEIGHT),...
            '],\n'];
        
        % document footprint
        if footprint.e < xmlItem(k).ATTRIBUTE.WIDTH
            footprint.e = xmlItem(k).ATTRIBUTE.WIDTH;
        end
        if footprint.s < xmlItem(k).ATTRIBUTE.HEIGHT
            footprint.s = xmlItem(k).ATTRIBUTE.HEIGHT;
        end
    end
end

% text blocks geometry 
if isfield(DOM.Layout.Page.PrintSpace, 'TextBlock')
    
    xmlItem = DOM.Layout.Page.PrintSpace.TextBlock;
    n = numel(xmlItem);
    counts.Texts = counts.Texts + n;
    for k = 1:n

        % get object label
        objLabel = [];
        if isfield(xmlItem(k).ATTRIBUTE,'TAGREFS')
            objLabel = xmlItem(k).ATTRIBUTE.TAGREFS;
            if contains(objLabel,'LAYOUT_TAG_')
                objLabel = objLabel(1:numel('LAYOUT_TAG_')+3);
            end
        end
        
        % get coordinates
        geoSpread = [geoSpread,...
            '\t\t\t[1,"',objLabel,'",', ...
            num2str(xmlItem(k).ATTRIBUTE.HPOS),',',...
                num2str(xmlItem(k).ATTRIBUTE.VPOS),',',...
            num2str(xmlItem(k).ATTRIBUTE.HPOS + xmlItem(k).ATTRIBUTE.WIDTH),',',...
                num2str(xmlItem(k).ATTRIBUTE.VPOS),',',...
            num2str(xmlItem(k).ATTRIBUTE.HPOS + xmlItem(k).ATTRIBUTE.WIDTH),',',...
                num2str(xmlItem(k).ATTRIBUTE.VPOS + xmlItem(k).ATTRIBUTE.HEIGHT),',',...
            num2str(xmlItem(k).ATTRIBUTE.HPOS),',',...
                num2str(xmlItem(k).ATTRIBUTE.VPOS + xmlItem(k).ATTRIBUTE.HEIGHT),...
            '],\n'];
    end
end

% graphics & text block geometry in composed blocks
if isfield(DOM.Layout.Page.PrintSpace, 'ComposedBlock')
    
    xmlCB = DOM.Layout.Page.PrintSpace.ComposedBlock;
    nCB = numel(xmlCB);
    for kCB = 1:nCB

        % get object label
        objLabel = [];
        if isfield(xmlCB(kCB).ATTRIBUTE,'TAGREFS')
            objLabel = xmlCB(kCB).ATTRIBUTE.TAGREFS;
            if contains(objLabel,'LAYOUT_TAG_')
                objLabel = objLabel(1:numel('LAYOUT_TAG_')+3);
            end
        end
        
        % look for graphics
        if isfield(xmlCB(kCB), 'GraphicalElement')
            nGE = numel(xmlCB(kCB).GraphicalElement);
            counts.Images = counts.Images + nGE;
            for kGE = 1:nGE
 
                % get coordinates
                xmlGE = xmlCB(kCB).GraphicalElement(kGE).ATTRIBUTE;
                geoSpread = [geoSpread,...
                    '\t\t\t[2,"',objLabel,'",', ...
                    num2str(xmlGE.HPOS),',',...
                        num2str(xmlGE.VPOS),',',...
                    num2str(xmlGE.HPOS + xmlGE.WIDTH),',',...
                        num2str(xmlGE.VPOS),',',...
                    num2str(xmlGE.HPOS + xmlGE.WIDTH),',',...
                        num2str(xmlGE.VPOS + xmlGE.HEIGHT),',',...
                    num2str(xmlGE.HPOS),',',...
                        num2str(xmlGE.VPOS + xmlGE.HEIGHT),...
                    '],\n'];
            end
        end
        
        % look for text
        if isfield(xmlCB(kCB), 'TextBlock')
            nTB = numel(xmlCB(kCB).TextBlock);
            counts.Texts = counts.Texts + nTB;
            for kTB = 1:nTB
 
                % get coordinates
                xmlTB = xmlCB(kCB).TextBlock(kTB).ATTRIBUTE;
                geoSpread = [geoSpread,...
                    '\t\t\t[1,"',objLabel,'",', ...
                    num2str(xmlTB.HPOS),',',...
                        num2str(xmlTB.VPOS),',',...
                    num2str(xmlTB.HPOS + xmlTB.WIDTH),',',...
                        num2str(xmlTB.VPOS),',',...
                    num2str(xmlTB.HPOS + xmlTB.WIDTH),',',...
                        num2str(xmlTB.VPOS + xmlTB.HEIGHT),',',...
                    num2str(xmlTB.HPOS),',',...
                        num2str(xmlTB.VPOS + xmlTB.HEIGHT),...
                    '],\n'];
            end
        end
    end
end

% manage object labels
if isfield(DOM.Tags, 'LayoutTag')
    
    % has no object label
    geoSpread = strrep(geoSpread,'""','0');
    
    % replace object keys with object labels
    xmlItem = DOM.Tags.LayoutTag;
    n = numel(xmlItem);
    objLabelsPg = cell(1,n);
    for k = 1:n
        
        objKey = xmlItem(k).ATTRIBUTE.ID;
        objLabel = xmlItem(k).ATTRIBUTE.LABEL;
        geoSpread = strrep(geoSpread, objKey, objLabel);
        
        % forward page labels to calling function for collection over 
        % entire document
        objLabelsPg{k} = objLabel;
    end
end

% finish
geoSpread(end-2) = [];
geoSpread = [geoSpread,'\t\t],\n'];
