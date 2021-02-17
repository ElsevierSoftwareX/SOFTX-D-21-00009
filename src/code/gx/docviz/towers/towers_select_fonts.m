function towers_select_fonts()
%TOWERS_SELECT_FONTS Select specific fonts in document
%
% -------------
% CREDITS
% -------------
% Vlad Atanasiu
% atanasiu@alum.mit.edu
% http://alum.mit.edu/www/atanasiu/
% 
% -------------
% LOG
% -------------
% 2015.05.26 - creation

% get list of unique font attributes
handles = guihandles(gcf);
fontsSingletons = getappdata(handles.figureMain,'fontsSingletons');

% construct color string
sColor = {};
nColor = size(fontsSingletons.color,1);
for kColor = nColor:-1:1

    r = fontsSingletons.color(kColor,1);
    % delimitator
    if r < 10
        dr = '  ';
    elseif r < 100
        dr = ' ';
    else
        dr = '';
    end
    
    g = fontsSingletons.color(kColor,2);
    if g < 10
        dg = '  ';
    elseif g < 100
        dg = ' ';
    else
        dg = '';
    end
    
    b = fontsSingletons.color(kColor,3);
    if b < 10
        db = '  ';
    elseif b < 100
        db = ' ';
    else
        db = '';
    end
    
    sColor{kColor} = [dr,num2str(r),' ',dg,num2str(g),' ',db,num2str(b)];
end

% build GUI
handles = guihandles(gcf);
hFigureMain = handles.figureMain;
preferences = getappdata(hFigureMain,'preferences');
color = preferences.color;
figX = hFigureMain.Position(1);
figY = hFigureMain.Position(2);
figW = 570;
figH = 400;
fontsSelectionIdx = getappdata(hFigureMain,'fontsSelectionIdx');

hFigureFonts = figure(...
    'Tag','figureFonts',...
    'Name','Font Filter',...
    'NumberTitle','off',...
    'MenuBar','none',...
    'Toolbar','none',...
	'Units','pixels',...
    'Position',[figX, figY, figW, figH],...
    'Color',color.gray,...
    'Visible','off');

% lists
hTextName = uicontrol(...
    'Tag','textName',...
    'String','Name',...
    'FontWeight','bold',...
    'FontSize',10,...
    'HorizontalAlignment','left',...
    'Units','pixels',...
    'Position',[10 370, 50, 20],...
    'Style','text'); %#ok<NASGU>

hListboxFontName = uicontrol(...
    'Tag','listboxFontName',...
    'Parent',hFigureFonts,...
    'Enable','on',...
    'FontName','FixedWidth',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[10 50 300 320],...
    'String',fontsSingletons.name,...
    'Style','listbox',...
    'Max',2,...
    'Min',0,...
    'Value',fontsSelectionIdx.name); %#ok<NASGU>

hTextSize = uicontrol(...
    'Tag','textSize',...
    'String','Size',...
    'FontWeight','bold',...
    'FontSize',10,...
    'HorizontalAlignment','left',...
    'Units','pixels',...
    'Position',[320 370, 50, 20],...
    'Style','text'); %#ok<NASGU>

hListboxFontSize = uicontrol(...
    'Tag','listboxFontSize',...
    'Parent',hFigureFonts,...
    'Enable','on',...
    'FontName','FixedWidth',...
    'FontSize',10,...
    'HorizontalAlignment','right',...
    'Units','pixels',...
    'Position',[320 50 50 320],...
    'String',fontsSingletons.size,...
    'Style','listbox',...
    'Max',2,...
    'Min',0,...
    'Value',fontsSelectionIdx.size); %#ok<NASGU>

hTextColorTransparency = uicontrol(...
    'Tag','textColorTransparency',...
    'String','Color (RGB) & Transparency',...
    'FontWeight','bold',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[370 370, 150, 20],...
    'Style','text'); %#ok<NASGU>

hListboxFontColor = uicontrol(...
    'Tag','listboxFontColor',...
    'Parent',hFigureFonts,...
    'Enable','on',...
    'FontName','FixedWidth',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[380 50 100 320],...
    'String',sColor,...
    'Style','listbox',...
    'Max',2,...
    'Min',0,...
    'Value',fontsSelectionIdx.color); %#ok<NASGU>

hListboxFontTransparency = uicontrol(...
    'Tag','listboxFontTransparency',...
    'Parent',hFigureFonts,...
    'Enable','on',...
    'FontName','FixedWidth',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[510 50 50 320],...
    'String',fontsSingletons.transparency,...
    'Style','listbox',...
    'Max',2,...
    'Min',0,...
    'Value',fontsSelectionIdx.transparency); %#ok<NASGU>

