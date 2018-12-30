function [desc, descH, descI, descII, descS] = describeUDyn(obj, u, planes)
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
uS  = uI+uII;
% Convert to gmm
uI  = uI*1e6;
uII = uII*1e6;
uS  = uS*1e6;
% Convert to mm
planes = planes*1e3;
%% Prepare header
descH = sprintf('%18s%15s%15s%15s%15s%15s', '', 'mean', 'median', 'min', 'max', 'count');
%% Calculate min, max, mean and median values
descI  = miniDesc(sprintf('U_I (x=%3.2f mm)', planes(1)), uI);
descII = miniDesc(sprintf('U_II (x=%3.2f mm)', planes(2)), uII);
descS  = miniDesc(sprintf('U_stat'), uS);

    function str = miniDesc(name, uu)
        str = sprintf('');
        str = sprintf('%s%18s', str, name);
        str = sprintf('%s%15s', str, sprintf('%3.2f gmm', mean(vecnorm(uu'))));
        str = sprintf('%s%15s', str, sprintf('%3.2f gmm', median(vecnorm(uu'))));
        str = sprintf('%s%15s', str, sprintf('%3.2f gmm', min(vecnorm(uu'))));
        str = sprintf('%s%15s', str, sprintf('%3.2f gmm', max(vecnorm(uu'))));
        str = sprintf('%s%15s', str, sprintf('%d', size(uu,1)));
    end

%% concat everything
desc = sprintf('%s\n%s\n%s\n%s\n', descH, descI, descII, descS);
end