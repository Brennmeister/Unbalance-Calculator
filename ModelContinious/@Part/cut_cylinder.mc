/*
Jxx_old : rho*integrate(integrate(integrate(y^2+z^2,z,0,(H/(2*R))*x+H/2),x,(-R)*sin(acos(y/R)),R*sin(acos(y/R))),y,-R,R);
Jyy_old : rho*integrate(integrate(integrate(x^2+z^2,z,0,(H/(2*R))*x+H/2),x,(-R)*sin(acos(y/R)),R*sin(acos(y/R))),y,-R,R);
Jzz_old : rho*integrate(integrate(integrate(x^2+y^2,z,0,(H/(2*R))*x+H/2),x,(-R)*sin(acos(y/R)),R*sin(acos(y/R))),y,-R,R);
        
Jxy_old : rho*integrate(integrate(integrate(-x*y,z,0,(H/(2*R))*x+H/2),x,(-R)*sin(acos(y/R)),R*sin(acos(y/R))),y,-R,R);
Jxz_old : rho*integrate(integrate(integrate(-x*z,z,0,(H/(2*R))*x+H/2),x,(-R)*sin(acos(y/R)),R*sin(acos(y/R))),y,-R,R);
Jyz_old : rho*integrate(integrate(integrate(-y*z,z,0,(H/(2*R))*x+H/2),x,(-R)*sin(acos(y/R)),R*sin(acos(y/R))),y,-R,R);
*/
/* 
Integral vollzylinder minus geschnittener zylinder:
f:y*z;
expand((integrate(integrate(integrate(f, z, -cos(asin(y/R))*R, cos(asin(y/R))*R), y, -R, R), x, -H/2, H/2)-
        integrate(integrate(integrate(f,x,-(H/2), (H/(2*R))*z),z,(-R)*sin(acos(y/R)),R*sin(acos(y/R))),y,-R,R))-
integrate(integrate(integrate(f,x,-(H/2), (H/(2*R))*z),z,(-R)*sin(acos(y/R)),R*sin(acos(y/R))),y,-R,R));

*/
/* == Berechnung des Trägheitstensors ================================= */
assume(R > 0)$
/* Festlegen der Integrationsgrenzen */
lim_x_low: 0$
lim_x_upp: (H/(2*R))*z+H/2$
lim_y_low: -R$
lim_y_upp:  R$
lim_z_low: (-R)*sin(acos(y/R))$
lim_z_upp: ( R)*sin(acos(y/R))$
/* Berechnen des Trägheitstensors */
Jxx : rho*integrate(integrate(integrate(y^2+z^2,x,lim_x_low,lim_x_upp),z,lim_z_low,lim_z_upp),y,lim_y_low,lim_y_upp);
Jyy : rho*integrate(integrate(integrate(x^2+z^2,x,lim_x_low,lim_x_upp),z,lim_z_low,lim_z_upp),y,lim_y_low,lim_y_upp);
Jzz : rho*integrate(integrate(integrate(x^2+y^2,x,lim_x_low,lim_x_upp),z,lim_z_low,lim_z_upp),y,lim_y_low,lim_y_upp);
    
Jxy : rho*integrate(integrate(integrate(-x*y,   x,lim_x_low,lim_x_upp),z,lim_z_low,lim_z_upp),y,lim_y_low,lim_y_upp);
Jxz : rho*integrate(integrate(integrate(-x*z,   x,lim_x_low,lim_x_upp),z,lim_z_low,lim_z_upp),y,lim_y_low,lim_y_upp);
Jyz : rho*integrate(integrate(integrate(-y*z,   x,lim_x_low,lim_x_upp),z,lim_z_low,lim_z_upp),y,lim_y_low,lim_y_upp);

J:matrix([Jxx,Jxy,Jxz], [Jxy,Jyy,Jyz], [Jxz,Jyz,Jzz]);

V : %pi*R^2*H/2;
m : rho*V;
J/m;


/* Berechnung des Schwerpunkts */
int_Vol:integrate(integrate(integrate(1,x,lim_x_low,lim_x_upp),z,lim_z_low,lim_z_upp),y,lim_y_low,lim_y_upp)$

