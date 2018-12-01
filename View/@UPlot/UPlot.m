classdef UPlot < handle
    %UPLOT is used to visualize the unbalance vector
    %   Detailed explanation goes here
    
    properties
        h  % stores the handles
        u = {} % list of unbalances shown
        autoScale = true;  % scale axes automaticly
        cm                 % Colormap
    end
    properties (Access = private)
        maxU=1e-9;   % Stores maximum value of unbalance amplitude
    end
    
    methods
        function obj = UPlot(varargin)
            inParser = inputParser();
            inParser.addParameter('axis',    [], @ishandle); % Handle to the plto axis
            inParser.addParameter('parent',  [], @ishandle); % Handle to the parent element (eg figure window)
            inParser.addParameter('cm',  [], @isnumeric); % colormap
            inParser.parse(varargin{:})
            
            inP = inParser.Results;
            if isempty(inP.parent)
                % if there is no parent window: create on
                obj.h.parent = figure('name','UPlot');
                obj.h.fig = obj.h.parent();
            else
                % Use the given parent gui Element
                obj.h.parent=inP.parent;
                % search for the parent figure
                f = obj.h.parent;
                while ~isa(f,'matlab.ui.Figure')
                    f=get(f,'parent');
                end
                obj.h.fig = f;
            end
            if isempty(inP.axis)
                % if there is no plot axis: create one
                obj.h.axis = axes('parent',obj.h.parent);
            else
                obj.h.axis = inP.axis;
            end
            
            % Store ColorMap
            if ~isempty(inP.cm)
                    obj.cm = inP.cm;
            else
                obj.cm = colormap('lines');
            end
            
            obj.h.amplitudeGrid = []; % holds the handles to the circle grid
            obj.h.phaseGrid = [];  % holds the handles to the phase grid
            obj.h.amplitudeTicks = []; % holds handles for ticks
            obj.h.phaseTicks = []; % holds handles for ticks
            % Set hold on for the axes
            hold(obj.h.axis,'on');
        end
        
        function obj = updatePolarGrid(obj,varargin)
            inParser = inputParser();
            inParser.addParameter('limitAmplitude',    20, @isnumeric); % Define axis limit for amplitude
            inParser.addParameter('amplitudeTick',    2, @isnumeric); % Define ticks for amplitude
            inParser.addParameter('phaseTick',        30, @isnumeric); % Define ticks for Phase
            inParser.parse(varargin{:})
            
            inP = inParser.Results;
            
            % 			set(obj.h.axis,'XAxisLocation', 'origin');
            % 			set(obj.h.axis,'YAxisLocation', 'origin');
            obj.h.axis.Box = 'off';
            
            % Create coordinates for unity-circle
            a=0:0.1:2*pi+0.1;
            ux=cos(a);
            uy=sin(a);
            
            % delete old grid and ticks
            if ~isempty(obj.h.amplitudeGrid)
                delete(obj.h.amplitudeGrid);
            end
            if ~isempty(obj.h.phaseGrid)
                delete(obj.h.phaseGrid);
            end
            if ~isempty(obj.h.amplitudeTicks)
                delete(obj.h.amplitudeTicks);
            end
             if ~isempty(obj.h.phaseTicks)
                delete(obj.h.phaseTicks);
            end
            % create new Grid for amplitude
            ag={};
            for ii=inP.amplitudeTick:inP.amplitudeTick:inP.limitAmplitude
                ag{end+1} = ux*ii;
                ag{end+1} = uy*ii;
            end
            obj.h.amplitudeGrid = plot(obj.h.axis,ag{:});
            set(obj.h.amplitudeGrid,...
                'Color',[1 1 1]*0.8,...
                'PickableParts', 'none');
            uistack(obj.h.amplitudeGrid,'bottom');
            % create new Grid for phase
            pg={};
            for ii=0:inP.phaseTick:360
                pg{end+1} = [0 cos(ii/180*pi)*inP.limitAmplitude];
                pg{end+1} = [0 sin(ii/180*pi)*inP.limitAmplitude];
            end
            obj.h.phaseGrid = plot(obj.h.axis,pg{:});
            set(obj.h.phaseGrid,...
                'Color',[1 1 1]*0.8,...
                'PickableParts', 'none');
            % Create tick labels Amplitude
            obj.h.amplitudeTicks = [];
            for ii=inP.amplitudeTick:inP.amplitudeTick:inP.limitAmplitude
                strNum = regexprep(sprintf('%2.2f', ii), '\.00', '');
                obj.h.amplitudeTicks(end+1) = text(obj.h.axis, ii,0,  strNum, 'Clipping', 'on');
                obj.h.amplitudeTicks(end+1) = text(obj.h.axis, -ii,0, strNum, 'Clipping', 'on');
                obj.h.amplitudeTicks(end+1) = text(obj.h.axis, 0,ii,  strNum, 'Clipping', 'on');
                obj.h.amplitudeTicks(end+1) = text(obj.h.axis, 0,-ii, strNum, 'Clipping', 'on');
            end
            set(obj.h.amplitudeTicks, ...
                'HorizontalAlignment', 'center'); %, 'BackgroundColor', [1 1 1]);
            % Create tick labels phase
            obj.h.phaseTicks = [];
            for ii=0:inP.phaseTick:360
                if mod(ii,90)~=0
                    obj.h.phaseTicks(end+1) = text(obj.h.axis, cos(ii/180*pi)*inP.limitAmplitude, sin(ii/180*pi)*inP.limitAmplitude, sprintf('%d%c', ii, char(176)), 'Rotation', ii, 'HorizontalAlignment', 'right', 'Clipping', 'on');
                end
            end
            
            % Set Layers
            uistack(obj.h.amplitudeTicks,'bottom');
            uistack(obj.h.phaseGrid,'bottom');
            % Set axis square
            axis(obj.h.axis,'equal');
            % Limit axis to clip points outside the limits
            maxAmp = inP.limitAmplitude;
            xlim(obj.h.axis,[-maxAmp maxAmp]);
            ylim(obj.h.axis,[-maxAmp maxAmp]);
            % remove axis
            box(obj.h.axis,'on');
            set(obj.h.axis,'XTick',[]);
            set(obj.h.axis,'YTick',[]);
        end
        
        function h=addU(obj,u,label)
            %% addU adds the given unbalance with label to the plot
            h = plot(obj.h.axis, u(:,1), u(:,2));
            set(h,...
                'Marker','o',...
                'MarkerFaceColor',[1 0 0],...
                'MarkerEdgeColor','none',...
                'LineStyle', 'none');
            obj.u{end+1}.marker = h;
            
            dcm_obj = datacursormode(obj.h.fig);
            set(dcm_obj,'Enable','on');
            set(dcm_obj,'UpdateFcn',@obj.dcUpdate);
            
            if exist('label','var')
                set(h,'Tag',label);
            end
            
            %if norm(u)> obj.maxU
            maxU = max( sqrt(u(:,1).^2+u(:,2).^2) );
            if  maxU>obj.maxU
                obj.maxU = maxU;
                if obj.autoScale
                    obj.autoScaleAxes();
                end
            end
            
            % Assign auto-color
            if size(u,1)>1
                set(h,...
                    'MarkerFaceColor',obj.cm(length(obj.u),:))
            end
        end
        function h = addUMeasuredAssembly(obj,u,label)
            h=obj.addU(u,label);
            set(h,'MarkerFaceColor',[0.12549 0.698039 0.666667]);
        end
        function h = addUMeasuredPart(obj,u,label)
            h=obj.addU(u,label);
            set(h,'MarkerFaceColor',[0.02549 0.698039 0.466667]);
        end
        function h = addUSimulated(obj,u,label)
            h=obj.addU(u,label);
            set(h,'MarkerFaceColor',[0.603922 0.803922 0.196078]);
        end
        function h = addUInitialPart(obj,u,label)
            h=obj.addU(u,label);
            set(h,'MarkerFaceColor',[199 97 20]./255);
        end
        
        %% 
        function h = addUHistory(obj, u)
            % Adds multiple unbalances and draws arrows
            % Example-input:
            % myU.u           = [2 3];
            % myU.label       = 'Scheibe'; % optional
            % myU.marker      = 'o';       % optional
            % myU.markerFaceColor   = [1 0 0];   % optional
            % myU.markerEdgeColor   = [1 1 1];   % optional
            % myU.showArrow   = true;      % optional
            % myU.uncertainty = 1.5e-3;    % optional
            % myU.child{1}.u  = [3 4];

            
            % Plot initial value
            if ~isfield(u,'label')
                u.label = '';
            end
            h.u = obj.addU(u.u, u.label);
            % Style initial value
            if isfield(u,'markerFaceColor')
                set(h.u,'MarkerFaceColor',u.markerFaceColor);
            end
            if isfield(u,'markerEdgeColor')
                set(h.u,'MarkerEdgeColor',u.markerEdgeColor);
            end
            if isfield(u,'marker')
                set(h.u,'Marker', u.marker);
            end
            if isfield(u,'uncertainty')
                alpha=0:0.1:2*pi+0.1;
                h.uncertainty = plot(obj.h.axis, sin(alpha)*u.uncertainty+u.u(1), cos(alpha)*u.uncertainty+u.u(2),...
                    'Color', [0.8 0.8 0.8],...
                    'PickableParts', 'none', ...
                    'LineStyle', '-.');
                obj.u{end}.uncertainty = h.uncertainty;
            end
            % Draw Arrow to children and plot children
            if isfield(u,'child')
                n = length(obj.u);
                for ii=1:length(u.child)
                    uc = u.child{ii};
                    if ~isfield(uc,'showArrow')
                        uc.showArrow=true;
                    end
                    h.child{ii} = obj.addUHistory(uc);
                    
                    if uc.showArrow
                        q(1)=u.u(1);
                        q(2)=u.u(2);
                        q(3)=uc.u(1)-u.u(1);
                        q(4)=uc.u(2)-u.u(2);
                        try
                            maxHeadSize = norm(get(obj.h.amplitudeTicks(end),'Position'))/400;
                        catch
                            maxHeadSize = 5/norm(q(3:4));
                        end
                        h.arrow(ii) = quiver(obj.h.axis, q(1), q(2), q(3), q(4),...
                            'AutoScale','off', ...
                            'MaxHeadSize', maxHeadSize, ...
                            'Color', [1 1 1]*0.5, ...
                            'PickableParts', 'none');
                    end
                end
                if isfield(h,'arrow')
                obj.u{n}.arrow = h.arrow;
                end
            end
        end
        %%
        function deleteAll(obj)
            if ~isempty(obj.u)
                for ii =1:length(obj.u)
                    delete(obj.u{ii}.marker);
                    try
                        delete(obj.u{ii}.arrow);
                    end
                    try
                        delete(obj.u{ii}.uncertainty);
                    end
                end
            end
            obj.u=[];
            obj.maxU=1e-9;
        end
        function txtOut = dcUpdate(varargin)
            %% dcUpdate updates the datacursor label
            hMark = varargin{3}.Target;
            txtOut=get(hMark,'Tag');
        end
        function autoScaleAxes(obj)
            f=(log(obj.maxU)/log(10)); % Zehnerpotenz der Größe ermitteln um dann "runde" Achsenteilung zu bestimmen
            f=ceil(f);
            
            % obj.updatePolarGrid('limitAmplitude',floor(obj.maxU/10^(f-1)), 'amplitudeTick', (ceil(obj.maxU*10^(-f))/5)*10^f/10);
            maxAmp = ceil(obj.maxU/10^(f-1))*10^(f-1);
            
            maxAmpLeadingDigit = maxAmp/10^(f-1);
            
            if any(maxAmpLeadingDigit==[1, 5])
                ampTickDivisions = 4;
            elseif any(maxAmpLeadingDigit==[2, 4, 8])
                ampTickDivisions = 4;
            elseif any(maxAmpLeadingDigit==[3, 6, 9])
                ampTickDivisions = 3;
            elseif any(maxAmpLeadingDigit==[7])
                ampTickDivisions = 7;
            elseif any(maxAmpLeadingDigit==[0, 10])
                ampTickDivisions = 5;
            else
                ampTickDivisions = 1;
            end
            obj.updatePolarGrid('limitAmplitude',maxAmp, 'amplitudeTick', maxAmp/ampTickDivisions );
        end
        
        function h = addLegend(obj)
            % Add a Legend to the added Points
            ltxt={};
            hMarker=[];
            for j = 1:length(obj.u)
                ltxt{j} = sprintf('%s',obj.u{j}.marker.Tag);
                hMarker(end+1) = obj.u{j}.marker;
            end
            obj.h.legend = clickableLegendM(hMarker, ltxt);
            h=obj.h.legend;
            % Deactivate data cursor mode
            dcm_obj = datacursormode(obj.h.fig);
            set(dcm_obj,'Enable','off');
        end
        
        function zoom(obj)
            N= length(obj.u);
            x=zeros(1, N);
            y=zeros(1, N);
            
            for ii=1:N
                x(ii) = obj.u{ii}.marker.XData;
                y(ii) = obj.u{ii}.marker.YData;
            end
            
            w = max([  abs(mean(x)-min(x)), abs(max(x)-mean(x)), abs(mean(y)-min(y)), abs(max(y)-mean(y))  ]);
            % ampTickDivisions = str2double(sprintf('%1.0d',w));
            % obj.updatePolarGrid('limitAmplitude',obj.maxU, 'amplitudeTick',ampTickDivisions);
            w=w*2;
            xlim(obj.h.axis, [ mean(x)-w, mean(x)+w ]);
            ylim(obj.h.axis, [ mean(y)-w, mean(y)+w ]);
            
        end
        function resetZoom(obj)
            xlim(obj.h.axis, 'auto');
            ylim(obj.h.axis, 'auto');
        end
    end
    
end

