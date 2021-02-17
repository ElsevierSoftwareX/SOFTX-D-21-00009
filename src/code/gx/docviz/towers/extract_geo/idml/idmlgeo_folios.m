function xml = idmlgeo_folios(url, DOM, showViz)
%IDMLGEO_FOLIOS Gets data on page numbers from InDesign IDML files
% 
% -------------
% INPUT
% -------------
% url - URL of IDML unzipped directory
% DOM - IDML DOMs of Styles.xml, Graphic.xml, Preferences.xml
% showViz {'show'} | 'noshow' - visualize some of the results
% 
% -------------
% OUTPUT
% -------------
% xml - data on the page numbers, as follows:
%     - page number information:
%         - coordinates of bounding boxes of page numbers frames on master 
%         pages
%         - font family
%         - font style
%         - font size
%         - numbering format (Upper�Roman, LowerRoman, UpperLetters, 
%         Lower�Letters, Arabic, KatakanaModern (a, i, u, e, o), KatakanaTraditional 
%         (i, ro, ha, ni), FormatNone (Do not add characters), SingleLeadingZeros 
%         (Add single leading zeros), Kanji (Kanji), DoubleLeadingZeros, 
%         Triple�LeadingZeros)
%         [name].png - an image visualizing the location of the page number locations
%     - master pages information:
%         - coordinates of bounding boxes of all text frames
% 
% -------------
% LIMITATIONS
% -------------
% - See also limitations in idmlgeo.m.
% - Page numbers limitations and assumptions:
%     - The page number location is approximative: it is that of the frame 
%     containing the page number. The reason is that the software looks 
%     for the marker denoting a page number, not at the final visual
%     appearance (i.e. after the text was set in a given font, size, 
%     kerning, sourrounding text, etc.).
%     - Only page numbers in master pages are considered (i.e. not 
%     'normal' pages).
%     - All spreads have identical dimensions and contain two pages.
%     - There is one page number per page.
%     - All page numbers have identical formatting.
%     - The order of numbering formats in the xml output is arbitrary.
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

if nargin < 2 || isempty(DOM)
    multiWaitbar('Importing IDML files',0);

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
end

if nargin < 3 || isempty(showViz)
    showViz = 'show';
end

% variables
pageSizeExtracted = false; % are page sizes extracted (1) or not yet (0)
pageNumber = [];
pageNumber.marker = '<?ACE 18?>';
pageNumber.coordinates = [];
pageNumber.attributes = {'AppliedFont','FontStyle','PointSize'};
pageNumber.ports = {'content','attribute','attribute'};
pageNumber.style(1).AppliedFont = '';
pageNumber.style(1).FontStyle = '';
pageNumber.style(1).PointSize = [];
pageNumber.style(1).characterStyleName = '';
pageNumber.style(1).paragraphStyleName = '';
pageNumber.format = [];
masterPageFrames.coordinates = [];


% -------------------
% MASTER PAGES INFO
% -------------------

% get master pages names
masterspreads = dir([url.dir filesep 'MasterSpreads']);
masterspreads = masterspreads(3:end);
nms = size(masterspreads,1);
multiWaitbar('Scanning master spreads',0);

