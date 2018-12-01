function outStr = showPartTable(obj, varargin)
%% Print a table showing the hirachy and the unbalance
% showPartTable(model, planeA, planeB, indentLevel)

outStr='';
indentLevel = 0;
if nargin == 3+1
	model = varargin{1};
	planeA=varargin{2};
	planeB=varargin{3};
	%% Print the header
	outStr = sprintf('%sPlane for Unbalance calculation planeA: %3.3f mm   planeB: %3.3f mm (in global Coordinates)', outStr, planeA, planeB);
	outStr = sprintf('%s\n % -50s % 30s % 38s',outStr, 'Assembly/Part Description', 'Position', 'Unbalance');
	outStr = sprintf('%s\n % 50s % 9s % 9s % 9s % 9s % 9s % 9s % 9s',outStr, '', 'x/mm', 'y/mm', 'z/mm', '|U_A|/gmm', 'ang(U_A)', '|U_B|/gmm', 'ang(U_B)');
	
	appendStr = obj.showPartTable(model, planeA, planeB, indentLevel+1);
	outStr = sprintf('%s%s',outStr, appendStr);
	%% Print Summary
	outStr = sprintf('%s\n\n-- SUMMARY ---------------------------------------------------------------------------------------------------------------\n',outStr);
	u=model.getUAll(planeA, planeB);
	outStr = sprintf('%sUnbalance of topmost Parent (%s) in planeA @%5.1f mm: %6.3f gmm @ %6.1f DEG\n',outStr, model.description, planeA*1e3, norm(u(1:3))*1e6, cart2pol(u(2), u(3))/pi*180);
	outStr = sprintf('%sUnbalance of topmost Parent (%s) in planeB @%5.1f mm: %6.3f gmm @ %6.1f DEG\n',outStr, model.description, planeB*1e3, norm(u(4:6))*1e6, cart2pol(u(5), u(6))/pi*180);
	outStr = sprintf('%s--------------------------------------------------------------------------------------------------------------------------\n',outStr);
elseif nargin == 4+1
	%% Calculate and print entry Line
	model = varargin{1};
	planeA=varargin{2};
	planeB=varargin{3};
	indentLevel = varargin{4};
	outStr='';
	
	if iscell(model)
		model = model{1};
	end
	
	if ~isa(model,'Part')
		p = model.getGlobalPosition();
		posx = p(1);
		posy = p(2);
		posz = p(3);
		outStr =sprintf('%s\n % *s% -*s % 9.2f % 9.2f % 9.2f % 9s % 10s % 9s % 10s',outStr, 2*indentLevel, '', 50-2*indentLevel, model.description, ...
		posx*1e3, posy*1e3, posz*1e3,...
		'', '',...
		'', '');		
		% Print without empty Assemblys:
		% outStr =sprintf('%s\n % *s%s',outStr, 2*indentLevel, '', model.description);
		
		for c=model.child
			appendStr = obj.showPartTable(c, planeA, planeB, indentLevel+1);
			outStr = sprintf('%s%s',outStr, appendStr);
		end
	else
		p = model.getGlobalPosition();
		posx = p(1);
		posy = p(2);
		posz = p(3);
		u=model.getUGlobal(planeA, planeB);
		norm_ua = norm(u(1,1:3));
		norm_ub = norm(u(1,4:6));
		ang_ua = cart2pol(u(1,2),u(1,3))/pi*180;
		ang_ub = cart2pol(u(1,5),u(1,6))/pi*180;
		
		outStr =sprintf('%s\n % *s% -*s % 9.2f % 9.2f % 9.2f % 9.2f % 5.0f DEG % 9.2f % 5.0f DEG',outStr, 2*indentLevel, '', 50-2*indentLevel, model.description, ...
		posx*1e3, posy*1e3, posz*1e3,...
		norm_ua*1e6, ang_ua,...
		norm_ub*1e6, ang_ub);
	end
end
end

