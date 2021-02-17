function towers(callFnName, callFnParam)
%TOWERS 3D visualization of document structures
%
% -------------
% INPUT (using GUI)
% -------------
% Programatic input:
% callFnName - function name to call
% callFnParam - parameteres of called function
%
% GUI input:
% 1. InDesign IDML or ALTO file(s).
% 2. JSON file containing document geometry.
% 
% -------------
% OUTPUT
% -------------
% Interactive visualization - 3D document structure of:
%         - document volume
%         - page boundaries
%         - text paragraph locations, size, and shape
%         - raster images
%         - vector graphics
%         - font name, size, color
% Files - visualization saved in various graphics formats
% 
% -------------
% LOG
% -------------
% 2021.01.03 - [new] change name from Crystal to Towers
% 2018.09.12 - [new] reads ALTO files
% 2016.01.23 - [bug][mod] various
%              [mod] better GUI: fits small screen sizes, etc.
%              [new] modifiable user preferences
% 2016.01.01 - [new] standalone versions
%            - [new] demo files
% 2015.05.00 - [new] better GUI
% 2013.10.03 - creation
% 
% -------------
% CREDITS
% -------------
% Vlad Atanasiu
% atanasiu@alum.mit.edu
% http://alum.mit.edu/www/atanasiu/



% ====================================
% PROGRAMMATIC CALL
% ====================================

% call specific function within this file instead of building the GUI
if nargin > 0 && ~isempty(callFnName) && ~isempty(callFnParam)
    switch callFnName
        case 'menuVisualize_Callback'
            menuVisualize_Callback(callFnParam)
    end
    return
end


% ====================================
% FIGURE
% ====================================

% ---
% USER PREFERENCES
% ---
% - visualization
% distance between two tower floors
% {-50}; (-) first page on top; (+) first page at bottom
preferences.floorHeight = -50;
% transparency of text objects: {0}, [0 1]: transparent - opaque, good: 0.3
preferences.textFaceAlpha = 0.3;
preferences.docPadXY = 300; % padding between documents
% projection type: {'Orthographic'} | 'Perspective'
preferences.vizProjection = 'Orthographic';
% viewpoint azimuth & elevation
preferences.view = [40 25];
% show only a specific range of documents or spreads; '[]' = show all
preferences.documentRange = [];
preferences.spreadRange = [];
% save setting
preferences.pngDpi = 150;

% - metrics settings
%
% what is measured: {'Absolute'} metric on a boundary; 'Relative'
% difference between the metrics of two boundaries
preferences.metricsValueType = 'Absolute';
% boundary within which to compute metrics: {'page'} | 'spread' | 'pasteboard'
preferences.metricsBoundaryType = 'Pages';
% how to measure cardinality: 'Linear' | {'Log'}
% the choice depends on the data: if it stretches over several orders of
% magnitude, then select the logarithmic scale, otehrwise linear scale
preferences.metricsCardinalityType = 'Linear';
% information potential methods:
% 'Salliency': sum( salliency(i,j) * area(i.j) )
% 'All': sqrt( sum( features^2 ) )
% 'RGB': Salliency > Red; Fill > Green; Cardinality > Blue
preferences.metricsInfoPotentialType = 'Salliency';
% paint or not towers with page metrics?
preferences.paint = 'None';
% colormap range: {'MinMax'} | 'ZeroOne'
% - 'ZeroOne': data is normalized with minimum inbetween zero and one,
% value zero beeing given the lowest colormap index color
% - 'MinMax': normalized with the minimum data value being given the lowest
% colormap index color
preferences.metricsColormapRangeType = 'MinMax';

% - other
% behaviour when creating new graphic objects
% {'new'} | 'newRange' | 'add': delete old datagraphics and metagraphics | 
% delete only datagraphics | don't delete anything
preferences.addVizMode = 'replace';
% ---

% static values
preferences.softVersion = '2021.01.10';
preferences.color.cyan = [0 0.682 0.937]; % RGB: 0 174 239
preferences.color.gray = [0.94 0.94 0.94];
preferences.color.magenta = [0.926 0 0.549]; % RGB: 236 0 140
preferences.color.white = [1 1 1];

% path to image files
apppath = mfilename('fullpath');
idx = strfind(apppath,filesep);
appRoot = apppath(1:idx(end));
if isdeployed
    pixdir = [apppath(1:idx(end-1)),'gui',filesep];
else
    pixdir = [apppath(1:idx(end)),'gui',filesep];
end


% ---
% UI LOCATIONS
% ---
% sizes & locations (bottom-up y values)

% figure size
screensize = get(groot, 'Screensize');
ui.FigH = screensize(4);
ui.FigY = 0;

% controls size
ui.PadXY = 10;
ui.ButtonW = 130;
ui.ButtonH = 20;
ui.CheckboxW = 130;
ui.CheckboxH = 25;
ui.TextH = 17.5;
ui.PopupmenuW = ui.CheckboxW;
ui.PopupmenuH = ui.ButtonH;
ui.BarsH = 40 + 27;

% logo size
ui.LogoW = 150;
ui.LogoH = 38;

% metadata - pagination, tags
ui.CheckboxTicksY = ui.PadXY;
ui.PopupmenuTagsY = ui.CheckboxTicksY + ui.CheckboxH + ui.PadXY/2;
ui.CheckboxTagsY = ui.PopupmenuTagsY + ui.ButtonH + ui.PadXY/2;

% paint
ui.PushbuttonPaintUpdateY = ui.PadXY;
% ui.RadiobuttonPaintInfoPotentialY = ui.PushbuttonPaintUpdateY + ui.ButtonH + ui.PadXY/2;
% ui.TextPaintLegendSetY = ui.RadiobuttonPaintInfoPotentialY + ui.TextH + ui.PadXY/2;
% ui.RadiobuttonPaintConfigurationY = ui.TextPaintLegendSetY + ui.ButtonH + ui.PadXY/2;
% ui.RadiobuttonPaintSalliencyY = ui.RadiobuttonPaintConfigurationY + ui.ButtonH + ui.PadXY/2;
% ui.RadiobuttonPaintFillY = ui.RadiobuttonPaintSalliencyY + ui.ButtonH + ui.PadXY/2;
ui.RadiobuttonPaintFillY = ui.PushbuttonPaintUpdateY + ui.ButtonH + ui.PadXY/2;
ui.RadiobuttonPaintCardinalityY = ui.RadiobuttonPaintFillY + ui.ButtonH + ui.PadXY/2;
ui.TextPaintLegendItemsY = ui.RadiobuttonPaintCardinalityY + ui.TextH + ui.PadXY/2;
ui.RadiobuttonPaintNoneY = ui.TextPaintLegendItemsY + ui.ButtonH + ui.PadXY/2;

% objects - labels, fonts, graphics, images, texts, pages, documents
ui.PushbuttonLabelsSelectY = ui.PadXY;
ui.PushbuttonFontsSelectY = ui.PushbuttonLabelsSelectY + ui.ButtonH + ui.PadXY/2;
ui.CheckboxFontsY = ui.PushbuttonFontsSelectY + ui.ButtonH + ui.PadXY/2;
ui.CheckboxGraphicsY = ui.CheckboxFontsY + ui.ButtonH + ui.PadXY/2;
ui.CheckboxImagesY = ui.CheckboxGraphicsY + ui.ButtonH + ui.PadXY/2;
ui.CheckboxTextY = ui.CheckboxImagesY + ui.ButtonH + ui.PadXY/2;
ui.CheckboxPagesY = ui.CheckboxTextY + ui.ButtonH + ui.PadXY/2;
ui.CheckboxDocumentsY = ui.CheckboxPagesY + ui.ButtonH + ui.PadXY/2;

% ranges - pages, documents
ui.PushbuttonPageRangeApplyY = ui.PadXY;
ui.EditPageRangeSelection2Y = ui.PushbuttonPageRangeApplyY + ui.ButtonH + ui.PadXY;
ui.TextPageRangeY = ui.EditPageRangeSelection2Y;
ui.EditPageRangeSelection1Y = ui.EditPageRangeSelection2Y;
ui.RadiobuttonPageRangeSelectionY = ui.EditPageRangeSelection2Y + ui.ButtonH + ui.PadXY/2;
ui.RadiobuttonPageRangeAllY = ui.RadiobuttonPageRangeSelectionY + ui.ButtonH + ui.PadXY/2;
ui.EditPageRangeSelection1X = ui.PadXY;
ui.TextPageRangeX = ui.EditPageRangeSelection1X + ui.ButtonW*0.45;
ui.EditPageRangeSelection2X = ui.TextPageRangeX + ui.ButtonW*0.1;
ui.RadiobuttonPageRangeSelectionX = ui.PadXY;

ui.PushbuttonDocumentRangeApplyY = ui.RadiobuttonPageRangeAllY + ui.ButtonH + ui.PadXY;
ui.EditDocumentRangeSelection2Y = ui.PushbuttonDocumentRangeApplyY + ui.ButtonH + ui.PadXY;
ui.TextDocumentRangeY = ui.EditDocumentRangeSelection2Y;
ui.EditDocumentRangeSelection1Y = ui.EditDocumentRangeSelection2Y;
ui.RadiobuttonDocumentRangeSelectionY = ui.EditDocumentRangeSelection1Y + ui.ButtonH + ui.PadXY/2;
ui.RadiobuttonDocumentRangeAllY = ui.RadiobuttonDocumentRangeSelectionY + ui.ButtonH + ui.PadXY/2;
ui.EditDocumentRangeSelection1X = ui.PadXY;
ui.TextDocumentRangeX = ui.EditDocumentRangeSelection1X + ui.ButtonW*0.45;
ui.EditDocumentRangeSelection2X = ui.TextDocumentRangeX + ui.ButtonW*0.1;
ui.RadiobuttonDocumentRangeSelectionX = ui.PadXY;

% user interface panel - wrapper for all panels
ui.PanelUiWrapperW = ui.ButtonW + ui.PadXY*2;
ui.PanelUiWrapperH = ui.FigH - ui.PadXY*2 + 5;
ui.PanelUiWrapperX = ui.PadXY;
ui.PanelUiWrapperY = ui.PadXY + 1;

% ui button - load geometry
ui.PushbuttonLoadGometryW = ui.ButtonW + ui.PadXY*2;
ui.PushbuttonLoadGometryH = ui.ButtonH;
ui.PushbuttonLoadGometryX = 1;
ui.PushbuttonLoadGometryY = 1; % ! distance from the parent's top
% This panel is clamped to its parent top, so that it stays on top of the
% figure when the figure is resized. This is a customized behavior, not the
% one of Matlab.
% ATTN: You need to specifiy any new panel put inside the wrapper in the
% 'resizing' section below, in the line 'objHandlesTop = {...}'.
% The following would be the typical Matlab way to do:
% ui.PanelObjectsY = ui.FigH - ui.PanelObjectsH - ui.PadXY;

% ui panel - ranges
ui.PanelRangesW = ui.ButtonW + ui.PadXY*2;
ui.PanelRangesH = ui.RadiobuttonDocumentRangeAllY + ui.CheckboxH + ui.PadXY;
ui.PanelRangesX = 1;
% ui.PanelRangesY = 1;
ui.PanelRangesY = ui.PushbuttonLoadGometryY + ui.ButtonH + ui.PadXY;

% ui panel - objects
ui.PanelObjectsW = ui.ButtonW + ui.PadXY*2;
ui.PanelObjectsH = ui.CheckboxDocumentsY + ui.CheckboxH + ui.PadXY;
ui.PanelObjectsX = 1;
ui.PanelObjectsY = ui.PanelRangesY + ui.PanelRangesH + ui.PadXY;

% ui panel - paint
ui.PanelPaintW = ui.ButtonW + ui.PadXY*2;
ui.PanelPaintH = ui.RadiobuttonPaintNoneY + ui.ButtonH + ui.PadXY*2;
ui.PanelPaintX = 1;
ui.PanelPaintY = ui.PanelObjectsY + ui.PanelObjectsH + ui.PadXY;

% ui panel - metadata
ui.PanelMetadataW = ui.ButtonW + ui.PadXY*2;
ui.PanelMetadataH = ui.CheckboxTagsY + ui.CheckboxH + ui.PadXY;
ui.PanelMetadataX = 1;
ui.PanelMetadataY = ui.PanelPaintY + ui.PanelPaintH + ui.PadXY;

% visualization panel
ui.PanelVizX = ui.PanelUiWrapperW + ui.PadXY*2;
ui.PanelVizW = 560;
ui.PanelVizH = ui.FigH - ui.PadXY*2 + 5;
ui.AxesVizW = ui.PanelVizW - ui.PadXY*2;
ui.AxesVizH = ui.PanelVizH - ui.PadXY*2;

% figure
ui.FigW = ui.PanelUiWrapperW + ui.PanelVizW + ui.PadXY*3;
ui.FigX = abs((screensize(3) - ui.FigW)/2);

% ---
% FIGURE
% ---

% figure
hFigureMain = figure(...
    'Tag','figureMain',...
    'Name','Towers',...
    'NumberTitle','off',...
    'MenuBar','none',...
    'Toolbar','none',...
	'Units','pixels',...
    'Position',[ui.FigX, ui.FigY, ui.FigW, ui.FigH],...
    'PaperPositionMode','auto',...
    'KeyPressFcn',@figureMain_KeyPressFcn,...
    'KeyReleaseFcn',@figureMain_KeyReleaseFcn,...
    'Visible','off');

% visualization
hPanelVisualization = uipanel(...
    'Tag','panelVisualization',...
    'Parent',hFigureMain,...
    'Title','Document Architecture',...
    'BackgroundColor',preferences.color.gray,...
    'FontSize',10,...
    'FontWeight','bold',...
    'Units','pixels',...
    'Position',[ui.PanelVizX, ui.PadXY, ui.PanelVizW, ui.PanelVizH]);

hAxesViz = axes(...
    'Tag','axesViz',...
    'Parent',hPanelVisualization,...
    'Box','off',...
    'XTick',[],...
    'YTick',[],...
    'ZTick',[],...
    'Color',preferences.color.white,...
    'XColor',preferences.color.white,...
    'YColor',preferences.color.white,...
    'ZColor',preferences.color.white,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.PadXY, ui.AxesVizW, ui.AxesVizH]);
%    'CreateFcn',@axesViz_CreateFcn);

% ui - wrapper
hPanelUiWrapper = uipanel(...
    'Tag','panelUiWrapper',...
    'Title','',...
    'Parent',hFigureMain,...
    'BorderType','none',...
    'Clipping','on',...
    'Units','pixels',...
    'Position',[ui.PanelUiWrapperX, ui.PanelUiWrapperY, ui.PanelUiWrapperW, ui.PanelUiWrapperH]);


% ui - load data
hPushbuttonLoadGometry = uicontrol(...
    'Tag','pushbuttonLoadGometry',...
    'String','Load Gometry',...
    'Parent',hPanelUiWrapper,...
    'Callback',@menuSelectDocuments_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PushbuttonLoadGometryX, ui.PushbuttonLoadGometryY, ...
        ui.PushbuttonLoadGometryW, ui.PushbuttonLoadGometryH],...
    'Style','pushbutton',...
    'Value',0);


% ui - ranges
hPanelRanges = uipanel(...
    'Tag','panelRanges',...
    'Title','Ranges',...
    'Parent',hPanelUiWrapper,...
    'FontSize',10,...
    'FontWeight','bold',...
    'Clipping','on',...
    'Units','pixels',...
    'Position',[ui.PanelRangesX, ui.PanelRangesY, ui.PanelRangesW, ui.PanelRangesH]);

hRadiobuttonDocumentRangeAll = uicontrol(...
    'Tag','radiobuttonDocumentRangeAll',...
    'String','All Documents',...
    'Parent',hPanelRanges,...
    'Callback',@radiobuttonDocumentRangeAll_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.RadiobuttonDocumentRangeAllY, ui.ButtonW, ui.ButtonH],...
    'Style','radiobutton',...
    'Value',1);

hRadiobuttonDocumentRangeSelection = uicontrol(...
    'Tag','radiobuttonDocumentRangeSelection',...
    'String','Range:',...
    'Parent',hPanelRanges,...
    'Callback',@radiobuttonDocumentRangeSelection_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.RadiobuttonDocumentRangeSelectionX, ui.RadiobuttonDocumentRangeSelectionY, ui.ButtonW, ui.ButtonH],...
    'Style','radiobutton',...
    'Value',0);

hEditDocumentRangeSelection1 = uicontrol(...
    'Tag','editDocumentRangeSelection1',...
    'String','',...
    'Parent',hPanelRanges,...
    'Callback',@editDocumentRangeSelection1_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.EditDocumentRangeSelection1X, ui.EditDocumentRangeSelection1Y, ui.ButtonW*0.45, ui.ButtonH],...
    'Style','edit');

hTextDocumentRange = uicontrol(...
    'Tag','textDocumentRange',...
    'String','–',...
    'Parent',hPanelRanges,...
    'Enable','off',...
    'FontSize',10,...
    'HorizontalAlignment','center',...
    'Units','pixels',...
    'Position',[ui.TextDocumentRangeX, ui.TextDocumentRangeY, ui.ButtonW*0.1, ui.ButtonH],...
    'Style','text');

hEditDocumentRangeSelection2 = uicontrol(...
    'Tag','editDocumentRangeSelection2',...
    'String','',...
    'Parent',hPanelRanges,...
    'Callback',@editDocumentRangeSelection2_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.EditDocumentRangeSelection2X, ui.EditDocumentRangeSelection2Y, ui.ButtonW*0.45, ui.ButtonH],...
    'Style','edit');

hPushbuttonDocumentRangeApply = uicontrol(...
    'Tag','pushbuttonDocumentRangeApply',...
    'String','Apply Documents',...
    'Parent',hPanelRanges,...
    'Callback',@pushbuttonDocumentRangeApply_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.PushbuttonDocumentRangeApplyY, ui.ButtonW ui.ButtonH],...
    'Style','pushbutton',...
    'Value',0);

hRadiobuttonPageRangeAll = uicontrol(...
    'Tag','radiobuttonPageRangeAll',...
    'String','All Pages',...
    'Parent',hPanelRanges,...
    'Callback',@radiobuttonPageRangeAll_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.RadiobuttonPageRangeAllY, ui.ButtonW, ui.ButtonH],...
    'Style','radiobutton',...
    'Value',1);

