classdef PartPlot < handle
    
    % PartPlot Shows parts as a simple geometry
    
    % parentplot: plots the child Assemblies and parts of an Assembly
    % plot: plots only the part
    % removeparent: removes only the Part
    % removeapart: Removes the Part and the parent Assemblies
    % isNewplot: Checks if a part was already plotted
    
    properties
        figure
        axes
        part = {}
        h = {}
        ks = {}
        bP = {}
        hRotAxis
        arrowColor
        arrowLength
        arrowStemWidth
        arrowTipWidth
        
        balancePlaneSize
        balancePlanePos
        showBalancePlane = true
        unbalanceScaleFactor = 1.5e4;
        
        faceColorCube     = [255, 153, 51]./255
        faceColorCylinder = [160, 160, 160]./255
        faceColorCylinderHole = [255, 255, 255]./255
        faceColorCubeHole     = [255, 255, 255]./255
        rotAxisColor = [1 0.3 0.3];
        balancingplaneColor= [255,255,10]./255;
        
        drawAssemblyKS = true
        drawAxisName = true
        drawDiscUnbalance = false;
        
        showRotAxis = true
        showPartLabel = true
    end
    
    methods
        
        function obj = PartPlot(preSet, ax) % Konstruktor
            disp('Objekt der Klasse PartPlot created');
            obj.arrowColor = {[1, 0, 0; 0, 1, 0; 0, 0, 1], [0.8, 0.6, 0; 0.6, 0.8, 0; 0, 0.6, 0.8] };
            obj.arrowLength = 1e-1;
            obj.arrowStemWidth = obj.arrowLength *1e-2;
            obj.arrowTipWidth = 3*obj.arrowStemWidth;
            if ~exist('ax','var')
                obj.figure = figure;
                obj.axes = axes();
            else
                obj.axes=ax;
                obj.figure = obj.axes.Parent;
                while ~isa(obj.figure,'matlab.ui.Figure')
                    obj.figure=obj.figure.Parent;
                end
            end
            
            hold(obj.axes,'on');
            xlabel('X');
            ylabel('Y');
            zlabel('Z');
            axis(obj.axes,'equal')
            %Values for the size/position of the planes
            obj.balancePlaneSize = 50 ;
            obj.balancePlanePos = [-10e-3 10e-3];
            
            % Load preSets for the appearance
            if exist('preSet','var')
                obj.setPreSet(preSet);
            end
        end
        
        function obj=setPreSet(obj,preSet)
            % Load preSets for the appearance
            switch preSet
                case 'minimal'
                    obj.drawAxisName          = false;
                    obj.drawAssemblyKS        = false;
                    obj.arrowLength           = obj.arrowLength/20;
                    obj.arrowStemWidth        = obj.arrowStemWidth/3;
                    obj.arrowTipWidth         = obj.arrowTipWidth/5;
                    obj.showBalancePlane      = false;
                    obj.showPartLabel         = false;
                case 'noKOS'
                    obj.drawAxisName          = false;
                    obj.drawAssemblyKS        = false;
                    obj.arrowLength           = 0;
                    obj.arrowStemWidth        = 0;
                    obj.arrowTipWidth         = 0;
                    obj.showBalancePlane      = false;
                    obj.showPartLabel         = false;
            end
        end
        function plot(obj, p)
            % activate axes
            axes(obj.axes);
            if isa(p,'Assembly')
                obj.plotAssembly(p);
            elseif isa(p,'Part')
                obj.plotPrim(p);
            end
        end
        
        function plotAssembly(obj,p)
            %obj.ParentPlot(kos): plots all the children of kos, kos though would not be plotted
            
            if isa(p,'Assembly') && ~isempty(p.child)
                
                %draws the kos
                %different colors of the kos: when the child of the
                %is a part it would be drawn with a different colors
                if isa(p.child{1}, 'Assembly') && ~isempty(p.parent) && obj.drawAssemblyKS
                    obj.ks{end+1} = obj.drawKOS(p, 2, obj.arrowLength*0.7);
                elseif isa(p.child{1},'Part') && ~isempty(p.parent)
                    obj.ks{end+1} = obj.drawKOS(p, 1, obj.arrowLength);
                end
                
                
                if ~isempty(p.child) && ~isa(p, 'Part')
                    %recursive calling of the function to repeat the
                    %process for child kos
                    
                    for i=1:length(p.child)
                        obj.plotAssembly(p.child{i});
                    end
                end
                
            elseif isa(p,'Part')
                obj.plotPrim(p);
            end
        end
        
        function plotPrim(obj, p)
            %obj.plot(quader): plots the primitive.
            if obj.isNewPart(p)
                obj.part{end+1} = p;
                if strcmp(p.primitive.primitiveType, 'cuboid')
                    if p.mass > 0
                        %plotting the cuboid
                        obj.h{end+1} = obj.drawCube(p.getGlobalPosition, [p.primitive.length, p.primitive.width, p.primitive.height], p.getGlobalRotm, p.description);
                    else
                        % Plotte in anderer Farbe und länge leicht größer
                        % --> keine Anzeige-Artefakte
                        obj.h{end+1} = obj.drawCube(p.getGlobalPosition, [p.primitive.length*1.0001, p.primitive.width*1.0001, p.primitive.height*1.0001], p.getGlobalRotm, p.description);
                        % Plotte in anderer Farbe
                        for nH = 1:length(obj.h{end})
                            if strcmp(get(obj.h{end}(nH),'Type'), 'surface') || strcmp(get(obj.h{end}(nH),'Type'), 'patch')
                                set(obj.h{end}(nH), 'FaceColor', obj.faceColorCubeHole);
                                set(obj.h{end}(nH), 'FaceAlpha', 0.8);
                            end
                        end
                    end
                elseif strcmp(p.primitive.primitiveType, 'cylinder')
                    %plotting the cylinder
                    if p.mass > 0
                        obj.h{end+1}= obj.drawCylinder(p.getGlobalPosition, [p.primitive.diameter/2, p.primitive.length],  p.getGlobalRotm, p.description);
                    else
                        % Plotte in anderer Farbe und länge leicht größer
                        % --> keine Anzeige-Artefakte
                        obj.h{end+1}= obj.drawCylinder(p.getGlobalPosition, [p.primitive.diameter/2, p.primitive.length*1.0001],  p.getGlobalRotm, p.description);
                        
                        for nH = 1:length(obj.h{end})
                            if strcmp(get(obj.h{end}{nH},'Type'), 'surface') || strcmp(get(obj.h{end}{nH},'Type'), 'patch')
                                %                             if isa(obj.h{end}{nH},'Surface')
                                set(obj.h{end}{nH}, 'FaceColor', obj.faceColorCylinderHole);
                                set(obj.h{end}{nH}, 'FaceAlpha', 0.8);
                            end
                        end
                    end

                    %checking if drawing the planes and the axis is needed
                    if obj.showBalancePlane
                        obj.bP{end+1}=obj.drawBalancePlane(obj.balancePlanePos,obj.balancePlaneSize);
                    end
                    if  obj.showRotAxis
                        obj.drawRotAxis();
                    end
                    %% Test zum Plotten der Scheibenunwucht+Exzentrischen Sitze auf Welle
                    if obj.drawDiscUnbalance
                        
                        uIni = p.initialU * p.getGlobalRotm';
                        o = p.getGlobalPosition();
                        sF = obj.unbalanceScaleFactor;
                        % Initialunwucht
                        if norm(uIni)>0
                            h.uIni = coolArrow(o, o + uIni*sF, 'color', [255,87,27]./255);
                        end
                        if exist('h','var')
                            obj.h{end}{end+1}=h;
                        end
                    end
                elseif strcmp(p.primitive.primitiveType, 'pointmass')
                    pos=p.getGlobalPosition();
                    obj.h{end+1}=plot3(pos(1), pos(2), pos(3),'o', 'MarkerSize', 8, 'MarkerFaceColor', [0,0,0]);
                elseif strcmp(p.primitive.primitiveType, 'cutCylinderWithBore')
                    pos=p.getGlobalPosition();
                    R = p.primitive.diameter/2;
                    Ri = p.primitive.boreDiameter/2;
                    
                    obj.drawCircle(pos, R,  p.getGlobalRotm, p.description);
                    obj.drawCircle(pos, Ri,  p.getGlobalRotm, p.description);
                     
                else
                    %just in case a wrong primitive was given as an input
                    warning('Such a primitive cannot be plotted');
                end
            else
                warning('part was already plotted');
            end
        end
        
        function res = isNewPart(obj, p)
            if size(obj.part,2) > 0
                %checking Object
                for i=1:size(obj.part,2)
                    if  isequal(obj.part{1,i},p)
                        res=false;
                        warning('Primitive wurde schon geplottet');
                        break
                    else
                        res=true;
                    end
                end
            else
                res=true;
            end
        end
        
        function remove(obj, p)
            if isa(p,'Assembly')
                obj.removeAssembly(p);
            elseif isa(p,'Part')
                obj.removePart(p);
            end
        end
        
        function removeAssembly(obj,p)
            
            for i=1:size(obj.part,2)
                if  isequal(obj.part{1,i},p)
                    
                    n = obj.h{1,i};
                    
                    if iscell(n)
                        %removes cylinders
                        for l=1:length(obj.h{1,i})
                            delete(n{l});
                        end
                        
                    else
                        %removes Cuboids
                        for l=1:length(obj.h{1,i})
                            delete(n(l,1));
                        end
                    end
                    %empty the place of the primitive in the Array
                    obj.h{1,i}=[];
                    obj.part{1,i}=[];
                    
                    for k=1:3
                        %removes the kos transformations of this part --> all the parents which were ploted with parentPlot
                        m=obj.ks{1,3*i-k+1};
                        delete(m(1,1));
                        delete(m(1,2));
                        delete(m(1,3));
                        obj.ks{1,3*i-k+1}=[];
                        
                    end
                    %remove the empty cells in the cell array
                    obj.h(cellfun('isempty',obj.h)) = [];
                    obj.part(cellfun('isempty',obj.part)) = [];
                    obj.ks(cellfun('isempty',obj.ks)) = [];
                    break; % since there's no need to go on through all the loops the part was already found and removed
                end
            end
        end
        
        
        function removePart(obj,p)
            
            %just removing the part leaving the parent kos, if it was
            %plotted
            
            for i=1:size(obj.part,2)
                if  isequal(obj.part{1,i},p)
                    
                    n = obj.h{1,i};
                    
                    if iscell(n)
                        %removes cylinders
                        for l=1:length(obj.h{1,i})
                            delete(n{l});
                        end
                        
                    else
                        %removes Cuboids
                        for l=1:length(obj.h{1,i})
                            delete(n(l,1));
                        end
                    end
                    %empty the place of the primitive in the Array
                    obj.h{1,i}=[];
                    obj.part{1,i}=[];
                    
                    %remove the empty cells in the cell array
                    obj.h(cellfun('isempty',obj.h)) = [];
                    obj.part(cellfun('isempty',obj.part)) = [];
                    break; % there's no need to go on through all the following iterations, since the part was already found and removed
                end
            end
        end
        
        function fullName=saveAsPNG(obj)
            fname = sprintf('PartPlot_image_%s.png', datestr(now, 'yyyy-mm-dd_HH-MM-SS'));
            [n,p] = uiputfile(fname, 'Save PNG Image');
            fullName = sprintf('%s\\%s', p, n);
            
            set(obj.figure,'PaperPosition',[0, 0, 30, 15]);
            print(obj.figure, fullName, '-dpng', '-r400');
            fprintf('Image saved as %s', fullName);
        end
        
        function drawRotAxis(obj,scaleF)
            if ~exist('k', 'var')
                scaleF=1.05;
            end
            
            try
                delete(obj.hRotAxis); % delete old axis
            end
            
            % use xlim as length for rot axis
            p = obj.axes.XLim;
            % Normalize Length and scale it
            p = p + [-1, 1] * norm(p)*(scaleF-1);
            % Plot Rot axis
            obj.hRotAxis = plot3(obj.axes, p, [0,0], [0,0], '-.','LineWidth',2.9,'color',[1 1 1].*0.3);
            
        end
        
        function [g] = drawBalancePlane(obj,xPos,planeSize)
            
            g={};
            
            obj.balancePlanePos = xPos;
            
            %checking for the cylinder on which the planes are to be drawn
            for i=1:size(obj.part,2)
                if isequal(obj.part{1,i}.primitive.primitiveType,'cylinder')
                    %getting the props of the cylinder
                    origin = obj.part{1,i}.getGlobalPosition;
                    Rota = obj.part{1,i}.getGlobalRotm;
                end
            end
            % Do not auto calculate
            origin=[0,0,0];
            Rota = eye(3);
            
            x = [0 0 0 0];
            y = [0 1 1 0];
            z = [0 0 1 1];
            % Shift cube to center [0, 0, 0]
            
            x=x;
            y=y-0.5;
            z=z-0.5;
            
            % Scale Plane
            x1 = x*planeSize * 1e-3 + xPos(1);
            y1=y*planeSize * 1e-3;
            z1=z*planeSize * 1e-3;
            
            x2= x*planeSize * 1e-3 + xPos(2);
            y2=y*planeSize * 1e-3;
            z2=z*planeSize * 1e-3;
            
            % Transform Plane
            x3=zeros(1,4);
            y3=zeros(1,4);
            z3=zeros(1,4);
            
            x4=zeros(1,4);
            y4=zeros(1,4);
            z4=zeros(1,4);
            
            for j=1:4
                
                Rots=Rota*transpose([x1(1,j) y1(1,j) z1(1,j)]);
                x3(1,j)=Rots(1,1)+origin(1);
                y3(1,j)=Rots(2,1)+origin(2);
                z3(1,j)=Rots(3,1)+origin(3);
                
                Rots=Rota*transpose([x2(1,j) y2(1,j) z2(1,j)]);
                x4(1,j)=Rots(1,1)+origin(1);
                y4(1,j)=Rots(2,1)+origin(2);
                z4(1,j)=Rots(3,1)+origin(3);
            end
            
            g{end+1} = patch(obj.axes,'XData',x3,'YData',y3,'ZData',z3,'FaceColor', obj.balancingplaneColor, 'faceAlpha', 0.3);
            g{end+1} = patch(obj.axes,'XData',x4,'YData',y4,'ZData',z4,'FaceColor', obj.balancingplaneColor, 'faceAlpha', 0.3);
            
        end
        
        function animateGIF(obj, fname)
            if ~exist('fname','var')
                error('File Name needed');
            end
            
            for ii=0:1:360
                view(obj.axes,  ii, 30);
                drawnow
                
                frame = getframe(obj.figure);
                im = frame2im(frame);
                [imind,cm] = rgb2ind(im,256);
                % Write to the GIF File
                if ii == 0
                    imwrite(imind,cm,fname,'gif', 'Loopcount',inf, 'DelayTime',0.01);
                else
                    imwrite(imind,cm,fname,'gif','WriteMode','append', 'DelayTime',0.01);
                end
            end
        end
        function animateAVI(obj,fname)
            vw = VideoWriter(fname);
            open(vw);
            for ii=0:1:360
                view(obj.axes,  ii, 30);
                drawnow();
                writeVideo(vw,getframe(obj.figure));
            end
            for ii=1:20
                view(obj.axes,  ii/20*90, 30-ii/20*30);
                drawnow();
                writeVideo(vw,getframe(obj.figure));
            end
            for ii=1:20
                drawnow();
                writeVideo(vw,getframe(obj.figure));
            end
            close(vw);
        end
        
        function [] = drawResultingDynUnbalance(obj)
            %% Loop through all parts and find the topmost parent
            
            for ii=1:length(obj.part)
                p=obj.part{ii};
                while ~isempty(p.parent)
                    p=p.parent;
                end
                parent(ii) = p;
            end
            
            if any(parent(1)~=parent())
                error('The plotted parts do not have a common Parent!');
            end
            
            u = parent(1).getUAll(obj.balancePlanePos(1), obj.balancePlanePos(2)) * obj.unbalanceScaleFactor;
            
            coolArrow( [obj.balancePlanePos(1), 0, 0], [obj.balancePlanePos(1), u(2:3)], 'color', [255, 145, 0]/255);
            coolArrow( [obj.balancePlanePos(2), 0, 0], [obj.balancePlanePos(2), u(5:6)], 'color', [255, 145, 0]/255);
        end
        
    end
end