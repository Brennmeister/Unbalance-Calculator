function outStr = showHierarchie(obj, varargin)
%% Print a table showing the hirarchie
% showHierarchie(model, indentLevel)

outStr='';
indentLevel = 0;
if nargin == 1+1
	model = varargin{1};
	%% Print the header
	outStr = sprintf('');
	outStr = sprintf('%s\n % -70s % 30s',outStr, 'Assembly/Part Description', 'Position');
	outStr = sprintf('%s\n % 70s % 9s % 9s % 9s',outStr, '', 'x/mm', 'y/mm', 'z/mm');
	
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
		
        strDesc = sprintf(model.description);
        if strcmp(model.primitive.primitiveType,'cylinder')
            strDesc = sprintf('%s (cyl L%3.1fmm, D%3.1fmm)', strDesc, model.primitive.length*1e3, model.primitive.diameter*1e3);
        elseif strcmp(model.primitive.primitiveType,'cuboid')
            strDesc = sprintf('%s (cub L%3.1fmm, H%3.1fmm, W%3.1fmm)', strDesc, model.primitive.length*1e3, model.primitive.height*1e3, model.primitive.width);
        end
		outStr =sprintf('%s\n % *s% -*s % 9.2f % 9.2f % 9.2f',outStr, 2*indentLevel, '', 70-2*indentLevel, strDesc, ...
		posx*1e3, posy*1e3, posz*1e3);
	end
end
end

