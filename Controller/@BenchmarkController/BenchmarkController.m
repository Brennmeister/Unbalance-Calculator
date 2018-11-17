classdef BenchmarkController < handle
    %BENCHMARKCONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bmMMGUI % Object of classe BenchmarkMagMount (GUI)
        sc = {} % Selma Controller Stack
        mountOnDiscTag; % Tag of disc onto which magnets are mounted
        mountOnDiscPart;
        dbc
        magMass = []; % Stack with magnet weights
        ut         % Universal Translator
        waage      % Obecht of Calss @Waage
        guiWaage   % GUI for Waage
    end

    
    methods
        function obj = BenchmarkController(eNameDisc)
            if ~exist('eNameDisc','var')
                error('EntityName for mounting must be specified!');
            end
            
            tmp=regexp(javaclasspath,'mysql-connector-java-5');
            if isempty(tmp{1})
                javaclasspath('Toolboxes/mysql-connector-java-5.0.8-bin.jar');
            end
            
            
            
            % Connect DB
            obj.dbc = DBController();
            obj.dbc.connect();
            
            discVariable = obj.dbc.loadEntityAsAV(eNameDisc);
            obj.mountOnDiscTag = discVariable.tag;
            % Connect Waage
            obj.guiWaage = GUIWaage();
            obj.waage    = Waage();
            obj.waage.PORT = 'COM5';
            obj.waage.valideValueRange = [10 20]; % [g] Range in which valide values are expected
            obj.waage.open();					  % Nur einkommentieren wenn Waage angeschlossen ist.
            
            obj.waage.updateOnNewValideValue={@(a,b,c){obj.guiWaage.newValue(a,b,c)}, @(a,b,c){obj.addNewMagValue(a,b,c)}};

            
            % Create UT
            obj.ut = UniversalTranslator();
            
            % Build GUI
            obj.bmMMGUI=BenchmarkMagMount();
            obj.bmMMGUI.buildGUI();
            obj.bmMMGUI.showGUI();
            % Add Stuff for MagnetMount (Single Disc)
            obj.addMMOptimization('NoOptimization',eNameDisc);
            obj.addMMOptimization('GreedyOnlineA',eNameDisc);
            obj.addMMOptimization('FullEnumerationBest',eNameDisc);
            obj.addMMOptimization('FullEnumerationWorst',eNameDisc);
            % Load a Disc from the Database. The initial Unbalance ist
            % automaticlly set
            obj.mountOnDiscPart = obj.dbc.loadObject(eNameDisc);
            % Set additional properties
            if isempty(obj.mountOnDiscPart)
                obj.mountOnDiscPart.mass=392-3;
            end

        end
        
        function obj = addNewMagValue(obj, varargin)
            if nargin==2
                value = varargin{1};
            elseif nargin==4
                value = varargin{3};
            end
            %% Add Value to Magnet Mass Stack
            obj.magMass(end+1) = value;
            
            %% Notify all Optimizations
            for ii = 1:length(obj.sc)
                obj.sc{ii}.notifyNewValueWaage([],[],value); % Notify controller about new Value
            end
            %% UpdateGUI
            obj.updateGUI();
        end
        
        function obj = updateGUI(obj)
            obj.updateMagnetStack();
            obj.updateBenchmarkItems();
            obj.updateDiscInfo();
        end
        
        function obj = updateMagnetStack(obj)
            % Fill values
            for ii=1:length(obj.magMass)
                if ii<=6
                    % magnet ist NOut
                    set(obj.bmMMGUI.h.lbl.magNOutVal{ii},'String', sprintf('%3.3f g',obj.magMass(ii)));
                else
                    % magnet is SOut
                    set(obj.bmMMGUI.h.lbl.magSOutVal{ii-6},'String', sprintf('%3.3f g',obj.magMass(ii)));
                end
            end
            % Fill dummy values
            for ii=length(obj.magMass)+1:12
                if ii<=6
                    % magnet ist NOut
                    set(obj.bmMMGUI.h.lbl.magNOutVal{ii},'String', sprintf('- g'));
                else
                    % magnet is SOut
                    set(obj.bmMMGUI.h.lbl.magSOutVal{ii-6},'String', sprintf('- g'));
                end
            end
        end
        
        function obj = updateBenchmarkItems(obj)
            for ii=1:length(obj.sc)
                %% Set name
                set(obj.bmMMGUI.h.opti{ii}.lbl.name, 'String', obj.sc{ii}.description);
                
                %% Calculate and set Unbalance
                u=obj.sc{ii}.mainPart.getUAll(-15e-3,15e-3);
                uStat=u(1:3)+u(4:6);
                
                [uStatPhase, uStatAmp] = cart2pol(uStat(2), uStat(3));
                uStatPhase = uStatPhase/pi*180;
                set(obj.bmMMGUI.h.opti{ii}.lbl.Uamp, 'String', sprintf('%3.3f gmm', uStatAmp*1e6));
                set(obj.bmMMGUI.h.opti{ii}.lbl.Uphase, 'String', sprintf('%3.1f DEG', uStatPhase));
                
                %% Set Parts
                for jj = 1:12
                    oldValue = get(obj.bmMMGUI.h.opti{ii}.lbl.mountPosMag{jj}, 'String');
                    if ~isempty(obj.sc{ii}.mainPart.child{1+jj}.child{1}.child)
                        newValue=regexprep(obj.sc{ii}.mainPart.child{1+jj}.child{1}.child{1}.description, 'Magnet (#.*) \(.*', '$1');
                    else
                        newValue='O';
                    end
                    set(obj.bmMMGUI.h.opti{ii}.lbl.mountPosMag{jj}, 'String', newValue);
                    
                    if strcmp(oldValue, newValue)
                        set(obj.bmMMGUI.h.opti{ii}.lbl.mountPosMag{jj}, 'FontWeight', 'normal', 'FontSize', 8);
                    else
                        set(obj.bmMMGUI.h.opti{ii}.lbl.mountPosMag{jj}, 'FontWeight', 'bold', 'FontSize', 15);
                    end
                end
                
            end
        end
        
        
        function obj = addMMOptimization(obj, type, eNameDisc)
            %% Adds required stuff for Offline Optimization
            %
            % type = 'NoOptimization'
            % type = 'GreedyOnlineA'
            % type = 'FullEnumerationBest'
            % type = 'FullEnumerationWorst'
            
            %% FullEnumerationBest
            % ==========================================================================================================================
            % ==========================================================================================================================
            if strcmp(type,'FullEnumerationBest')
                %% Create Controller Objects
                mc			= SelmaController;			% Create the Main Controller
                mc.description = 'FullEnumeration (best)';
                mc.dbc		= DBController;				% Add the Controller for the DataBase Access
                mc.mntc		= MountController;			% Add the Controller for the Mounting Process
                mc.dbc.connect();                       % Connect to the Database Server in the Cloud
                v           = ViewHelper();
                %% Create the skeleton for the current Task (e.g. ProLemo)
                % The Genie helps building it
                myGenie = Genie();
                rd   = myGenie.wish('make an assembly skeleton',  'ofTypeID', 'ProLemoDisc'); % Create First Rotor Disc
                
                mc.skeleton.magnet = myGenie.wish('make a part skeleton',  'ofTypeID', 'ProLemoMagnet'); % Create a Dummy-Magnet
                mc.skeleton.disc   = myGenie.wish('make a part skeleton',  'ofTypeID', 'ProLemoDisc'); % Create a Dummy-Disc
                mc.skeleton.shaft  = myGenie.wish('make a part skeleton',  'ofTypeID', 'ProLemoShaft'); % Create a Dummy-Shaft
                
                mc.mntc.mnti	= MountingInstructions();	% Add the Mounting Instructions to the Mounting Controller
                mc.mainPart = rd;
                %% 1. Mounting Step
                mc.mntc.addMountingStep('Add a Disc Part to the Rotor Disc Assembly',		{rd.child{1}},				'ProLemoDisc',	1);
                %% 2. Mounting Step
                t=cell(1,6); for ii = 2:2:13, t{ii/2}=rd.child{ii}.child{1}; end
                of = ObjectiveFunction(); % Create Object for calculating the objective function value. Can be used multiple times
                alg = FullEnumeration();  % Use Full Enumeration Algorithm for optimization
                mc.mntc.addMountingStep('Add Magnets (NOut) to Rotor Disc Assembly',		t,							'ProLemoMagnet',6, 'algorithm', alg, 'objectiveFunction', @(u){of.rateUnbalance(mc.mainPart.getUAll(-15e-3, 15e-3))});
                
                %% 3. Mounting Step
                t=cell(1,6); for ii = 3:2:13, t{(ii-1)/2}=rd.child{ii}.child{1}; end
                alg = FullEnumeration();  % Use Full Enumeration Algorithm for optimization
                mc.mntc.addMountingStep('Add Magnets (SOut) to Rotor Disc Assembly',		t,							'ProLemoMagnet',6, 'algorithm', alg, 'objectiveFunction', @(u){of.rateUnbalance(mc.mainPart.getUAll(-15e-3, 15e-3))});
                %% Ready to process input Data and give Instructions
                %% Mount Disc as initial Part (Step 1)
                % Load a Disc from the Database. The initial Unbalance ist
                % automaticlly set
                p = mc.dbc.loadObject(eNameDisc);
                % Set additional properties
                if isempty(p.mass)
                    p.mass=392-3;
                end
                p.setPrimitive('cylinder', 'diameter', 90e-3, 'length', 30e-3);
                
                mc.mntc.mount(p,mc.mntc.getNextMountingPlace);	% Mount the Disc as first part.
                v.showMountingInstructions(mc.mntc.mnti);		% Show Status
                %% Mount Magnets (NOut) (step 2)
                mc.mntc.gotoNextMountingStep;					% Go on to the next Mounting step
                v.showMountingInstructions(mc.mntc.mnti);		% Show Status
                
                % Mounting with the new, build-in, optimization
                % Measure 6 magnets with the Waage and perform calculation with them
                p={};
                ta = TriggerAction('Call AutoMount after 6 Magnets were added');
                ta.numAction = 6;
                for ii=1:6 % Create 6 Skeleton-Parts. The mass is added later
                    p{ii} = mc.skeleton.magnet.copy();
                    p{ii}.description = sprintf('Magnet #%d NOut (Offline Optimierung)',ii);
                    p{ii}.mass=[]; % Must be set to whatever was measured
                end
                ta.stack = p;            % Pass Part-Skeleton to Trigger Action
                ta.funObject = mc.mntc;  % Set Object for auto-Mount function after Trigger was reached
                mc.taMesswertWaage{2} = ta; % Set Object for main controller to pass new measured values to
                % Add Post Optimization Action for step 2
                ta.postTriggerAction = { ...
                    @(){fprintf('%s', v.showPartTable(mc.mainPart,-15e-3,15e-3))}, ...
                    @(o){fprintf('Going to next MountingStep (by TA)')}, ...
                    @(o){mc.mntc.gotoNextMountingStep},  ...
                    @(o){v.showMountingInstructions(mc.mntc.mnti)} ...
                    };
                
                %% Mount Magnets (SOut)
                % Mounting with the new, build-in, optimization
                % Measure 6 magnets with the Waage and perform calculation with them
                p={};
                ta = TriggerAction('Call AutoMount after 6 Magnets were added');
                ta.numAction = 6;
                for ii=1:6 % Create 6 Skeleton-Parts. The mass is added later
                    p{ii} = mc.skeleton.magnet.copy();
                    p{ii}.description = sprintf('Magnet #%d SOut (Offline Optimierung)',ii);
                    p{ii}.mass=[]; % Must be set to whatever was measured
                end
                ta.stack = p;            % Pass Part-Skeleton to Trigger Action
                ta.funObject = mc.mntc;  % Set Object for auto-Mount function after Trigger was reached
                mc.taMesswertWaage{3} = ta; % Set Object for main controller to pass new measured values to
                
                % Add Post Optimization Action for step 3
                ta.postTriggerAction = { ...
                    @(o){v.showPartTable(mc.mainPart,-15e-3,15e-3)}, ...
                    @(o){fprintf('Going to next MountingStep (by TA)')}, ...
                    @(o){mc.mntc.gotoNextMountingStep},  ...
                    @(o){v.showMountingInstructions(mc.mntc.mnti)} ...
                    };
            end
            %% FullEnumerationWorst
            % ==========================================================================================================================
            % ==========================================================================================================================
            if strcmp(type,'FullEnumerationWorst')
                %% Create Controller Objects
                mc			= SelmaController;			% Create the Main Controller
                mc.description = 'FullEnumeration (worst)';
                mc.dbc		= DBController;				% Add the Controller for the DataBase Access
                mc.mntc		= MountController;			% Add the Controller for the Mounting Process
                mc.dbc.connect();                       % Connect to the Database Server in the Cloud
                v           = ViewHelper();
                %% Create the skeleton for the current Task (e.g. ProLemo)
                % The Genie helps building it
                myGenie = Genie();
                rd   = myGenie.wish('make an assembly skeleton',  'ofTypeID', 'ProLemoDisc'); % Create First Rotor Disc
                
                mc.skeleton.magnet = myGenie.wish('make a part skeleton',  'ofTypeID', 'ProLemoMagnet'); % Create a Dummy-Magnet
                mc.skeleton.disc   = myGenie.wish('make a part skeleton',  'ofTypeID', 'ProLemoDisc'); % Create a Dummy-Disc
                mc.skeleton.shaft  = myGenie.wish('make a part skeleton',  'ofTypeID', 'ProLemoShaft'); % Create a Dummy-Shaft
                
                mc.mntc.mnti	= MountingInstructions();	% Add the Mounting Instructions to the Mounting Controller
                mc.mainPart = rd;
                %% 1. Mounting Step
                mc.mntc.addMountingStep('Add a Disc Part to the Rotor Disc Assembly',		{rd.child{1}},				'ProLemoDisc',	1);
                %% 2. Mounting Step
                t=cell(1,6); for ii = 2:2:13, t{ii/2}=rd.child{ii}.child{1}; end
                of = ObjectiveFunction(); % Create Object for calculating the objective function value. Can be used multiple times
                alg = FullEnumeration();  % Use Full Enumeration Algorithm for optimization
                mc.mntc.addMountingStep('Add Magnets (NOut) to Rotor Disc Assembly',		t,							'ProLemoMagnet',6, 'algorithm', alg, 'objectiveFunction', @(u){of.rateUnbalanceInverse(mc.mainPart.getUAll(-15e-3, 15e-3))});
                
                %% 3. Mounting Step
                t=cell(1,6); for ii = 3:2:13, t{(ii-1)/2}=rd.child{ii}.child{1}; end
                alg = FullEnumeration();  % Use Full Enumeration Algorithm for optimization
                mc.mntc.addMountingStep('Add Magnets (SOut) to Rotor Disc Assembly',		t,							'ProLemoMagnet',6, 'algorithm', alg, 'objectiveFunction', @(u){of.rateUnbalanceInverse(mc.mainPart.getUAll(-15e-3, 15e-3))});
                %% Ready to process input Data and give Instructions
                %% Mount Disc as initial Part (Step 1)
                % Load a Disc from the Database. The initial Unbalance ist
                % automaticlly set
                p = mc.dbc.loadObject(eNameDisc);
                % Set additional properties
                if isempty(p.mass)
                    p.mass=392-3;
                end
                p.setPrimitive('cylinder', 'diameter', 90e-3, 'length', 30e-3);
                
                mc.mntc.mount(p,mc.mntc.getNextMountingPlace);	% Mount the Disc as first part.
                v.showMountingInstructions(mc.mntc.mnti);		% Show Status
                %% Mount Magnets (NOut) (step 2)
                mc.mntc.gotoNextMountingStep;					% Go on to the next Mounting step
                v.showMountingInstructions(mc.mntc.mnti);		% Show Status
                
                % Mounting with the new, build-in, optimization
                % Measure 6 magnets with the Waage and perform calculation with them
                p={};
                ta = TriggerAction('Call AutoMount after 6 Magnets were added');
                ta.numAction = 6;
                for ii=1:6 % Create 6 Skeleton-Parts. The mass is added later
                    p{ii} = mc.skeleton.magnet.copy();
                    p{ii}.description = sprintf('Magnet #%d NOut (Offline Optimierung)',ii);
                    p{ii}.mass=[]; % Must be set to whatever was measured
                end
                ta.stack = p;            % Pass Part-Skeleton to Trigger Action
                ta.funObject = mc.mntc;  % Set Object for auto-Mount function after Trigger was reached
                mc.taMesswertWaage{2} = ta; % Set Object for main controller to pass new measured values to
                % Add Post Optimization Action for step 2
                ta.postTriggerAction = { ...
                    @(){fprintf('%s', v.showPartTable(mc.mainPart,-15e-3,15e-3))}, ...
                    @(o){fprintf('Going to next MountingStep (by TA)')}, ...
                    @(o){mc.mntc.gotoNextMountingStep},  ...
                    @(o){v.showMountingInstructions(mc.mntc.mnti)} ...
                    };
                
                %% Mount Magnets (SOut)
                % Mounting with the new, build-in, optimization
                % Measure 6 magnets with the Waage and perform calculation with them
                p={};
                ta = TriggerAction('Call AutoMount after 6 Magnets were added');
                ta.numAction = 6;
                for ii=1:6 % Create 6 Skeleton-Parts. The mass is added later
                    p{ii} = mc.skeleton.magnet.copy();
                    p{ii}.description = sprintf('Magnet #%d SOut (Offline Optimierung)',ii);
                    p{ii}.mass=[]; % Must be set to whatever was measured
                end
                ta.stack = p;            % Pass Part-Skeleton to Trigger Action
                ta.funObject = mc.mntc;  % Set Object for auto-Mount function after Trigger was reached
                mc.taMesswertWaage{3} = ta; % Set Object for main controller to pass new measured values to
                
                % Add Post Optimization Action for step 3
                ta.postTriggerAction = { ...
                    @(o){v.showPartTable(mc.mainPart,-15e-3,15e-3)}, ...
                    @(o){fprintf('Going to next MountingStep (by TA)')}, ...
                    @(o){mc.mntc.gotoNextMountingStep},  ...
                    @(o){v.showMountingInstructions(mc.mntc.mnti)} ...
                    };
            end
            
            %% NoOptimization
            % ==========================================================================================================================
            % ==========================================================================================================================
            if strcmp(type,'NoOptimization')
                %% Create Controller Objects
                mc			= SelmaController;			% Create the Main Controller
                mc.description = 'NoOptimization';       % Add short description
                mc.dbc		= DBController;				% Add the Controller for the DataBase Access
                mc.mntc		= MountController;			% Add the Controller for the Mounting Process
                % mc.opt	= OptimizationController;	% Add the Controller for Optimization
                mc.dbc.connect();                       % Connect to the Database Server in the Cloud
                v           = ViewHelper();
                %% Create the skeleton for the current Task (e.g. ProLemo)
                % The Genie helps building it
                myGenie = Genie();
                rd   = myGenie.wish('make an assembly skeleton',  'ofTypeID', 'ProLemoDisc'); % Create First Rotor Disc
                
                mc.skeleton.magnet = myGenie.wish('make a part skeleton',  'ofTypeID', 'ProLemoMagnet'); % Create a Dummy-Magnet
                mc.skeleton.disc   = myGenie.wish('make a part skeleton',  'ofTypeID', 'ProLemoDisc'); % Create a Dummy-Disc
                mc.skeleton.shaft  = myGenie.wish('make a part skeleton',  'ofTypeID', 'ProLemoShaft'); % Create a Dummy-Shaft
                
                mc.mntc.mnti	= MountingInstructions();	% Add the Mounting Instructions to the Mounting Controller
                
                %% 1. Mounting Step
                mc.mntc.addMountingStep('Add a Disc Part to the Rotor Disc Assembly',		{rd.child{1}},				'ProLemoDisc',	1);
                %% 2. Mounting Step
                t=cell(1,6); for ii = 2:2:13, t{ii/2}=rd.child{ii}.child{1}; end
                of = ObjectiveFunction(); % Create Object for calculating the objective function value. Can be used multiple times
                alg = NoOptimization();
                mc.mntc.addMountingStep('Add Magnets (NOut) to Rotor Disc Assembly',		t,							'ProLemoMagnet',6, 'algorithm', alg, 'objectiveFunction', @(u){of.rateUnbalance(mc.mainPart.getUAll(-15e-3, 15e-3))});
                %% 3. Mounting Step
                t=cell(1,6); for ii = 3:2:13, t{(ii-1)/2}=rd.child{ii}.child{1}; end
                alg = NoOptimization();
                mc.mntc.addMountingStep('Add Magnets (SOut) to Rotor Disc Assembly',		t,							'ProLemoMagnet',6, 'algorithm', alg, 'objectiveFunction', @(u){of.rateUnbalance(mc.mainPart.getUAll(-15e-3, 15e-3))});
                %% Save Assembly/Part Objects
                mc.mntc.assembly	= rd;	% Connect the Assembly
                mc.mainPart			= rd;	% Save the MainPart (in this case the rotor) in the Controller
                %% Ready to process input Data and give Instructions
                %% Mount Disc as initial Part (Step 1)
                % Load a Disc from the Database. The initial Unbalance ist
                % automaticlly set
                p = mc.dbc.loadObject(eNameDisc);
                % Set additional properties
                if isempty(p.mass)
                    p.mass=392-3;
                end
                p.setPrimitive('cylinder', 'diameter', 90e-3, 'length', 30e-3);
                
                mc.mntc.mount(p,mc.mntc.getNextMountingPlace);	% Mount the Disc as first part.
                mc.mntc.gotoNextMountingStep();
                %% Ab Hier Montage.
                for numMag1=1:6
                    %% Mount Magnets (NOut) (step 2) (execute 6x)
                    % Create dummy-parts which will receive measured values
                    p={};
                    for ii=1:6 % Create 6 Skeleton-Parts. The mass is added later
                        p{ii} = mc.skeleton.magnet.copy();
                        p{ii}.description = sprintf('Magnet #%d NOut (NoOptimization)',ii);
                        p{ii}.mass=[]; % Must be set to whatever was measured
                    end
                    
                    % Set action
                    ta = TriggerAction('Call AutoMount after 1 Magnets were added');
                    ta.numAction = 1;
                    ta.stack = {p{numMag1}};            % Pass Part-Skeleton to Trigger Action
                    ta.funObject = mc.mntc;  % Set Object for auto-Mount function after Trigger was reached
                    mc.taMesswertWaage{2}{numMag1} = ta; % Set Object for main controller to pass new measured values to
                    % Add Post Optimization Action for step 2...7
                    if numMag1<6
                        ta.postTriggerAction = { ...
                            @(o){v.showPartTable(mc.mainPart,-15e-3,15e-3)}, ...
                            @(o){v.showMountingInstructions(mc.mntc.mnti)} ...
                            };
                    else
                        ta.postTriggerAction = { ...
                            @(o){v.showPartTable(mc.mainPart,-15e-3,15e-3)}, ...
                            @(o){fprintf('Going to next MountingStep (by TA)')}, ...
                            @(o){mc.mntc.gotoNextMountingStep},  ...
                            @(o){v.showMountingInstructions(mc.mntc.mnti)} ...
                            };
                    end
                    
                end
                for numMag2=1:6
                    % Create dummy-parts which will receive measured values
                    p={};
                    for ii=1:6 % Create 6 Skeleton-Parts. The mass is added later
                        p{ii} = mc.skeleton.magnet.copy();
                        p{ii}.description = sprintf('Magnet #%d SOut (NoOptimization)',ii);
                        p{ii}.mass=[]; % Must be set to whatever was measured
                    end
                    % Set action
                    ta = TriggerAction('Call AutoMount after 1 Magnets were added');
                    ta.numAction = 1;
                    ta.stack = {p{numMag2}};            % Pass Part-Skeleton to Trigger Action
                    ta.funObject = mc.mntc;  % Set Object for auto-Mount function after Trigger was reached
                    mc.taMesswertWaage{3}{numMag2} = ta; % Set Object for main controller to pass new measured values to
                    % Add Post Optimization Action for step 2...7
                    if numMag2<6
                        ta.postTriggerAction = { ...
                            @(o){v.showPartTable(mc.mainPart,-15e-3,15e-3)}, ...
                            @(o){v.showMountingInstructions(mc.mntc.mnti)} ...
                            };
                    else
                        ta.postTriggerAction = { ...
                            @(o){v.showPartTable(mc.mainPart,-15e-3,15e-3)}, ...
                            @(o){fprintf('Going to next MountingStep (by TA)')}, ...
                            @(o){mc.mntc.gotoNextMountingStep},  ...
                            @(o){v.showMountingInstructions(mc.mntc.mnti)} ...
                            };
                    end
                    
                end
            end
            
            %% GreedyOnlineA
            % ==========================================================================================================================
            % ==========================================================================================================================
            if strcmp(type,'GreedyOnlineA')
                %% Create Controller Objects
                mc			= SelmaController;			% Create the Main Controller
                mc.description = 'GreedyOnlineA';       % Add short description
                mc.dbc		= DBController;				% Add the Controller for the DataBase Access
                mc.mntc		= MountController;			% Add the Controller for the Mounting Process
                % mc.opt	= OptimizationController;	% Add the Controller for Optimization
                mc.dbc.connect();                       % Connect to the Database Server in the Cloud
                v           = ViewHelper();
                %% Create the skeleton for the current Task (e.g. ProLemo)
                % The Genie helps building it
                myGenie = Genie();
                rd   = myGenie.wish('make an assembly skeleton',  'ofTypeID', 'ProLemoDisc'); % Create First Rotor Disc
                
                mc.skeleton.magnet = myGenie.wish('make a part skeleton',  'ofTypeID', 'ProLemoMagnet'); % Create a Dummy-Magnet
                mc.skeleton.disc   = myGenie.wish('make a part skeleton',  'ofTypeID', 'ProLemoDisc'); % Create a Dummy-Disc
                mc.skeleton.shaft  = myGenie.wish('make a part skeleton',  'ofTypeID', 'ProLemoShaft'); % Create a Dummy-Shaft
                
                mc.mntc.mnti	= MountingInstructions();	% Add the Mounting Instructions to the Mounting Controller
                
                %% 1. Mounting Step
                mc.mntc.addMountingStep('Add a Disc Part to the Rotor Disc Assembly',		{rd.child{1}},				'ProLemoDisc',	1);
                %% 2. Mounting Step
                t=cell(1,6); for ii = 2:2:13, t{ii/2}=rd.child{ii}.child{1}; end
                of = ObjectiveFunction(); % Create Object for calculating the objective function value. Can be used multiple times
                % - Greedy Online Algorithm -----------------------------------------------
                % Use Greedy Online Algorithm for optimization.
                % It requires an "average" part for online-capabilitys
                alg = GreedyOnlineA();
                
                % Generate Average Part
                fprintf('Generating Average Part for Greedy Online Algorithm ');
                avgPart = mc.skeleton.magnet.copy();                                        % Create Average Part
                % e=mc.dbc.getUniqueEntityNames('mag_pro.*','attribute','nout','value',1);    % Load all Magnet Names
                % eMass = NaN(size(e));                                                                % Set mass vector
                % for ii=1:length(e)
                %     eMass(ii) = mc.dbc.loadAttributeValue(e{ii},'mass');
                %     if mod(ii,10)==0
                %         fprintf('.');
                %     end
                % end
                % avgMass = mean(eMass); % =14.4653
                avgMass = 14.4653; % Einmal ermittelt, zum test jetzt statisch
                avgPart.mass=avgMass*1e-3;
                fprintf(' done\n');
                alg.setAvgPart(avgPart);
                % -------------------------------------------------------------------------
                mc.mntc.addMountingStep('Add Magnets (NOut) to Rotor Disc Assembly',		t,							'ProLemoMagnet',6, 'algorithm', alg, 'objectiveFunction', @(u){of.rateUnbalance(mc.mainPart.getUAll(-15e-3, 15e-3))});
                
                %% 3. Mounting Step
                t=cell(1,6); for ii = 3:2:13, t{(ii-1)/2}=rd.child{ii}.child{1}; end
                % - Greedy Online Algorithm -----------------------------------------------
                % Use Greedy Online Algorithm for optimization.
                % It requires an "average" part for online-capabilitys
                alg = GreedyOnlineA();
                
                % Generate Average Part
                fprintf('Generating Average Part for Greedy Online Algorithm ');
                avgPart = mc.skeleton.magnet.copy();                                        % Create Average Part
                % e=mc.dbc.getUniqueEntityNames('mag_pro.*','attribute','nout','value',0);    % Load all Magnet Names
                % eMass = NaN(size(e));                                                                % Set mass vector
                % for ii=1:length(e)
                %     eMass(ii) = mc.dbc.loadAttributeValue(e{ii},'mass');
                %     if mod(ii,10)==0
                %         fprintf('.');
                %     end
                % end
                % avgMass = mean(eMass);
                avgMass = 14.4670; % Zum Test, einmalig ermittelt
                avgPart.mass=avgMass*1e-3;
                fprintf(' done\n');
                alg.setAvgPart(avgPart);
                % -------------------------------------------------------------------------
                mc.mntc.addMountingStep('Add Magnets (SOut) to Rotor Disc Assembly',		t,							'ProLemoMagnet',6, 'algorithm', alg, 'objectiveFunction', @(u){of.rateUnbalance(mc.mainPart.getUAll(-15e-3, 15e-3))});
                
                %% Save Assembly/Part Objects
                mc.mntc.assembly	= rd;	% Connect the Assembly
                mc.mainPart			= rd;	% Save the MainPart (in this case the rotor) in the Controller
                %% Ready to process input Data and give Instructions
                %% Mount Disc as initial Part (Step 1)
                % Load a Disc from the Database. The initial Unbalance ist
                % automaticlly set
                p = mc.dbc.loadObject(eNameDisc);
                % Set additional properties
                if isempty(p.mass)
                    p.mass=392-3;
                end
                p.setPrimitive('cylinder', 'diameter', 90e-3, 'length', 30e-3);
                
                mc.mntc.mount(p,mc.mntc.getNextMountingPlace);	% Mount the Disc as first part.
                mc.mntc.gotoNextMountingStep();
                %% Ab Hier Montage.
                for numMag1=1:6
                    %% Mount Magnets (NOut) (step 2) (execute 6x)
                    % Create dummy-parts which will receive measured values
                    p={};
                    for ii=1:6 % Create 6 Skeleton-Parts. The mass is added later
                        p{ii} = mc.skeleton.magnet.copy();
                        p{ii}.description = sprintf('Magnet #%d NOut (GreedyOnlineA)',ii);
                        p{ii}.mass=[]; % Must be set to whatever was measured
                    end
                    
                    % Set action
                    ta = TriggerAction('Call AutoMount after 1 Magnets were added');
                    ta.numAction = 1;
                    ta.stack = {p{numMag1}};            % Pass Part-Skeleton to Trigger Action
                    ta.funObject = mc.mntc;  % Set Object for auto-Mount function after Trigger was reached
                    mc.taMesswertWaage{2}{numMag1} = ta; % Set Object for main controller to pass new measured values to
                    % Add Post Optimization Action for step 2...7
                    if numMag1<6
                        ta.postTriggerAction = { ...
                            @(o){v.showPartTable(mc.mainPart,-15e-3,15e-3)}, ...
                            @(o){v.showMountingInstructions(mc.mntc.mnti)} ...
                            };
                    else
                        ta.postTriggerAction = { ...
                            @(o){v.showPartTable(mc.mainPart,-15e-3,15e-3)}, ...
                            @(o){fprintf('Going to next MountingStep (by TA)')}, ...
                            @(o){mc.mntc.gotoNextMountingStep},  ...
                            @(o){v.showMountingInstructions(mc.mntc.mnti)} ...
                            };
                    end
                    
                end
                for numMag2=1:6
                    % Create dummy-parts which will receive measured values
                    p={};
                    for ii=1:6 % Create 6 Skeleton-Parts. The mass is added later
                        p{ii} = mc.skeleton.magnet.copy();
                        p{ii}.description = sprintf('Magnet #%d SOut (GreedyOnlineA)',ii);
                        p{ii}.mass=[]; % Must be set to whatever was measured
                    end
                    % Set action
                    ta = TriggerAction('Call AutoMount after 1 Magnets were added');
                    ta.numAction = 1;
                    ta.stack = {p{numMag2}};            % Pass Part-Skeleton to Trigger Action
                    ta.funObject = mc.mntc;  % Set Object for auto-Mount function after Trigger was reached
                    mc.taMesswertWaage{3}{numMag2} = ta; % Set Object for main controller to pass new measured values to
                    % Add Post Optimization Action for step 2...7
                    if numMag2<6
                        ta.postTriggerAction = { ...
                            @(o){v.showPartTable(mc.mainPart,-15e-3,15e-3)}, ...
                            @(o){v.showMountingInstructions(mc.mntc.mnti)} ...
                            };
                    else
                        ta.postTriggerAction = { ...
                            @(o){v.showPartTable(mc.mainPart,-15e-3,15e-3)}, ...
                            @(o){fprintf('Going to next MountingStep (by TA)')}, ...
                            @(o){mc.mntc.gotoNextMountingStep},  ...
                            @(o){v.showMountingInstructions(mc.mntc.mnti)} ...
                            };
                    end
                    
                end
                
            end
            %% Load measured manufacturing deviations
             d = obj.dbc.loadEntityAsAV(eNameDisc);
             if isfield(d, 'magMountEccentricity')
                 % Check if length fits the required one
                 if length(d.magMountEccentricity)~=length(mc.mainPart.child)-1
                     error('The length of the loaded ''magMountEccentricity'' does not fit the length of the MagMountContainers');
                 end
                 % Assemblies to set the eccentricity
                 obj.setEccentricity(mc.mainPart, d.magMountEccentricity);
             end
            %% Add MainController to stack
            obj.sc{end+1} = mc;
        end
        
        function setEccentricity(obj, rotor, e)
            if isa(rotor,'Assembly') && isnumeric(e)
                % Set eccentricity for the given rotor
            for ii=1:length(rotor.child)-1
                rotor.child{ii+1}.child{1}.origin(2) =rotor.child{ii+1}.child{1}.origin(2) + e(ii);
            end
            elseif nargin==2 && isnumeric(rotor)
                e=rotor;
                for ii=1:length(obj.sc)
                    obj.setEccentricity(obj.sc{ii}.mainPart, e);
                end
            else
                error('Inputs could not be parsed. No Eccentricity set.');
            end
        end
        
        function obj = updateDiscInfo(obj)
            p=obj.mountOnDiscPart;
            [uphase, uamp] = cart2pol(p.initialU(2), p.initialU(3)); 
            uphase=uphase/pi*180;
            uamp=uamp*1e6;
            set(obj.bmMMGUI.h.lbl.disc, 'String', sprintf('Disc (tag= %d; entity= %s) UAmp = %3.3f gmm UPhase= %3.1f DEG', p.tag, p.entityName, uamp, uphase));
        end
        
        function s = exportToStruct(obj)
            s.discTag = obj.mountOnDiscTag;
            s.discPart = obj.mountOnDiscPart;
            s.datetime = datestr(now,'yyyy-mm-dd HH:MM:SS');
            s.magnets = obj.magMass;
            for ii=1:length(obj.sc)
                s.result{ii}.description = obj.sc{ii}.description;
                s.result{ii}.u = obj.sc{ii}.mainPart.getUAll(-15e-3, 15e-3);
                
                u=s.result{ii}.u;
                us=u(1:3)+u(4:6);
                [uphase, uamp] = cart2pol(us(2), us(3));
                
                s.result{ii}.usPhaseDEG=uphase/pi*180;
                s.result{ii}.usAmpGMM=uamp*1e6;
                
                %% Save Magnet Positions on disc
                s.result{ii}.magMountString = '';
                numMountPosMax = length(obj.bmMMGUI.h.opti{ii}.lbl.mountPosMag);
                for jj=1:numMountPosMax
                    mountPosString = obj.bmMMGUI.h.opti{ii}.lbl.mountPosMag{jj}.String;
                    if ~strcmp(mountPosString,'O')
                        magSeqNum = str2double(regexprep(mountPosString,'#(\d) .*', '$1'));
                        nOut = regexp(obj.bmMMGUI.h.opti{ii}.lbl.mountPosMag{jj}.String,'NOut');
                        sOut = regexp(obj.bmMMGUI.h.opti{ii}.lbl.mountPosMag{jj}.String,'SOut');
                    else
                        % Es wurde noch kein Magnet montiert
                        magSeqNum = [];
                        nOut = false;
                        sOut = flase;
                        m = 0;
                    end
                    if nOut
                        % Magnet mit Nordpol außen.
                        % Für ihn stehen die Montageplätze 1,3,5,7... zur
                        % Verfügung.
                        % Die Magnete mit Nordpol außen werden zuerst
                        % montiert. Der Index der Magnetmasse ist 1:6 in
                        % obj.magMass 
                        % Die Sequenznummer muss daher nicht angepasst
                        % werden!
                        magSeqNum = magSeqNum;
                        m=obj.magMass(magSeqNum);
                    elseif sOut
                        % Magnet mit Südpol außen.
                        % Für ihn stehen die Montageplätze 2,4,6,8... zur
                        % Verfügung.
                        % Die Magnete mit Südpol außen werden nach den NOut
                        % Magneten montiert.
                        % Der Index der Magnetmasse ist 7:12 in
                        % obj.magMass 
                        % Die Sequenznummer muss daher angepasst
                        % werden!
                        magSeqNum = numMountPosMax/2+magSeqNum;
                        m=obj.magMass(magSeqNum);
                    end
                    % Abspeichern der Sequenz-Nummer.
                    % Auf den Montageplat jj (gespeichert in
                    % s.result{ii}.magMountSequence(jj)) wird der Magnet
                    % mit dem Index magSeqNum gespeichert
                    s.result{ii}.magMountSequence(jj) = magSeqNum;

                    s.result{ii}.magMountString = sprintf('%s\nPos. %d: %s (%5.3f g)', s.result{ii}.magMountString, jj, mountPosString, m);
                end
            end
        end
        
        function closeFcn(obj)
           obj.waage.close();
        end
        function e = saveInDB(obj)
            e = obj.dbc.generateEntityName('mmBenchM');
            s=obj.exportToStruct();
            avC = obj.ut.avStructToCell(s);
            obj.dbc.createEntity(e,avC{:});
        end
        
        function obj = loadOptimization(obj, eName)
            %% Loads an Optimization 
            % eName
            %  Name of the entity (DB) of the saved
            %  BenchmarkController, eg eName='mmBenchM_1OJXEBDS47'
            loadBM = obj.dbc.loadEntityAsAV(eName);
            if ~strcmp(loadBM.discPart.description, obj.mountOnDiscPart.description)
                error('DiscTag of loaded entity does not fit the initially given one');
            end
            switch loadBM.discPart.typeID
                case 'ProLemoDisc'
                    obj.magMass = loadBM.magnets;
                    for ii=1:length(loadBM.result)
                        magSeq = loadBM.result{ii}.magMountSequence;
                        if max(loadBM.result{ii}.magMountSequence)==6
                            magSeq = loadBM.result{ii}.magMountSequence + [0 6 0 6 0 6 0 6 0 6 0 6];
                        end
                        % Recreate Sequenze of Magnet Container
                        asblySeq =cell(1,length(magSeq));
                        for jj=1:length(magSeq)
                            asblySeq{jj} = obj.sc{ii}.mainPart.child{1+jj}.child{1};
                        end
                        % Fill Magnet in Container
                        for jj=1:length(magSeq)
                            p = obj.sc{ii}.skeleton.magnet.copy();
                            p.mass = loadBM.magnets(magSeq(jj))*1e-3;
                            isNOut = mod(jj,2);
                            if isNOut
                                strNSOut='NOut';
                                magNum=magSeq(jj);
                            else
                                strNSOut='SOut';
                                magNum=magSeq(jj)-6;
                            end
                            p.description = sprintf('#%1.0f %s', magNum, strNSOut);
                            p.setParent(asblySeq{jj});
                        end
                    end
                otherwise
                    error('Loading of PartType ''%s'' not supported yet', loadBM.discPart.typeID);
            end
            obj.updateGUI();
        end
        
        function obj = simulateOptimization(obj, eName)
            %% Simulate Optimization with given Magnet-Stack
            % eName (= string)
            %  Name of the entity (DB) of the saved
            %  BenchmarkController, eg eName='mmBenchM_1OJXEBDS47'
            % eName (=vector)
            %  Uses eName as vector of magnet mass values (in g)
            
            if isstr(eName)
                loadBM = obj.dbc.loadEntityAsAV(eName);
                if ~strcmp(loadBM.discPart.description, obj.mountOnDiscPart.description)
                    warning('DiscTag of loaded entity does not fit the initially given one. Are you sure what you are doing?');
                end
                obj.simulateOptimization(loadBM.magnets);
            elseif isvector(eName)
                mStack = eName;
                for m=mStack
                    obj.waage.testValue(m);
                end
            else
                error('Unsupported input type');
            end
            
            if false
                %% Code-Schnipsel
                str='';
                resO={};
                for ii=1:length(ee)
                    bmc=BenchmarkController(ee{ii}.discPart.entityName);
                    bmc.simulateOptimization(ee{ii}.entityName);
                    s=bmc.exportToStruct();
                    str=sprintf('%s\n=Entity %s ===============', str, ee{ii}.entityName);
                    str=sprintf('%s\nAltes Ergebnis (geladen, mit Exz): greedyOnline: %3.3f gmm    GlobalBest: %3.3f gmm', str, ee{ii}.result{2}.usAmpGMM, ee{ii}.result{3}.usAmpGMM);
                    str=sprintf('%s\nNeues Ergebnis (optimiert, Exz=0): greedyOnline: %3.3f gmm    GlobalBest: %3.3f gmm\n', str, s.result{2}.usAmpGMM, s.result{3}.usAmpGMM);
                    resO{ii}.bmc=bmc;
                    resO{ii}.s=s;
                    resO{ii}.bmcOle=ee{ii};
                end
                fprintf('%s',str);
                %%
                str='';
                resO={};
                for ii=1:length(ee)
                    bmc=BenchmarkController(ee{ii}.discPart.entityName);
                    bmc.loadOptimization(ee{ii}.entityName);
                    s=bmc.exportToStruct();
                    str=sprintf('%s\n=Entity %s ===============', str, ee{ii}.entityName);
                    str=sprintf('%s\nAltes Ergebnis (geladen, mit Exz): greedyOnline: %3.3f gmm    GlobalBest: %3.3f gmm', str, ee{ii}.result{2}.usAmpGMM, ee{ii}.result{3}.usAmpGMM);
                    str=sprintf('%s\n Neues Ergebnis (alte Pos, Exz=0): greedyOnline: %3.3f gmm    GlobalBest: %3.3f gmm\n', str, s.result{2}.usAmpGMM, s.result{3}.usAmpGMM);
                    resO{ii}.bmc=bmc;
                    resO{ii}.s=s;
                    resO{ii}.bmcOle=ee{ii};
                end
                fprintf('%s',str);
                
                
                % =Entity mmBenchM_1OJXE67ZOM ===============
                % Altes Ergebnis (geladen, mit Exz): greedyOnline: 11.036 gmm    GlobalBest: 1.451 gmm
                %  Neues Ergebnis (alte Pos, Exz=0): greedyOnline: 10.502 gmm    GlobalBest: 0.708 gmm
                % Neues Ergebnis (optimiert, Exz=0): greedyOnline: 10.508 gmm    GlobalBest: 0.708 gmm
                % 
                % 
                % =Entity mmBenchM_1OJXE6K58K ===============
                % Altes Ergebnis (geladen, mit Exz): greedyOnline: 2.237 gmm    GlobalBest: 0.823 gmm
                %  Neues Ergebnis (alte Pos, Exz=0): greedyOnline: 3.086 gmm    GlobalBest: 1.590 gmm
                % Neues Ergebnis (optimiert, Exz=0): greedyOnline: 3.086 gmm    GlobalBest: 1.393 gmm
                % 
                % =Entity mmBenchM_1OJXE6T8NH ===============
                % Altes Ergebnis (geladen, mit Exz): greedyOnline: 2.956 gmm    GlobalBest: 0.035 gmm
                %  Neues Ergebnis (alte Pos, Exz=0): greedyOnline: 3.552 gmm    GlobalBest: 1.182 gmm
                % Neues Ergebnis (optimiert, Exz=0): greedyOnline: 2.896 gmm    GlobalBest: 0.243 gmm
                % 
                % =Entity mmBenchM_1OJXE75JLX ===============
                % Altes Ergebnis (geladen, mit Exz): greedyOnline: 9.283 gmm    GlobalBest: 1.797 gmm
                %  Neues Ergebnis (alte Pos, Exz=0): greedyOnline: 9.808 gmm    GlobalBest: 2.416 gmm
                % Neues Ergebnis (optimiert, Exz=0): greedyOnline: 9.808 gmm    GlobalBest: 2.272 gmm
                % 
                % =Entity mmBenchM_1OJXE9UKCI ===============  
                % Altes Ergebnis (geladen, mit Exz): greedyOnline: 9.248 gmm    GlobalBest: 1.689 gmm
                %  Neues Ergebnis (alte Pos, Exz=0): greedyOnline: 7.933 gmm    GlobalBest: 0.430 gmm
                % Neues Ergebnis (optimiert, Exz=0): greedyOnline: 7.933 gmm    GlobalBest: 0.393 gmm
                % 
                % =Entity mmBenchM_1OJXEA4XAK =============== 
                % Altes Ergebnis (geladen, mit Exz): greedyOnline: 16.461 gmm    GlobalBest: 14.563 gmm
                %  Neues Ergebnis (alte Pos, Exz=0): greedyOnline: 14.429 gmm    GlobalBest: 12.314 gmm
                % Neues Ergebnis (optimiert, Exz=0): greedyOnline: 14.429 gmm    GlobalBest: 12.229 gmm
                % 
                % =Entity mmBenchM_1OJXEAEY2S =============== 
                % Altes Ergebnis (geladen, mit Exz): greedyOnline: 18.050 gmm    GlobalBest: 17.494 gmm
                %  Neues Ergebnis (alte Pos, Exz=0): greedyOnline: 15.881 gmm    GlobalBest: 15.534 gmm
                % Neues Ergebnis (optimiert, Exz=0): greedyOnline: 15.930 gmm    GlobalBest: 15.438 gmm
                % 
                % =Entity mmBenchM_1OJXEAYIAK =============== 
                % Altes Ergebnis (geladen, mit Exz): greedyOnline: 17.588 gmm    GlobalBest: 15.711 gmm
                %  Neues Ergebnis (alte Pos, Exz=0): greedyOnline: 15.884 gmm    GlobalBest: 13.957 gmm
                % Neues Ergebnis (optimiert, Exz=0): greedyOnline: 15.884 gmm    GlobalBest: 13.957 gmm
                % 
                % =Entity mmBenchM_1OJXEB5J1D =============== 
                % Altes Ergebnis (geladen, mit Exz): greedyOnline: 11.177 gmm    GlobalBest: 7.382 gmm
                %  Neues Ergebnis (alte Pos, Exz=0): greedyOnline: 9.490 gmm    GlobalBest: 6.022 gmm
                % Neues Ergebnis (optimiert, Exz=0): greedyOnline: 9.490 gmm    GlobalBest: 5.842 gmm
                % 
                % =Entity mmBenchM_1OJXEBDS47 =============== 
                % Altes Ergebnis (geladen, mit Exz): greedyOnline: 17.714 gmm    GlobalBest: 13.354 gmm
                %  Neues Ergebnis (alte Pos, Exz=0): greedyOnline: 15.721 gmm    GlobalBest: 11.334 gmm
                % Neues Ergebnis (optimiert, Exz=0): greedyOnline: 15.721 gmm    GlobalBest: 11.334 gmm
            end
        end
    end
    
end
