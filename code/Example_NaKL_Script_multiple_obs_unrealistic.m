%% Example of how to conduct twin experiment for 4D-Var
% Written by Matthew Moye

% Generate the time dependent injected current.
%t = 0:.02:(300-.02);
% tnew = [ 0 25 75 100 1000]; Inew = [0 100 -50 0 50 ];
% Inewnew= interp1(tnew, Inew, t);
% figure, plot(t,Inewnew)
% Iapp=Inewnew;
%Iapp=40*ones(size(t));
%Inewnew= interp1(tnew, Inew, t(1:5:end));
%A2 = repmat(Inewnew,5,1); A3 = A2(:);
%Iapp= A3(1:5000);
%save('IconstforNaKL_superlong.mat','t','Iapp');

%load('IrampforNaKL.mat','t',Iapp');

% We generate the data at the prescribed time points and save as a csv file
% Template:
% Run_ODE_Iappt_GenObsData_CSV(obsNoise,Iapp,time,fnprefix,ODE_RHS,p,x0)
%       obsnoise: level of additive noise to include. should be a small
%       factor
%       Iapp: time dependent current.
%       time: vector of time points.
%       fnprefix: the file name prefix, string, to be used to name the data
%       ODE_RHS: name of the function which specifies ode dynamics as 
%           as ODE_RHS(t,x,p,Iapp). 
%       p: set of parameters for the model
%       x0: initial conditions of the model


ODE_RHS=@ode_NaKL_4kineticparams_basic;
x0=[-20,.8,.2,.4]';
% Paramdetails
paramboundsSpecsdotText=[ %adjusted from specs.txt
    1,1000,120 %gNa
    1,1000,20% gK
    0.001,10,.3% gL
    -60,-30,-40%, Vmo
    10,100,15%, dVm
    0.05,.25,.1%, Cm1
    .1,1,.4%, Cm2
    -70,-40,-60%, Vho
    -100,-10,-15%, dVh
    .1,5,1%, Ch1
    1,15,7%, Ch2
    -70,-40,-55%, Vno
    10,100,30%, dVn
    .1,5,1%, Cn1
    2,12,5%, Cn2
    ];

paramboundsSpecsdotText=[ %adjusted from specs.txt
    100,200,120 %gNa
    1,200,20% gK
    0.001,10,.3% gL
    -60,-30,-40%, Vmo
    10,20,15%, dVm
    0.05,.25,.1%, Cm1
    .1,1,.4%, Cm2
    -70,-40,-60%, Vho
    -30,-10,-15%, dVh
    .1,5,1%, Ch1
    1,15,7%, Ch2
    -70,-40,-55%, Vno
    10,50,30%, dVn
    .1,5,1%, Cn1
    2,8,5%, Cn2
    ];
% passive parameters
passivebounds = repmat([1,50,-77,-54.4]',1,3);
PDATA = [passivebounds; paramboundsSpecsdotText];
Nstate=4;
compartments=1;
nleaks=1;
p=PDATA(:,3);
modelDataFileName='dataNaKLBasic_2132021.mat';
%save(modelDataFileName,'PDATA','Nstate','compartments','nleaks');
% Generate the data.
t = 0:.02:(40-.02);
t(1:4:end)=[];
Iapp=40*ones(size(t));

[filename1,SNR,xtotal]=Run_ODE_Iappt_GenObsData_mat(.01,Iapp,t,'Const1_NaKL_2132021',ODE_RHS,p,x0);
ICs1=xtotal(1,:);



t = 0:.02:(50-.02);
t(1:4:end)=[];
Iapp=50*ones(size(t));
[filename2,SNR,xtotal]=Run_ODE_Iappt_GenObsData_mat(.01,Iapp,t,'Const2_NaKL_2132021',ODE_RHS,p,x0);
ICs2=xtotal(1,:);

t = 0:.02:(30-.02);
t(1:4:end)=[];
Iapp=20*ones(size(t));
[filename3,SNR,xtotal]=Run_ODE_Iappt_GenObsData_mat(.01,Iapp,t,'Const3_NaKL_2132021',ODE_RHS,p,x0);
ICs3=xtotal(1,:);
vseriesCollection={filename1,filename2,filename3};
% Specify the model using the casadi symbolic framework.
ODEmodel=@casadi_model_test;

save(modelDataFileName,'PDATA','Nstate','compartments','nleaks','vseriesCollection','ODEmodel');

% The csvfile structure is [Index, time (ms), I (pA), V (mV)]
% We have implemented that applied current, I (pA) will be scaled by a
% factor of 10^-3 consistent with the drosophila data. This is scaled back
% prior to the 4D-Var problem initiation.


% Construct the data to be passed, which includes a matrix of lowerbounds,
% upperbounds, and intial guesses, respectively (np x 3). Also, specify
% Nstate in the model (4 for NaKL) and compartments (1 for NaKL).


% Now we pass these as arguments to our initiation function for 4D-Var.
% The choice to encapsulate this in another function is for ease with
% running in batch with KONG for various initial conditions (multi-start).
SeedNum=2; modeldata=modelDataFileName;

%[tout,yout] = downsample_from_threshold(tin,yin,thresh,apwidth,dsf);
%filename='Ramp_LongStressTest_1msdt_NaKLobs0pt01.csv';

observed_variable_in_experiment=struct;
observed_variable_in_experiment(1).val=1;
observed_variable_in_experiment(2).val=1;
observed_variable_in_experiment(3).val=1;

VariableICs = struct;
VariableICs(1).known  =true;
VariableICs(1).lb = [ICs1(1)*.8 0 0 0]';
VariableICs(1).ub = [ICs1(1)*1.2 1 1 1]';
if ICs1(1)<0
    VariableICs(1).lb(1)=ICs1(1)*1.2;
    VariableICs(1).rb(1) = ICs1(1)*.8;
end
VariableICs(1).vals = ICs1';
VariableICs(1).forceTimeZeroStart=1;
VariableICs(2).known  =true;
VariableICs(2).lb = [ICs2(1)*.8 0 0 0]';
VariableICs(2).ub = [ICs2(1)*1.2 1 1 1]';
VariableICs(2).vals = ICs2';
if ICs2(1)<0
    VariableICs(2).lb(1)=ICs2(1)*1.2;
    VariableICs(2).rb(1) = ICs2(1)*.8;
end
VariableICs(2).forceTimeZeroStart=1;

VariableICs(3).known  =true;
VariableICs(3).lb = [ICs3(1)*.8 0 0 0]';
VariableICs(3).ub = [ICs3(1)*1.2 1 1 1]';
VariableICs(3).vals = ICs3';
if ICs3(1)<0
    VariableICs(3).lb(1)=ICs3(1)*1.2;
    VariableICs(3).rb(1) = ICs3(1)*.8;
end
VariableICs(3).forceTimeZeroStart=1;

ScalingSupplied=struct('provided',true);

QinvStdUnscaled=.1*[1 100 100 100];
VariableScale=[.01 1 1 1]';
Qinv=(10^-2)*[1 10000 10000 10000];
Rinv = [1];
ScalingSupplied.QinvStdUnscaled=QinvStdUnscaled;
ScalingSupplied.VariableScale=VariableScale;
ScalingSupplied.Qinv=Qinv;
ScalingSupplied.Rinv=Rinv;
%filename='Ramp_Long_1msdt_NaKLobs0pt01.csv';
% DATA= {filename1,filename2}
%%
tic
for i=1
run_Run_ODE_4dvar_multiple_collocation_multiple_experiments(i,'UseModelData',modeldata,ODEmodel,  ...
    'UseControl',0,'SmoothControl',0,'ControlPenalty',1,'dt',.02,'yinds',1,'TOL',1e-12,...
    'METHODTOUSE','Strong','varannealbounds',[30,30],'hessian_approximation','exact',...
    'ControlAtEnd',0,'linear_solver','mumps','UseSlack',0,...
    'NonUniform',1,'observed_variable_in_experiment',observed_variable_in_experiment,...
    'VariableICs',VariableICs,'ScalingSupplied',ScalingSupplied,...
    'alpha0',1.5,'UseColpack',1,'ScaleSlack',1,'ScaleConstraints',1)
end
toc
% % change linear_solver value: 'ma_57' to 'mumps' if ma57 not installed.
% run_Run_ODE_4dvar_multiple_collocation(SeedNum,'UseModelData',modelDataFileName,ODEmodel,  ...
%     'UseControl',1,'SmoothControl',1,'ControlPenalty',100,'yinds',1,'TOL',1e-10,...
%     'METHODTOUSE','Strong','varannealbounds',[75,75],'hessian_approximation','exact',...
%     'ControlAtEnd',0,'linear_solver','mumps','SaveLagGrad',0,'UseSlack',0,'UseAdaptive',1,...
%     'correctLJPData',0,'alpha0',1.5,'UseColpack',1,'ScaleSlack',0,'ScaleConstraints',0,'saveDir',saveDir)
% 

%                        modelDataFileName=[mDFN_prefix,'data_SCN_new_Ia_tauall','_case',num2str(CASE)];
%             modelDataFileName=strrep(modelDataFileName,'.','pt');
%             PDATA=PDATA_new_twoleaks_Ia_tauall;
%             ODEmodel=@casadi_Belle2009_Ia_tauall_twoleak;
%             save(modelDataFileName,'PDATA','Nstate','compartments','nleaks','vseriesCollection','ODEmodel');
%            
