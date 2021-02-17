function xml = idmlgeo_frames(url, showViz, saveViz, saveFile, getPolygons, onlyGeoJson)
%IDMLGEO_FRAMES Extract frame & page boundaries from InDesign IDML files.
% 
% -------------
% INPUT
% -------------
% url - URL of IDML unzipped directory
% showViz {'show'} | 'noshow' - visualize some of the results
% saveViz {'save'} | 'nosave' - save the visualizations
% saveFile {'save'} | 'nosave' - save the results to XML & JSON files
% getPolygons {false} | true - whether to extract Polygons or not; 
%       see Limitations below for implications of this option
% onlyGeoJson {true} | false - save only to JSON, i.e. no XML, MAT
% 
% -------------
% OUTPUT
% -------------
% xml - data on frames and page boundaries
% [name] - frames.mat - frames coordinates of each spread;
%     saved in matlab format, useful for example for visualizing
%     individual documents or collections; saved within the 
%     folder contianing the IDML file that is processed
% [name] - frames.xml - as above but in XML format
% [name] - frames.json - as above but in JSON format
% 
% if showPix = 'show':
% [name].fig - visualization of frames as Matlab figure
% [name].eps - idem in Encapsulated Post Script;
%     useful to insert in print documents
% [name].png - idem in PNG; useful for web display
% [name] - w pages.[fig,eps,png] - shows frames and page boundaries
% 
% -------------
% LIMITATIONS
% -------------
% - Supported frame types Page, TextFrame, Rectangle, Polygon, Oval.
%
%   NOTE: You shouldn't extract geometry of frames with other than four 
%   vertices if you visualize the data with Crystal - it won't work. 
%   The reason is that the json reader function 'loadjson' considers 
%   numerical arrays as having equal number of items per row, so
%   that a polygonal frame will usually produce an error. However,
%   for visualization in Crystal for web browsers it is ok to extract 
%   polygonal frames.
%
%   HACK: put quotes after the object coordinates to make loadjson accept
%   polygons. Ex: [ [0,10,10,20,20,""],[0,10,10,20,20,30,30,""] ]
%
% - Frames can have any number of anchors and be rotated by any angle.
%   But see above about when you can use polygonal frames.
% - Transformations are supported on only the supported objects.
% - Master Pages are not supported.
% - Frames are quite limited object descriptors: they don't tell if
%     there is anything inside, where it is, and if it is visible. 
%     Furthermore, often there is no way to know these things until 
%     the document is set, i.e. it doesn't result from the IDML file.
%     For example, there are many factors that can affect the 
%     continuation of a story across frames: fonts, justification, 
%     hyphenation, kerning, tracking, leading, margins, etc.
% - See also limitations in idmlgeo.m.
% 
% -------------
% TO DEVELOPERS
% -------------
% New features should consider transformations, inheritance, and master pages.
%
% -------------
% JSON SAMPLE FORMAT
% -------------
% IMPORTANT: See the help file for latest format specifications.
%
% jsondata ({
% 	"geometry":
% 	[
% 		{[
% 			{[0,0.0,0.0,595.0,0.0,595.0,793.0,0.0,793.0,0.0,0.0]},
% 			{[1,217.692,101.85832,335.37054,101.85832,335.37054,109.55744,217.692,109.55744,217.692,101.85832]},
% 			{[2,32.7061,657.37036,68.5716,657.37036,68.5716,657.37036,32.7061,657.37036,32.7061,657.37036]},
% 			{[3,464.7561,48.2686,552.6937,48.2686,552.6937,107.8247,464.7561,107.8247,464.7561,48.2686]}
% 		]},
% 		{[
% 			{[0,0.0,0.0,595.0,0.0,595.0,793.0,0.0,793.0,0.0,0.0]},
% 			{[1,217.692,101.85832,335.37054,101.85832,335.37054,109.55744,217.692,109.55744,217.692,101.85832]},
% 			{[2,32.7061,657.37036,68.5716,657.37036,68.5716,657.37036,32.7061,657.37036,32.7061,657.37036]},
% 			{[3,464.7561,48.2686,552.6937,48.2686,552.6937,107.8247,464.7561,107.8247,464.7561,48.2686]}
% 		]}
% 	],
% 	"metadata":
% 	{
% 		"filename":"atanasiu2013expertbytes.pdf",
% 		"url":"file:///Users/ana/Documents/_creation/Code/MATLAB/gx/docviz/data/real/xb/pdf/wo markers/atanasiu2013expertbytes.pdf",
% 		"volume":[882.0, 666.0, 208.0],
% 		"counts":[208, 2813, 94, 1150, 0],
% 		"objects":[[0,"Pages"],[1,"Text"],[2,"Images"],[3,"Graphics"],[4,"Fonts"]],
% 		"legend":"object type; bounding box coordinates: n * (x, y); font name; font size; font fill color: rgba"
% 	}
% })
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
% 2015.12.30 - [fix] converts polygonal shapes to bounding boxes
% 2014.12.03 - [mod] made visuaization to an independent function
% 2014.07.04-17 - [new] new gui
%            - [new] gets locations for pages, rectangles, polygons, ovals
%            - [new] takes into account groups
%            - [fix] takes into account transformations
% 2013.10.03 - creation
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
    if url == 0
        return
    end
