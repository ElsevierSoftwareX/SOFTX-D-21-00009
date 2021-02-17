function [] = towers_show(...
    spreads, metadata, url, ...
    docsPerFig, hFigureMain, docRank, ...
    textFaceAlpha, objectClassesShow, tags, addVizMode)
%TOWERS_SHOW Show object boundaries of a single document
% 
% -------------
% INPUT
% -------------
% spreads - geometry data as Matlab variable
%       Note: use docgeo.m to read geometry files
%       Note: for the format see towers_frames
% metadata - file & geometry metadata
% url - structure w/ following fields:
%       url.path - directory path
%       url.documentFileName - document source of the geometry data
%       url.geometryFileName - document geometry data file including
%           extension (json)
% docsPerFig - {'single'} | 'multiple'; number of documents per figure;
%       the 'multiple' choice allows the visualization of a collection of
%       documents on a single figure
% hFigMain - figure handle where the documents are displayed;
%       is the same over multiple calls to this function if documents
%       are to be displayed on the same figure
% docRank.{k,n} - document rank in list of files to be processed
% textFaceAlpha - {0.3} | [0 1]; transparency of text object surfaces
% objectClassesShow - {'Pages','Text','Images','Graphics','Fonts'};
%       classes of objects to display
% tags - object tags, such as table of contents or illustrations
% addVizMode - {'replace'}|'newRange'|'add' : 
%       replace: delete everything
%       newRange: delete data graphics, keep metagraphics
%       add: just add objects to existing visualization, 
%       i.e. no filenames, tags, tick marks, etc.
% 
% -------------
% OUTPUT
% -------------
% hFig - figure handle where the documents are displayed
% hObjectClasses - handle to object classes, such as text or graphic objects
% [name].fig - visualization of frames as Matlab figure
% [name].png - PNG, raster graphics, 150dpi
% [name].eps - EPS, vector graphics, good for print, since scalable
% 
% -------------
% ASSUMPTIONS / LIMITATIONS
% -------------
% - Only polygons with 4 vertices are supported for display.
% - Only exactly one or two pages per spread are supported. The first and
% last spread is assumed to have a single page.
%
% -------------
% REQUIREMENTS
% -------------
% - multiWaitbar
% http://www.mathworks.com/matlabcentral/fileexchange/26589-multi-progress-bar/content/multiWaitbar.m
% 
% -------------
% CREDITS
% -------------
% Vlad Atanasiu, atanasiu@alum.mit.edu, http://alum.mit.edu/www/atanasiu/
% 
% -------------
% LOG
% -------------
% 2016.01.23 - [bug] document volume is the right size and location
%              [bug][mod] various
% 2015.00.00 - [mod] changed name from 'souffleur_show' to 'crystal_show'
% 2014.12.03 - creation


% -------------------
% INITIALIZATION
% -------------------
if nargin < 1 || isempty(spreads) || isempty(fieldnames(spreads))
    return
end

if nargin < 2 || isempty(metadata)
    return
end

if nargin < 3 || isempty(url)
    return
end

% number of documents per figure
if nargin < 4 || isempty(docsPerFig)
    docsPerFig = 'single'; %#ok<NASGU>
end

% figure handle
if nargin < 5 || isempty(hFigureMain)
    hFigureMain = gcf;
end
preferences = getappdata(hFigureMain,'preferences');

% document rank
if nargin < 6 || isempty(docRank)
    docRank.k = 1;
    docRank.n = 1;
end    

% transparency of text object surfaces
if nargin < 7 || isempty(textFaceAlpha)
    textFaceAlpha = preferences.textFaceAlpha;
end

% object classes
if nargin < 8 || isempty(objectClassesShow)
    objectClassesShow = {'Documents','Pages','Text','Images','Graphics'};
end

% get the document rank in the document list
switch docRank.k
    case 1 && docRank.k == docRank.n
        docRank.s = 'firstAndLast';
    case docRank.n
        docRank.s = 'last';
    case 1
        docRank.s = 'first';
    otherwise
        docRank.s = 'middle';
