classdef AnyAlgorithm < handle
	%ANYALGORITHM is defines the way all algorithms should be used
	%   Defines abstract classes
	
	properties(SetAccess=protected)
		maxIterations
		description
		doMinimizeFunction = true
		
		part
		asmbly
		objectiveFunc
        parentAssembly     % Assembly for which the objectivFunction is calculated.
        showDBGInfo = false
	end
	
	methods (Abstract)
		setPartsToMount(obj, part)
		setMountingPlaces(obj, asmbly)
		setObjectiveFunction(obj, funHandle)
		setParentAssembly(obj, parentAsmbly)
		optimize(obj) 
	end
	
	methods
	end
end