end
% get directory path & name
if isfield(url, 'dir') == 0
    t = url; clear url; url.dir = t;
    url = url_chop(url);
end
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
    getPolygons = false;
end
if nargin < 6 || isempty(onlyGeoJson)
    onlyGeoJson = true;
end

% transparency of text objects surfaces
textFaceAlpha = 0.3;

closeFigs = true;
if strcmp(showViz,'show') == 1
    closeFigs = false;
end

% WARNING: if the following frameType variables are modified, 
% then change them also in the crystal_show file
frameTypeInDesign = {'Page','TextFrame','Rectangle','Oval','Polygon'};
frameTypeBasic = {'Page','Text','Graphics'};
frameTypeBasicId = {'0','1','3'};

% object counter
counts.Page = 0;
counts.Text = 0;
counts.Images = 0;
counts.Graphics = 0;
counts.Fonts = 0;

% document volume
volume.n = [];
volume.e = [];
volume.s = [];
volume.w = [];


% -------------------
% MASTER PAGES
% -------------------

% Extraction algorithm for frames on master pages:
% - for each spread
%     - for each page
%         - get the name of the page's master page: Spread > Page: AppliedMaster
%         - read the frames in the master page: dir = MasterSpreads
%         - remove those frames mentioned in Page: OverrideList
%         - apply transform: Page: MasterPageTransform
%         
% * include support for grouping in the above algorithm
% * take into consideration the page size of master pages


% -------------------
% LOOP IDML OBJECTS
% -------------------

% Format:
% masterSpreadsAvailable.masterName(pageIndex).frameName.coordinates.(x,y)

% get spreads names & sequence
DOM.Designmap = xml_read([url.dir filesep 'designmap.xml']);
DOM.Designmap = DOM.Designmap.idPkg_COLON_Spread;
n1 = numel(DOM.Designmap);
multiWaitbar(['Scanning ',num2str(n1),' spreads'],0);

