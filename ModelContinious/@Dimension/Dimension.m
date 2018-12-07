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
            inpPa.addParameter(          'tolerance_class',       [],        @isstr                                         );
            inpPa.addParameter(             'distribution',   'unif',        @(x) any(validatestring(x,{'norm', 'unif'}))   );
            inpPa.addParameter(                    'sigma',       [],        @isnumeric                                     );
            inpPa.addParameter(                   'source',       '',        @isstr                                         );
            inpPa.addParameter(                     'unit',       '',        @isstr                                         );
            inpPa.addParameter(                     'desc',       '',        @isstr                                         );
            inpPa.addParameter(              'use_nominal',     true,        @boolean                                       );
            inpPa.addParameter(  'force_value_in_interval',     true,        @boolean                                       );
            
            
            inpPa.parse(varargin{:})
            
            if strcmp(inpPa.Results.id,'')
                error('Given id must not be empty.');
            end
            if inpPa.Results.nominal == []
                error('Given nominal value must not be empty.');
            end
            % Assign values
            obj.id                        = inpPa.Results.id;
            obj.nominal                   = inpPa.Results.nominal;
            obj.tolerance                 = inpPa.Results.tolerance;
            obj.distribution              = inpPa.Results.distribution;
            obj.sigma                     = inpPa.Results.sigma;
            obj.source                    = inpPa.Results.source;
            obj.unit                      = inpPa.Results.unit;
            obj.desc                      = inpPa.Results.desc;
            obj.use_nominal               = inpPa.Results.use_nominal;
            obj.force_value_in_interval   = inpPa.Results.force_value_in_interval;
            
        end
        
        function val = value(obj)
            if obj.use_nominal
                val = obj.nominal;
            else
                val = obj.nominal + obj.differing(1);
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
                    while and(obj.force_value_in_interval, or(val<obj.tolerance(1)), (val>obj.tolerance(2)))
                        val = obj.tolerance(1) + (obj.tolerance(2)-obj.tolerance(1)).*rand(N,1);
                    end
                elseif strcmpi(obj.distribution,'norm')
                    val = (obj.tolerance(1) + obj.tolerance(2))/2 + obj.sigma*randn(N,1);
                    % Assure that the new value is within the defined
                    % tolerance
                    while and(obj.force_value_in_interval, or(val<obj.tolerance(1)), (val>obj.tolerance(2)))
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
                % fprintf('Executing "%s" on part %s\n', cmd, links(ii).part.description);
                try
                    eval(cmd);
                catch
                    warning('ERROR Executing "%s" on part %s\n', cmd, links(ii).part.description);
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
    end
end

