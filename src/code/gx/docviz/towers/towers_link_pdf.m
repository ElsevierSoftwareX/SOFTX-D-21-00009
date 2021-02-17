function towers_link_pdf(hObject, ~)
%TOWERS_LINK_PDF Display selected PDF document page web browser
% 
% -------------
% INPUT
% -------------
% hObject - handle of text tag to the document visualization where the
%   page number where the document has to be opened is to be found
% url - url of the PDF document to be openend at a specific page
%   (this is given in the metadata of the json file of the document)
%     The syntax for a local file is
%       'file:///mydirectory/mypdf.pdf'
%     and for an online file:
%       'http://mydirectory/mypdf.pdf',
%       'ftp://mydirectory/mypdf.pdf', etc.
%     Don't use escape characters. 
%     Ex: use ' ' (space) instead of '%20', and '%' for '%%'.
%
% -------------
% OUTPUT
% -------------
% the PDF document will be opened in a web browser at a given page
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
% 2015.05.22 - creation


% get document url and page number
handles = guihandles(hObject);
metadata = getappdata(handles.figureMain,'metadata');
url = metadata(hObject.UserData(1)).url;
pgnbr = num2str(hObject.UserData(2));

% document url is unknonw
if isempty(url)
    return
end

% make html file container for pdf
% (The software that opens PDF files might not be able to handle standard
% Adobe API instructions for PDFs, such as opening them at specific pages 
% [such is apparently the case for Mac's Preview]. We circonvent this by
% using the web browser to open PDFs, and this is the reason we encapsulate
% the PDF in an html. Note that if the browser has no PDF reader capability,
% we won't be able to see the PDF.)
html = ['<html><body style="margin:0px;"><object data="',...
    url, '#page=', num2str(pgnbr),...
    '" type="application/pdf" width="100%" height="100%">',...
    '<p style="font-family:monospace;">To view <a href="',url,...
    '">this file</a> in your browser you need to install a ',...
    '<a href="https://www.google.com/search?q=pdf%20plugin" ',...
    'target="_blank">PDF plugin</a>.</p>',...
    '</object></body></html>'];
html = strrep(html,'%','%%');
% appRoot = getappdata(handles.figureMain,'appRoot');
appRoot = pwd;
fid = fopen([appRoot,filesep,'pdf.html'],'w');
fprintf(fid,html,'%s');
fclose(fid);

% display pdf at selected page
web([appRoot,filesep,'pdf.html'],'-browser')