% buttons
hPushbuttonFontsCancel = uicontrol(...
    'Tag','pushbuttonFontsCancel',...
    'String','Cancel',...
    'Parent',hFigureFonts,...
    'Callback',@pushbuttonFontsCancel_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[10 10 100 20],...
    'Style','pushbutton'); %#ok<NASGU>

hPushbuttonFontsOK = uicontrol(...
    'Tag','pushbuttonFontsOK',...
    'String','OK',...
    'Parent',hFigureFonts,...
    'Callback',{@pushbuttonFontsOK_Callback,fontsSingletons},...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[460 10 100 20],...
    'Style','pushbutton'); %#ok<NASGU>

% display color patches
nColor = size(fontsSingletons.color,1);
if nColor > 32
    % there is room for only 32 color patches
    nColor = 32;
end
for kColor = nColor:-1:1

    r = fontsSingletons.color(kColor,1)/255;
    g = fontsSingletons.color(kColor,2)/255;
    b = fontsSingletons.color(kColor,3)/255;
    
    hTextColorPatches(kColor) = uicontrol(...
        'Tag',['textColorPatches',num2str(kColor)],...
        'String',' ',...
        'FontName','FixedWidth',...
        'FontSize',10,...
        'BackgroundColor',[r g b],...
        'Units','pixels',...
        'Position',[490 370 - kColor*10, 10, 10],...
        'Style','text'); %#ok<NASGU>
end

% finish
metrics = getappdata(hFigureMain,'metrics');
metrics.FontsSelected = 0;
setappdata(hFigureMain,'metrics',metrics)
hFigureFonts.Visible = 'on';


% cancel font selection process
function pushbuttonFontsCancel_Callback(~, ~)
close gcf

% ------------------------------------
% DISPLAY SELECTED FONTS
% ------------------------------------
function fontsAttributes = pushbuttonFontsOK_Callback(~, ~, fontsSingletons)

% read font attributes
% filter logic: (nameA OR ... OR nameZ) AND (sizeA OR ... ) AND (colorA OR ...)
handles = guihandles(gcf);
idx = handles.listboxFontName.Value;
fontsSelectionIdx.name = idx;
fontsAttributes.name = fontsSingletons.name(idx);

idx = handles.listboxFontSize.Value;
fontsSelectionIdx.size = idx;
fontsAttributes.size = fontsSingletons.size(idx);

idx = handles.listboxFontColor.Value;
fontsSelectionIdx.color = idx;
fontsAttributes.color = fontsSingletons.color(idx,:);

idx = handles.listboxFontTransparency.Value;
fontsSelectionIdx.transparency = idx;
fontsAttributes.transparency = fontsSingletons.transparency(idx);

% close font selection figure so that we can draw on the main figure
close gcf

% get main figure handles
handles = guihandles(gcf);
hFigureMain = handles.figureMain;

% save selection to figure
setappdata(hFigureMain,'fontsSelectionIdx',fontsSelectionIdx);

% get geometries of selected fonts
fontsSelection = towers_selectFonts(hFigureMain,fontsAttributes);
nFiles = length(fontsSelection.file);
docRank.n = nFiles;

% nothing found
if fontsSelection.status == 0
    msg = 'No font objects corresponding to selection';
    msgbox(msg, 'Error','error');
    return
end

% remove previous graphics
hObjectClasses = getappdata(hFigureMain,'hObjectClasses');
geometry = getappdata(hFigureMain,'geometry');
n = length(geometry);

for k = 1:n
    if isfield(hObjectClasses(k),'Fonts')
        % find handles of Font objects
        h = findobj(hObjectClasses(k).Fonts);
        if length(h) > 1
            delete(h(1:end))
        end
    end
end

% initialization data for geometries display
metadata = getappdata(hFigureMain,'metadata');
metrics = getappdata(hFigureMain,'metrics');
fontsSelectedCount = 0;
url = getappdata(hFigureMain,'url');
docsPerFig = getappdata(hFigureMain,'docsPerFig');
textFaceAlpha = getappdata(hFigureMain,'textFaceAlpha');
objectClassesShow = {'Fonts'};
tags = [];
addVizMode = 'add';

% reset document location in collection grid
grid = struct;
grid.x = 0;
grid.y = 0;
grid.ykmax = ceil( sqrt( nFiles ) ); % documents per row of a square grid
grid.yk = 1; % current document index
grid.xk1 = 0; % current document x axis displacement
grid.xk2 = 0; % next document x axis displacement
setappdata(hFigureMain,'grid',grid)

