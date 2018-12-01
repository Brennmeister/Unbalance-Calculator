
classdef SelmaController < handle
	%SELMACONTROLLER Main Controller for Selma
	%   Detailed explanation goes here
	
	properties
		dbc					% The Database Controller
		mntc				% The Mounting Controller
		mainPart			% The topmost Part (i.e. the Rotor)
		skeleton			% Stores the skeleton parts
		taMesswertWaage		% @TriggerAction Object for the current TriggerAction TODO: Solve differently 
        description
	end
	
	methods
		function obj = SelmaController()
			
		end
		%% Function which is called if new mass was measured
		function varargout = notifyNewValueWaage(obj, src, event, data)
			fprintf('Selma Controller got new Value of the Scale: %4.4f\n', data);
			% Call Function to create new Part
			% varargout = {obj.createNewPart('parttype','magnet','measuredMass',data*1e-3)};
			% What to do with the output? It needs to be passed along!
			if ~isempty(obj.taMesswertWaage)
                if ~isempty(obj.taMesswertWaage{obj.mntc.mnti.curMountingStep})
                    if iscell(obj.taMesswertWaage{obj.mntc.mnti.curMountingStep})
                        partNum = obj.mntc.mnti.instruction(obj.mntc.mnti.curMountingStep).numPartsMounted+1;
                        obj.taMesswertWaage{obj.mntc.mnti.curMountingStep}{partNum}.inAction(data*1e-3);
                    else
                        obj.taMesswertWaage{obj.mntc.mnti.curMountingStep}.inAction(data*1e-3);
                    end
                end
			end
		end
		%% Function to create a new Part
		function varargout = createNewPart(obj, varargin)
			inpPa = inputParser;
			
			inpPa.addParameter('parttype',		@isstr);
			inpPa.addParameter('measuredMass',	@isnumeric);
			
			inpPa.parse(varargin{:})
			
			switch inpPa.Results.parttype
				case 'magnet'
					p = Part('Magnet');
					p.setPrimitive('cuboid', ...
						'mass',inpPa.Results.measuredMass, ...
						'length', 30e-3, ...
						'width',  18e-3, ...
						'height', 5e-3);
					varargout{1} = p;
			end
		end
	end
	
end