% loop spreads
% -------------------
for k1 = 1:n1
    multiWaitbar(['Scanning ',num2str(n1),' spreads'],'Increment',1/n1);
    
    % read DOM
    DOM.Spreads = xml_read([url.dir filesep DOM.Designmap(k1).ATTRIBUTE.src]);
    SpreadRoot = DOM.Spreads.Spread;

    % loop pages
    % -------------------
    n2 = SpreadRoot.ATTRIBUTE.PageCount;

    for k2 = 1:n2

        % get page coordinates
        % -------------------
        
        % page extremities IDML: top y, x; bottom y, x
        % positive coordinates direction is down and right
        f = SpreadRoot.(frameTypeInDesign{1})(k2);
        coords = str2num(f.ATTRIBUTE.GeometricBounds);

        % get object transform from transform matrix;
        % only translations are supported for pages
        t = str2num(f.ATTRIBUTE.ItemTransform);
        translate = [];
        translate.x = t(5);
        translate.y = t(6);

        % NOTE: y and x InDesign coordinates are swapped
        % so as to convert to the Matlab coordinates system
        %
        % InDesign                  Matlab
        %
        % o ---> x2              y1 <--- o
        % |                              |
        % |                ->            |
        % v                              v
        % y1     .(y3,x4)       .(y3,x4) x2
        
        frameType = convertFrameType(frameTypeInDesign{1});
        spreads(k1).(frameType)(k2).coordinates(1).x = translate.y + coords(1);
        spreads(k1).(frameType)(k2).coordinates(1).y = translate.x + coords(2);
        spreads(k1).(frameType)(k2).coordinates(2).x = translate.y + coords(3);
        spreads(k1).(frameType)(k2).coordinates(2).y = translate.x + coords(2);
        spreads(k1).(frameType)(k2).coordinates(3).x = translate.y + coords(3);
        spreads(k1).(frameType)(k2).coordinates(3).y = translate.x + coords(4);
        spreads(k1).(frameType)(k2).coordinates(4).x = translate.y + coords(1);
        spreads(k1).(frameType)(k2).coordinates(4).y = translate.x + coords(4);
        
        % update document volume
        if isempty(volume.n) || volume.n > translate.y + coords(1)
            volume.n = translate.y + coords(1); % top
        end
        if isempty(volume.e) || volume.e < translate.x + coords(4)
            volume.e = translate.x + coords(4); % right
        end
        if isempty(volume.s) || volume.s < translate.y + coords(3)
            volume.s = translate.y + coords(3); % bottom
        end
        if isempty(volume.w) || volume.w > translate.x + coords(2)
            volume.w = translate.x + coords(2); % left
        end
        
        % get excentricity
        
%         % get frames from master pages
%         % -------------------
% 
%         % skip if ShowMasterItems false
%         % set masterName & loop pageIndex
%         % if frameName already in masterSpreadsUsed skip
%         % if frameName on exclusion list skip
%         % masterSpreadsUsed = frameName.coordinates.(x,y)
% 
%         % masterSpreadsAvailable.masterName(pageIndex).frameName.coordinates.(x,y)
%         % masterSpreadsUsed
% 
%         % skip page if no master page items should be shown
%         if strcmp(SpreadRoot.ATTRIBUTE.ShowMasterItems,'false') == 1
%             continue
%         end
%         
%         % set excluded frames
%         excludedFrames = SpreadRoot.(frameTypeInDesign{1})(k2).ATTRIBUTE.OverrideList;
%         excludedFrames = strsplit(excludedFrames,' ');
% 
%         masterName = f.ATTRIBUTE.AppliedMaster;
%         % skip if master already in used list
%         if isfield(masterSpreadsUsed, masterName) == 1
%             continue
%         end
        
        
    end
        
%     % get frames from master pages
%     % -------------------
%     
%     % All frames are extracted even if they are not used - 
%     % it's faster than to do this for each spread
%     
%     % Elements for an algorithm
%     %
%     % Spread:ShowMasterItems      VISIBILITY
%     %     -> show/noshow of master page items
%     % Spread:Pages:AppliedMaster  NAME
%     %     -> specifies the MasterSpread
%     % Spread:Pages                INDEX
%     %     -> specifies which page of the MasterSpread is used
%     % MasterSpread:Page           MASK
%     %     -> selects all frames which overlap this page
%     % MasterItems                 DUPLICATES
%     %     -> delete duplicates from extracted master page items
%     % Spread:Page:OverridesList   EXCLUSION
%     %     -> specifies which frames are excluded
%     
%     multiWaitbar('Getting master pages',0);
% 
%     for k2 = 1:n2
%         multiWaitbar('Getting master pages','Increment',1/n2);
% 
%         % read master page data
%         DOM.MasterSpreads = xml_read([url.dir filesep ...
%             'MasterSpreads/MasterSpread_' ...
%             SpreadRoot.(frameTypeInDesign{1})(k2).ATTRIBUTE.AppliedMaster...
%             '.xml']);
%         MasterSpreadRoot = DOM.MasterSpreads.MasterSpread;
% 
%         % skip page if no master page items should be shown
%         if strcmp(MasterSpreadRoot.ATTRIBUTE.ShowMasterItems,'false') == 1
%             continue
%         end
%         
%         % set excluded frames
%         excludedFrames = SpreadRoot.(frameTypeInDesign{1})(k2).ATTRIBUTE.OverrideList;
%         excludedFrames = strsplit(excludedFrames,' ');
% 
%         % get frames
%         groupTransform = [1 0 0 1 0 0];
%         spreads = getFrames( groupTransform, ...
%             frameTypeInDesign, MasterSpreadRoot, spreads, k1, excludedFrames );
%         
%     end
%     multiWaitbar('Getting master pages','Close');
    
    % loop various frame types
    % -------------------
    groupTransform = [1 0 0 1 0 0];
    spreads = getFrames( groupTransform, ...
        frameTypeInDesign, SpreadRoot, spreads, k1, [], getPolygons );

