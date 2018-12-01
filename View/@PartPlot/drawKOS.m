function [m] = drawKOS(obj,kos,col, scaleArrowLength)

% Set default Color Index to 1
if ~exist('col','var')
    col=1;
end

% Set default arrowLength to 1
if ~exist('scaleArrowLength','var')
    scaleArrowLength=1;
end

Rota= kos.getGlobalRotm;
origin= kos.getGlobalPosition;
%text= kos.description;

% Calculate Rotation
Rots1=Rota*[1, 0, 0]';
Rots2=Rota*[0, 1, 0]';
Rots3=Rota*[0, 0, 1]';

% Calculate Points for KS
P1=origin;
P2=origin+Rots1';
P4=origin+Rots2';
P6=origin+Rots3';

% Normalize Length and scale it
P2s = P1+(P2-P1)./norm((P2-P1)).*scaleArrowLength;
P4s = P1+(P4-P1)./norm((P4-P1)).*scaleArrowLength;
P6s = P1+(P6-P1)./norm((P6-P1)).*scaleArrowLength;

% Plot Arrows and store handles
m(1,1) = obj.Arrows(P1, P2s, 'color',obj.arrowColor{col}(1,:), 'stemWidth', obj.arrowStemWidth, 'tipWidth', obj.arrowTipWidth);
m(1,2) = obj.Arrows(P1, P4s, 'color',obj.arrowColor{col}(2,:), 'stemWidth', obj.arrowStemWidth, 'tipWidth', obj.arrowTipWidth);
m(1,3) = obj.Arrows(P1, P6s, 'color',obj.arrowColor{col}(3,:), 'stemWidth', obj.arrowStemWidth, 'tipWidth', obj.arrowTipWidth);

% Plot Arrow Labels
if obj.drawAxisName
    text(obj.axes, P2s(1), P2s(2), P2s(3), 'X', 'HorizontalAlignment', 'left', 'FontSize', 8)
    text(obj.axes, P4s(1), P4s(2), P4s(3), 'Y', 'HorizontalAlignment', 'left', 'FontSize', 8)
    text(obj.axes, P6s(1), P6s(2), P6s(3), 'Z', 'HorizontalAlignment', 'left', 'FontSize', 8)
end
end