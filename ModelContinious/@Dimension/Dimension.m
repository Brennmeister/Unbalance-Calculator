classdef Dimension < handle
    %DIMENSION Describes a geometric dimension including the tolerances
    %
    
    properties
        id
        nominal
        tolerance
        tolerance_class
        distribution
        sigma
        z_sigma % Streuintervall
        source
        unit
        desc
        linked_to = struct('part',{}, 'property', {}, 'calc_func', {})
        use_nominal
        force_value_in_interval
    end
    
    methods
        function obj = Dimension(varargin)
            %DIMENSION Construct an instance of this class
            %   Detailed explanation goes here
            inpPa = inputParser;
            inpPa.addParameter(                       'id',       '',        @isstr                                         );
            inpPa.addParameter(                  'nominal',       [],        @isnumeric                                     );
            
            inpPa.addParameter(                'tolerance',       [],        @isnumeric                                     );
            inpPa.addParameter(          'tolerance_class',       [],        @(x) or(ischar(x),isempty(x))                  );
            inpPa.addParameter(             'distribution',   'unif',        @(x) any(validatestring(x,{'norm', 'unif'}))   );
            inpPa.addParameter(                    'sigma',       [],        @isnumeric                                     );
            inpPa.addParameter(                  'z_sigma',       [],        @isnumeric                                     );
            inpPa.addParameter(                   'source',       '',        @(x) or(ischar(x),isempty(x))                  );
            inpPa.addParameter(                     'unit',      'm',        @(x) or(ischar(x),isempty(x))                  );
            inpPa.addParameter(                     'desc',       '',        @(x) or(ischar(x),isempty(x))                  );
            inpPa.addParameter(              'use_nominal',     true,        @boolean                                       );
            inpPa.addParameter(  'force_value_in_interval',     true,        @boolean                                       );
            
            
            inpPa.parse(varargin{:})
            
            if strcmp(inpPa.Results.id,'')
                error('Given id must not be empty.');
            end
            if inpPa.Results.nominal == []
                error('Given nominal value must not be empty.');
            end
            
            % only one of sigma/z_sigma might be given at the same time
            if and(~isempty(inpPa.Results.sigma), ~isempty(inpPa.Results.z_sigma))
                error('Only one of these parameters might be given at the same time: sigma, z_sigma');
            end
            
            %% Assigen values not needing further checking
            obj.id                        = inpPa.Results.id;
            obj.nominal                   = inpPa.Results.nominal;
            obj.tolerance_class           = inpPa.Results.tolerance_class();
            obj.distribution              = inpPa.Results.distribution;
            obj.source                    = inpPa.Results.source;
            obj.unit                      = inpPa.Results.unit;
            obj.desc                      = inpPa.Results.desc;
            obj.use_nominal               = inpPa.Results.use_nominal;
            obj.force_value_in_interval   = inpPa.Results.force_value_in_interval;
            obj.tolerance                 = inpPa.Results.tolerance;
            
            %% Check if tolerance_class can be resolved
            if ~isempty(obj.tolerance_class) & ~any(strcmp(obj.tolerance_class,{'min', 'max', 'allg'})) & isempty(obj.tolerance)
                obj.tolerance       = obj.ressolve_tolerance_class();
                tolerance_already_set = true;
            end
            
            if ~isempty(inpPa.Results.z_sigma)
                obj.z_sigma = inpPa.Results.z_sigma;
                % Check if distribution is normal distribution
                if ~strcmp(inpPa.Results.distribution, 'norm')
                    error('setting z_sigma is only supported for normal distribution');
                end
                % Calculate the resulting sigma
                obj.sigma = (obj.tolerance(2)-obj.tolerance(1))/2 / inpPa.Results.z_sigma;
            else
                % Use given values without any further processing
               obj.z_sigma = inpPa.Results.z_sigma;
               obj.sigma   = inpPa.Results.sigma;
            end

            

        end
        
        function val = value(obj)
            %% VALUE returns one value, according to the dimension's distribution
            if obj.use_nominal
                val = obj.nominal;
            else
                val = obj.nominal + obj.differing(1);
            end
        end
        
        function val = values(obj, N)
            %% VALUES returns N values
            val = nan(N,1);
            for ii=1:N
                val(ii)=obj.value;
            end
        end
        function val = differing(obj, N)
            %% Calculates a random Value between low and high with given distribution
            if ~isempty(obj.tolerance)
                val=nan;
                if strcmpi(obj.distribution,'unif')
                    % Assure that the new value is within the defined
                    % tolerance
                    val = obj.tolerance(1) + (obj.tolerance(2)-obj.tolerance(1)).*rand(N,1);
                    % Assure that the new value is within the defined
                    % tolerance
                    while and(obj.force_value_in_interval, or(val<obj.tolerance(1), val>obj.tolerance(2)))
                        val = obj.tolerance(1) + (obj.tolerance(2)-obj.tolerance(1)).*rand(N,1);
                    end
                elseif strcmpi(obj.distribution,'norm')
                    val = (obj.tolerance(1) + obj.tolerance(2))/2 + obj.sigma*randn(N,1);
                    % Assure that the new value is within the defined
                    % tolerance
                    while and(obj.force_value_in_interval, or(val<obj.tolerance(1), val>obj.tolerance(2)))
                        % Varianz = sigma^2
                        val = (obj.tolerance(1) + obj.tolerance(2))/2 + obj.sigma*randn(N,1);
                    end
                end
            else
                val=0;
            end
        end
        
        
        function addLinkTo(obj, pa, prop, calc_func)
            %% Links the Dimension to a part or assembly
            % Example:
            % dim.addLinkTo(partA, 'primitive.length')
            if ~exist('calc_func','var')
                calc_func=@(dim_value)dim_value;
            end
            if ~obj.isLinkedTo(pa,prop)
                obj.linked_to(end+1) = struct(...
                    'part', pa, ...
                    'property', prop, ...
                    'calc_func', calc_func);
            else
                warning('Part/Assembly is already linked!')
            end
        end
        function is_linked = isLinkedTo(obj, pa, prop)
            %% Checks if the given part and properties are linked
            is_linked = false;
            for l = obj.linked_to
                if and((l.part == pa), strcmp(l.property, prop))
                    is_linked = true;
                    break;
                end
            end
        end
        function removeLinkTo(obj, pa, prop)
            %% Removes a linked part/assembly
            for ii = 1:size(obj.linked_to,1)
                if and((obj.linked_to(ii).part == pa), strcmp(obj.linked_to(ii).property, prop))
                    obj.linked_to(ii)=[];
                    break;
                end
            end
        end
        function updateLinkedEntities(obj)
            %% UPDATELINKEDENTITIES updates the values on each linked part/assembly
            links = obj.linked_to;
            for ii = 1:length(obj.linked_to)
                cmd=sprintf('links(%d).part.%s = [%s];', ii, links(ii).property, sprintf('%f,',links(ii).calc_func(obj.value())));
                %  fprintf('Executing "%s" on part %s for dim-id %s\n', cmd, links(ii).part.description, obj.id);
                try
                    eval(cmd);
                catch
                    warning('ERROR Executing "%s" on part %s for dim-id %s\n', cmd, links(ii).part.description, obj.id);
                end
                
                % % %% Resolve the defined property string to actual useable parts
                % % % Not yet fully implemented.
                % % % test with:
                % % % pa.property='mass';
                % % % pa.property='primitive.length';
                % % % pa.property='parent.origin(1)';
                % % % pa.property='parent.origin(1:3)';
                % % % pa.property='parent.parent.parent.origin';
                % % named_tok = regexp(pa.property,'(?<parent>parent\.)*(?<primitive>primitive\.)?(?<prop>[^\(\n]*)(?<elements>\((\d):?(\d)?\))?','names');
                % % % Get depth of parents
                % % named_tok.num_parents = length(regexp(named_tok.parent,'parent'));
                % % % Get Components of Property
                % % if ~isempty(named_tok.elements)
                % %     elements = regexp(named_tok.elements(2:end-1),':','split');
                % %     if length(elements)==1
                % %         named_tok.elements = str2double(elements(1));
                % %     elseif length(elements)==2
                % %         named_tok.elements = str2double(elements(1)):str2double(elements(2));
                % %     else
                % %         error('Specified range contains more than 1 range-identifier.');
                % %     end
                % % else
                % %     named_tok.elements=[];
                % % end
                % % 
                % % % Step up to the parent entity
                % % p = pa.part;
                % % for ii=1:named_tok.num_parents
                % %     p = p.parent;
                % % end
                
                
                
            end
        end
        
