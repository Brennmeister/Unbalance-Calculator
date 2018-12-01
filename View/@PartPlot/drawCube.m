function [g] = drawCube (obj, origin, pSize, Rota, desc)

% Create Points for cube with size 1x1x1 and center [0.5 0.5 0.5]
x=[0 1 1 0 0 0; 1 1 0 0 1 1; 1 1 0 0 1 1; 0 1 1 0 0 0];
y=[0 0 1 1 0 0; 0 1 1 0 0 0; 0 1 1 0 1 1; 0 0 1 1 1 1];
z=[0 0 0 0 0 1; 0 0 0 0 0 1; 1 1 1 1 0 1; 1 1 1 1 0 1];
% Shift cube to center [0, 0, 0]
x=x-0.5;
y=y-0.5;
z=z-0.5;

% Scale Cube
x=x*pSize(1);
y=y*pSize(2);
z=z*pSize(3);

% Transform Cube
x1=zeros(4,6);
y1=zeros(4,6);
z1=zeros(4,6);
for j=1:6
    for k=1:4
        Rots=Rota*transpose([x(k,j) y(k,j) z(k,j)]);
        x1(k,j)=Rots(1,1)+origin(1);
        y1(k,j)=Rots(2,1)+origin(2);
        z1(k,j)=Rots(3,1)+origin(3);        
    end
end

g=zeros(6,1);
for i=1:6
    g(i)=patch(obj.axes, x1(:,i),y1(:,i),z1(:,i), 'r');
    set(g(i), 'FaceColor', obj.faceColorCube, 'faceAlpha', 0.8);
end

if obj.showPartLabel
    T1= Rota*transpose([-2e-1*pSize(1) 12e-1*pSize(2) 12e-1*pSize(3)])+transpose(origin) ;
    text(obj.axes, T1(1),T1(2),T1(3),desc,'HorizontalAlignment','left','FontSize',6);
end
