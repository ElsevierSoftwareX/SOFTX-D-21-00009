function towers_PaintCardinality(hObject,jumpToCompute)

% -----------------
% Metric definition
% -----------------
% CARDINALITY = Number of objects in a page or spread.


% parse input
if nargin < 2 || isempty(jumpToCompute)
    jumpToCompute = false;
end

% only metrics computing, no paint update
if jumpToCompute == true
    computeMetricsCardinality(hObject)
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
handles.radiobuttonPaintCardinality.Value = 1;
handles.radiobuttonPaintFill.Value = 0;
handles.radiobuttonPaintSalliency.Value = 0;
handles.radiobuttonPaintConfiguration.Value = 0;
handles.radiobuttonPaintInfoPotential.Value = 0;

% memorize paint state
preferences.paint = 'Cardinality';
setappdata(handles.figureMain,'preferences',preferences)

% paint page objects
hFigureMain = handles.figureMain;

% compute metrics if not already done
metrics = getappdata(hFigureMain,'metrics');
if isfield(metrics,'Cardinality') == 0 || isempty(metrics.Cardinality)
    computeMetricsCardinality(hObject);
    metrics = getappdata(hFigureMain,'metrics');
end

% paint page objects
hObjectClasses = getappdata(hFigureMain,'hObjectClasses');
nDocuments = length(hObjectClasses);
for kDocuments = 1:nDocuments
    hObjectClasses(kDocuments).Pages(1).Children.FaceAlpha = 1;
    if strcmp(preferences.metricsValueType,'Absolute')
        hObjectClasses(kDocuments).Pages(1).Children.FaceVertexCData = ...
            metrics.Cardinality(kDocuments).color.cmap.abs;
    else
        hObjectClasses(kDocuments).Pages(1).Children.FaceVertexCData = ...
            metrics.Cardinality(kDocuments).color.cmap.rel;
    end
end


function computeMetricsCardinality(hObject)
% Cardinality metric
% - measure: item number per spread
% - meaning: information density

handles = guihandles(hObject);
geometry = getappdata(handles.figureMain,'geometry');
preferences = getappdata(handles.figureMain,'preferences');
objType = {'Text','Images','Graphics'};
nObjType = length(objType);
     
% size data
nDocuments = length(geometry);
metricsCardinality = struct('value',{},'color',{});
maxMetricsCardinalityAbs = -Inf;
minMetricsCardinalityAbs = Inf;
maxMetricsCardinalityRel = -Inf;
minMetricsCardinalityRel = Inf;

% turn warnings on polyshapes off
% (since, e.g., you might have zero-area shapes)
% identify error: >> warning('query','last')
warning('off','MATLAB:polyshape:repairedBySimplify')
warning('off','MATLAB:polyshape:boolOperationFailed')