% loop master spreads
% -------------------
for kms = 1:nms
    multiWaitbar('Scanning master spreads','Increment',1/nms);
    
    % read DOM
    DOM_ms = xml_read([url.dir filesep 'MasterSpreads'...
        filesep masterspreads(kms).name]);
    % skip if no text frames
    if isfield(DOM_ms.MasterSpread, 'TextFrame') == 0
        continue;
    end
    % number of text frames in spread
    nf = size(DOM_ms.MasterSpread.TextFrame, 1);
    % get page size (assumed that all are the same)
    if(not(pageSizeExtracted))
        pageSize = str2num(DOM_ms.MasterSpread.Page(1).ATTRIBUTE.GeometricBounds);
        pageSize = pageSize(3:4);
        pageSizeExtracted = true;
    end
    multiWaitbar('Getting frames',0);
    
    % loop frames
    % -------------------
    for kf = 1:nf
        multiWaitbar('Getting frames','Increment',1/nf);

        % get story name
        tf = DOM_ms.MasterSpread.TextFrame(kf);
        storyName = tf.ATTRIBUTE.ParentStory;
        storyUrl = [url.dir filesep 'Stories' filesep ...
            'Story_' storyName '.xml'];
        
        % get frames coordinates
        % -------------------
        fid = fopen(storyUrl);
        storyText = fscanf(fid,'%c');
        fclose(fid);
        
        % --- frames without page numbers
        % origin
        frameOrigin = [];
        coords = str2num(tf.ATTRIBUTE.ItemTransform);
        frameOrigin(1) = coords(5);
        frameOrigin(2) = coords(6);

        % frame edges
        % coordinates appear in x, y sequence;
        % positive direction is down and right
        idx = size(masterPageFrames.coordinates, 1) + 1;
        c = tf.Properties.PathGeometry.GeometryPathType.PathPointArray;
        coords = str2num(c.PathPointType(1).ATTRIBUTE.Anchor);
        masterPageFrames.coordinates(idx,1) = ...
            frameOrigin(1) + coords(1);
        masterPageFrames.coordinates(idx,2) = ...
            frameOrigin(2) + coords(2);
        coords = str2num(c.PathPointType(3).ATTRIBUTE.Anchor);
        masterPageFrames.coordinates(idx,3) = ...
            frameOrigin(1) + coords(1);
        masterPageFrames.coordinates(idx,4) = ...
            frameOrigin(2) + coords(2);

        
        % --- frames with page numbers
        % skip if no page number in frame
        if isempty(strfind(storyText, pageNumber.marker))
            continue;
        end
        idx = size(pageNumber.coordinates, 1) + 1;
        
        % origin
        frameOrigin = [];
        coords = str2num(tf.ATTRIBUTE.ItemTransform);
        frameOrigin(1) = coords(5);
        frameOrigin(2) = coords(6);
        
        % frame edges
        % coordinates appear in x, y sequence;
        % positive direction is down and right
        c = tf.Properties.PathGeometry.GeometryPathType.PathPointArray;
        coords = str2num(c.PathPointType(1).ATTRIBUTE.Anchor);
        pageNumber.coordinates(idx,1) = ...
            frameOrigin(1) + coords(1);
        pageNumber.coordinates(idx,2) = ...
            frameOrigin(2) + coords(2);
        coords = str2num(c.PathPointType(3).ATTRIBUTE.Anchor);
        pageNumber.coordinates(idx,3) = ...
            frameOrigin(1) + coords(1);
        pageNumber.coordinates(idx,4) = ...
            frameOrigin(2) + coords(2);

        % get style
        % -------------------
        DOM.Stories = xml_read(storyUrl);
        % --- look in stories
        % loop paragraphs
        ps = DOM.Stories.Story.ParagraphStyleRange;
        nps = size(ps, 1);
        for kps = 1:nps
            % loop character styles
            cs = ps(kps).CharacterStyleRange;
            ncs = size(cs, 1);
            for kcs = 1:ncs
                % skip if no pagenumber marker in current node
                if isfield(cs(kcs).Content, 'PROCESSING_INSTRUCTION') == 0
                    continue
                end
                % --- look for overrides
                % font family
                if isfield(cs(kcs), 'Properties') == 1 && ...
                        isfield(cs(kcs).Properties, 'AppliedFont') == 1
                    pageNumber.style(idx).AppliedFont = ...
                        cs(kcs).Properties.AppliedFont.CONTENT;
                end
                % font style
                if isfield(cs(kcs).ATTRIBUTE, 'FontStyle') == 1
                    pageNumber.style(idx).FontStyle = ...
                        cs(kcs).ATTRIBUTE.FontStyle;
                end
                % font size
                if isfield(cs(kcs).ATTRIBUTE, 'PointSize') == 1
                    pageNumber.style(idx).PointSize = ...
                        cs(kcs).ATTRIBUTE.PointSize;
                end
                % character style
                len = length('CharacterStyle/');
                pageNumber.style(idx).characterStyleName = ...
                    cs(kcs).ATTRIBUTE.AppliedCharacterStyle(len+1:end);
                % paragraph style
                len = length('ParagraphStyle/');
                pageNumber.style(idx).paragraphStyleName = ...
                    ps(kps).ATTRIBUTE.AppliedParagraphStyle(len+1:end);
            end
        end
    end
    multiWaitbar('Getting frames','Close');
end
multiWaitbar('Scanning master spreads','Close');

% --- inherit styles
multiWaitbar('Recovering inherited styles',0);

% move styles out of groups
DOM_K = DOM.Styles.RootCharacterStyleGroup;
DOM_K = xml_flatten(DOM_K, 'CharacterStyle');
DOM.Styles.RootCharacterStyleGroup = DOM_K;
DOM_K = DOM.Styles.RootParagraphStyleGroup;
DOM_K = xml_flatten(DOM_K, 'ParagraphStyle');
DOM.Styles.RootParagraphStyleGroup = DOM_K;