hRadiobuttonPageRangeSelection = uicontrol(...
    'Tag','radiobuttonPageRangeSelection',...
    'String','Range:',...
    'Parent',hPanelRanges,...
    'Callback',@radiobuttonPageRangeSelection_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.RadiobuttonPageRangeSelectionX, ui.RadiobuttonPageRangeSelectionY, ui.ButtonW, ui.ButtonH],...
    'Style','radiobutton',...
    'Value',0);

hEditPageRangeSelection1 = uicontrol(...
    'Tag','editPageRangeSelection1',...
    'String','',...
    'Parent',hPanelRanges,...
    'Callback',@editPageRangeSelection1_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.EditPageRangeSelection1X, ui.EditPageRangeSelection1Y, ui.ButtonW*0.45, ui.ButtonH],...
    'Style','edit');

hTextPageRange = uicontrol(...
    'Tag','textPageRange',...
    'String','–',...
    'Parent',hPanelRanges,...
    'Enable','off',...
    'FontSize',10,...
    'HorizontalAlignment','center',...
    'Units','pixels',...
    'Position',[ui.TextPageRangeX, ui.TextPageRangeY, ui.ButtonW*0.1, ui.ButtonH],...
    'Style','text');

hEditPageRangeSelection2 = uicontrol(...
    'Tag','editPageRangeSelection2',...
    'String','',...
    'Parent',hPanelRanges,...
    'Callback',@editPageRangeSelection2_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.EditPageRangeSelection2X, ui.EditPageRangeSelection2Y, ui.ButtonW*0.45, ui.ButtonH],...
    'Style','edit');

hPushbuttonPageRangeApply = uicontrol(...
    'Tag','pushbuttonPageRangeApply',...
    'String','Apply Pages',...
    'Parent',hPanelRanges,...
    'Callback',@pushbuttonPageRangeApply_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.PushbuttonPageRangeApplyY, ui.ButtonW, ui.ButtonH],...
    'Style','pushbutton',...
    'Value',0);


% ui - objects
hPanelObjects = uipanel(...
    'Tag','panelObjects',...
    'Title','Objects',...
    'Parent',hPanelUiWrapper,...
    'FontSize',10,...
    'FontWeight','bold',...
    'Clipping','on',...
    'Units','pixels',...
    'Position',[ui.PanelObjectsX, ui.PanelObjectsY, ui.PanelObjectsW, ui.PanelObjectsH]);

hCheckboxDocuments = uicontrol(...
    'Tag','checkboxDocuments',...
    'String','Document Volumes',...
    'Parent',hPanelObjects,...
    'Callback',@checkboxDocuments_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.CheckboxDocumentsY, ui.ButtonW, ui.ButtonH],...
    'Style','checkbox',...
    'Value',0);

hCheckboxPages = uicontrol(...
    'Tag','checkboxPages',...
    'String','Page Boundaries',...
    'Parent',hPanelObjects,...
    'Callback',@checkboxPages_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.CheckboxPagesY, ui.ButtonW, ui.ButtonH],...
    'Style','checkbox',...
    'Value',1);

hCheckboxText = uicontrol(...
    'Tag','checkboxText',...
    'String','Text Frames',...
    'Parent',hPanelObjects,...
    'Callback',@checkboxText_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.CheckboxTextY, ui.CheckboxW, ui.CheckboxH],...
    'Style','checkbox',...
    'Value',1);

hCheckboxImages = uicontrol(...
    'Tag','checkboxImages',...
    'String','Bitmap Images',...
    'Parent',hPanelObjects,...
    'Callback',@checkboxImages_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.CheckboxImagesY, ui.CheckboxW, ui.CheckboxH],...
    'Style','checkbox',...
    'Value',1);

hCheckboxGraphics = uicontrol(...
    'Tag','checkboxGraphics',...
    'String','Vector Graphics',...
    'Parent',hPanelObjects,...
    'Callback',@checkboxGraphics_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.CheckboxGraphicsY, ui.CheckboxW, ui.CheckboxH],...
    'Style','checkbox',...
    'Value',1);

hCheckboxFonts = uicontrol(...
    'Tag','checkboxFonts',...
    'String','Font Properties',...
    'Parent',hPanelObjects,...
    'Callback',@checkboxFonts_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.CheckboxFontsY, ui.CheckboxW, ui.CheckboxH],...
    'Style','checkbox',...
    'Value',0);

hPushbuttonFontsSelect = uicontrol(...
    'Tag','pushbuttonFontsSelect',...
    'String','Select Fonts',...
    'Parent',hPanelObjects,...
    'Callback',@pushbuttonFontsSelect_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.PushbuttonFontsSelectY, ui.ButtonW, ui.ButtonH],...
    'Style','pushbutton');

hPushbuttonLabelsSelect = uicontrol(...
    'Tag','pushbuttonLabelsSelect',...
    'String','Select Labels',...
    'Parent',hPanelObjects,...
    'Callback',@pushbuttonLabelsSelect_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.PushbuttonLabelsSelectY, ui.ButtonW, ui.ButtonH],...
    'Style','pushbutton');


% ui - paint
hPanelPaint = uipanel(...
    'Tag','panelPaint',...
    'Title',['Metrics ',preferences.metricsBoundaryType],...
    'Parent',hPanelUiWrapper,...
    'FontSize',10,...
    'FontWeight','bold',...
    'Clipping','on',...
    'Units','pixels',...
    'Position',[ui.PanelPaintX, ui.PanelPaintY, ui.PanelPaintW, ui.PanelPaintH]);

hRadiobuttonPaintNone = uicontrol(...
    'Tag','radiobuttonPaintNone',...
    'String','None',...
    'Parent',hPanelPaint,...
    'Callback',@radiobuttonPaintNone_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.RadiobuttonPaintNoneY, ui.ButtonW, ui.ButtonH],...
    'Style','radiobutton',...
    'Value',1);

hTextPaintLegendItems = uicontrol(...
    'Tag','textPaintLegendItems',...
    'String','Fragmentation / Distribution',...
    'Parent',hPanelPaint,...
    'Enable','off',...
    'FontSize',10,...
    'HorizontalAlignment','left',...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.TextPaintLegendItemsY, ui.ButtonW, ui.TextH],...
    'Style','text');

hRadiobuttonPaintCardinality = uicontrol(...
    'Tag','radiobuttonPaintCardinality',...
    'String','Cardinality / Density',...
    'Parent',hPanelPaint,...
    'Callback',@radiobuttonPaintCardinality_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.RadiobuttonPaintCardinalityY, ui.ButtonW, ui.ButtonH],...
    'Style','radiobutton',...
    'Value',0);

hRadiobuttonPaintFill = uicontrol(...
    'Tag','radiobuttonPaintFill',...
    'String','Fill / Range',...
    'Parent',hPanelPaint,...
    'Callback',@radiobuttonPaintFill_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.RadiobuttonPaintFillY, ui.ButtonW, ui.ButtonH],...
    'Style','radiobutton',...
    'Value',0);

% hRadiobuttonPaintSalliency = uicontrol(...
%     'Tag','radiobuttonPaintSalliency',...
%     'String','Salliency / Fit Z',...
%     'Parent',hPanelPaint,...
%     'Callback',@radiobuttonPaintSalliency_Callback,...
%     'Enable','off',...
%     'FontSize',10,...
%     'Units','pixels',...
%     'Position',[ui.PadXY, ui.RadiobuttonPaintSalliencyY, ui.ButtonW, ui.ButtonH],...
%     'Style','radiobutton',...
%     'Value',0,...
%     'Visible','off');
% 
% hRadiobuttonPaintConfiguration = uicontrol(...
%     'Tag','radiobuttonPaintConfiguration',...
%     'String','Configuration / Fit XY',...
%     'Parent',hPanelPaint,...
%     'Callback',@radiobuttonPaintConfiguration_Callback,...
%     'Enable','off',...
%     'FontSize',10,...
%     'Units','pixels',...
%     'Position',[ui.PadXY, ui.RadiobuttonPaintConfigurationY, ui.ButtonW, ui.ButtonH],...
%     'Style','radiobutton',...
%     'Value',0,...
%     'Visible','off');
% 
% hTextPaintLegendSet = uicontrol(...
%     'Tag','textPaintLegendSet',...
%     'String','Packing Optimality',...
%     'Parent',hPanelPaint,...
%     'Enable','off',...
%     'FontSize',10,...
%     'HorizontalAlignment','left',...
%     'Units','pixels',...
%     'Position',[ui.PadXY, ui.TextPaintLegendSetY, ui.ButtonW, ui.TextH],...
%     'Style','text',...
%     'Visible','off');
% 
% hRadiobuttonPaintInfoPotential = uicontrol(...
%     'Tag','radiobuttonPaintInfoPotential',...
%     'String','Information Potential',...
%     'Parent',hPanelPaint,...
%     'Callback',@radiobuttonPaintInfoPotential_Callback,...
%     'Enable','off',...
%     'FontSize',10,...
%     'Units','pixels',...
%     'Position',[ui.PadXY, ui.RadiobuttonPaintInfoPotentialY, ui.ButtonW, ui.ButtonH],...
%     'Style','radiobutton',...
%     'Value',0,...
%     'Visible','off');

hPushbuttonPaintUpdate = uicontrol(...
    'Tag','pushbuttonPaintUpdate',...
    'String','Update Paint',...
    'Parent',hPanelPaint,...
    'Callback',@pushbuttonPaintUpdate_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.PushbuttonPaintUpdateY, ui.ButtonW, ui.ButtonH],...
    'Style','pushbutton');


% ui - metadata
hPanelMetadata = uipanel(...
    'Tag','panelMetadata',...
    'Title','Metadata',...
    'Parent',hPanelUiWrapper,...
    'FontSize',10,...
    'FontWeight','bold',...
    'Clipping','on',...
    'Units','pixels',...
    'Position',[ui.PanelMetadataX, ui.PanelMetadataY, ui.PanelMetadataW, ui.PanelMetadataH]);

hCheckboxTags = uicontrol(...
    'Tag','checkboxTags',...
    'String','Page Tags',...
    'Parent',hPanelMetadata,...
    'Callback',@checkboxTags_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.CheckboxTagsY, ui.CheckboxW, ui.CheckboxH],...
    'Style','checkbox',...
    'Value',1);

hPopupmenuTags = uicontrol(...
    'Tag','popupmenuTags',...
    'Parent',hPanelMetadata,...
    'Callback',@popupmenuTags_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.PopupmenuTagsY, ui.PopupmenuW, ui.PopupmenuH],...
    'String',{'None'},...
    'Style','popupmenu',...
    'Value',1);

hCheckboxTicks = uicontrol(...
    'Tag','checkboxTicks',...
    'String','Page Numbers',...
    'Parent',hPanelMetadata,...
    'Callback',@checkboxTicks_Callback,...
    'Enable','off',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.CheckboxTicksY, ui.CheckboxW, ui.CheckboxH],...
    'Style','checkbox',...
    'Value',1);

% % logo
% hPanelLogo = uipanel(...
%     'Tag','panelLogo',...
%     'Parent',hFigureMain,...
%     'Title','',...
%     'BorderType','none',...
%     'Units','pixels',...
%     'Position',[ui.PadXY, ui.LogoY, ui.LogoW, ui.LogoH]);
% 
% hAxesLogo = axes(...
%     'Tag','axesLogo',...
%     'Parent',hPanelLogo,...
%     'Units','pixels',...
%     'Position',[1, 1, ui.LogoW, ui.LogoH],...
%     'CreateFcn',@axesLogo_CreateFcn);

% ---
% MENU
% ---
% geometry
hMenuGeometry = uimenu(...
    'Tag','menuGeometry',...
    'Label','Geometry',...
    'Parent',hFigureMain,...
    'Enable','on',...
    'Callback',@menuGeometry_Callback);

hMenuExtract = uimenu(...
    'Tag','menuExtract',...
    'Label','Extract...',...
    'Parent',hMenuGeometry,...
    'Enable','on',...
    'Callback',@menuExtract_Callback);

hMenuExtractAlto = uimenu(...
    'Tag','menuExtractAlto',...
    'Label','Alto',...
    'Parent',hMenuExtract,...
    'Enable','on',...
    'Callback',@menuExtractAlto_Callback);

hMenuExtractIdml = uimenu(...
    'Tag','menuExtractIdml',...
    'Label','IDML',...
    'Parent',hMenuExtract,...
    'Enable','on',...
    'Callback',@menuExtractIdml_Callback);

hMenuVisualize = uimenu(...
    'Tag','menuVisualize',...
    'Label','Visualize',...
    'Parent',hMenuGeometry,...
    'Enable','on',...
    'Callback',@menuSelectDocuments_Callback);

% visualization
hMenuVisualization = uimenu(...
    'Tag','menuVisualization',...
    'Label','Visualization',...
    'Parent',hFigureMain,...
    'Enable','on',...
    'Callback',@menuVisualization_Callback);

hMenuSave = uimenu(...
    'Tag','menuSaveAs',...
    'Label','Save As...',...
    'Parent',hMenuVisualization,...
    'Enable','off',...
    'Callback',@menuSaveAs_Callback);

hMenuSaveAsPng = uimenu(...
    'Tag','menuSaveAsPng',...
    'Label','PNG',...
    'Parent',hMenuSave,...
    'Callback',@menuSaveAsPng_Callback);

hMenuSaveAsSvg = uimenu(...
    'Tag','menuSaveAsSvg',...
    'Label','SVG',...
    'Parent',hMenuSave,...
    'Callback',@menuSaveAsSvg_Callback);

hMenuSaveAsPdf = uimenu(...
    'Tag','menuSaveAsPdf',...
    'Label','PDF',...
    'Parent',hMenuSave,...
    'Callback',@menuSaveAsPdf_Callback);

hMenuSaveAsEps = uimenu(...
    'Tag','menuSaveAsEps',...
    'Label','EPS',...
    'Parent',hMenuSave,...
    'Callback',@menuSaveAsEps_Callback);

hMenuSaveAsFig = uimenu(...
    'Tag','menuSaveAsFig',...
    'Label','FIG',...
    'Parent',hMenuSave,...
    'Callback',@menuSaveAsFig_Callback);

hMenuVizPreferences = uimenu(...
    'Tag','menuVizPreferences',...
    'Label','Preferences',...
    'Parent',hMenuVisualization,...
    'Enable','off',...
    'Callback',@menuVizPreferences_Callback);

% metrics
hMenuMetrics = uimenu(...
    'Tag','menuMetrics',...
    'Label','Metrics',...
    'Parent',hFigureMain,...
    'Enable','on',...
    'Callback',@menuMetrics_Callback);

hMenuStatistics = uimenu(...
    'Tag','menuStatistics',...
    'Label','Statistics',...
    'Parent',hMenuMetrics,...
    'Enable','off',...
    'Callback',@menuStatistics_Callback);

hMenuMetricsPreferences = uimenu(...
    'Tag','menuMetricsPreferences',...
    'Label','Preferences',...
    'Parent',hMenuMetrics,...
    'Enable','off',...
    'Callback',@menuMetricsPreferences_Callback);

% help
hMenuHelp = uimenu(...
    'Tag','menuHelp',...
    'Label','Help',...
    'Parent',hFigureMain,...
    'Callback',@menuHelp_Callback);

hMenuHelpDocumentation = uimenu(...
    'Tag','menuHelpDocumentation',...
    'Label','Documentation',...
    'Parent',hMenuHelp,...
    'Callback',@menuHelpDocumentation_Callback);

hMenuHelpAbout = uimenu(...
    'Tag','menuHelpAbout',...
    'Label','About',...
    'Parent',hMenuHelp,...
    'Callback',@menuHelpAbout_Callback);

% ---
% TOOLBAR
% ---

hToolbar = uitoolbar(hFigureMain);

hToolLogo = uipushtool(...
    hToolbar,...
    'CData',imread(fullfile(pixdir,'towers-logo-symbol.jpg')),...
    'TooltipString','3D Interaction Tools');

hToolZoom = uipushtool(...
    hToolbar,...
    'Tag','toolZoom',...
    'TooltipString','Zoom',...
    'CData',imread(fullfile(pixdir,'iconZ.jpg')),...
    'ClickedCallback',@toolZoom_Callback,...
    'Separator','on');

hToolRotate = uipushtool(...
    hToolbar,...
    'Tag','toolRotate',...
    'TooltipString','Rotate',...
    'CData',imread(fullfile(pixdir,'iconR.jpg')),...
    'ClickedCallback',@toolRotate_Callback);

hToolPan = uipushtool(...
    hToolbar,...
    'Tag','toolPan',...
    'TooltipString','Pan',...
    'CData',imread(fullfile(pixdir,'iconP.jpg')),...
    'ClickedCallback',@toolPan_Callback);

hToolViewOblique = uipushtool(...
    hToolbar,...
    'Tag','toolViewOblique',...
    'TooltipString','Oblique View',...
    'CData',imread(fullfile(pixdir,'iconO.jpg')),...
    'ClickedCallback',@toolViewOblique_Callback,...
    'Separator','on');

hToolViewFront = uipushtool(...
    hToolbar,...
    'Tag','toolViewFront',...
    'TooltipString','Front View',...
    'CData',imread(fullfile(pixdir,'iconF.jpg')),...
    'ClickedCallback',@toolViewFront_Callback);

hToolViewSide = uipushtool(...
    hToolbar,...
    'Tag','toolViewSide',...
    'TooltipString','Side View',...
    'CData',imread(fullfile(pixdir,'iconS.jpg')),...
    'ClickedCallback',@toolViewSide_Callback);

hToolViewTop = uipushtool(...
    hToolbar,...
    'Tag','toolViewTop',...
    'TooltipString','Top View',...
    'CData',imread(fullfile(pixdir,'iconT.jpg')),...
    'ClickedCallback',@toolViewTop_Callback);


% we define the callbacks only after the UI objects were created
% so as to have a handle on them, since the SizeChangedFcn callback 
% is called as soon as it is defined
hFigureMain.SizeChangedFcn = @figureMain_SizeChangedFcn;

% group handles
handles = guihandles(hFigureMain);
handles.figureMain = hFigureMain;

