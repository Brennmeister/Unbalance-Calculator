%% Test analytic equations for cutCylinder with discrete model
clc
clear all
%%
fig = figure();
ax=axes();
hold(ax,'on');
axis('equal');
H=2;
R=1;
Ri=0.8;
step_x=H/30;
step_zy=R/30;
xlabel('X'); ylabel('Y'); zlabel('Z');
y_cut_plane = 0.8;
all_xx = [];
all_yy = [];
all_zz = [];
do_plot=1;

for x=0:step_x:H
    [zz yy] = meshgrid(-R:step_zy:R);
    xx = x*ones(size(zz));
    r=1;
    idx_circ = [(zz.^2+yy.^2)<=r];
    idx_plane = [x<=zz./(2*R)*H+H/2];
    idx_not_bore = [zz.^2+yy.^2>=Ri^2];
    idx=idx_circ & idx_plane& idx_not_bore;
    all_xx = [all_xx; xx(idx)];
    all_yy = [all_yy; yy(idx)];
    all_zz = [all_zz; zz(idx)];
    % h=plot3(xx(idx),yy(idx),zz(idx),'b.', 'LineWidth',0.1, 'MarkerSize', 3);
    
    idx_intersect = yy==y_cut_plane;
    idx=idx_circ & idx_plane & idx_intersect;
    if do_plot
        plot3(xx(idx),yy(idx),zz(idx),'r.');
    end
    
%     idx_intersect = zz>=0.7;
%     idx=idx_circ & idx_plane & idx_intersect;
%     plot3(xx(idx),yy(idx),zz(idx),'g.');
end
if do_plot
    h=plot3(all_xx,all_yy,all_zz,'b.', 'LineWidth',0.1, 'MarkerSize', 3);
end
%
alpha=acos((y_cut_plane)/R);
L=R*sin(alpha);
fprintf('start_z=%f, end_z=%f\n', -L,L)
%
y = 0.5;
inc=0.01;
z=-R*sin(acos(y/R)):inc:R*sin(acos(y/R));
x=z.*H/(2*R)+H/2;
plot3(x,y*ones(size(x)),z,'c.');

%
j_disc= [sum(all_zz.^2+all_yy.^2), sum(-all_xx.*all_yy), sum(-all_xx.*all_zz)
    sum(-all_xx.*all_yy),sum(all_zz.^2+all_xx.^2), sum(-all_yy.*all_zz)
    sum(-all_xx.*all_zz), sum(-all_yy.*all_zz), sum(all_yy.^2+all_xx.^2)
    ]*1/length(all_xx)


p=Part('cutCylinder'); 
a=Assembly('T'); 
p.setParent(a); 
p.dens=10; 
p.setPrimitive('cutCylinderWithBore','diameter',2*R, 'length',H, 'boreDiameter', 2*Ri);
j_cont = p.j/p.mass
j_disc/j_cont

%% 
% Erstellen cutcylinder
p=Part('cutCylinder'); 
a=Assembly('T'); 
p.setParent(a); 
p.dens=7500; 
% H=0.1e-3;
% R=15e-3;
p.setPrimitive('cutCylinderWithBore','diameter',2*R, 'length',H);
u=a.getUAll(0,H);
1e6*(u(1:3)+u(4:6))

% Vergleich mit Punktmasse, Position bei 1/3 entfernung der schweren seite
% des cutcylinders
disp('Gerechnet mit Punktmasse und 1/4 Abstand zur Rotachse:')
u_stat = p.mass * R/4 * 1e6

% Vergleich mit diskreter Rechnung
disp('Gerechnet mit diskreten Punktmassen:')
mass_discrete = p.mass/length(all_yy); % Masse pro massepunkt
sp_x = sum(all_xx*mass_discrete)/(mass_discrete*length(all_yy))
sp_y = sum(all_yy*mass_discrete)/(mass_discrete*length(all_yy))
sp_z = sum(all_zz*mass_discrete)/(mass_discrete*length(all_yy))

sp_x_cont = 5/16*H
sp_z_cont = R/4