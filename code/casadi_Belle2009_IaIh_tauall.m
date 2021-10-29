function [f,fu,p] = casadi_Belle2009_IaIh_tauall()
% NaKL 4 kinetic parameter dynamics
%X = x(probinfo.xind);

%p = x(probinfo.pind);
%Iapp=probinfo.Iapp;
% Calculate h
%Iapp=interp1(Iappt,Iappdata,t);
timeScaleFactor=10;
import casadi.*

V= SX.sym('V');
h_na = SX.sym('h_na');
n = SX.sym('n');
m_ca = SX.sym('m_ca');
h_ca = SX.sym('h_ca');
m_h  = SX.sym('m_h');
%m_to = SX.sym('m_to');
h_to = SX.sym('h_to');
x = [V,h_na,n,m_ca,h_ca,m_h,h_to];

C = SX.sym('C');
Ena = SX.sym('Ena');
Ek =   SX.sym('Ek');
Eca= SX.sym('Eca');
Eh = SX.sym('Eh');
%Eleak   = SX.sym('Eleak');
Gna= SX.sym('Gna');
Gk= SX.sym('Gk');
Gca = SX.sym('Gca');
Gto = SX.sym('Gto');
Gleak_na =  SX.sym('Gleak_na');
Gleak_k = SX.sym('Gleak_k');
Gh = SX.sym('Gh');
%m_na
vm_na= SX.sym('vm_na');
dvm_na= SX.sym('dvm_na');

%h_na
vh_na= SX.sym('vh_na');
dvh_na= SX.sym('dvh_na');
th0_na = SX.sym('th0_na');
th1_na = SX.sym('th1_na');
%vht_na = SX.sym('vht_na');
vht_na = vh_na;
dvht_na = SX.sym('dvht_na');

%n%
vn= SX.sym('vn');
dvn= SX.sym('dvn');
tn0 = SX.sym('tn0');
tn1= SX.sym('tn1');
%vnt = SX.sym('vnt');
vnt = vn;
dvnt = SX.sym('dvnt');

%m_ca
vm_ca= SX.sym('vm_ca');
dvm_ca= SX.sym('dvm_ca');
tm0_ca = SX.sym('tm0_ca');
tm1_ca = SX.sym('tm1_ca');
%vmt_ca = SX.sym('vmt_ca');
vmt_ca = vm_ca;
dvmt_ca = SX.sym('dvmt_ca');
%h_ca
vh_ca= SX.sym('vh_ca');
dvh_ca= SX.sym('dvh_ca');
th0_ca = SX.sym('th0_ca');
th1_ca = SX.sym('th1_ca');
%vht_ca = SX.sym('vht_ca');
vht_ca = vh_ca;
dvht_ca = SX.sym('dvht_ca');
% 
% m_h
vm_h = SX.sym('vm_h');
dvm_h = SX.sym('dvm_h');
tm0_h = SX.sym('tm0_h');
tm1_h = SX.sym('tm1_h');
vmt_h= vm_h;
dvmt_h = SX.sym('dvmt_h');

%th1_ca = SX.sym('th1_ca');
%vht_ca = SX.sym('vht_ca');
%dvht_ca = SX.sym('dvht_ca');

%m_to
vm_to = SX.sym('vm_to');
dvm_to = SX.sym('dvm_to');
%tm0_to = SX.sym('tm0_to');
%h_to
vh_to = SX.sym('vh_to');
dvh_to = SX.sym('dvh_to');
th0_to = SX.sym('th0_to');
th1_to = SX.sym('th1_to');
vht_to = vh_to;
dvht_to = SX.sym('dvht_to');

p = [C, Ena, Ek, Eca, Eh,  Gna, Gk, Gca, Gh, Gto, Gleak_na,Gleak_k]';
p = [p; vm_na; dvm_na;
    vh_na; dvh_na; th0_na; th1_na;dvht_na; ...
    vn; dvn; tn0; tn1; dvnt; ...
    vm_ca; dvm_ca; tm0_ca; tm1_ca; dvmt_ca;
    vh_ca; dvh_ca; th0_ca; th1_ca; dvht_ca;
    vm_h; dvm_h; tm0_h; tm1_h; dvmt_h;
    vm_to; dvm_to; 
    vh_to; dvh_to; th0_to; th1_to; dvht_to];


u = SX.sym('u');
ydat = SX.sym('ydat');
Iappx = SX.sym('Iappx');
m_na=ainf_fun(V,vm_na,dvm_na);
m_to = ainf_fun(V,vm_to,dvm_to);
xdot = [ fV(V,m_na,h_na,n,m_ca,h_ca,m_h,m_to,h_to,C,Ena,Ek,Eca,Eh,Gna,Gk,Gca,Gh,Gleak_na,Gleak_k,Gto,Iappx);
    fa(h_na,V,vh_na,dvh_na,th0_na,th1_na,vht_na,dvht_na);
    fa(n,V,vn,dvn,tn0,tn1,vnt,dvnt);
    fa(m_ca,V,vm_ca,dvm_ca,tm0_ca,tm1_ca,vmt_ca,dvmt_ca);
    fa(h_ca,V,vh_ca,dvh_ca,th0_ca,timeScaleFactor*th1_ca,vht_ca,dvht_ca);
    fa(m_h,V,vm_h,dvm_h,timeScaleFactor*tm0_h,timeScaleFactor*tm1_h,vmt_h,dvmt_h);
    fa(h_to,V,vh_to,dvh_to,timeScaleFactor*th0_to,timeScaleFactor*th1_to,vht_to,dvht_to)];