properties = pageNumber.attributes;
n1 = numel(pageNumber.style);
n2 = numel(properties);
for k1 = 1:n1
    multiWaitbar('Recovering inherited styles','Increment',1/n1);
    item = pageNumber.style(k1);
    
    % check if any style is empty (no overrides)
    if (isempty(item.AppliedFont) || ...
        isempty(item.FontStyle) || ...
        isempty(item.PointSize))

        % --- look in inherited character style
        item = style_inherit(DOM.Styles.RootCharacterStyleGroup, ...
            'CharacterStyle', item, item.characterStyleName, properties);

        % --- look in inherited paragraph style
        if (isempty(item.AppliedFont) || ...
            isempty(item.FontStyle) || ...
            isempty(item.PointSize))

            item = style_inherit(DOM.Styles.RootParagraphStyleGroup, ...
                'ParagraphStyle', item, item.paragraphStyleName, properties);
        end
        
        % --- if still empty read defaults
        for k2 = 1:n2

            % check if any property is empty
            if isempty(item.(properties{k2}))

                % read default property
                item.(properties{k2}) = ...
                    idmlgeo_defaults(DOM,'Preferences',...
                    'TextDefault',pageNumber.ports{k2},properties{k2});
            end
        end
    end
    pageNumber.style(k1) = item;
end
multiWaitbar('Recovering inherited styles','Close');

        
% get numbering formats
% -------------------
% get master pages names
spreads = dir([url.dir filesep 'Spreads']);
spreads = spreads(3:end);
nsp = size(spreads,1);

% loop spreads
multiWaitbar('Getting folio styling',0);
idx = 1;
for ksp = 1:nsp
    multiWaitbar('Getting folio styling','Increment',1/nsp);
    DOM_sp = xml_read([url.dir filesep 'Spreads'...
        filesep spreads(ksp).name]);
    % loop pages
    npages = size(DOM_sp.Spread.Page, 1);
    for kpages = 1:npages
        dlist = DOM_sp.Spread.Page(kpages).Properties.Descriptor;
        % loop page descriptors
        nlist = size(dlist.ListItem, 1);
        for klist = 1:nlist
            if strcmp(dlist.ListItem(klist).ATTRIBUTE.type, 'enumeration') == 1
                % get numbering format
                pageNumber.format(idx).format = dlist.ListItem(klist).CONTENT;
                idx = idx + 1;
            end
        end
    end
end
multiWaitbar('Getting folio styling','Close');

% remove duplicates from the numbering list
multiWaitbar('Cleaning folio styling',0);
t1 = pageNumber.format;
t2 = [];
t2(1).format = t1(1).format;
pageNumber.format = [];
itemExists = 0;
n1 = size(t1,2);
for k1 = 1:n1
    multiWaitbar('Cleaning folio styling','Increment',1/n1);
    n2 = size(t2,2);
    for k2 = 1:n2
        if strcmp(t1(k1).format, t2(k2).format) == 1
            itemExists = 1;
        end
    end
    if itemExists == 0
        t2(k2+1).format = t1(k1).format;
    end
    itemExists = 0;
end    
pageNumber.format = t2;

multiWaitbar('Cleaning folio styling','Close');


% -------------------
% XML OUTPUT
% -------------------

multiWaitbar('Writing XML string',0);

% page numbers
% -------------------
multiWaitbar('Writing XML string','Increment',1/2);

% write location and pageNumber style information
xml = '\t<pageNumbers>\n';
n = size(pageNumber.coordinates,1);
for k = 1:n
    xml = [xml,...
	'\t\t<pageNumber>\n',...
    	'\t\t\t<location>\n',...
            '\t\t\t\t<nwx>',num2str(pageNumber.coordinates(k,1)),'</nwx>\n',...
            '\t\t\t\t<nwy>',num2str(pageNumber.coordinates(k,2)),'</nwy>\n',...
            '\t\t\t\t<sex>',num2str(pageNumber.coordinates(k,3)),'</sex>\n',...
            '\t\t\t\t<sey>',num2str(pageNumber.coordinates(k,4)),'</sey>\n',...
    	'\t\t\t</location>\n',...
    	'\t\t\t<style>\n',...
            '\t\t\t\t<fontFamily>',pageNumber.style(k).AppliedFont,'</fontFamily>\n'...
            '\t\t\t\t<fontStyle>',pageNumber.style(k).FontStyle,'</fontStyle>\n'...
            '\t\t\t\t<pointSize>',num2str(pageNumber.style(k).PointSize),'</pointSize>\n'...
    	'\t\t\t</style>\n',...
	'\t\t</pageNumber>\n'];