%         function str = get_create_params(obj)
%             %% GET_CREATE_PARAMS returns a sting containing the constructor params
%             % props = properties(obj);
%             props=struct(...
%                 'id'                     , 15,...
%                 'nominal'                , 15,...
%                 'tolerance'              , 15,...
%                 'tolerance_class'        , 15,...
%                 'distribution'           , 15,...
%                 'sigma'                  , 15,...
%                 'z_sigma'                , 15,...
%                 'source'                 , 35,...
%                 'unit'                   , 15,...
%                 'desc'                   , 35,...
%                 'use_nominal'            , 15,...
%                 'force_value_in_interval', 20 ...
%                 );
%             props_vals = strings(length(props),1);
%             fn = fieldnames(props);
%             for ii=1:length(fn)
%                 val = obj.(fn{ii});
%                 if ischar(val)
%                     props_vals(ii) = sprintf('''%s'', ''%s''', fn{ii}, val);
%                 else
%                     if strcmp(fn{ii},'tolerance')
%                         props_vals(ii) = sprintf('''%s'', [% 3.4f, % 3.4f]', fn{ii}, val);
%                     elseif ~isempty(val)
%                          props_vals(ii) = sprintf('''%s'', %5.5f', fn{ii}, val);
%                     else
%                          props_vals(ii) = sprintf('''%s'', []', fn{ii});
%                     end
%                 end
%                 props_vals(ii)=sprintf('% *s', props.(fn{ii}), props_vals(ii));
%             end
%             str = join(props_vals, ',');
%         end
    end
end

