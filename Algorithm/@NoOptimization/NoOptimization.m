classdef NoOptimization < AnyAlgorithm
	%NOOPTIMIZATION Simply adds the given Parts step by step to the
	%assembly
	%   Detailed explanation goes here
	
	properties
	end
	
	methods
		function obj = NoOptimization()
			obj.maxIterations = 0;
			obj.description = 'Algorithm doing no optimization. Parts are mounted one by another.';
		end
		function setPartsToMount(obj, part)
			obj.part = part;
		end
		function setMountingPlaces(obj, asmbly)
			obj.asmbly = asmbly;
		end
		function setObjectiveFunction(obj, funHandle)
			obj.objectiveFunc = funHandle;
		end
        function setParentAssembly(obj, parentAsmbly)
           obj.parentAssembly = parentAsmbly; 
        end
		function resOut = optimize(obj)
			%% Create Iterations			
			lenP = length(obj.part);
			lenA = length(obj.asmbly);
			minLenAP = min([lenP, lenA]);
			% Create Iterations for lenP=1
			if lenP==1
				iterIndexAsbmbly	= [1:lenA];
				iterIndexPart		= [1];
			elseif lenP>=lenA
				iterIndexAsbmbly	= [1:lenA];
				iterIndexPart		= [1:lenA];
			elseif lenA>lenP
				iterIndexAsbmbly	= [1:lenP];
				iterIndexPart		= [1:lenP];
			end
			iterAsmbly	= obj.asmbly(iterIndexAsbmbly);
			iterPart	= obj.part(iterIndexPart);
			
			result = cell(max([size(iterIndexPart,1), size(iterIndexPart,1)]),1);		% result stores the optimization results
			%% Loop over Assemblys and Parts
			for iiA = 1:size(iterAsmbly,1)
				for iiP = 1:size(iterPart,1);
					for jj = 1:minLenAP
						iterPart{iiP,jj}.setParent(iterAsmbly{iiA,jj});
					end
					% calculate Results
					resStep = obj.objectiveFunc();
					result{iiA*iiP} = resStep{1};
					% Revert Mounting Process
					for jj = 1:minLenAP
						iterPart{iiP,jj}.unsetParent();
					end
				end
			end
			resOut.objectiveValue = result;
			resOut.partSequence = iterPart;
			resOut.asmblySequence = iterAsmbly';

		end
	end
	
end

