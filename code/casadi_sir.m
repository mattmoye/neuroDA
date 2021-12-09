function [f,fu] = casadi_sir()
import casadi.*


Sx = SX.sym('Sx');
Ix = SX.sym('Ix');
Rx = SX.sym('Rx');
x = [Sx; Ix; Rx];
p=[];
beta = SX.sym('beta');
gamma = SX.sym('gamma');
N = SX.sym('N');
p = [beta; gamma; N];

u = SX.sym('u');
ydat= SX.sym('ydat');
Iappx = SX.sym('Iappx');
%% Model equations
            xdot = [-beta*Sx*Ix/N;
                beta*Sx*Ix/N - gamma*Ix;
                gamma*Ix;];
            xdotu =  [-beta*Sx*Ix/N
                beta*Sx*Ix/N - gamma*Ix - (u*(Ix-ydat));
                gamma*Ix;];
%%
% Sum of states
% S_x = vm+vh+vn;
% obsout = [S_x];
%%

f = Function('f', {x,p,Iappx}, {xdot});
fu = Function('fu', {x,p,Iappx,ydat,u}, {xdotu});
%fobs = Function('fobs', {x,p,Iappx}, {obsout});