end

% tags
if nargin < 9 || isempty(tags)
    tags = [];
end

% addition mode
if nargin < 10 || isempty(addVizMode)
    addVizMode = 'replace';
end

% handles to class of objects
hObjectClasses = getappdata(hFigureMain,'hObjectClasses');
hFilenames = getappdata(hFigureMain,'hFilenames');
hTags = getappdata(hFigureMain,'hTags');
hTicks = getappdata(hFigureMain,'hTicks');

% distance between two tower floors
floorHeight = preferences.floorHeight;

% quantity of physical spreads in document
n0Spreads = numel(spreads);

% restrict visualization to specific page range
preferences = getappdata(hFigureMain,'preferences');
spreadRange = preferences.spreadRange;
if isempty(spreadRange)
    % show all spreads
    spreadRange = [1 n0Spreads];
end
if spreadRange(2) > n0Spreads
    % avoid drawing out of range
    spreadRange(2) = n0Spreads;
end
if ~(spreadRange(1) == 1 && spreadRange(2) == n0Spreads)
    spreads = spreads(spreadRange(1):spreadRange(2));
end

% start drawing further down in the stack
zShift = spreadRange(1) - 1;
% if strcmp(addVizMode,'add') == 1
%     zShift = spreadRange(1) - 2; % why this?!
% end

% document volume
if numel(metadata.volume) > 3
    vol.x = metadata.volume(3) - metadata.volume(1);
    vol.y = metadata.volume(2) - metadata.volume(4);
else % legacy: only the volume, not its exact location
    vol.x = metadata.volume(2);
    vol.y = metadata.volume(1);
end

% document spacing
preferences = getappdata(hFigureMain,'preferences');
docPadXY = preferences.docPadXY;

% update grid displacement values
grid = getappdata(hFigureMain,'grid');
if grid.yk == 1
    % first document in a row is not displaced on y axis
    vol.x = 0;
    vol.y = - docPadXY;
end
if grid.yk <= grid.ykmax
    % increment row location
    grid.y = grid.y - vol.y - docPadXY;
    grid.yk = grid.yk + 1;
    grid.x = grid.xk1;
    if grid.xk1 + vol.x + docPadXY > grid.xk2
        % get maximal displacement per row
        grid.xk2 = grid.xk1 + vol.x + docPadXY;
    end
else
    % first document in a row
    grid.yk = 2;
    grid.y = 0;
    grid.xk1 = grid.xk2;
    grid.x = grid.xk1;
end
setappdata(hFigureMain,'grid',grid)


% -------------------
% SHOW DOCUMENT GEOMETRY
% -------------------

% labels
objLabels = getappdata(hFigureMain,'labels');
objLabelsSelected = objLabels.selection;

% draw objects
showFrames(...
    spreads, metadata, grid, docRank, floorHeight, ...
    objectClassesShow, hObjectClasses, objLabelsSelected, textFaceAlpha, ...
    zShift, n0Spreads)

if strcmp(addVizMode,'replace') == 1

    % display file names
    showFilenames(floorHeight, grid, metadata, docRank, hFilenames);

    % display tags
    if ~isempty(tags)
        showTags(tags, floorHeight, grid, metadata, docRank, ...
            n0Spreads, hTags);
    end

    % display tick marks
    showTicks(spreads, floorHeight, grid, metadata, docRank, ...
        n0Spreads, hTicks)
end

% memorize default axes limits
setappdata(hFigureMain,'axesLim',...
    [get(gca,'XLim'); get(gca,'YLim'); get(gca,'ZLim')])


% -------------------
% DRAW OBJECT GEOMETRY
% -------------------
function showFrames(...
    spreads, metadata, grid, docRank, floorHeight, ...
    objectClassesShow, hObjectClasses, objLabelsSelected, textFaceAlpha, ...
    zShift, n0Spreads)