% metrics on pages
multiWaitbar('Parsing Documents',0);
for kDocuments = 1:nDocuments
    multiWaitbar('Parsing Documents','Increment',1/nDocuments);
    multiWaitbar('Parsing Spreads',0);
    
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
        multiWaitbar('Parsing Spreads','Increment',1/(r2Spreads - r1Spreads));
        
        % collect objects into single vector
        fgdObj = [];
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
            
            if handles.(checkboxType).Value == 1 && ~isempty(nObj)  && nObj ~= 0
                % loop through objects
                for kObj = 1:nObj
                    poly = polyshape(...
                        [objGeo(kObj).coordinates.x],...
                        [objGeo(kObj).coordinates.y]);
                    fgdObj = [fgdObj, poly];
                end
            end
        end
        
        % compute number of objects overlaping with metrics boundary
        nPages = length(geometry(kDocuments).spreads(kSpreads).Pages);
        
        if strcmp(preferences.metricsBoundaryType,'Pages')
            for kPages = 1:nPages

                % single page boundary
                bkd = polyshape(...
                    [geometry(kDocuments).spreads(kSpreads).Pages(kPages).coordinates.x],...
                    [geometry(kDocuments).spreads(kSpreads).Pages(kPages).coordinates.y]);
                inBoundaryMtx = overlaps([bkd, fgdObj]);
                valMetric = sum(inBoundaryMtx(1,:)) - 1; % the 'one' we
                % remove represents the verlaping of an object with itself
                
                if valMetric == 0
                    valMetric = NaN;
                end
                
                % difference between consecutive pages
                if kSpreads == 1 && kPages == 1
                    valDiff = NaN;
                else
                    % use logarithmic scale
                    if strcmp(preferences.metricsCardinalityType,'Log')
                        valMetricPrev = ...
                            metricsCardinality(kDocuments).value.abs(mFaces - 1);
                        valMetricPrev = 2^valMetricPrev;
                        valDiff = abs(valMetric - valMetricPrev);
                        
                        valMetric = log2( valMetric + 1 ); % the 'one' we 
                        % add makes valMetric be have value 1 when there is
                        % only one object within the boundary (log2(2) = 1);
                        % thus we avoid a valMetric value of zero for both
                        % one and no object within boundary
                    else
                        valMetricPrev = ...
                            metricsCardinality(kDocuments).value.abs(mFaces - 1);
                        valDiff = abs(valMetric - valMetricPrev);
                    end
                end

                % memorize cardinality for each page and all of its four faces
                % we assume we deal with only four-faced polygons
                % and the page sequence is left-to-right
                nFaces = mFaces + 3;
                for kFaces = mFaces:nFaces
                    metricsCardinality(kDocuments).value.abs(kFaces) = valMetric;
                    metricsCardinality(kDocuments).value.rel(kFaces) = valDiff;
                end
                maxMetricsCardinalityAbs = max(maxMetricsCardinalityAbs,valMetric);
                minMetricsCardinalityAbs = min(minMetricsCardinalityAbs,valMetric);
                maxMetricsCardinalityRel = max(maxMetricsCardinalityRel,valDiff);
                minMetricsCardinalityRel = min(minMetricsCardinalityRel,valDiff);
                mFaces = nFaces + 1;
            end
            
        elseif strcmp(preferences.metricsBoundaryType,'Spreads')
            
            % unite all pages in a spread
            bkgBoundary = [];
            for kPages = 1:nPages
                poly = polyshape(...
                    [geometry(kDocuments).spreads(kSpreads).Pages(kPages).coordinates.x],...
                    [geometry(kDocuments).spreads(kSpreads).Pages(kPages).coordinates.y]);
                bkgBoundary = union([bkgBoundary, poly]);
            end
            
            % compute cardinality
            inBoundaryMtx = overlaps([bkgBoundary, fgdObj]);
            valMetric = sum(inBoundaryMtx(1,:)) - 1;

            if valMetric == 0
                valMetric = NaN;
            end

            % difference between consecutive pages
            if kSpreads == 1
                valDiff = NaN;
            else
                % use logarithmic scale
                if strcmp(preferences.metricsCardinalityType,'Log')
                    valMetricPrev = ...
                        metricsCardinality(kDocuments).value.abs(mFaces - 1);
                    valMetricPrev = 2^valMetricPrev;
                    valDiff = abs(valMetric - valMetricPrev);

                    valMetric = log2( valMetric + 1 ); % the 'one' we 
                    % add makes valMetric be have value 1 when there is
                    % only one object within the boundary (log2(2) = 1);
                    % thus we avoid a valMetric value of zero for both
                    % one and no object within boundary
                else
                    valMetricPrev = ...
                        metricsCardinality(kDocuments).value.abs(mFaces - 1);
                    valDiff = abs(valMetric - valMetricPrev);
                end
            end
                
            % memorize cardinality for each page and all of its four faces
            % we assume we deal with only four-faced polygons
            nFaces = mFaces + nPages * 4 - 1;
            for kFaces = mFaces:nFaces
                metricsCardinality(kDocuments).value.abs(kFaces) = valMetric;
                metricsCardinality(kDocuments).value.rel(kFaces) = valDiff;
            end
            maxMetricsCardinalityAbs = max(maxMetricsCardinalityAbs,valMetric);
            minMetricsCardinalityAbs = min(minMetricsCardinalityAbs,valMetric);
            maxMetricsCardinalityRel = max(maxMetricsCardinalityRel,valDiff);
            minMetricsCardinalityRel = min(minMetricsCardinalityRel,valDiff);
            mFaces = nFaces + 1;
            
        else % pasteboard
            
            valMetric = length(fgdObj);
            
            if valMetric == 0
                valMetric = NaN;
            end

            % difference between consecutive pages
            if kSpreads == 1
                valDiff = NaN;
            else
                % use logarithmic scale
                if strcmp(preferences.metricsCardinalityType,'Log')
                    valMetricPrev = ...
                        metricsCardinality(kDocuments).value.abs(mFaces - 1);
                    valMetricPrev = 2^valMetricPrev;
                    valDiff = abs(valMetric - valMetricPrev);

                    valMetric = log2( valMetric + 1 ); % the 'one' we 
                    % add makes valMetric be have value 1 when there is
                    % only one object within the boundary (log2(2) = 1);
                    % thus we avoid a valMetric value of zero for both
                    % one and no object within boundary
                else
                    valMetricPrev = ...
                        metricsCardinality(kDocuments).value.abs(mFaces - 1);
                    valDiff = abs(valMetric - valMetricPrev);
                end
            end
            
            % memorize cardinality for each page and all of its four faces
            % we assume we deal with only four-faced polygons
            nFaces = mFaces + nPages*4 - 1;
            for kFaces = mFaces:nFaces
                metricsCardinality(kDocuments).value.abs(kFaces) = valMetric;
                metricsCardinality(kDocuments).value.rel(kFaces) = valDiff;
            end
            maxMetricsCardinalityAbs = max(maxMetricsCardinalityAbs,valMetric);
            minMetricsCardinalityAbs = min(minMetricsCardinalityAbs,valMetric);
            maxMetricsCardinalityRel = max(maxMetricsCardinalityRel,valDiff);
            minMetricsCardinalityRel = min(minMetricsCardinalityRel,valDiff);
            mFaces = nFaces + 1;
        end
            
    end
    multiWaitbar('Parsing Spreads','Close');
