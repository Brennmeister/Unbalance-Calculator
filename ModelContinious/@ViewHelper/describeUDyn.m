function [desc, descH, descI, descII, descS] = describeU(obj, u, planes)
%% Describes the given dynamic unbalance matrix (Nx6)
% u
%   The Nx6 Matrix containing the unbalance values
% planes
%   The panes in which the unbalance was calculated

%% Check if planes were given
if ~exist('planes','var')
    planes = [0 0];
end

%% Prepare unbalance Values
uI  = u(:,1:3);
uII = u(:,4:6);
[uP, uS] = uDynToUMomentStat(u,planes);
% Convert to gmm
uI  = uI*1e6; % [g*mm]
uII = uII*1e6;% [g*mm]
uS  = uS*1e6; % [g*mm]
uP  = uP*1e9; % [g*mm^2]
% Convert to mm
planes = planes*1e3;
%% Prepare header
descH = sprintf('%18s%20s%20s%20s%20s%20s', '', 'mean', 'median', 'min', 'max', 'count');
%% Calculate min, max, mean and median values
descI  = miniDesc(sprintf('U_I (x=%3.2f mm)', planes(1)), uI, 'gmm');
descII = miniDesc(sprintf('U_II (x=%3.2f mm)', planes(2)), uII, 'gmm');
descS  = miniDesc(sprintf('U_stat'), uS, 'gmm');
descP  = miniDesc(sprintf('U_P (Momentenunw.)'), uP, 'gmm^2');

    function str = miniDesc(name, uu, unit)
        str = sprintf('');
        str = sprintf('%s%18s', str, name);
        str = sprintf('%s%20s', str, sprintf('%3.2f %s', mean(vecnorm(uu')), unit));
        str = sprintf('%s%20s', str, sprintf('%3.2f %s', median(vecnorm(uu')), unit));
        str = sprintf('%s%20s', str, sprintf('%3.2f %s', min(vecnorm(uu')), unit));
        str = sprintf('%s%20s', str, sprintf('%3.2f %s', max(vecnorm(uu')), unit));
        str = sprintf('%s%20s', str, sprintf('%d', size(uu,1)));
    end

%% concat everything
desc = sprintf('%s\n%s\n%s\n%s\n%s\n', descH, descI, descII, descP, descS);
end