sp_x:integrate(integrate(integrate(x,x,lim_x_low,lim_x_upp),z,lim_z_low,lim_z_upp),y,lim_y_low,lim_y_upp)/int_Vol;
sp_y:integrate(integrate(integrate(y,x,lim_x_low,lim_x_upp),z,lim_z_low,lim_z_upp),y,lim_y_low,lim_y_upp)/int_Vol;
sp_z:integrate(integrate(integrate(z,x,lim_x_low,lim_x_upp),z,lim_z_low,lim_z_upp),y,lim_y_low,lim_y_upp)/int_Vol;






/*== Berechnung schräg geschnittener Zylinder mit Innenaussparung ===============*/

assume(Ri>0)$
assume(Ri<R)$

lim_x_low: 0$
lim_x_upp: (H/(2*R))*z+H/2$

L:(R)*sin(acos(y/R))$
Li:(Ri)*sin(acos(y/Ri))$
f:y^2+z^2$
j_hollow_xx: rho*(
    integrate(
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,0)+
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,0,L),
    y,-R,-Ri) +
    integrate(
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,-Li)+
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,Li,L),
    y,-Ri,Ri) + 
    integrate(
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,0)+
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,0,L),
    y,Ri, R)
    )$
    
f:x^2+z^2$
j_hollow_yy: rho*(
    integrate(
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,0)+
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,0,L),
    y,-R,-Ri) +
    integrate(
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,-Li)+
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,Li,L),
    y,-Ri,Ri) + 
    integrate(
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,0)+
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,0,L),
    y,Ri, R)
    )$
    
f:x^2+y^2$
j_hollow_zz: rho*(
    integrate(
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,0)+
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,0,L),
    y,-R,-Ri) +
    integrate(
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,-Li)+
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,Li,L),
    y,-Ri,Ri) + 
    integrate(
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,0)+
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,0,L),
    y,Ri, R)
    )$
    
    
    
f:-x*y$
j_hollow_xy: rho*(
    integrate(
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,0)+
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,0,L),
    y,-R,-Ri) +
    integrate(
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,-Li)+
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,Li,L),
    y,-Ri,Ri) + 
    integrate(
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,0)+
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,0,L),
    y,Ri, R)
    )$
    
f:-x*z$
j_hollow_xz: rho*(
    integrate(
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,0)+
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,0,L),
    y,-R,-Ri) +
    integrate(
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,-Li)+
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,Li,L),
    y,-Ri,Ri) + 
    integrate(
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,0)+
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,0,L),
    y,Ri, R)
    )$
    
f:-y*z$
j_hollow_yz: rho*(
    integrate(
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,0)+
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,0,L),
    y,-R,-Ri) +
    integrate(
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,-Li)+
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,Li,L),
    y,-Ri,Ri) + 
    integrate(
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,0)+
      integrate(integrate(f,x,lim_x_low,lim_x_upp),z,0,L),
    y,Ri, R)
    )$    

    
J_hollow:matrix([j_hollow_xx,j_hollow_xy,j_hollow_xz], [j_hollow_xy,j_hollow_yy,j_hollow_yz], [j_hollow_xz,j_hollow_yz,j_hollow_zz]);



/* Berechnung des Schwerpunkts */
f:1$
int_Vol_hollow:(integrate(
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,0)+
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,0,L),
               y,-R,-Ri) +
               integrate(
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,-Li)+
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,Li,L),
               y,-Ri,Ri) + 
               integrate(
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,0)+
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,0,L),
               y,Ri, R)
               )$

f:x$
sp_x_hollow:(integrate(
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,0)+
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,0,L),
               y,-R,-Ri) +
               integrate(
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,-Li)+
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,Li,L),
               y,-Ri,Ri) + 
               integrate(
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,0)+
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,0,L),
               y,Ri, R)
               )/int_Vol_hollow$
f:y$
sp_y_hollow:(integrate(
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,0)+
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,0,L),
               y,-R,-Ri) +
               integrate(
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,-Li)+
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,Li,L),
               y,-Ri,Ri) + 
               integrate(
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,0)+
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,0,L),
               y,Ri, R)
               )/int_Vol_hollow$
f:z$
sp_z_hollow:(integrate(
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,0)+
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,0,L),
               y,-R,-Ri) +
               integrate(
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,-Li)+
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,Li,L),
               y,-Ri,Ri) + 
               integrate(
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,-L,0)+
                 integrate(integrate(f,x,lim_x_low,lim_x_upp),z,0,L),
               y,Ri, R)
               )/int_Vol_hollow$


sp_hollow: matrix([sp_x_hollow, sp_y_hollow, sp_z_hollow])$
ratsimp(J_hollow);
ratsimp(sp_hollow);