% objects
nSpreads = numel(spreads);
nObjectClasses = numel(objectClassesShow);
for o = 1:nObjectClasses

    % documents are constructed separately
    % because their geometry is not given in the spread cells
    if strcmp(objectClassesShow{o},'Documents') == 1
        continue
    end
    
    multiWaitbar(['Building ',objectClassesShow{o},' objects'],0);
    
    % skin
    switch objectClassesShow{o}
        case 'Fonts' % cyan
            ci = 5; % class index
            FaceAlpha = 0;
            EdgeColor = [0 174/255 239/255];
            EdgeAlpha = 0.3;
        case 'Text' % black
            ci = 2;
            FaceAlpha = textFaceAlpha;
            EdgeColor = [0 0 0];
            EdgeAlpha = 0.3; % 0.05
        case 'Graphics' % green
            ci = 4;
            FaceAlpha = 0;
            EdgeColor = [0 .5 0];
            EdgeAlpha = 0.3;
        case 'Images' % blue
            ci = 3;
            FaceAlpha = 0;
            EdgeColor = [0 0 1];
            EdgeAlpha = 0.3;
        case 'Pages' % magenta
            ci = 1;
            FaceAlpha = 0;
            EdgeColor = [236/255 0 140/255];
            EdgeAlpha = 0.3;
        otherwise % black
            ci = 1;
            FaceAlpha = 0;
            EdgeColor = [0 0 0];
            EdgeAlpha = 0.3;
    end
    FaceColor = [0 0 0];
    FaceAlphaLabeled = 0.3;
    
    % group objects by type, so as to manipulate them all at once
    hObjectClasses(docRank.k).(objectClassesShow{o}) = hggroup;
    
    % draw
    objectCounts = metadata.counts(ci);
    % skip documents w/o this object
    if objectCounts == 0
        multiWaitbar(['Building ',objectClassesShow{o},' objects'],'Close');
        continue
    end
    verts = NaN(objectCounts*8,3);
    faces = NaN(objectCounts*4,4);
    alphas = NaN(objectCounts*4,1);
    vertsIdx = 0;
    facesIdx = 0;
    alphasIdx = 0;

    % spreads
    for kSpread = 1:nSpreads
        
        s = spreads(kSpread);

        % skip pages w/o objects
        if isfield(s, objectClassesShow{o}) == 0
            continue
        end

        % objects
        nObjects = numel(s.(objectClassesShow{o}));
        for kObjects = 1:nObjects

            % vertices
            n = numel(s.(objectClassesShow{o})(kObjects).coordinates);
            if n < 2, continue, end
            for k = 1:4
                x = s.(objectClassesShow{o})(kObjects).coordinates(k).x;
                if isstring(x)
                    x = str2double(x);
                end
                y = s.(objectClassesShow{o})(kObjects).coordinates(k).y;
                if isstring(y)
                    y = str2double(y);
                end
                verts(vertsIdx + k,:) = [ ...
                    x + grid.x, ...
                    - y - grid.y, ...
                    - floorHeight*(n0Spreads - kSpread - zShift) ];
                verts(vertsIdx + k + 4,:) = [ ...
                    x + grid.x, ...
                    - y - grid.y, ...
                    - floorHeight*(n0Spreads - kSpread - zShift) ...
                        - floorHeight ];
            end
            
            % faces
            faces(facesIdx + 1: facesIdx + 4,:) = [ ...
                vertsIdx + 1, vertsIdx + 5, vertsIdx + 6, vertsIdx + 2 ;...
                vertsIdx + 2, vertsIdx + 6, vertsIdx + 7, vertsIdx + 3 ;...
                vertsIdx + 3, vertsIdx + 7, vertsIdx + 8, vertsIdx + 4 ;...
                vertsIdx + 4, vertsIdx + 8, vertsIdx + 5, vertsIdx + 1 ];
            
            % face alphas
            a = FaceAlpha;
            if ~isempty(objLabelsSelected)
                ok = logical(sum(contains(objLabelsSelected,...
                    s.(objectClassesShow{o})(kObjects).label)));
                if ok
                    a = FaceAlphaLabeled;
                end
            end
            alphas(alphasIdx + 1: alphasIdx + 4,1) = [a;a;a;a];
            
            % objects
            vertsIdx = vertsIdx + 8;
            facesIdx = facesIdx + 4;
            alphasIdx = alphasIdx + 4;

        end % objects in spread
        
        multiWaitbar(['Building ',objectClassesShow{o},' objects'],...
            'Increment',1/nSpreads);
    end % spreads
    
    % prism
    patch(...
        'Parent',hObjectClasses(docRank.k).(objectClassesShow{o}),...
        'Faces',faces,...
        'Vertices',verts,...
        'FaceAlpha','flat',...
        'FaceVertexAlphaData',alphas,...
        'AlphaDataMapping','none',...
        'EdgeColor',EdgeColor,...
        'EdgeAlpha',EdgeAlpha,...
        'FaceVertexCData',FaceColor,...
        'FaceColor','flat');