end
multiWaitbar(['Scanning ',num2str(n1),' spreads'],'Close');

if onlyGeoJson == false
    % save frames in Matlab .mat format
    save([url.path, url.name,' - frames.mat'],'spreads')
end


% -------------------
% CREATE XML & JSON OUTPUTS
% -------------------

xml = '';
json = '';
n1 = numel(spreads);
multiWaitbar('Preparing output files',0);
% spreads
for k1 = 1:n1
    multiWaitbar('Preparing output files','Increment',1/n1);
    s = spreads(k1);
    if onlyGeoJson == false
        xml = [xml,'\t\t<Spread>\n'];
    end
    json = [json,'\t\t[\n'];

    % frames
    n2 = numel(frameTypeBasic);
    for k2 = 1:n2
        % skip spreads w/o frames
        if isfield(s, frameTypeBasic{k2}) == 0
            continue
        end
        
        n3 = numel(s.(frameTypeBasic{k2}));
        counts.(frameTypeBasic{k2}) = counts.(frameTypeBasic{k2}) + n3;
        for k3 = 1:n3
            if onlyGeoJson == false
                xml = [xml,...
                    '\t\t\t<',(frameTypeBasic{k2}),'>\n',...
                    '\t\t\t\t<label>0</label>\n',...
                    '\t\t\t\t<location>\n'];
            end
            json = [json,...
                '\t\t\t[',frameTypeBasicId{k2},',0,'];
            
            n4 = numel(s.(frameTypeBasic{k2})(k3).coordinates);
            for k4 = 1:n4
                if onlyGeoJson == false
                    xml = [xml,...
                        '\t\t\t\t\t<y',num2str(k4),'>',...
                            num2str(s.(frameTypeBasic{k2})(k3).coordinates(k4).y),...
                            '</y',num2str(k4),'>\n',...
                        '\t\t\t\t\t<x',num2str(k4),'>',...
                            num2str(s.(frameTypeBasic{k2})(k3).coordinates(k4).x),...
                            '</x',num2str(k4),'>\n'];
                end
                json = [json,...
                        num2str(s.(frameTypeBasic{k2})(k3).coordinates(k4).y),',',...
                        num2str(s.(frameTypeBasic{k2})(k3).coordinates(k4).x),','];
            end
            if onlyGeoJson == false
                xml = [xml,...
                    '\t\t\t\t</location>\n',...
                    '\t\t\t</',(frameTypeBasic{k2}),'>\n'];
            end
            json = [json(1:end-1),'],\n'];
            % hack: make loadjson accept polygons
%             json = [json(1:end-1),',""],\n'];
        end
    end
    if onlyGeoJson == false
        xml = [xml,'\t\t</Spread>\n'];
    end
    json = [json(1:end-3),'\n\t\t],\n'];
end
json = [json(1:end-3),'\n'];

