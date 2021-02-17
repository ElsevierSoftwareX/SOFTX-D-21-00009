function url = url_chop(url)
% URL_CHOP - Gets path & name of a directory URL
% 
% INPUT
% -------------
% url - A structure 'url.dir' with the URL of the IDML unzipped directory
% 
% OUTPUT
% -------------
% url.path - the path to url.dir
% url.name - the name in the url.dir
% 
% CREDITS
% -------------
% Vlad Atanasiu
% atanasiu@alum.mit.edu
% http://alum.mit.edu/www/atanasiu/
% 
% LOG
% -------------
% 2013.10.03
%     - creation

if strcmp(url.dir(end), filesep) == 1
    url.dir = url.dir(1:end-1);
end
t = strfind(url.dir, filesep);
url.path = url.dir(1:t(end));
url.name = url.dir(t(end)+1:length(url.dir));
