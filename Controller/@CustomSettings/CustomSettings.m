classdef CustomSettings < handle
    %CUSTOMSETTINGS Stores costom settings
    %   Created by: Manuel
    %	Created on: 2018-08-20
    
    properties
		% vv Used for discrete model and Unbalance Estimation -------------------------------------
        algNameDiscAssembly;
        algFcnNameDiscAssembly;
        algNameShaftAssembly;
        algFcnNameShaftAssembly;
        msgDBG; % Debug-Level
        magPolarizationFlag; % true or false
        writeResultDB; % enable or disable to write the results in database after statistical analysis 
        
        % Magnet TODO-C: Add class geometry to store default values.
        magLength;	% [m]
        magWidth;	% [m]
        magHeight;	% [m]
		
        
        % RotorDisc TODO-C: Add class geometry to store default values.
        discR; % distance between the center of the rotor disc and the mounting surface for the magnets [m]
        discInnerDia; % [m]
        discOuterDia; % [m]
        discLength; % [m]
        
        maxMagNum;
        extraMagNum;
        magMountingPlaceOriginAngle;
        magMountingPlaceOriginRPZ;
        
        % Shaft
        shaftDiameter; % [m]
        shaftLength; %  [m]
        
        maxDiscNum;
        discMountingPlaceOrigin;
        balancingPlaneOrigin; % balancing plane 1 and plane 2 
		
		% Rotation axis; Defined and applied to all created parts as copy
		% NOT AS INSTANCE
		rotAxRXYZ = [0 0 1]; % Richtungsvektor, trivialer Fall: Richtung z-Achse
		
		runGUI; % Defines if the GUI is created at startup [bool]
        % ^^ Used for discrete model and Unbalance Estimation -------------------------------------
		
		% vv Used for continious model ------------------------------------------------------------
		
		% ^^ Used for continious model ------------------------------------------------------------
    end
    
    methods
        function obj = CustomSettings()
            obj.algNameDiscAssembly = {'no optimization';...
                'complete enumeration';...
                'genetic algorithm';...
                'random search';...
                'greedy algorithm';...
                'pairwise exchange';...
                'differencing algorithm';...
                'consensus greedy online';...
                'consensus GA online';...
                'greedy online';...
                'greedy2 online';...
                'greedy4 online';...
                'greedy5 online'};
            
            obj.algFcnNameDiscAssembly = {'ALG_random';...
                'ALG_Enumeration';...
                'ALG_GA';...
                'ALG_random_search';...
                'ALG_greedy';...
                'ALG_pairwiseExchange';...
                'ALG_differencing';...
                'ALG_Consensus_greedy_online';...
                'ALG_Consensus_GA_online';...
                'ALG_greedy_online';...
                'ALG_greedy_version2_online';...
                'ALG_greedy_version4_online';...
                'ALG_greedy_version5_online'};
            
            obj.algNameShaftAssembly =  {'no optimization';...
                                         'Genetic Algorithm';...
                                         'Genetic Algorithm 2';...
                                         'greedy online'};
            
            obj.algFcnNameShaftAssembly = {'ALG_random_shaft';...
                                           'ALG_GA_shaft';...
                                           'ALG_GA2_shaft';...
                                           'ALG_greedy_online_shaft'};
                                       
            obj.msgDBG = 0;
            obj.writeResultDB = 0; % enable or disable to write the results in database after statistical analysis
                                   % if writeResultDB = 1, enable to write the result in the database (discAssembly)
                                   % if writeResultDB = 2, enable to write the result in the database (shaftAssembly)
                                   
            obj.magPolarizationFlag = true;
            
            % Magnet
             obj.magLength   = 30.*1e-3; % [m]
             obj.magWidth    = 20.*1e-3; % [m]
             obj.magHeight   = 5.*1e-3; % [m]
            
            % RotorDisc
            obj.discR = 40.*1e-3;            % distance between the center of the rotor disc and the mounting surface for the magnets [m]
            obj.discInnerDia = 35.*1e-3; % [m]
            obj.discOuterDia = 90.*1e-3; % [m]
            obj.discLength   = 30.*1e-3; % [m]
            
            obj.maxMagNum = 12;
            obj.extraMagNum = 1;
            
            obj.magMountingPlaceOriginAngle = 0: 2*pi/obj.maxMagNum : (2*pi-2*pi/obj.maxMagNum); % [rad]       
            obj.magMountingPlaceOriginRPZ = [ones(obj.maxMagNum,1).* obj.discOuterDia/2 , [0:obj.maxMagNum-1]'.* 2*pi/obj.maxMagNum , zeros(obj.maxMagNum,1) ];
%           obj.maxMagNum = 12;
%           obj.magMountingPlaceORiginAngle = [ 0: 2*pi/12 :(2*pi-2*pi/12)]; % [rad] 
%           obj.magMountingPlaceOriginRPZ = [90.*1e-3/2 2*pi/12*0  0;
%                                              90.*1e-3/2 2*pi/12*1  0;
%                                              90.*1e-3/2 2*pi/12*2  0;
%                                              90.*1e-3/2 2*pi/12*3  0;
%                                              90.*1e-3/2 2*pi/12*4  0;
%                                              90.*1e-3/2 2*pi/12*5  0;
%                                              90.*1e-3/2 2*pi/12*6  0;
%                                              90.*1e-3/2 2*pi/12*7  0;
%                                              90.*1e-3/2 2*pi/12*8  0;
%                                              90.*1e-3/2 2*pi/12*9  0;
%                                              90.*1e-3/2 2*pi/12*10 0;
%                                              90.*1e-3/2 2*pi/12*11 0]; % in r-phi-z coordinate-system [m]
            
            % Shaft
            obj.shaftDiameter = 35*1e-3 ; % [m]
            obj.shaftLength = 360*1e-3 ; %  [m]
            
            obj.maxDiscNum = 8;
            obj.discMountingPlaceOrigin = [0 0 60; ...
                                           0 0 90; ...
                                           0 0 120;...
                                           0 0 150;...
                                           0 0 180;...
                                           0 0 210;...
                                           0 0 240;...
                                           0 0 270;...
                                           ].*1e-3; % [m]
            obj.balancingPlaneOrigin = [60 , 300] .* 1e-3; % balancing plane 1 and plane 2 
            
			obj.runGUI = true; % Run GUI by default
        end
        
        
    end
    
end