xdotu = [ fVu(V,m_na,h_na,n,m_ca,h_ca,m_h,m_to,h_to,C,Ena,Ek,Eca,Eh,Gna,Gk,Gca,Gh,Gleak_na,Gleak_k,Gto,Iappx,u,ydat);
    fa(h_na,V,vh_na,dvh_na,th0_na,th1_na,vht_na,dvht_na);
    fa(n,V,vn,dvn,tn0,tn1,vnt,dvnt);
    fa(m_ca,V,vm_ca,dvm_ca,tm0_ca,tm1_ca,vmt_ca,dvmt_ca);
    fa(h_ca,V,vh_ca,dvh_ca,th0_ca,timeScaleFactor*th1_ca,vht_ca,dvht_ca);
    fa(m_h,V,vm_h,dvm_h,timeScaleFactor*tm0_h,timeScaleFactor*tm1_h,vmt_h,dvmt_h);
    fa(h_to,V,vh_to,dvh_to,timeScaleFactor*th0_to,timeScaleFactor*th1_to,vht_to,dvht_to)];


% xdot = [ fV(V,m_na,n,m_nap,k,Gna,Gk,Gks,Gnap,Gleak,Gtonic,Iappx,Ena,Ek,Eleak,Esyn,C);
%     fa(n,V,vn,dvn,tn1);
%     fa(k,V,vk,dvk,exp(tk1));];
%  xdotu = [ fVu(V,m_na,n,m_nap,k,Gna,Gk,Gks,Gnap,Gleak,Gtonic,Iappx,Ena,Ek,Eleak,Esyn,C,u,ydat);
%     fa(n,V,vn,dvn,tn1);
%     fa(k,V,vk,dvk,exp(tk1));];

f = Function('f', {x,p,Iappx}, {xdot});
fu = Function('fu', {x,p,Iappx,ydat,u}, {xdotu});
%f= Function('Ff',{x,p,Iappx}, {xdot}, char('x0','p0','Iapp'),char('xf'));
%fu = Function('Ffu', {x,p,Iappx,ydat,u}, {xdotu}, char('x0','p0','Iapp','ydat','u'),char('xf'));


    function dVdt = fV(V,m_na,h_na,n,m_ca,h_ca,m_h,m_to,h_to,C,Ena,Ek,Eca,Eh,Gna,Gk,Gca,Gh,Gleak_na,Gleak_k,Gto,Iapp)
        Ina = Gna*(m_na^3)*h_na*(V-Ena);
        Ik = Gk*(n^4)*(V-Ek);
        %Ileak = Gleak*(V-Eleak);
        Ileak_na = Gleak_na*(V-Ena);
        Ileak_k = Gleak_k*(V-Ek);
        Ica = Gca*m_ca*h_ca*(V-Eca);
        Ito = Gto*(m_to^3)*h_to*(V-Ek);
        Ih = Gh*m_h*(V-Eh);
        dVdt = (1/C)*(Iapp-Ina-Ik-Ileak_na-Ileak_k-Ica-Ito-Ih);
    end

    function dVdt = fVu(V,m_na,h_na,n,m_ca,h_ca,m_h,m_to,h_to,C,Ena,Ek,Eca,Eh,Gna,Gk,Gca,Gh,Gleak_na,Gleak_k,Gto,Iapp,u,ydat)
        Ina = Gna*(m_na^3)*h_na*(V-Ena);
        Ik = Gk*(n^4)*(V-Ek);
        %Ileak = Gleak*(V-Eleak);
        Ileak_na = Gleak_na*(V-Ena);
        Ileak_k = Gleak_k*(V-Ek);
        Ica = Gca*m_ca*h_ca*(V-Eca);
       Ih = Gh*m_h*(V-Eh);
        Iu= u*(V-ydat);
                Ito = Gto*(m_to^3)*h_to*(V-Ek);
        dVdt =  (1/C)*(Iapp-Ina-Ik-Ileak_na-Ileak_k-Ica-Ito-Ih)-Iu;
    end

    function dadt = fa_tau_constant(a,V,va,dva,ta0)
        ainf =ainf_fun(V,va,dva);
        %tau = ta1./cosh((V-va)./(dva));
        tau = ta0;
        dadt = (ainf-a)/tau;
    end

    function dadt = fa(a,V,va,dva,ta0,ta1,vat,dvat)
        ainf =ainf_fun(V,va,dva);
        tau = ta0 + ta1*(1-tanh((V-vat)/dvat)^2);
        dadt = (ainf-a)/tau;
    end

    function ainf = ainf_fun(V,va,dva)
        ainf =(1/2)*(1+tanh((V-va)/(dva)));
    end

%  (.5*(1+tanh((vx-vm)/dvm)) - mx)/((tm0+tm1.*(1-tanh((vx-vm)./dvm)^2)));

end