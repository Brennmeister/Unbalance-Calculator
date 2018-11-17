classdef ObjectiveFunction
    %OBJECTIVEFUNCTION Class for the calculation of the objective Value
    % Function can be shown with
    % of=ObjectiveFunction; v=ViewHelper(); v.showObjectiveFunction(of);
    properties
        polyBounds				% Boundaries of a polygon for punishment Values
    end
    
    methods
        function obj = ObjectiveFunction(varargin)
            obj.polyBounds = [0, 0, 15, 20, 20; 0, 10, 10, 8, 0]*1e-4; % Currently not used
        end
        %% Methode to cacluclate the objective value
        % The objective value is calculated of the unbalance
        % Static unbalance is calculated by summing up the dynamic
        % unbalance
        function [ratingValue, inRange, valueX, valueY] = rateUnbalance(obj, u)
            uDynPlane1=u(1:3);
            uDynPlane2=u(4:6);
            
            uStat = uDynPlane1+uDynPlane2;
            
            % 			ratingValue = norm(uStat)+(norm(uDynPlane1)+norm(uDynPlane2))/2;
            ratingValue = norm(uDynPlane1)+norm(uDynPlane2)+1/2*norm(uStat); % Gewichte wie in Diss
            % 			ratingValue = 1/ratingValue; %% Von Dirk zum Testen;
            
            
            valueX = norm(uStat);
            valueY = (norm(uDynPlane1)+norm(uDynPlane2))/2;
            
            inRange=true;
            if ~inpolygon(valueX, valueY, obj.polyBounds(1,:), obj.polyBounds(2,:))
                % If the value is outside of the defined polygon: give
                % penelty and set inRange=False
                ratingValue = ratingValue*2;
                inRange = false;
            end
        end
        
        function [ratingValue, inRange, valueX, valueY] = rateUnbalanceInverse(obj, u)
            uDynPlane1=u(1:3);
            uDynPlane2=u(4:6);
            
            uStat = uDynPlane1+uDynPlane2;            
            ratingValue = norm(uDynPlane1)+norm(uDynPlane2)+1/2*norm(uStat); % Gewichte wie in Diss
            if ratingValue==0
                ratingValue=inf;
            else
                ratingValue=1/ratingValue;
            end            
        end
    end
    
end

