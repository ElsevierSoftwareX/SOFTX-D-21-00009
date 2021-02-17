function towers_PaintFill(hObject,jumpToCompute)

% -----------------
% Metric definition
% -----------------
% FILL = area of objects within a page of a spread,
% normalized by the page or spread area.


% parse input
if nargin < 2 || isempty(jumpToCompute)
    jumpToCompute = false;
end

% only metrics computing, no paint update
if jumpToCompute == true
    computeMetricsFill(hObject)
    return
end

handles = guihandles(hObject);
preferences = getappdata(handles.figureMain,'preferences');

% don't compute metrics if no object selected
if sum([handles.checkboxText.Value, ...
        handles.checkboxImages.Value, ...
        handles.checkboxGraphics.Value]) == 0
    
    % reset radio buttons
    handles.radiobuttonPaintNone.Value = 1;
    handles.radiobuttonPaintCardinality.Value = 0;
    handles.radiobuttonPaintFill.Value = 0;
    handles.radiobuttonPaintSalliency.Value = 0;
    handles.radiobuttonPaintConfiguration.Value = 0;
    handles.radiobuttonPaintInfoPotential.Value = 0;

    % display error message
    msgbox('Please select text, image, or graphics object.', 'Error','error');
    
    return
end

% deactivation of opposite choice controls
handles.radiobuttonPaintNone.Value = 0;
handles.radiobuttonPaintCardinality.Value = 0;
handles.radiobuttonPaintFill.Value = 1;
handles.radiobuttonPaintSalliency.Value = 0;
handles.radiobuttonPaintConfiguration.Value = 0;
handles.radiobuttonPaintInfoPotential.Value = 0;

% memorize paint state
preferences.paint = 'Fill';
setappdata(handles.figureMain,'preferences',preferences)

% paint page objects
hFigureMain = handles.figureMain;

% compute metrics if not already done
metrics = getappdata(hFigureMain,'metrics');
if isfield(metrics,'Fill') == 0 || isempty(metrics.Fill)
    computeMetricsFill(hObject);
    metrics = getappdata(hFigureMain,'metrics');
end

% paint page objects
hObjectClasses = getappdata(hFigureMain,'hObjectClasses');
nDocuments = length(hObjectClasses);
for kDocuments = 1:nDocuments
    hObjectClasses(kDocuments).Pages(1).Children.FaceAlpha = 1;
    if strcmp(preferences.metricsValueType,'Absolute')
        hObjectClasses(kDocuments).Pages(1).Children.FaceVertexCData = ...
            metrics.Fill(kDocuments).color.cmap.abs;
    else
        hObjectClasses(kDocuments).Pages(1).Children.FaceVertexCData = ...
            metrics.Fill(kDocuments).color.cmap.rel;
    end
end

function computeMetricsFill(hObject)
% Fill metric
% - measure: percentage of spread area covered by document objects
% - meaning: fraction of available information from maximum obtainable

handles = guihandles(hObject);
geometry = getappdata(handles.figureMain,'geometry');
preferences = getappdata(handles.figureMain,'preferences');
objType = {'Text','Images','Graphics'};
nObjType = length(objType);

% size data
nDocuments = length(geometry);
metricsFill = struct('value',{},'color',{});
maxMetricsFillAbs = -Inf;
minMetricsFillAbs = Inf;
maxMetricsFillRel = -Inf;
minMetricsFillRel = Inf;

% turn warnings on polyshapes off
% (since, e.g., you might have zero-area shapes)
warning('off','MATLAB:polyshape:repairedBySimplify')
warning('off','MATLAB:polyshape:boolOperationFailed')

