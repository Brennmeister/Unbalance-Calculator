classdef Part < handle
    %PART Stellt ein Bauteil dar
    %   Detailed explanation goes here
    
    properties
        description='Part'				% String to describe the current AssemblySet
        dbg=false						% if true: print debug-info
        parent      = []				% Links to the parent element
        mass							% [kg]	Mass of the Part
        dens        = []                % [kg/m³] density of part. If dens is set, it will be used to calculate the mass
        vol                             % [m^3] volume of primitive
        j       						% [kg m²] Trägheitstensor, 3x3, im lokalen, Hauptachsensystem des Parts
        initialU	= [ 0 0 0 ]			% [kg m] initial unbalance vector. initialU is added to the calculated one
        primitive						% struct with Informations of the primitive used to calculate inertia
        typeID							% ID to describe the Part type, e.g. ProjectX_magnet, ProjectX_disc, ProjectX_shaft
        entityName						% Name of the Part in the Databas - if loaded from there or if inserted in DB
        tag                             % The unique identifyer of a part
        counter                         % Added by DO to count Part Number
        autoUpdate = true               % Update the part every time the unbalance is calculated
    end
    properties(SetAccess	= 'protected')
        origin		= [0 0 0];		% [m] Ursprung. Muss immer [0 0 0] sein.
        orientation	= [1 0 0 0];	% [-] Orientierung des Teils. Muss immer [1 0 0 0] sein.  1:3=> Normalenvektor 4: Drehung um diese Achse
        cog         = [0 0 0];      % [m] Center of gravity. required if coordinate system of part is not set into the center of gravity, e.g. for primitive cutcylinder
        uuid                        % uuid for object identifications
    end
    
    methods
        %% Create Object with Constructor
        function obj = Part(description)
            obj.description = description;
            obj.uuid = char(java.util.UUID.randomUUID.toString());
        end
        %% Position in local coordinates
        function pos = getChildsPosition(obj)
            pos = obj.origin;
        end
        %% Position in global coordinates
        % global coordinates = from topmost assembly
        function pos = getGlobalPosition(obj)
            pos = obj.parent.getGlobalPosition()+ (obj.parent.getGlobalRotm()*obj.origin')';
        end
        %% Center of Gravity in global coordinates
        % global coordinates = from topmost assembly
        function cog = getGlobalCOG(obj)
            cog = obj.parent.getGlobalPosition()+ (obj.parent.getGlobalRotm()*(obj.origin+obj.cog)')';
        end
        %% Global Rotation matrix
        function rotm = getGlobalRotm(obj)
            rotm = obj.parent.getGlobalRotm();
        end
        %% Global Euler Angles
        % The Euler Angels are given in the rotation order z-y-x
        function eul = getGlobalEulerAngles(obj)
            eul = rotm2eul(obj.getGlobalRotm,'zyx');
        end
        %% Calculates the unbalance Vector
        % The position of the current object is used in global coordinates
        % The equation to calculate the unbalance vector was calculated in
        % maple. It depends on the center of gravity, the rotation along
        % the axis, the mass and the balancing planes.
        %
        % INPUT
        %	planeA, planeB
        %		The Position of the two Planes in which the unbalance
        %		vector will be calculated.
        % OUTPUT
        %	uGlobal
        %		3x2 Matrix with the unbalance Vectors
        function uGlobal = getUGlobal(obj, planeA, planeB)
            % Update the Part to get correct inertia Values
            if obj.autoUpdate
                obj.update();
            end
            % Get needed Variables
            eul = obj.getGlobalEulerAngles;
            alpha_z = eul(1);
            alpha_y = eul(2);
            alpha_x = eul(3);
            
            j=obj.j; % Die Maple-Formel berücksichtigt bereits alle Drehungen für einen allg. Trägheitstensor
            mass=obj.mass;
            sp = obj.getGlobalCOG;
            if false
                %% Equation from Maple
                % Be careful: The deviation moments J[Pxy], J[Pxz] are
                % implemented as the absolute value (without sign because it is
                % always negative). siehe Script Uni Siegen und Maple
                % String aus Maple exportieren: convert(U_[A], 'string')
                % stra='Vector(3, [0,((-4*cos(alpha[x])^2*sin(alpha[y])*J[Pyz]+(-2*cos(alpha[y])*J[Pxy]+2*sin(alpha[y])*(J[Py]-J[Pz])*sin(alpha[x]))*cos(alpha[x])+2*cos(alpha[y])*J[Pxz]*sin(alpha[x])+2*sin(alpha[y])*J[Pyz])*cos(alpha[z])^2-2*(-1/2*(cos(alpha[y])^2-2)*(J[Py]-J[Pz])*cos(alpha[x])^2+(-J[Pyz]*cos(alpha[y])^2*sin(alpha[x])+cos(alpha[y])*sin(alpha[y])*J[Pxz]+2*J[Pyz]*sin(alpha[x]))*cos(alpha[x])+(-1/2*J[Px]+1/2*J[Py])*cos(alpha[y])^2+sin(alpha[y])*cos(alpha[y])*sin(alpha[x])*J[Pxy]-1/2*J[Py]+1/2*J[Pz])*sin(alpha[z])*cos(alpha[z])+2*cos(alpha[x])^2*sin(alpha[y])*J[Pyz]+(-sin(alpha[y])*(J[Py]-J[Pz])*sin(alpha[x])+cos(alpha[y])*J[Pxy])*cos(alpha[x])-cos(alpha[y])*J[Pxz]*sin(alpha[x])-sin(alpha[y])*J[Pyz]+m*S[yK]*(L[Bx]-S[xK]))/(L[Ax]-L[Bx]),(-2*cos(alpha[z])*(sin(alpha[x])*J[Pxy]+J[Pxz]*cos(alpha[x]))*cos(alpha[y])^2+((-sin(alpha[y])*(J[Py]-J[Pz])*cos(alpha[z])+2*sin(alpha[z])*J[Pyz])*cos(alpha[x])^2-2*(cos(alpha[z])*sin(alpha[y])*J[Pyz]+1/2*sin(alpha[z])*(J[Py]-J[Pz]))*sin(alpha[x])*cos(alpha[x])-sin(alpha[y])*(J[Px]-J[Py])*cos(alpha[z])-sin(alpha[z])*J[Pyz])*cos(alpha[y])+(-sin(alpha[y])*sin(alpha[z])*J[Pxy]+cos(alpha[z])*J[Pxz])*cos(alpha[x])+sin(alpha[x])*cos(alpha[z])*J[Pxy]+sin(alpha[y])*sin(alpha[x])*sin(alpha[z])*J[Pxz]+m*S[zK]*(L[Bx]-S[xK]))/(L[Ax]-L[Bx])])';
                % strb='Vector(3, [0,((4*cos(alpha[x])^2*sin(alpha[y])*J[Pyz]+(2*cos(alpha[y])*J[Pxy]-2*sin(alpha[y])*(J[Py]-J[Pz])*sin(alpha[x]))*cos(alpha[x])-2*cos(alpha[y])*J[Pxz]*sin(alpha[x])-2*sin(alpha[y])*J[Pyz])*cos(alpha[z])^2+2*(-1/2*(cos(alpha[y])^2-2)*(J[Py]-J[Pz])*cos(alpha[x])^2+(-J[Pyz]*cos(alpha[y])^2*sin(alpha[x])+cos(alpha[y])*sin(alpha[y])*J[Pxz]+2*J[Pyz]*sin(alpha[x]))*cos(alpha[x])+(-1/2*J[Px]+1/2*J[Py])*cos(alpha[y])^2+sin(alpha[y])*cos(alpha[y])*sin(alpha[x])*J[Pxy]-1/2*J[Py]+1/2*J[Pz])*sin(alpha[z])*cos(alpha[z])-2*cos(alpha[x])^2*sin(alpha[y])*J[Pyz]+(sin(alpha[y])*(J[Py]-J[Pz])*sin(alpha[x])-cos(alpha[y])*J[Pxy])*cos(alpha[x])+cos(alpha[y])*J[Pxz]*sin(alpha[x])+sin(alpha[y])*J[Pyz]-m*S[yK]*(L[Ax]-S[xK]))/(L[Ax]-L[Bx]),(2*cos(alpha[z])*(sin(alpha[x])*J[Pxy]+J[Pxz]*cos(alpha[x]))*cos(alpha[y])^2+((sin(alpha[y])*(J[Py]-J[Pz])*cos(alpha[z])-2*sin(alpha[z])*J[Pyz])*cos(alpha[x])^2+2*(cos(alpha[z])*sin(alpha[y])*J[Pyz]+1/2*sin(alpha[z])*(J[Py]-J[Pz]))*sin(alpha[x])*cos(alpha[x])+sin(alpha[y])*(J[Px]-J[Py])*cos(alpha[z])+sin(alpha[z])*J[Pyz])*cos(alpha[y])+(sin(alpha[y])*sin(alpha[z])*J[Pxy]-cos(alpha[z])*J[Pxz])*cos(alpha[x])-sin(alpha[x])*cos(alpha[z])*J[Pxy]-sin(alpha[y])*sin(alpha[x])*sin(alpha[z])*J[Pxz]-m*S[zK]*(L[Ax]-S[xK]))/(L[Ax]-L[Bx])])';
                %
                % Neue Werte für stra, strb vom 12.01.2017. Es gab
                % Abweichungen zwischen den Formeln in Matlab und den in
                % Maple. Die Ursache ist mir jedoch nicht klar.
                % v1, 12.01.2017
                % stra='Vector(3, [0,((-4*cos(alpha[x])^2*sin(alpha[y])*J[Pyz]+(-2*cos(alpha[y])*J[Pxy]+2*sin(alpha[y])*(J[Py]-J[Pz])*sin(alpha[x]))*cos(alpha[x])+2*cos(alpha[y])*J[Pxz]*sin(alpha[x])+2*sin(alpha[y])*J[Pyz])*cos(alpha[z])^2-2*sin(alpha[z])*(-1/2*(cos(alpha[y])^2-2)*(J[Py]-J[Pz])*cos(alpha[x])^2+(-J[Pyz]*cos(alpha[y])^2*sin(alpha[x])+cos(alpha[y])*sin(alpha[y])*J[Pxz]+2*J[Pyz]*sin(alpha[x]))*cos(alpha[x])+(-1/2*J[Px]+1/2*J[Py])*cos(alpha[y])^2+sin(alpha[y])*cos(alpha[y])*sin(alpha[x])*J[Pxy]-1/2*J[Py]+1/2*J[Pz])*cos(alpha[z])+2*cos(alpha[x])^2*sin(alpha[y])*J[Pyz]+(-sin(alpha[y])*(J[Py]-J[Pz])*sin(alpha[x])+cos(alpha[y])*J[Pxy])*cos(alpha[x])-cos(alpha[y])*J[Pxz]*sin(alpha[x])-sin(alpha[y])*J[Pyz]+m*S[yK]*(L[Bx]-S[xK]))/(L[Ax]-L[Bx]),(-2*cos(alpha[z])*(sin(alpha[x])*J[Pxy]+J[Pxz]*cos(alpha[x]))*cos(alpha[y])^2+((-sin(alpha[y])*(J[Py]-J[Pz])*cos(alpha[z])+2*sin(alpha[z])*J[Pyz])*cos(alpha[x])^2-2*(cos(alpha[z])*sin(alpha[y])*J[Pyz]+1/2*sin(alpha[z])*(J[Py]-J[Pz]))*sin(alpha[x])*cos(alpha[x])-sin(alpha[y])*(J[Px]-J[Py])*cos(alpha[z])-sin(alpha[z])*J[Pyz])*cos(alpha[y])+(-sin(alpha[y])*sin(alpha[z])*J[Pxy]+cos(alpha[z])*J[Pxz])*cos(alpha[x])+cos(alpha[z])*sin(alpha[x])*J[Pxy]+sin(alpha[z])*sin(alpha[y])*sin(alpha[x])*J[Pxz]+m*S[zK]*(L[Bx]-S[xK]))/(L[Ax]-L[Bx])])';
                % strb='Vector(3, [0,((4*cos(alpha[x])^2*sin(alpha[y])*J[Pyz]+(2*cos(alpha[y])*J[Pxy]-2*sin(alpha[y])*(J[Py]-J[Pz])*sin(alpha[x]))*cos(alpha[x])-2*cos(alpha[y])*J[Pxz]*sin(alpha[x])-2*sin(alpha[y])*J[Pyz])*cos(alpha[z])^2+2*sin(alpha[z])*(-1/2*(cos(alpha[y])^2-2)*(J[Py]-J[Pz])*cos(alpha[x])^2+(-J[Pyz]*cos(alpha[y])^2*sin(alpha[x])+cos(alpha[y])*sin(alpha[y])*J[Pxz]+2*J[Pyz]*sin(alpha[x]))*cos(alpha[x])+(-1/2*J[Px]+1/2*J[Py])*cos(alpha[y])^2+sin(alpha[y])*cos(alpha[y])*sin(alpha[x])*J[Pxy]-1/2*J[Py]+1/2*J[Pz])*cos(alpha[z])-2*cos(alpha[x])^2*sin(alpha[y])*J[Pyz]+(sin(alpha[y])*(J[Py]-J[Pz])*sin(alpha[x])-cos(alpha[y])*J[Pxy])*cos(alpha[x])+cos(alpha[y])*J[Pxz]*sin(alpha[x])+sin(alpha[y])*J[Pyz]-m*S[yK]*(L[Ax]-S[xK]))/(L[Ax]-L[Bx]),(2*cos(alpha[z])*(sin(alpha[x])*J[Pxy]+J[Pxz]*cos(alpha[x]))*cos(alpha[y])^2+((sin(alpha[y])*(J[Py]-J[Pz])*cos(alpha[z])-2*sin(alpha[z])*J[Pyz])*cos(alpha[x])^2+2*(cos(alpha[z])*sin(alpha[y])*J[Pyz]+1/2*sin(alpha[z])*(J[Py]-J[Pz]))*sin(alpha[x])*cos(alpha[x])+sin(alpha[y])*(J[Px]-J[Py])*cos(alpha[z])+sin(alpha[z])*J[Pyz])*cos(alpha[y])+(sin(alpha[y])*sin(alpha[z])*J[Pxy]-cos(alpha[z])*J[Pxz])*cos(alpha[x])-cos(alpha[z])*sin(alpha[x])*J[Pxy]-sin(alpha[z])*sin(alpha[y])*sin(alpha[x])*J[Pxz]-m*S[zK]*(L[Ax]-S[xK]))/(L[Ax]-L[Bx])])';
                
                % Neue Werte für Unwucht in Ebene A und B.
                % Berechnet für Drehmatrix R[zyx] := R[z].R[y].R[x]
                % v2, 16.05.2017
                stra='Vector(3, [0,((-4*cos(alpha[x])^2*sin(alpha[y])*J[Pyz]+(-2*cos(alpha[y])*J[Pxy]+2*sin(alpha[y])*(J[Py]-J[Pz])*sin(alpha[x]))*cos(alpha[x])+2*cos(alpha[y])*J[Pxz]*sin(alpha[x])+2*sin(alpha[y])*J[Pyz])*cos(alpha[z])^2-2*sin(alpha[z])*(-1/2*(cos(alpha[y])^2-2)*(J[Py]-J[Pz])*cos(alpha[x])^2+(-J[Pyz]*cos(alpha[y])^2*sin(alpha[x])+cos(alpha[y])*sin(alpha[y])*J[Pxz]+2*J[Pyz]*sin(alpha[x]))*cos(alpha[x])+(-1/2*J[Px]+1/2*J[Py])*cos(alpha[y])^2+sin(alpha[y])*cos(alpha[y])*sin(alpha[x])*J[Pxy]-1/2*J[Py]+1/2*J[Pz])*cos(alpha[z])+2*cos(alpha[x])^2*sin(alpha[y])*J[Pyz]+(-sin(alpha[y])*(J[Py]-J[Pz])*sin(alpha[x])+cos(alpha[y])*J[Pxy])*cos(alpha[x])-cos(alpha[y])*J[Pxz]*sin(alpha[x])-sin(alpha[y])*J[Pyz]+m*S[yK]*(L[Bx]-S[xK]))/(L[Ax]-L[Bx]),(-2*cos(alpha[z])*(sin(alpha[x])*J[Pxy]+J[Pxz]*cos(alpha[x]))*cos(alpha[y])^2+((-sin(alpha[y])*(J[Py]-J[Pz])*cos(alpha[z])+2*sin(alpha[z])*J[Pyz])*cos(alpha[x])^2-(2*cos(alpha[z])*sin(alpha[y])*J[Pyz]+sin(alpha[z])*(J[Py]-J[Pz]))*sin(alpha[x])*cos(alpha[x])-sin(alpha[y])*(J[Px]-J[Py])*cos(alpha[z])-sin(alpha[z])*J[Pyz])*cos(alpha[y])+(-sin(alpha[y])*sin(alpha[z])*J[Pxy]+cos(alpha[z])*J[Pxz])*cos(alpha[x])+sin(alpha[x])*cos(alpha[z])*J[Pxy]+sin(alpha[y])*sin(alpha[x])*sin(alpha[z])*J[Pxz]+m*S[zK]*(L[Bx]-S[xK]))/(L[Ax]-L[Bx])])';
                strb='Vector(3, [0,((4*cos(alpha[x])^2*sin(alpha[y])*J[Pyz]+(2*cos(alpha[y])*J[Pxy]-2*sin(alpha[y])*(J[Py]-J[Pz])*sin(alpha[x]))*cos(alpha[x])-2*cos(alpha[y])*J[Pxz]*sin(alpha[x])-2*sin(alpha[y])*J[Pyz])*cos(alpha[z])^2+2*sin(alpha[z])*(-1/2*(cos(alpha[y])^2-2)*(J[Py]-J[Pz])*cos(alpha[x])^2+(-J[Pyz]*cos(alpha[y])^2*sin(alpha[x])+cos(alpha[y])*sin(alpha[y])*J[Pxz]+2*J[Pyz]*sin(alpha[x]))*cos(alpha[x])+(-1/2*J[Px]+1/2*J[Py])*cos(alpha[y])^2+sin(alpha[y])*cos(alpha[y])*sin(alpha[x])*J[Pxy]-1/2*J[Py]+1/2*J[Pz])*cos(alpha[z])-2*cos(alpha[x])^2*sin(alpha[y])*J[Pyz]+(sin(alpha[y])*(J[Py]-J[Pz])*sin(alpha[x])-cos(alpha[y])*J[Pxy])*cos(alpha[x])+cos(alpha[y])*J[Pxz]*sin(alpha[x])+sin(alpha[y])*J[Pyz]-m*S[yK]*(L[Ax]-S[xK]))/(L[Ax]-L[Bx]),(2*cos(alpha[z])*(sin(alpha[x])*J[Pxy]+J[Pxz]*cos(alpha[x]))*cos(alpha[y])^2+((sin(alpha[y])*(J[Py]-J[Pz])*cos(alpha[z])-2*sin(alpha[z])*J[Pyz])*cos(alpha[x])^2+(2*cos(alpha[z])*sin(alpha[y])*J[Pyz]+sin(alpha[z])*(J[Py]-J[Pz]))*sin(alpha[x])*cos(alpha[x])+sin(alpha[y])*(J[Px]-J[Py])*cos(alpha[z])+sin(alpha[z])*J[Pyz])*cos(alpha[y])+(sin(alpha[y])*sin(alpha[z])*J[Pxy]-cos(alpha[z])*J[Pxz])*cos(alpha[x])-sin(alpha[x])*cos(alpha[z])*J[Pxy]-sin(alpha[y])*sin(alpha[x])*sin(alpha[z])*J[Pxz]-m*S[zK]*(L[Ax]-S[xK]))/(L[Ax]-L[Bx])])';
                
                s=strb;
                s=regexprep(s,	'alpha\[(.)\]'			, 'alpha_$1'			);
                s=regexprep(s,	'J\[Px\]'				, 'j(1,1)'			);
                s=regexprep(s,	'J\[Py\]'				, 'j(2,2)'			);
                s=regexprep(s,	'J\[Pz\]'				, 'j(3,3)'			);
                
                s=regexprep(s,	'J\[Pxy\]'				, 'j(1,2)'			);
                s=regexprep(s,	'J\[Pyx\]'				, 'j(2,1)'			);
                
                s=regexprep(s,	'J\[Pxz\]'				, 'j(1,3)'			);
                s=regexprep(s,	'J\[Pzx\]'				, 'j(3,1)'			);
                
                s=regexprep(s,	'J\[Pyz\]'				, 'j(2,3)'			);
                s=regexprep(s,	'J\[Pzy\]'				, 'j(3,2)'			);
                
                s=regexprep(s,	'L\[Ax\]'				, 'planeA'				);
                s=regexprep(s,	'L\[Bx\]'				, 'planeB'				);
                
                s=regexprep(s,	'S\[xK\]'				, 'sp(1)'		);
                s=regexprep(s,	'S\[yK\]'				, 'sp(2)'		);
                s=regexprep(s,	'S\[zK\]'				, 'sp(3)'		);
                
                s=regexprep(s,	'm'				        , 'mass'				);
                
                s=regexprep(s,	'Vector\(3, \['         , '['  );
                % 			s=regexprep(s,  ','						, '\n\t'                  );
                s=regexprep(s,  '\]\)$'                   , '];'                );
                
                fprintf('\n------\n%s\n------\n',s);
                clipboard('copy',s);
            end
            %% Matlab-Format for the Equation
            % - v0 --------------------------------------------------------
            % ua = [0,((-4*cos(alpha_x)^2*sin(alpha_y)*j(2,3)+(-2*cos(alpha_y)*j(1,2)+2*sin(alpha_y)*(j(2,2)-j(3,3))*sin(alpha_x))*cos(alpha_x)+2*cos(alpha_y)*j(1,3)*sin(alpha_x)+2*sin(alpha_y)*j(2,3))*cos(alpha_z)^2-2*(-1/2*(cos(alpha_y)^2-2)*(j(2,2)-j(3,3))*cos(alpha_x)^2+(-j(2,3)*cos(alpha_y)^2*sin(alpha_x)+cos(alpha_y)*sin(alpha_y)*j(1,3)+2*j(2,3)*sin(alpha_x))*cos(alpha_x)+(-1/2*j(1,1)+1/2*j(2,2))*cos(alpha_y)^2+sin(alpha_y)*cos(alpha_y)*sin(alpha_x)*j(1,2)-1/2*j(2,2)+1/2*j(3,3))*sin(alpha_z)*cos(alpha_z)+2*cos(alpha_x)^2*sin(alpha_y)*j(2,3)+(-sin(alpha_y)*(j(2,2)-j(3,3))*sin(alpha_x)+cos(alpha_y)*j(1,2))*cos(alpha_x)-cos(alpha_y)*j(1,3)*sin(alpha_x)-sin(alpha_y)*j(2,3)+mass*sp(2)*(planeB-sp(1)))/(planeA-planeB),(-2*cos(alpha_z)*(sin(alpha_x)*j(1,2)+j(1,3)*cos(alpha_x))*cos(alpha_y)^2+((-sin(alpha_y)*(j(2,2)-j(3,3))*cos(alpha_z)+2*sin(alpha_z)*j(2,3))*cos(alpha_x)^2-2*(cos(alpha_z)*sin(alpha_y)*j(2,3)+1/2*sin(alpha_z)*(j(2,2)-j(3,3)))*sin(alpha_x)*cos(alpha_x)-sin(alpha_y)*(j(1,1)-j(2,2))*cos(alpha_z)-sin(alpha_z)*j(2,3))*cos(alpha_y)+(-sin(alpha_y)*sin(alpha_z)*j(1,2)+cos(alpha_z)*j(1,3))*cos(alpha_x)+sin(alpha_x)*cos(alpha_z)*j(1,2)+sin(alpha_y)*sin(alpha_x)*sin(alpha_z)*j(1,3)+mass*sp(3)*(planeB-sp(1)))/(planeA-planeB)];
            % ub = [0,((4*cos(alpha_x)^2*sin(alpha_y)*j(2,3)+(2*cos(alpha_y)*j(1,2)-2*sin(alpha_y)*(j(2,2)-j(3,3))*sin(alpha_x))*cos(alpha_x)-2*cos(alpha_y)*j(1,3)*sin(alpha_x)-2*sin(alpha_y)*j(2,3))*cos(alpha_z)^2+2*(-1/2*(cos(alpha_y)^2-2)*(j(2,2)-j(3,3))*cos(alpha_x)^2+(-j(2,3)*cos(alpha_y)^2*sin(alpha_x)+cos(alpha_y)*sin(alpha_y)*j(1,3)+2*j(2,3)*sin(alpha_x))*cos(alpha_x)+(-1/2*j(1,1)+1/2*j(2,2))*cos(alpha_y)^2+sin(alpha_y)*cos(alpha_y)*sin(alpha_x)*j(1,2)-1/2*j(2,2)+1/2*j(3,3))*sin(alpha_z)*cos(alpha_z)-2*cos(alpha_x)^2*sin(alpha_y)*j(2,3)+(sin(alpha_y)*(j(2,2)-j(3,3))*sin(alpha_x)-cos(alpha_y)*j(1,2))*cos(alpha_x)+cos(alpha_y)*j(1,3)*sin(alpha_x)+sin(alpha_y)*j(2,3)-mass*sp(2)*(planeA-sp(1)))/(planeA-planeB),(2*cos(alpha_z)*(sin(alpha_x)*j(1,2)+j(1,3)*cos(alpha_x))*cos(alpha_y)^2+((sin(alpha_y)*(j(2,2)-j(3,3))*cos(alpha_z)-2*sin(alpha_z)*j(2,3))*cos(alpha_x)^2+2*(cos(alpha_z)*sin(alpha_y)*j(2,3)+1/2*sin(alpha_z)*(j(2,2)-j(3,3)))*sin(alpha_x)*cos(alpha_x)+sin(alpha_y)*(j(1,1)-j(2,2))*cos(alpha_z)+sin(alpha_z)*j(2,3))*cos(alpha_y)+(sin(alpha_y)*sin(alpha_z)*j(1,2)-cos(alpha_z)*j(1,3))*cos(alpha_x)-sin(alpha_x)*cos(alpha_z)*j(1,2)-sin(alpha_y)*sin(alpha_x)*sin(alpha_z)*j(1,3)-mass*sp(3)*(planeA-sp(1)))/(planeA-planeB)];
            
            % - v1, 12.01.2017 --------------------------------------------
            % ua = [0,((-4*cos(alpha_x)^2*sin(alpha_y)*j(2,3)+(-2*cos(alpha_y)*j(1,2)+2*sin(alpha_y)*(j(2,2)-j(3,3))*sin(alpha_x))*cos(alpha_x)+2*cos(alpha_y)*j(1,3)*sin(alpha_x)+2*sin(alpha_y)*j(2,3))*cos(alpha_z)^2-2*sin(alpha_z)*(-1/2*(cos(alpha_y)^2-2)*(j(2,2)-j(3,3))*cos(alpha_x)^2+(-j(2,3)*cos(alpha_y)^2*sin(alpha_x)+cos(alpha_y)*sin(alpha_y)*j(1,3)+2*j(2,3)*sin(alpha_x))*cos(alpha_x)+(-1/2*j(1,1)+1/2*j(2,2))*cos(alpha_y)^2+sin(alpha_y)*cos(alpha_y)*sin(alpha_x)*j(1,2)-1/2*j(2,2)+1/2*j(3,3))*cos(alpha_z)+2*cos(alpha_x)^2*sin(alpha_y)*j(2,3)+(-sin(alpha_y)*(j(2,2)-j(3,3))*sin(alpha_x)+cos(alpha_y)*j(1,2))*cos(alpha_x)-cos(alpha_y)*j(1,3)*sin(alpha_x)-sin(alpha_y)*j(2,3)+mass*sp(2)*(planeB-sp(1)))/(planeA-planeB),(-2*cos(alpha_z)*(sin(alpha_x)*j(1,2)+j(1,3)*cos(alpha_x))*cos(alpha_y)^2+((-sin(alpha_y)*(j(2,2)-j(3,3))*cos(alpha_z)+2*sin(alpha_z)*j(2,3))*cos(alpha_x)^2-2*(cos(alpha_z)*sin(alpha_y)*j(2,3)+1/2*sin(alpha_z)*(j(2,2)-j(3,3)))*sin(alpha_x)*cos(alpha_x)-sin(alpha_y)*(j(1,1)-j(2,2))*cos(alpha_z)-sin(alpha_z)*j(2,3))*cos(alpha_y)+(-sin(alpha_y)*sin(alpha_z)*j(1,2)+cos(alpha_z)*j(1,3))*cos(alpha_x)+cos(alpha_z)*sin(alpha_x)*j(1,2)+sin(alpha_z)*sin(alpha_y)*sin(alpha_x)*j(1,3)+mass*sp(3)*(planeB-sp(1)))/(planeA-planeB)];
            % ub = [0,((4*cos(alpha_x)^2*sin(alpha_y)*j(2,3)+(2*cos(alpha_y)*j(1,2)-2*sin(alpha_y)*(j(2,2)-j(3,3))*sin(alpha_x))*cos(alpha_x)-2*cos(alpha_y)*j(1,3)*sin(alpha_x)-2*sin(alpha_y)*j(2,3))*cos(alpha_z)^2+2*sin(alpha_z)*(-1/2*(cos(alpha_y)^2-2)*(j(2,2)-j(3,3))*cos(alpha_x)^2+(-j(2,3)*cos(alpha_y)^2*sin(alpha_x)+cos(alpha_y)*sin(alpha_y)*j(1,3)+2*j(2,3)*sin(alpha_x))*cos(alpha_x)+(-1/2*j(1,1)+1/2*j(2,2))*cos(alpha_y)^2+sin(alpha_y)*cos(alpha_y)*sin(alpha_x)*j(1,2)-1/2*j(2,2)+1/2*j(3,3))*cos(alpha_z)-2*cos(alpha_x)^2*sin(alpha_y)*j(2,3)+(sin(alpha_y)*(j(2,2)-j(3,3))*sin(alpha_x)-cos(alpha_y)*j(1,2))*cos(alpha_x)+cos(alpha_y)*j(1,3)*sin(alpha_x)+sin(alpha_y)*j(2,3)-mass*sp(2)*(planeA-sp(1)))/(planeA-planeB),(2*cos(alpha_z)*(sin(alpha_x)*j(1,2)+j(1,3)*cos(alpha_x))*cos(alpha_y)^2+((sin(alpha_y)*(j(2,2)-j(3,3))*cos(alpha_z)-2*sin(alpha_z)*j(2,3))*cos(alpha_x)^2+2*(cos(alpha_z)*sin(alpha_y)*j(2,3)+1/2*sin(alpha_z)*(j(2,2)-j(3,3)))*sin(alpha_x)*cos(alpha_x)+sin(alpha_y)*(j(1,1)-j(2,2))*cos(alpha_z)+sin(alpha_z)*j(2,3))*cos(alpha_y)+(sin(alpha_y)*sin(alpha_z)*j(1,2)-cos(alpha_z)*j(1,3))*cos(alpha_x)-cos(alpha_z)*sin(alpha_x)*j(1,2)-sin(alpha_z)*sin(alpha_y)*sin(alpha_x)*j(1,3)-mass*sp(3)*(planeA-sp(1)))/(planeA-planeB)];
            % Added a negative sign to get angular positions right
            % ua = -1*ua; ub = -1*ub;
            
            % - v2, 16.05.2017 --------------------------------------------
            ua = [0,((-4*cos(alpha_x)^2*sin(alpha_y)*j(2,3)+(-2*cos(alpha_y)*j(1,2)+2*sin(alpha_y)*(j(2,2)-j(3,3))*sin(alpha_x))*cos(alpha_x)+2*cos(alpha_y)*j(1,3)*sin(alpha_x)+2*sin(alpha_y)*j(2,3))*cos(alpha_z)^2-2*sin(alpha_z)*(-1/2*(cos(alpha_y)^2-2)*(j(2,2)-j(3,3))*cos(alpha_x)^2+(-j(2,3)*cos(alpha_y)^2*sin(alpha_x)+cos(alpha_y)*sin(alpha_y)*j(1,3)+2*j(2,3)*sin(alpha_x))*cos(alpha_x)+(-1/2*j(1,1)+1/2*j(2,2))*cos(alpha_y)^2+sin(alpha_y)*cos(alpha_y)*sin(alpha_x)*j(1,2)-1/2*j(2,2)+1/2*j(3,3))*cos(alpha_z)+2*cos(alpha_x)^2*sin(alpha_y)*j(2,3)+(-sin(alpha_y)*(j(2,2)-j(3,3))*sin(alpha_x)+cos(alpha_y)*j(1,2))*cos(alpha_x)-cos(alpha_y)*j(1,3)*sin(alpha_x)-sin(alpha_y)*j(2,3)+mass*sp(2)*(planeB-sp(1)))/(planeA-planeB),(-2*cos(alpha_z)*(sin(alpha_x)*j(1,2)+j(1,3)*cos(alpha_x))*cos(alpha_y)^2+((-sin(alpha_y)*(j(2,2)-j(3,3))*cos(alpha_z)+2*sin(alpha_z)*j(2,3))*cos(alpha_x)^2-(2*cos(alpha_z)*sin(alpha_y)*j(2,3)+sin(alpha_z)*(j(2,2)-j(3,3)))*sin(alpha_x)*cos(alpha_x)-sin(alpha_y)*(j(1,1)-j(2,2))*cos(alpha_z)-sin(alpha_z)*j(2,3))*cos(alpha_y)+(-sin(alpha_y)*sin(alpha_z)*j(1,2)+cos(alpha_z)*j(1,3))*cos(alpha_x)+sin(alpha_x)*cos(alpha_z)*j(1,2)+sin(alpha_y)*sin(alpha_x)*sin(alpha_z)*j(1,3)+mass*sp(3)*(planeB-sp(1)))/(planeA-planeB)];
            ub = [0,((4*cos(alpha_x)^2*sin(alpha_y)*j(2,3)+(2*cos(alpha_y)*j(1,2)-2*sin(alpha_y)*(j(2,2)-j(3,3))*sin(alpha_x))*cos(alpha_x)-2*cos(alpha_y)*j(1,3)*sin(alpha_x)-2*sin(alpha_y)*j(2,3))*cos(alpha_z)^2+2*sin(alpha_z)*(-1/2*(cos(alpha_y)^2-2)*(j(2,2)-j(3,3))*cos(alpha_x)^2+(-j(2,3)*cos(alpha_y)^2*sin(alpha_x)+cos(alpha_y)*sin(alpha_y)*j(1,3)+2*j(2,3)*sin(alpha_x))*cos(alpha_x)+(-1/2*j(1,1)+1/2*j(2,2))*cos(alpha_y)^2+sin(alpha_y)*cos(alpha_y)*sin(alpha_x)*j(1,2)-1/2*j(2,2)+1/2*j(3,3))*cos(alpha_z)-2*cos(alpha_x)^2*sin(alpha_y)*j(2,3)+(sin(alpha_y)*(j(2,2)-j(3,3))*sin(alpha_x)-cos(alpha_y)*j(1,2))*cos(alpha_x)+cos(alpha_y)*j(1,3)*sin(alpha_x)+sin(alpha_y)*j(2,3)-mass*sp(2)*(planeA-sp(1)))/(planeA-planeB),(2*cos(alpha_z)*(sin(alpha_x)*j(1,2)+j(1,3)*cos(alpha_x))*cos(alpha_y)^2+((sin(alpha_y)*(j(2,2)-j(3,3))*cos(alpha_z)-2*sin(alpha_z)*j(2,3))*cos(alpha_x)^2+(2*cos(alpha_z)*sin(alpha_y)*j(2,3)+sin(alpha_z)*(j(2,2)-j(3,3)))*sin(alpha_x)*cos(alpha_x)+sin(alpha_y)*(j(1,1)-j(2,2))*cos(alpha_z)+sin(alpha_z)*j(2,3))*cos(alpha_y)+(sin(alpha_y)*sin(alpha_z)*j(1,2)-cos(alpha_z)*j(1,3))*cos(alpha_x)-sin(alpha_x)*cos(alpha_z)*j(1,2)-sin(alpha_y)*sin(alpha_x)*sin(alpha_z)*j(1,3)-mass*sp(3)*(planeA-sp(1)))/(planeA-planeB)];
            
            ua=-ua;
            ub=-ub;
            %% Transform the initial unbalance to the current orientation
            initialUTransformed = (obj.getGlobalRotm()*obj.initialU')';
            initialUTransformed_ua = initialUTransformed * (planeB-sp(1))/(planeB-planeA);
            initialUTransformed_ub = initialUTransformed * (sp(1)-planeA)/(planeB-planeA);
            %% Debugging Information
            % fprintf('[ua ub: [%f %f %f %f %f %f]\n', [ua ub]);
            % fprintf('[initialUTransformed_ua initialUTransformed_ub: [%f %f %f %f %f %f]\n', [initialUTransformed_ua initialUTransformed_ub]);
            %% Return the unbalance
            uGlobal = [ua ub] + [initialUTransformed_ua initialUTransformed_ub];
        end
        %% Plotting the Part
        function plot(obj)
            hold on
            p=obj.getGlobalPosition();
            v=obj.getGlobalRotm();
            l=5e-3;
            vx=v*[1 0 0]'*l;
            vy=v*[0 1 0]'*l;
            vz=v*[0 0 1]'*l;
            
            plot3(     	p(1),		p(2),		p(3),		'Marker', '^', 	'MarkerFaceColor', [1 0 0],	'Color', [1 0 0], 'MarkerSize', 8);
            quiver3(	p(1),		p(2),		p(3),		vx(1),	vx(2),	vx(3),			'Color', [1 0 0], 'LineWidth', 2);
            text(		p(1)+vx(1),	p(2)+vx(2),	p(3)+vx(3),							'px', 	'Color', [1 0 0]);
            ii=2;
            quiver3(	p(1),		p(2),		p(3),		vy(1),	vy(2),	vy(3),			'Color', [0 1 0], 'LineWidth', 2);
            text(		p(1)+vy(1),	p(2)+vy(2),	p(3)+vy(3),							'py', 	'Color', [0 1 0]);
            ii=3;
            quiver3(	p(1),		p(2),		p(3),		vz(1),	vz(2),	vz(3),			'Color', [0 0 1], 'LineWidth', 2);
            text(		p(1)+vz(1),	p(2)+vz(2),	p(3)+vz(3),							'pz', 	'Color', [0 0 1]);
            
            d=-l/4;
            text(p(1)+d, p(2)+d, p(3)+d, obj.description);
            % xlabel('x'); ylabel('y'); zlabel('z');
            % axis('equal');
        end
        %% Set the Parent Assembly
        % For esier and consistent hirachy building
        function setParent(obj, p)
            if ~isempty(obj.parent)
                error('The object already has a parent. The Parent and from that parent the Child must be removed first!')
            else
                if ~isempty(p.child)
                    error('The Parent already has a Child. Having multiple Children of Class @Part is not allowed.')
                end
                obj.parent=p;
                p.child{1}=obj;
            end
        end
        %% Umset the Parent Assembly
        % For esier and consistent hirachy building
        function unsetParent(obj)
            if isempty(obj.parent)
                error('The object has no parent. The Parent can not be unset')
            else
                obj.parent.child=[];
                obj.parent=[];
            end
        end
        function setPrimitive(obj, primitiveType, varargin)
            %% Set properties for specific primitives
            % This function assumes the matrix of inertia for given geometric
            % primitives
            % Example:
            %  obj.setPrimitive('cuboid', 'length', 30e-3, 'width', 10e3, 'height', 5e-3);
            inpPa = inputParser;
            inpPa.addRequired('primitiveType',			 @(x) any(validatestring(x,{'pointmass', 'cuboid', 'cylinder', 'cutCylinder', 'cutCylinderWithBore'})));
            inpPa.addParameter('diameter',			0,	 @isnumeric);		% valide for cylinder, cutCylinder
            inpPa.addParameter('boreDiameter',		0,	 @isnumeric);		% valide for cutCylinderWithBore
            inpPa.addParameter('length',			0,	 @isnumeric);		% valide for all
            inpPa.addParameter('width',				0,	 @isnumeric);		% valide for cuboid
            inpPa.addParameter('height',			0,	 @isnumeric);		% valide for cuboid
            
            inpPa.parse(primitiveType,varargin{:})
            
            if	strcmpi(inpPa.Results.primitiveType,'pointmass')
                obj.j = zeros(3,3);
                obj.vol = 0;
                obj.cog = [0,0,0];
            elseif strcmpi(inpPa.Results.primitiveType,'cuboid')
                obj.vol = abs(inpPa.Results.width*inpPa.Results.height*inpPa.Results.length);
                obj.updateMass();
                obj.j = obj.mass/12 * [
                    inpPa.Results.width^2+inpPa.Results.height^2, 0, 0
                    0, inpPa.Results.length^2+inpPa.Results.height^2, 0
                    0, 0, inpPa.Results.width^2+inpPa.Results.length^2
                    ];
                % Check with maple:
                % fprintf('pMatlab := {l[quad_x] = %f, l[quad_y] = %f, l[quad_z] = %f, m[quader] = %f}; eval(J[quaderSH_ini], pMatlab);\n\n',inpPa.Results.mass, inpPa.Results.length, inpPa.Results.width, inpPa.Results.height);
                obj.cog = [0,0,0];
            elseif strcmpi(inpPa.Results.primitiveType,'cylinder')
                obj.vol = abs(pi*inpPa.Results.diameter^2/4*inpPa.Results.length);
                obj.updateMass();
                obj.j = obj.mass/2 * [
                    (inpPa.Results.diameter/2)^2, 0, 0
                    0, inpPa.Results.diameter^2/8 + inpPa.Results.length^2/6, 0
                    0, 0, inpPa.Results.diameter^2/8 + inpPa.Results.length^2/6
                    ];
                % Check with maple:
                % fprintf('pMatlab := {m[zylinder] = %f, d[zylinder] = %f, l[zylinder] = %f}; eval(J[zylinderSH_ini], pMatlab);\n\n',inpPa.Results.mass, inpPa.Results.diameter, inpPa.Results.length);
                obj.cog = [0,0,0];
            elseif strcmpi(inpPa.Results.primitiveType,'cutCylinderWithBore')
                R = inpPa.Results.diameter/2;
                Ri = inpPa.Results.boreDiameter/2;
                H = inpPa.Results.length;
                obj.vol = abs((pi*H*R^2-pi*Ri^2*H)/2);
                obj.updateMass();
                
                obj.j = obj.mass * [
                    (Ri^2+R^2)/2,0,-(Ri^2*H+H*R^2)/(8*R)
                    0,(3*Ri^2*H^2+(7*H^2+12*Ri^2)*R^2+12*R^4)/(48*R^2),0
                    -(Ri^2*H+H*R^2)/(8*R),0,(3*Ri^2*H^2+(7*H^2+12*Ri^2)*R^2+12*R^4)/(48*R^2)
                    ];
                obj.cog = [(Ri^2*H+5*H*R^2)/(16*R^2),0,(Ri^2+R^2)/(4*R)];
            elseif strcmpi(inpPa.Results.primitiveType,'cutCylinder')
                % this is a special case of cutCylinderWithBore with
                % boreDiameter = 0
                obj.setPrimitive('cutCylinderWithBore','diameter',inpPa.Results.diameter, 'length', inpPa.Results.length, 'boreDiameter', 0);
            end
            % Save Information about Primitve in struct
            obj.primitive = inpPa.Results;
        end
        function massUpdated = updateMass(obj)
            %% UPDATEMASS
            % Update the mass propertiy if a density was set.
            massUpdated=false;
            if ~isempty(obj.dens)
                obj.mass = obj.dens*obj.vol;
                massUpdated=true;
            end
        end
        function update(obj)
            %% Updates the Object
            % The mass given in obj.mass will be written to
            % obj.primitive.mass and the Inertia will be calculated
            % according to the already set primitive Type with the new mass
            if isprop(obj,'primitive')
                if isfield(obj.primitive,'primitiveType')
                    obj.updateByPrimitiveStruct();
                else
                    error('No primitiveType given.');
                end
            else
                error('Mass in obj.primitive.mass can not be set. obj has no property "primitive"');
            end
        end
        function updateByPrimitiveStruct(obj)
            %% Updates the inertia settings of the object by the Values stored in obj.primitive
            % This function is used to update the inertia if a different
            % mass is given for a specified primitive
            props={};
            fn = fieldnames(obj.primitive);
            for ii=1:length(fn)
                if ~strcmp('primitiveType',fn{ii})
                    props{end+1}=fn{ii};
                    props{end+1}=obj.primitive.(fn{ii});
                end
            end
            obj.setPrimitive(obj.primitive.primitiveType, props{:});
        end
        function new = copy(obj)
            %% Make a copy of this object
            % Instantiate new object of the same class.
            new = feval(class(obj), 'copy');
            % Unset the parent of the part so it is not copied
            originalParent = obj.parent;
            if ~isempty(originalParent)
                obj.unsetParent();
            end
            % Copy all non-hidden properties.
            p = properties(obj);
            for i = 1:length(p)
                new.(p{i}) = obj.(p{i});
            end
            if ~isempty(originalParent)
                % set the Parent back
                obj.setParent(originalParent);
            end
        end
    end
    
end

