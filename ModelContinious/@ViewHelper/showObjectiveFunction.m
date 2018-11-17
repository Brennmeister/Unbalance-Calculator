function showObjectiveFunction( obj, of, u )
%SHOWOBJECTIVEFUNCTION Plots the Area for the objective function

h.fig = figure;
h.ax = axes;
% Set the Colormap
cm=colormap('parula');
% Plot the Surrounding Border
h.plt = plot([of.polyBounds(1,:), of.polyBounds(1,1)], [of.polyBounds(2,:), of.polyBounds(2,1)], 'LineWidth', 1, 'Color', [0 0 0]);
hold(h.ax,'on');
% Calculate the Objective Value for the given unbalance Vector and store it
if ~exist('u','var')
	u= [1 0 0 0 0 0; 1 0 0 1 0 0 ; -1 0 0 1 0 0; 0 -5 0 0 5 0; 0 5 0 0 5 0]*1e-6;
end

if exist('u','var')
	for ii =1:size(u,1)
		[ratingValue, inRange, valueX, valueY] = of.rateUnbalance(u(ii,:));
		scatter(valueX, valueY, 30, ratingValue, 'filled');
		text(valueX+0.2e-6, valueY+0.2e-6, sprintf('Obj. Value: %3.3fe-6', ratingValue*1e6));
	end
end
end

