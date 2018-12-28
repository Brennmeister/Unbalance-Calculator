classdef DimHelper < handle
    %DIMHELPER Helps to organize different dimensions and their tolerances
    %   Detailed explanation goes here
    
    properties
        dims
    end
    
    methods
        function obj = DimHelper()
            %DIMHELPER Construct an instance of this class
        end
        
        function loadDimensionsFromCell(obj, dim_cfg)
            %% LOADMINENSIONSFROMCELL creates and adds Dimensions
            for ii=1:size(dim_cfg, 1)
                obj.addDimension(Dimension(dim_cfg{ii}{:}));
            end
        end
        function addDimension(obj, dim)
            %% ADDDIMENSION adds the given Dimension dim
            % input Parameter:
            %   dim - Object of class @Dimension
            if ~isa(dim,'Dimension')
                error('Only Dimensions of class @Dimension can be added');
            end
            
            obj.dims{end+1} = dim;
        end
        function val = getDimVal(obj, dim_id)
            %GETDIMVAL returns the value of the specified id by dim_id
            dim = obj.getDimension(dim_id);
            val = dim.value;
        end
        
        function dim = getDimension(obj, dim_id)
            %% GETDIMENSION returns a dimenson object for the given dim_id
            if isa(dim_id, 'numeric')
                dim = obj.dims{dim_id};
            elseif isa(dim_id, 'char')
                for ii = 1:length(obj.dims)
                    if isa(obj.dims{ii},'Dimension') && strcmp(obj.dims{ii}.id, dim_id)
                        dim = obj.dims{ii};
                        break;
                    end
                end
            end
        end
        
        function setUseNominalValue(obj, flag, forToleranceIDs)
            if ~exist('forToleranceIDs','var')
                forToleranceIDs=[];
            end
            for ii = 1:length(obj.dims)
                if and(isa(obj.dims{ii},'Dimension'), or(isempty(forToleranceIDs), any(strcmp(forToleranceIDs, obj.dims{ii}.id))))
                    obj.dims{ii}.use_nominal=flag;
                end
            end
        end
        
        function updateLinkedEntities(obj)
            for ii = 1:length(obj.dims)
                if isa(obj.dims{ii},'Dimension')
                    obj.dims{ii}.updateLinkedEntities()
                end
            end
        end
        
        function showLinkStatus(obj)
           for ii=1:length(obj.dims)
               fprintf('dh.dims{%d}.id = %5s   .linked_to: %3.0f entities\n', ii,obj.dims{ii}.id, length(obj.dims{ii}.linked_to))
           end 
        end
    end
end

