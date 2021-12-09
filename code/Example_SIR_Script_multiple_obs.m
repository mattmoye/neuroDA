%% Example of how to conduct twin experiment for 4D-Var
% Written by Matthew Moye


% We generate the data at the prescribed time points and save as a csv file
% Template:
% Run_ODE_Iappt_GenObsData_mat(obsNoise,Iapp,time,fnprefix,ODE_RHS,p,x0,varargin)
%       obsnoise: level of additive noise to include. should be a small
%       factor
%       Iapp: time dependent current.
%       time: vector of time points.
%       fnprefix: the file name prefix, string, to be used to name the data
%       ODE_RHS: name of the function which specifies ode dynamics as 
%           as ODE_RHS(t,x,p,Iapp). 
%       p: set of parameters for the model
%       x0: initial conditions of the model
%       varargin: additional optional arguments
%           varargin{1}: seed for RNG
%           varargin{2}: odeopts, options for odesolver
%           varargin{3}: obsid, specifies which variable is observed
%           varargin{4}: TossInit, flag of whether or not to through out
%           the initial value (good for testing forceTimeZeroStart)

% Ode implementation of simple SIR model (full 3-D model, not accounting
% for conservation law)
ODE_RHS=@ode_sir;
N=1000;
x0=[N-1; 1; 0];

% First two columns are lower and upper bounds, respectfully. 
% third column will not be used by solver, but holds the true values. in
% the case of real data, this last column is arbitrary.
parambounds=[ 
   .5, 2, 1 % beta
   1/10 1/2, 1/5 % gamma, five day infection period
   N, N, N % N, here total population is fixed. 
];
PDATA = parambounds;
Nstate=3;
p=PDATA(:,3);
compartments=1; % this is old code to allow easy implementation of multiple-connected neurons
modelDataFileName='dataSIRBasic_1282021.mat';
%save(modelDataFileName,'PDATA','Nstate','compartments','nleaks');


% Testing a case with 3 distinct data sets with various missing data values
% and initial infected numbers. The underlying rates beta and gamma are the 
% same amongst the 3 data sets. 


%% Generate the data.
t = 0:1:40;
t(1:4:end)=[];
Iapp=0*ones(size(t));
obsid=2; % for infected
dataRNGSeed=4;
[filename1,SNR,xtotal]=Run_ODE_Iappt_GenObsData_mat(.01,Iapp,t,'Const1_SIR_1282021',ODE_RHS,p,x0,dataRNGSeed,odeset(),obsid);
ICs1=xtotal(1,:);


t = 0:1:50;
t(1:3:end)=[];
Iapp=0*ones(size(t));
x0=[N-2; 2; 0];
[filename2,SNR,xtotal]=Run_ODE_Iappt_GenObsData_mat(.01,Iapp,t,'Const2_SIR_1282021',ODE_RHS,p,x0,dataRNGSeed,odeset(),obsid);
ICs2=xtotal(1,:);

t = 0:2:30;
t(1:5:end)=[];
Iapp=0*ones(size(t));
x0=[N-10; 10; 0];
[filename3,SNR,xtotal]=Run_ODE_Iappt_GenObsData_mat(.01,Iapp,t,'Const3_SIR_1282021',ODE_RHS,p,x0,dataRNGSeed,odeset(),obsid);
ICs3=xtotal(1,:);

vseriesCollection={filename1,filename2,filename3};


%% Specify the model using the casadi symbolic framework.
ODEmodel=@casadi_sir;

save(modelDataFileName,'PDATA','Nstate','compartments','vseriesCollection','ODEmodel');

% The csvfile structure is [Index, time (ms), Iapp (pA), V (mV)].
% For .mat files, the matrix is similarly structured. 
% We have implemented that applied current, Iapp (pA) will be scaled by a
% factor of 10^-3 consistent with the drosophila data. This is scaled back
% prior to the 4D-Var problem initiation. 
% For non-neuroscience models, just set Iapp as a vector of zeros (if there
% is no control applied). "V" represents whatever variable data we have,
% and can be multiple columns if multiple variables are observed.

% Now we pass these as arguments to our initiation function for 4D-Var.
SeedNum=2; modeldata=modelDataFileName;

%
observed_variable_in_experiment=struct;
% if providing a "special" observed quantity function in in the ODEmodel,
% this value corresponds to the index of the observed quantity(quantites)
% in the function. Otherwise, this corresponds to the observed variable(s)
observed_variable_in_experiment(1).val=obsid;
observed_variable_in_experiment(2).val=obsid;
observed_variable_in_experiment(3).val=obsid;

% Have to decide initial conditions based on best guess. If truly, totally
% known, make the lb and up equal to impose that the initial condition is 
% fixed at this value, otherwise the algorithm may adjust your initial 
% guess during the estimation procedure.
VariableICs = struct;
VariableICs(1).known  =true; 
VariableICs(1).lb = [ICs1(1)*.8 0 0]';
VariableICs(1).ub = [N 10 0]';
VariableICs(1).vals = ICs1';
VariableICs(1).forceTimeZeroStart=0; % not necessary, already start at time 0
VariableICs(2).known  =true;
VariableICs(2).lb = [ICs2(1)*.8 0 0]';
VariableICs(2).ub = [N 10 0]';
VariableICs(2).vals = ICs2';
VariableICs(2).forceTimeZeroStart=0; 

