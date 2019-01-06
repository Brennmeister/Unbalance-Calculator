function [uP, uStat] = uDynToUMomentStat(u_dyn, planes)
%% Transforms the given dynamic unbalance (Nx6 matrix) in planes to moment and static unbalance
cog = zeros(1,3);
uStat = (u_dyn(:,2:3) + u_dyn(:,5:6));
uP    = cross(repmat([planes(1), 0, 0] - cog, size(u_dyn,1),1), u_dyn(:,1:3)) + ...
        cross(repmat([planes(2), 0, 0] - cog, size(u_dyn,1),1), u_dyn(:,4:6));
