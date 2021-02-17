function item = style_inherit(styles, domain, item, parent, properties)
% STYLE_INHERIT - Finds the definiton of inherited styles
% 
% INPUT
% -------------
% styles (structure) - styles in cascade form
% domain (CharacterStyle|ParagraphStyle) - type of style
% item (structure) - single style to be filled out with the inherited info
% parent (string) - name of the parent style (=BasedOn)
% properties (cell array) - styles to look for
% 
% Example:
% item = (styles, 'CharacterStyle', item, 'Normal', 'AppliedFont')
% 
% OUTPUT
% -------------
% item (structure) - style definition w/ inherited data
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


% loop style items
n1 = numel(styles.(domain));
for k1 = 1:n1
    s = styles.(domain)(k1);
    % get item name
    if isfield(s, 'Name')
        % used by souffleur_frames.m
        name = s.Name;
    elseif isfield(s.ATTRIBUTE,'Name')
        % used by souffleur_folios.m
        name = s.ATTRIBUTE.Name;
    end
    
    if strcmp(name, parent) == 1
        % get parent name
        parent = [];
        if isfield(s, 'BasedOn')
            parent = s.BasedOn;
        elseif isfield(s, 'Properties') &&...
                isfield(s.Properties,'BasedOn')
            parent = s.Properties.BasedOn.CONTENT;
        end
        
        % loop properties
        n2 = numel(properties);
        for k2 = 1:n2
            % read property
            if isempty(item.(properties{k2}))
                % properties can be nodes, attributes or child nodes
                % so we have to check them out to see which they are
                if isfield(s, properties{k2})
                    item.(properties{k2}) = ...
                        s.(properties{k2});
                elseif isfield(s.ATTRIBUTE, properties{k2})
                    item.(properties{k2}) = ...
                        s.ATTRIBUTE.(properties{k2});
                elseif isfield(s, 'Properties') &&...
                         isfield(s.Properties, properties{k2})
                    item.(properties{k2}) = ...
                        s.Properties.(properties{k2}).CONTENT;
                end
            end
        end
        break
    end
    % no more parent
    if isempty(parent)
        break
    end
end

% stop if parent not found
if (k1 == n1) && (strcmp(name, parent) == 0)
    return
end

% check if any property is empty
n = numel(properties);
for k = 1:n
    if isempty(item.(properties{k}))
        if ~isempty(parent)
            % call the inheritance function again
            item = style_inherit(styles, domain, item, parent, properties);
        end
    end
end