VariableICs(3).known  =true;
VariableICs(3).lb = [ICs3(1)*.8 0 0]';
VariableICs(3).ub = [N 10 0]';
VariableICs(3).vals = ICs3';
VariableICs(3).forceTimeZeroStart=0;

ScalingSupplied=struct('provided',true);

QinvStdUnscaled=.1*[1 1 1];
VariableScale=[1 1 1]';
Qinv=(10^-2)*[1 1 1];
% Rinv should either be the length of the observed quantities in the system
% in ODEmodel observed function, or same size as the ODE system, and the
% index will correspond to measurement error associated with that
% quantity. In the case of observing the variable, some of these values can
% just be put in arbitrarily and only the observed index
% (observed_variable_in_experiment(i).val) will be extracted.
Rinv = [1 1 1];
ScalingSupplied.QinvStdUnscaled=QinvStdUnscaled;
ScalingSupplied.VariableScale=VariableScale;
ScalingSupplied.Qinv=Qinv;
ScalingSupplied.Rinv=Rinv;
xbounds = [0 N; 0 N; 0 N]; % left and right bounds for system.
%%
tic

% For this problem, may not need to use the controlled version of 4dvar,
% with nudging factor "u", but could explor enabling it with UseControl set
% to 1. If using the control, also consider "smoothing" it impose that it
% will not rapidly change between time points, with SmoothControl set to 1
% (totally optional, amy not impact results).
% Change dt to change the collocation intervals (smaller is more precise,
% but should lead to a rational number when comparing "dt" to whatever the
% time differences are in your data stream. Enable UseSlack if the system
% too stiff and it may reduce the stiffness. This increases the size of the
% system to act to regularize it a bit. There is a slack factor hard coded
% into the subsequent files (slackeps) that could also be adjusted. Can
% enable/disable "ScaleSlack" and "ScaleConstraints" to see if it improves.
% There are a few other parameters, but these are the main onces to
% consider. 

% If considering Weak4dvar, change METHODTOUSE to Weak, and create an
% interval of bounds of the annealing parameter, ranging from say [0,30],
% based on raising alpha0 to this value. e.g. the model contribution will
% be scaled as alpha0^Beta where Beta \in varannealbounds. 

for i=1
run_Run_ODE_neuroDA_multiple_collocation_multiple_experiments(i,'UseModelData',modeldata,ODEmodel,  ...
    'UseControl',0,'SmoothControl',0,'ControlPenalty',1,'dt',.02,'yinds',1,'TOL',1e-12,...
    'METHODTOUSE','Strong','varannealbounds',[30,30],'hessian_approximation','exact',...
    'ControlAtEnd',0,'linear_solver','mumps','UseSlack',0,...
    'NonUniform',1,'observed_variable_in_experiment',observed_variable_in_experiment,...
    'VariableICs',VariableICs,'ScalingSupplied',ScalingSupplied,...
    'alpha0',1.5,'UseColpack',1,'ScaleSlack',1,'ScaleConstraints',1,'xbounds',xbounds)
end
toc

probinfo.pest% compare against original values, last column of parambounds (which isn't revealed to solver), only outputs non-fixed parameters
% let's compare against the relevant estimated values for infected
% probinfo.xt holds the concatatenation of all state variables across all
% experiments. One can extract the specific variable by slicing using its
% appropriate index (in this case 2)


xdata=probinfo.xt;
Idata=xdata(2:3:end); % extract the infected
idxend=length(probinfo.obsarray{1});
idxstart=1;
Ix1=Idata(idxstart:idxend);
% obsarray captures the observations as logical. whenever an observation
% was present, a 1 is present
Ix1 = Ix1(logical(probinfo.obsarray{1}));

idxstart=idxend+1;
idxend=idxend+length(probinfo.obsarray{2});
Ix2=Idata(idxstart:idxend);
Ix2=Ix2(logical(probinfo.obsarray{2}));

idxstart=idxend+1;
idxend=idxend+length(probinfo.obsarray{3});
Ix3=Idata(idxstart:idxend);
Ix3=Ix3(logical(probinfo.obsarray{3}));

figure
 plot(probinfo.tdataarray{1},probinfo.yarray{1},'bo')
hold on
 plot(probinfo.tdataarray{1},Ix1,'bx')
 
 plot(probinfo.tdataarray{2},probinfo.yarray{2},'go')
 plot(probinfo.tdataarray{2},Ix2,'gx')
 
  plot(probinfo.tdataarray{3},probinfo.yarray{3},'ko')
   plot(probinfo.tdataarray{3},Ix3,'kx')
 
  legend({'Data 1: Infected','Estimated 1: Infected',...
      'Data 2: Infected','Estimated 2: Infected',...
      'Data 3: Infected','Estimated 2: Infected'});
   
