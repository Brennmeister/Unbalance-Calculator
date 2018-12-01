function h=addVertHist(hLine,numBins, normHistHeight, xPosHist)
%% Adds a vertical histogram to the plot
% hLine: Array of Line-Handles to which the vertical Histogram is
% added. Entities of hLine must all have the same Parent!
% numBins: Number of bins to create. Leave empty for automatic
% determination of good number
if ~exist('normHistHeight', 'var')
	normHistHeight = 0.2;
end
if ~exist('xPosHist', 'var')
	xPosHist = [];
end
parenAxes = get(hLine(1),'Parent');
axes(parenAxes); % Activate the parent Axes
% Set the y-limits
xLimCur = xlim();
xlim([xLimCur(1), xLimCur(2)+normHistHeight]);

for numLine = 1:length(hLine)
	y=get(hLine(numLine),'YData');
	x=get(hLine(numLine),'XData');
	if exist('numBins','var') && ~isempty(numBins)
		[counts,bins] = hist(y,numBins);
	else
		[counts,bins] = hist(y);
	end
	
	% ymin = bins(1)-(bins(2)-bins(1))/2;
	% ymax = bins(end)+(bins(2)-bins(1))/2;
	binw=(bins(2)-bins(1));
	yy = zeros(1,length(bins)*2+2);
	xx = zeros(1,length(bins)*2+2);
	countSF = 1/max(counts)*normHistHeight;
	for ii=1:length(bins)
		yy(ii*2) = bins(ii)-binw/2;
		yy(ii*2+1) = bins(ii)+binw/2;
		xx(ii*2) = counts(ii)*countSF;
		xx(ii*2+1) = counts(ii)*countSF;
	end
	yy(1) = yy(2);
	yy(end) = yy(end-1);
	xx(1) = 0;
	xx(end)=0;
	if isempty(xPosHist)
		xx = xx+x(1);
	else
		xx = xx+xPosHist;
	end
	
	yLimOld = ylim;
	h.patch(numLine) = patch(xx,yy,zeros(size(xx))-0.1, [176 226 255]/255);
	set(h.patch(numLine),'EdgeColor',[135 206 250]/255);
	ylim(yLimOld); % Workaround, needed to get correct Label positions back!
end
end