handles.panelVisualization = hPanelVisualization;
handles.axesViz = hAxesViz;

handles.panelUiWrapper = hPanelUiWrapper;

handles.pushbuttonLoadGometry = hPushbuttonLoadGometry;

handles.panelObjects = hPanelObjects;
handles.checkboxDocuments = hCheckboxDocuments;
handles.radiobuttonDocumentRangeAll = hRadiobuttonDocumentRangeAll;
handles.radiobuttonDocumentRangeSelection = hRadiobuttonDocumentRangeSelection;
handles.editDocumentRangeSelection1 = hEditDocumentRangeSelection1;
handles.editDocumentRangeSelection2 = hEditDocumentRangeSelection2;
handles.pushbuttonDocumentRangeApply = hPushbuttonDocumentRangeApply;
handles.checkboxPages = hCheckboxPages;
handles.radiobuttonPageRangeAll = hRadiobuttonPageRangeAll;
handles.radiobuttonPageRangeSelection = hRadiobuttonPageRangeSelection;
handles.editPageRangeSelection1 = hEditPageRangeSelection1;
handles.editPageRangeSelection2 = hEditPageRangeSelection2;
handles.pushbuttonPageRangeApply = hPushbuttonPageRangeApply;
handles.checkboxText = hCheckboxText;
handles.checkboxImages = hCheckboxImages;
handles.checkboxGraphics = hCheckboxGraphics;
handles.checkboxFonts = hCheckboxFonts;

handles.panelPaint = hPanelPaint;
handles.radiobuttonPaintNone = hRadiobuttonPaintNone;
handles.radiobuttonPaintCardinality = hRadiobuttonPaintCardinality;
handles.radiobuttonPaintFill = hRadiobuttonPaintFill;
% handles.radiobuttonPaintSalliency = hRadiobuttonPaintSalliency;
% handles.radiobuttonPaintConfiguration = hRadiobuttonPaintConfiguration;
% handles.radiobuttonPaintInfoPotential = hRadiobuttonPaintInfoPotential;
handles.pushbuttonPaintUpdate = hPushbuttonPaintUpdate;

handles.panelMetadata = hPanelMetadata;
handles.checkboxTags = hCheckboxTags;
handles.checkboxTicks = hCheckboxTicks;
handles.popupmenuTags = hPopupmenuTags;

handles.toolZoom = hToolZoom;
handles.toolRotate = hToolRotate;
handles.toolPan = hToolPan;
handles.toolViewOblique = hToolViewOblique;
handles.toolViewFront = hToolViewFront;
handles.toolViewSide = hToolViewSide;
handles.toolViewTop = hToolViewTop;

% memorize initial state
states.panelVisualizationTitle = hPanelVisualization.Title;
states.panelVisualizationBorderType = hPanelVisualization.BorderType;

% -------
% LOAD DATA FROM FILES
% -------

% preload colormaps
preferences.cmap.map = [];
preferences.cmap.selection = 1;
cmapFileName = {...
    'D2 - diverging_gwv_55-95_c39_n256-pk',...
    'D12 - diverging-isoluminant_cjm_75_c24_n256-pk',...
    'cmap cool n256',...
    'cmap X3 center shifted to golden ratio'};
ncmap = length(cmapFileName);
for kcmap = 1:ncmap
    temp = load([appRoot,filesep,'colormaps',filesep,cmapFileName{kcmap}]);
    temp = [1 1 1; temp.map]; % NaN represented by white color
    preferences.cmap.map = cat(3, preferences.cmap.map, temp);
end

% -------
% SPECIFY RESIZEABLE OBJECTS AND VALUES
% -------

% specify the resizable GUI objects handles;
% figure handle should be first
objHandles = {...
    hFigureMain, hPanelVisualization, hAxesViz, hPanelUiWrapper};

% minimum and maximum object width and height;
% use 'inf' for no limit; 
% minimum size should be a positive integer;
% [width-min width-max height-min height-max]
limits = {...
    [1, inf, 1, inf],...
    [1, inf, 1, inf],...
    [1, inf, 1, inf],...
    [hPanelUiWrapper.Position(3), hPanelUiWrapper.Position(3), 1, inf]...
    };

% handles of objects clamped to the top of their parents;
% their parents should be included in the 'objHandles' definition above;
% type '{}' if there are no top clamped object
objHandlesTop = {hPanelRanges, hPanelObjects, hPanelPaint, ...
    hPanelMetadata, hPushbuttonLoadGometry};


% -------
% PREPARE RESIZEABLE OBJECTS
% -------

% get object names
objNames = struct([]);
n = length(objHandles);
for k = 1:n
    objNames{k} = objHandles{k}.Tag;
end
objNamesTop = struct([]);

n = length(objHandlesTop);
for k = 1:n
    objNamesTop{k} = objHandlesTop{k}.Tag;
end

% clamp top-aligned objects to the top of their parents
n = length(objHandlesTop);
for k = 1:n
    % get parent
    p = objHandlesTop{k}.Parent;
    
    % synchronize object units to parent
    t = objHandlesTop{k}.Units;
    objHandlesTop{k}.Units = p.Units;

    % relocate
    objHandlesTop{k}.Position(2) = ...
        p.Position(4) - ...
        objHandlesTop{k}.Position(2) - ...
        objHandlesTop{k}.Position(4);
    
    % memorize position
    objSize.(objNamesTop{k}).Y0 = objHandlesTop{k}.Position(2);
    objSize.(objNamesTop{k}).Y1 = objHandlesTop{k}.Position(2);
    
    % undo unit change
    objHandlesTop{k}.Units = t;

end

% memorize figure size
objSize.(objNames{1}).W0 = objHandles{1}.Position(3); % default value
objSize.(objNames{1}).H0 = objHandles{1}.Position(4);
objSize.(objNames{1}).W1 = objHandles{1}.Position(3); % previous value
objSize.(objNames{1}).H1 = objHandles{1}.Position(4);

% memorize object positions and sizes
n = length(objNames);
for k = 2:n
    objSize.(objNames{k}).W0 = objHandles{k}.Position(3);
    objSize.(objNames{k}).W1 = objHandles{k}.Position(3);
    objSize.(objNames{k}).WMIN = limits{k}(1);
    objSize.(objNames{k}).WMAX = limits{k}(2);
    objSize.(objNames{k}).H0 = objHandles{k}.Position(4);
    objSize.(objNames{k}).H1 = objHandles{k}.Position(4);
    objSize.(objNames{k}).HMIN = limits{k}(3);
    objSize.(objNames{k}).HMAX = limits{k}(4);
    objSize.(objNames{k}).X0 = objHandles{k}.Position(1);
    objSize.(objNames{k}).Y0 = objHandles{k}.Position(2);
    % distance between right edges of object and figure
    objSize.(objNames{k}).R0 = objHandles{1}.Position(3) - ...
        objSize.(objNames{k}).X0 - objSize.(objNames{k}).W0;
    % distance between top edges of object and figure
    objSize.(objNames{k}).T0 = objHandles{1}.Position(4) - ...
        objSize.(objNames{k}).Y0 - objSize.(objNames{k}).H0;
end

% we store variables in the figure as application data
setappdata(objHandles{1},'objNames',objNames)
setappdata(objHandles{1},'objNamesTop',objNamesTop)
setappdata(objHandles{1},'objSize',objSize)

% --- END RESIZE PREPARATION

% save preferences & temporary states
setappdata(hFigureMain,'preferences',preferences)
setappdata(hFigureMain,'states',states)

% save other data
setappdata(hFigureMain,'appRoot',appRoot)
setappdata(hFigureMain,'pixdir',pixdir)
setappdata(hFigureMain,'ui',ui)
setappdata(hFigureMain,'hObjectClasses',{})
setappdata(hFigureMain,'objectClasses',...
    {'Pages','Text','Images','Graphics','Fonts'})
setappdata(hFigureMain,'hFilenames',{})
setappdata(hFigureMain,'hTags',{})
setappdata(hFigureMain,'hTicks',{})
fontsSelectionIdx = struct;
fontsSelectionIdx.name = 1;
fontsSelectionIdx.size = 1;
fontsSelectionIdx.color = 1;
fontsSelectionIdx.transparency = 1;
setappdata(hFigureMain,'fontsSelectionIdx',fontsSelectionIdx);
statistics = struct(...
    'Documents',0,'Pages',0,'Text',0,'Images',0,'Graphics',0,...
    'Fonts',0,'FontsSelected',0);
setappdata(hFigureMain,'statistics',statistics)
setappdata(hFigureMain,'labels',...
    struct('list',[],'selection',""))
setappdata(hFigureMain,'metricsClasses',...
    {'Cardinality','Fill','Salliency','Configuration','InfoPotential'})
guidata(hFigureMain,handles)
axesViz_CreateFcn(hAxesViz)

% all ok, so show figure
hFigureMain.Visible = 'on';


% ====================================
% CALLBACKS
% ====================================


% ------------------------------------
% FIGURE
% ------------------------------------

% --- Executes at key press on figureMain.
function figureMain_KeyPressFcn(hObject, event)

handles = guihandles(gcf);
states = getappdata(hObject,'states');
ui = getappdata(handles.figureMain,'ui');

switch event.Character
    case 'z' % zoom
        toolZoom_Callback(hObject)
    case 'r' % rotate
        toolRotate_Callback(hObject)
    case 'p' % pan
        toolPan_Callback(hObject)
    case 'h' % hide figure except visualization
             % useful for saving only the visualization w/o the menu
        visibility = handles.panelUiWrapper.Visible;
        if strcmp(visibility,'on') == 1
            visibility = 'off';
            handles.panelVisualization.Title = '';
            handles.panelVisualization.BorderType = 'none';
            handles.panelVisualization.Position(1) = ...
                handles.panelVisualization.Position(1) - ...
                ui.PanelUiWrapperW - ui.PadXY;
            handles.panelVisualization.Position(3) = ...
                handles.panelVisualization.Position(3) + ...
                ui.PanelUiWrapperW + ui.PadXY;
        else
            visibility = 'on';
            handles.panelVisualization.Title = ...
                states.panelVisualizationTitle;
            handles.panelVisualization.BorderType = ...
                states.panelVisualizationBorderType;
            handles.panelVisualization.Position(1) = ...
                handles.panelVisualization.Position(1) + ...
                ui.PanelUiWrapperW + ui.PadXY;
            handles.panelVisualization.Position(3) = ...
                handles.panelVisualization.Position(3) - ...
                ui.PanelUiWrapperW - ui.PadXY;
        end
        handles.panelUiWrapper.Visible = visibility;
    case 'o' % open file
        menuSelectDocuments_Callback(hObject)
    case '0' % show coordinates
        hCoordinatesAxes = getappdata(handles.figureMain,'hCoordinatesAxes');
        if isempty(hCoordinatesAxes)
            return
        end
        if strcmp(hCoordinatesAxes.Visible,'on') == 1
            hCoordinatesAxes.Visible = 'off';
        else
            hCoordinatesAxes.Visible = 'on';
        end
        setappdata(handles.figureMain,'hCoordinatesAxes',hCoordinatesAxes)
end
guidata(hObject,handles);

figure_CloseByKey(hObject, event)


% --- Executes at key release on figureMain.
function figureMain_KeyReleaseFcn(hObject, event)


% --- Close figure through keypress
function figure_CloseByKey(hObject, event)

% support Mac and Windows key combinations
if (strcmp(event.Character,'w') == 1 && strcmp(event.Modifier,'command') == 1) || ...
        (strcmp(event.Character,'F4') == 1 && strcmp(event.Modifier,'alt') == 1)
    % branch for closing the main figure
    if strcmp(hObject.Tag,'figureMain')
        figureMain_CloseRequestFcn(hObject, []);
    end
    close gcf
end

% --- Executes before closing the figure.
function figureMain_CloseRequestFcn(hObject, ~)

% remove temporary file
handles = guihandles(hObject);
appRoot = getappdata(handles.figureMain,'appRoot');
pdfTemp = [appRoot,filesep,'pdf.html'];
if exist(pdfTemp,'file') ~= 0
    delete(pdfTemp);
end

% --- Executes during object resizing.
function figureMain_SizeChangedFcn(hObject, ~)

% get handles of GUI objects
handles = guihandles(hObject);
objNames = getappdata(hObject, 'objNames');

% get position and size values
objSize = getappdata(hObject,'objSize');

% previous figure size
fig_W1 = objSize.(objNames{1}).W1;
fig_H1 = objSize.(objNames{1}).H1;

% current figure size
fig_W2 = handles.(objNames{1}).Position(3);
fig_H2 = handles.(objNames{1}).Position(4);

% difference between previous and current sizes
DW = fig_W2 - fig_W1;
DH = fig_H2 - fig_H1;

% change object size values
n = length(objNames);
for k = 2:n
    
    % WIDTH
    % define values
    W1 = handles.(objNames{k}).Position(3); % previous size
    W2 = W1 + DW; % projected size
    WMIN = objSize.(objNames{k}).WMIN;
    WMAX = objSize.(objNames{k}).WMAX;
    X0 = objSize.(objNames{k}).X0;
    R0 = objSize.(objNames{k}).R0;
    R2 = fig_W2 - W2 - X0; % projected right padding
    
    % change object settings
    if (W2 > WMIN && W2 < WMAX) && W2 + R2 > WMIN + R0
        % change: size within limis and object within viewport
        handles.(objNames{k}).Position(3) = W2;
        objSize.(objNames{k}).W1 = W2;
    elseif W2 < WMIN || W2 + R2 < WMIN + R0
        % no change; size is minimal or object outside viewport
        handles.(objNames{k}).Position(3) = WMIN;
        objSize.(objNames{k}).W1 = WMIN;
    elseif W2 > WMAX
        % no change; size is maximal
        handles.(objNames{k}).Position(3) = WMAX;
        objSize.(objNames{k}).W1 = WMAX;
    end

    % HEIGHT
    H1 = handles.(objNames{k}).Position(4);
    H2 = H1 + DH;
    HMIN = objSize.(objNames{k}).HMIN;
    HMAX = objSize.(objNames{k}).HMAX;
    Y0 = objSize.(objNames{k}).Y0;
    T0 = objSize.(objNames{k}).T0;
    T2 = fig_H2 - H2 - Y0;
    if (H2 > HMIN && H2 < HMAX) && H2 + T2 > HMIN + T0
        handles.(objNames{k}).Position(4) = H2;
        objSize.(objNames{k}).H1 = H2;
    elseif H2 < HMIN || H2 + T2 < HMIN + T0
        handles.(objNames{k}).Position(4) = HMIN;
        objSize.(objNames{k}).H1 = HMIN;
    elseif H2 > HMAX
        handles.(objNames{k}).Position(4) = HMAX;
        objSize.(objNames{k}).H1 = HMAX;
    end

end

% set previous value to the current one
objSize.(objNames{1}).W1 = fig_W2;
objSize.(objNames{1}).H1 = fig_H2;

% reposition top-aligned objects
objNamesTop = getappdata(hObject, 'objNamesTop');

n = length(objNamesTop);
for k = 1:n

    % get parent
    p = handles.(objNamesTop{k}).Parent;
    p = p.Tag;
    
    % get initial and previous vertical locations
    Y1 = objSize.(objNamesTop{k}).Y1;

    % don't reposition if the parent is outside resizing limits
    if objSize.(p).H1 <= objSize.(p).HMIN || ...
            objSize.(p).H1 >= objSize.(p).HMAX
        continue
    end

    % give object and figure the same units
    t = handles.(objNamesTop{k}).Units;
    handles.(objNamesTop{k}).Units = handles.(objNames{1}).Units;

    % set new vertical location
    handles.(objNamesTop{k}).Position(2) = Y1 + DH;
    objSize.(objNamesTop{k}).Y1 = Y1 + DH;
    
    % undo object units change
    handles.(objNamesTop{k}).Units = t;
end

% update size data and handles
setappdata(handles.(objNames{1}),'objSize',objSize)
guidata(hObject, handles);


% ------------------------------------
% AXES
% ------------------------------------

function axesViz_CreateFcn(hObject, ~)

handles = guihandles(hObject);
pixdir = getappdata(handles.figureMain,'pixdir');
axes(hObject)
imshow(fullfile(pixdir,'towers-splash.jpg'))
axis off

% have to rewrite object Tag, since it is deleted by imshow
set(gca,'Tag','axesViz')
handles.axesViz = gca;
guidata(hObject, handles);


function axesLogo_CreateFcn(hObject, ~)

handles = guihandles(hObject);
pixdir = getappdata(handles.figureMain,'pixdir');
axes(hObject)
imshow(fullfile(pixdir,'towers-logo.jpg'))

% have to rewrite object Tag, since it is deleted by imshow
set(gca,'Tag','axesLogo')
handles.axesLogo = gca;
guidata(hObject, handles);


% ------------------------------------
% OBJECTS
% ------------------------------------

% -- documents
function checkboxDocuments_Callback(hObject, ~)

% get data
fn = 'Documents';
handles = guihandles(hObject);
hFigureMain = handles.figureMain;
preferences = getappdata(hFigureMain,'preferences');
geometry = getappdata(hFigureMain,'geometry');
hObjectClasses = getappdata(hFigureMain,'hObjectClasses');
n = length(geometry);

% get document range
if isempty(preferences.documentRange)
    r1 = 1;
    r2 = n;
else
    r1 = preferences.documentRange(1);
    r2 = preferences.documentRange(2);
end

% show only documents in selected range
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


function radiobuttonDocumentRangeAll_Callback(hObject, ~)

handles = guihandles(hObject);
if hObject.Value == 1
    
    % deactivation of opposite choice controls
    handles.radiobuttonDocumentRangeSelection.Value = 0;
    handles.editDocumentRangeSelection1.Enable = 'off';
    handles.editDocumentRangeSelection2.Enable = 'off';
    handles.pushbuttonDocumentRangeApply.Enable = 'off';

    % mark selection as being "all pages"
    preferences = getappdata(handles.figureMain,'preferences');
    preferences.documentRange = [];
    setappdata(handles.figureMain,'preferences',preferences)
    
    % redraw
    pushbuttonDocumentRangeApply_Callback(hObject)
else
    hObject.Value = 1;
end


function radiobuttonDocumentRangeSelection_Callback(hObject, ~)

