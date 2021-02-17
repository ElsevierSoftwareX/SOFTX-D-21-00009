function DOM = xml_flatten(DOM, node)
% XML_FLATTEN Moves nodes up the DOM hierarchy
% 
% INPUT
% -------------
% DOM - DOM of IDML's Styles.xml and Preferences.xml
% node - XML node name that has to be moved up the DOM hierarchy
% 
% OUTPUT
% -------------
% DOM - Flattened XML structure
% 
% NOTE
% -------------
% This function is used to ungroup styles in InDesign IDML files.
% 
% REQUIREMENTS
% -------------
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

if isfield(DOM,[node 'Group']) == 1
    ng = size(DOM.([node 'Group']), 1);
    for kg = 1:ng
        % get end nodes
        idx = size(DOM.(node),1);
        if isfield(DOM.([node 'Group'])(kg), (node)) == 1
            n = size(DOM.([node 'Group'])(kg).(node), 1);
            for k = 1:n
                DOM.(node)(idx+k).ATTRIBUTE = ...
                    DOM.([node 'Group'])(kg).(node)(k).ATTRIBUTE;
                DOM.(node)(idx+k).Properties = ...
                    DOM.([node 'Group'])(kg).(node)(k).Properties;
            end
        end
        % get intermediary nodes
        if isfield(DOM.([node 'Group'])(kg), [node 'Group']) == 1
            n = size(DOM.([node 'Group'])(kg).([node 'Group']), 1);
            for k = 1:n
                output = ...
                    xml_flatten(DOM.([node 'Group'])(kg).(...
                        [node 'Group'])(k), node);
                if (isfield(output, node) == 1 && ...
                        isempty(output.(node)) == 0)
                    p = size(DOM.(node),1);
                    q = size(output.(node),1);
                    DOM.(node)(p+1:p+1+q) = output.(node);
                end
                if (isfield(output, [node 'Group']) == 1 && ...
                        isempty(output.([node 'Group'])) == 0)
                    p = size(DOM.([node 'Group']),1);
                    q = size(output.([node 'Group']),1);
                    DOM.([node 'Group'])(p+1:p+1+q) = output.([node 'Group']);
                end
            end
        end
    end
end