%         'UserData',[docRank.k,kPage],...
%         'ButtonDownFcn',@towers_link_pdf);
    
    drawnow
    multiWaitbar(['Building ',objectClassesShow{o},' objects'],'Close');
end

% ---
% draw document volumes
% ---
if sum(strcmp(objectClassesShow,'Documents')) == 1
    
    % skin
    FaceAlpha = 0;
    EdgeColor = [1 0 0];
    EdgeAlpha = 0.3;

    % group objects by type, so as to manipulate them all at once
    hObjectClasses(docRank.k).Documents = hggroup;
    hObjectClasses(docRank.k).Documents.Visible = 'off';

    % geometry
    vol.z = -floorHeight * n0Spreads;
    if numel(metadata.volume) > 3
        vol.n = metadata.volume(1);
        vol.e = metadata.volume(2);
        vol.s = metadata.volume(3);
        vol.w = metadata.volume(4);
        
        % vertices
        verts = [...
            grid.x + vol.n,     -grid.y - vol.w,     0 ;...
            grid.x + vol.n,     -grid.y - vol.e,     0 ;...
            grid.x + vol.s,     -grid.y - vol.e,     0 ;...
            grid.x + vol.s,     -grid.y - vol.w,     0 ;...
            grid.x + vol.n,     -grid.y - vol.w,     vol.z ;...
            grid.x + vol.n,     -grid.y - vol.e,     vol.z ;...
            grid.x + vol.s,     -grid.y - vol.e,     vol.z ;...
            grid.x + vol.s,     -grid.y - vol.w,     vol.z ...
            ];
        
    else % legacy: only the volume, not its exact location
        vol.w = metadata.volume(2);
        vol.h = metadata.volume(1);
        
        % vertices
        verts = [...
            grid.x,             -grid.y - vol.h/2,   0 ;...
            grid.x + vol.w,     -grid.y - vol.h/2,   0 ;...
            grid.x + vol.w,     -grid.y + vol.h/2,   0 ;...
            grid.x,             -grid.y + vol.h/2,   0 ;...
            grid.x,             -grid.y - vol.h/2,   vol.z ;...
            grid.x + vol.w,     -grid.y - vol.h/2,   vol.z ;...
            grid.x + vol.w,     -grid.y + vol.h/2,   vol.z ;...
            grid.x,             -grid.y + vol.h/2,   vol.z ...
            ];
    end

    % faces
    faces = [ ...
        1, 5, 6, 2 ;...
        2, 6, 7, 3 ;...
        3, 7, 8, 4 ;...
        4, 8, 5, 1 ];

    % prism
    patch(...
        'Parent',hObjectClasses(docRank.k).Documents,...
        'Faces',faces,...
        'Vertices',verts,...
        'FaceColor',[0 0 0],...
        'FaceAlpha',FaceAlpha,...
        'EdgeColor',EdgeColor,...
        'EdgeAlpha',EdgeAlpha);