handles = guihandles(hObject);
if hObject.Value == 1
    
    % deactivation of opposite choice controls
    handles.radiobuttonDocumentRangeAll.Value = 0;
    handles.editDocumentRangeSelection1.Enable = 'on';
    handles.editDocumentRangeSelection2.Enable = 'on';
    handles.pushbuttonDocumentRangeApply.Enable = 'on';
else
    hObject.Value = 1;
end

% save values
preferences = getappdata(handles.figureMain,'preferences');
preferences.documentRange = [...
    str2num(handles.editDocumentRangeSelection1.String),...
    str2num(handles.editDocumentRangeSelection2.String)]; %#ok<ST2NM>
setappdata(handles.figureMain,'preferences',preferences)


function editDocumentRangeSelection1_Callback(hObject, ~)

% convert content to positive integer
handles = guihandles(hObject);
r1 = handles.editDocumentRangeSelection1.String;
r2 = handles.editDocumentRangeSelection2.String;

if ~isempty(r1)
    if isempty(regexp(r1,'[1-9]','once'))
        msgbox('Document numbers should be positive, non-zero integers.', ...
            'Error', 'error')
        handles.editDocumentRangeSelection1.String = r2;
        return
    end
    r1 = floor(abs(str2num(r1))); %#ok<ST2NM>
    if isempty(r2)
        r2 = r1;
    else
        r2 = str2double(r2);
    end
    if r1 > r2
        % make values monotounously increasing
        r2 = r1;
    end
    r1 = num2str(r1);
    r2 = num2str(r2);
    handles.editDocumentRangeSelection1.String = r1;
    handles.editDocumentRangeSelection2.String = r2;
else
    % make range if none given
    handles.editDocumentRangeSelection1.String = ...
        handles.editDocumentRangeSelection2.String;
end

% save values
preferences = getappdata(handles.figureMain,'preferences');
preferences.documentRange = [...
    str2num(handles.editDocumentRangeSelection1.String),...
    str2num(handles.editDocumentRangeSelection2.String)]; %#ok<ST2NM>
setappdata(handles.figureMain,'preferences',preferences)


function editDocumentRangeSelection2_Callback(hObject, ~)

% convert content to positive integer
handles = guihandles(hObject);
r1 = handles.editDocumentRangeSelection1.String;
r2 = handles.editDocumentRangeSelection2.String;

if ~isempty(r2)
    if isempty(regexp(r2,'[1-9]','once'))
        msgbox('Document numbers should be positive, non-zero integers.', ...
            'Error', 'error')
        handles.editDocumentRangeSelection2.String = r1;
        return
    end
    if isempty(r1)
        r1 = r2;
    else
        r1 = str2double(r1);
    end
    r2 = floor(abs(str2num(r2))); %#ok<ST2NM>
    if r2 < r1
        % make values monotounously increasing
        r2 = r1;
    end
    % check for out of range
    geometry = getappdata(handles.figureMain,'geometry');
    n = length(geometry);
    if r2 > n
        r2 = n;
    end
    r1 = num2str(r1);
    r2 = num2str(r2);
    handles.editDocumentRangeSelection1.String = r1;
    handles.editDocumentRangeSelection2.String = r2;
else
    % make range if none given
    handles.editDocumentRangeSelection2.String = ...
        handles.editDocumentRangeSelection1.String;
end

% save values
preferences = getappdata(handles.figureMain,'preferences');
preferences.documentRange = [...
    str2num(handles.editDocumentRangeSelection1.String),...
    str2num(handles.editDocumentRangeSelection2.String)]; %#ok<ST2NM>
setappdata(handles.figureMain,'preferences',preferences)


function pushbuttonDocumentRangeApply_Callback(hObject, ~)

% get data
handles = guihandles(hObject);
hFigureMain = handles.figureMain;
preferences = getappdata(hFigureMain,'preferences');
geometry = getappdata(hFigureMain,'geometry');
hObjectClasses = getappdata(hFigureMain,'hObjectClasses');
fn = fieldnames(hObjectClasses);
n1 = length(geometry);
n2 = numel(fn);

% get document range
if isempty(preferences.documentRange)
    r1 = 1;
    r2 = n1;
else
    r1 = preferences.documentRange(1);
    r2 = preferences.documentRange(2);
end

% show only documents in selected range
for k1 = 1:n1
    for k2 = 1:n2
        visibility = 'off';
        if (k1 >= r1 && k1 <= r2) && ...
                handles.(['checkbox' char(fn(k2))]).Value == 1
            visibility = 'on';
        end
        hObjectClasses( n1-k1+1 ).(char(fn(k2))).Visible = visibility;
    end
end
checkboxTags_Callback(hObject)
checkboxTicks_Callback(hObject)

% -- pages
function checkboxPages_Callback(hObject, ~)

% get data
fn = 'Pages';
handles = guihandles(hObject);
hFigureMain = handles.figureMain;
preferences = getappdata(hFigureMain,'preferences');
geometry = getappdata(hFigureMain,'geometry');
hObjectClasses = getappdata(hFigureMain,'hObjectClasses');
n = length(geometry);

% get document range
if isempty(preferences.documentRange)
    r1 = 1;
    r2 = n;
else
    r1 = preferences.documentRange(1);
    r2 = preferences.documentRange(2);
end

% make visible only documents in selected range
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


function radiobuttonPageRangeAll_Callback(hObject, ~)

handles = guihandles(hObject);
if hObject.Value == 1
    
    % deactivation of opposite choice controls
    handles.radiobuttonPageRangeSelection.Value = 0;
    handles.editPageRangeSelection1.Enable = 'off';
    handles.editPageRangeSelection2.Enable = 'off';
    handles.pushbuttonPageRangeApply.Enable = 'off';

    % mark selection as being "all pages"
    preferences = getappdata(handles.figureMain,'preferences');
    preferences.spreadRange = [];
    setappdata(handles.figureMain,'preferences',preferences)
    
    % page selection applies only on all documents
    handles.radiobuttonDocumentRangeAll.Value = 1;
    handles.radiobuttonDocumentRangeSelection.Value = 0;
    handles.editDocumentRangeSelection1.Enable = 'off';
    handles.editDocumentRangeSelection2.Enable = 'off';
    handles.pushbuttonDocumentRangeApply.Enable = 'off';
    preferences.documentRange = [];
    setappdata(handles.figureMain,'preferences',preferences)

    % redraw
    pushbuttonPageRangeApply_Callback(hObject)
else
    hObject.Value = 1;
end


function radiobuttonPageRangeSelection_Callback(hObject, ~)

handles = guihandles(hObject);
if hObject.Value == 1
    
    % activation of appropriate choice controls
    handles.radiobuttonPageRangeAll.Value = 0;
    handles.editPageRangeSelection1.Enable = 'on';
    handles.editPageRangeSelection2.Enable = 'on';
    handles.pushbuttonPageRangeApply.Enable = 'on';
else
    hObject.Value = 1;
end

% page selection applies only on all documents
handles.radiobuttonDocumentRangeAll.Value = 1;
handles.radiobuttonDocumentRangeSelection.Value = 0;
handles.editDocumentRangeSelection1.Enable = 'off';
handles.editDocumentRangeSelection2.Enable = 'off';
handles.pushbuttonDocumentRangeApply.Enable = 'off';
preferences = getappdata(handles.figureMain,'preferences');
preferences.documentRange = [];

% save values
preferences.spreadRange = [...
    str2num(handles.editPageRangeSelection1.String),...
    str2num(handles.editPageRangeSelection2.String)]; %#ok<ST2NM>
setappdata(handles.figureMain,'preferences',preferences)


function editPageRangeSelection1_Callback(hObject, ~)

% convert content to positive integer
handles = guihandles(hObject);
r1 = handles.editPageRangeSelection1.String;
r2 = handles.editPageRangeSelection2.String;

if ~isempty(r1)
    if isempty(regexp(r1,'[1-9]','once'))
        msgbox('Page numbers should be positive, non-zero integers.', 'Error', 'error')
        handles.editPageRangeSelection1.String = r2;
        return
    end
    r1 = floor(abs(str2num(r1))); %#ok<ST2NM>
    if isempty(r2)
        r2 = r1;
    else
        r2 = str2double(r2);
    end
    if r1 > r2
        % make values monotounously increasing
        r2 = r1;
    end
    r1 = num2str(r1);
    r2 = num2str(r2);
    handles.editPageRangeSelection1.String = r1;
    handles.editPageRangeSelection2.String = r2;
else
    % make range if none given
    handles.editPageRangeSelection1.String = ...
        handles.editPageRangeSelection2.String;
end

% save values
preferences = getappdata(handles.figureMain,'preferences');
preferences.spreadRange = [...
    str2num(handles.editPageRangeSelection1.String),...
    str2num(handles.editPageRangeSelection2.String)]; %#ok<ST2NM>
setappdata(handles.figureMain,'preferences',preferences)


function editPageRangeSelection2_Callback(hObject, ~)

% convert content to positive integer
handles = guihandles(hObject);
r1 = handles.editPageRangeSelection1.String;
r2 = handles.editPageRangeSelection2.String;

if ~isempty(r2)
    if isempty(regexp(r2,'[1-9]','once'))
        msgbox('Page numbers should be positive, non-zero integers.', 'Error', 'error')
        handles.editPageRangeSelection2.String = r1;
        return
    end
    if isempty(r1)
        r1 = r2;
    else
        r1 = str2double(r1);
    end
    r2 = floor(abs(str2num(r2))); %#ok<ST2NM>
    % make values monotounously increasing
    if r2 < r1
        r2 = r1;
    end
    r1 = num2str(r1);
    r2 = num2str(r2);
    handles.editPageRangeSelection1.String = r1;
    handles.editPageRangeSelection2.String = r2;
else
    % make range if none given
    handles.editPageRangeSelection2.String = ...
        handles.editPageRangeSelection1.String;
end

% save values
preferences = getappdata(handles.figureMain,'preferences');
preferences.spreadRange = [...
    str2num(handles.editPageRangeSelection1.String),...
    str2num(handles.editPageRangeSelection2.String)]; %#ok<ST2NM>
setappdata(handles.figureMain,'preferences',preferences)


function pushbuttonPageRangeApply_Callback(hObject, ~)

handles = guihandles(hObject);
hFigureMain = handles.figureMain;
preferences = getappdata(hFigureMain,'preferences');

if ~isempty(preferences.spreadRange)
    % get page range
    r1 = handles.editPageRangeSelection1.String;
    r2 = handles.editPageRangeSelection2.String;

    % check for empty range
    if ~isempty(r1) && ~isempty(r2)

        r1 = str2num(r1); %#ok<ST2NM>
        r2 = str2num(r2); %#ok<ST2NM>

        % convert to spread range
        r1 = floor(r1/2) + 1;
        r2 = floor(r2/2) + 1;

        % memorize selection
        preferences.spreadRange = [r1 r2];
    else
        preferences.spreadRange = [];
    end
    setappdata(hFigureMain,'preferences',preferences)
end

% delete existent graphics objects
hObjectClasses = getappdata(hFigureMain,'hObjectClasses');
fn = fieldnames(hObjectClasses);
n1 = numel(fn);
for k1 = 1:n1
    n2 = numel(hObjectClasses);
    for k2 = 1:n2
        delete(hObjectClasses(k2).(char(fn(k1))))
    end
end
hObjectClasses = struct;
setappdata(hFigureMain,'hObjectClasses',hObjectClasses);

% reset gui settings
handles.checkboxDocuments.Value = 0;
handles.checkboxPages.Value = 1;
handles.checkboxText.Value = 1;
handles.checkboxImages.Value = 1;
handles.checkboxGraphics.Value = 1;
handles.checkboxFonts.Value = 0;
handles.radiobuttonPaintNone.Value = 1;
handles.radiobuttonPaintCardinality.Value = 0;
handles.radiobuttonPaintFill.Value = 0;
handles.radiobuttonPaintSalliency.Value = 0;
handles.radiobuttonPaintConfiguration.Value = 0;
handles.radiobuttonPaintInfoPotential.Value = 0;

% page selection applies only on all documents
handles.radiobuttonDocumentRangeAll.Value = 1;
handles.radiobuttonDocumentRangeSelection.Value = 0;
handles.editDocumentRangeSelection1.Enable = 'off';
handles.editDocumentRangeSelection2.Enable = 'off';
handles.pushbuttonDocumentRangeApply.Enable = 'off';
preferences.documentRange = [];
setappdata(handles.figureMain,'preferences',preferences)

% get object data
geometry = getappdata(hFigureMain,'geometry');
metadata = getappdata(hFigureMain,'metadata');
docsPerFig = getappdata(hFigureMain,'docsPerFig');
nFiles = length(geometry);
docRank.n = nFiles;
textFaceAlpha = [];
objectClassesShow = {'Documents','Pages','Text','Images','Graphics'};
tags = [];
addVizMode = 'replaceRange';

% document location in a planar, rectangular, fixed distance grid
grid = struct;
grid.x = 0;
grid.y = 0;
grid.ykmax = ceil( sqrt( nFiles ) ); % documents per row of a square grid
grid.yk = 1; % current document index
grid.xk1 = 0; % current document x axis displacement
grid.xk2 = 0; % next document x axis displacement
setappdata(hFigureMain,'grid',grid)

% draw
for kFiles = 1:nFiles % files

    docRank.k = kFiles;
    url.documentFileName = metadata(kFiles).filename;

    towers_show(...
        geometry(kFiles).spreads, metadata(kFiles), url, ...
        docsPerFig, hFigureMain, docRank, ...
        textFaceAlpha, objectClassesShow, tags, addVizMode);
end


% -- text
function checkboxText_Callback(hObject, ~)

% get data
fn = 'Text';
handles = guihandles(hObject);
hFigureMain = handles.figureMain;
preferences = getappdata(hFigureMain,'preferences');
geometry = getappdata(hFigureMain,'geometry');
hObjectClasses = getappdata(hFigureMain,'hObjectClasses');
n = length(geometry);

% get document range
if isempty(preferences.documentRange)
    r1 = 1;
    r2 = n;
else
    r1 = preferences.documentRange(1);
    r2 = preferences.documentRange(2);
end

% show only documents in selected range
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


% -- images
function checkboxImages_Callback(hObject, ~)

% get data
fn = 'Images';
handles = guihandles(hObject);
hFigureMain = handles.figureMain;
preferences = getappdata(hFigureMain,'preferences');
geometry = getappdata(hFigureMain,'geometry');
hObjectClasses = getappdata(hFigureMain,'hObjectClasses');
n = length(geometry);

% get document range
if isempty(preferences.documentRange)
    r1 = 1;
    r2 = n;
else
    r1 = preferences.documentRange(1);
    r2 = preferences.documentRange(2);
end

% show only documents in selected range
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


% -- graphics
function checkboxGraphics_Callback(hObject, ~)

% get data
fn = 'Graphics';
handles = guihandles(hObject);
hFigureMain = handles.figureMain;
preferences = getappdata(hFigureMain,'preferences');
geometry = getappdata(hFigureMain,'geometry');
hObjectClasses = getappdata(hFigureMain,'hObjectClasses');
n = length(geometry);

% get document range
if isempty(preferences.documentRange)
    r1 = 1;
    r2 = n;
else
    r1 = preferences.documentRange(1);
    r2 = preferences.documentRange(2);
end

% show only documents in selected range
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


% -- fonts
function checkboxFonts_Callback(hObject, ~)

% NOTE: Since there are too many font objects and they create occulsion
% in the visualization, we won't draw them unless required to do so by 
% the user; so by default the 'Fonts' checkbox is unchecked.

% get data
fn = 'Fonts';
handles = guihandles(hObject);
hFigureMain = handles.figureMain;
preferences = getappdata(hFigureMain,'preferences');
geometry = getappdata(hFigureMain,'geometry');
hObjectClasses = getappdata(hFigureMain,'hObjectClasses');
n = length(geometry);

% get document range
if isempty(preferences.documentRange)
    r1 = 1;
    r2 = n;
else
    r1 = preferences.documentRange(1);
    r2 = preferences.documentRange(2);
end

% show only documents in selected range
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


% create font selection GUI
function pushbuttonFontsSelect_Callback(~, ~)
towers_select_fonts()

% create label selection GUI
function pushbuttonLabelsSelect_Callback(~, ~)
towers_select_labels();


% --- paint
function radiobuttonPaintNone_Callback(hObject, ~)
towers_PaintNone(hObject)

function radiobuttonPaintCardinality_Callback(hObject, ~)
towers_PaintCardinality(hObject)

function radiobuttonPaintFill_Callback(hObject, ~)
towers_PaintFill(hObject)

function radiobuttonPaintSalliency_Callback(hObject, ~)
% compute salliency in a n-dimensional pattern phase space
towers_PaintSalliency(hObject) % uniform - regular - irregular
% towers_PaintSalliencyBinary(hObject) % regular - irregular

function radiobuttonPaintConfiguration_Callback(hObject, ~)
towers_PaintConfiguration(hObject)

function radiobuttonPaintInfoPotential_Callback(hObject, ~)
towers_PaintInfoPotential(hObject)

function pushbuttonPaintUpdate_Callback(hObject, ~)

% delete paint data
handles = guihandles(hObject);
hFigureMain = handles.figureMain;
metrics = getappdata(hFigureMain,'metrics');
if isfield(metrics,'Cardinality')
    metrics = rmfield(metrics,'Cardinality');
end
if isfield(metrics,'Fill')
    metrics = rmfield(metrics,'Fill');
end
if isfield(metrics,'SalliencyRatio')
    metrics = rmfield(metrics,'SalliencyRatio');
end
if isfield(metrics,'SalliencyPhi')
    metrics = rmfield(metrics,'SalliencyPhi');
end
if isfield(metrics,'SalliencyAbs')
    metrics = rmfield(metrics,'SalliencyAbs');
end
if isfield(metrics,'Configuration')
    metrics = rmfield(metrics,'Configuration');
end
if isfield(metrics,'InfoPotential')
    metrics = rmfield(metrics,'InfoPotential');
end
setappdata(handles.figureMain,'metrics',metrics);

% update paint data
if handles.radiobuttonPaintNone.Value == 1
    radiobuttonPaintNone_Callback(hObject)
