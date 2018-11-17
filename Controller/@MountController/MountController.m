classdef MountController < handle
	%MOUNTCONTROLLER Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		assembly			% Stores the Handle to the topmost @Assembly-Object
		mnti				% Stores the Handle to the @MountingInstructions-Object
		alg					% Stores the Handle to the used Algorithm in a cell-struct. The element of the cell needs to fit to the mounting-step
        showDBGInfo = true
	end
	
	methods
		function obj = MountController()
			
		end
		% Map the Controller-Function Calls to the Model-Function Calls
		% Additional Functions (e.g. Calling the GUI) could be added here.
		function isSF = isStepFinished(obj, step)
			isSF = obj.mnti.isStepFinished(step);
		end
		function isCSF = isCurrentStepFinished(obj)
			isCSF = obj.mnti.isCurrentStepFinished();
		end
		function isFM = isFullyMounted(obj)
			isFM = obj.mnti.isFullyMounted();
		end
		function asmbly = getPossibleNextMountingPlaces(obj)
			asmbly = obj.mnti.getPossibleNextMountingPlaces();
		end
		function asmbly = getNextMountingPlace(obj)
			asmbly = obj.mnti.getNextMountingPlace();
		end
		function mount(obj, part, asmbly)
			obj.mnti.mount(part, asmbly);
		end
		function unmount(obj, part)
			obj.mnti.unmount(part);
		end
		function obj=gotoNextMountingStep(obj)
			obj.mnti.gotoNextMountingStep();
		end
		%% Add a mounting Step, objective Function and algorithm
		function obj = addMountingStep(obj, varargin)
			inpPa = inputParser;
			
			inpPa.addRequired('description',		@isstr);
			inpPa.addRequired('asmbly');
			inpPa.addRequired('reqPartTypeID',		@isstr);
			inpPa.addRequired('numPartsRequired',	@isnumeric);
			inpPa.addParameter('algorithm',			NoOptimization(),		@(o)isa(o,'AnyAlgorithm'));
			inpPa.addParameter('objectiveFunction', @(varargin){-1});
			
			inpPa.parse(varargin{:})
			
			% Add Step to the Mounting Instructions Object
			obj.mnti.addMountingStep(...
				inpPa.Results.description, ...
				inpPa.Results.asmbly, ...
				inpPa.Results.reqPartTypeID, ...
				inpPa.Results.numPartsRequired);
			
			% Add the algorithm for the currently added Mounting Step
			obj.alg{length(obj.mnti.instruction)} = inpPa.Results.algorithm;
			% Add the objective Function for the currently added Mounting Step
			obj.alg{length(obj.mnti.instruction)}.setObjectiveFunction(inpPa.Results.objectiveFunction);
		end
		%% Finds the optimum mounting solution for the current Mounting Step
		% INPUT:
		%	part
		%	Cell Array with the Parts which should be mounted
		%
		function resultAlg = findOptimumMountingSolution(obj, part)
			alg = obj.alg{obj.mnti.curMountingStep};
			alg.setPartsToMount(part);
			alg.setMountingPlaces(obj.getPossibleNextMountingPlaces);
			if obj.showDBGInfo 
            fprintf('Optimization started... '); tic;
            end
			resultAlg = alg.optimize();
			if obj.showDBGInfo 
            fprintf('done. Time needed: %3.3f s\n', toc);
            end
		end
		%% Mounts according to the optimal Solution
		% INPUT:
		%	none needed
		function autoMount(obj, part)
			% First, use the algorithm to find good solutions
			resultAlg = obj.findOptimumMountingSolution(part);
			% Then select the best solution (mini = index of the best
			% solution)
			[minv mini] = min([resultAlg.objectiveValue{:}]);
			% Mount the parts to to best places
			if size(resultAlg.partSequence,1)>size(resultAlg.asmblySequence,1)
				% There were more parts than assemblies. Mount according to
				% the parts
				for ii=1:length({resultAlg.partSequence{mini,:}})
					obj.mount(resultAlg.partSequence{mini,ii}, resultAlg.asmblySequence{1,ii});
				end
			else
				% There were more possible mounting places (=assemblies)
				% than parts. Mount according to the assemblies
				for ii=1:length({resultAlg.asmblySequence{mini,:}})
					obj.mount(resultAlg.partSequence{1,ii}, resultAlg.asmblySequence{mini,ii});
				end
			end
		end
	end
	
end

