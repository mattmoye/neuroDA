function [filename,SNR,xtotal] = Run_ODE_Iappt_GenObsData_mat(obsNoise,Iapp,time,fnprefix,ODE_RHS,p,x0,varargin)
if nargin > 7
    s=varargin{1};
else
s=4;
end
if nargin >8
    odeopts=varargin{2};
else
    odeopts=odeset();
end

if nargin >9
    obsid=varargin{3};
else
    obsid=1;
end

if nargin >10
    TossInit=varargin{4};
else
TossInit=0;
end
rng(s);
dt = time(2)-time(1);
time = reshape(time,length(time),1);
NoiseVec= randn(size(time));
f=@(t,x,Iapp)ODE_RHS(t,x,p,Iapp);
x0=reshape(x0,length(x0),1);
ttotal=[0]; xtotal=x0';
for i=1:length(time)-1
f1=@(t,x)f(t,x,Iapp(i));
     [t1,x1]=ode15s(f1,time(i:i+1),x0,odeopts);
    % [x1] =ode4(f1,time(i:i+1),x0);
     x0=x1(end,:)';
     ttotal=[ttotal; time(i+1)];
     xtotal=[xtotal; x1(end,:)];
end
V_Clean=xtotal(:,obsid); signalStdev=std(V_Clean);
ErrorVec=obsNoise*(signalStdev.*NoiseVec);
V_Noisy=V_Clean+ErrorVec;
signalPow = sum((V_Clean).^2);
noisePow  = sum((ErrorVec).^2);
SNR = 10 * log10(signalPow / noisePow);
obs = V_Noisy;
if TossInit
    obs=obs(2:end);
    Iapp=Iapp(2:end);
    time=time(2:end);
end
Iappdata=Iapp/1e3; % scaling consistent with dros data
inds=1:length(time);
inds=reshape(inds,length(inds),1); 
Iappdata=reshape(Iappdata,length(Iappdata),1);
obs=reshape(obs,length(obs),1);
time = reshape(time,length(time),1);
filename=[fnprefix,'obs',num2str(obsNoise)];
filename=strrep(filename,'.','pt');
filename=[filename,'.mat'];
data = [inds, time, Iappdata, obs];
save(filename,'data');
end