elseif handles.radiobuttonPaintCardinality.Value == 1
    radiobuttonPaintCardinality_Callback(hObject)
elseif handles.radiobuttonPaintFill.Value == 1
    radiobuttonPaintFill_Callback(hObject)
elseif handles.radiobuttonPaintSalliency.Value == 1
    radiobuttonPaintSalliency_Callback(hObject)
elseif handles.radiobuttonPaintConfiguration.Value == 1
    radiobuttonPaintConfiguration_Callback(hObject)
elseif handles.radiobuttonPaintInfoPotential.Value == 1
    radiobuttonPaintInfoPotential_Callback(hObject)
end


% -- tags
function checkboxTags_Callback(hObject, ~)

% get data
fn = 'Tags';
handles = guihandles(hObject);
hFigureMain = handles.figureMain;
preferences = getappdata(hFigureMain,'preferences');
geometry = getappdata(hFigureMain,'geometry');
hTags = getappdata(hFigureMain,'hTags');
hFilenames = getappdata(hFigureMain,'hFilenames');
n = length(geometry);

% get document range
if isempty(preferences.documentRange)
    r1 = 1;
    r2 = n;
else
    r1 = preferences.documentRange(1);
    r2 = preferences.documentRange(2);
end

% show only documents in selected range
for k = 1:n
    visibility = 'off';
    if (k >= r1 && k <= r2) && handles.(['checkbox' fn]).Value == 1
        visibility = 'on';
    end
    if ~isempty(hTags) && isfield(hTags( n-k+1 ),'Tags') == 1
        activeTagsClass = hTags( n-k+1 ).Tags.active;
        hTags( n-k+1 ).Tags.(activeTagsClass).Visible = visibility;
    end
    if ~isempty(hFilenames) && isfield(hFilenames( n-k+1 ),'Filenames') == 1
        hFilenames( n-k+1 ).Filenames.Visible = visibility;
    end
end

% reset default axes values
axesLim = getappdata(handles.figureMain,'axesLim');
set(handles.axesViz,'XLim',axesLim(1,:),'YLim',axesLim(2,:),'ZLim',axesLim(3,:))


% select tag class
function popupmenuTags_Callback(hObject, ~)

% get data
handles = guihandles(hObject);
hFigureMain = handles.figureMain;
preferences = getappdata(hFigureMain,'preferences');
geometry = getappdata(hFigureMain,'geometry');
n = length(geometry);
handles.checkboxTags.Value = 1;
hTags = getappdata(handles.figureMain,'hTags');
if isempty(hTags) || numel(fields(hTags)) == 0
    return
end

% get document range
if isempty(preferences.documentRange)
    r1 = 1;
    r2 = n;
else
    r1 = preferences.documentRange(1);
    r2 = preferences.documentRange(2);
end

% switch active tag class off
for k = 1:n
    activeTagsClass = hTags( n-k+1 ).Tags.active;
    if k >= r1 && k <= r2
        hTags( n-k+1 ).Tags.(activeTagsClass).Visible = 'off';
    end
end

% get index of selected class
selectedTags = hObject.String{hObject.Value};
selectedTags = strrep(selectedTags,' ','_');

% switch selected class on
for k = 1:n
    if k >= r1 && k <= r2
    	hTags( n-k+1 ).Tags.(selectedTags).Visible = 'on';
    end
end

% memorize selected class as the active one
for k = 1:n
    hTags(k).Tags.active = selectedTags;
end
setappdata(handles.figureMain,'hTags',hTags);


% -- ticks
function checkboxTicks_Callback(hObject, ~)

% get data
fn = 'Ticks';
handles = guihandles(hObject);
hFigureMain = handles.figureMain;
preferences = getappdata(hFigureMain,'preferences');
geometry = getappdata(hFigureMain,'geometry');
hTicks = getappdata(hFigureMain,'hTicks');
n = length(geometry);

% get document range
if isempty(preferences.documentRange)
    r1 = 1;
    r2 = n;
else
    r1 = preferences.documentRange(1);
    r2 = preferences.documentRange(2);
end

% show only documents in selected range
for k = 1:n
    visibility = 'off';
    if (k >= r1 && k <= r2) && handles.(['checkbox' fn]).Value == 1
        visibility = 'on';
    end
    hTicks( n-k+1 ).(fn).Visible = visibility;
end

% reset default axes values
axesLim = getappdata(handles.figureMain,'axesLim');
set(handles.axesViz,'XLim',axesLim(1,:),'YLim',axesLim(2,:),'ZLim',axesLim(3,:))



% ------------------------------------
% 3D INTERACTION
% ------------------------------------

function toolZoom_Callback(hObject, ~)
handles = guihandles(hObject);
hTool = zoom(handles.figureMain);
pixdir = getappdata(handles.figureMain,'pixdir');

if strcmp(hTool.Enable,'off') == 1
    rotate3d off
    pan off
    zoom on
    handles.toolZoom.CData = imread(fullfile(pixdir,'iconZneg.jpg'));
    handles.toolRotate.CData = imread(fullfile(pixdir,'iconR.jpg'));
    handles.toolPan.CData = imread(fullfile(pixdir,'iconP.jpg'));
else
    zoom off
    handles.toolZoom.CData = imread(fullfile(pixdir,'iconZ.jpg'));
end

function toolRotate_Callback(hObject, ~)
handles = guihandles(hObject);
hTool = rotate3d(handles.figureMain);
pixdir = getappdata(handles.figureMain,'pixdir');

if strcmp(hTool.Enable,'off') == 1
    zoom off
    pan off
    rotate3d on
    handles.toolZoom.CData = imread(fullfile(pixdir,'iconZ.jpg'));
    handles.toolRotate.CData = imread(fullfile(pixdir,'iconRneg.jpg'));
    handles.toolPan.CData = imread(fullfile(pixdir,'iconP.jpg'));
    handles.toolViewOblique.CData = imread(fullfile(pixdir,'iconO.jpg'));
    handles.toolViewFront.CData = imread(fullfile(pixdir,'iconF.jpg'));
    handles.toolViewSide.CData = imread(fullfile(pixdir,'iconS.jpg'));
    handles.toolViewTop.CData = imread(fullfile(pixdir,'iconT.jpg'));
else
    rotate3d off
    handles.toolRotate.CData = imread(fullfile(pixdir,'iconR.jpg'));
end

function toolPan_Callback(hObject, ~)
handles = guihandles(hObject);
hTool = pan(handles.figureMain);
pixdir = getappdata(handles.figureMain,'pixdir');

if strcmp(hTool.Enable,'off') == 1
    zoom off
    rotate3d off
    pan on
    handles.toolZoom.CData = imread(fullfile(pixdir,'iconZ.jpg'));
    handles.toolRotate.CData = imread(fullfile(pixdir,'iconR.jpg'));
    handles.toolPan.CData = imread(fullfile(pixdir,'iconPneg.jpg'));
else
    pan off
    handles.toolPan.CData = imread(fullfile(pixdir,'iconP.jpg'));
end


% -- selected points of view
% oblique
function toolViewOblique_Callback(hObject, ~)
handles = guihandles(hObject);
preferences = getappdata(handles.figureMain,'preferences');
pixdir = getappdata(handles.figureMain,'pixdir');
view(handles.axesViz,preferences.view)

handles.toolViewOblique.CData = imread(fullfile(pixdir,'iconOneg.jpg'));
handles.toolViewFront.CData = imread(fullfile(pixdir,'iconF.jpg'));
handles.toolViewSide.CData = imread(fullfile(pixdir,'iconS.jpg'));
handles.toolViewTop.CData = imread(fullfile(pixdir,'iconT.jpg'));

% front
function toolViewFront_Callback(hObject, ~)
handles = guihandles(hObject);
pixdir = getappdata(handles.figureMain,'pixdir');
view(handles.axesViz,[90 0])

handles.toolViewOblique.CData = imread(fullfile(pixdir,'iconO.jpg'));
handles.toolViewFront.CData = imread(fullfile(pixdir,'iconFneg.jpg'));
handles.toolViewSide.CData = imread(fullfile(pixdir,'iconS.jpg'));
handles.toolViewTop.CData = imread(fullfile(pixdir,'iconT.jpg'));

% side
function toolViewSide_Callback(hObject, ~)
handles = guihandles(hObject);
pixdir = getappdata(handles.figureMain,'pixdir');
view(handles.axesViz,[0 0])

handles.toolViewOblique.CData = imread(fullfile(pixdir,'iconO.jpg'));
handles.toolViewFront.CData = imread(fullfile(pixdir,'iconF.jpg'));
handles.toolViewSide.CData = imread(fullfile(pixdir,'iconSneg.jpg'));
handles.toolViewTop.CData = imread(fullfile(pixdir,'iconT.jpg'));

% top
function toolViewTop_Callback(hObject, ~)
handles = guihandles(hObject);
pixdir = getappdata(handles.figureMain,'pixdir');
view(handles.axesViz,[90 90])

handles.toolViewOblique.CData = imread(fullfile(pixdir,'iconO.jpg'));
handles.toolViewFront.CData = imread(fullfile(pixdir,'iconF.jpg'));
handles.toolViewSide.CData = imread(fullfile(pixdir,'iconS.jpg'));
handles.toolViewTop.CData = imread(fullfile(pixdir,'iconTneg.jpg'));


% ------------------------------------
% OPEN
% ------------------------------------

function menuSelectDocuments_Callback(hObject, ~)

% select directory interactively
url = uigetdir('','Select directory of geometry data files');
if sum(double(url)) == 0
    return
elseif size(dir(fullfile(url,'*.json')),1) == 0
    msgbox('No geometry files in this directory', 'Error','error');
    return
end

% save selected url
handles = guihandles(hObject);
hFigureMain = handles.figureMain;
setappdata(hFigureMain,'docsurl',url);

% now visualize documents
menuVisualize_Callback(hObject)


function menuVisualize_Callback(hObject, ~)

handles = guihandles(hObject);
hFigureMain = handles.figureMain;

% read documents url
url = getappdata(hFigureMain,'docsurl');

% remove previous graphics
setappdata(hFigureMain,'hObjectClasses',{})
setappdata(hFigureMain,'hFilenames',{})
setappdata(hFigureMain,'hTags',{})
setappdata(hFigureMain,'hTicks',{})
preferences = getappdata(hFigureMain,'preferences');
axes(handles.axesViz)
cla reset
axis ij
axis equal
axis off
camproj(preferences.vizProjection)
view(preferences.view)
setAxes3DPanAndZoomStyle(zoom,gca,'camera') % don't clip graphics in axis

% 'cla' deleted the axes Tag property, so lets write it back
set(gca,'Tag','axesViz')
handles.axesViz = gca;
handles.panelVisualization.BackgroundColor = preferences.color.white;
guidata(hObject, handles);

% set default checkbox states
handles.checkboxDocuments.Value = 0;
handles.radiobuttonDocumentRangeAll.Value = 1;
handles.radiobuttonDocumentRangeSelection.Value = 0;
handles.editDocumentRangeSelection1.String = '';
handles.editDocumentRangeSelection2.String = '';
handles.editDocumentRangeSelection1.Enable = 'off';
handles.editDocumentRangeSelection2.Enable = 'off';
handles.pushbuttonPageRangeApply.Enable = 'off';
preferences.documentRange = [];
setappdata(handles.figureMain,'preferences',preferences)

handles.checkboxPages.Value = 1;
handles.radiobuttonPageRangeAll.Value = 1;
handles.radiobuttonPageRangeSelection.Value = 0;
handles.editPageRangeSelection1.String = '';
handles.editPageRangeSelection2.String = '';
handles.editPageRangeSelection1.Enable = 'off';
handles.editPageRangeSelection2.Enable = 'off';
handles.pushbuttonPageRangeApply.Enable = 'off';
preferences.spreadRange = [];
setappdata(handles.figureMain,'preferences',preferences)

handles.checkboxText.Value = 1;
handles.checkboxImages.Value = 1;
handles.checkboxGraphics.Value = 1;
handles.checkboxFonts.Value = 0;
handles.checkboxFonts.Enable = 'on';
handles.pushbuttonFontsSelect.Enable = 'on';
handles.checkboxTags.Value = 1;
handles.checkboxTicks.Value = 1;

handles.radiobuttonPaintNone.Value = 1;
handles.radiobuttonPaintCardinality.Value = 0;
handles.radiobuttonPaintFill.Value = 0;
handles.radiobuttonPaintSalliency.Value = 0;
handles.radiobuttonPaintConfiguration.Value = 0;
handles.radiobuttonPaintInfoPotential.Value = 0;

% reset tags data and menu
hTagsClasses = struct;
setappdata(handles.figureMain,'hTagsClasses',hTagsClasses)
handles.popupmenuTags.String = {'None'};
handles.popupmenuTags.Value = 1;
hTicks = struct;
setappdata(handles.figureMain,'hTicks',hTicks)

% open document geometry file
towers_load(handles.figureMain, url);

% set figure name
url = getappdata(hFigureMain,'url');
docsPerFig = getappdata(hFigureMain,'docsPerFig');
if strcmp(docsPerFig,'single')
    hFigureMain.Name = url.file;
else
    hFigureMain.Name = url.dir;
end

% reset font selection index
fontsSelectionIdx.name = 1;
fontsSelectionIdx.size = 1;
fontsSelectionIdx.color = 1;
fontsSelectionIdx.transparency = 1;
setappdata(hFigureMain,'fontsSelectionIdx',fontsSelectionIdx);

% if the "Open File" button is not virgin, stop here,
% no need to change button color & enable ui controls
if handles.panelVisualization.BackgroundColor(1) ~= 1

    % handle font data availability
    handles.checkboxFonts.Value = 0;
    statistics = getappdata(hFigureMain,'statistics');
    if statistics.Fonts == 0
        handles.checkboxFonts.Enable = 'off';
        handles.pushbuttonFontsSelect.Enable = 'off';
    end

    % handle tags availability
    hTagsClasses = getappdata(handles.figureMain,'hTagsClasses');
    if isempty(hTagsClasses)
        handles.checkboxTags.Enable = 'off';
        handles.popmenuTags.Enable = 'off';
    end

    guidata(hObject, handles);
    return
end

% enable controls
s = fieldnames(handles);
n = length(s);
for k = 1:n
    try
        % workaround to "isfield(handles.(char(s(k))),'Enable')"
        handles.(char(s(k))).Enable;
    catch
        continue
    end
    handles.(char(s(k))).Enable = 'on';
end

% exceptions
handles.radiobuttonDocumentRangeAll.Value = 1;
handles.radiobuttonDocumentRangeSelection.Value = 0;
handles.editDocumentRangeSelection1.Enable = 'off';
handles.editDocumentRangeSelection2.Enable = 'off';
handles.pushbuttonDocumentRangeApply.Enable = 'off';

handles.radiobuttonPageRangeAll.Value = 1;
handles.radiobuttonPageRangeSelection.Value = 0;
handles.editPageRangeSelection1.Enable = 'off';
handles.editPageRangeSelection2.Enable = 'off';
handles.pushbuttonPageRangeApply.Enable = 'off';

% enable menu
handles.hMenuSaveAs.Enable = 'on';
handles.hMenuStatistics.Enable = 'on';

% handle font data availability
handles.checkboxFonts.Value = 0;
statistics = getappdata(hFigureMain,'statistics');
if statistics.Fonts == 0
    handles.checkboxFonts.Enable = 'off';
    handles.pushbuttonFontsSelect.Enable = 'off';
end

% handle tags availability
hTagsClasses = getappdata(handles.figureMain,'hTagsClasses');
if isempty(hTagsClasses)
    handles.checkboxTags.Enable = 'off';
    handles.popmenuTags.Enable = 'off';
end

guidata(hObject, handles);


% ------------------------------------
% MENU
% ------------------------------------

function menuGeometry_Callback(~, ~)

function menuExtract_Callback(~, ~)

function menuExtractAlto_Callback(~, ~)
% extracts document geometry from Alto files
altogeo()

function menuExtractIdml_Callback(~, ~)
% extracts document geometry from InDesign IDML files
idmlgeo()

function menuVisualization_Callback(~, ~)

function menuSaveAs_Callback(~, ~)

function menuSaveAsPng_Callback(hObject, ~)

handles = guihandles(hObject);
url = getappdata(handles.figureMain,'url');
preferences = getappdata(handles.figureMain,'preferences');

% obfuscate menu items before saving figure
event.Character = 'h';
figureMain_KeyPressFcn(handles.figureMain, event)
fn = [url.path, url.file(1:end-5), '.png'];
print(handles.figureMain, '-dpng', fn, ['-r', num2str(preferences.pngDpi)])
figureMain_KeyPressFcn(handles.figureMain, event)


function menuSaveAsSvg_Callback(hObject, ~)

handles = guihandles(hObject);
url = getappdata(handles.figureMain,'url');

% obfuscate menu items before saving figure
event.Character = 'h';
figureMain_KeyPressFcn(handles.figureMain, event)
fn = [url.path, url.file(1:end-5), '.svg'];
print(handles.figureMain, '-dsvg', '-painters', fn)
figureMain_KeyPressFcn(handles.figureMain, event)


function menuSaveAsPdf_Callback(hObject, ~)

handles = guihandles(hObject);
url = getappdata(handles.figureMain,'url');

% obfuscate menu items before saving figure
event.Character = 'h';
figureMain_KeyPressFcn(handles.figureMain, event)
fn = [url.path, url.file(1:end-5), '.pdf'];
print(handles.figureMain, '-dpdf', '-painters', '-bestfit', fn)
figureMain_KeyPressFcn(handles.figureMain, event)


function menuSaveAsEps_Callback(hObject, ~)

handles = guihandles(hObject);
url = getappdata(handles.figureMain,'url');

% obfuscate menu items before saving figure
event.Character = 'h';
figureMain_KeyPressFcn(handles.figureMain, event)
fn = [url.path, url.file(1:end-5), '.eps'];
print(handles.figureMain, '-depsc', '-painters', fn)
figureMain_KeyPressFcn(handles.figureMain, event)


function menuSaveAsFig_Callback(hObject, ~)

handles = guihandles(hObject);
url = getappdata(handles.figureMain,'url');

saveas(handles.axesViz, [url.path, url.file(1:end-5), '.fig'],'fig')


function menuVizPreferences_Callback(hObject, ~)