end
% write page number format
xml = [xml, '\t\t<format>\n'];
n = size(pageNumber.format, 2);
for k = 1:n
    xml = [xml,...
	'\t\t\t<item>', pageNumber.format(k).format, '</item>\n'];
end
xml = [xml,'\t\t</format>\n\t</pageNumbers>\n'];

% master page frames
% -------------------
multiWaitbar('Writing XML string','Increment',1/2);

xml = [xml,'\t<masterPageFrames>\n'];
n = size(masterPageFrames.coordinates,1);
for k = 1:n
    xml = [xml,...
	'\t\t<frame>\n',...
    	'\t\t\t<location>\n',...
            '\t\t\t\t<nwx>',num2str(masterPageFrames.coordinates(k,1)),'</nwx>\n',...
            '\t\t\t\t<nwy>',num2str(masterPageFrames.coordinates(k,2)),'</nwy>\n',...
            '\t\t\t\t<sex>',num2str(masterPageFrames.coordinates(k,3)),'</sex>\n',...
            '\t\t\t\t<sey>',num2str(masterPageFrames.coordinates(k,4)),'</sey>\n',...
    	'\t\t\t</location>\n',...
	'\t\t</frame>\n'];
end
xml = [xml,'\t</masterPageFrames>\n'];

multiWaitbar('Writing XML string','Close');



% -------------------
% SHOW
% -------------------
if strcmp(showViz,'show') == 0
    return
end

% page numbers
% -------------------
% display frames boxes
figure('name',url.name,...
    'Color',[hex2dec('ee')/255,hex2dec('ee')/255,hex2dec('ee')/255]);
title('Page numbers locations on master pages');
whitebg([hex2dec('ee')/255,hex2dec('ee')/255,hex2dec('ee')/255]);
set(gca,'DataAspectRatio',[1 1 1]);
axis ij; % flip view
axis off;
% page
rectangle('Position',...
    [-pageSize(2), -pageSize(1)/2, pageSize(2), pageSize(1)],...
    'EdgeColor', [hex2dec('66')/255,hex2dec('66')/255,hex2dec('66')/255],...
    'FaceColor', [hex2dec('aa')/255,hex2dec('aa')/255,hex2dec('aa')/255]);
rectangle('Position',...
    [0, -pageSize(1)/2, pageSize(2), pageSize(1)],...
    'EdgeColor', [hex2dec('66')/255,hex2dec('66')/255,hex2dec('66')/255],...
    'FaceColor', [hex2dec('aa')/255,hex2dec('aa')/255,hex2dec('aa')/255]);
% pagenumbers
n = size(pageNumber.coordinates, 1);
for k = 1:n    
    rectangle('Position',...
        [pageNumber.coordinates(k, 1), pageNumber.coordinates(k, 2),...
        abs(pageNumber.coordinates(k, 3) - pageNumber.coordinates(k, 1)),... 
        abs(pageNumber.coordinates(k, 4) - pageNumber.coordinates(k, 2))],...
        'EdgeColor', 'red');
end


% -------------------
% GET STYLES
% -------------------
function output = get_style(DOM, node, port, property, content)
% from a specific style property (property) defined by a name (content)
% gets its definition (output), given a DOM where to search, 
% a xml node name (CharacterStyle|ParagraphStyle), and whether
% the inofrmation appears as an attribute or a subnode (port = 
% attribute|content)

output = [];

s = DOM.Styles.(['Root' node 'Group']).(node);
n = size(s, 1);
for k = 1:n
    if strcmp(s(k).ATTRIBUTE.Name, content) == 1
        switch port
            case 'attribute'
                if isfield(s(k).ATTRIBUTE, property) == 1
                    output = s(k).ATTRIBUTE.(property);
                else
                    if isfield(s(k), 'Properties') == 1
                        if isfield(s(k).Properties, 'BasedOn') == 1
                            name_parent = s(k).Properties.BasedOn.CONTENT;
                            output = ...
                                get_style(DOM, node, name_parent, property);
                        end
                    end
                end
            case 'content'
                if isfield(s(k), 'Properties') == 1
                    if isfield(s(k).Properties, 'AppliedFont') == 1
                        output = s(k).Properties.AppliedFont.CONTENT;
                    end
                end
        end
    end
end

