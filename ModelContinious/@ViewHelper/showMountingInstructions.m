function obj = showMountingInstructions( obj, m )
%SHOWMOUNTINGINSTRUCTIONS Prints a table with the Mounting steps
%   Usage Example:
%		showMountingInstructions(myMountingInstructions)

%%
numSteps=length(m.instruction);

str = '== Showing Mounting Instructions ==================================';
str = sprintf('%s\n+-----------------------------------------------------------------+', str);
ii = 1;
for ii=1:numSteps
if ii==m.curMountingStep
	s = sprintf(' * Step % 3d of % 3d | Parts mounted: % 2d | Parts Required: % 2d', ii, numSteps, m.instruction(ii).numPartsMounted, m.instruction(ii).numPartsRequired); 
else
	s = sprintf('   Step % 3d of % 3d | Parts mounted: % 2d | Parts Required: % 2d', ii, numSteps, m.instruction(ii).numPartsMounted, m.instruction(ii).numPartsRequired); 
end
str = sprintf('%s\n|%-65s|',str, s);

s	= sprintf(' %s', m.instruction(ii).description);
str = sprintf('%s\n|%-65s|',str, s);
str = sprintf('%s\n|%-65s|',str,'');
s	= sprintf(' % 42s: %-20s', 'Required Part Type ID', m.instruction(ii).requiredPartTypeID);
str = sprintf('%s\n|%-65s|',str, s);

s	= sprintf(' % 42s: %-20d', 'Possible Mounting Positions', length(m.instruction(ii).asmbly));
str = sprintf('%s\n|%-65s|',str, s);

s	= sprintf(' % 42s: %-20d', 'Step finished', m.isStepFinished(ii));
str = sprintf('%s\n|%-65s|',str, s);

str = sprintf('%s\n+-----------------------------------------------------------------+', str);
end

str = sprintf('%s\n',str);
fprintf(str);
end