% get preferences
handles = guihandles(hObject);
hFigureMain = handles.figureMain;
ui = getappdata(hFigureMain,'ui');
preferences = getappdata(hFigureMain,'preferences');

% get main figure location in characters
ui.FigMainX = hFigureMain.Position(1);
ui.FigMainY = hFigureMain.Position(2) + floor(hFigureMain.Position(4)/2);
ui.FigMainW = hFigureMain.Position(3);
ui.FigMainH = hFigureMain.Position(4);

% controls - save
ui.PushbuttonUpdateSavePreferencesY = ui.PadXY;
ui.PushbuttonUpdateSavePreferencesX = ui.PadXY;
ui.TextPngDpiY = ui.PushbuttonUpdateSavePreferencesY + ui.ButtonH + ui.PadXY;
ui.EditPngDpiY = ui.TextPngDpiY;
ui.EditPngDpiX = ui.PadXY*2 + ui.ButtonW;

% controls - objects
ui.PushbuttonUpdateObjecsPreferencesY = ui.PadXY;
ui.PushbuttonUpdateObjecsPreferencesX = ui.PadXY;
ui.TextDocumentSpacingY = ui.PushbuttonUpdateObjecsPreferencesY + ui.ButtonH + ui.PadXY;
ui.EditDocumentSpacingY = ui.TextDocumentSpacingY;
ui.EditDocumentSpacingX = ui.PadXY*2 + ui.ButtonW;
ui.TextFloorHeightY = ui.TextDocumentSpacingY + ui.ButtonH + ui.PadXY;
ui.EditFloorHeightY = ui.TextFloorHeightY;
ui.EditFloorHeightX = ui.PadXY*2 + ui.ButtonW;
ui.TextTextFaceAlphaY = ui.TextFloorHeightY + ui.ButtonH + ui.PadXY;
ui.EditTextFaceAlphaY = ui.TextTextFaceAlphaY;
ui.EditTextFaceAlphaX = ui.PadXY*2 + ui.ButtonW;

% panel - save
ui.PanelSaveX = ui.PadXY;
ui.PanelSaveY = ui.PadXY;
ui.PanelSaveH = ui.TextPngDpiY + ui.ButtonH + ui.PadXY*2;
ui.PanelSaveW = ui.ButtonW*2 + ui.PadXY*3;

% panel - objects
ui.PanelObjectsX = ui.PadXY;
ui.PanelObjectsY = ui.PanelSaveY + ui.PanelSaveH + ui.PadXY;
ui.PanelObjectsH = ui.TextTextFaceAlphaY + ui.ButtonH + ui.PadXY*2;
ui.PanelObjectsW = ui.ButtonW*2 + ui.PadXY*3;

% figure - preferences figure location
ui.FigW = ui.PanelObjectsW + ui.PadXY*2;
ui.FigH = ui.PanelSaveH + ui.PanelObjectsH + ui.PadXY*3;
ui.FigX = ui.FigMainX + floor(ui.FigMainW/2) - floor(ui.FigW/2);
ui.FigY = ui.FigMainY + floor(ui.FigMainH/2) - floor(ui.FigH/2);

% make figure
hFigurePreferences = figure(...
    'Name','Preferences',...
    'NumberTitle','off',...
    'MenuBar','none',...
    'Toolbar','none',...
	'Units','pixels',...
    'Position',[ui.FigX, ui.FigY, ui.FigW, ui.FigH],...
    'KeyPressFcn',@figurePreferences_KeyPressFcn,...
    'Visible','on');

% objects
hPanelObjects = uipanel(...
    'Tag','panelObjects',...
    'Title','Objects',...
    'Parent',hFigurePreferences,...
    'FontSize',10,...
    'FontWeight','bold',...
    'Clipping','on',...
    'Units','pixels',...
    'Position',[ui.PanelObjectsX, ui.PanelObjectsY, ui.PanelObjectsW, ui.PanelObjectsH]);

hTextFloorHeight = uicontrol(...
    'Tag','textFloorHeight',...
    'String','Floor Height',...
    'Parent',hPanelObjects,...
    'Enable','on',...
    'FontSize',10,...
    'HorizontalAlignment','left',...
    'Units','pixels',...
    'Position',[ui.PadXY ui.TextFloorHeightY ui.ButtonW ui.ButtonH],...
    'Style','text');

hEditFloorHeight = uicontrol(...
    'Tag','editFloorHeight',...
    'String',-preferences.floorHeight,...
    'Parent',hPanelObjects,...
    'Callback',@editFloorHeight_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.EditFloorHeightX ui.EditFloorHeightY ui.ButtonW ui.ButtonH],...
    'Style','edit');

hTextTextFaceAlpha = uicontrol(...
    'Tag','textTextFaceAlpha',...
    'String','Text Transparency',...
    'Parent',hPanelObjects,...
    'Enable','on',...
    'FontSize',10,...
    'HorizontalAlignment','left',...
    'Units','pixels',...
    'Position',[ui.PadXY ui.TextTextFaceAlphaY ui.ButtonW ui.ButtonH],...
    'Style','text');

hEditTextFaceAlpha = uicontrol(...
    'Tag','editTextFaceAlpha',...
    'String',preferences.textFaceAlpha,...
    'Parent',hPanelObjects,...
    'Callback',@editTextFaceAlpha_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.EditTextFaceAlphaX ui.EditTextFaceAlphaY ui.ButtonW ui.ButtonH],...
    'Style','edit');

hTextDocumentSpacing = uicontrol(...
    'Tag','textDocumentSpacing',...
    'String','Document Spacing',...
    'Parent',hPanelObjects,...
    'Enable','on',...
    'FontSize',10,...
    'HorizontalAlignment','left',...
    'Units','pixels',...
    'Position',[ui.PadXY ui.TextDocumentSpacingY ui.ButtonW ui.ButtonH],...
    'Style','text');

hEditDocumentSpacing = uicontrol(...
    'Tag','editDocumentSpacing',...
    'String',preferences.docPadXY,...
    'Parent',hPanelObjects,...
    'Callback',@editDocumentSpacing_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.EditDocumentSpacingX ui.EditDocumentSpacingY ui.ButtonW ui.ButtonH],...
    'Style','edit');

hPushbuttonUpdateObjecsPreferences = uicontrol(...
    'Tag','pushbuttonUpdateObjecsPreferences',...
    'String','Reimport Geometry to Apply Changes',...
    'Parent',hPanelObjects,...
    'Callback',@pushbuttonUpdateObjecsVizPreferences_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PushbuttonUpdateObjecsPreferencesX, ui.PushbuttonUpdateObjecsPreferencesY, ...
        ui.ButtonW*2 + ui.PadXY, ui.ButtonH],...
    'Style','pushbutton',...
    'Value',0);

% save
hPanelSave = uipanel(...
    'Tag','panelSave',...
    'Title','Save',...
    'Parent',hFigurePreferences,...
    'FontSize',10,...
    'FontWeight','bold',...
    'Clipping','on',...
    'Units','pixels',...
    'Position',[ui.PanelSaveX, ui.PanelSaveY, ui.PanelSaveW, ui.PanelSaveH]);

hTextPngDpi = uicontrol(...
    'Tag','textPngDpi',...
    'String','PNG dpi',...
    'Parent',hPanelSave,...
    'Enable','on',...
    'FontSize',10,...
    'HorizontalAlignment','left',...
    'Units','pixels',...
    'Position',[ui.PadXY ui.TextPngDpiY ui.ButtonW ui.ButtonH],...
    'Style','text');

hEditPngDpi = uicontrol(...
    'Tag','editPngDpi',...
    'String',preferences.pngDpi,...
    'Parent',hPanelSave,...
    'Callback',@editPngDpi_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.EditPngDpiX ui.EditPngDpiY ui.ButtonW ui.ButtonH],...
    'Style','edit');

hPushbuttonUpdateSavePreferences = uicontrol(...
    'Tag','pushbuttonUpdateSavePreferences',...
    'String','Save',...
    'Parent',hPanelSave,...
    'Callback',@pushbuttonUpdateSaveVizPreferences_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PushbuttonUpdateSavePreferencesX, ui.PushbuttonUpdateSavePreferencesY, ...
        ui.ButtonW*2 + ui.PadXY, ui.ButtonH],...
    'Style','pushbutton',...
    'Value',0);


% --- OBJECTS
function pushbuttonUpdateObjecsVizPreferences_Callback(hObject, ~)

% read new preferences
handles = guihandles(hObject);
preferencesNew.floorHeight = - str2num(handles.editFloorHeight.String);
preferencesNew.textFaceAlpha = str2num(handles.editTextFaceAlpha.String);
preferencesNew.docPadXY = str2num(handles.editDocumentSpacing.String);

% close preferences window
close(gcf)

% update preferences
handles = guihandles(gcf);
hFigureMain = handles.figureMain;
preferences = getappdata(hFigureMain,'preferences');
preferences.floorHeight = preferencesNew.floorHeight;
preferences.textFaceAlpha = preferencesNew.textFaceAlpha;
preferences.docPadXY = preferencesNew.docPadXY;
setappdata(hFigureMain,'preferences',preferences)

% reimport geometry
menuVisualize_Callback(hFigureMain)

function figurePreferences_KeyPressFcn(hObject, event)
figure_CloseByKey(hObject, event)

function editFloorHeight_Callback(hObject, ~)

function editTextFaceAlpha_Callback(hObject, ~)

function editDocumentSpacing_Callback(hObject, ~)


% --- SAVE
function editPngDpi_Callback(hObject, ~)

function pushbuttonUpdateSaveVizPreferences_Callback(hObject, ~)

% read new preferences
handles = guihandles(hObject);
preferencesNew.pngDpi = str2num(handles.editPngDpi.String);

% close preferences window
close(gcf)

% update preferences
handles = guihandles(gcf);
hFigureMain = handles.figureMain;
preferences = getappdata(hFigureMain,'preferences');
preferences.pngDpi = preferencesNew.pngDpi;
setappdata(hFigureMain,'preferences',preferences)


% --- MENU METRICS
function menuMetrics_Callback(~, ~)

function menuStatistics_Callback(hObject, ~)

% prepare data
handles = guihandles(hObject);
statistics = getappdata(handles.figureMain,'statistics');
pad = '     ';
data = {...
    ' ';...
    ' ';...
    [pad,'====================',pad];...
    [pad,'OBJECTS'];...
    [pad,'--------------------'];...
    [pad,'Documents ...... ',num2str(statistics.Documents)];...
    [pad,'Pages .......... ',num2str(statistics.Pages)];...
    [pad,'Texts .......... ',num2str(statistics.Text)];...
    [pad,'Images ......... ',num2str(statistics.Images)];...
    [pad,'Graphics ....... ',num2str(statistics.Graphics)];...
    [pad,'Fonts .......... ',num2str(statistics.Fonts)];...
    [pad,'Fonts Selected . ',num2str(statistics.FontsSelected)];...
    [pad,'--------------------'];...
    ' ';...
    ' '};

% get statistics figure size and location
paraW = 0;
paraH = size(data,1);
for k = 1:paraH
    if length(data{k}) > paraW
        paraW = length(data{k});
    end
end

% main figure size and location
hFigureMain = gcf;
t = hFigureMain.Units;
hFigureMain.Units = 'characters';
figMainX = hFigureMain.Position(1);
figMainY = hFigureMain.Position(2) + floor(hFigureMain.Position(4)/2);
figMainW = hFigureMain.Position(3);
figMainH = hFigureMain.Position(4);
hFigureMain.Units = t;

% Preferences figure location
figW = paraW + 1;
figH = paraH;
figX = figMainX + floor(figMainW/2) - floor(figW/2);
figY = figMainY + floor(figMainH/2) - floor(figH/2);

% make figure
uiFigureStatistics = figure(...
    'Name','Statistics',...
    'NumberTitle','off',...
    'MenuBar','none',...
    'Toolbar','none',...
	'Units','characters',...
    'Position',[figX, figY, figW, figH],...
    'KeyPressFcn',@figureStatistics_KeyPressFcn,...
    'Visible','on');

hTextAbout = uicontrol(...
    'Tag','textAbout',...
    'String',data,...
    'FontName','FixedWidth',...
    'FontWeight','normal',...
    'FontSize',10,...
    'HorizontalAlignment','left',...
    'Units','normalized',...
    'Position',[0 0 1 1],...
    'Style','text');


function figureStatistics_KeyPressFcn(hObject, event)
figure_CloseByKey(hObject, event)


function menuMetricsPreferences_Callback(hObject, ~)

% get preferences
handles = guihandles(hObject);
hFigureMain = handles.figureMain;
ui = getappdata(hFigureMain,'ui');
preferences = getappdata(hFigureMain,'preferences');

% get main figure location in characters
ui.FigMainX = hFigureMain.Position(1);
ui.FigMainY = hFigureMain.Position(2) + floor(hFigureMain.Position(4)/2);
ui.FigMainW = hFigureMain.Position(3);
ui.FigMainH = hFigureMain.Position(4);

% controls - colormap palette
ui.PushbuttonUpdateColormapPalettePreferencesY = ui.PadXY;
ui.PushbuttonUpdateColormapPalettePreferencesX = ui.PadXY;
ui.RadiobuttonColormapPalette4Y = ...
    ui.PushbuttonUpdateColormapPalettePreferencesY + ui.ButtonH + ui.PadXY;
ui.RadiobuttonColormapPalette3Y = ...
    ui.RadiobuttonColormapPalette4Y + ui.ButtonH + ui.PadXY/2;
ui.RadiobuttonColormapPalette2Y = ...
    ui.RadiobuttonColormapPalette3Y + ui.ButtonH + ui.PadXY/2;
ui.RadiobuttonColormapPalette1Y = ...
    ui.RadiobuttonColormapPalette2Y + ui.ButtonH + ui.PadXY/2;

% controls - colormap range
ui.PushbuttonUpdateColormapRangePreferencesY = ui.PadXY;
ui.PushbuttonUpdateColormapRangePreferencesX = ui.PadXY;
ui.RadiobuttonColormapRangeZeroOneY = ...
    ui.PushbuttonUpdateColormapRangePreferencesY + ...
    (ui.ButtonH + ui.PadXY/2)*2 + ui.ButtonH + ui.PadXY;
ui.RadiobuttonColormapRangeMinMaxY = ...
    ui.RadiobuttonColormapRangeZeroOneY + ui.ButtonH + ui.PadXY/2;

% % controls - metrics information potential
% ui.PushbuttonUpdateMetricsInfoPotentialPreferencesY = ui.PadXY;
% ui.PushbuttonUpdateMetricsInfoPotentialPreferencesX = ui.PadXY;
% ui.RadiobuttonMetricsInfoPotentialRGBY = ...
%     ui.PushbuttonUpdateMetricsInfoPotentialPreferencesY + ui.ButtonH + ui.PadXY;
% ui.RadiobuttonMetricsInfoPotentialAllY = ...
%     ui.RadiobuttonMetricsInfoPotentialRGBY + ui.ButtonH + ui.PadXY/2;
% ui.RadiobuttonMetricsInfoPotentialSalliencyY = ...
%     ui.RadiobuttonMetricsInfoPotentialAllY + ui.ButtonH + ui.PadXY/2;

% controls - metrics boundary
ui.PushbuttonUpdateMetricsBoundaryPreferencesY = ui.PadXY;
ui.PushbuttonUpdateMetricsBoundaryPreferencesX = ui.PadXY;
ui.RadiobuttonMetricsBoundaryPasteboardY = ...
    ui.PushbuttonUpdateMetricsBoundaryPreferencesY + ...
    ui.ButtonH + ui.PadXY;
ui.RadiobuttonMetricsBoundarySpreadY = ...
    ui.RadiobuttonMetricsBoundaryPasteboardY + ui.ButtonH + ui.PadXY/2;
ui.RadiobuttonMetricsBoundaryPageY = ...
    ui.RadiobuttonMetricsBoundarySpreadY + ui.ButtonH + ui.PadXY/2;

% controls - metrics cardinality
ui.PushbuttonUpdateMetricsCardinalityPreferencesY = ui.PadXY;
ui.PushbuttonUpdateMetricsCardinalityPreferencesX = ui.PadXY;
ui.RadiobuttonMetricsCardinalityLogY = ...
    ui.PushbuttonUpdateMetricsCardinalityPreferencesY + ...
    ui.ButtonH*2 + ui.PadXY;
ui.RadiobuttonMetricsCardinalityLinearY = ...
    ui.RadiobuttonMetricsCardinalityLogY + ui.ButtonH + ui.PadXY/2;

% controls - metrics value
ui.PushbuttonUpdateMetricsValuePreferencesY = ui.PadXY;
ui.PushbuttonUpdateMetricsValuePreferencesX = ui.PadXY;
ui.RadiobuttonMetricsValueRelativeY = ...
    ui.PushbuttonUpdateMetricsValuePreferencesY + ui.ButtonH + ui.PadXY;
ui.RadiobuttonMetricsValueAbsoluteY = ...
    ui.RadiobuttonMetricsValueRelativeY + ui.ButtonH + ui.PadXY/2;

% panel - colormap palette
ui.PanelColormapPaletteX = ui.PadXY;
ui.PanelColormapPaletteY = ui.PadXY;
ui.PanelColormapPaletteH = ui.RadiobuttonColormapPalette1Y + ui.ButtonH + ui.PadXY*2;
ui.PanelColormapPaletteW = ui.ButtonW + ui.PadXY;

% panel - colormap range
ui.PanelColormapRangeX = ui.PanelColormapPaletteW + ui.PadXY*2;
ui.PanelColormapRangeY = ui.PadXY;
ui.PanelColormapRangeH = ui.RadiobuttonColormapRangeMinMaxY + ui.ButtonH + ui.PadXY*2;
ui.PanelColormapRangeW = ui.ButtonW + ui.PadXY;

% % panel - metrics information potential
% ui.PanelMetricsInfoPotentialX = ui.PadXY;
% ui.PanelMetricsInfoPotentialY = ui.PanelColormapPaletteH + ui.PadXY*2;
% ui.PanelMetricsInfoPotentialH = ui.RadiobuttonMetricsInfoPotentialSalliencyY + ...
%     ui.ButtonH + ui.PadXY*2;
% ui.PanelMetricsInfoPotentialW = ui.PanelColormapRangeW*2 + ui.PadXY;