if onlyGeoJson == false
    xml = [...
        '<?xml version="1.0" encoding="UTF-8"?>\n'...
        '<!-- Coordinates origin: center of the doublepage. -->\n'...
        '<InDesignInfo '...
        'xmlns="." '...
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '...
        'xsi:schemaLocation=". indesign_info.xsd">\n'...
        '\t<Spreads>\n',...
        xml,...
        '\t</Spreads>\n',...
        '\t<metadata>',...
            '\t\t<fileName>',url.name,'</fileName>\n',...
            '\t\t<url>',url.path,'</url>\n',...
            '\t\t<volume>',...
                num2str(volume.n),', ',...
                num2str(volume.e),', ',...
                num2str(volume.s),', ',...
                num2str(volume.w),', ',...
                num2str(counts.Page),'</volume>\n',...
            '\t\t<counts>',...
                num2str(counts.Page),', ',...
                num2str(counts.Text),', NaN, ',...
                num2str(counts.Graphics),'</counts>,\n',...
            '\t\t<objects>\n'...
                '\t\t\t<Pages>0</Pages>\n'...
                '\t\t\t<Text>1</Pages>\n'...
                '\t\t\t<Graphics>3</Pages>\n'...
            '\t\t</objects>\n'...
            '\t\t<legend>'...
            'geometry: object type, bounding box coordinates (n * (y, x)), font name, font size, font fill color (rgba); '...
            'volume: top, right, bottom, left bounding volume coordinates</legend>\n',...
        '\t</metadata>\n',...
        '</InDesignInfo>'];
end
json = [...
    'jsondata ({\n',...
        '\t"geometry":\n',...
        '\t[\n',...
        '\t\t"",\n',...
        json,...
        '\t],\n',...
        '\t"metadata":\n',...
        '\t{\n',...
            '\t\t"filename":"',url.name,'",\n',...
            '\t\t"url":"',url.path,'",\n',...
    		'\t\t"volume":[',...
                num2str(volume.n,'%.4f'),', ',...
                num2str(volume.e,'%.4f'),', ',...
                num2str(volume.s,'%.4f'),', ',...
                num2str(volume.w,'%.4f'),', ',...
                num2str(counts.Page),'],\n',...
    		'\t\t"counts":[',...
                num2str(counts.Page),', ',...
                num2str(counts.Text),', ',...
                num2str(counts.Images),', ',...
                num2str(counts.Graphics),', ',...
                num2str(counts.Fonts),'],\n',...
    		'\t\t"objects":[[0,"Pages"],[1,"Text"],[2,"Images"],[3,"Graphics"],[4,"Fonts"]],\n',...
    		'\t\t"labels":[[0,"Unlabeled"]],\n',...
    		'\t\t"legend":',...
                '"geometry: object type, bounding box coordinates (n * (y, x)), font name, font size, font fill color (rgba); ',...
                'volume: top, right, bottom, left bounding volume coordinates"\n',...
        '\t}\n',...
    '})'];
multiWaitbar('Preparing output files','Close');

% save xml to file
if strcmp(saveFile,'save') == 1
    if onlyGeoJson == false
        fid = fopen([url.path, url.name,' - frames.xml'],'w');
        fprintf(fid,xml,'%s');
        fclose(fid);
    end

    fid = fopen([url.path, url.name,' - frames.json'],'w');
    fprintf(fid,json,'%s');
    fclose(fid);
end

% show frames
if strcmp(showViz,'show') == 1
%     souffleur_show(spreads, url, frameTypeBasic, closeFigs, saveViz, ...
%         textFaceAlpha) % old function
    crystal_show(spreads, [], url, [], [], [], textFaceAlpha)
end



% -------------------
% use basic frame names
% -------------------

function frameTypeInDesign = convertFrameType(frameTypeInDesign)

switch frameTypeInDesign
    case 'TextFrame'
        frameTypeInDesign = 'Text';
    case 'Page'
        frameTypeInDesign = 'Page';
    otherwise
        frameTypeInDesign = 'Graphics';
end


% -------------------
% extract frame coordinates from objects and groups of objects
% -------------------

function [spreads, groupTransform] = getFrames( groupTransform, ...
    frameTypeInDesign, SpreadRoot, spreads, k1, excludedFrames, getPolygons )