%         'UserData',[docRank.k,kPage],...
%         'ButtonDownFcn',@towers_link_pdf);
    drawnow
end

% save object classes to figure
handles = guidata(gcf);
setappdata(handles.figureMain,'hObjectClasses',hObjectClasses)


% -------------------
% DISPLAY FILENAMES
% -------------------
function showFilenames(floorHeight, grid, metadata, docRank, hFilenames)

% construct a placeholder for file name tags
hFilenames(docRank.k).Filenames = hggroup;

% location of filenames next to tower, top left
if numel(metadata.volume) > 3
    shiftX = metadata.volume(1);
    shiftY = metadata.volume(4);
else % legacy: only the volume, not its exact location
    shiftX = 0;
    shiftY = metadata.volume(1)/2;
end

% display file name
s = metadata.filename;
s = strrep(s,'_','\_'); % escape reserved characters
d = floorHeight; % displacement from object
x = grid.x + shiftX + d;
y = - grid.y - shiftY - d;
z = floorHeight;
ht = text(...
    'Parent',hFilenames(docRank.k).Filenames,...
    'String',s,...
    'FontWeight','bold',...
    'Color',[1 1 1],...
    'BackgroundColor',[0 0 0],...
    'UserData',[docRank.k,1],...
    'Position',[x,y,z],...
    'HorizontalAlignment','right');
    % in UserData we store url index into metadata and page number
    % for the display of the pdf

% add link to original document
if isfield(metadata,'url') && ~isempty(metadata.url)
    ht.ButtonDownFcn = @towers_link_pdf;
end
drawnow

% save object classes to figure
handles = guidata(gcf);
setappdata(handles.figureMain,'hFilenames',hFilenames)


% -------------------
% DISPLAY TAGS
% -------------------
function showTags(tags, floorHeight, grid, metadata, docRank, ...
    nSpreads, hTags)

% construct a placeholder for tag classes
handles = guidata(gcf);

% location of tags next to tower, top left
if numel(metadata.volume) > 3
    shiftX = metadata.volume(1);
    shiftY = metadata.volume(4);
else % legacy: only the volume, not its exact location
    shiftX = 0;
    shiftY = metadata.volume(1)/2;
end
d = floorHeight; % displacement from object
x = grid.x + shiftX + d;
y = -grid.y - shiftY - d;

% display tags
nTagClasses = length(tags);
for kTagClasses = 1:nTagClasses % tag class

    % convert json to Matlab structure
%     tagClassData = tags{kTagClasses};
%     tagClassName = tagClassData{1};
    if isstring(tags{kTagClasses}(1))
        % the following is needed because of an apparent bug:
        % construct ["A",[["B",1]]] is read as 
        %   1×3 string array
        %   "A"    "B"    "1"
        % while it should be read as
        %   1×2 cell array
        %   {'A'}    {1×2 string}
        tagClassData = { char(tags{kTagClasses}(1)), ...
            [tags{kTagClasses}(2),tags{kTagClasses}(3)] };
    else
        tagClassData = tags{kTagClasses};
    end
    tagClassName = tagClassData{1};

    % add tag class names to gui popupmenu
    h = handles.popupmenuTags;
    n = length(h.String);
    h.String{n+1} = tagClassName;
    for k = 1:n
        if strcmp(h.String(k),tagClassName) == 1
            h.String(n+1) = [];
        end
    end

    % object tag (need to replace spaces by some symbol)
    objectTag = strrep(tagClassName,' ','_');
    
    % group objects by type, so as to manipulate them all at once
    hTags(docRank.k).Tags.(objectTag) = hggroup;

    nClassData = size(tagClassData{2},1);
    for kClassData = 1:nClassData % tag item

        % tag attributes
        tagName = tagClassData{2}(kClassData,1);
        tagValue = str2double(tagClassData{2}(kClassData,2));
        tagSpread = floor(tagValue/2) + 1; % convert page to spread number

        % display tag
        s = strjoin([tagName,' \color[rgb]{.5,.5,.5} \bf[ ',num2str(tagValue),' ]\rm']);
        z = -floorHeight*(nSpreads - tagSpread) - floorHeight/2;
        ht = text(...
            'String',s,...
            'UserData',[docRank.k,tagValue],...
            'Position',[x,y,z],...
            'HorizontalAlignment','right',...
            'Parent',hTags(docRank.k).Tags.(objectTag));

        % add link to original document
        if isfield(metadata,'url') && ~isempty(metadata.url)
            ht.ButtonDownFcn = @towers_link_pdf;
        end
    end
    
    % show only the first tag class
    visibility = 'off';
    if kTagClasses == 1
        visibility = 'on';
        activeClass = objectTag;
    end
    hTags(docRank.k).Tags.(objectTag).Visible = visibility;
    
    % memorize class name
    hTags(docRank.k).Tags.(objectTag).UserData = tagClassName;
