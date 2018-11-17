function [h] = drawCylinder (obj, origin, pSize, Rota, desc)
 
h={}; % Create Cell for handles
 
r=pSize(1);
height=pSize(2);
 
origin1=origin*Rota;
xs=origin1(1,1);
ys=origin1(1,2);
zs=origin1(1,3);
theta = 0:0.05:2*pi;
 
z = r*cos(theta);
y = r*sin(theta);
y(end) = 0;
 
x1 = 0;
x2 = height;
 
V1=[(x1*ones(size(y))+xs-height/2); (y+ys); (z+zs)];
V2=[(x2*ones(size(y))+xs-height/2); (y+ys); (z+zs)];
V4=zeros(size(V1));
V5=zeros(size(V1));
 
for i=1:size(y,2)
    
    V4(:,i)=(Rota*(V1(:,i)));
    V5(:,i)=(Rota*(V2(:,i)));
 
end
 
h{end+1}=surf(obj.axes,[V4(1,:);V5(1,:)],[V4(2,:);V5(2,:)],[V4(3,:);V5(3,:)], 'EdgeColor', 'none');
set(h{end},'FaceColor',[0 0 1], 'FaceAlpha',0.5);
h{end+1}=patch(obj.axes,'XData',V4(1,:),'YData',V4(2,:),'ZData',V4(3,:),'FaceColor', obj.faceColorCylinder, 'FaceAlpha', 0.5);
h{end+1}=patch(obj.axes,'XData',V5(1,:),'YData',V5(2,:),'ZData',V5(3,:),'FaceColor', obj.faceColorCylinder, 'FaceAlpha', 0.5);

if obj.showPartLabel
    h{end+1}=text(obj.axes, origin(1)+0.1*height,origin(2)+0.7*r,origin(3)+0.7*r,desc,'HorizontalAlignment','left','FontSize',6);
end