end
multiWaitbar('Parsing Documents','Close');

% restore warnings
warning('on','MATLAB:polyshape:repairedBySimplify')
warning('on','MATLAB:polyshape:boolOperationFailed')

% map metrics into colormap
ncmap = size(preferences.cmap.map,1) - 1;
kcmap = preferences.cmap.selection;
for kDocuments = 1:nDocuments
    % normalize metric values
    if strcmp(preferences.metricsColormapRangeType,'ZeroOne')
        % [0 maxMetricsCardinality] as [0 1]
        idx.abs = metricsCardinality(kDocuments).value.abs / maxMetricsCardinalityAbs;
        idx.rel = metricsCardinality(kDocuments).value.rel / maxMetricsCardinalityRel;
    end
    if strcmp(preferences.metricsColormapRangeType,'MinMax')
        % [minMetricsCardinality maxMetricsCardinality] as [0 1]
        idx.abs = (metricsCardinality(kDocuments).value.abs - minMetricsCardinalityAbs) / ...
            (maxMetricsCardinalityAbs - minMetricsCardinalityAbs);
        idx.rel = (metricsCardinality(kDocuments).value.rel - minMetricsCardinalityRel) / ...
            (maxMetricsCardinalityRel - minMetricsCardinalityRel);
    end
    
    % convert to integers of cmap index range [2 257] (1 reserved for white)
    idx.abs = round( idx.abs * (ncmap - 1) + 2 );
    idx.rel = round( idx.rel * (ncmap - 1) + 2 );
    
    % set NaN (i.e. value zero) to index value 1 (i.e. map to color white)
    idx.abs(isnan(idx.abs)) = 1;
    idx.rel(isnan(idx.rel)) = 1;
    
    % map values to colormap
    metricsCardinality(kDocuments).color.cmap.abs = ...
        preferences.cmap.map(idx.abs',:,kcmap);
    metricsCardinality(kDocuments).color.idx.abs = idx.abs';
    metricsCardinality(kDocuments).color.cmap.rel = ...
        preferences.cmap.map(idx.rel',:,kcmap);
    metricsCardinality(kDocuments).color.idx.rel = idx.rel';
end

% memorize data
metrics = getappdata(handles.figureMain,'metrics');
metrics.Cardinality = metricsCardinality;
metrics.Cardinality(1).maxValAbs = maxMetricsCardinalityAbs;
metrics.Cardinality(1).minValAbs = minMetricsCardinalityAbs;
metrics.Cardinality(1).maxValRel = maxMetricsCardinalityRel;
metrics.Cardinality(1).minValRel = minMetricsCardinalityRel;
setappdata(handles.figureMain,'metrics',metrics)
