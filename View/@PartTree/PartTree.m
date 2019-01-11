classdef PartTree < handle
	%PartTree displays a collapseble Tree of the part/assembly structure
	%   Detailed explanation goes here
	
	properties
		h  % stores the handles
		iconDir
		iconMain
		iconLeaf
   		asbly % The assembly which is shown 
    end
	
	methods
		function obj = PartTree(varargin)
			inParser = inputParser();
			inParser.addParameter('assembly',    [], @ishandle); % The Assembly to show
			inParser.addParameter('parent',      [], @ishandle); % Handle to the parent element (eg figure window)
			inParser.parse(varargin{:})
			
			inP = inParser.Results;
			if isempty(inP.parent)
				% if there is no parent window: create on
				obj.h.parent = figure('visible','off', 'Position', [143,125,411,824], 'name',  'Bauteil-Hirachie', 'MenuBar', 'none');
			else
				% Use the given parent window
				obj.h.parent=inP.parent;
			end
			
			obj.iconDir =  sprintf('%s\\..\\..\\gfx\\icon\\', fileparts(which(mfilename))); % Specify dir with icons
			oldDir = pwd;
			cd(obj.iconDir);
			obj.iconDir =pwd;
			cd(oldDir);
			obj.iconMain = sprintf('%s\\cubes.png', obj.iconDir);
			obj.iconLeaf = sprintf('%s\\cube.png', obj.iconDir);
			
			obj.buildGUI();
			obj.showGUI();
            
		end
		
		%% Set the Assembly to the given one and update the View
		function obj = setAssembly(obj,asbly)
			obj.asbly = asbly;
			obj.updateView();
		end
		
		
		function obj= buildGUI(obj)
			%%
			obj.h.mainBox         = uix.VBox('parent', obj.h.parent);
			
			[obj.h.uiTree, obj.h.uiTreeCont] = uitree('v0','Parent',obj.h.mainBox); % Parent is ignored
			set(obj.h.uiTreeCont, 'Parent', obj.h.mainBox);  % fix the uitree Parent
			
			obj.h.mainDetailBox    = uix.VBox('parent', obj.h.mainBox);
			
			set(obj.h.mainBox,'Heights',[-1,200]);
			
			%% Detail-Panel gestalten
			obj.h.detail.table = uitable('parent', obj.h.mainDetailBox);
			
			obj.h.detail.copyLinkToWorkspace = uicontrol('parent', obj.h.mainDetailBox, ...
				'Style', 'Pushbutton', ...
				'String', 'Copy Part to Workspace as Variable p',...
				'Callback',@obj.copySelectedNodeToWorkspace);
			
			set(obj.h.mainDetailBox,'Heights',[-1,50]);
			
			%% Add actions
			
		end
		
		
		function node = updateView(obj, varargin)
			inParser = inputParser();
			inParser.addParameter('parentNode',      [], @ishandle); % Handle to the parent Node
			inParser.addParameter('element',     []); % Next element (Assembly or Part) to add
			inParser.addParameter('userData', []); % The user Data which will be stored in the Node. It will be a part or assembly-Object
			inParser.parse(varargin{:})
			
			inP = inParser.Results;
			%% Loop through the assemblies and create hirachie
			if isempty(inP.element)
				inP.element     = obj.asbly; % Set the assembly as root element
				inP.parentNode  = uitreenode('v0',inP.element.description,inP.element.description,obj.iconMain,false);
				inP.userData = obj.asbly;
				isRootNode = true;
			else
				isRootNode = false;
            end
			if isprop(inP.element,'child')
				% There could be children
				if ~isempty(inP.element.child)
					node = uitreenode('v0',inP.element.description,inP.element.description,obj.iconMain,false);
					% Loop through the children and add a node for them
					for ii = 1:length(inP.element.child)
						node.add(obj.updateView(...
							'parentNode',inP.parentNode, ...
							'element', inP.element.child{ii}, ...
							'userData', inP.element.child{ii})); % Add the children
					end
				else
					% There is the 'child' property, but no children added
					% At least there should be a node showing the empty
					% assembly
					node = uitreenode('v0',inP.element.description,inP.element.description,obj.iconMain,true);
				end
			else
				% The element seems to be a part
				node = uitreenode('v0',inP.element.description,inP.element.description,obj.iconLeaf,true);
			end
			% Set the user Object, which is the part or assembly
			set(node,'UserData',inP.userData);
			%% Set the root node
			if isRootNode
				% Set nodes
				obj.h.uiTree.setRoot(node);
				% Expand to the first level
				obj.h.uiTree.expand(node);
				% Set callback
				set(obj.h.uiTree, 'NodeSelectedCallback', @obj.nodeSelected);
			end
		end
		
		function obj = nodeSelected(obj, varargin)
			% Get the selected nodes n(1)...n(x)
			n=obj.h.uiTree.getSelectedNodes;
			if isempty(n)
				n=obj.h.uiTree.getRoot;
			end
			p = get(n(1),'UserData');
			if ~isempty(p)
				%% Calculate Detail-Values
				if isa(p,'Assembly')
					u = p.getUAll(0,1);
				elseif isa(p,'Part')
					u=p.getUGlobal(0,1);
				end
				ustat = u(1:3)+u(4:6);
				[uPhase, uAmpl] = cart2pol(ustat(2), ustat(3));
				
				if isprop(p, 'primitive')
					strPrimitive =  p.primitive.primitiveType;
				elseif isa(p,'Assembly')
					strPrimitive = 'Assembly';
				end
				
				%% Set Values in Detail-Panel-Table
				
				rowNames = {...
					'Bezeichnung', ...
					'Position (global)',...
					'Unwucht (global)',...
					'Unwuchtamplitude',...
					'Unwuchtphase',...
					'Masse',...
					'Geometrie-Primitiv'};
				rowData = {...
					p.description;...
					sprintf('x=%3.1f mm y=%3.1f mm z=%3.1f mm', p.getGlobalPosition*1e3);...
					sprintf('Uy=%3.1f mm Uz=%3.1f mm', ustat(2)*1e6, ustat(3)*1e6);...
					sprintf('%3.3f gmm', uAmpl*1e6);...
					sprintf('%3.1f DEG', uPhase/pi*180);...
					sprintf('%4.1f g ', p.mass*1e3);...
					strPrimitive};
				
				set(obj.h.detail.table, ...
					'RowName', rowNames, ...
					'Data', rowData, ...
					'ColumnName', [],...
					'ColumnWidth',{200});
			end
		end
		function obj=copySelectedNodeToWorkspace(obj, varargin)
			% Get the selected nodes n(1)...n(x)
			n=obj.h.uiTree.getSelectedNodes;
			p = get(n(1),'UserData');
			% Assign Variable to Workspace
			assignin('base','p',p)
		end
		function showGUI(obj)
			set(obj.h.parent,'Visible','on');
		end
		function hideGUI(obj)
			set(obj.h.parent,'Visible','off');
		end
	end
	
end

