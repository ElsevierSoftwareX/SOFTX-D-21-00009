function altogeo(urlRoot)
%ALTOGEO Reads document object coordinates from Alto files
% 
% -------------
% INPUT
% -------------
% urlRoot - URL of directory with Alto directories
%
% -------------
% OUTPUT
% -------------
% JSON file, in urlRoot, containg Alto document geometry
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
% 2018.09.12 - creation
% 
% -------------
% CREDITS
% -------------
% Vlad Atanasiu, atanasiu@alum.mit.edu, http://alum.mit.edu/www/atanasiu/


% -------------------
% INITIALIZATION
% -------------------

% select directory interactively if none supplied
if nargin < 1 || isempty(urlRoot)
    urlRoot = uigetdir('','Select directory with Alto directories');
    if urlRoot == 0
        return
    end
end

% footprint
footprint.n = Inf;
footprint.e = -Inf;
footprint.s = -Inf;
footprint.w = Inf;

% current folder
oldFolder = cd(urlRoot);


% -------------------
% PROCESS FILES
% -------------------

% retain folders and no files
urlDoc = dir;
urlDoc(~[urlDoc.isdir]) = [];
urlDoc(1:2) = [];

% loop documents
multiWaitbar('Process Documents',0);
ndoc = numel(urlDoc);
objLabelsDoc = cell(1,ndoc);
for kdoc = 1:ndoc
    multiWaitbar('Process Documents','Increment',1/ndoc);

    % loop pages
    urlPage = dir([urlDoc(kdoc).name, filesep, 'ALTO', filesep, '*.xml']);
    
    % initialize
    counts.Pages = 0;
    counts.Texts = 0;
    counts.Images = 0;
    counts.Graphics = 0;
    counts.Fonts = 0;
    
    multiWaitbar('Process Spreads',0);
    geoDoc = [];
    npg = numel(urlPage);
    counts.Pages = npg;
    for kpg = 1:npg
        multiWaitbar('Process Spreads','Increment',1/npg);
        
        % extract page geometry
        url = [urlPage(kpg).folder, filesep, urlPage(kpg).name];
        [geoSpread, countsSpread, footprintSpread, objLabelsPg] = altogeo_pg(url);
        
        % update docuemnt geometry and object format counts
        geoDoc = [geoDoc, geoSpread];
        counts.Texts = counts.Texts + countsSpread.Texts;
        counts.Images = counts.Images + countsSpread.Images;
        counts.Graphics = counts.Graphics + countsSpread.Graphics;
        counts.Fonts = counts.Fonts + countsSpread.Fonts;
        
        % update document footprint
        if footprint.n > footprintSpread.n
            footprint.n = footprintSpread.n; % top
        end
        if footprint.e < footprintSpread.e
            footprint.e = footprintSpread.e; % right
        end
        if footprint.s < footprintSpread.s
            footprint.s = footprintSpread.s; % bottom
        end
        if footprint.w > footprintSpread.w
            footprint.w = footprintSpread.w; % left
        end
        
        % update object label list
        if kpg == 1
            objLabelsDoc = sort(unique(objLabelsPg));
        else
            objLabelsDoc = sort(unique([objLabelsDoc,objLabelsPg]));
        end

    end
    geoDoc(end-2) = [];
    multiWaitbar('Process Spreads','Close');
    
    % manage object labels
    objLabelsLegend = [];
    n = numel(objLabelsDoc);
    for k = 1:n
        
        % replace textual labels by numerical keys
        targetStr = ['"',char(objLabelsDoc(k)),'"'];
        geoDoc = strrep(geoDoc, targetStr, num2str(k));
        
        % generate key-labels concordance legend
        objLabelsLegend = [objLabelsLegend,...
            '[',num2str(k),',"',char(objLabelsDoc(k)),'"],'];
    end
    objLabelsLegend = ['[','[0,"Unlabeled"],',objLabelsLegend(1:end-1),']'];
    
    % add header and footer
    urlPDF = [urlDoc(kdoc).folder, filesep, urlDoc(kdoc).name,...
        filesep, urlDoc(kdoc).name, '.pdf'];
    urlPDF = strrep(urlPDF,' ','%20');
    json = [...
        'jsondata ({\n',...
            '\t"geometry":\n',...
            '\t[\n',...
            '\t\t"",\n',...
            geoDoc,...
            '\t],\n',...
            '\t"metadata":\n',...
            '\t{\n',...
                '\t\t"filename":"',urlDoc(kdoc).name,'.pdf",\n',...
                '\t\t"url":"file://',urlPDF,'",\n',...
                '\t\t"volume":[',...
                    num2str(footprint.n,'%.4f'),', ',...
                    num2str(footprint.e,'%.4f'),', ',...
                    num2str(footprint.s,'%.4f'),', ',...
                    num2str(footprint.w,'%.4f'),', ',...
                    num2str(counts.Pages),'],\n',...
                '\t\t"counts":[',...
                    num2str(counts.Pages),', ',...
                    num2str(counts.Texts),', ',...
                    num2str(counts.Images),', ',...
                    num2str(counts.Graphics),', ',...
                    num2str(counts.Fonts),'],\n',...
                '\t\t"objects":[[0,"Pages"],[1,"Text"],[2,"Images"],',...
                '[3,"Graphics"],[4,"Fonts"]],\n',...
                '\t\t"labels":',objLabelsLegend,',\n',...
                '\t\t"legend":',...
                    '"geometry: object format type, object label, ',...
                    'bounding box coordinates (n * (y, x)), ',...
                    'font name, font size, font fill color (rgba); ',...
                    'volume: top, right, bottom, left bounding volume coordinates"\n',...
            '\t}\n',...
        '})'];
    
    % save document
    hf = fopen([urlDoc(kdoc).name,'.json'],'wt');
    fprintf(hf,json);
    fclose(hf);

end
multiWaitbar('Process Documents','Close');

% finish
cd(oldFolder)
beep, beep, beep