% ---
% display geometries
% ---
for kFiles = nFiles:-1:1 % files

    docRank.k = kFiles;
    url.documentFileName = metadata(kFiles).filename;
    metadata(kFiles).counts(5) = fontsSelection.file(kFiles).counts;
    fontsSelectedCount = fontsSelectedCount + ...
        metadata(kFiles).counts(5);

    if ~isempty(fontsSelection.file(kFiles).spread)
        towers_show(...
            fontsSelection.file(kFiles).spread, metadata(kFiles), url, ...
            docsPerFig, hFigureMain, docRank, ...
            textFaceAlpha, objectClassesShow, tags, addVizMode);
    end
end
metrics.FontsSelected = fontsSelectedCount;
setappdata(hFigureMain,'metrics',metrics)

% show only documents in selected range
fn = 'Fonts';
handles.checkboxFonts.Value = 1;
hObjectClasses = getappdata(hFigureMain,'hObjectClasses');
preferences = getappdata(hFigureMain,'preferences');
geometry = getappdata(hFigureMain,'geometry');
n = length(geometry);

% get document range
if isempty(preferences.documentRange)
    r1 = 1;
    r2 = n;
else
    r1 = preferences.documentRange(1);
    r2 = preferences.documentRange(2);
end

% show documents
for k = 1:n
    visibility = 'off';
    if (k >= r1 && k <= r2) && handles.(['checkbox' fn]).Value == 1
        visibility = 'on';
    end
    hObjectClasses( n-k+1 ).(fn).Visible = visibility;
end

% reset default axes values
axesLim = getappdata(handles.figureMain,'axesLim');
set(handles.axesViz,'XLim',axesLim(1,:),'YLim',axesLim(2,:),'ZLim',axesLim(3,:))



% ------------------------------------
% SELECT FONT GEOMETRY OBJECTS
% ------------------------------------
function fontsSelection = towers_selectFonts(hFigureMain,fontsAttributes)

% get fonts geometry
fontsGeometry = getappdata(hFigureMain,'fontsGeometry');

multiWaitbar('Extracting fonts geometries',0);
fontsSelection.status = 0; % anything found with selection?
nFiles = length(fontsGeometry);
for kFiles = 1:nFiles % files

    multiWaitbar('Extracting fonts geometries','Increment',1/nFiles);
    
    % counter of selected font items
    fontsSelection.file(kFiles).counts = 0;
    % mark as empty
    fontsSelection.file(kFiles).status = 0;
    
    % cascade filters
    nSpreads = length(fontsGeometry(kFiles).spreads);
    for kSpreads = 1:nSpreads % spreads

        % all fonts geometries for this spread
        fs = fontsGeometry(kFiles).spreads(kSpreads).Fonts;
        if isempty(fs)
            continue
        end
        idx = zeros(1,length(fs));

        % name 
        n = length(fontsAttributes.name);
        if n > 0
            for k = 1:n
                idx1 = arrayfun(@(x) strcmp(x.name,fontsAttributes.name(k)), fs);
                idx = or(idx,idx1);
            end
            if sum(idx) > 0
                fs = fontsGeometry(kFiles).spreads(kSpreads).Fonts(idx);
                idx = zeros(1,length(fs));
            else
                continue
            end
        end

        % size
        n = size(fontsAttributes.size,1);
        if n > 0
            for k = 1:n
                val = fontsAttributes.size(k);
                idx1 = arrayfun(@(x) isequal(x.size,val), fs);
                idx = or(idx,idx1);
            end
            if sum(idx) > 0
                fs = fs(idx);
                idx = zeros(1,length(fs));
            else
                continue
            end
        end
        
        % color
        n = size(fontsAttributes.color,1);
        if n > 0
            for k = 1:n
                val = fontsAttributes.color(k,:);
                idx1 = arrayfun(@(x) isequal(x.color,val), fs);
                idx = or(idx,idx1);
            end
            if sum(idx) > 0
                fs = fs(idx);
                idx = zeros(1,length(fs));
            else
                continue
            end
        end

        % transparency
        n = size(fontsAttributes.transparency,1);
        if n > 0
            for k = 1:n
                val = fontsAttributes.transparency(k);
                idx1 = arrayfun(@(x) isequal(x.transparency,val), fs);
                idx = or(idx,idx1);
            end
            if sum(idx) > 0
                fs = fs(idx);
                idx = zeros(1,length(fs));
            else
                continue
            end
        end
        
        % add items to selection set
        if ~isempty(fs)
            fontsSelection.file(kFiles).spread(kSpreads).Fonts = fs;
            fontsSelection.file(kFiles).counts = ...
                fontsSelection.file(kFiles).counts + ...
                length(fs);
            fontsSelection.file(kFiles).status = 1;
            fontsSelection.status = 1;
        end
    end
end
multiWaitbar('Extracting fonts geometries','Close');

