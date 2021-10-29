function [f,fu] = casadi_Belle2009_new()
% NaKL 4 kinetic parameter dynamics
%X = x(probinfo.xind);

%p = x(probinfo.pind);
%Iapp=probinfo.Iapp;
% Calculate h
%Iapp=interp1(Iappt,Iappdata,t);

import casadi.*

V= SX.sym('V');
m_na = SX.sym('m_na');
h_na = SX.sym('h_na');
n = SX.sym('n');
m_ca = SX.sym('m_ca');
h_ca = SX.sym('h_ca');

x = [V,m_na,h_na,n,m_ca,h_ca];

C = SX.sym('C');
Ena = SX.sym('Ena');
Ek =   SX.sym('Ek');
Eca= SX.sym('Eca');
Eleak   = SX.sym('Eleak');
Gna= SX.sym('Gna');
Gk= SX.sym('Gk');
Gca = SX.sym('Gca');
Gleak =  SX.sym('Gleak');
%m_na
vm_na= SX.sym('vm_na');
dvm_na= SX.sym('dvm_na');
tm0_na = SX.sym('tm0_na');
tm1_na = SX.sym('tm1_na');
vmt_na = SX.sym('vmt_na');
dvmt_na = SX.sym('dvmt_na');
%h_na
vh_na= SX.sym('vh_na');
dvh_na= SX.sym('dvh_na');
th0_na = SX.sym('th0_na');
th1_na = SX.sym('th1_na');
vht_na = SX.sym('vht_na');
dvht_na = SX.sym('dvht_na');

%n%
vn= SX.sym('vn');
dvn= SX.sym('dvn');
tn0 = SX.sym('tn0');
tn1= SX.sym('tn1');
vnt = SX.sym('vnt');
dvnt = SX.sym('dvnt');

%m_ca
vm_ca= SX.sym('vm_ca');
dvm_ca= SX.sym('dvm_ca');
tm0_ca = SX.sym('tm0_ca');
%h_ca
vh_ca= SX.sym('vh_ca');
dvh_ca= SX.sym('dvh_ca');
th0_ca = SX.sym('th0_ca');
th1_ca = SX.sym('th1_ca');
vht_ca = SX.sym('vht_ca');
dvht_ca = SX.sym('dvht_ca');




p = [C, Ena, Ek, Eca, Eleak,  Gna, Gk, Gca, Gleak]';
p = [p; vm_na; dvm_na; tm0_na; tm1_na; vmt_na; dvmt_na; ...
    vh_na; dvh_na; th0_na; th1_na; vht_na; dvht_na; ...
    vn; dvn; tn0; tn1; vnt; dvnt; ...
    vm_ca; dvm_ca; tm0_ca; 
    vh_ca; dvh_ca; th0_ca; th1_ca; vht_ca; dvht_ca;];


u = SX.sym('u');
ydat = SX.sym('ydat');
Iappx = SX.sym('Iappx');

xdot = [ fV(V,m_na,h_na,n,m_ca,h_ca,C,Ena,Ek,Eca,Eleak,Gna,Gk,Gca,Gleak,Iappx);
    fa(m_na,V,vm_na,dvm_na,tm0_na,tm1_na,vmt_na,dvmt_na);
    fa(h_na,V,vh_na,dvh_na,th0_na,th1_na,vht_na,dvht_na);
    fa(n,V,vn,dvn,tn0,tn1,vnt,dvnt);
        fa_tau_constant(m_ca,V,vm_ca,dvm_ca,tm0_ca);
            fa(h_ca,V,vh_ca,dvh_ca,th0_ca,th1_ca,vht_ca,dvht_ca); ];
xdotu = [ fVu(V,m_na,h_na,n,m_ca,h_ca,C,Ena,Ek,Eca,Eleak,Gna,Gk,Gca,Gleak,Iappx,u,ydat);
    fa(m_na,V,vm_na,dvm_na,tm0_na,tm1_na,vmt_na,dvmt_na);
    fa(h_na,V,vh_na,dvh_na,th0_na,th1_na,vht_na,dvht_na);
    fa(n,V,vn,dvn,tn0,tn1,vnt,dvnt);
        fa_tau_constant(m_ca,V,vm_ca,dvm_ca,tm0_ca);
            fa(h_ca,V,vh_ca,dvh_ca,th0_ca,th1_ca,vht_ca,dvht_ca); ];


% xdot = [ fV(V,m_na,n,m_nap,k,Gna,Gk,Gks,Gnap,Gleak,Gtonic,Iappx,Ena,Ek,Eleak,Esyn,C);
%     fa(n,V,vn,dvn,tn1);
%     fa(k,V,vk,dvk,exp(tk1));];
%  xdotu = [ fVu(V,m_na,n,m_nap,k,Gna,Gk,Gks,Gnap,Gleak,Gtonic,Iappx,Ena,Ek,Eleak,Esyn,C,u,ydat);
%     fa(n,V,vn,dvn,tn1);
%     fa(k,V,vk,dvk,exp(tk1));];
 
f = Function('f', {x,p,Iappx}, {xdot});
fu = Function('fu', {x,p,Iappx,ydat,u}, {xdotu});

function dVdt = fV(V,m_na,h_na,n,m_ca,h_ca,C,Ena,Ek,Eca,Eleak,Gna,Gk,Gca,Gleak,Iapp)
 Ina = Gna*(m_na^3)*h_na*(V-Ena);
        Ik = Gk*(n^4)*(V-Ek);
        Ileak = Gleak*(V-Eleak);
        Ica = Gca*m_ca*h_ca*(V-Eca);
        dVdt = (1/C)*(Iapp-Ina-Ik-Ileak-Ica);  
end

function dVdt = fVu(V,m_na,h_na,n,m_ca,h_ca,C,Ena,Ek,Eca,Eleak,Gna,Gk,Gca,Gleak,Iapp,u,ydat)
 Ina = Gna*(m_na^3)*h_na*(V-Ena);
        Ik = Gk*(n^4)*(V-Ek);
        Ileak = Gleak*(V-Eleak);
        Ica = Gca*m_ca*h_ca*(V-Eca);
Iu= u*(V-ydat);
dVdt =  (1/C)*(Iapp-Ina-Ik-Ileak-Ica)-Iu;
end

function dadt = fa_tau_constant(a,V,va,dva,ta0)
ainf =ainf_fun(V,va,dva);
%tau = ta1./cosh((V-va)./(dva));
tau = ta0;  
dadt = (ainf-a)/tau;
end

function dadt = fa(a,V,va,dva,ta0,ta1,vat,dvat)
ainf =ainf_fun(V,va,dva);
tau = ta0 + ta1*((1-tanh((V-vat)/dvat)^2));
dadt = (ainf-a)/tau;
end

function ainf = ainf_fun(V,va,dva)
ainf =(1/2)*(1+tanh((V-va)/(dva)));
end

              %  (.5*(1+tanh((vx-vm)/dvm)) - mx)/((tm0+tm1.*(1-tanh((vx-vm)./dvm)^2)));

end