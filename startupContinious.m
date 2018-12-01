%% Unbalance-Calculator
% A tool for modeling rigid multi body rotors for calculating and
% optimizing their unbalance.
% Currently the set of supported rigid bodies contains: Pointmass,
% Cylinder, Cuboid
% The tool calculates dynamic unbalances for the given arrangement of an
% arbitrary number of these rigid bodies.
% Consistently use SI-Units! The resulting Unbalnce will also be in
% SI-Units (--> kg * m. Multiply it with 1e6 to transform into gmm!)
%
% = How to Use =
% Run this script within MATLAB, change to the folder of this script when
% asked
%
% Created by: M Peter
% Created on: 2018-08-25
%
% = Convetions for this Tool:
% Classes get uppercase first Letter
% Objects of classes are lowercase
% Methods get lowercase first Letter. New Objects get uppercase letter. "-"
% or "_" are not used in method-Names.
% Variables or Methods containing several "words" get concatenated by an
% Uppercase of the next Word. eg: longVariableName (DO NOT use
% underline-chars as in: long_variable_name
%
% = Setup of Matlab
% Install Toolboxes: 
%   - GUI Layout Toolbox 2.1.2.mltbx
%   - jsonlab-1.2.mltbx (only required when working with SQL-DB)
%
%% =======================================================================
%% Clean Workspace
clear variables;
clear classes;
close all;
clc;
%% Add everything to the path
addpath(genpath(pwd));
% Add MySQL Connector
javaclasspath('Toolboxes/mysql-connector-java-5.0.8-bin.jar');
% Set UTF8 default encoding
oldEncoding = feature('DefaultCharacterSet'); % should be windows-1252
feature('DefaultCharacterSet','UTF-8');
%% Custom Settings, View Helper
v=ViewHelper();
%% Create Controller Objects
mc			= SelmaController;			% Create the Main Controller
mc.dbc		= DBController;				% Add the Controller for the DataBase Access
mc.mntc		= MountController;			% Add the Controller for the Mounting Process
% mc.opt	= OptimizationController;	% Add the Controller for Optimization
%% Start building a rotor model
% This example will consist of a shaft with a single disc attaced to it
% First the disc is created
rd = Part('Rotor Disc');
rd.mass = 100e-3;
rd.setPrimitive('cylinder', 'length', 10e-3, 'diameter', 90e-3)
% Add an assembly for the disc
a_rd = Assembly('Rotor Disc Assembly');
rd.setParent(a_rd)
% Create left side part of the shaft
shaft_l = Part('Rotor Shaft, left side of Disc');
shaft_l.mass = 50e-3;
shaft_l.setPrimitive('cylinder', 'length', 50e-3, 'diameter', 10e-3)
% Add an assembly for the shaft
a_shaft_l = Assembly('Left-Side Shaft Assembly');
shaft_l.setParent(a_shaft_l)

% Create right side part of the shaft
shaft_r = Part('Rotor Shaft, right side of Disc');
shaft_r.mass = 50e-3;
shaft_r.setPrimitive('cylinder', 'length', 50e-3, 'diameter', 10e-3)
% Add an assembly for the shaft
a_shaft_r = Assembly('Right-Side Shaft Assembly');
shaft_r.setParent(a_shaft_r)

% Create the root-assembly which contains als sub-assemblies and parts
r = Assembly('Rotor');
a_shaft_l.setParent(r)
a_rd.setParent(r)
a_shaft_r.setParent(r)

% Move the assemblies to the correct position
a_shaft_l.origin = [shaft_l.primitive.length/2, 0, 0];
a_rd.origin = [shaft_l.primitive.length + rd.primitive.length/2, 0, 0];
a_shaft_r.origin = [shaft_l.primitive.length + rd.primitive.length + shaft_r.primitive.length/2, 0, 0];

%% Set position for the balancing planes
balancePlanePos=[0, 110e-3];

%% View the Parts created
pp = PartPlot();
% Set position for the balancing planes
pp.balancePlanePos=balancePlanePos;
pp.plotAssembly(r);
view(30,30)


%% Calculate the Unbalance in the Planes at x1=0, x2=110e-6
% since the model has no unbalance, the result will be zero
u = r.getUAll(balancePlanePos(1), balancePlanePos(2));

%% Create an unbalance by moving the Rotor disc 10 mm up
a_rd.origin(3) = 10e-3;
% Plot again and calculate the unbalance
pp = PartPlot();
pp.arrowLength=0.02;
pp.arrowStemWidth=5e-4;
pp.arrowTipWidth=1e-3;
pp.balancePlanePos=balancePlanePos;
pp.showPartLabel = false;
pp.plotAssembly(r);
view(30,30)
u = r.getUAll(balancePlanePos(1), balancePlanePos(2));

pp.unbalanceScaleFactor=100;
pp.drawResultingDynUnbalance();

% The resulting Unbalace has an amplitude of 500 gmm in each plane which is
% plausible since the setup is mirror-symmetric and the mass (0.1 kg)
% multiplied with the distance to the axis of rotation (10 mm) results in
% an *static* unbalance of 10mm*100g = 1000 gmm.
% Due to the mirror-symmetric setup it distributes uniformly to the two
% planes --> 500 gmm each