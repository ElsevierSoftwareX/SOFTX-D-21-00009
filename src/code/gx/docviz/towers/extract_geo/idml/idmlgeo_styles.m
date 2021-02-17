function xml = idmlgeo_styles(url, DOM)
%IDMLGEO_STYLES Gets data on syles from InDesign IDML files
% 
% -------------
% INPUT
% -------------
% url - URL of IDML unzipped directory
% DOM - IDML DOMs of Styles.xml, Graphic.xml, Preferences.xml
% 
% -------------
% OUTPUT
% -------------
% xml - style description
% 
% -------------
% NOTE
% -------------
% - For the style inheritance logic and limitations see idmlgeo.m.
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
% 2013.10.03 - creation
% 
% -------------
% CREDITS
% -------------
% Vlad Atanasiu, atanasiu@alum.mit.edu, http://alum.mit.edu/www/atanasiu/


% -------------------
% INITIALIZATION
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

if nargin < 2 || isempty(DOM)
    multiWaitbar('Importing IDML files',0);

    multiWaitbar('Importing IDML files','Increment',1/3);
    DOM.Styles = xml_read(...
        [url.dir filesep 'Resources' filesep 'Styles.xml']);
    multiWaitbar('Importing IDML files','Increment',1/3);
    DOM.Preferences = xml_read(...
        [url.dir filesep 'Resources' filesep 'Preferences.xml']);
    multiWaitbar('Importing IDML files','Increment',1/3);
    DOM.Graphic = xml_read(...
        [url.dir filesep 'Resources' filesep 'Graphic.xml']);
    
    multiWaitbar('Importing IDML files','Close');
end

% input, output data
styles = []; % extracted styles
styles.CharacterStyle = [];
styles.ParagraphStyle = [];
styles.TextDefault = [];

indata = []; % indesign styles to be extracted
indata.Domain = {'CharacterStyle','ParagraphStyle'};

indata.CharacterStyle.Descriptors = {'Name','BasedOn',...
    'AppliedFont','FontStyle','PointSize','Leading','FillColor'};
indata.CharacterStyle.Attributes = {...
    'Name','FontStyle','PointSize','FillColor'};
indata.CharacterStyle.Contents = {'BasedOn','AppliedFont','Leading'};

indata.ParagraphStyle.Descriptors = {'Name','BasedOn',...
    'AppliedFont','FontStyle','PointSize','Leading','FillColor',...
    'FirstLineIndent','Justification','SpaceBefore','SpaceAfter',...
    'LeftIndent','RightIndent'};
indata.ParagraphStyle.Attributes = {...
    'Name','FontStyle','PointSize','FillColor',...
    'FirstLineIndent','Justification','SpaceBefore','SpaceAfter',...
    'LeftIndent','RightIndent'};
indata.ParagraphStyle.Contents = {'BasedOn','AppliedFont','Leading'};

indata.TextDefault.Descriptors = {...
    'AppliedFont','FontStyle','PointSize','Leading','FillColor',...
    'FirstLineIndent','Justification','SpaceBefore','SpaceAfter',...
    'LeftIndent','RightIndent'};
indata.TextDefault.Attributes = {...
    'Name','FontStyle','PointSize','FillColor',...
    'FirstLineIndent','Justification','SpaceBefore','SpaceAfter',...
    'LeftIndent','RightIndent'};
indata.TextDefault.Contents = {'AppliedFont','Leading'};


% -------------------
% STYLES
% -------------------

% ungroup styles
n = numel(indata.Domain);
for k = 1:n
    DOM.Styles.(['Root' indata.Domain{k} 'Group']) = xml_flatten(...
        DOM.Styles.(['Root' indata.Domain{k} 'Group']), indata.Domain{k});
end

% loop domains
n1 = numel(indata.Domain);
multiWaitbar('Extracting style types',0);

