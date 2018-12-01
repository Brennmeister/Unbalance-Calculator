classdef Assembly < handle
	properties
		child		= {}			% Links to the child element. Only ONE Part-Child allowd. Multiply Assembly-Childs allowd.
		parent      = {}            % Links to the parent element
		description = 'Assembly'    % Dscription for the Assembly
		origin		= [0 0 0]		% [m] Ursprung. Muss immer [0 0 0] sein.
		orientation	= [1 0 0 0]	% [-] Orientierung des Teils. Muss immer [1 0 0 0] sein.  1:3=> Normalenvektor 4: Drehung um diese Achse in rad
		showPlot	= true			% BOOL, defines if the plot should be showed if obj.plot is issued
		entityName					% Name of the Part in the Databas - if loaded from there or if inserted in DB
	end
	properties (SetAccess=private, GetAccess=public)
		typeID		= 'assembly'	% Specifies the type of the Object
	end
	methods
		%% Create Object and set given description
		function obj = Assembly(description)
			obj.description = description;
		end
		%% Get the Position in global coords of the Child
		function pos = getChildsPosition(obj)
			if (length(obj.child)>1)
				error('Function getChildsPosition only works for parent:child = 1:n with n=1. n>1 currently unsupported');
			else
				pos = obj.origin + obj.child.getChildsPosition()*obj.getRotM();
				% Alternative ways which do not work correctly
				%pos = obj.origin + obj.child.getChildsPosition()*obj.getRotM(obj.child.orientation);
				%pos = obj.origin + obj.child.getChildsPosition()*obj.getRotM(obj.child.orientation)';
				%pos = obj.origin + obj.child.getChildsPosition()*obj.getGlobalRotm;
			end
			
		end
		%% Get global rotation Matrix
		function rotm = getGlobalRotm(obj)
			if isempty(obj.parent)
				rotm = obj.getRotM();
			else
				rotm = obj.getRotM()*obj.parent.getGlobalRotm();
			end
		end
		%% Get the rotation matrix for given orientation
		function rotm = getRotM(obj,orientTo)
			if ~exist('orientTo','var')
				orientTo=obj.orientation;
				orientTo(4)=orientTo(4)*-1; % Fix the direction of rotation (Drehsinn) for matlab. So a positive angle rotates counterclockwise ccw. Genie was also patched
			end
			tmOrient = vrrotvec2mat(vrrotvec(orientTo(1:3), obj.orientation(1:3)));
			% Berechnung der notwendigen Rotation um den neuen orientierungsvektor
			tmRot = vrrotvec2mat(orientTo);
			% Verknüpfen der Transformationsmatrizen
			rotm=tmOrient'*tmRot';
		end
		%% Get Position of the Origin in Global Coordinates
		function pos = getGlobalPosition(obj)
			if isempty(obj.parent)
				pos = obj.origin;
			else
				pos = obj.parent.getGlobalPosition() + (obj.parent.getGlobalRotm()*obj.origin')';
			end
		end
		%% Convert given Points in assembly coordinatesystem to global Coords
		% Caution:
		%	The given Points are absolute Positions within the Assembly.
		%	Example:	origin = [ 10 0 0 ]
		%				pLocal = [ 1 0 0 ]
		%				The local Point is [ 1 0 0 ] and NOT [ 10 0 0 ]
		function pGlobal = convertToGlobal(obj, pLocal)
			if isempty(obj.parent)
				pGlobal = pLocal;
			else
				pGlobal = repmat(obj.parent.getGlobalPosition(),size(pLocal,1),1) + (obj.parent.getGlobalRotm()*pLocal')';
			end
		end
		%% Plotting-Function for Debugging-Purposes
		function obj = plot(obj)
			if obj.showPlot
				hold on
				p=obj.getGlobalPosition();
				v=obj.getGlobalRotm();
				l=3e-3;
				vx=v*[1 0 0]'*l;
				vy=v*[0 1 0]'*l;
				vz=v*[0 0 1]'*l;
				
				plot3(     	p(1),		p(2),		p(3),		'Marker', 'o', 	'MarkerFaceColor', [0 0 1],	'Color', [0 0 1]);
				quiver3(	p(1),		p(2),		p(3),		vx(1),	vx(2),	vx(3),			'Color', [1 0 0]);
				text(		p(1)+vx(1),	p(2)+vx(2),	p(3)+vx(3),							'x', 	'Color', [1 0 0]);
				ii=2;
				quiver3(	p(1),		p(2),		p(3),		vy(1),	vy(2),	vy(3),			'Color', [0 1 0]);
				text(		p(1)+vy(1),	p(2)+vy(2),	p(3)+vy(3),							'y', 	'Color', [0 1 0]);
				ii=3;
				quiver3(	p(1),		p(2),		p(3),		vz(1),	vz(2),	vz(3),			'Color', [0 0 1]);
				text(		p(1)+vz(1),	p(2)+vz(2),	p(3)+vz(3),							'z', 	'Color', [0 0 1]);
				
				d=l/4;
				text(p(1)+d, p(2)+d, p(3)+d, obj.description);
			end
		end
		%% Plot Assembly and all sub-assemblies
		function obj = plotAll(obj, showCylinder)
			if ~exist('showCylinder','var')
				showCylinder=false;
			end
			if showCylinder %TODO: Make this adjust to the given Data
				[X,Y,Z] = cylinder(10e-3,20);
				Z=Z*0.4;
				
				hold on;
				h=surf(Z,Y,X); 
% 				rotate(h,[0 1 0],90); 
				set(h,'EdgeAlpha',0.1); 
				set(h,'FaceColor',[1 1 1]*0.8);
				xlabel('x'); ylabel('y'); zlabel('z');
				axis('equal');
			end
			obj.plot();
			for c = obj.child
				if iscell(c)
					if isprop(c{1},'child')
						c{1}.plotAll();
					else
						c{1}.plot();
					end
				else
					c.plot();
				end
			end
			view(90,0);
		end
		
		%% Calculate the unbalance of all (sub)components
		function [u, umat, umatDesc] = getUAll(obj, planeA, planeB)
			umat=[];
			umatDesc={};
			if isprop(obj,'child')
				hasNoChild = true; % Flag to see if there was a child
				% Loop through all childs.
				for c = obj.child
					hasNoChild = false;
					if iscell(c)
						cc=c{1};
					end
					if ~isa(cc,'Part')
						% cc is an assembly
						[~, umatNew , umatDescNew] = cc.getUAll(planeA, planeB);
					else
						% cc is a part
						umatNew=cc.getUGlobal(planeA, planeB);
						umatDescNew = {cc.description};
					end
					% Add calculated Values to the Matrix
					umat=[umat; umatNew];
					% umatDesc = {umatDesc{:} umatDescNew{:}}; % Slow
					umatDesc = [umatDesc umatDescNew];
				end
				% If there was no child, do not calculate the unbalance -->
				% there is no unbalance
				if hasNoChild
					umat = zeros(1,6);
					umatDesc = {'No Child Present --> 0'};
				end
			end
			u =	[	sum(umat(:,1)), sum(umat(:,2)), sum(umat(:,3)) sum(umat(:,4)), sum(umat(:,5)), sum(umat(:,6))	];
		end
		%% Calculate the mass of all sub-components
		function [m] = mass(obj)
			m=0;
			if isprop(obj,'child')
				% Loop through all childs.
				for c = obj.child
					if iscell(c)
						cc=c{1};
					end
					if ~isa(cc,'Part')
						% cc is an assembly
						m=m+cc.mass;
					else
						% cc is a part
						m=m+cc.mass;
					end
				end
			end
		end
		%% Set the parent assembly
		% The parent assembly should only be set, if there is no parent yet
		function setParent(obj, p)
			if ~isempty(obj.parent)
				error('The object already has a parent. The Parent and from that parent the Child must be removed first!')
			else
				obj.parent=p;
				p.child{end+1}=obj;
			end
		end
		%% Unset the Parent Assembly
		% For esier and consistent hirachy building
		function unsetParent(obj)
			if isempty(obj.parent)
				error('The object has no parent. The Parent can not be unset')
			else
				% Search for the obejct to remove and do not add it to the
				% new created child-list
				c = obj.parent.child;
				obj.parent.child={};
				for ii = 1:length(c)
					if c{ii} ~= obj
						obj.parent.child{end+1}=c{ii};
					end
				end
				obj.parent.child;
				obj.parent=[];
			end
		end
		%% Unset all Children
        function obj = unsetChildren(obj)
           for ii=length(obj.child):-1:1
              obj.child{ii}.unsetParent();
           end
        end
        %% Create a Copy with all Properties
		function new = copy(obj)
			%% Make a copy of this object
			% Instantiate new object of the same class.
			new = feval(class(obj), 'copy');
			
			% Copy all non-hidden properties.
			p = properties(obj);
			for i = 1:length(p)
				new.(p{i}) = obj.(p{i});
			end
		end
		
		function propList = getChildPropList(obj, propName)
			%% getChildPropList gets a list of the specified Property for all Children 
			%
			propList={};
			for ii=1:length(obj.child)
				if isprop(obj.child{ii},propName)
					% Get the value of the prop and append it to the list
					propList{end+1} = obj.child{ii}.(propName);
				end
				
				if isprop(obj.child{ii},'child')
					% Call this function recursivly for all other
					% children
					propList=[propList obj.child{ii}.getChildPropList(propName)];
				end
			end
		end
	end
	methods (Access={?Part})
		
	end
end