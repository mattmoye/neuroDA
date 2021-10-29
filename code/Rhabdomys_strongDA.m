function [] = Rhabdomys_strongDA(SeedNum,CASE,varargin)
%% Rhabdomys SCN run script
% Written by Matthew Moye

if nargin > 2
    saveDir=varargin{1};
else
    saveDir='';
end
ModelLoaded=0;
RunWithoutControl=0;
RampUpControl=0;
switch CASE
    case 2
        modelDataFileName='Cell10_0003_190620_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case2.mat';
        ModelLoaded=1;
end


if ~contains(modelDataFileName,'twoleaks')
    ODEmodel=@casadi_Belle2009_new_mtau_fastm;
else
    ODEmodel=@casadi_Belle2009_new_mtau_fastm_twoleaks;
end
if ModelLoaded
    load(modelDataFileName,'ODEmodel');
end
%% Import and downsample the data
%
%%
% change linear_solver value: 'ma_57' to 'mumps' if ma57 not installed.
run_Run_ODE_neuroDA_multiple_collocation(SeedNum,'UseModelData',modelDataFileName,ODEmodel,  ...
    'UseControl',1,'SmoothControl',1,'ControlPenalty',1,'ControlBound',1.0','yinds',1,'TOL',1e-10,...
    'METHODTOUSE','Strong','varannealbounds',[75,75],'hessian_approximation','exact',...
    'ControlAtEnd',0,'linear_solver','mumps','SaveLagGrad',0,'UseSlack',0,'UseAdaptive',1,...
    'correctLJPData',0,'alpha0',1.5,'UseColpack',1,'ScaleSlack',1,'ScaleConstraints',0,...
    'saveDir',saveDir,'PenalizeSlope',0,'RunWithoutControl',RunWithoutControl,...
    'RampUpControl',RampUpControl)