% panel - metrics boundary
ui.PanelMetricsBoundaryX = ui.PadXY;
% ui.PanelMetricsBoundaryY = ui.PanelMetricsInfoPotentialY + ...
%     ui.PanelMetricsInfoPotentialH + ui.PadXY;
ui.PanelMetricsBoundaryY = ui.PanelColormapPaletteH + ui.PadXY*2;
ui.PanelMetricsBoundaryH = ui.RadiobuttonMetricsBoundaryPageY + ui.ButtonH + ui.PadXY*2;
ui.PanelMetricsBoundaryW = ui.ButtonW + ui.PadXY;

% panel - metrics cardinality
ui.PanelMetricsCardinalityX = ui.PanelMetricsBoundaryW + ui.PadXY*2;
% ui.PanelMetricsCardinalityY = ui.PanelMetricsInfoPotentialY + ...
%     ui.PanelMetricsInfoPotentialH + ui.PadXY;
ui.PanelMetricsCardinalityY = ui.PanelColormapRangeY + ...
    ui.PanelColormapRangeH + ui.PadXY;
ui.PanelMetricsCardinalityH = ui.PanelMetricsBoundaryH;
ui.PanelMetricsCardinalityW = ui.ButtonW + ui.PadXY;

% panel - metrics value
ui.PanelMetricsValueX = ui.PadXY;
ui.PanelMetricsValueY = ui.PanelMetricsBoundaryY + ...
    ui.PanelMetricsBoundaryH + ui.PadXY;
ui.PanelMetricsValueH = ui.RadiobuttonMetricsValueAbsoluteY + ui.ButtonH + ui.PadXY*2;
ui.PanelMetricsValueW = ui.PanelMetricsBoundaryW*2 + ui.PadXY;

% figure - preferences figure location
% ui.FigW = ui.PanelMetricsInfoPotentialW + ui.PadXY*2;
ui.FigW = ui.PanelMetricsValueW + ui.PadXY*3;
% ui.FigH = ui.PanelMetricsValueH + ui.PanelMetricsBoundaryH + ...
%     ui.PanelMetricsInfoPotentialH + ui.PanelColormapPaletteH + ui.PadXY*5;
ui.FigH = ui.PanelMetricsValueH + ui.PanelMetricsBoundaryH + ...
    + ui.PanelColormapPaletteH + ui.PadXY*4;
ui.FigX = ui.FigMainX + floor(ui.FigMainW/2) - floor(ui.FigW/2);
ui.FigY = ui.FigMainY + floor(ui.FigMainH/2) - floor(ui.FigH/2);

% read colormap palette selection stored in main figure
metricsColormapPalette1Value = 0;
metricsColormapPalette2Value = 0;
metricsColormapPalette3Value = 0;
metricsColormapPalette4Value = 0;
if preferences.cmap.selection == 1
    metricsColormapPalette1Value = 1;
elseif preferences.cmap.selection == 2
    metricsColormapPalette2Value = 1;
elseif preferences.cmap.selection == 3
    metricsColormapPalette3Value = 1;
elseif preferences.cmap.selection == 4
    metricsColormapPalette4Value = 1;
end

% read colormap range settings stored in main figure
metricsColormapRangeZeroOneValue = 0;
metricsColormapRangeMinMaxValue = 0;
if strcmp(preferences.metricsColormapRangeType,'ZeroOne')
        metricsColormapRangeZeroOneValue = 1;
end
if strcmp(preferences.metricsColormapRangeType,'MinMax')
        metricsColormapRangeMinMaxValue = 1;
end

% read metrics infopotential settings stored in main figure
metricsInfoPotentialTypeSalliencyValue = 0;
metricsInfoPotentialTypeAllValue = 0;
metricsInfoPotentialTypeRGBValue = 0;
if strcmp(preferences.metricsInfoPotentialType,'Salliency')
        metricsInfoPotentialTypeSalliencyValue = 1;
end
if strcmp(preferences.metricsInfoPotentialType,'All')
        metricsInfoPotentialTypeAllValue = 1;
end
if strcmp(preferences.metricsInfoPotentialType,'RGB')
        metricsInfoPotentialTypeRGBValue = 1;
end

% read metrics area settings stored in main figure
metricsBoundaryTypePageValue = 0;
metricsBoundaryTypeSpreadValue = 0;
metricsBoundaryTypePasteboardValue = 0;
if strcmp(preferences.metricsBoundaryType,'Pages')
        metricsBoundaryTypePageValue = 1;
end
if strcmp(preferences.metricsBoundaryType,'Spreads')
        metricsBoundaryTypeSpreadValue = 1;
end
if strcmp(preferences.metricsBoundaryType,'Pasteboards')
        metricsBoundaryTypePasteboardValue = 1;
end

% read metrics cardinality settings stored in main figure
metricsCardinalityLinearValue = 0;
metricsCardinalityLogValue = 0;
if strcmp(preferences.metricsCardinalityType,'Linear')
        metricsCardinalityLinearValue = 1;
end
if strcmp(preferences.metricsCardinalityType,'Log')
        metricsCardinalityLogValue = 1;
end

% read metrics value settings stored in main figure
metricsValueTypeAbsoluteValue = 0;
metricsValueTypeRelativeValue = 0;
if strcmp(preferences.metricsValueType,'Absolute')
        metricsValueTypeAbsoluteValue = 1;
end
if strcmp(preferences.metricsValueType,'Relative')
        metricsValueTypeRelativeValue = 1;
end


% make figure
hFigurePreferences = figure(...
    'Name','Preferences',...
    'NumberTitle','off',...
    'MenuBar','none',...
    'Toolbar','none',...
	'Units','pixels',...
    'Position',[ui.FigX, ui.FigY, ui.FigW, ui.FigH],...
    'KeyPressFcn',@figurePreferences_KeyPressFcn,...
    'Visible','on');

% metrics value
hPanelMetricsValue = uipanel(...
    'Tag','panelMetricsValue',...
    'Title','Metrics Value',...
    'Parent',hFigurePreferences,...
    'FontSize',10,...
    'FontWeight','bold',...
    'Clipping','on',...
    'Units','pixels',...
    'Position',[ui.PanelMetricsValueX, ui.PanelMetricsValueY, ...
        ui.PanelMetricsValueW, ui.PanelMetricsValueH]);

hRadiobuttonMetricsValueAbsolute = uicontrol(...
    'Tag','radiobuttonMetricsValueAbsolute',...
    'String','Absolute (Boundary Metric)',...
    'Parent',hPanelMetricsValue,...
    'Callback',@radiobuttonMetricsValueAbsolute_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.RadiobuttonMetricsValueAbsoluteY, ...
        ui.ButtonW*2 + ui.PadXY, ui.ButtonH],...
    'Style','radiobutton',...
    'Value',metricsValueTypeAbsoluteValue);

hRadiobuttonMetricsValueRelative = uicontrol(...
    'Tag','radiobuttonMetricsValueRelative',...
    'String','Relative (Difference of Consecutive Boundary Metrics)',...
    'Parent',hPanelMetricsValue,...
    'Callback',@radiobuttonMetricsValueRelative_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.RadiobuttonMetricsValueRelativeY, ...
        ui.ButtonW*2 + ui.PadXY, ui.ButtonH],...
    'Style','radiobutton',...
    'Value',metricsValueTypeRelativeValue);

hPushbuttonUpdateMetricsValuePreferences = uicontrol(...
    'Tag','pushbuttonUpdateMetricsValuePreferences',...
    'String','Update Paint',...
    'Parent',hPanelMetricsValue,...
    'Callback',@pushbuttonUpdateMetricsValuePreferences_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PushbuttonUpdateMetricsValuePreferencesX, ...
        ui.PushbuttonUpdateMetricsValuePreferencesY, ...
        ui.ButtonW*2 + ui.PadXY, ui.ButtonH],...
    'Style','pushbutton',...
    'Value',0);

% metrics boundary
hPanelMetricsBoundary = uipanel(...
    'Tag','panelMetricsBoundary',...
    'Title','Metrics Boundary',...
    'Parent',hFigurePreferences,...
    'FontSize',10,...
    'FontWeight','bold',...
    'Clipping','on',...
    'Units','pixels',...
    'Position',[ui.PanelMetricsBoundaryX, ui.PanelMetricsBoundaryY, ...
        ui.PanelMetricsBoundaryW, ui.PanelMetricsBoundaryH]);

hRadiobuttonMetricsBoundaryPage = uicontrol(...
    'Tag','radiobuttonMetricsBoundaryPage',...
    'String','Pages',...
    'Parent',hPanelMetricsBoundary,...
    'Callback',@radiobuttonMetricsBoundaryPage_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.RadiobuttonMetricsBoundaryPageY, ui.ButtonW, ui.ButtonH],...
    'Style','radiobutton',...
    'Value',metricsBoundaryTypePageValue);

hRadiobuttonMetricsBoundarySpread = uicontrol(...
    'Tag','radiobuttonMetricsBoundarySpread',...
    'String','Spreads',...
    'Parent',hPanelMetricsBoundary,...
    'Callback',@radiobuttonMetricsBoundarySpread_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.RadiobuttonMetricsBoundarySpreadY, ui.ButtonW, ui.ButtonH],...
    'Style','radiobutton',...
    'Value',metricsBoundaryTypeSpreadValue);

hRadiobuttonMetricsBoundaryPasteboard = uicontrol(...
    'Tag','radiobuttonMetricsBoundaryPasteboard',...
    'String','Pasteboards',...
    'Parent',hPanelMetricsBoundary,...
    'Callback',@radiobuttonMetricsBoundaryPasteboard_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.RadiobuttonMetricsBoundaryPasteboardY, ui.ButtonW, ui.ButtonH],...
    'Style','radiobutton',...
    'Value',metricsBoundaryTypePasteboardValue);

hPushbuttonUpdateMetricsBoundaryPreferences = uicontrol(...
    'Tag','pushbuttonUpdateMetricsBoundaryPreferences',...
    'String','Update Paint',...
    'Parent',hPanelMetricsBoundary,...
    'Callback',@pushbuttonUpdateMetricsBoundaryPreferences_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PushbuttonUpdateMetricsBoundaryPreferencesX, ...
        ui.PushbuttonUpdateMetricsBoundaryPreferencesY, ui.ButtonW - ui.PadXY, ui.ButtonH],...
    'Style','pushbutton',...
    'Value',0);

% metrics cardinality
hPanelMetricsCardinality = uipanel(...
    'Tag','panelMetricsCardinality',...
    'Title','Metrics Cardinality',...
    'Parent',hFigurePreferences,...
    'FontSize',10,...
    'FontWeight','bold',...
    'Clipping','on',...
    'Units','pixels',...
    'Position',[ui.PanelMetricsCardinalityX, ui.PanelMetricsCardinalityY, ...
        ui.PanelMetricsCardinalityW, ui.PanelMetricsCardinalityH]);

hRadiobuttonMetricsCardinalityLinear = uicontrol(...
    'Tag','radiobuttonMetricsCardinalityLinear',...
    'String','Linear',...
    'Parent',hPanelMetricsCardinality,...
    'Callback',@radiobuttonMetricsCardinalityLinear_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.RadiobuttonMetricsCardinalityLinearY, ...
        ui.ButtonW, ui.ButtonH],...
    'Style','radiobutton',...
    'Value',metricsCardinalityLinearValue);

hRadiobuttonMetricsCardinalityLog = uicontrol(...
    'Tag','radiobuttonMetricsCardinalityLog',...
    'String','Log',...
    'Parent',hPanelMetricsCardinality,...
    'Callback',@radiobuttonMetricsCardinalityLog_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.RadiobuttonMetricsCardinalityLogY, ...
        ui.ButtonW, ui.ButtonH],...
    'Style','radiobutton',...
    'Value',metricsCardinalityLogValue);

hPushbuttonUpdateMetricsCardinalityPreferences = uicontrol(...
    'Tag','pushbuttonUpdateMetricsCardinalityPreferences',...
    'String','Update Paint',...
    'Parent',hPanelMetricsCardinality,...
    'Callback',@pushbuttonUpdateMetricsCardinalityPreferences_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PushbuttonUpdateMetricsCardinalityPreferencesX, ...
        ui.PushbuttonUpdateMetricsCardinalityPreferencesY, ...
        ui.ButtonW - ui.PadXY, ui.ButtonH],...
    'Style','pushbutton',...
    'Value',0);

% % metrics information potential
% hPanelMetricsInfoPotential = uipanel(...
%     'Tag','panelMetricsInfoPotential',...
%     'Title','Metrics Information Potential',...
%     'Parent',hFigurePreferences,...
%     'FontSize',10,...
%     'FontWeight','bold',...
%     'Clipping','on',...
%     'Units','pixels',...
%     'Position',[ui.PanelMetricsInfoPotentialX, ui.PanelMetricsInfoPotentialY, ...
%         ui.PanelMetricsInfoPotentialW, ui.PanelMetricsInfoPotentialH],...
%     'Visible','off');
% 
% hRadiobuttonMetricsInfoPotentialSalliency = uicontrol(...
%     'Tag','radiobuttonMetricsInfoPotentialSalliency',...
%     'String','Sum( Salliency(i,j) * Area(i,j) )',...
%     'Parent',hPanelMetricsInfoPotential,...
%     'Callback',@radiobuttonMetricsInfoPotentialSalliency_Callback,...
%     'Enable','on',...
%     'FontSize',10,...
%     'Units','pixels',...
%     'Position',[ui.PadXY, ui.RadiobuttonMetricsInfoPotentialSalliencyY, ...
%         ui.ButtonW*2 + ui.PadXY, ui.ButtonH],...
%     'Style','radiobutton',...
%     'Value',metricsInfoPotentialTypeSalliencyValue);
% 
% hRadiobuttonMetricsInfoPotentialAll = uicontrol(...
%     'Tag','radiobuttonMetricsInfoPotentialAll',...
%     'String','Sqrt( Sum( Feature(i)^2 ) )',...
%     'Parent',hPanelMetricsInfoPotential,...
%     'Callback',@radiobuttonMetricsInfoPotentialAll_Callback,...
%     'Enable','on',...
%     'FontSize',10,...
%     'Units','pixels',...
%     'Position',[ui.PadXY, ui.RadiobuttonMetricsInfoPotentialAllY, ...
%         ui.ButtonW*2 + ui.PadXY, ui.ButtonH],...
%     'Style','radiobutton',...
%     'Value',metricsInfoPotentialTypeAllValue);
% 
% hRadiobuttonMetricsInfoPotentialRGB = uicontrol(...
%     'Tag','radiobuttonMetricsInfoPotentialRGB',...
%     'String','Salliency > Red; Fill > Green; Cardinality > Blue',...
%     'Parent',hPanelMetricsInfoPotential,...
%     'Callback',@radiobuttonMetricsInfoPotentialRGB_Callback,...
%     'Enable','on',...
%     'FontSize',10,...
%     'Units','pixels',...
%     'Position',[ui.PadXY, ui.RadiobuttonMetricsInfoPotentialRGBY, ...
%         ui.ButtonW*2 + ui.PadXY, ui.ButtonH],...
%     'Style','radiobutton',...
%     'Value',metricsInfoPotentialTypeRGBValue);
% 
% hPushbuttonUpdateMetricsInfoPotentialPreferences = uicontrol(...
%     'Tag','pushbuttonUpdateMetricsInfoPotentialPreferences',...
%     'String','Update Paint',...
%     'Parent',hPanelMetricsInfoPotential,...
%     'Callback',@pushbuttonUpdateMetricsInfoPotentialPreferences_Callback,...
%     'Enable','on',...
%     'FontSize',10,...
%     'Units','pixels',...
%     'Position',[ui.PushbuttonUpdateMetricsInfoPotentialPreferencesX, ...
%         ui.PushbuttonUpdateMetricsInfoPotentialPreferencesY,  ...
%         ui.ButtonW*2 + ui.PadXY, ui.ButtonH],...
%     'Style','pushbutton',...
%     'Value',0);

% colormap palette
hPanelColormapPalette = uipanel(...
    'Tag','panelColormapPalette',...
    'Title','Colormap Scheme',...
    'Parent',hFigurePreferences,...
    'FontSize',10,...
    'FontWeight','bold',...
    'Clipping','on',...
    'Units','pixels',...
    'Position',[ui.PanelColormapPaletteX, ui.PanelColormapPaletteY, ...
        ui.PanelColormapPaletteW, ui.PanelColormapPaletteH]);

hRadiobuttonColormapPalette1 = uicontrol(...
    'Tag','radiobuttonColormapPalette1',...
    'String','Green – Purple',...
    'Parent',hPanelColormapPalette,...
    'Callback',@radiobuttonColormapPalette1_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.RadiobuttonColormapPalette1Y, ...
        ui.ButtonW, ui.ButtonH],...
    'Style','radiobutton',...
    'Value',metricsColormapPalette1Value);

hRadiobuttonColormapPalette2 = uicontrol(...
    'Tag','radiobuttonColormapPalette2',...
    'String','Blue – Purple',...
    'Parent',hPanelColormapPalette,...
    'Callback',@radiobuttonColormapPalette2_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.RadiobuttonColormapPalette2Y, ...
        ui.ButtonW, ui.ButtonH],...
    'Style','radiobutton',...
    'Value',metricsColormapPalette2Value);

hRadiobuttonColormapPalette3 = uicontrol(...
    'Tag','radiobuttonColormapPalette3',...
    'String','Cyan – Magenta',...
    'Parent',hPanelColormapPalette,...
    'Callback',@radiobuttonColormapPalette3_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.RadiobuttonColormapPalette3Y, ...
        ui.ButtonW, ui.ButtonH],...
    'Style','radiobutton',...
    'Value',metricsColormapPalette3Value);

hRadiobuttonColormapPalette4 = uicontrol(...
    'Tag','radiobuttonColormapPalette4',...
    'String','Green – Red – Blue',...
    'Parent',hPanelColormapPalette,...
    'Callback',@radiobuttonColormapPalette4_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.RadiobuttonColormapPalette4Y, ...
        ui.ButtonW, ui.ButtonH],...
    'Style','radiobutton',...
    'Value',metricsColormapPalette4Value);

