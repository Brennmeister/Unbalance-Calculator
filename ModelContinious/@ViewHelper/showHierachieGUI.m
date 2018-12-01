function outStr = showHierachieGUI(obj, varargin)
%% Print a table showing the hirarchie
% showHierarchie(model, indentLevel)

outStr='';
indentLevel = 0;
if nargin == 1+1
	model = varargin{1};
	%% Print the header
	outStr = sprintf('');
	outStr = sprintf('%s\n % -50s % 30s',outStr, 'Assembly/Part Description', 'Position');
	outStr = sprintf('%s\n % 50s % 9s % 9s % 9s',outStr, '', 'x/mm', 'y/mm', 'z/mm');
	
	appendStr = obj.showHierarchie(model, indentLevel+1);
	outStr = sprintf('%s%s',outStr, appendStr);
elseif nargin == 2+1
	%% Calculate and print entry Line
	model = varargin{1};
	indentLevel = varargin{2};
	outStr='';
	
	if iscell(model)
		model = model{1};
	end
	
	if ~isa(model,'Part')
		outStr =sprintf('%s\n % *s%s',outStr, 2*indentLevel, '', model.description);
		for c=model.child
			appendStr = obj.showHierarchie(c, indentLevel+1);
			outStr = sprintf('%s%s',outStr, appendStr);
		end
	else
		p = model.getGlobalPosition();
		posx = p(1);
		posy = p(2);
		posz = p(3);
		
		outStr =sprintf('%s\n % *s% -*s % 9.2f % 9.2f % 9.2f',outStr, 2*indentLevel, '', 50-2*indentLevel, model.description, ...
		posx*1e3, posy*1e3, posz*1e3);
	end
end
end