% change transform data from IDML vector format to this matrix format
g = horzcat(reshape(groupTransform,2,3)', [0; 0; 1]);

% loop types of frames
% -------------------
n2 = numel(frameTypeInDesign);
for k2 = 2:n2

    % skip pages w/o frames
    if isfield(SpreadRoot, frameTypeInDesign{k2}) == 0
        continue
    end
    % avoid deleting frame object in output structure if looping groups
    frameType = convertFrameType(frameTypeInDesign{k2});
    if isfield(spreads(k1), frameType) == 0
        spreads(k1).(frameType) = [];
    end

    % loop frames
    % -------------------
    n3 = numel(SpreadRoot.(frameTypeInDesign{k2}));
%     multiWaitbar(['Getting frames ' num2str(k2) '/2'],0);

    for k3 = 1:n3
%         multiWaitbar(...
%             ['Getting frames ' num2str(k2) '/2'],'Increment',1/n3);

        % InDesign Transformation Matrix
        % ---
        % ItemTransform: [a1 b1 a2 b2 a3 (x translation) b3 (y trans.)]
        % Page: GeometricBounds: top-left, bottom-right; y, x
        % Frame: Anchor: NW SW SE NE; x, y
        % positive direction is down and right
        % path direction is counterclockwise
        % ---
        % Fromula (= matrix multiplication):
        %	xTransformed = x * t(1) + y * t(3) + 1 * t(5);
        %	yTransformed = x * t(2) + y * t(4) + 1 * t(6);
        % ---
        % Ref: 
        % Autret - Coordinate Spaces and Transformations in InDesign.pdf
        % IDML Specification CS6.pdf

        f = SpreadRoot.(frameTypeInDesign{k2})(k3);
        
        % skip excluded frames (applies to frames of master pages)
        skipFrame = false;
        n4 = numel(excludedFrames);
        for k4 = 1:n4
            if strcmp(f.ATTRIBUTE.Self, excludedFrames{k4}) == 1
                skipFrame = true;
                break
            end
        end
        if skipFrame == true
            continue
        end

        % apply group transform on item transform
        t = str2num(f.ATTRIBUTE.ItemTransform);
        t = horzcat(reshape(t,2,3)', [0; 0; 1]);
        t = t * g;
        
        % apply transform on item coordinates
        p = f.Properties.PathGeometry.GeometryPathType;
        n4 = size(p,1);
        
        for k4 = 1:n4
            % skip items w/o anchors
            if isfield(p(k4).PathPointArray, 'PathPointType') == 0
                continue
            end
            
            j = size(spreads(k1).(frameType), 2) + 1;
            q = p(k4).PathPointArray.PathPointType;
            n5 = size(q,1);

            % get coordinates
            coord = zeros(n5,3);
            for k5 = 1:n5
                c = str2num(q(k5).ATTRIBUTE.Anchor);
                coord(k5,:) = [c(1) c(2) 1] * t;
            end
            
            % reduce polygon to bounding box
            if getPolygons == false
                
                % extrema
                bb.n = min(coord(:,2));
                bb.s = max(coord(:,2));
                bb.w = min(coord(:,1));
                bb.e = max(coord(:,1));
                
                % vertices
                clear coord;
                coord = [...
                    bb.w, bb.n; ...
                    bb.e, bb.n; ...
                    bb.e, bb.s; ...
                    bb.w, bb.s ];
            end
            
            % memorize coordinates
            n6 = size(coord,1);
            for k6 = 1:n6
                % rotate by 90 deg to accommodate Crystal visualizer
                spreads(k1).(frameType)(j).coordinates(k6).y = coord(k6,1);
                spreads(k1).(frameType)(j).coordinates(k6).x = coord(k6,2);
            end
        end
    end
%     multiWaitbar(['Getting frames ' num2str(k2) '/2'],'Close');
end

% loop groups of objects
% -------------------

% skip pages w/o groups
if isfield(SpreadRoot, 'Group') == 0
    return
end

n2 = numel(SpreadRoot.Group);
% multiWaitbar('Getting groups',0);

for k2 = 1:n2
%     multiWaitbar('Getting groups','Increment',1/n2);

    % get this group transform
    gItem = str2num(SpreadRoot.('Group')(k2).ATTRIBUTE.ItemTransform);
    gItem = horzcat(reshape(gItem,2,3)', [0; 0; 1]);
    
    % apply group transform of higher group level
    gItem = gItem * g;
    % convert to IDML vectorized format
    gItem = reshape(gItem(:,1:2)',1,6);
    
    % look for frames one DOM level deeper
    spreads = getFrames( gItem, ...
        frameTypeInDesign, SpreadRoot.('Group')(k2), spreads, k1, ...
        excludedFrames, getPolygons );
end
% multiWaitbar('Getting groups','Close');


