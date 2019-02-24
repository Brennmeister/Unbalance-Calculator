function [h] = drawCircle(obj, origin, r, Rota, desc)
 
h={}; % Create Cell for handles

origin1=origin*Rota;
xs=origin1(1,1);
ys=origin1(1,2);
zs=origin1(1,3);

% build circle
theta = 0:0.05:2*pi;
x = zeros(size(theta))+xs;
y = r*sin(theta)+ys;
z = r*cos(theta)+zs;

XYZ = Rota*[x', y', z']'; 

h{end+1}=plot3(obj.axes, XYZ(1,:), XYZ(2,:), XYZ(3,:), 'Color', 'red', 'LineWidth',1);

if obj.showPartLabel
    h{end+1}=text(obj.axes, origin(1)+0.1*height,origin(2)+0.7*r,origin(3)+0.7*r,desc,'HorizontalAlignment','left','FontSize',6);
end