% loop documents and spreads
multiWaitbar('Computing Metric in Documents',0);
for kDocuments = 1:nDocuments

    % waitbar
    multiWaitbar('Computing Metric in Documents','Increment',1/nDocuments);
    multiWaitbar('Computing Metric in Spreads',0);
    
    % compute metric only for active ranges of documents and spreads
    % (We could compute the metric for all documents and spreads, but it might
    % take a long time, so I prefere to do the computing on the active ranges.)
    % spreadRange = preferences.spreadRange;
    % if ~isempty(spreadRange)
    %     r1Spreads = spreadRange(1);
    %     r2Spreads = spreadRange(2);
    % else
    %    r1Spreads = 1;
    %    r2Spreads = nSpreads;
    % end
    r1Spreads = 1;
    r2Spreads = length(geometry(kDocuments).spreads);
    mFaces = 1;
    
    for kSpreads = r1Spreads:r2Spreads
    
        multiWaitbar('Computing Metric in Spreads','Increment',1/r2Spreads);

        % get union of objects
        unionObj = [];
        for kObjType = 1:nObjType

            % object type not in the document
            if ~isfield(geometry(kDocuments).spreads(kSpreads),...
                    objType{kObjType})
                continue
            end
            
            % object type exists in document
            objGeo = geometry(kDocuments).spreads(kSpreads).(objType{kObjType});
            checkboxType = ['checkbox',objType{kObjType}];
            nObj = length(objGeo);
            
            if handles.(checkboxType).Value == 1 && ~isempty(nObj)
                % loop through objects
                nObj = length(objGeo);
                for kObj = 1:nObj
                    poly = polyshape(cat(2,...
                        [objGeo(kObj).coordinates.x]',...
                        [objGeo(kObj).coordinates.y]'));
                    if ~isempty(unionObj)
                        unionObj = union(unionObj,poly);
                    else
                        unionObj = poly;
                    end
                end
            end
        end
        
        % get intersection area between objects and background
        nPages = length(geometry(kDocuments).spreads(kSpreads).Pages);

        if strcmp(preferences.metricsBoundaryType,'Pages')
            
            for kPages = 1:nPages % for each page in the spread
                if isempty(unionObj)
                    valMetric = NaN;
                else
                    bkg = polyshape(...
                        [geometry(kDocuments).spreads(kSpreads).Pages(kPages).coordinates.x],...
                        [geometry(kDocuments).spreads(kSpreads).Pages(kPages).coordinates.y]);

                    % subtract objects selected in the user interface from background
                    intersectionFgdBkd = subtract(bkg,unionObj);

                    % get fill metric
                    valMetric = 1 - area(intersectionFgdBkd)/area(bkg);
                    if valMetric == 0
                        valMetric = NaN;
                    end
                end
            
                % difference between consecutive pages
                if kSpreads == 1 && kPages == 1
                    valDiff = NaN;
                else
                    valMetricPrev = ...
                        metricsFill(kDocuments).value.abs(mFaces - 1);
                    valDiff = abs(valMetric - valMetricPrev);
                end

                % memorize metric for each page and all of its four faces
                % [!!!] we assume we deal with only four-faced polygons
                nFaces = mFaces + 3;
                for kFaces = mFaces:nFaces
                    metricsFill(kDocuments).value.abs(kFaces) = valMetric;
                    metricsFill(kDocuments).value.rel(kFaces) = valDiff;
                end    
                mFaces = nFaces + 1;
                maxMetricsFillAbs = max(maxMetricsFillAbs,valMetric);
                minMetricsFillAbs = min(minMetricsFillAbs,valMetric);
                maxMetricsFillRel = max(maxMetricsFillRel,valDiff);
                minMetricsFillRel = min(minMetricsFillRel,valDiff);
            end
        else % background is spread or pasteboard
            
            if isempty(unionObj)
                valMetric = NaN;
            else
                % unite all pages in a spread
                bkg = [];
                for kPages = 1:nPages
                    poly = polyshape(...
                        [geometry(kDocuments).spreads(kSpreads).Pages(kPages).coordinates.x],...
                        [geometry(kDocuments).spreads(kSpreads).Pages(kPages).coordinates.y]);
                    bkg = union([bkg, poly]);
                end

                % subtract objects selected in the user interface from background
                intersectionFgdBkd = subtract(bkg,unionObj);

                % get fill metric
                valMetric = 1 - area(intersectionFgdBkd)/area(bkg);
                if valMetric == 0
                    valMetric = NaN;
                end
            end

            % difference between consecutive pages
            if kSpreads == 1
                valDiff = NaN;
            else
                valMetricPrev = ...
                    metricsFill(kDocuments).value.abs(mFaces - 1);
                valDiff = abs(valMetric - valMetricPrev);
            end

            % memorize metric for each page and all of its four faces
            % [!!!] we assume we deal with only four-faced polygons
            nFaces = mFaces + nPages * 4 - 1;
            for kFaces = mFaces:nFaces
                metricsFill(kDocuments).value.abs(kFaces) = valMetric;
                metricsFill(kDocuments).value.rel(kFaces) = valDiff;
            end    
            mFaces = nFaces + 1;
            maxMetricsFillAbs = max(maxMetricsFillAbs,valMetric);
            minMetricsFillAbs = min(minMetricsFillAbs,valMetric);
            maxMetricsFillRel = max(maxMetricsFillRel,valDiff);
            minMetricsFillRel = min(minMetricsFillRel,valDiff);
        end
    end
    
    multiWaitbar('Computing Metric in Spreads','Close');
end
multiWaitbar('Computing Metric in Documents','Close');

% restore warnings
warning('on','MATLAB:polyshape:repairedBySimplify')
warning('on','MATLAB:polyshape:boolOperationFailed')

% map metrics into colormap
ncmap = size(preferences.cmap.map,1) - 1;
kcmap = preferences.cmap.selection;
for kDocuments = 1:nDocuments
    % normalize metric values 
    if strcmp(preferences.metricsColormapRangeType,'ZeroOne')
        % [0 minMetricsFill maxMetricsFill] to [0 minMetricsFill 1]
        idx.abs = metricsFill(kDocuments).value.abs / maxMetricsFillAbs;
        idx.rel = metricsFill(kDocuments).value.rel / maxMetricsFillRel;
    end
    if strcmp(preferences.metricsColormapRangeType,'MinMax')
        % [minMetricsFill maxMetricsFill] to [0 1]
        idx.abs = (metricsFill(kDocuments).value.abs - minMetricsFillAbs) / ...
            (maxMetricsFillAbs - minMetricsFillAbs);
        idx.rel = (metricsFill(kDocuments).value.rel - minMetricsFillRel) / ...
            (maxMetricsFillRel - minMetricsFillRel);
    end
    
    % convert to integers of cmap index range [2 257]
    idx.abs = round( idx.abs * (ncmap - 1) + 2 );
    idx.rel = round( idx.rel * (ncmap - 1) + 2 );
    
    % set NaN to index value 1
    idx.abs(isnan(idx.abs)) = 1;
    idx.rel(isnan(idx.rel)) = 1;
    
    % map values to colormap
    metricsFill(kDocuments).color.cmap.abs = ...
        preferences.cmap.map(idx.abs',:,kcmap);
    metricsFill(kDocuments).color.idx.abs = idx.abs';
    metricsFill(kDocuments).color.cmap.rel = ...
        preferences.cmap.map(idx.rel',:,kcmap);
    metricsFill(kDocuments).color.idx.rel = idx.rel';
end

% memorize data
metrics = getappdata(handles.figureMain,'metrics');
metrics.Fill = metricsFill;
metrics.Fill(1).maxValAbs = maxMetricsFillAbs;
metrics.Fill(1).minValAbs = minMetricsFillAbs;
metrics.Fill(1).maxValRel = maxMetricsFillRel;
metrics.Fill(1).minValRel = minMetricsFillRel;
setappdata(handles.figureMain,'metrics',metrics)
