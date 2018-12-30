function u = transformUToPlane(from_planes, to_planes, udyn)
%% Transforms the given dynamic unbalance (Nx6 matrix) from from_planes to to_planes
L = from_planes(2)-from_planes(1);
a = to_planes-from_planes(1);
b = from_planes(2)-to_planes;
A = reshape(repmat(a,3,1),1,[]);
B = reshape(repmat(b,3,1),1,[]);
u  = (udyn.*B + udyn.*A)/L;
