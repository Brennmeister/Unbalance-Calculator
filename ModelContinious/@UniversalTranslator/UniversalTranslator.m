classdef UniversalTranslator
	%UniversalTranslator Helps to modify DB-Entity-Entries according to
	%Assemblies and Parts
	%   Detailed explanation goes here
	
	% TODO: Fix loading of entity Names!
	properties
		
	end
	
	methods
		function obj = UniversalTranslator()
			
		end
		
		function [av, eName] = assemblyToAVCell(obj, p)
			%% assemblyToAVCell Transforms a given Assembly recursively to an Attribute-Value-Cell (1x2*N), which can be stored in the DB as an Entity
			% Usage: av = assemblyToAVCell(myAssembly)
			%        Storing in DB: @DBController.createEntity('myName', av);
			
			%% Check if Input is really an Assembly
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
				'tag',          'tag';...
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
						% childData = 'I am a Part. Store me separatly';
						childData = obj.partToAVCell(p.child{ii});
					end
					av{end}{ii}=childData;
					clear childData;
				end
			end
		end
		
		function p = avToAssembly(obj, av)
			%% avSToAssembly Transforms a given entity to an assembly
			% Usage: p = avSToAssembly(@DBController.loadEntityAsAVCell('testassembly_1KXL4A40CT'))
			%% Create a struct out of the attribute-value cell for
			% faster searching
			avStruct = obj.avCellToStruct(av);
			%% Check if the given av-List has an attribute typeID
			if ~isfield(avStruct,'typeID')
				error('No field ''typeID'' specified. But this field is required for correct Object creation.');
			end
			
			if ~strcmp(avStruct.typeID,'assembly')
				% It's a part. Handle it differently
				p = obj.avToPart(av);
			else
				% It's an assembly.
				
				%% Define the Mapping-List: avList = {attribute, partProperty);
				avList={...
					'description',	'description';...
					'origin',		'origin';...
					'orientation',	'orientation';...
					%                    'typeID',		'typeID';... % An Assembly always has the type_ID='assembly'. It may not be changed.
					'tag',          'tag';...
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
							% This solution does not set the
							% child-parent-link!
							% p.child{ii}=obj.avToAssembly(avStruct.child{ii});
							
							% Create childs and set child-parent-links
							c = obj.avToAssembly(avStruct.child{ii});
							c.setParent(p);
						end
					end
				end
			end
		end
		
		function av = avStructToCell(obj, avStruct)
			%% Converts a 2D Attribute-Value Struct to a 1D-Cell
			av={};
			fn = fieldnames(avStruct);
			for ii=1:size(fn)
				av{end+1} = fn{ii};
				av{end+1} = avStruct.(fn{ii});
			end
		end
		
		function avStruct = avCellToStruct(obj, av)
			%% Converts a 1D-Cell of Attributes-Values to a 2D Attribute-Value Struct
			avStruct=struct();
			if mod(size(av,2),2)==1
				error('The size of av must be even!');
			end
			for ii=0:size(av,2)/2-1
				avStruct.(av{ii*2+1}) = av{ii*2+2};
			end
		end
		
		function [av, eName] = partToAVCell(obj, p)
			%% partToAVCell Transforms a given Part to an Attribute-Value-Cell (1x2*N), which can be stored in the DB as an Entity
			% Usage: av = partToAVCell(myPart), @DBController.createEntity('myName', av);
			
			%% Check if Input is an Part
			if ~isa(p,'Part')
				error('Given Object is not of class ''Part''.');
			end
			
			%% Define which Properties should be stored if they exist. A
			% check for existance is done later
			
			% avList = {attribute, partProperty);
			avList={...
				'description',	'description';...
				'mass',			'mass';...
				'primitive',	'primitive';...
				'typeID',		'typeID';...
				'initialU',		'initialU';...
				'j',			'j';...
				'tag',          'tag';...
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
		end
		
		function p = avToPart(obj, av)
			%% entityToPart Transforms a given entity to a Part
			% Usage: p = entityToPart(@DBController.loadEntityAsAVCell('testdisc_1KXL4A40CT'))
			%% Create a struct out of the attribute-value cell for
			% faster searching
			avStruct = obj.avCellToStruct(av);
			% Define the Mapping-List: avList = {attribute, partProperty);
			avList={...
				'description',						'description';...
				'mass',								'mass';...
				'primitive',						'primitive';...
				'typeID',							'typeID';...
				'initialU',							'initialU';...
				'j',								'j';...
				'entityName',						'entityName';...
				'tag',								'tag';...
				};
			% Create a new Part
			p=Part('New Part');
			% Check for existance of Attribute and assign it to the Part
			for ii=1:size(avList,1)
				if isprop(p,avList{ii,2}) && isfield(avStruct,avList{ii,1})
					p.(avList{ii,2}) = avStruct.(avList{ii,1});
				end
			end
			
			%% Calculate the initual Unbalance and appl it, if appropriate
			initialU = p.initialU;
			initialUMeasured = obj.calcInitialUByMeasuredValues(avStruct);
			% Logic for applying the Measured Value or not:
			% initialU == initialUMeasured									-> everything is fine, use initialU
			% initialU != initialUMeasured	&& ...
			%	initialU == [0 0 0] && initialUMeasured == [  ]				-> Use initial U
			%	initialU != [0 0 0] && initialUMeasured == [  ]				-> Use initial U
			%	initialU != [0 0 0] && initialUMeasured != [  ]				-> Error				* Needs to be considered!
			%	initialU == [0 0 0] && initialUMeasured != [  ]				-> Use MeasuredValue	* Needs to be considered!
			if ~isempty(initialUMeasured) && ~isequal(initialU, initialUMeasured)
				if ~isequal(initialU, [0 0 0]) && ~isempty(initialUMeasured)
					error('The initial Unbalance (initialU) of the specified attribute-value-List does not match the measured one.');
				elseif isequal(initialU, [ 0 0 0 ]) && ~isempty(initialUMeasured)
					p.initialU = initialUMeasured;
				end
			end
			%% Calculate the measured Mass and apply it, if appropriate
			mass = p.mass;
			massMeasured = obj.calcMassByMeasuredValues(avStruct);
			if mass ~= massMeasured
				if mass ~= 0 && ~isempty(massMeasured)
					error('The mass of the specified attribute-value-List does not match the measured one.');
				elseif (mass == 0 || isempty(mass)) && ~isempty(massMeasured)
					p.mass = massMeasured;
				end
			end
		end
		
		function siAmp = parseAmplitude(obj, amp, ampU)
			%% Calculates the amplitude in si units
			% Determine the required scale Factor
			switch ampU
				case 'gmm'
					sF = 1e-6;
				case 'kgm'
					sF = 1;
				otherwise
					error('No supported Units for the unbalance amplitude specified. Supported: gmm, kgm');
			end
			siAmp = amp*sF;
		end
		function siPhase = parsePhase(obj, p, pU)
			%% Calculates the phase in si units (radians)
			% Determine the required scale Factor
			switch pU
				case 'DEG'
					sF = pi/180;
				case 'RAD'
					sF = 1;
				otherwise
					error('No supported Units for the unbalance amplitude specified. Supported: DEG, RAD');
			end
			siPhase = p*sF;
		end
		function siU = parseAmpPhase3(obj, amp, ampU, p, pU)
			%% Calculates the unbalance vector (3 components)
			% x,y,z but x = 0 due to coordinate-setup
			siAmp = obj.parseAmplitude(amp,ampU);
			siPhase = obj.parsePhase(p,pU);
			siU=siAmp*[0 sin(siPhase) cos(siPhase)];
		end
		function siMass = parseMass(obj, m, mU)
			%% Calculates the mass in si units (kg)
			% Determine the required scale Factor
			switch pU
				case 'g'
					sF = 1e-3;
				case 'kg'
					sF = 1;
				otherwise
					error('Not supported units selected. Supported: g, kg');
			end
			siMass = m*sF;
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
				% Check if Phase is correct
				if ~isfield(av,'unbalanceMeasuredPhaseUnits')
					error('No units for the unbalance Phase of entity %s stored.', eName);
				end
				
				initialU= obj.parseAmpPhase3(av.unbalanceMeasuredAmplitude,...
					av.unbalanceMeasuredAmplitudeUnits,...
					av.unbalanceMeasuredPhase,...
					av.unbalanceMeasuredPhaseUnits);
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
				mass = obj.siMass(av.massMeasured, av.massMeasuredUnits);;
			end
		end
	end
	
end

