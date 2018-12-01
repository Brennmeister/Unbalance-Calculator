classdef AlgorithmController < handle
	%@ALGORITHMCONTROLLER Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		funcToNotifyOnResult		% Cell containing Function handles to call if Algorithm has finished
		alg							% Cell containing the algorithm objects
	end
	
	methods
		function obj = AlgorithmController()
		end
	end
	
end