for k1 = 1:n1
    multiWaitbar('Extracting style types','Increment',1/n1);
    d = indata.Domain{k1};

    % 2. loop style items
    n2 = numel(DOM.Styles.(['Root' d 'Group']).(d));
    multiWaitbar('Style items',0);
    
    for k2 = 1:n2
        multiWaitbar('Style items','Increment',1/n2);
        
        % 3. loop attributes
        n3 = numel(indata.(d).Attributes);
        for k3 = 1:n3
            
            a = indata.(d).Attributes{k3};
            styles.(d)(k2).(a) = [];
            s = DOM.Styles.(['Root' d 'Group']).(d)(k2);
            if isfield(s.ATTRIBUTE, a)
                
                % common
                c = s.ATTRIBUTE.(a);
                styles.(d)(k2).(a) = c;
                
                % exceptions
                if strcmp(a,'Name') == 1
                    
                    % postprocessing
                    % -------------------
                    q = strfind(c,'/'); % remove prepended identifiers
                    if ~isempty(q)
                        c = c(q(end)+1:end);
                    end
                    q = strfind(c,'%3a'); % remove groupe names
                    if ~isempty(q)
                        c = c(q(end)+3:end);
                    end
                    c = strrep(c,'\:','\\'); % avoid escape character
                    q = strfind(c,':');
                    if ~isempty(q)
                        c = c(q(end)+1:end);
                    end
                    c = strrep(c,'\\',':');
                    % -------------------
                    styles.(d)(k2).(a) = c;             
                end
            end
            
            % exceptions
            if strcmp(a,'FillColor') == 1
                styles.(d)(k2).(a) = ...
                    idmlgeo_colors(DOM, styles.(d)(k2).(a));
            end
        end
        
        % 3. loop contents
        n3 = numel(indata.(d).Contents);
        for k3 = 1:n3
            
            a = indata.(d).Contents{k3};
            styles.(d)(k2).(a) = [];
            s = DOM.Styles.(['Root' d 'Group']).(d)(k2);
            if isfield(s, 'Properties') && isfield(s.Properties, a)
                
                % common
                c = s.Properties.(a).CONTENT;
                styles.(d)(k2).(a) = c;
                
                % exceptions
                if strcmp(a,'BasedOn') == 1
                    
                    % postprocessing
                    % -------------------
                    q = strfind(c,'/'); % remove prepended identifiers
                    if ~isempty(q)
                        c = c(q(end)+1:end);
                    end
                    q = strfind(c,'%3a'); % remove groupe names
                    if ~isempty(q)
                        c = c(q(end)+3:end);
                    end
                    c = strrep(c,'\:','\\'); % avoid escape character
                    q = strfind(c,':');
                    if ~isempty(q)
                        c = c(q(end)+1:end);
                    end
                    c = strrep(c,'\\',':');
                    % -------------------
                    styles.(d)(k2).(a) = c;             
                    
                elseif strcmp(a,'Leading') == 1
                    if strcmp(c,'Auto') == 1
                        t = idmlgeo_defaults(DOM,'Preferences',...
                            'TextDefault','attribute','AutoLeading');
                        t = styles.(d)(k2).PointSize * t / 100;
                        styles.(d)(k2).(a) = t;
                    end
                end
            end
        end
    end
    multiWaitbar('Style items','Close');
end
multiWaitbar('Extracting style types','Close');


% -------------------
% DEFAULTS
% -------------------

multiWaitbar('Extracting default style',0);
d = 'TextDefault';
s = DOM.Preferences.(d);
n0 = numel(indata.(d).Attributes) + numel(indata.(d).Contents);

% loop attributes
n = numel(indata.TextDefault.Attributes);
for k = 1:n
    multiWaitbar('Extracting default style','Increment',1/n0);
    a = indata.(d).Attributes{k};
    styles.(d).(a) = [];
    
    if isfield(s.ATTRIBUTE, a)
        % skip properties that shouldn't be inherited
        if strcmp(a,'Name') == 1
            continue
        end
            
        % common
        c = s.ATTRIBUTE.(a);
        styles.(d).(a) = c;

        % exceptions
        if strcmp(a,'FillColor') == 1
            styles.(d).(a) = idmlgeo_colors(DOM, styles.(d).(a));
        end
    end
