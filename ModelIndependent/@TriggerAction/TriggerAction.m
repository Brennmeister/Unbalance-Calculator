classdef TriggerAction < handle
	%TRIGGERACTION can call a function if an event happens
	
	properties
		description			% Stores a description
		stack				% Storing the elements
		numAction			% Integer, defining when an action is called
        postTriggerAction={}  % Cell of actions to be executed after autoMount
		funObject
		count = 0
	end
	properties (Access=private)
		% 		count = 0
	end
	
	methods
		function obj = TriggerAction(obj, description)
			if exist('description','var')
				obj.description = description;
            end
		end
		
		function inAction(obj, varargin)
			%inAction is Called of an external function
			if obj.count<obj.numAction
				obj.count = obj.count + 1;
				
				obj.stack{obj.count}.mass = varargin{1};
				obj.stack{obj.count}.update();
				
                % Trigger Action
				if obj.count >= obj.numAction
					obj.funObject.autoMount(obj.stack);
                    
                    % Execte post-trigger functions
                    for ii=1:length(obj.postTriggerAction)
                       obj.postTriggerAction{ii}();
                    end
				end
			else
				error('Trigger was already reached and executed');
			end
		end
		
	end
	
end

