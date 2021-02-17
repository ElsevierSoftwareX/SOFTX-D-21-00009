function towers_PaintNone(hObject)
% at first call of 'Paint' functions we compute this metric for the all 
% documents available; even if not all documents or all pages are
% visualized; thus we avoid repeated computation of this metric

handles = guihandles(hObject);
if hObject.Value == 1
    
    % deactivation of opposite choice controls
    handles.radiobuttonPaintNone.Value = 1;
    handles.radiobuttonPaintCardinality.Value = 0;
    handles.radiobuttonPaintFill.Value = 0;
    handles.radiobuttonPaintSalliency.Value = 0;
    handles.radiobuttonPaintConfiguration.Value = 0;
    handles.radiobuttonPaintInfoPotential.Value = 0;

    % memorize paint state
    preferences = getappdata(handles.figureMain,'preferences');
    preferences.paint = 'None';
    setappdata(handles.figureMain,'preferences',preferences)
    
    % make object transparent
    hFigureMain = handles.figureMain;
    hObjectClasses = getappdata(hFigureMain,'hObjectClasses');
    n = length(hObjectClasses);
    for k = 1:n
        hObjectClasses(k).Pages(1).Children.FaceAlpha = 0;
    end
else
    hObject.Value = 1;
end