hPushbuttonUpdateColormapPalettePreferences = uicontrol(...
    'Tag','pushbuttonUpdateColormapPalettePreferences',...
    'String','Update Paint',...
    'Parent',hPanelColormapPalette,...
    'Callback',@pushbuttonUpdateColormapPalettePreferences_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PushbuttonUpdateColormapPalettePreferencesX, ...
        ui.PushbuttonUpdateColormapPalettePreferencesY, ...
        ui.ButtonW - ui.PadXY, ui.ButtonH],...
    'Style','pushbutton',...
    'Value',0);

% colormap range
hPanelColormapRange = uipanel(...
    'Tag','panelColormapRange',...
    'Title','Colormap Range',...
    'Parent',hFigurePreferences,...
    'FontSize',10,...
    'FontWeight','bold',...
    'Clipping','on',...
    'Units','pixels',...
    'Position',[ui.PanelColormapRangeX, ui.PanelColormapRangeY, ...
        ui.PanelColormapRangeW, ui.PanelColormapRangeH]);

hRadiobuttonColormapRangeZeroOne = uicontrol(...
    'Tag','radiobuttonColormapRangeZeroOne',...
    'String','Zero – One',...
    'Parent',hPanelColormapRange,...
    'Callback',@radiobuttonColormapRangeZeroOne_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.RadiobuttonColormapRangeZeroOneY, ...
        ui.ButtonW, ui.ButtonH],...
    'Style','radiobutton',...
    'Value',metricsColormapRangeZeroOneValue);

hRadiobuttonColormapRangeMinMax = uicontrol(...
    'Tag','radiobuttonColormapRangeMinMax',...
    'String','Min – Max',...
    'Parent',hPanelColormapRange,...
    'Callback',@radiobuttonColormapRangeMinMax_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PadXY, ui.RadiobuttonColormapRangeMinMaxY, ...
        ui.ButtonW, ui.ButtonH],...
    'Style','radiobutton',...
    'Value',metricsColormapRangeMinMaxValue);

hPushbuttonUpdateColormapRangePreferences = uicontrol(...
    'Tag','pushbuttonUpdateColormapRangePreferences',...
    'String','Update Paint',...
    'Parent',hPanelColormapRange,...
    'Callback',@pushbuttonUpdateColormapRangePreferences_Callback,...
    'Enable','on',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[ui.PushbuttonUpdateColormapRangePreferencesX, ...
        ui.PushbuttonUpdateColormapRangePreferencesY, ...
        ui.ButtonW - ui.PadXY, ui.ButtonH],...
    'Style','pushbutton',...
    'Value',0);

% --- METRICS VALUE
function radiobuttonMetricsValueAbsolute_Callback(hObject, ~)
% deactivation of opposite choice controls
handles = guihandles(hObject);
handles.radiobuttonMetricsValueAbsolute.Value = 1;
handles.radiobuttonMetricsValueRelative.Value = 0;

function radiobuttonMetricsValueRelative_Callback(hObject, ~)
% deactivation of opposite choice controls
handles = guihandles(hObject);
handles.radiobuttonMetricsValueAbsolute.Value = 0;
handles.radiobuttonMetricsValueRelative.Value = 1;

function pushbuttonUpdateMetricsValuePreferences_Callback(hObject, ~)

% read new preferences
handles = guihandles(hObject);
if handles.radiobuttonMetricsValueAbsolute.Value == 1
    pref = 'Absolute';
else
    pref = 'Relative';
end

% close preferences figure
close(gcf)

% update preferences in main figure
handles = guihandles(gcf);
hFigureMain = handles.figureMain;
preferences = getappdata(hFigureMain,'preferences');
preferences.metricsValueType = pref;
setappdata(hFigureMain,'preferences',preferences)
guidata(gcf,handles)

% recompute metrics
pushbuttonPaintUpdate_Callback(gcf)


% --- METRICS BOUNDARY
function radiobuttonMetricsBoundaryPage_Callback(hObject, ~)
% deactivation of opposite choice controls
handles = guihandles(hObject);
handles.radiobuttonMetricsBoundaryPage.Value = 1;
handles.radiobuttonMetricsBoundarySpread.Value = 0;
handles.radiobuttonMetricsBoundaryPasteboard.Value = 0;

function radiobuttonMetricsBoundarySpread_Callback(hObject, ~)
% deactivation of opposite choice controls
handles = guihandles(hObject);
handles.radiobuttonMetricsBoundaryPage.Value = 0;
handles.radiobuttonMetricsBoundarySpread.Value = 1;
handles.radiobuttonMetricsBoundaryPasteboard.Value = 0;

function radiobuttonMetricsBoundaryPasteboard_Callback(hObject, ~)
% deactivation of opposite choice controls
handles = guihandles(hObject);
handles.radiobuttonMetricsBoundaryPage.Value = 0;
handles.radiobuttonMetricsBoundarySpread.Value = 0;
handles.radiobuttonMetricsBoundaryPasteboard.Value = 1;

function pushbuttonUpdateMetricsBoundaryPreferences_Callback(hObject, ~)

% read new preferences
handles = guihandles(hObject);
if handles.radiobuttonMetricsBoundaryPage.Value == 1
    pref = 'Pages';
elseif handles.radiobuttonMetricsBoundarySpread.Value == 1
    pref = 'Spreads';
else
    pref = 'Pasteboards';
end

% close preferences figure
close(gcf)

% update preferences in main figure
handles = guihandles(gcf);
hFigureMain = handles.figureMain;
preferences = getappdata(hFigureMain,'preferences');
preferences.metricsBoundaryType = pref;
setappdata(hFigureMain,'preferences',preferences)

handles.panelPaint.Title = ['Paint / Metrics ',pref];
guidata(gcf,handles)

% recompute metrics
pushbuttonPaintUpdate_Callback(gcf)


% --- METRICS CARDINALITY
function radiobuttonMetricsCardinalityLinear_Callback(hObject, ~)
% deactivation of opposite choice controls
handles = guihandles(hObject);
handles.radiobuttonMetricsCardinalityLinear.Value = 1;
handles.radiobuttonMetricsCardinalityLog.Value = 0;

function radiobuttonMetricsCardinalityLog_Callback(hObject, ~)
% deactivation of opposite choice controls
handles = guihandles(hObject);
handles.radiobuttonMetricsCardinalityLinear.Value = 0;
handles.radiobuttonMetricsCardinalityLog.Value = 1;

function pushbuttonUpdateMetricsCardinalityPreferences_Callback(hObject, ~)

% read new preferences
handles = guihandles(hObject);
if handles.radiobuttonMetricsCardinalityLinear.Value == 1
    pref = 'Linear Colormap';
else
    pref = 'Log Colormap';
end

% close preferences figure
close(gcf)

% update preferences in main figure
handles = guihandles(gcf);
hFigureMain = handles.figureMain;
preferences = getappdata(hFigureMain,'preferences');
preferences.metricsCardinalityType = pref;
setappdata(hFigureMain,'preferences',preferences)

% recompute metrics
metrics = getappdata(hFigureMain,'metrics');
if isfield(metrics,'Cardinality')
    metrics = rmfield(metrics,'Cardinality');
end
setappdata(handles.figureMain,'metrics',metrics);

radiobuttonPaintCardinality_Callback(gcf)

% --- METRICS INFORMATION POTENTIAL
function radiobuttonMetricsInfoPotentialSalliency_Callback(hObject, ~)
% deactivation of opposite choice controls
handles = guihandles(hObject);
handles.radiobuttonMetricsInfoPotentialSalliency.Value = 1;
handles.radiobuttonMetricsInfoPotentialAll.Value = 0;
handles.radiobuttonMetricsInfoPotentialRGB.Value = 0;

function radiobuttonMetricsInfoPotentialAll_Callback(hObject, ~)
% deactivation of opposite choice controls
handles = guihandles(hObject);
handles.radiobuttonMetricsInfoPotentialSalliency.Value = 0;
handles.radiobuttonMetricsInfoPotentialAll.Value = 1;
handles.radiobuttonMetricsInfoPotentialRGB.Value = 0;

function radiobuttonMetricsInfoPotentialRGB_Callback(hObject, ~)
% deactivation of opposite choice controls
handles = guihandles(hObject);
handles.radiobuttonMetricsInfoPotentialSalliency.Value = 0;
handles.radiobuttonMetricsInfoPotentialAll.Value = 0;
handles.radiobuttonMetricsInfoPotentialRGB.Value = 1;

function pushbuttonUpdateMetricsInfoPotentialPreferences_Callback(hObject, ~)

% read new preferences
handles = guihandles(hObject);
if handles.radiobuttonMetricsInfoPotentialSalliency.Value == 1
    pref = 'Salliency';
elseif handles.radiobuttonMetricsInfoPotentialAll.Value == 1
    pref = 'All';
else
    pref = 'RGB';
end

% close preferences figure
close(gcf)

% update preferences in main figure
handles = guihandles(gcf);
hFigureMain = handles.figureMain;
preferences = getappdata(hFigureMain,'preferences');
preferences.metricsInfoPotentialType = pref;
setappdata(hFigureMain,'preferences',preferences)
guidata(gcf,handles)

% recompute metrics
pushbuttonPaintUpdate_Callback(gcf)


% --- COLORMAP PALETTE
function radiobuttonColormapPalette1_Callback(hObject, ~)
% deactivation of opposite choice controls
handles = guihandles(hObject);
handles.radiobuttonColormapPalette1.Value = 1;
handles.radiobuttonColormapPalette2.Value = 0;
handles.radiobuttonColormapPalette3.Value = 0;
handles.radiobuttonColormapPalette4.Value = 0;

function radiobuttonColormapPalette2_Callback(hObject, ~)
% deactivation of opposite choice controls
handles = guihandles(hObject);
handles.radiobuttonColormapPalette1.Value = 0;
handles.radiobuttonColormapPalette2.Value = 1;
handles.radiobuttonColormapPalette3.Value = 0;
handles.radiobuttonColormapPalette4.Value = 0;

function radiobuttonColormapPalette3_Callback(hObject, ~)
% deactivation of opposite choice controls
handles = guihandles(hObject);
handles.radiobuttonColormapPalette1.Value = 0;
handles.radiobuttonColormapPalette2.Value = 0;
handles.radiobuttonColormapPalette3.Value = 1;
handles.radiobuttonColormapPalette4.Value = 0;

function radiobuttonColormapPalette4_Callback(hObject, ~)
% deactivation of opposite choice controls
handles = guihandles(hObject);
handles.radiobuttonColormapPalette1.Value = 0;
handles.radiobuttonColormapPalette2.Value = 0;
handles.radiobuttonColormapPalette3.Value = 0;
handles.radiobuttonColormapPalette4.Value = 1;

function pushbuttonUpdateColormapPalettePreferences_Callback(hObject, ~)

% read new preferences
handles = guihandles(hObject);
if handles.radiobuttonColormapPalette1.Value == 1
    prefCmap = 1;
elseif handles.radiobuttonColormapPalette2.Value == 1
    prefCmap = 2;
elseif handles.radiobuttonColormapPalette3.Value == 1
    prefCmap = 3;
else
    prefCmap = 4;
end

% close preferences figure
close(gcf)

% update preferences in main figure
handles = guihandles(gcf);
hFigureMain = handles.figureMain;
preferences = getappdata(hFigureMain,'preferences');
preferences.cmap.selection = prefCmap;
setappdata(hFigureMain,'preferences',preferences)

% repaint metrics
metrics = getappdata(hFigureMain,'metrics');
hObjectClasses = getappdata(hFigureMain,'hObjectClasses');
nDocuments = length(hObjectClasses);
kcmap = preferences.cmap.selection;

for kDocuments = 1:nDocuments
    if isfield(metrics,'Cardinality') ~= 0 && ~isempty(metrics.Cardinality)
        if strcmp(preferences.metricsValueType, 'Absolute')
            idx = metrics.Cardinality(kDocuments).color.idx.abs;
        else
            idx = metrics.Cardinality(kDocuments).color.idx.rel;
        end
        hObjectClasses(kDocuments).Pages(1).Children.FaceAlpha = 1;
        hObjectClasses(kDocuments).Pages(1).Children.FaceVertexCData = ...
            preferences.cmap.map(idx,:,kcmap);
    end
    if isfield(metrics,'Fill') ~= 0 && ~isempty(metrics.Fill)
        if strcmp(preferences.metricsValueType, 'Absolute')
            idx = metrics.Fill(kDocuments).color.idx.abs;
        else
            idx = metrics.Fill(kDocuments).color.idx.rel;
        end
        hObjectClasses(kDocuments).Pages(1).Children.FaceAlpha = 1;
        hObjectClasses(kDocuments).Pages(1).Children.FaceVertexCData = ...
            preferences.cmap.map(idx,:,kcmap);
    end
    if isfield(metrics,'SalliencyRatio') ~= 0 && ~isempty(metrics.SalliencyRatio)
        if strcmp(preferences.metricsValueType, 'Absolute')
            idx = metrics.SalliencyRatio(kDocuments).color.idx.abs;
        else
            idx = metrics.SalliencyRatio(kDocuments).color.idx.rel;
        end
        hObjectClasses(kDocuments).Pages(1).Children.FaceAlpha = 1;
        hObjectClasses(kDocuments).Pages(1).Children.FaceVertexCData = ...
            preferences.cmap.map(idx,:,kcmap);
    end
    if isfield(metrics,'Configuration') ~= 0 && ~isempty(metrics.Configuration)
        if strcmp(preferences.metricsValueType, 'Absolute')
            idx = metrics.Configuration(kDocuments).color.idx.abs;
        else
            idx = metrics.Configuration(kDocuments).color.idx.rel;
        end
        hObjectClasses(kDocuments).Pages(1).Children.FaceAlpha = 1;
        hObjectClasses(kDocuments).Pages(1).Children.FaceVertexCData = ...
            preferences.cmap.map(idx,:,kcmap);
    end
    if isfield(metrics,'InfoPotential') ~= 0 && ~isempty(metrics.InfoPotential)
        if strcmp(preferences.metricsValueType, 'Absolute')
            idx = metrics.InfoPotential(kDocuments).color.idx.abs;
        else
            idx = metrics.InfoPotential(kDocuments).color.idx.rel;
        end
        hObjectClasses(kDocuments).Pages(1).Children.FaceAlpha = 1;
        hObjectClasses(kDocuments).Pages(1).Children.FaceVertexCData = ...
            preferences.cmap.map(idx,:,kcmap);
    end
end


% --- COLORMAP RANGE
function radiobuttonColormapRangeMinMax_Callback(hObject, ~)
% deactivation of opposite choice controls
handles = guihandles(hObject);
handles.radiobuttonColormapRangeMinMax.Value = 1;
handles.radiobuttonColormapRangeZeroOne.Value = 0;

function radiobuttonColormapRangeZeroOne_Callback(hObject, ~)
% deactivation of opposite choice controls
handles = guihandles(hObject);
handles.radiobuttonColormapRangeMinMax.Value = 0;
handles.radiobuttonColormapRangeZeroOne.Value = 1;

function pushbuttonUpdateColormapRangePreferences_Callback(hObject, ~)

% read new preferences
handles = guihandles(hObject);
if handles.radiobuttonColormapRangeMinMax.Value == 1
    pref = 'MinMax';
else
    pref = 'ZeroOne';
end

% close preferences figure
close(gcf)

% update preferences in main figure
handles = guihandles(gcf);
hFigureMain = handles.figureMain;
preferences = getappdata(hFigureMain,'preferences');
preferences.metricsColormapRangeType = pref;
setappdata(hFigureMain,'preferences',preferences)

% recompute metrics
metrics = getappdata(hFigureMain,'metrics');
if isfield(metrics,'ColormapRange')
    metrics = rmfield(metrics,'ColormapRange');
end
setappdata(handles.figureMain,'metrics',metrics);

pushbuttonPaintUpdate_Callback(gcf)

% --- END PREFERENCES FIGURE


% Help menu
function menuHelp_Callback(~, ~)

function menuHelpDocumentation_Callback(~, ~)
web('help.txt','-browser')

function menuHelpAbout_Callback(hObject, ~)

% text
handles = guihandles(hObject);
preferences = getappdata(handles.figureMain,'preferences');
s = {...
    'TOWERS',...
    ['version ',preferences.softVersion],...
    '-',...
    'Vlad Atanasiu',...
    'atanasiu@alum.mit.edu',...
    'http://alum.mit.edu/www/atanasiu/',...
    ' ',...
    '- - - - - - - - -',...
    '  - - - - - - -  ',...
    '    - - - - -    ',...
    '      - - -      ',...
    '        -        '};

% Main figure location
hFigureMain = gcf;
figMainX = hFigureMain.Position(1);
figMainY = hFigureMain.Position(2) + floor(hFigureMain.Position(4)/2);
figMainW = hFigureMain.Position(3);
figMainH = hFigureMain.Position(4);

% About figure positon
figAboutW = 250;
figAboutH = 200;
figAboutX = figMainX + floor(figMainW/2) - floor(figAboutW/2);
figAboutY = figMainY + floor(figMainH/2) - floor(figAboutH/2);

% make figure
uiFigureAbout = figure(...
    'name','About',...
    'NumberTitle','off',...
    'MenuBar','none',...
    'ToolBar','none',...
    'Units','pixels',...
    'Position',[figAboutX, figAboutY, figAboutW, figAboutH],...
    'KeyPressFcn',@figureAbout_KeyPressFcn,...
    'Visible','off');
hTextAbout = uicontrol(...
    'Tag','textAbout',...
    'String',s,...
    'FontName','FixedWidth',...
    'FontWeight','normal',...
    'FontSize',10,...
    'HorizontalAlignment','center',...
    'Units','pixels',...
    'Position',[1 1 250 175],...
    'Style','text');

% show figure
set(uiFigureAbout,'visible','on');

% % slide out window
% figAboutHeight = 0;
% while figAboutHeight < figAboutH
%     figAboutHeight = figAboutHeight + 1;
%     uiFigureAbout.Position(2) = uiFigureAbout.Position(2) - 1;
%     uiFigureAbout.Position(4) = figAboutHeight;
% 	
% 	drawnow
% end


% --- Executes at key press on figureAbout.
function figureAbout_KeyPressFcn(~, event)
figure_CloseByKey(hObject, event)




