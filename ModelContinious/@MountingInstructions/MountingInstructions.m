classdef MountingInstructions < handle
	%MOUNTINGINSTRUCTIONS Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		instruction				% Specifying the instructions
		curMountingStep			% Number specifying the current Mounting Step
		
	end
	
	methods
		function obj = MountingInstructions()
			obj.instruction = struct('description', '', ...
				'asmbly',{}, ...
				'requiredPartType', {}, ...
				'numPartsRequired', [], ...
				'numPartsMounted', []);
			obj.curMountingStep = 1;
		end
		
		%% Function to add  a new Mounting Step
		function obj = addMountingStep(obj, description, asmbly, reqPartTypeID, numPartsRequired)
			if ~exist('numPartsRequired', 'var')
				numPartsRequired = length(asmbly);
			end
			% Check that there is no child mounted!
			for ii=1:length(asmbly)
				if ~isempty(asmbly{ii}.child)
					error('Assemblys added to MontingInstructions must have no children');
				end
			end
			obj.instruction(end+1).description = description;
			obj.instruction(end).asmbly = asmbly;
			obj.instruction(end).requiredPartTypeID = reqPartTypeID;
			obj.instruction(end).numPartsRequired = numPartsRequired;
			obj.instruction(end).numPartsMounted = 0;
		end
		%% Function to check if specified Step is finished
		function isSF = isStepFinished(obj, step)
			if step > length(obj.instruction)
				error('This step does not exist. Number of steps in mounting instructions < requested step: %d<%d', length(obj.instruction), step);
			end
			isSF = obj.instruction(step).numPartsMounted >= obj.instruction(step).numPartsRequired;
		end
		%% Function to check if current Step is finished
		function isCSF = isCurrentStepFinished(obj)
			isCSF = isStepFinished(obj, obj.curMountingStep);
		end
		%% Function to check if all Mounting Steps are done
		function isFM = isFullyMounted(obj)
			isFM = obj.curMountingStep > length(obj.instruction);
		end
		%% Function to return all the possible assemblies for the next mouting
		function asmbly = getPossibleNextMountingPlaces(obj)
			asmbly = {};
			for ii=1:length(obj.instruction(obj.curMountingStep).asmbly)
				if isempty(obj.instruction(obj.curMountingStep).asmbly{ii}.child)
					asmbly{end+1} = obj.instruction(obj.curMountingStep).asmbly{ii};
				end
			end
		end
		%% Special case of getPossiblenextMountingPlaces to get simply the next Mounting Place in line
		function asmbly = getNextMountingPlace(obj)
			if ~obj.isCurrentStepFinished
				tmp = obj.getPossibleNextMountingPlaces();
				asmbly = tmp{1};
			else
				error('Current Mounting Step is already finished. No Next Mounting Place can be returned.');
			end
		end
		%% Function to mount a part to a specific assembly
		function mount(obj, part, asmbly)
			% Check if the current Mounting Process is already finished 
			if obj.isCurrentStepFinished
				error('Assembly already fully mounted. No more parts can be added.');
			end
			% Check if assembly is part of the current mounting Step
			isValideAssembly = false;
			for ii=1:length(obj.instruction(obj.curMountingStep).asmbly)
				if obj.instruction(obj.curMountingStep).asmbly{ii} == asmbly
					isValideAssembly=true;
				end
			end
			if ~isValideAssembly
				error('Mounting to the specified Assembly not possible. The Assembly is not part of the current Mounting Step.');
			end
			% Check if part has the needed parttype for the mounting
			if ~strcmp(part.typeID,obj.instruction(obj.curMountingStep).requiredPartTypeID)
				error('PartTypeID does not match requiredPartTypeID. Given Type: %s, Required Type: %s', part.typeID, obj.instruction(obj.curMountingStep).requiredPartTypeID);
			end
			% Check if part is mounted somewhere else
			if ~isempty(part.parent)
				error('Part is already mounted somewhere (has parent).');
			end
			% Check if the assembly already has a child is done in
			% @Part.setParent
			
			% Mount part
			part.setParent(asmbly);
			% Update counter
			obj.instruction(obj.curMountingStep).numPartsMounted=obj.instruction(obj.curMountingStep).numPartsMounted+1;
		end
		%% Function to unmount a part of the current mounting Step
		function unmount(obj, part)
			% Check if part is truly mounted
			if isempty(part.parent)
				error('Part is not mounted (has no parent). So unmounting it does not make any sense!');
			end
			% Check if part is mounted on one of the assemblies in the current mounting Step
			isWithinAssembly = false;
			for ii=1:length(obj.instruction(obj.curMountingStep).asmbly)
				if obj.instruction(obj.curMountingStep).asmbly{ii} == part.parent
					isWithinAssembly=true;
				end
			end
			if ~isWithinAssembly
				error('Unmounting to the specified part is not possible. The Part is mounted on an Assembly outside the current Mounting Step.');
			end

			% Unmount part
			part.unsetParent();
			% Update counter
			obj.instruction(obj.curMountingStep).numPartsMounted=obj.instruction(obj.curMountingStep).numPartsMounted-1;
		end
		
		%% Function to move to the next Mounting Step
		function obj=gotoNextMountingStep(obj)
			if ~obj.isFullyMounted && obj.isCurrentStepFinished
				% There are still free Mounting Places
				obj.curMountingStep = obj.curMountingStep+1;
			else
				error('Mounting is already fully mounted (check with isFullyMounted()) or the current step is not finished yet (check with isCurrentStepFinished())');
			end
		end
	end
	
end