end
drawnow

% memorize displayed tags class
hTags(docRank.k).Tags.active = activeClass;
handles.popupmenuTags.Value = 2;

% save data
setappdata(handles.figureMain,'hTags',hTags)
guidata(gcf,handles)


% -------------------
% DISPLAY TICK MARKS
% -------------------
function showTicks(spreads, floorHeight, grid, metadata, docRank, ...
    nSpreads, hTicks)

% get number of pages per spread
n = numel(spreads);
if n == 1
    % we count the page number per spread from the second spread, since
    % usually the first spread has only one page per spread; however, we
    % need to account for documents with a single spread
    pagesPerSpread = numel(spreads(1).Pages);
else
    pagesPerSpread = numel(spreads(2).Pages);
end

% group objects, so as to manipulate them all at once
hTicks(docRank.k).Ticks = hggroup;

% location of ticks next to tower, bottom right
if numel(metadata.volume) > 3
    shiftX = metadata.volume(3);
    shiftY = metadata.volume(2);
else % legacy: only the volume, not its exact location
    shiftX = 0;
    shiftY = metadata.volume(1)/2;
end

% display tick marks
nPages = metadata.counts(1);
kPage = 1;

% first spread
s = [' \color[rgb]{.5,.5,.5}- ',num2str(1),'\rm'];
d = floorHeight; % displacement from object
x = grid.x + shiftX - d;
y = - grid.y - shiftY + d;
z = -floorHeight*(nSpreads - 1) - d/2;
text(...
    'String',s,...
    'Position',[x,y,z],...
    'HorizontalAlignment','left',...
    'Parent',hTicks(docRank.k).Ticks,...
    'UserData',[docRank.k,1],...
    'ButtonDownFcn',@towers_link_pdf);

% intermediate spreads
step = 1;
for kTick = (step + 1):step:nSpreads

    kPage = (kTick-1) * pagesPerSpread; % page number
    if rem(kPage,10) == 0
        % display even page numer on spread every other tick mark
        s = [' \color[rgb]{.5,.5,.5}- ',num2str(kPage),'\rm'];
    else
        % display the tick mark w/o page number
        s = ' \color[rgb]{.5,.5,.5}- \rm';
    end
    z = -floorHeight*(nSpreads - kTick) - d/2;
    text(...
        'String',s,...
        'Position',[x,y,z],...
        'HorizontalAlignment','left',...
        'Parent',hTicks(docRank.k).Ticks,...
        'UserData',[docRank.k,kPage],...
        'ButtonDownFcn',@towers_link_pdf);
end

% last spread
if rem(kPage,10) ~= 0
    s = [' \color[rgb]{.5,.5,.5}- ',num2str(nPages),'\rm'];
    z = -d/2;
    text(...
        'String',s,...
        'Position',[x,y,z],...
        'HorizontalAlignment','left',...
        'Parent',hTicks(docRank.k).Ticks,...
        'UserData',[docRank.k,nPages],...
        'ButtonDownFcn',@towers_link_pdf);
end
drawnow

% save data
handles = guidata(gcf);
setappdata(handles.figureMain,'hTicks',hTicks)