end

% loop contents
n = numel(indata.(d).Contents);
for k = 1:n
    multiWaitbar('Extracting default style','Increment',1/n0);
    a = indata.(d).Contents{k};
    styles.(d).(a) = [];
    
    if isfield(s.Properties, a)
            
        % common
        c = s.Properties.(a).CONTENT;
        styles.(d).(a) = c;

        % exceptions
        if strcmp(a,'Leading') == 1
            if strcmp(c,'Auto') == 1
                t = idmlgeo_defaults(DOM,'Preferences',...
                    'TextDefault','attribute','AutoLeading');
                t = styles.(d).PointSize * t / 100;
                styles.(d).(a) = t;
            end
        end
    end
end
multiWaitbar('Extracting default style','Close');


% -------------------
% RESOLVE INHERITANCES
% -------------------

% total style numbers
multiWaitbar('Recover inheritances',0);
n0 = 0;
n1 = numel(indata.Domain);
for k = 1:n1
    n0 = n0 + numel(styles.(indata.Domain{k}));
end

% loop domains
n1 = numel(indata.Domain);
for k1 = 1:n1
    d = indata.Domain{k1};

    % loop style items
    n2 = numel(styles.(d));
    for k2 = 1:n2

        multiWaitbar('Recover inheritances','Increment',1/n0);
        item = styles.(d)(k2);
        % skip properties that don't style_inherit
        properties = indata.(d).Descriptors(3:end);

        % loop style descriptors
        n3 = numel(properties);
        for k3 = 1:n3

            % check if any property is empty
            if ~isempty(item.BasedOn)
                if isempty(item.(properties{k3}))
                    % style_inherit style
                    parent = item.BasedOn;
                    item = style_inherit(styles, d, item, parent, properties);
                end
            end
        end

        % if still empty read defaults
        for k3 = 1:n3

            % check if any property is empty
            if isempty(item.(properties{k3}))

                % read default property
                item.(properties{k3}) = styles.TextDefault.(properties{k3});            
            end
        end
        styles.(d)(k2) = item;
    end
end
multiWaitbar('Recover inheritances','Close');


% -------------------
% GENERATE XML STRING
% -------------------

xml = '\t<styles>\n';
% total style numbers
n0 = 0;
n1 = numel(indata.Domain);
for k = 1:n1
    n0 = n0 + numel(styles.(indata.Domain{k}));
end

% loop domains
multiWaitbar('Writing XML string',0);
for k1 = 1:n1
    xml = [xml '\t\t<' indata.Domain{k1} '>\n'];

    % loop style items
    n2 = numel(styles.(indata.Domain{k1}));
    for k2 = 1:n2
        multiWaitbar('Writing XML string','Increment',1/n0);
        xml = [xml '\t\t\t<style>\n'];

        % loop style descriptors
        f = indata.(indata.Domain{k1}).Descriptors;
        n3 = numel(f);
        for k3 = 1:n3

            c = styles.(indata.Domain{k1})(k2).(f{k3});

            % exceptions
            if strcmp(f{k3}, 'FillColor') == 1
                c = ['\n' ...
                    '\t\t\t\t\t<Name>' c.Name '</Name>\n' ...
                    '\t\t\t\t\t<Model>' c.Model '</Model>\n' ...
                    '\t\t\t\t\t<Space>' c.Space '</Space>\n' ...
                    '\t\t\t\t\t<ColorValue>' num2str(c.ColorValue) ...
                        '</ColorValue>\n' ...
                    '\t\t\t\t'];
            % common
            else
                % postprocessing
                % -------------------
                if ~isa(c,'char') % convert from number to string
                    c = num2str(c);
                end
                % -------------------
            end

            % style node
            xml = [xml '\t\t\t\t<' f{k3} '>' c '</' f{k3} '>\n'];

        end
        xml = [xml '\t\t\t</style>\n'];
    end
    xml = [xml '\t\t</' indata.Domain{k1} '>\n'];
end
xml = [xml '\t</styles>\n'];
multiWaitbar('Writing XML string','Close');

