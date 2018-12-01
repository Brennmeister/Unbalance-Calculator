classdef AssemblyEntityTranslator
    %AssemblyEntityTranslator Helps to modify DB-Entity-Entries according to
    %Assemblies
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = AssemblyEntityTranslator()
            
        end
        
        function [av, eName] = assemblyToAVCell(obj, p)
            %% assemblyToAVCell Transforms a given Assembly recursively to an Attribute-Value-Cell (1x2*N), which can be stored in the DB as an Entity
            % Usage: av = assemblyToAVCell(myAssembly)
            %        Storing in DB:  @DBController.createEntity('myName', av);
           
            %% Check if Input is an Part
            if ~isa(p,'Assembly')
                error('Given Object is not of class ''Assembly''.');
            end
            
            %% Define which Properties should be stored if they exist. A
            % check for existance is done later
            
            % avList = {attribute, partProperty);
            avList={...
                'description',	'description';...
                'origin',		'origin';...
                'orientation',	'orientation';...
                'typeID',		'typeID';...
                };
            
            % Check for existance and create an 1-D Cell with the
            % Attribute-Value-Pairs
            av={};
            for ii=1:size(avList,1)
                if isprop(p,avList{ii,2}) && ~isempty(p.(avList{ii,2}))
                    av{end+1} = avList{ii,1};
                    av{end+1} = p.(avList{ii,2});
                end
            end
            
            %% Process the EntityName
            if isprop(p,'entityName') && ~isempty(p.('entityName'))
                eName = p.('entityName');
            else
                eName = [];
            end
            
            %% Process the children
            av{end+1}='child';
            av{end+1}=[];
            if ~isempty(p.child)
                av{end}=cell(1,length(p.child));
                for ii=1:length(p.child)
                    try
                        % Try if child is an assembly, it should work
                        childData = obj.assemblyToAVCell(p.child{ii});
                    catch
                        % child seems to be a part
                        childData = 'I am a Part. Store me separatly';
                    end
                    av{end}{ii}=childData;
                    clear childData;
                end
            end
        end
        
        function p = avSToAssembly(obj, av)
            %% avSToAssembly Transforms a given entity to an assembly
            % Usage: p = avSToAssembly(@DBController.loadEntityAsAVCell('testassembly_1KXL4A40CT'))
            %% Create a struct out of the attribute-value cell for
            % faster searching
            avStruct = obj.avCToS(av);
            %% Check if the given av-List has an attribute typeID
            if ~isfield(avStruct,'typeID')
                error('No field ''typeID'' specified. But this field is required for correct Object creation.');
            end
            
            if ~strcmp(avStruct.typeID,'assembly')
                % It's a part. Handle it differently
            else
                % It's an assembly.

                %% Define the Mapping-List: avList = {attribute, partProperty);
                avList={...
                    'description',	'description';...
                    'origin',		'origin';...
                    'orientation',	'orientation';...
                    'typeID',		'typeID';...
                    };
                
                %% Create a new Assembly
                p=Assembly('New Assembly');
                %% Check for existance of Attribute and assign it to the Part
                for ii=1:size(avList,1)
                    if isprop(p,avList{ii,2}) && isfield(avStruct,avList{ii,1})
                        p.(avList{ii,2}) = avStruct.(avList{ii,1});
                    end
                end
                %% Create the children
                if isfield(avStruct,'child')
                    if ~isempty(avStruct.child)
                        for ii = 1:length(avStruct.child) % Loop through all children
                            p.child{ii}=obj.avSToAssembly(avStruct.child{ii});
                        end
                    end
                end
            end
        end
        
        function av = avSToC(obj, avStruct)
            %% Converts a 2D Attribute-Value Struct to a 1D-Cell
            av={};
            fn = fieldnames(avStruct);
            for ii=1:size(fn)
                av{end+1} = fn{ii};
                av{end+1} = avStruct.(fn{ii});
            end
        end
        
        function avStruct = avCToS(obj, av)
            %% Converts a 1D-Cell of Attributes-Values to a 2D Attribute-Value Struct
            avStruct=struct();
            if mod(size(av,2),2)==1
                error('The size of av must be even!');
            end
            for ii=0:size(av,2)/2-1
                avStruct.(av{ii*2+1}) = av{ii*2+2};
            end
        end
    end
    
    
    
    
    
    
    
    methods (Access=private)
        function initialU = calcInitialUByMeasuredValues(obj, av)
            initialU=[]; % Set default Value
            %% Load the unbalance Vector of measured Values
            if isfield(av,'unbalanceMeasuredAmplitude') && isfield(av,'unbalanceMeasuredPhase')
                % Check if Amplitude is correct
                if ~isfield(av,'unbalanceMeasuredAmplitudeUnits')
                    error('No units for the unbalance Amplitude of entity %s stored.', eName);
                end
                
                switch av.unbalanceMeasuredAmplitudeUnits
                    case 'gmm'
                        scaleFactorAmplitude = 1e-6;
                    case 'kgm'
                        scaleFactorAmplitude = 1;
                    otherwise
                        error('No supported Units for the unbalance amplitude specified for entity %s', eName);
                end
                % Check if Phase is correct
                if ~isfield(av,'unbalanceMeasuredPhaseUnits')
                    error('No units for the unbalance Phase of entity %s stored.', eName);
                end
                
                switch av.unbalanceMeasuredPhaseUnits
                    case 'DEG'
                        scaleFactorPhase = pi/180;
                    case 'RAD'
                        scaleFactorPhase = 1;
                    otherwise
                        error('No supported Units for the unbalance amplitude specified for entity %s', eName);
                end
                initialU=av.unbalanceMeasuredAmplitude*scaleFactorAmplitude * [0 sin(av.unbalanceMeasuredPhase*scaleFactorPhase) cos(av.unbalanceMeasuredPhase*scaleFactorPhase)];
            end
        end
        function mass = calcMassByMeasuredValues(obj, av)
            mass=[]; % Set default Value
            %% Load the mass of measured Values
            if isfield(av,'massMeasured')
                % Check if Amplitude is correct
                if ~isfield(av,'massMeasuredUnits')
                    error('No units for the mass of entity %s stored.', eName);
                end
                switch av.massMeasured
                    case 'g'
                        scaleFactor = 1e-3;
                    case 'kg'
                        scaleFactor = 1;
                    otherwise
                        error('No supported Units for the mass specified for entity %s', eName);
                end
                mass = av.massMeasured * scaleFactor;
            end
        end
    end
    
end

